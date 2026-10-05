using UnityEngine;

/// <summary>
/// 12-character roster with coin unlocks, sprite loading (with
/// procedural fallbacks), player + cameo visual construction.
/// Sprites load from Resources/Characters/&lt;id&gt; if present;
/// anything missing falls back to per-character colored primitives.
/// </summary>
public static class CharacterFactory
{
    public class CharacterData
    {
        public string id;
        public string displayName;
        public int cost;
        public Color theme;
        public bool hasSprite;
        public CharacterData(string id, string displayName, int cost, Color theme, bool hasSprite)
        {
            this.id = id; this.displayName = displayName; this.cost = cost;
            this.theme = theme; this.hasSprite = hasSprite;
        }
    }

    public static readonly CharacterData[] Roster = new CharacterData[]
    {
        new CharacterData("popeye", "Popeye",     0, new Color(0.15f, 0.35f, 0.75f), true),
        new CharacterData("felix",  "Felix",     500, new Color(0.12f, 0.12f, 0.14f), true),
        new CharacterData("oswald", "Oswald",   1000, new Color(0.2f, 0.25f, 0.45f), true),
        new CharacterData("minnie", "Minnie",   1500, new Color(0.85f, 0.25f, 0.35f), false),
        new CharacterData("mickey", "Mickey",   2500, new Color(0.8f, 0.15f, 0.15f), false),
        new CharacterData("koko",   "Koko",     3000, new Color(0.9f, 0.9f, 0.92f), true),
        new CharacterData("bimbo",  "Bimbo",    4000, new Color(0.95f, 0.85f, 0.6f), true),
        new CharacterData("pooh",   "Pooh",     5000, new Color(0.85f, 0.6f, 0.25f), true),
        new CharacterData("olive",  "Olive",    6500, new Color(0.3f, 0.5f, 0.25f), true),
        new CharacterData("bosko",  "Bosko",    8000, new Color(0.45f, 0.3f, 0.2f), true),
        new CharacterData("betty",  "Betty",   10000, new Color(0.9f, 0.5f, 0.7f), false),
        new CharacterData("pete",   "Peg-Leg Pete", 12000, new Color(0.5f, 0.2f, 0.15f), true),
    };

    private const string KeyOwnedPrefix = "PierPressure_CharOwned_";
    private const string KeySelected = "PierPressure_SelectedChar";

    public static string SelectedId
    {
        get { return PlayerPrefs.GetString(KeySelected, "popeye"); }
        private set { PlayerPrefs.SetString(KeySelected, value); PlayerPrefs.Save(); }
    }

    public static CharacterData GetData(string id)
    {
        foreach (CharacterData c in Roster)
            if (c.id == id) return c;
        return Roster[0];
    }

    public static bool IsOwned(string id)
    {
        if (id == "popeye") return true;
        return PlayerPrefs.GetInt(KeyOwnedPrefix + id, 0) == 1;
    }

    public static bool Buy(string id)
    {
        CharacterData d = GetData(id);
        if (IsOwned(id)) return true;
        GameManager gm = GameManager.Instance;
        if (gm == null) return false;
        if (!gm.SpendCoins(d.cost)) return false;
        PlayerPrefs.SetInt(KeyOwnedPrefix + id, 1);
        PlayerPrefs.Save();
        if (AudioSynth.Instance != null) AudioSynth.Instance.Play("powerup");
        return true;
    }

    public static void Select(string id)
    {
        if (!IsOwned(id)) return;
        SelectedId = id;
        if (AudioSynth.Instance != null) AudioSynth.Instance.Play("click");
    }

    /// <summary>Player visual for the currently selected character (rear view).</summary>
    public static GameObject CreatePlayerVisual()
    {
        return BuildCharacter(SelectedId, "PlayerVisual");
    }

    /// <summary>Sideline cameo visual; deterministic pick from roster by index.</summary>
    public static GameObject CreateCameoVisual(int index)
    {
        System.Random rng = new System.Random(1000 + index * 77);
        CharacterData d = Roster[rng.Next(Roster.Length)];
        GameObject go = BuildCharacter(d.id, "CameoVisual_" + index);
        go.AddComponent<WaveCameo>();
        return go;
    }

