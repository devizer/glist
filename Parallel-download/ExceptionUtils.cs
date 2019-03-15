using System;
using System.Collections.Generic;
using System.Text;

class ExceptionUtils
{
    public static string GetDigest(Exception ex)
    {
        List<string> list = new List<string>();
        while (ex != null)
        {
            list.Add(string.Format("[{0}] {1}", ex.GetType().Name, ex.Message));
            ex = ex.InnerException;
        }

        // list.Reverse();
        return string.Join(" --> ", list.ToArray());
    }

    public static string GetDigest(IEnumerable<Exception> exceptions, int padding)
    {
        string pad = new string(' ', padding);
        StringBuilder ret = new StringBuilder();
        foreach (var exception in exceptions)
        {
            ret.AppendFormat("{0}{1}", pad, GetDigest(exception)).AppendLine();
        }
        
        return ret.ToString();
    }
}