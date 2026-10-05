using SkiaSharp;

namespace PierPressure.Windows.Theme;

/// <summary>1930s cartoon-marquee palette.</summary>
public static class DeltaTheme
{
    public static readonly SKColor Ink   = new(0x0A, 0x0A, 0x0C);
    public static readonly SKColor Cream = new(0xF5, 0xEF, 0xE0);
    public static readonly SKColor Gold  = new(0xD4, 0xA9, 0x42);
    public static readonly SKColor Red   = new(0xB0, 0x3A, 0x2E);

    public static Color InkM   => Color.FromRgb(0x0A, 0x0A, 0x0C);
    public static Color CreamM => Color.FromRgb(0xF5, 0xEF, 0xE0);
    public static Color GoldM  => Color.FromRgb(0xD4, 0xA9, 0x42);
    public static Color RedM   => Color.FromRgb(0xB0, 0x3A, 0x2E);
}
