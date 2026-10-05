using SkiaSharp;

namespace PierPressure.Windows.Game;

/// <summary>
/// Full-screen 60fps perspective-3D renderer for <see cref="DeltaEngine"/>.
/// World units are projected (x, y, z) → screen with a level camera at
/// height 5, z = -8:  d = z + 8; s = f / d;
/// screenX = cx + x·s;  screenY = horizonY + (H − y)·s.
/// Direct port of the Android GameCanvas — same math, same art direction.
/// </summary>
public static class DeltaRenderer
{
    // Animation juice state (mirrors Android): lane lean, land squash.
    public static double Lean { get; set; }
    public static double LandT { get; set; } = 1;

    public static void Draw(SKCanvas canvas, DeltaEngine engine,
        Dictionary<string, SKBitmap> sprites, string characterID,
        double tSec, double speedU, int width, int height)
    {
        float w = width, h = height;
        float cx = w / 2f;
        float horizonY = h * 0.42f;
        const float camH = 5f, camZ = -8f;
        float f = h * 0.62f;
        float sPlayer = f / 8f;

        SKPoint? Proj(double x, double y, double z)
        {
            double d = z - camZ;
            if (d <= 0.5) return null;
            double s = f / d;
            return new SKPoint((float)(cx + x * s), (float)(horizonY + (camH - y) * s));
        }
        float ScaleAt(double z) => (float)(f / (z - camZ));

        // ---- sky ----
        using (var paint = new SKPaint
        {
            Shader = SKShader.CreateLinearGradient(
                new SKPoint(0, 0), new SKPoint(0, horizonY),
                new[] { new SKColor(0x04, 0x06, 0x0E), new SKColor(0x0A, 0x0D, 0x1F) },
                null, SKShaderTileMode.Clamp)
        })
            canvas.DrawRect(0, 0, w, horizonY, paint);

        // ---- stars (fixed seed: no flicker) ----
        var starRand = new Random(42);
        for (int i = 0; i < 44; i++)
        {
            float sx = (float)(starRand.NextDouble() * w);
            float sy = (float)(starRand.NextDouble() * horizonY * 0.92);
            float sr = (float)(1 + starRand.NextDouble() * 1.6);
            double tw = 0.35 + 0.65 * Math.Abs(Math.Sin(tSec * (1 + starRand.NextDouble() * 2) + i));
            using var p = new SKPaint { Color = new SKColor(255, 255, 255, (byte)(255 * 0.75 * tw)), IsAntialias = true };
            canvas.DrawCircle(sx, sy, sr, p);
        }

        // ---- moon + halo ----
        float moonX = w * 0.22f, moonY = h * 0.13f, moonR = h * 0.045f;
        var cream = new SKColor(0xF5, 0xEF, 0xE0);
        using (var p = new SKPaint { Color = cream.WithAlpha((byte)(255 * 0.10)), IsAntialias = true })
            canvas.DrawCircle(moonX, moonY, moonR * 2.6f, p);
        using (var p = new SKPaint { Color = cream.WithAlpha((byte)(255 * 0.16)), IsAntialias = true })
            canvas.DrawCircle(moonX, moonY, moonR * 1.7f, p);
        using (var p = new SKPaint { Color = new SKColor(0xF2, 0xEB, 0xD8), IsAntialias = true })
            canvas.DrawCircle(moonX, moonY, moonR, p);

        // ---- water ----
        using (var paint = new SKPaint
        {
            Shader = SKShader.CreateLinearGradient(
                new SKPoint(0, horizonY), new SKPoint(0, h),
                new[] { new SKColor(0x0A, 0x0F, 0x22), new SKColor(0x04, 0x06, 0x0D) },
                null, SKShaderTileMode.Clamp)
        })
            canvas.DrawRect(0, horizonY, w, h - horizonY, paint);

        // ---- moonlight shimmer ----
        for (int i = 0; i <= 7; i++)
        {
            double fy = i / 7.0;
            float ry = (float)(horizonY + (h - horizonY) * (0.08 + 0.88 * fy * fy));
            float rw = (float)((10 + 46 * fy) * (0.75 + 0.25 * Math.Sin(tSec * 2.2 + i * 1.7)));
            using var p = new SKPaint
            {
                Color = cream.WithAlpha((byte)(255 * 0.10 * (1 - fy * 0.6))),
                StrokeWidth = (float)(3 + 5 * fy),
                IsAntialias = true,
            };
            canvas.DrawLine(moonX - rw, ry, moonX + rw, ry, p);
        }

        // ---- scrolling wave dashes ----
        double waveMod = engine.Distance % 4;
        using var wavePaint = new SKPaint { Color = new SKColor(255, 255, 255, (byte)(255 * 0.16)), StrokeCap = SKStrokeCap.Round, IsAntialias = true };
        for (int m = -1; m <= 17; m++)
        {
            double zLine = m * 4 - waveMod;
            if (zLine < -6) continue;
            foreach (double wx in new[] { -11.0, -7.0, 7.0, 11.0 })
            {
                double wob = Math.Sin(wx * 12.9898 + m * 78.233) * 0.7;
                var a = Proj(wx + wob - 0.85, -0.5, zLine);
                var b = Proj(wx + wob + 0.85, -0.5, zLine);
                if (a == null || b == null) continue;
                wavePaint.StrokeWidth = Math.Max(1, Math.Min(8, ScaleAt(zLine) * 0.10f));
                canvas.DrawLine(a.Value, b.Value, wavePaint);
            }
        }
        using (var p = new SKPaint { Color = new SKColor(0x6A, 0x5A, 0xCD, (byte)(255 * 0.25)), StrokeWidth = 2 })
            canvas.DrawLine(0, horizonY, w, horizonY, p);

        // ---- distant riverboat ----
        double boatX = 16 + Math.Sin(tSec * 0.1) * 3;
        const double boatZ = 80;
        DrawShadedBox(canvas, Proj, boatX, 0, 1.5, boatZ, 8, 20,
            new SKColor(0x1A, 0x20, 0x30), new SKColor(0x23, 0x2B, 0x40), new SKColor(0x11, 0x14, 0x1F));
        DrawShadedBox(canvas, Proj, boatX, 1.5, 4, boatZ, 6, 14,
            new SKColor(0x8E, 0x93, 0xA6), new SKColor(0xA6, 0xAC, 0xBF), new SKColor(0x6B, 0x70, 0x85));
        DrawShadedBox(canvas, Proj, boatX - 1.5, 4, 7, boatZ - 2, 1, 1,
            new SKColor(0x1A, 0x20, 0x30), new SKColor(0x23, 0x2B, 0x40), new SKColor(0x11, 0x14, 0x1F));

        // ---- pier deck (perspective quad) ----
        var slabA = Proj(-3.6, 0, -6); var slabB = Proj(3.6, 0, -6);
        var slabC = Proj(3.6, 0, 64); var slabD = Proj(-3.6, 0, 64);
        if (slabA != null && slabB != null && slabC != null && slabD != null)
        {
            using var path = new SKPath();
            path.MoveTo(slabA.Value); path.LineTo(slabB.Value);
            path.LineTo(slabC.Value); path.LineTo(slabD.Value); path.Close();
            using var p = new SKPaint { Color = new SKColor(0x33, 0x29, 0x1F) };
            canvas.DrawPath(path, p);
        }

        // ---- deck planks ----
        double plankMod = engine.Distance % 2;
        using var plankPaint = new SKPaint { Color = new SKColor(0x5C, 0x4F, 0x45, (byte)(255 * 0.85)), StrokeCap = SKStrokeCap.Butt };
        for (int m = -3; m <= 33; m++)
        {
            double zLine = m * 2 - plankMod;
            if (zLine < -6) continue;
            var a = Proj(-3.55, 0, zLine); var b = Proj(3.55, 0, zLine);
            if (a == null || b == null) continue;
            plankPaint.StrokeWidth = Math.Max(1.5f, Math.Min(30, ScaleAt(zLine) * 0.45f));
            canvas.DrawLine(a.Value, b.Value, plankPaint);
        }

        // ---- railings ----
        var railF = new SKColor(0x3D, 0x33, 0x2B); var railT = new SKColor(0x4A, 0x3F, 0x36); var railS = new SKColor(0x2C, 0x25, 0x1F);
        DrawShadedBox(canvas, Proj, -3.62, 1.02, 1.22, 29, 0.16, 70, railF, railT, railS);
        DrawShadedBox(canvas, Proj, 3.62, 1.02, 1.22, 29, 0.16, 70, railF, railT, railS);
        double postMod = engine.Distance % 8;
        for (double pz = -4 - postMod; pz < 64; pz += 8)
        {
            if (pz > -6)
            {
                DrawShadedBox(canvas, Proj, -3.62, 0, 1.1, pz, 0.16, 0.16, railF, railT, railS);
                DrawShadedBox(canvas, Proj, 3.62, 0, 1.1, pz, 0.16, 0.16, railF, railT, railS);
            }
        }

        // ---- lane dividers ----
        using var divPaint = new SKPaint { Color = new SKColor(0xFF, 0xD5, 0x4F, (byte)(255 * 0.25)), StrokeWidth = 4, IsAntialias = true };
        using var edgePaint = new SKPaint { Color = new SKColor(0xFF, 0xD5, 0x4F, (byte)(255 * 0.15)), StrokeWidth = 4, IsAntialias = true };
        foreach (double dx in new[] { -3.4, -1.1, 1.1, 3.4 })
        {
            var a = Proj(dx, 0, -6); var b = Proj(dx, 0, 64);
            if (a == null || b == null) continue;
            canvas.DrawLine(a.Value, b.Value, Math.Abs(dx) > 2 ? edgePaint : divPaint);
        }

        // ---- background cameos ----
        var rosterIds = Characters.Roster.All.Select(c => c.Id).Where(id => id != characterID).ToList();
        var cameoRand = new Random(characterID.GetHashCode());
        var cameoIds = rosterIds.OrderBy(_ => cameoRand.Next()).Take(3).ToList();
        var cameoSpots = new[] { (-3.3, 0.0, 16.0), (3.3, 0.0, 16.0), (boatX, 4.2, boatZ) };
        float charBasePx = 130;
        for (int i = 0; i < 3 && i < cameoIds.Count; i++)
        {
            var (ccx, ccy, ccz) = cameoSpots[i];
            double bobY = ccy + Math.Sin(tSec * 2.8 + i * 2.1) * 0.12;
            var p = Proj(ccx, bobY, ccz);
            if (p == null) continue;
            double sizeMul = i == 2 ? 2.2 : 1;
            float size = (float)(charBasePx * 8 / (ccz + 8) * sizeMul);
            DrawCharacter(canvas, sprites, cameoIds[i], p.Value.X, p.Value.Y, size, false, 0);
        }

        // ---- entities, far to near ----
        var items = new List<(double zKey, Action draw)>();
        foreach (var o in engine.Obstacles)
        {
            if (o.Lane < 0 || o.Lane > 2) continue;
            double lx = DeltaEngine.LaneX[o.Lane];
            double zKey = o.Kind == ObstacleKind.Train ? o.Z - o.Depth : o.Z - 0.5;
            var oc = o;
            items.Add((zKey, () => DrawObstacle(canvas, Proj, ScaleAt, oc, lx, tSec)));
        }
        foreach (var c in engine.Coins)
        {
            if (c.Collected) continue;
            var cc = c;
            items.Add((cc.Z, () => DrawCoin(canvas, Proj, ScaleAt, cc, tSec)));
        }
        foreach (var p in engine.PowerUps)
        {
            if (p.Taken) continue;
            var pp = p;
            items.Add((pp.Z, () => DrawPowerUp(canvas, Proj, ScaleAt, pp)));
        }
        items.Add((0, () =>
        {
            double bobY = (!engine.IsRolling && engine.PlayerY < 0.02) ? Math.Sin(tSec * 14) * 0.05 : 0;
            var feet = Proj(engine.PlayerX, engine.PlayerY + bobY, 0);
            if (feet == null) return;
            float s = ScaleAt(0);
            double sx = 1, sy = 1, spin = 0;
            if (engine.IsRolling)
            {
                double rt = Math.Max(0, Math.Min(1, engine.StateT / DeltaEngine.RollTime));
                spin = rt * 720;
                double tuck = Math.Sin(Math.PI * rt);
                sx = 1 + 0.06 * tuck; sy = 1 - 0.10 * tuck;
            }
            else
            {
                if (engine.PlayerY > 0.02)
                {
                    double jt = Math.Max(0, Math.Min(1, engine.StateT / DeltaEngine.JumpTime));
                    double stretch = Math.Sin(Math.PI * jt);
                    sx = 1 - 0.16 * stretch; sy = 1 + 0.28 * stretch;
                }
                else if (LandT < 0.22)
                {
                    double k = 1 - LandT / 0.22;
                    sx = 1 + 0.14 * k; sy = 1 - 0.22 * k;
                }
                double lateral = DeltaEngine.LaneX[engine.PlayerLane] - engine.PlayerX;
                double slideK = Math.Max(0, Math.Min(1, Math.Abs(lateral) / 2.2));
                sx += 0.16 * slideK; sy -= 0.06 * slideK;
            }
            canvas.Save();
            canvas.Translate(feet.Value.X, feet.Value.Y);
            canvas.RotateDegrees((float)(-Lean * 57.2958));
            canvas.Scale((float)sx, (float)sy);
            canvas.Translate(-feet.Value.X, -feet.Value.Y);
            DrawCharacter(canvas, sprites, characterID, feet.Value.X, feet.Value.Y,
                charBasePx * s / sPlayer, engine.IsRolling, spin);
            canvas.Restore();
            // shadow
            var g = Proj(engine.PlayerX, 0, 0);
            if (g != null)
            {
                double fade = 1 - Math.Max(0, Math.Min(1, engine.PlayerY / 4));
                using var p = new SKPaint { Color = new SKColor(0, 0, 0, (byte)(255 * 0.35 * fade)), IsAntialias = true };
                canvas.DrawOval(g.Value.X, g.Value.Y, 0.9f * s, 0.12f * s, p);
            }
        }));
        foreach (var item in items.OrderByDescending(i => i.zKey))
            item.draw();

        // ---- speed streaks ----
        if (speedU > 13)
        {
            double alpha = Math.Max(0, Math.Min(1, (speedU - 13) / 9)) * 0.14;
            using var p = new SKPaint { Color = new SKColor(255, 255, 255, (byte)(255 * alpha)), StrokeWidth = 5, StrokeCap = SKStrokeCap.Round };
            for (int i = 0; i < 10; i++)
            {
                float sx = ((i % 2 == 0 ? 0.04f : 0.96f) * w) + (i % 3) * 14;
                float sy = (float)(((i * 197 + tSec * 900) % (h * 1.2)) - h * 0.1);
                canvas.DrawLine(sx, sy, sx, sy + 110, p);
            }
        }

        // ---- power-up pips ----
        float pipX = 44;
        if (engine.MagnetActive)
        {
            using var p = new SKPaint { Color = new SKColor(0xE5, 0x39, 0x35), Style = SKPaintStyle.Stroke, StrokeWidth = 12, IsAntialias = true };
            canvas.DrawArc(new SKRect(pipX - 18, 66, pipX + 18, 102), 180, 180, false, p);
            pipX += 68;
        }
        if (engine.DoubleScore)
        {
            using var p = new SKPaint { Color = new SKColor(0xFF, 0xD5, 0x4F), IsAntialias = true };
            canvas.DrawCircle(pipX, 84, 24, p);
            using var tp = new SKPaint
            {
                Color = new SKColor(0x3E, 0x27, 0x23),
                TextSize = 24, IsAntialias = true, TextAlign = SKTextAlign.Center,
                Typeface = SKTypeface.FromFamilyName("Georgia", SKFontStyleWeight.Bold, SKFontStyleWidth.Normal, SKFontStyleSlant.Upright),
            };
            canvas.DrawText("2x", pipX, 84 + 8, tp);
        }
    }

