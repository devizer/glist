using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Reflection;
using GitInfo;

[assembly: AssemblyGitInfo("master", 97, 1514306669L)]

namespace GitInfo
{
    [AttributeUsage(AttributeTargets.Assembly, AllowMultiple = false, Inherited = false)]
    public class AssemblyGitInfoAttribute : Attribute
    {
        private static readonly DateTime ZeroDate = new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public string Branch { get; private set; }
        public int Counter { get; private set; }
        public DateTime DateTimeUtc { get; private set; }

        public AssemblyGitInfoAttribute(string branch, int counter, long since1970)
        {
            Branch = branch;
            Counter = counter;
            DateTimeUtc = ZeroDate.AddSeconds(since1970);
        }

        public static AssemblyGitInfoAttribute GetGitInfo(Assembly assembly)
        {
            if (assembly == null)
                throw new ArgumentNullException(nameof(assembly));

            IEnumerable<Attribute> arr = assembly.GetCustomAttributes(typeof(AssemblyGitInfoAttribute));
            AssemblyGitInfoAttribute attr = (AssemblyGitInfoAttribute)arr.FirstOrDefault();
            return attr;
        }

        public override string ToString()
        {
            return $"{nameof(Branch)}: {Branch}, {nameof(Counter)}: {Counter}, {nameof(DateTimeUtc)}: {DateTimeUtc.ToString("R")}";
        }
    }
}