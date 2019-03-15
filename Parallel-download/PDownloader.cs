using System.Collections.Generic;
using System.Runtime.Remoting.Contexts;
using System.Threading;
using Linked;

namespace Parallel_Download
{
    class PDownloader
    {
        public static int TimeoutSeconds = 10;
        public static string TargetDirectory;

        public readonly string[] Urls;
        public DownloaderEnv Env;

        public PDownloader(string[] urls)
        {
            Urls = urls;
        }

        public void Run()
        {
            DownloaderEnv env = new DownloaderEnv()
            {
                Countdown = new CountdownEvent(Urls.Length),
                MaxRetryCount = 5,
                Tasks = new List<InProgressUrl>(),
                InProgressCount = Urls.Length,
            };

            foreach (var url in Urls)
            {
                InProgressUrl task = new InProgressUrl(url, env);
                env.Tasks.Add(task);
            }

            foreach (var inProgressUrl in env.Tasks)
            {
                ThreadPool.QueueUserWorkItem(delegate(object state) { inProgressUrl.Start(); });

            }

            Env = env;
            env.Countdown.WaitHandle.WaitOne();

            var okCount = CompletedCount;

            ConsoleLog.Write(Kind.Bold, "Total: {0}. Completed: {1}", Urls.Length, okCount);

        }

        public int CompletedCount
        {
            get
            {
                if (Env == null) return 0;
                int okCount = 0;
                foreach (var task in Env.Tasks)
                    if (task.IsComplete)
                        okCount++;

                return okCount;
            }
        }
    }
}
