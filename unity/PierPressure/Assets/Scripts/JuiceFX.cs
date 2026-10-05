using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;

/// <summary>
/// Juice: pooled coin sparkles, landing dust, trauma-based screen shake
/// (runs after the camera follow via execution order), speed-lines
/// overlay at high velocity, confetti burst on a new high score.
/// </summary>
[DefaultExecutionOrder(100)]
public class JuiceFX : MonoBehaviour
{
    private class Particle
    {
        public GameObject go;
        public Renderer rend;
        public Material mat;
        public Vector3 vel;
        public float life;
        public float maxLife;
        public float grow;
        public float gravity;
        public float baseSize;
        public bool active;
    }

    private class Confetto
    {
        public Image img;
        public Vector2 vel;
        public float life;
        public float maxLife;
        public float spin;
        public bool active;
    }

    private readonly List<Particle> sparkles = new List<Particle>();
    private readonly List<Particle> dust = new List<Particle>();
    private readonly List<Confetto> confetti = new List<Confetto>();

    private float trauma;
    private int lastCoins;
    private float lastYPos;
    private GameManager.State prevState = GameManager.State.Menu;

    private Image speedLines;
    private Canvas fxCanvas;

    void Start()
    {
        fxCanvas = new GameObject("FXCanvas").AddComponent<Canvas>();
        fxCanvas.transform.SetParent(transform, false);
        fxCanvas.renderMode = RenderMode.ScreenSpaceOverlay;
        fxCanvas.sortingOrder = 6;
        fxCanvas.gameObject.AddComponent<CanvasScaler>();
        fxCanvas.gameObject.AddComponent<GraphicRaycaster>();
        BuildSpeedLines();

        for (int i = 0; i < 24; i++) sparkles.Add(MakeParticle(0.16f));
        for (int i = 0; i < 16; i++) dust.Add(MakeParticle(0.3f));
        BuildConfetti();

        GameManager gm = GameManager.Instance;
        if (gm != null) { lastCoins = gm.Coins; prevState = gm.CurrentState; }
        PlayerController pc = PlayerController.Instance;
        if (pc != null) lastYPos = pc.BoundsCenter.y - pc.Height * 0.5f;
    }

    void Update()
    {
        GameManager gm = GameManager.Instance;
        PlayerController pc = PlayerController.Instance;
        if (gm == null) return;

        // Death: shake + maybe confetti.
        if (prevState == GameManager.State.Playing && gm.CurrentState == GameManager.State.GameOver)
        {
            trauma = 1f;
            if (gm.Score > 0 && gm.Score >= gm.HighScore) ConfettiBurst();
        }
        prevState = gm.CurrentState;

        // Coin collected: sparkle at the player.
        if (gm.Coins > lastCoins && pc != null)
        {
            Burst(sparkles, new Vector3(pc.XPos, 1.2f, 0f),
                new Color(1f, 0.85f, 0.25f), 6, 4f, 0.45f, 0.5f, 6f);
            lastCoins = gm.Coins;
        }

        // Landing: dust puff.
        if (pc != null)
        {
            float y = pc.BoundsCenter.y - pc.Height * 0.5f;
            if (lastYPos > 0.25f && y <= 0.01f)
                Burst(dust, new Vector3(pc.XPos, 0.15f, 0f),
                    new Color(0.75f, 0.65f, 0.5f), 5, 2.5f, 0.7f, 2.2f, -2f);
            lastYPos = y;
        }

        UpdateParticles(sparkles);
        UpdateParticles(dust);
        UpdateConfetti();

        // Speed lines fade in with velocity.
        if (speedLines != null)
        {
            float a = 0f;
            if (gm.CurrentState == GameManager.State.Playing)
                a = Mathf.Clamp01((gm.Speed - 17f) / 13f);
            Color c = speedLines.color;
            c.a = a * (0.28f + 0.12f * Mathf.Sin(Time.time * 28f));
            speedLines.color = c;
        }
    }

    void LateUpdate()
    {
        if (trauma <= 0f) return;
        Camera cam = Camera.main;
        if (cam == null) return;
        trauma = Mathf.Max(0f, trauma - Time.deltaTime * 1.4f);
        float s = trauma * trauma * 0.7f;
        cam.transform.position += new Vector3(
            (Random.value - 0.5f) * s, (Random.value - 0.5f) * s, 0f);
        cam.transform.rotation *= Quaternion.Euler(0f, 0f, (Random.value - 0.5f) * s * 5f);
    }

    // ---------- particles ----------

    private Particle MakeParticle(float size)
    {
        GameObject go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        go.name = "FXParticle";
        go.transform.SetParent(transform, false);
        go.transform.localScale = Vector3.one * size;
        Material m = TransparentMat(Color.white);
        go.GetComponent<Renderer>().material = m;
        go.SetActive(false);
        return new Particle { go = go, rend = go.GetComponent<Renderer>(), mat = m, active = false, baseSize = size };
    }

    private static Material TransparentMat(Color c)
    {
        Material m = new Material(Shader.Find("Standard"));
        m.SetFloat("_Mode", 3f);
        m.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        m.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        m.SetInt("_ZWrite", 0);
        m.DisableKeyword("_ALPHATEST_ON");
        m.EnableKeyword("_ALPHABLEND_ON");
        m.DisableKeyword("_ALPHAPREMULTIPLY_ON");
        m.renderQueue = 3000;
        m.color = c;
        return m;
    }

