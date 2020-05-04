using System;
using System.Globalization;
using System.Reflection;

namespace GitInfo
{
    class Program
    {
        static void Main(string[] args)
        {
            var x1 = DateTime.Now.ToString("O");
            DateTime.ParseExact(x1, "O", new CultureInfo("en-US"));

            var last = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc).AddSeconds(1514306669);
            Console.WriteLine($"Last: {last}"); 

            Console.WriteLine($"ISO: {DateTime.Now.ToString("O")}");
            Console.WriteLine($"iso: {DateTime.Now.ToString("o")}");
            Console.WriteLine($"Git Info: {AssemblyGitInfoAttribute.GetGitInfo(Assembly.GetExecutingAssembly())}");

        }


    }
}