    // ================= helpers =================

    private static SKPath QuadPath(SKPoint a, SKPoint b, SKPoint c, SKPoint d)
    {
        var path = new SKPath();
        path.MoveTo(a); path.LineTo(b); path.LineTo(c); path.LineTo(d); path.Close();
        return path;
    }

    private static SKPoint Lerp(SKPoint a, SKPoint b, double t)
        => new((float)(a.X + (b.X - a.X) * t), (float)(a.Y + (b.Y - a.Y) * t));

    private delegate SKPoint? ProjFn(double x, double y, double z);

    private static SKPoint[]? DrawShadedBox(SKCanvas canvas, ProjFn proj,
        double bcx, double y0, double y1, double zc, double w, double depth,
        SKColor front, SKColor top, SKColor side)
    {
        double x0 = bcx - w / 2, x1 = bcx + w / 2;
        double zN = zc - depth / 2, zF = zc + depth / 2;
        var pts = new[]
        {
            proj(x0, y0, zN), proj(x1, y0, zN), proj(x1, y1, zN), proj(x0, y1, zN),
            proj(x0, y0, zF), proj(x1, y0, zF), proj(x1, y1, zF), proj(x0, y1, zF),
        };
        if (pts.Any(p => p == null)) return null;
        var q = pts.Select(p => p!.Value).ToArray();
        using var sideP = new SKPaint { Color = side };
        using var topP = new SKPaint { Color = top };
        using var frontP = new SKPaint { Color = front };
        if (bcx < 0) canvas.DrawPath(QuadPath(q[1], q[5], q[6], q[2]), sideP);
        else canvas.DrawPath(QuadPath(q[0], q[4], q[7], q[3]), sideP);
        canvas.DrawPath(QuadPath(q[2], q[6], q[7], q[3]), topP);
        canvas.DrawPath(QuadPath(q[0], q[1], q[2], q[3]), frontP);
        return q;
    }

