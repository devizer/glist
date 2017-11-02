
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
        Write(Kind.Progress,  "Downloader @ NET: {0}", Environment.Version);
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
            Write(Kind.Error, "Wrong arguments: " + Environment.NewLine + ex);
            Write(Kind.Bold, "USAGE: Parallel-Download.exe <target\\folder> url1 [url2] [url3] ...");

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

        Write(Kind.Bold, "Target Dir: [{0}], {1}", TargetDir, Directory.Exists(TargetDir) ? "OK" : "Can't be created");

        List<string> urls = new List<string>();
        for (int i = 1; i < args.Length; i++) urls.Add(args[i]);

        int retryNumer = 0;
        while (urls.Count > 0 && retryNumer < args.Length)
        {
            if (retryNumer > 0) Write(Kind.Error, "RETRY: {0}", retryNumer);
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
        string nl = Environment.NewLine;
        int pos = 0;
        foreach (string u in urls)
        {
            string url = u;
            ManualResetEvent done = new ManualResetEvent(false);
            dones.Add(done);
            LastProgress[url] = Sw.ElapsedMilliseconds;
            pos++;
            int position = pos;

            Thread t = new Thread(delegate (object o)
            {
                if (position > 1) Thread.Sleep((position-1) * 300);
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
                            Write(Kind.Progress, "{4} {0} of {1}K{2}: {3}", cur / 1024, tot / 1024, p, Path.GetFileName(url), inProgress);
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
                            Write(Kind.Error, "FAIL: {0}", targetFile);
                            try
                            {
                                File.WriteAllText(Path.GetFileNameWithoutExtension(targetFile) + "(DOWNLOAD ERROR).LOG", err.ToString());
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
                            Write(Kind.Done, "OK: {0}", url);

                        lock (Sync) Finished[url] = null;
                        done.Set();
                    };
                    Write(Kind.Bold, "Started {0}", url);
                    wc.DownloadFileAsync(new Uri(url), targetFile);
                }
                catch (Exception ex)
                {
                    Exception ex2 = new Exception("Failed to ENQUEUE " + url, ex);
                    AddError(url, ex2);
                    Write(Kind.Error, ex2.ToString());
                    done.Set();
                }
                finally
                {
                }
            });
            t.IsBackground = true;
            t.Start();
        }

        Write(Kind.Bold, "{0} downloads started", dones.Count);
        foreach (ManualResetEvent e in dones) e.WaitOne();
        if (Errors.Count > 0)
        {
            Write(Kind.Bold, "Errors details");
            string[] sorted = new string[Errors.Keys.Count];
            Errors.Keys.CopyTo(sorted, 0);
            Array.Sort(sorted);
            foreach (string url in sorted)
            {
                Write(Kind.Error, " **** {0}", url);
                foreach (Exception exception in Errors[url])
                    Write(Kind.Error, "{0} {1}", exception, nl);

                Write(Kind.Progress, "");
            }
        }
        Write(Kind.Bold, "So Success: {0}, Failed: {1}", urls.Count - Errors.Count, Errors.Count);

        foreach (string u in Finished.Keys)
            if (!Errors.ContainsKey(u))
                urls.Remove(u);

    }

    static void Write(Kind kind, string msg)
    {
        lock (Sync)
        {
            /*
                        ConsoleColor prevColor = Console.ForegroundColor;
                        ConsoleColor newColor = ConsoleColor.Gray;
                        if (kind == Kind.Bold) newColor = ConsoleColor.White;
                        if (kind == Kind.Error) newColor = ConsoleColor.Red;
                        if (kind == Kind.Done) newColor = ConsoleColor.Green;

                        Console.ForegroundColor = ConsoleColor.DarkGray;
                        var seconds = new DateTime(0).AddSeconds(Sw.Elapsed.TotalSeconds).ToString("H:mm:ss.f");
                        Console.Write("{0,12} ", seconds);

                        Console.ForegroundColor = newColor;
                        Console.WriteLine("{0}", msg);
                        Console.ForegroundColor = prevColor;
            */

            ConsoleColor prevColor = Console.ForegroundColor;
            ConsoleColor newColor = ColorConsole.GetColor(kind);

            Console.ForegroundColor = (Console.BackgroundColor == ConsoleColor.DarkGray) ? ConsoleColor.Gray: ConsoleColor.DarkGray;
            var seconds = new DateTime(0).AddSeconds(Sw.Elapsed.TotalSeconds).ToString("H:mm:ss.f");
            Console.Write("{0,12} ", seconds);

            Console.ForegroundColor = newColor;
            Console.WriteLine("{0}", msg);
            Console.ForegroundColor = prevColor;

        }
    }

    static void Write(Kind kind, string format, params object[] args)
    {
        Write(kind, string.Format(format, args));
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

public enum Kind
{
    Progress,
    Done,
    Error,
    Bold,
}

public class ColorConsole 
{



    public static ConsoleColor GetColor(Kind style)
    {
        ConsoleColor color = GetColorForStyle(style);
        ConsoleColor bg = Console.BackgroundColor;

        if (color == bg || color == ConsoleColor.Red && bg == ConsoleColor.Magenta)
            return bg == ConsoleColor.Black
                ? ConsoleColor.White
                : ConsoleColor.Black;

        return color;
    }

    private static ConsoleColor GetColorForStyle(Kind style)
    {
        switch (Console.BackgroundColor)
        {
            case ConsoleColor.White:
                switch (style)
                {
                    case Kind.Bold:
                        return ConsoleColor.Black;
                    case Kind.Done:
                        return ConsoleColor.Green;
                    case Kind.Error:
                        return ConsoleColor.Red;
                    case Kind.Progress:
                        return ConsoleColor.Black;
                    default:
                        return ConsoleColor.Black;
                }

            case ConsoleColor.Cyan:
            case ConsoleColor.Green:
            case ConsoleColor.Red:
            case ConsoleColor.Magenta:
            case ConsoleColor.Yellow:
                switch (style)
                {
                    case Kind.Bold:
                        return ConsoleColor.Black;
                    case Kind.Done:
                        return ConsoleColor.Black;
                    case Kind.Error:
                        return ConsoleColor.Red;
                    case Kind.Progress:
                        return ConsoleColor.DarkGray;
                    default:
                        return ConsoleColor.Black;
                }

            default:
                switch (style)
                {
                    case Kind.Bold:
                        return ConsoleColor.White;
                    case Kind.Done:
                        return ConsoleColor.Green;
                    case Kind.Error:
                        return ConsoleColor.Red;
                    case Kind.Progress:
                        return ConsoleColor.Gray;
                    default:
                        return ConsoleColor.Gray;
                }
        }
    }

}