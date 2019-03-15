using System;

public enum Kind
{
    Progress,
    Done,
    Error,
    Bold,
}

public class ColorConsole 
{
    public static ConsoleColor GetColor(Kind style)
    {
        ConsoleColor color = GetColorForStyle(style);
        ConsoleColor bg = Console.BackgroundColor;

        if (color == bg || color == ConsoleColor.Red && bg == ConsoleColor.Magenta)
            return bg == ConsoleColor.Black
                ? ConsoleColor.White
                : ConsoleColor.Black;

        return color;
    }

    private static ConsoleColor GetColorForStyle(Kind style)
    {
        switch (Console.BackgroundColor)
        {
            case ConsoleColor.White:
                switch (style)
                {
                    case Kind.Bold:
                        return ConsoleColor.Black;
                    case Kind.Done:
                        return ConsoleColor.Green;
                    case Kind.Error:
                        return ConsoleColor.Red;
                    case Kind.Progress:
                        return ConsoleColor.Black;
                    default:
                        return ConsoleColor.Black;
                }

            case ConsoleColor.Cyan:
            case ConsoleColor.Green:
            case ConsoleColor.Red:
            case ConsoleColor.Magenta:
            case ConsoleColor.Yellow:
                switch (style)
                {
                    case Kind.Bold:
                        return ConsoleColor.Black;
                    case Kind.Done:
                        return ConsoleColor.Black;
                    case Kind.Error:
                        return ConsoleColor.Red;
                    case Kind.Progress:
                        return ConsoleColor.Gray;
                    default:
                        return ConsoleColor.Black;
                }

            default:
                switch (style)
                {
                    case Kind.Bold:
                        return ConsoleColor.White;
                    case Kind.Done:
                        return ConsoleColor.Green;
                    case Kind.Error:
                        return ConsoleColor.Red;
                    case Kind.Progress:
                        return ConsoleColor.Gray;
                    default:
                        return ConsoleColor.Gray;
                }
        }
    }
}