    private static void StripeFrontFace(SKCanvas canvas, SKPoint[] q, int stripes, SKColor color)
    {
        using var p = new SKPaint { Color = color };
        for (int i = 0; i < stripes; i += 2)
        {
            double t0 = (double)i / stripes, t1 = (double)(i + 1) / stripes;
            using var path = QuadPath(Lerp(q[0], q[1], t0), Lerp(q[0], q[1], t1),
                                      Lerp(q[3], q[2], t1), Lerp(q[3], q[2], t0));
            canvas.DrawPath(path, p);
        }
    }

    private static void DrawObstacle(SKCanvas canvas, ProjFn proj, Func<double, float> scaleAt,
        DeltaEngine.Obstacle o, double lx, double tSec)
    {
        var sh = proj(lx, 0, o.Z);
        if (sh != null)
        {
            float ss = scaleAt(o.Z);
            using var p = new SKPaint { Color = new SKColor(0, 0, 0, (byte)(255 * 0.28)), IsAntialias = true };
            canvas.DrawOval(sh.Value.X, sh.Value.Y, 1.1f * ss, 0.08f * ss, p);
        }
        var woodF = new SKColor(0x5C, 0x4F, 0x45); var woodT = new SKColor(0x6B, 0x5D, 0x4F); var woodS = new SKColor(0x46, 0x3C, 0x33);
        var woodDarkF = new SKColor(0x3D, 0x33, 0x2B); var woodDarkT = new SKColor(0x4A, 0x3F, 0x36); var woodDarkS = new SKColor(0x2C, 0x25, 0x1F);
        var hullF = new SKColor(0x1C, 0x1C, 0x1E); var hullT = new SKColor(0x2A, 0x2A, 0x2C); var hullS = new SKColor(0x10, 0x10, 0x12);
        var cabinF = new SKColor(0xB5, 0xB0, 0xA6); var cabinT = new SKColor(0xCF, 0xC9, 0xBC); var cabinS = new SKColor(0x8E, 0x88, 0x7A);
        var trimF = new SKColor(0x7A, 0x74, 0x68); var trimT = new SKColor(0x8E, 0x88, 0x7A); var trimS = new SKColor(0x5C, 0x57, 0x4C);
        var stackF = new SKColor(0x14, 0x14, 0x14); var stackT = new SKColor(0x1E, 0x1E, 0x1E); var stackS = new SKColor(0x0A, 0x0A, 0x0A);
        var warm = new SKColor(0xFF, 0xEB, 0xBF);
        var wheelRed = new SKColor(0x9E, 0x29, 0x24);

        switch (o.Kind)
        {
            case ObstacleKind.Barrier: // rowboat — jump it
                DrawShadedBox(canvas, proj, lx, 0.15, 0.85, o.Z, 2.6, 1.2, woodF, woodT, woodS);
                DrawShadedBox(canvas, proj, lx - 1.45, 0.2, 0.8, o.Z, 0.7, 1.0, woodF, woodT, woodS);
                DrawShadedBox(canvas, proj, lx + 1.45, 0.2, 0.8, o.Z, 0.7, 1.0, woodF, woodT, woodS);
                DrawShadedBox(canvas, proj, lx, 0.84, 0.96, o.Z, 2.75, 1.3, woodDarkF, woodDarkT, woodDarkS);
                DrawShadedBox(canvas, proj, lx - 0.55, 0.7, 0.78, o.Z, 0.28, 1.05, woodDarkF, woodDarkT, woodDarkS);
                DrawShadedBox(canvas, proj, lx + 0.55, 0.7, 0.78, o.Z, 0.28, 1.05, woodDarkF, woodDarkT, woodDarkS);
                DrawShadedBox(canvas, proj, lx + 0.1, 0.95, 1.02, o.Z, 2.4, 0.07, woodDarkF, woodDarkT, woodDarkS);
                break;

            case ObstacleKind.Overhead: // footbridge — roll under
                DrawShadedBox(canvas, proj, lx - 1.05, 0, 2.6, o.Z, 0.22, 0.22, woodF, woodT, woodS);
                DrawShadedBox(canvas, proj, lx + 1.05, 0, 2.6, o.Z, 0.22, 0.22, woodF, woodT, woodS);
                var q = DrawShadedBox(canvas, proj, lx, 1.72, 2.08, o.Z, 2.35, 0.9, woodF, woodT, woodS);
                if (q == null) return;
                StripeFrontFace(canvas, q, 5, woodDarkF);
                DrawShadedBox(canvas, proj, lx, 1.42, 1.72, o.Z, 0.05, 0.05, woodDarkF, woodDarkT, woodDarkS);
                var lp = proj(lx, 1.38, o.Z);
                if (lp != null)
                {
                    float ls = scaleAt(o.Z);
                    using var glow = new SKPaint { Color = warm.WithAlpha((byte)(255 * 0.25)), IsAntialias = true };
                    canvas.DrawCircle(lp.Value.X, lp.Value.Y, 0.34f * ls, glow);
                    using var lamp = new SKPaint { Color = warm, IsAntialias = true };
                    canvas.DrawCircle(lp.Value.X, lp.Value.Y, 0.14f * ls, lamp);
                }
                break;

            case ObstacleKind.Train: // paddle-wheeler — dodge!
                double depth = o.Depth;
                double zc = o.Z - depth / 2;
                if (DrawShadedBox(canvas, proj, lx, 0, 1.0, zc, 2.0, depth, hullF, hullT, hullS) == null) return;
                DrawShadedBox(canvas, proj, lx, 0, 0.9, zc - 2.4, 1.4, 1.2, hullF, hullT, hullS);
                var cq = DrawShadedBox(canvas, proj, lx, 1.0, 1.9, zc, 1.7, 4.6, cabinF, cabinT, cabinS);
                DrawShadedBox(canvas, proj, lx, 1.9, 2.02, zc, 1.9, 4.8, trimF, trimT, trimS);
                DrawShadedBox(canvas, proj, lx, 2.02, 2.7, zc, 1.4, 3.4, cabinF, cabinT, cabinS);
                DrawShadedBox(canvas, proj, lx, 2.7, 2.82, zc, 1.6, 3.6, trimF, trimT, trimS);
                if (cq != null)
                {
                    SKPoint FacePt(double fx, double fy) => Lerp(Lerp(cq[0], cq[1], fx), Lerp(cq[3], cq[2], fx), fy);
                    using var wp = new SKPaint { Color = warm };
                    foreach (var (a0, a1) in new[] { (0.14, 0.30), (0.42, 0.58), (0.70, 0.86) })
                    {
                        using var path = QuadPath(FacePt(a0, 0.3), FacePt(a1, 0.3), FacePt(a1, 0.62), FacePt(a0, 0.62));
                        canvas.DrawPath(path, wp);
                    }
                }
                double stackZ = zc - 1.2;
                DrawShadedBox(canvas, proj, lx - 0.4, 2.82, 4.1, stackZ, 0.36, 0.36, stackF, stackT, stackS);
                DrawShadedBox(canvas, proj, lx + 0.4, 2.82, 4.1, stackZ, 0.36, 0.36, stackF, stackT, stackS);
                DrawShadedBox(canvas, proj, lx - 0.4, 4.1, 4.25, stackZ, 0.48, 0.48, stackF, stackT, stackS);
                DrawShadedBox(canvas, proj, lx + 0.4, 4.1, 4.25, stackZ, 0.48, 0.48, stackF, stackT, stackS);
                float sSmoke = scaleAt(stackZ);
                using var smokeP = new SKPaint { Color = new SKColor(0xB0, 0xA8, 0x9C, (byte)(255 * 0.45)), IsAntialias = true };
                var puffX = new[] { lx - 0.4, lx + 0.4, lx };
                for (int i = 0; i < 3; i++)
                {
                    double px = puffX[i] + Math.Sin(tSec * 1.3 + i * 2.1) * 0.18;
                    var pp = proj(px, 4.55 + i * 0.38, stackZ);
                    if (pp != null) canvas.DrawCircle(pp.Value.X, pp.Value.Y, (float)((0.30 + i * 0.13) * sSmoke), smokeP);
                }
                double side = lx < 0 ? 1 : -1;
                var wp2 = proj(lx + side * 1.02, 0.95, zc);
                if (wp2 != null)
                {
                    float ws = scaleAt(zc);
                    float wr = 0.75f * ws;
                    using var wheelP = new SKPaint { Color = wheelRed, Style = SKPaintStyle.Stroke, StrokeWidth = 0.13f * ws, IsAntialias = true };
                    canvas.DrawCircle(wp2.Value.X, wp2.Value.Y, wr, wheelP);
                    using var spokeP = new SKPaint { Color = wheelRed, StrokeWidth = 0.07f * ws };
                    for (int i = 0; i < 4; i++)
                    {
                        double a = i * Math.PI / 4;
                        canvas.DrawLine(wp2.Value.X, wp2.Value.Y,
                            (float)(wp2.Value.X + Math.Cos(a) * wr), (float)(wp2.Value.Y + Math.Sin(a) * wr), spokeP);
                    }
                    using var hubP = new SKPaint { Color = wheelRed, IsAntialias = true };
                    canvas.DrawCircle(wp2.Value.X, wp2.Value.Y, 0.12f * ws, hubP);
                }
                break;
        }
    }

