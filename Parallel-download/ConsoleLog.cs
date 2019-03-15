using System;
using System.Diagnostics;

namespace Parallel_Download
{
    class ConsoleLog
    {
        static Stopwatch Sw = Stopwatch.StartNew();
        static readonly object Sync = new object();

        public static void Write(Kind kind, string msg)
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

                Console.ForegroundColor = (Console.BackgroundColor == ConsoleColor.DarkGray) ? ConsoleColor.Gray : ConsoleColor.DarkGray;
                var seconds = new DateTime(0).AddSeconds(Sw.Elapsed.TotalSeconds).ToString("H:mm:ss.f");
                Console.Write("{0,12} ", seconds);

                Console.ForegroundColor = newColor;
                Console.WriteLine("{0}", msg);
                Console.ForegroundColor = prevColor;

            }
        }

        public static void Write(Kind kind, string format, params object[] args)
        {
            Write(kind, string.Format(format, args));
        }

    }
}