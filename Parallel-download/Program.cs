
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Net;
using System.Reflection;
using System.Threading;
using Parallel_Download;

internal class Program
{

    public static int Main(string[] args)
    {
        int minWaiters;
        int minWorkers;
        ThreadPool.GetMinThreads(out minWorkers, out minWaiters);
        minWorkers = 7 + args.Length * 3;
        ThreadPool.SetMinThreads(minWorkers, minWaiters);

        string protocol = ApplyTls12();
        ConsoleLog.Write(Kind.Progress,  "Parallel Downloader @ NET: {0}, Secure Protocol: {1}", Environment.Version, protocol);
        ServicePointManager.ServerCertificateValidationCallback += delegate { return true; };
        var defaultConnectionLimit = Math.Max(args.Length-1, 2);
        ServicePointManager.DefaultConnectionLimit = defaultConnectionLimit;
        ServicePointManager.MaxServicePoints = defaultConnectionLimit;
        ServicePointManager.MaxServicePointIdleTime = PDownloader.TimeoutSeconds * 1000;

        try
        {
            return Exec(args);
        }
        catch (Exception ex)
        {
            ConsoleLog.Write(Kind.Error, "Wrong arguments: {0}", ExceptionUtils.GetDigest(ex));
            ConsoleLog.Write(Kind.Bold, "USAGE: Parallel-Download.exe <target\\folder> url1 [url2] [url3] ...");

            return 9999;
        }
    }

    static string ApplyTls12()
    {
        string ret = "default";
        try
        {
            ret = ServicePointManager.SecurityProtocol.ToString();
            FieldInfo protocolTypeField = typeof(SecurityProtocolType).GetField("Tls12");
            if (protocolTypeField != null)
            {
                SecurityProtocolType protocolType = (SecurityProtocolType) protocolTypeField.GetValue(null);
                ServicePointManager.SecurityProtocol = protocolType;
                ret = protocolType.ToString();
            }
        }
        catch
        {
        }

        return ret;
    }


    private static int Exec(string[] args)
    {
        PDownloader.TargetDirectory= args[0];
        try
        {
            Directory.CreateDirectory(PDownloader.TargetDirectory);
        }
        catch { }

        ConsoleLog.Write(Kind.Bold, "Target Dir: [{0}], {1}", PDownloader.TargetDirectory, Directory.Exists(PDownloader.TargetDirectory) ? "OK" : "Can't be created");

        List<string> urls = new List<string>();
        for (int i = 1; i < args.Length; i++) urls.Add(args[i]);
        PDownloader pd = new PDownloader(urls.ToArray());
        pd.Run();

        return urls.Count - pd.CompletedCount;
    }



}

