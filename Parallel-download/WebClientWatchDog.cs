using System;
using System.Diagnostics;
using System.Threading;

public class WebClientWatchDog : IDisposable
{
    public delegate void Action();

    public readonly Action Cancel;
    public readonly long Timeout;

    private Stopwatch _Sw;
    private long _PrevMilliseconds;
    private readonly object _Sync = new object();
    private readonly ManualResetEvent _Stop = new ManualResetEvent(false);


    public WebClientWatchDog(long timeout, Action cancel)
    {
        Cancel = cancel;
        Timeout = timeout;

        RunWatchDog();
    }

    public void HealthMessage()
    {
        lock (_Sync)
            _PrevMilliseconds = _Sw.ElapsedMilliseconds;
    }

    void RunWatchDog()
    {
        Thread t = new Thread(delegate()
        {
            _Sw = Stopwatch.StartNew();
            _PrevMilliseconds = _Sw.ElapsedMilliseconds;
            while (true)
            {
                long next = _Sw.ElapsedMilliseconds;
                long elapsed = next - _PrevMilliseconds;
                bool isTimeout = elapsed > Timeout;
                lock (_Sync) _PrevMilliseconds = next;
                if (isTimeout)
                {
                    Cancel();
                    return;
                }

                bool isStop = _Stop.WaitOne(200);
                if (isStop) return;
            }
        });
        t.IsBackground = true;
        t.Start();
    }

    public void Dispose()
    {
        _Stop.Set();
    }

}