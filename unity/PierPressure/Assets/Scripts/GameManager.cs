using UnityEngine;
using UnityEngine.UI;

/// <summary>
/// Game state machine, scoring, speed ramp, persistence.
/// Phase 1: a minimal debug HUD (legacy UGUI Text + built-in Arial, no assets).
/// Phase 2 replaces it with the real marquee menu UI.
/// </summary>
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    public enum State { Menu, Playing, GameOver, Paused }
    public State CurrentState { get; private set; } = State.Menu;

    public float Distance { get; private set; }
    public int Coins { get; private set; }
    public int HighScore { get; private set; }
    public int TotalCoins { get; private set; }
    public float Speed { get; private set; }
    public float ScoreMultiplier { get; set; } = 1f;

    /// <summary>
    /// When true (set by UIManager), menu/game-over taps are consumed by
    /// the UI and GameManager no longer auto-starts on any tap.
    /// </summary>
    public static bool UiConsumeTaps = false;

    public int Score => (int)(Distance * ScoreMultiplier) + Coins * 5;

    private const float BaseSpeed = 10f;
    private const float MaxSpeed = 30f;
    private const float RampPerMeter = 0.022f;

    private const string KeyHigh = "PierPressure_HighScore";
    private const string KeyCoins = "PierPressure_TotalCoins";

    private Text hudText;

    void Awake()
    {
        Instance = this;
        HighScore = PlayerPrefs.GetInt(KeyHigh, 0);
        TotalCoins = PlayerPrefs.GetInt(KeyCoins, 0);
        Speed = BaseSpeed;
        BuildDebugHud();
    }

    void Update()
    {
        switch (CurrentState)
        {
            case State.Menu:
                if (!UiConsumeTaps && TapPressed()) StartGame();
                break;
            case State.Playing:
                Distance += Speed * Time.deltaTime;
                Speed = Mathf.Min(MaxSpeed, BaseSpeed + Distance * RampPerMeter);
                if (Input.GetKeyDown(KeyCode.Escape) || Input.GetKeyDown(KeyCode.P))
                {
                    CurrentState = State.Paused;
                    Time.timeScale = 0f;
                }
                break;
            case State.Paused:
                if (Input.GetKeyDown(KeyCode.Escape) || Input.GetKeyDown(KeyCode.P))
                {
                    CurrentState = State.Playing;
                    Time.timeScale = 1f;
                }
                break;
            case State.GameOver:
                if (!UiConsumeTaps && TapPressed()) StartGame();
                break;
        }
        UpdateHud();
    }

    public void StartGame()
    {
        Distance = 0f;
        Coins = 0;
        Speed = BaseSpeed;
        ScoreMultiplier = 1f;
        Time.timeScale = 1f;
        if (PlayerController.Instance != null) PlayerController.Instance.ResetPlayer();
        if (ObstacleSpawner.Instance != null) ObstacleSpawner.Instance.ResetSpawner();
        if (CoinManager.Instance != null) CoinManager.Instance.ResetCoins();
        CurrentState = State.Playing;
        if (AudioSynth.Instance != null) AudioSynth.Instance.Play("click");
    }

    public void OnPlayerDied()
    {
        if (CurrentState != State.Playing) return;
        CurrentState = State.GameOver;
        if (AudioSynth.Instance != null) AudioSynth.Instance.Play("crash");
        int s = Score;
        if (s > HighScore)
        {
            HighScore = s;
            PlayerPrefs.SetInt(KeyHigh, HighScore);
        }
        PlayerPrefs.SetInt(KeyCoins, TotalCoins);
        PlayerPrefs.Save();
    }

    public void AddCoins(int n)
    {
        Coins += n;
        TotalCoins += n;
    }

    /// <summary>Spend banked coins (character unlocks). Returns false if broke.</summary>
    public bool SpendCoins(int n)
    {
        if (TotalCoins < n) return false;
        TotalCoins -= n;
        PlayerPrefs.SetInt(KeyCoins, TotalCoins);
        PlayerPrefs.Save();
        return true;
    }

    public void PauseGame()
    {
        if (CurrentState != State.Playing) return;
        CurrentState = State.Paused;
        Time.timeScale = 0f;
    }

    public void ResumeGame()
    {
        if (CurrentState != State.Paused) return;
        CurrentState = State.Playing;
        Time.timeScale = 1f;
    }

    public void QuitToMenu()
    {
        CurrentState = State.Menu;
        Time.timeScale = 1f;
        Distance = 0f;
        Coins = 0;
        Speed = BaseSpeed;
        ScoreMultiplier = 1f;
        if (PlayerController.Instance != null) PlayerController.Instance.ResetPlayer();
        if (ObstacleSpawner.Instance != null) ObstacleSpawner.Instance.ResetSpawner();
        if (CoinManager.Instance != null) CoinManager.Instance.ResetCoins();
    }

    private bool TapPressed()
    {
        if (Input.GetMouseButtonDown(0)) return true;
        if (Input.touchCount > 0 && Input.GetTouch(0).phase == TouchPhase.Began) return true;
        if (Input.GetKeyDown(KeyCode.Space) || Input.GetKeyDown(KeyCode.Return)) return true;
        return false;
    }

    private void BuildDebugHud()
    {
        GameObject canvasGO = new GameObject("DebugHUD");
        canvasGO.transform.SetParent(transform);
        Canvas canvas = canvasGO.AddComponent<Canvas>();
        canvas.renderMode = RenderMode.ScreenSpaceOverlay;

        GameObject textGO = new GameObject("HudText");
        textGO.transform.SetParent(canvasGO.transform, false);
        hudText = textGO.AddComponent<Text>();
        Font arial = Resources.GetBuiltinResource<Font>("Arial.ttf");
        if (arial != null) hudText.font = arial;
        hudText.fontSize = 26;
        hudText.color = Color.white;
        hudText.alignment = TextAnchor.UpperLeft;
        RectTransform rt = textGO.GetComponent<RectTransform>();
        rt.anchorMin = new Vector2(0f, 1f);
        rt.anchorMax = new Vector2(1f, 1f);
        rt.offsetMin = new Vector2(12f, -190f);
        rt.offsetMax = new Vector2(-12f, -12f);
    }

    private void UpdateHud()
    {
        if (hudText == null) return;
        string extra = "";
        CoinManager cm = CoinManager.Instance;
        if (cm != null)
        {
            if (cm.IsMagnetActive) extra += "  MAGNET " + cm.MagnetTimeLeft.ToString("0") + "s";
            if (cm.IsDoubleActive) extra += "  2X " + cm.DoubleTimeLeft.ToString("0") + "s";
        }
        string prompt = CurrentState == State.Menu ? "[Tap / Space] to start"
            : CurrentState == State.GameOver ? "[Tap / Space] to retry"
            : CurrentState == State.Paused ? "PAUSED - [Esc] resume"
            : "Arrows/WASD move - [Esc] pause";
        hudText.text = CurrentState + "\n"
            + "Score " + Score + "   Best " + HighScore + "\n"
            + "Coins " + Coins + " (bank " + TotalCoins + ")   Speed " + Speed.ToString("0.0") + extra + "\n"
            + prompt;
    }
}