    private static void DrawCoin(SKCanvas canvas, ProjFn proj, Func<double, float> scaleAt,
        DeltaEngine.Coin c, double tSec)
    {
        double bobY = c.Y + Math.Sin(tSec * 3 + c.Z * 0.7) * 0.12;
        var p = proj(c.X, bobY, c.Z);
        if (p == null) return;
        float s = scaleAt(c.Z);
        float r = 0.42f * s;
        double spin = Math.Max(0.15, Math.Abs(Math.Cos(tSec * 6 + c.X * 2 + c.Z * 0.5)));
        using var gold = new SKPaint { Color = new SKColor(0xFF, 0xD5, 0x4F), IsAntialias = true };
        canvas.DrawOval(p.Value.X, p.Value.Y, (float)(r * spin), r, gold);
        using var shine = new SKPaint { Color = new SKColor(0xFF, 0xF5, 0x9D), IsAntialias = true };
        canvas.DrawOval(p.Value.X, p.Value.Y - r * 0.1f, (float)(r * 0.45 * spin), r * 0.45f, shine);
    }

    private static void DrawPowerUp(SKCanvas canvas, ProjFn proj, Func<double, float> scaleAt,
        DeltaEngine.PowerUp p)
    {
        var c = proj(p.X, 1.2, p.Z);
        if (c == null) return;
        float s = scaleAt(p.Z);
        float r = 0.55f * s;
        using var bg = new SKPaint { Color = new SKColor(0x2A, 0x1B, 0x4E), IsAntialias = true };
        canvas.DrawCircle(c.Value.X, c.Value.Y, r, bg);
        using var ring = new SKPaint { Color = new SKColor(0xFF, 0xD5, 0x4F), Style = SKPaintStyle.Stroke, StrokeWidth = r * 0.12f, IsAntialias = true };
        canvas.DrawCircle(c.Value.X, c.Value.Y, r, ring);
        if (p.Kind == PowerUpKind.Magnet)
        {
            using var mag = new SKPaint { Color = new SKColor(0xE5, 0x39, 0x35), Style = SKPaintStyle.Stroke, StrokeWidth = r * 0.36f };
            canvas.DrawArc(new SKRect(c.Value.X - r * 0.5f, c.Value.Y - r * 0.5f, c.Value.X + r * 0.5f, c.Value.Y + r * 0.5f), 180, 180, false, mag);
        }
        else
        {
            using var tp = new SKPaint
            {
                Color = new SKColor(0xFF, 0xD5, 0x4F),
                TextSize = r * 0.8f, IsAntialias = true, TextAlign = SKTextAlign.Center,
                Typeface = SKTypeface.FromFamilyName("Georgia", SKFontStyleWeight.Bold, SKFontStyleWidth.Normal, SKFontStyleSlant.Upright),
            };
            canvas.DrawText("2x", c.Value.X, c.Value.Y + r * 0.28f, tp);
        }
    }