    private static GameObject BuildCharacter(string id, string name)
    {
        CharacterData d = GetData(id);
        GameObject root = new GameObject(name);

        Sprite sprite = null;
        if (d.hasSprite)
            sprite = Resources.Load<Sprite>("Characters/" + d.id);

        if (sprite != null)
        {
            // Billboarded rear-view quad (texture faces the camera at -z).
            GameObject quad = GameObject.CreatePrimitive(PrimitiveType.Quad);
            quad.name = "Sprite";
            quad.transform.SetParent(root.transform, false);
            quad.transform.rotation = Quaternion.Euler(0f, 180f, 0f);
            quad.transform.localScale = new Vector3(1.5f, 1.8f, 1f);
            quad.transform.localPosition = new Vector3(0f, 0.95f, 0f);
            Material m = new Material(Shader.Find("Sprites/Default"));
            m.mainTexture = sprite.texture;
            quad.GetComponent<Renderer>().material = m;
        }
        else
        {
            BuildPrimitiveToon(root, d);
        }
        return root;
    }

    /// <summary>
    /// Procedural 1930s rubber-hose toon: capsule body, sphere head,
    /// white pie-cut eyes with pupils, round ears. Faces -z (rear view
    /// shows the back of the head; eyes peek for charm).
    /// </summary>
    private static void BuildPrimitiveToon(GameObject root, CharacterData d)
    {
        Material bodyMat = ToonMat(d.theme);
        Material skinMat = ToonMat(new Color(0.98f, 0.87f, 0.72f));
        Material whiteMat = ToonMat(Color.white);
        Material blackMat = ToonMat(Color.black);

        GameObject body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
        body.name = "Body";
        body.transform.SetParent(root.transform, false);
        body.transform.localPosition = new Vector3(0f, 0.75f, 0f);
        body.transform.localScale = new Vector3(0.85f, 0.85f, 0.85f);
        body.GetComponent<Renderer>().material = bodyMat;

        GameObject head = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        head.name = "Head";
        head.transform.SetParent(root.transform, false);
        head.transform.localPosition = new Vector3(0f, 1.55f, 0.05f);
        head.transform.localScale = Vector3.one * 0.62f;
        head.GetComponent<Renderer>().material = skinMat;

        for (int side = -1; side <= 1; side += 2)
        {
            GameObject ear = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            ear.name = "Ear";
            ear.transform.SetParent(root.transform, false);
            ear.transform.localPosition = new Vector3(side * 0.3f, 1.78f, 0.05f);
            ear.transform.localScale = Vector3.one * 0.22f;
            ear.GetComponent<Renderer>().material = bodyMat;

            // Pie-cut eyes peeking over the shoulder line (visible from rear).
            GameObject eye = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            eye.name = "Eye";
            eye.transform.SetParent(root.transform, false);
            eye.transform.localPosition = new Vector3(side * 0.14f, 1.62f, -0.24f);
            eye.transform.localScale = new Vector3(0.16f, 0.2f, 0.08f);
            eye.GetComponent<Renderer>().material = whiteMat;

            GameObject pupil = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            pupil.name = "Pupil";
            pupil.transform.SetParent(root.transform, false);
            pupil.transform.localPosition = new Vector3(side * 0.14f, 1.62f, -0.29f);
            pupil.transform.localScale = Vector3.one * 0.07f;
            pupil.GetComponent<Renderer>().material = blackMat;
        }
    }

    private static Material ToonMat(Color c)
    {
        Material m = new Material(Shader.Find("Standard"));
        m.color = c;
        m.SetFloat("_Glossiness", 0.35f);
        return m;
    }
}

/// <summary>Billboard: keeps a quad facing the main camera.</summary>
public class Billboard : MonoBehaviour
{
    void LateUpdate()
    {
        Camera cam = Camera.main;
        if (cam == null) return;
        transform.rotation = Quaternion.LookRotation(transform.position - cam.transform.position);
    }
}

/// <summary>Sideline cameo wave: gentle side-to-side rock.</summary>
public class WaveCameo : MonoBehaviour
{
    private float phase;
    void Start() { phase = Random.value * 6.28f; }
    void Update()
    {
        float w = Mathf.Sin(Time.time * 3.5f + phase);
        transform.rotation = Quaternion.Euler(0f, 180f, w * 22f);
    }
}
