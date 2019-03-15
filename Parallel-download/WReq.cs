using System;
using System.Net;
using Parallel_Download;

internal class WReq : WebClient
{

    protected override WebRequest GetWebRequest(Uri uri)
    {
        WebRequest w = base.GetWebRequest(uri);
        w.Timeout = PDownloader.TimeoutSeconds * 1000;
        w.Proxy = WebProxy.GetDefaultProxy();
        return w;
    }
}