    /// <summary>
    /// Draws the toon sprite (feet at feetY, centered on centerX, `size` tall),
    /// or a simple silhouette capsule when the sprite isn't bundled.
    /// </summary>
    public static void DrawCharacter(SKCanvas canvas, Dictionary<string, SKBitmap> sprites,
        string id, float centerX, float feetY, float size, bool rolling, double rollSpin)
    {
        if (sprites.TryGetValue(id, out var bmp) && bmp != null)
        {
            float dw = size * bmp.Width / (float)bmp.Height;
            float dh = size;
            canvas.Save();
            canvas.Translate(centerX, feetY - dh / 2);
            if (rolling) canvas.RotateDegrees((float)rollSpin);
            canvas.DrawBitmap(bmp, new SKRect(-dw / 2, -dh / 2, dw / 2, dh / 2));
            canvas.Restore();
        }
        else
        {
            // Fallback silhouette: ink capsule with cream face.
            using var body = new SKPaint { Color = new SKColor(0x1A, 0x1A, 0x1E), IsAntialias = true };
            float w = size * 0.55f;
            canvas.DrawRoundRect(new SKRect(centerX - w / 2, feetY - size, centerX + w / 2, feetY), size * 0.27f, size * 0.27f, body);
            using var face = new SKPaint { Color = new SKColor(0xF5, 0xEF, 0xE0), IsAntialias = true };
            canvas.DrawCircle(centerX, feetY - size * 0.78f, size * 0.14f, face);
        }
    }
}