    private void Burst(List<Particle> pool, Vector3 pos, Color color,
        int count, float speed, float life, float grow, float gravity)
    {
        int spawned = 0;
        foreach (Particle p in pool)
        {
            if (p.active) continue;
            p.active = true;
            p.go.SetActive(true);
            p.go.transform.position = pos;
            p.go.transform.localScale = Vector3.one * p.baseSize;
            p.mat.color = color;
            float a = Random.value * Mathf.PI * 2f;
            p.vel = new Vector3(Mathf.Cos(a) * speed * Random.Range(0.4f, 1f),
                Random.Range(0.5f, 1.2f) * speed * 0.6f,
                Mathf.Sin(a) * speed * Random.Range(0.4f, 1f));
            p.life = p.maxLife = life * Random.Range(0.7f, 1.2f);
            p.grow = grow;
            p.gravity = gravity;
            if (++spawned >= count) break;
        }
    }

    private void UpdateParticles(List<Particle> pool)
    {
        foreach (Particle p in pool)
        {
            if (!p.active) continue;
            p.life -= Time.deltaTime;
            if (p.life <= 0f)
            {
                p.active = false;
                p.go.SetActive(false);
                continue;
            }
            p.vel.y -= p.gravity * Time.deltaTime;
            p.go.transform.position += p.vel * Time.deltaTime;
            float baseSize = p.go.transform.localScale.x;
            p.go.transform.localScale = Vector3.one * (baseSize + p.grow * Time.deltaTime);
            Color c = p.mat.color;
            c.a = Mathf.Clamp01(p.life / p.maxLife);
            p.mat.color = c;
        }
    }

    // ---------- speed lines ----------

    private void BuildSpeedLines()
    {
        int s = 256;
        Texture2D tex = new Texture2D(s, s, TextureFormat.RGBA32, false);
        for (int y = 0; y < s; y++)
            for (int x = 0; x < s; x++)
                tex.SetPixel(x, y, Color.clear);
        System.Random rng = new System.Random(42);
        for (int i = 0; i < 30; i++)
        {
            float ang = (float)(i / 30.0 * Mathf.PI * 2.0 + rng.NextDouble() * 0.2);
            float dx = Mathf.Cos(ang), dy = Mathf.Sin(ang);
            for (float r = 50f; r < 125f; r += 2f)
            {
                int x = (int)(s / 2 + dx * r), y = (int)(s / 2 + dy * r);
                float alpha = Mathf.Clamp01(1f - (r - 50f) / 75f) * 0.8f;
                for (int ox = -1; ox <= 1; ox++)
                    for (int oy = -1; oy <= 1; oy++)
                    {
                        int px = x + ox, py = y + oy;
                        if (px >= 0 && px < s && py >= 0 && py < s)
                            tex.SetPixel(px, py, new Color(1f, 1f, 1f, alpha));
                    }
            }
        }
        tex.Apply();

        GameObject go = new GameObject("SpeedLines");
        go.transform.SetParent(fxCanvas.transform, false);
        speedLines = go.AddComponent<Image>();
        speedLines.sprite = Sprite.Create(tex, new Rect(0f, 0f, s, s), new Vector2(0.5f, 0.5f));
        speedLines.color = new Color(1f, 1f, 1f, 0f);
        speedLines.raycastTarget = false;
        RectTransform rt = go.GetComponent<RectTransform>();
        rt.anchorMin = Vector2.zero;
        rt.anchorMax = Vector2.one;
        rt.offsetMin = Vector2.zero;
        rt.offsetMax = Vector2.zero;
    }

    // ---------- confetti ----------

    private void BuildConfetti()
    {
        Color[] palette = new Color[]
        {
            new Color(1f, 0.3f, 0.3f), new Color(0.3f, 0.8f, 1f),
            new Color(1f, 0.85f, 0.3f), new Color(0.5f, 1f, 0.5f),
            new Color(1f, 0.5f, 0.9f), new Color(1f, 1f, 1f),
        };
        for (int i = 0; i < 48; i++)
        {
            GameObject go = new GameObject("Confetto");
            go.transform.SetParent(fxCanvas.transform, false);
            Image img = go.AddComponent<Image>();
            img.color = palette[i % palette.Length];
            img.raycastTarget = false;
            RectTransform rt = go.GetComponent<RectTransform>();
            rt.sizeDelta = new Vector2(14f, 10f);
            go.SetActive(false);
            confetti.Add(new Confetto { img = img, active = false });
        }
    }

    private void ConfettiBurst()
    {
        foreach (Confetto c in confetti)
        {
            c.active = true;
            c.img.gameObject.SetActive(true);
            RectTransform rt = c.img.GetComponent<RectTransform>();
            rt.anchoredPosition = new Vector2(Random.Range(-120f, 120f), 260f);
            c.vel = new Vector2(Random.Range(-260f, 260f), Random.Range(-60f, 160f));
            c.life = c.maxLife = Random.Range(1.8f, 2.8f);
            c.spin = Random.Range(-360f, 360f);
            Color col = c.img.color;
            col.a = 1f;
            c.img.color = col;
        }
    }

    private void UpdateConfetti()
    {
        foreach (Confetto c in confetti)
        {
            if (!c.active) continue;
            c.life -= Time.deltaTime;
            if (c.life <= 0f)
            {
                c.active = false;
                c.img.gameObject.SetActive(false);
                continue;
            }
            RectTransform rt = c.img.GetComponent<RectTransform>();
            c.vel.y -= 500f * Time.deltaTime;
            c.vel.x *= (1f - 0.6f * Time.deltaTime);
            rt.anchoredPosition += c.vel * Time.deltaTime;
            rt.rotation = Quaternion.Euler(0f, 0f, rt.rotation.eulerAngles.z + c.spin * Time.deltaTime);
            Color col = c.img.color;
            col.a = Mathf.Clamp01(c.life / c.maxLife * 1.5f);
            c.img.color = col;
        }
    }
}
