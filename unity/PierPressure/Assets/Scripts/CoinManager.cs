using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Pooled spinning coins (lines + arcs) and magnet / 2x power-ups.
/// Manual collection checks; magnet pulls nearby coins to the player.
/// </summary>
public class CoinManager : MonoBehaviour
{
    public static CoinManager Instance { get; private set; }

    private class Coin
    {
        public GameObject go;
        public bool active;
    }

    private class PUp
    {
        public GameObject go;
        public bool active;
        public bool isMagnet;
        public float bob;
    }

    private readonly List<Coin> coins = new List<Coin>();
    private readonly List<PUp> pups = new List<PUp>();

    private Material coinMat;
    private Material magnetMat;
    private Material doubleMat;

    private float coinTimer = 2f;
    private float pupTimer = 20f;

    public bool IsMagnetActive { get; private set; }
    public bool IsDoubleActive { get; private set; }
    public float MagnetTimeLeft { get; private set; }
    public float DoubleTimeLeft { get; private set; }

    private const float PowerDuration = 8f;
    private const float SpawnZ = 70f;
    private const float DespawnZ = -12f;

    void Awake()
    {
        Instance = this;

        coinMat = new Material(Shader.Find("Standard"));
        coinMat.color = new Color(1f, 0.8f, 0.15f);
        coinMat.SetColor("_EmissionColor", new Color(0.6f, 0.45f, 0.05f));
        coinMat.EnableKeyword("_EMISSION");

        magnetMat = new Material(Shader.Find("Standard"));
        magnetMat.color = new Color(0.2f, 0.5f, 1f);
        magnetMat.SetColor("_EmissionColor", new Color(0.1f, 0.25f, 0.8f));
        magnetMat.EnableKeyword("_EMISSION");

        doubleMat = new Material(Shader.Find("Standard"));
        doubleMat.color = new Color(0.2f, 1f, 0.4f);
        doubleMat.SetColor("_EmissionColor", new Color(0.1f, 0.7f, 0.2f));
        doubleMat.EnableKeyword("_EMISSION");

        for (int i = 0; i < 48; i++)
        {
            GameObject go = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            go.name = "Coin";
            go.transform.localScale = new Vector3(0.7f, 0.24f, 0.7f);
            go.transform.rotation = Quaternion.Euler(90f, 0f, 0f);
            go.GetComponent<Renderer>().material = coinMat;
            go.SetActive(false);
            coins.Add(new Coin { go = go, active = false });
        }

        for (int i = 0; i < 4; i++)
        {
            GameObject go = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            go.name = "PowerUp";
            go.GetComponent<Renderer>().material = (i % 2 == 0) ? magnetMat : doubleMat;
            go.SetActive(false);
            pups.Add(new PUp { go = go, active = false, isMagnet = (i % 2 == 0), bob = Random.value * 6f });
        }
    }

