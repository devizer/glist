
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Threading;

internal class Program
{
    private const int _TimeOut = 240;

    private class WReq : WebClient
    {

        protected override WebRequest GetWebRequest(Uri uri)
        {
            WebRequest w = base.GetWebRequest(uri);
            w.Timeout = _TimeOut * 1000;
            w.Proxy = WebProxy.GetDefaultProxy();
            return w;
        }
    }

    static Dictionary<string, List<Exception>> Errors;
    static Dictionary<string, object> Finished = new Dictionary<string, object>();
    static Stopwatch Sw = Stopwatch.StartNew();
    static Dictionary<string, long> LastProgress = new Dictionary<string, long>();
    private static string TargetDir;
    static object Sync = new object();

    public static int Main(string[] args)
    {
        Write("Downloader @ NET: " + Environment.Version);
        ServicePointManager.ServerCertificateValidationCallback += delegate { return true; };
        var defaultConnectionLimit = Math.Max(args.Length-1, 2);
        ServicePointManager.DefaultConnectionLimit = defaultConnectionLimit;
        ServicePointManager.MaxServicePoints = defaultConnectionLimit;
        ServicePointManager.MaxServicePointIdleTime = _TimeOut;

        try
        {
            return Exec(args);
        }
        catch (Exception ex)
        {
            Write("Wrong arguments: " + Environment.NewLine + ex + 
                Environment.NewLine + "USAGE: Parallel-Download.exe <target\\folder> url1 [url2] [url3] ...");

            return 9999;
        }
    }

    private static int Exec(string[] args)
    {
        TargetDir = args[0];
        try
        {
            Directory.CreateDirectory(TargetDir);
        }
        catch { }

        Write("Target Dir: [{0}], {1}", TargetDir, Directory.Exists(TargetDir) ? "OK" : "Can't be created");

        List<string> urls = new List<string>();
        for (int i = 1; i < args.Length; i++) urls.Add(args[i]);

        int retryNumer = 0;
        while (urls.Count > 0 && retryNumer < args.Length)
        {
            if (retryNumer > 0) Write("{1}RETRY: {0}", retryNumer, Environment.NewLine);
            int prev = urls.Count;
            TryDownload(urls);
            int next = urls.Count;
            retryNumer++;
        }

        return Errors.Count;
    }

    static void TryDownload(List<string> urls)
    {
        List<ManualResetEvent> dones = new List<ManualResetEvent>();
        Errors = new Dictionary<string, List<Exception>>();
        Finished = new Dictionary<string, object>();
        string n = Environment.NewLine;
        foreach (string u in urls)
        {
            string url = u;
            ManualResetEvent done = new ManualResetEvent(false);
            dones.Add(done);
            LastProgress[url] = Sw.ElapsedMilliseconds;

            Thread t = new Thread(delegate (object o)
            {
                Stopwatch swThis = Stopwatch.StartNew();
                Thread.CurrentThread.CurrentCulture = new CultureInfo("en-US");
                string targetFile = Path.Combine(TargetDir, Path.GetFileName(url));
                try
                {
                    WReq wc = new WReq();
                    wc.Proxy = WebProxy.GetDefaultProxy();
                    wc.DownloadProgressChanged +=
                    delegate (object sender, DownloadProgressChangedEventArgs e)
                    {
                        long msec = Sw.ElapsedMilliseconds;
                        if (msec - LastProgress[url] > 499)
                        {
                            string inProgress;
                            lock (Sync) inProgress = string.Format("({0}/{1})", urls.Count - Finished.Count, urls.Count);
                            string p = "";
                            long tot = e.TotalBytesToReceive;
                            long cur = e.BytesReceived;
                            if (tot > 0)
                            {
                                double pc = (1.0 * cur / tot);
                                TimeSpan eta = TimeSpan.FromSeconds(Math.Max(0, swThis.Elapsed.TotalSeconds / pc - swThis.Elapsed.TotalSeconds));
                                p = string.Format(", {0:f0}% ETA {1}", pc * 100, eta);
                            }
                            Write("{4} {0} of {1}K{2}: {3}", cur / 1024, tot / 1024, p, Path.GetFileName(url), inProgress);
                            lock (Sync) LastProgress[url] = msec;
                        }
                    };

                    wc.DownloadFileCompleted += delegate (object sender, AsyncCompletedEventArgs e)
                    {
                        Exception err = null;

                        if (e.Error != null)
                            err = new Exception("Failed to download " + url, e.Error);

                        if (e.Cancelled)
                        {
                            err = new Exception("Canceled: " + url);
                        }
                        if (err != null)
                        {
                            AddError(url, err);
                            Write("FAIL: " + targetFile);
                            try
                            {
                                File.WriteAllText(Path.GetFileNameWithoutExtension(targetFile) + ".DOWNLOAD ERROR.LOG", err.ToString());
                            }
                            catch
                            {
                            }
                            try
                            {
                                File.Delete(targetFile);
                            }
                            catch
                            {
                            }
                        }
                        else
                            Write("OK: {0}", url);

                        lock (Sync) Finished[url] = null;
                        done.Set();
                    };
                    Write("Started {0}", url);
                    wc.DownloadFileAsync(new Uri(url), targetFile);
                }
                catch (Exception ex)
                {
                    Exception ex2 = new Exception("Failed to ENQUEUE " + url, ex);
                    AddError(url, ex2);
                    Write(ex2.ToString());
                    done.Set();
                }
                finally
                {
                }
            });
            t.IsBackground = true;
            t.Start();
        }

        Write("{0} downloads started", dones.Count);
        foreach (ManualResetEvent e in dones) e.WaitOne();
        if (Errors.Count > 0)
        {
            Write("Errors details");
            string[] sorted = new string[Errors.Keys.Count];
            Errors.Keys.CopyTo(sorted, 0);
            Array.Sort(sorted);
            foreach (string url in sorted)
            {
                Write(" **** " + url);
                foreach (Exception exception in Errors[url])
                    Write(exception + n);

                Write("");
            }
        }
        Write("So Success: {0}, Failed: {1}", urls.Count - Errors.Count, Errors.Count);

        foreach (string u in Finished.Keys)
            if (!Errors.ContainsKey(u))
                urls.Remove(u);

    }

    static void Write(string msg)
    {
        lock (Sync) Console.WriteLine("{0} {1}", Sw.Elapsed, msg);
    }

    static void Write(string format, params object[] args)
    {
        Write(string.Format(format, args));
    }

    static void AddError(string url, Exception err)
    {
        lock (Sync)
        {
            List<Exception> list;
            if (!Errors.TryGetValue(url, out list))
            {
                list = new List<Exception>();
                Errors.Add(url, list);
            }
            list.Add(err);
        }
    }
}


