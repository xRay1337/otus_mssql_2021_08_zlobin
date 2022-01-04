using System;
using System.Text.RegularExpressions;

namespace LibSQL
{
    public class SqlFunctions
    {
        public static int IsMatched(string str, string pattern) => Regex.IsMatch(str, pattern, RegexOptions.IgnoreCase) ? 1 : 0;


        public static int GetRandomNumber(int min, int max) => new Random().Next(min, max);

    }
}