    void Update()
    {
        GameManager gm = GameManager.Instance;
        if (gm == null || gm.CurrentState != GameManager.State.Playing) return;
        float speed = gm.Speed;
        float dz = speed * Time.deltaTime;

        PlayerController pc = PlayerController.Instance;
        float playerX = pc != null ? pc.XPos : 0f;
        Vector3 magnetTarget = new Vector3(playerX, 1f, 0f);

        coinTimer -= Time.deltaTime;
        if (coinTimer <= 0f)
        {
            SpawnCoinRow();
            coinTimer = Random.Range(1.2f, 2.6f) * (12f / speed);
        }
        pupTimer -= Time.deltaTime;
        if (pupTimer <= 0f)
        {
            SpawnPowerUp();
            pupTimer = Random.Range(25f, 45f);
        }

        if (IsMagnetActive)
        {
            MagnetTimeLeft -= Time.deltaTime;
            if (MagnetTimeLeft <= 0f) IsMagnetActive = false;
        }
        if (IsDoubleActive)
        {
            DoubleTimeLeft -= Time.deltaTime;
            if (DoubleTimeLeft <= 0f)
            {
                IsDoubleActive = false;
                gm.ScoreMultiplier = 1f;
            }
        }

        foreach (Coin c in coins)
        {
            if (!c.active) continue;
            Transform t = c.go.transform;

            if (IsMagnetActive && pc != null && Vector3.Distance(t.position, magnetTarget) < 8f)
                t.position = Vector3.MoveTowards(t.position, magnetTarget, 22f * Time.deltaTime);
            else
                t.position = new Vector3(t.position.x, t.position.y, t.position.z - dz);

            t.Rotate(0f, 220f * Time.deltaTime, 0f, Space.World);

            if (t.position.z < DespawnZ)
            {
                c.active = false;
                c.go.SetActive(false);
                continue;
            }

            if (pc != null
                && Mathf.Abs(t.position.x - playerX) < 0.9f
                && Mathf.Abs(t.position.z) < 0.9f
                && Mathf.Abs(t.position.y - 1f) < 1.4f)
            {
                c.active = false;
                c.go.SetActive(false);
                gm.AddCoins(1);
                if (AudioSynth.Instance != null) AudioSynth.Instance.Play("coin");
            }
        }

        foreach (PUp p in pups)
        {
            if (!p.active) continue;
            Transform t = p.go.transform;
            t.position = new Vector3(t.position.x, t.position.y, t.position.z - dz);
            p.bob += Time.deltaTime * 3f;
            t.position = new Vector3(t.position.x, 1.3f + Mathf.Sin(p.bob) * 0.25f, t.position.z);

            if (t.position.z < DespawnZ)
            {
                p.active = false;
                p.go.SetActive(false);
                continue;
            }

            if (pc != null && Mathf.Abs(t.position.x - playerX) < 1f && Mathf.Abs(t.position.z) < 1f)
            {
                p.active = false;
                p.go.SetActive(false);
                if (p.isMagnet)
                {
                    IsMagnetActive = true;
                    MagnetTimeLeft = PowerDuration;
                }
                else
                {
                    IsDoubleActive = true;
                    DoubleTimeLeft = PowerDuration;
                    gm.ScoreMultiplier = 2f;
                }
                if (AudioSynth.Instance != null) AudioSynth.Instance.Play("powerup");
            }
        }
    }

    public void ResetCoins()
    {
        foreach (Coin c in coins)
        {
            c.active = false;
            c.go.SetActive(false);
        }
        foreach (PUp p in pups)
        {
            p.active = false;
            p.go.SetActive(false);
        }
        IsMagnetActive = false;
        IsDoubleActive = false;
        MagnetTimeLeft = 0f;
        DoubleTimeLeft = 0f;
        if (GameManager.Instance != null) GameManager.Instance.ScoreMultiplier = 1f;
        coinTimer = 2f;
        pupTimer = 20f;
    }

    private void SpawnCoinRow()
    {
        PlayerController pc = PlayerController.Instance;
        if (pc == null) return;
        int lane = Random.Range(0, 3);
        float x = pc.LaneX[lane];
        int count = Random.Range(6, 10);
        bool arc = Random.value < 0.35f;
        for (int i = 0; i < count; i++)
        {
            Coin c = FreeCoin();
            if (c == null) return;
            float y = 1f;
            if (arc) y = 1f + Mathf.Sin((float)i / (count - 1) * Mathf.PI) * 1.6f;
            c.go.transform.position = new Vector3(x, y, SpawnZ + i * 2f);
            c.go.SetActive(true);
            c.active = true;
        }
    }

    private void SpawnPowerUp()
    {
        PlayerController pc = PlayerController.Instance;
        if (pc == null) return;
        foreach (PUp p in pups)
        {
            if (p.active) continue;
            int lane = Random.Range(0, 3);
            p.go.transform.position = new Vector3(pc.LaneX[lane], 1.3f, SpawnZ);
            p.go.SetActive(true);
            p.active = true;
            return;
        }
    }

    private Coin FreeCoin()
    {
        foreach (Coin c in coins)
            if (!c.active) return c;
        return null;
    }
}
