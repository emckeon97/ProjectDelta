using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Full procedural uGUI: 1930s marquee main menu (chasing light bulbs,
/// blinking INSERT COIN), character-select grid with coin unlocks,
/// how-to-play, HUD, pause menu, game-over screen.
/// Ticket-booth styling: dark wood panels + brass trim, cream text.
/// Replaces GameManager's phase-1 debug HUD and owns all menu taps.
/// </summary>
public class UIManager : MonoBehaviour
{
    public static UIManager Instance { get; private set; }

    private enum MenuTab { Main, Chars, HowTo }
    private MenuTab menuTab = MenuTab.Main;

    private Canvas menuCanvas, charsCanvas, howToCanvas, hudCanvas, pauseCanvas, gameOverCanvas;
    private Text hudScore, hudCoins, hudBest, hudPower;
    private Text gameOverScore, gameOverBest, newBestBanner;
    private Image[] bulbsTop, bulbsBottom;
    private Text insertCoinText;
    private Text menuStatsText;
    private Transform cardGrid;
    private Font arial;

    private static readonly Color Wood = new Color(0.23f, 0.13f, 0.07f);
    private static readonly Color WoodLight = new Color(0.35f, 0.21f, 0.11f);
    private static readonly Color Brass = new Color(0.78f, 0.6f, 0.28f);
    private static readonly Color BrassDim = new Color(0.4f, 0.3f, 0.15f);
    private static readonly Color Cream = new Color(0.96f, 0.9f, 0.78f);
    private static readonly Color MarqueeRed = new Color(0.75f, 0.16f, 0.14f);

    void Awake()
    {
        Instance = this;
        GameManager.UiConsumeTaps = true;
    }

    void Start()
    {
        arial = Resources.GetBuiltinResource<Font>("Arial.ttf");
        // Remove the phase-1 debug HUD; the real HUD replaces it.
        GameObject gmGO = GameObject.Find("GameManager");
        if (gmGO != null)
        {
            Transform hud = gmGO.transform.Find("DebugHUD");
            if (hud != null) Destroy(hud.gameObject);
        }

        BuildMenu();
        BuildChars();
        BuildHowTo();
        BuildHud();
        BuildPause();
        BuildGameOver();
        RefreshCards();
    }

    void Update()
    {
        GameManager gm = GameManager.Instance;
        if (gm == null) return;
        GameManager.State s = gm.CurrentState;

        menuCanvas.gameObject.SetActive(s == GameManager.State.Menu && menuTab == MenuTab.Main);
        charsCanvas.gameObject.SetActive(s == GameManager.State.Menu && menuTab == MenuTab.Chars);
        howToCanvas.gameObject.SetActive(s == GameManager.State.Menu && menuTab == MenuTab.HowTo);
        hudCanvas.gameObject.SetActive(s == GameManager.State.Playing || s == GameManager.State.Paused);
        pauseCanvas.gameObject.SetActive(s == GameManager.State.Paused);
        gameOverCanvas.gameObject.SetActive(s == GameManager.State.GameOver);

        if (menuCanvas.gameObject.activeSelf) AnimateMarquee();

        if (menuTab == MenuTab.Main) UpdateMenuStats();

        if (hudCanvas.gameObject.activeSelf)
        {
            hudScore.text = gm.Score.ToString();
            hudCoins.text = gm.Coins.ToString();
            hudBest.text = "BEST " + gm.HighScore;
            string p = "";
            CoinManager cm = CoinManager.Instance;
            if (cm != null)
            {
                if (cm.IsMagnetActive) p += "MAGNET " + cm.MagnetTimeLeft.ToString("0") + "s  ";
                if (cm.IsDoubleActive) p += "2X " + cm.DoubleTimeLeft.ToString("0") + "s";
            }
            hudPower.text = p;
        }

        if (gameOverCanvas.gameObject.activeSelf)
        {
            gameOverScore.text = "SCORE  " + gm.Score;
            gameOverBest.text = "BEST  " + gm.HighScore;
            bool isBest = gm.Score > 0 && gm.Score >= gm.HighScore;
            newBestBanner.gameObject.SetActive(isBest);
        }
    }

    // ---------- construction helpers ----------

    private Canvas MakeCanvas(string name, int sortOrder)
    {
        GameObject go = new GameObject(name);
        go.transform.SetParent(transform, false);
        Canvas c = go.AddComponent<Canvas>();
        c.renderMode = RenderMode.ScreenSpaceOverlay;
        c.sortingOrder = sortOrder;
        CanvasScaler scaler = go.AddComponent<CanvasScaler>();
        scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
        scaler.referenceResolution = new Vector2(1280f, 720f);
        go.AddComponent<GraphicRaycaster>();
        go.SetActive(false);
        return c;
    }

    private Text MakeText(Transform parent, string content, int size, Color color,
        float x, float y, float w = 600f, float h = 60f,
        TextAnchor anchor = TextAnchor.MiddleCenter)
    {
        GameObject go = new GameObject("Text");
        go.transform.SetParent(parent, false);
        Text t = go.AddComponent<Text>();
        if (arial != null) t.font = arial;
        t.text = content;
        t.fontSize = size;
        t.color = color;
        t.alignment = anchor;
        t.fontStyle = FontStyle.Bold;
        RectTransform rt = go.GetComponent<RectTransform>();
        rt.anchoredPosition = new Vector2(x, y);
        rt.sizeDelta = new Vector2(w, h);
        return t;
    }

    private Image MakePanel(Transform parent, Color color, float x, float y, float w, float h)
    {
        GameObject go = new GameObject("Panel");
        go.transform.SetParent(parent, false);
        Image img = go.AddComponent<Image>();
        img.color = color;
        RectTransform rt = go.GetComponent<RectTransform>();
        rt.anchoredPosition = new Vector2(x, y);
        rt.sizeDelta = new Vector2(w, h);
        return img;
    }

    private Button MakeButton(Transform parent, string label, float x, float y,
        float w, float h, UnityEngine.Events.UnityAction onClick, int fontSize = 30)
    {
        // Brass backing slightly larger than the wood face = ticket-booth trim.
        MakePanel(parent, Brass, x, y, w + 10f, h + 10f);
        GameObject go = new GameObject("Button_" + label);
        go.transform.SetParent(parent, false);
        Image face = go.AddComponent<Image>();
        face.color = WoodLight;
        Button b = go.AddComponent<Button>();
        ColorBlock cb = b.colors;
        cb.pressedColor = MarqueeRed;
        cb.highlightedColor = new Color(0.45f, 0.28f, 0.15f);
        b.colors = cb;
        b.onClick.AddListener(onClick);
        b.onClick.AddListener(() => { if (AudioSynth.Instance != null) AudioSynth.Instance.Play("click"); });
        RectTransform rt = go.GetComponent<RectTransform>();
        rt.anchoredPosition = new Vector2(x, y);
        rt.sizeDelta = new Vector2(w, h);
        MakeText(go.transform, label, fontSize, Cream, 0f, 0f, w, h);
        return b;
    }

    private Texture2D circleTex;
    private Texture2D CircleTexture()
    {
        if (circleTex != null) return circleTex;
        int s = 48;
        circleTex = new Texture2D(s, s, TextureFormat.RGBA32, false);
        for (int y = 0; y < s; y++)
            for (int x = 0; x < s; x++)
            {
                float dx = (x - s / 2f) / (s / 2f);
                float dy = (y - s / 2f) / (s / 2f);
                float d = Mathf.Sqrt(dx * dx + dy * dy);
                circleTex.SetPixel(x, y, d <= 1f ? Color.white : Color.clear);
            }
        circleTex.Apply();
        return circleTex;
    }

    // ---------- main menu ----------

    private void BuildMenu()
    {
        menuCanvas = MakeCanvas("MenuCanvas", 10);
        Transform t = menuCanvas.transform;

        MakeText(t, "PIER PRESSURE", 110, Cream, 0f, 190f, 1100f, 140f);

        bulbsTop = MakeBulbRow(t, 300f);
        bulbsBottom = MakeBulbRow(t, 80f);

        insertCoinText = MakeText(t, "- INSERT COIN -", 34, Brass, 0f, -40f, 600f, 50f);

        MakeButton(t, "PLAY", 0f, -140f, 320f, 80f, () =>
        {
            menuTab = MenuTab.Main;
            GameManager.Instance.StartGame();
        }, 40);
        MakeButton(t, "CHARACTERS", 0f, -240f, 320f, 70f, () =>
        {
            menuTab = MenuTab.Chars;
            RefreshCards();
        });
        MakeButton(t, "HOW TO PLAY", 0f, -330f, 320f, 70f, () => { menuTab = MenuTab.HowTo; });

        GameManager gm = GameManager.Instance;
        menuStatsText = MakeText(t, "", 26,
            new Color(0.8f, 0.75f, 0.65f), 0f, -420f, 800f, 40f);
        UpdateMenuStats();
    }

    private Image[] MakeBulbRow(Transform parent, float y)
    {
        int n = 16;
        Image[] bulbs = new Image[n];
        for (int i = 0; i < n; i++)
        {
            GameObject go = new GameObject("Bulb");
            go.transform.SetParent(parent, false);
            Image img = go.AddComponent<Image>();
            img.sprite = Sprite.Create(CircleTexture(),
                new Rect(0f, 0f, 48f, 48f), new Vector2(0.5f, 0.5f));
            img.color = BrassDim;
            RectTransform rt = go.GetComponent<RectTransform>();
            rt.anchoredPosition = new Vector2(-525f + i * 70f, y);
            rt.sizeDelta = new Vector2(30f, 30f);
            bulbs[i] = img;
        }
        return bulbs;
    }

    private void AnimateMarquee()
    {
        int step = (int)(Time.time * 10f);
        for (int i = 0; i < bulbsTop.Length; i++)
        {
            bool lit = ((step + i) % bulbsTop.Length) < 3;
            Color c = lit ? new Color(1f, 0.85f, 0.4f) : BrassDim;
            bulbsTop[i].color = c;
            bulbsBottom[bulbsBottom.Length - 1 - i].color = c;
        }
        float blink = Mathf.Sin(Time.time * 5f) > 0f ? 1f : 0.25f;
        insertCoinText.color = new Color(Brass.r, Brass.g, Brass.b, blink);
    }

    private void UpdateMenuStats()
    {
        if (menuStatsText == null) return;
        GameManager gm = GameManager.Instance;
        if (gm == null) return;
        menuStatsText.text = "BEST " + gm.HighScore + "   •   COINS " + gm.TotalCoins;
    }

    // ---------- character select ----------

    private void BuildChars()
    {
        charsCanvas = MakeCanvas("CharsCanvas", 11);
        Transform t = charsCanvas.transform;

        MakePanel(t, new Color(0f, 0f, 0f, 0.55f), 0f, 0f, 2000f, 1200f);
        MakeText(t, "CHOOSE YOUR TOON", 54, Cream, 0f, 300f, 900f, 70f);

        GameObject gridGO = new GameObject("CardGrid");
        gridGO.transform.SetParent(t, false);
        GridLayoutGroup grid = gridGO.AddComponent<GridLayoutGroup>();
        grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
        grid.constraintCount = 4;
        grid.cellSize = new Vector2(220f, 150f);
        grid.spacing = new Vector2(18f, 18f);
        grid.childAlignment = TextAnchor.MiddleCenter;
        RectTransform grt = gridGO.GetComponent<RectTransform>();
        grt.anchoredPosition = new Vector2(0f, 40f);
        grt.sizeDelta = new Vector2(980f, 500f);
        cardGrid = gridGO.transform;

        for (int i = 0; i < CharacterFactory.Roster.Length; i++)
        {
            CharacterFactory.CharacterData d = CharacterFactory.Roster[i];
            string id = d.id;

            GameObject cardGO = new GameObject("Card_" + id);
            cardGO.transform.SetParent(cardGrid, false);
            Image cardImg = cardGO.AddComponent<Image>();
            cardImg.color = WoodLight;
            Button b = cardGO.AddComponent<Button>();
            ColorBlock cb = b.colors;
            cb.highlightedColor = new Color(0.45f, 0.28f, 0.15f);
            cb.pressedColor = MarqueeRed;
            b.colors = cb;
            b.onClick.AddListener(() => OnCardClicked(id));

            // Portrait swatch.
            GameObject sw = new GameObject("Swatch");
            sw.transform.SetParent(cardGO.transform, false);
            Image swImg = sw.AddComponent<Image>();
            swImg.color = d.theme;
            RectTransform srt = sw.GetComponent<RectTransform>();
            srt.anchoredPosition = new Vector2(-70f, 0f);
            srt.sizeDelta = new Vector2(70f, 110f);
            MakeText(sw.transform, d.displayName.Substring(0, 1), 44, Cream, 0f, 0f, 70f, 110f);

            MakeText(cardGO.transform, d.displayName, 24, Cream, 45f, 35f, 200f, 36f, TextAnchor.MiddleLeft);
            Text status = MakeText(cardGO.transform, "", 24, Brass, 45f, -35f, 200f, 36f, TextAnchor.MiddleLeft);
            status.name = "Status";
        }

        MakeButton(t, "BACK", 0f, -300f, 240f, 64f, () => { menuTab = MenuTab.Main; });
    }

    private void OnCardClicked(string id)
    {
        if (CharacterFactory.SelectedId == id) return;
        if (CharacterFactory.IsOwned(id))
        {
            CharacterFactory.Select(id);
        }
        else
        {
            if (CharacterFactory.Buy(id))
                CharacterFactory.Select(id);
            else
            {
                if (AudioSynth.Instance != null) AudioSynth.Instance.Play("crash");
                RefreshCards();
                return;
            }
        }
        if (PlayerController.Instance != null) PlayerController.Instance.RebuildVisual();
        RefreshCards();
    }

    private void RefreshCards()
    {
        if (cardGrid == null) return;
        foreach (Transform card in cardGrid)
        {
            string id = card.gameObject.name.Substring("Card_".Length);
            CharacterFactory.CharacterData d = CharacterFactory.GetData(id);
            Text status = card.Find("Status").GetComponent<Text>();
            Image img = card.GetComponent<Image>();
            if (CharacterFactory.SelectedId == id)
            {
                status.text = "SELECTED";
                status.color = new Color(0.4f, 1f, 0.5f);
                img.color = new Color(0.42f, 0.26f, 0.13f);
            }
            else if (CharacterFactory.IsOwned(id))
            {
                status.text = "OWNED";
                status.color = Brass;
                img.color = WoodLight;
            }
            else
            {
                GameManager gm = GameManager.Instance;
                bool afford = gm != null && gm.TotalCoins >= d.cost;
                status.text = d.cost + " COINS";
                status.color = afford ? new Color(1f, 0.85f, 0.4f) : new Color(0.6f, 0.55f, 0.5f);
                img.color = WoodLight;
            }
        }
    }

    // ---------- how to play ----------

    private void BuildHowTo()
    {
        howToCanvas = MakeCanvas("HowToCanvas", 11);
        Transform t = howToCanvas.transform;

        MakePanel(t, new Color(0f, 0f, 0f, 0.55f), 0f, 0f, 2000f, 1200f);
        MakePanel(t, Wood, 0f, 0f, 760f, 520f);
        MakeText(t, "HOW TO PLAY", 48, Cream, 0f, 210f, 700f, 60f);
        MakeText(t,
            "Swipe LEFT / RIGHT (or A/D, arrows) to change lanes\n" +
            "Swipe UP (or W / SPACE) to JUMP the rowboats\n" +
            "Swipe DOWN (or S) to ROLL under footbridges\n" +
            "Dodge the paddle-wheelers — switch lanes!\n\n" +
            "Grab coins, magnet and 2x multiplier power-ups.\n" +
            "Spend coins to unlock all 12 toons.\n" +
            "ESC pauses. How far down the pier can you get?",
            26, Cream, 0f, -30f, 700f, 400f, TextAnchor.MiddleCenter);
        MakeButton(t, "BACK", 0f, -300f, 240f, 64f, () => { menuTab = MenuTab.Main; });
    }

    // ---------- HUD ----------

    private void BuildHud()
    {
        hudCanvas = MakeCanvas("HudCanvas", 5);
        Transform t = hudCanvas.transform;

        hudScore = MakeText(t, "0", 64, Cream, 0f, 310f, 400f, 80f);
        hudBest = MakeText(t, "BEST 0", 24, new Color(0.8f, 0.75f, 0.65f), 480f, 310f, 300f, 40f, TextAnchor.MiddleRight);

        GameObject coinIcon = new GameObject("CoinIcon");
        coinIcon.transform.SetParent(t, false);
        Image ci = coinIcon.AddComponent<Image>();
        ci.sprite = Sprite.Create(CircleTexture(), new Rect(0f, 0f, 48f, 48f), new Vector2(0.5f, 0.5f));
        ci.color = new Color(1f, 0.8f, 0.15f);
        RectTransform cirt = coinIcon.GetComponent<RectTransform>();
        cirt.anchoredPosition = new Vector2(-560f, 310f);
        cirt.sizeDelta = new Vector2(36f, 36f);
        hudCoins = MakeText(t, "0", 40, Cream, -480f, 310f, 200f, 50f, TextAnchor.MiddleLeft);

        hudPower = MakeText(t, "", 28, new Color(0.5f, 0.9f, 1f), 0f, 240f, 600f, 40f);

        MakeButton(t, "II", 590f, 250f, 64f, 56f, () =>
        {
            GameManager gm = GameManager.Instance;
            if (gm != null) gm.PauseGame();
        }, 28);
    }

    // ---------- pause ----------

    private void BuildPause()
    {
        pauseCanvas = MakeCanvas("PauseCanvas", 20);
        Transform t = pauseCanvas.transform;

        MakePanel(t, new Color(0f, 0f, 0f, 0.6f), 0f, 0f, 2000f, 1200f);
        MakePanel(t, Wood, 0f, 0f, 460f, 420f);
        MakeText(t, "PAUSED", 54, Cream, 0f, 130f, 440f, 70f);
        MakeButton(t, "RESUME", 0f, 30f, 300f, 70f, () => GameManager.Instance.ResumeGame());
        MakeButton(t, "RESTART", 0f, -60f, 300f, 70f, () => GameManager.Instance.StartGame());
        MakeButton(t, "MENU", 0f, -150f, 300f, 70f, () =>
        {
            menuTab = MenuTab.Main;
            GameManager.Instance.QuitToMenu();
        });
    }

    // ---------- game over ----------

    private void BuildGameOver()
    {
        gameOverCanvas = MakeCanvas("GameOverCanvas", 20);
        Transform t = gameOverCanvas.transform;

        MakePanel(t, new Color(0f, 0f, 0f, 0.55f), 0f, 0f, 2000f, 1200f);
        MakePanel(t, Wood, 0f, 0f, 520f, 480f);
        MakeText(t, "GAME OVER", 64, MarqueeRed, 0f, 160f, 500f, 80f);
        gameOverScore = MakeText(t, "SCORE  0", 40, Cream, 0f, 70f, 500f, 50f);
        gameOverBest = MakeText(t, "BEST  0", 32, new Color(0.8f, 0.75f, 0.65f), 0f, 15f, 500f, 44f);
        newBestBanner = MakeText(t, "★ NEW BEST! ★", 40, new Color(1f, 0.85f, 0.4f), 0f, -45f, 500f, 50f);
        MakeButton(t, "RESTART", 0f, -130f, 300f, 70f, () => GameManager.Instance.StartGame());
        MakeButton(t, "MENU", 0f, -220f, 300f, 70f, () =>
        {
            menuTab = MenuTab.Main;
            GameManager.Instance.QuitToMenu();
        });
    }
}
