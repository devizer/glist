#!/bin/sh

echo "Finally, checking mcs and mono command lines (working directory is '`pwd`')"
t=`mktemp -d`
echo '
using System;
using System.Diagnostics;
using System.Reflection;

internal class Program
{
    private static void Main(string[] args)
    {
        string runtime = null, footprint = null;

        try
        {
            footprint = GetMemoryFootprint();
        }
        catch (Exception)
        {
        }

        try
        {
            runtime = GetMonoVersion();
        }
        catch
        {
        }

        Console.WriteLine("Runtime: {0}, Memory Footprint: {1}",
            runtime ?? "N/A",
            footprint ?? "N/A"
            );
    }

    private static string GetMemoryFootprint()
    {
        return Process.GetCurrentProcess().WorkingSet64/1024/1024 + " Kilo";
    }

    private static string GetMonoVersion()
    {
        var t = Type.GetType("Mono.Runtime", false);
        if (t != null)
        {
            var method = t.GetMethod("GetDisplayName",
                BindingFlags.DeclaredOnly | BindingFlags.Static | BindingFlags.NonPublic | BindingFlags.ExactBinding);
            if (method != null)
                return
                    "CLR " + Environment.Version + "; "
                    + "Mono " + method.Invoke(null, new object[0]);
        }

        return "Net " + Environment.Version;
    }
}
' > "$t/program.cs"
LD_LIBRARY_PATH="$LD_LIBRARY_PATH:./lib"
export LD_LIBRARY_PATH
bin/mono lib/mono/4.5/mcs.exe -out:"$t/program.exe" "$t/program.cs" || ( echo "mcs (compiler) isn't working"; exit; )
bin/mono "$t/program.exe" || ( echo "mono (runtime) isn't working"; exit; )
rm -rf "$t"

TO="$1"
if [ -z "$TO" ]; then
  exit;
fi

if [ "$TO" = "`pwd`" ]; then
  exit;
fi

# sudo rm -rf "$TO"
sudo cp -rp . "$TO"

sudo ldconfig -n "$TO" || echo ldconfig skipped

rc=`mktemp`
echo "

# mono at $TO
export PATH=\"\$PATH:$TO/bin\"
export LD_LIBRARY_PATH=\"\$LD_LIBRARY_PATH:$TO/lib\"
export PKG_CONFIG_PATH=\"\$PKG_CONFIG_PATH:$TO/lib/pkgconfig\"
export MANPATH=\"\$MANPATH:$TO/share/man1:$TO/share/man5\"
" > $rc

cat $rc >> ~/.bashrc
echo "~/.bashrc file appended: `cat $rc`"
