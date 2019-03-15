using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Threading;
using Linked;

namespace Parallel_Download
{
    delegate void Action();

    class DownloaderEnv
    {
        public int MaxRetryCount = 5;
        public List<InProgressUrl> Tasks = new List<InProgressUrl>();
        public CountdownEvent Countdown;
        public int InProgressCount = 0;
        

        public void Release1()
        {
            Interlocked.Decrement(ref InProgressCount);
            Countdown.Signal();
        }

        private int _maxSizeInfoLength = 1;
        readonly object _SyncMaxSizeInfoLength = new object();

        public int ApplyInfoLength(int infoLength)
        {
            lock (_SyncMaxSizeInfoLength)
            {
                _maxSizeInfoLength = Math.Max(_maxSizeInfoLength, infoLength);
                return _maxSizeInfoLength;
            }
        }

    }

    class InProgressUrl
    {
        public readonly string Url;
        public readonly DownloaderEnv Env;

        public InProgressUrl(string url, DownloaderEnv env)
        {
            Url = url;
            Env = env;
        }

        public int RetryCount = 0;
        public bool IsFinished = false;
        public List<Exception> Errors = new List<Exception>();
        public bool IsComplete = false;

        private string TempFileName = null;

        public string TargetName
        {
            get { return Path.Combine(PDownloader.TargetDirectory, Path.GetFileName(Url)); }
        }

        private readonly object Sync = new object();
        private long LastProgress;
        Stopwatch Sw = Stopwatch.StartNew();

        public void Start()
        {
            again:
            Restart();
            if (!IsComplete)
            {
                if (this.RetryCount < this.Env.MaxRetryCount)
                {
                    ConsoleLog.Write(Kind.Error, "RETRY #{0} for {1}", RetryCount, Url);
                    goto again;
                }
                else
                {
                    ConsoleLog.Write(Kind.Error, "Final FAIL for {0}{1}{2}", Url, Environment.NewLine, ExceptionUtils.GetDigest(this.Errors, 4));
                    MakeFinallyFailed();
                }
            }
        }

        void Restart()
        {
            RetryCount++;
            var fileName = Path.GetFileName(Url);
            TempFileName = Path.Combine(PDownloader.TargetDirectory, fileName + " (try " + RetryCount + ")");
            CleanUpTempFile();

            LastProgress = Sw.ElapsedMilliseconds;
            ManualResetEvent done = new ManualResetEvent(false);

            Thread thread = new Thread(delegate()
            {
                try
                {
                    WReq wc = new WReq();
                    wc.Proxy = WebProxy.GetDefaultProxy();
                    WebClientWatchDog watchDog = new WebClientWatchDog(PDownloader.TimeoutSeconds * 1000, delegate ()
                    {
                        Errors.Add(new Exception("Timed out"));
                        done.Set();
                        TryAndForgetAsync(delegate { wc.CancelAsync(); });
                    });

                    wc.DownloadProgressChanged +=
                    delegate (object sender, DownloadProgressChangedEventArgs e)
                    {
                        watchDog.HealthMessage();
                        long msec = Sw.ElapsedMilliseconds;
                        long elapsedSinceLastProgress;
                        lock (Sync) elapsedSinceLastProgress = msec - LastProgress;
                        if (elapsedSinceLastProgress > 499)
                        {
                            string inProgress;
                            lock (Sync)
                            {
                                inProgress = string.Format("({0}/{1})", Env.Tasks.Count - Env.InProgressCount, Env.Tasks.Count);
                                LastProgress = msec;
                            }
                            string p = "";
                            long tot = e.TotalBytesToReceive;
                            long cur = e.BytesReceived;
                            if (tot > 0)
                            {
                                double pc = (1.0 * cur / tot);
                                TimeSpan eta = TimeSpan.FromSeconds(Math.Max(0, Sw.Elapsed.TotalSeconds / pc - Sw.Elapsed.TotalSeconds));
                                string etaAsString = new DateTime(0).Add(eta).ToString("HH:mm:ss");
                                p = string.Format(", {0,3} % ETA {1}", (int)(pc * 100), etaAsString);
                            }

                            string sizeInfo = (tot / 1024).ToString();
                            var maxSizeInfoLength = Env.ApplyInfoLength(sizeInfo.Length);
                            ConsoleLog.Write(Kind.Progress, "{4} {0," + maxSizeInfoLength + "} of {1,-" + maxSizeInfoLength + "}K{2}: {3}", cur / 1024, tot / 1024, p, Path.GetFileName(Url), inProgress);
                        }
                    };

                    wc.DownloadFileCompleted += delegate (object sender, AsyncCompletedEventArgs e)
                    {
                        Exception err = null;

                        if (e.Error != null)
                            err = new Exception("Failed to download " + Url, e.Error);

                        if (e.Cancelled)
                        {
                            err = new Exception("Canceled: " + Url);
                        }
                        if (err != null)
                        {
                            this.Errors.Add(err);
                            ConsoleLog.Write(Kind.Error, "FAIL of {0}: {1}", Path.GetFileName(TempFileName), ExceptionUtils.GetDigest(err));
                            try
                            {
                                File.WriteAllText(TempFileName + " (DOWNLOAD ERROR).LOG", err.ToString());
                            }
                            catch
                            {
                            }

                            CleanUpTempFile();

                            // Start DownloadFileAsync again
                        }
                        else
                        {
                            ConsoleLog.Write(Kind.Done, "OK: {0}", Url);
                            MakeCompleted();
                        }

                        watchDog.Dispose();
                        done.Set();
                    };

                    ConsoleLog.Write(Kind.Bold, "Started {0}", Url);
                    wc.DownloadFileAsync(new Uri(Url), TempFileName);
                }
                catch (Exception ex)
                {
                    Exception ex2 = new Exception("Failed to ENQUEUE " + Url, ex);
                    this.Errors.Add(ex2);
                    ConsoleLog.Write(Kind.Error, ex2.ToString());
                    done.Set();
                }
                finally
                {
                }
            });
            thread.IsBackground = true;
            thread.Start();

            done.WaitOne();
        }

        void MakeCompleted()
        {
            try
            {
                File.Delete(TargetName);
            }
            catch
            {
            }

            File.Move(TempFileName, TargetName);
            IsComplete = true;
            IsFinished = true;
            this.Env.Release1();
        }

        void MakeFinallyFailed()
        {
            CleanUpTempFile();

            IsFinished = true;
            IsComplete = false;
            this.Env.Release1();
        }

        void CleanUpTempFile()
        {
            if (File.Exists(TempFileName))
                File.Delete(TempFileName);
        }

        static void TryAndForgetAsync(Action a)
        {
            ThreadPool.QueueUserWorkItem(delegate(object state)
            {
                try
                {
                    a();
                }
                catch
                {
                }
            });
        }
    }
}