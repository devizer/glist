using System;
using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;

namespace RegisterFont
{
    static class Program
    {
        [STAThread]
        static int Main(string[] args)
        {
            if (args.Length == 0)
                Console.WriteLine("Usage: RegisterFont.exe <font-file> | :broadcast");

            else if (args[0].ToLower() == ":broadcast")
                SendMessage(HWND_BROADCAST, WM_FONTCHANGE, 0, 0);

            else
            {
                string file = args[0];
                file = new FileInfo(file).FullName;
                try
                {
                    if (!File.Exists(file))
                        throw new Exception("Font file " + file + " not found");

                    int count = AddFontResource(file);
                    if (count == 0)
                        throw new Exception("None fonts added");

                    var isOk = WriteProfileString("fonts", Path.GetFileNameWithoutExtension(file) + "(TrueType)", file);

                    if (!isOk)
                    {
                        int errorCode = Marshal.GetLastWin32Error();
                        throw new Exception("WriteProfileString failed. Win32 Error: "
                            + errorCode
                            + ". " + new Win32Exception(errorCode).Message);
                    }


                    Console.WriteLine("Registered {0} font(s) using '{1}' file", count, file);
                    return 0;
                }
                catch (Exception ex)
                {
                    Console.WriteLine("New font '{0}' was not added. [{1}] {2}", file, ex.GetType(), ex.Message);
                    return 1;
                }
            }

            return 0;
        }

        const int WM_FONTCHANGE = 0x001D;
        static IntPtr HWND_BROADCAST = new IntPtr(0xffff);
        
        [DllImport("kernel32.dll", SetLastError = true)]
        static extern bool WriteProfileString(string lpszSection, string lpszKeyName, string lpszString);

        [DllImport("user32.dll")]
        public static extern int SendMessage(IntPtr hWnd, uint msg, int wParam, int lParam);
        

        [DllImport("gdi32")]
        public static extern int AddFontResource(string lpFileName);

    }
}
