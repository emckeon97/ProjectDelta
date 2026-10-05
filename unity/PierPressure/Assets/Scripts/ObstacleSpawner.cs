using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Pooled obstacles, all procedural primitives, manual AABB collision.
/// Rowboat = jump over. Footbridge = roll under. Paddle-wheeler = change lanes.
/// Spawn rows always leave at least one passable lane.
/// </summary>
public class ObstacleSpawner : MonoBehaviour
{
    public static ObstacleSpawner Instance { get; private set; }

    public enum ObType { Rowboat, Footbridge, PaddleWheeler }

    private class Ob
    {
        public GameObject go;
        public ObType type;
        public int lane;
        public bool active;
        public Vector3 size;
        public float centerY;
    }

    private readonly List<Ob> pool = new List<Ob>();
    private float spawnTimer = 1.5f;

    private const float SpawnZ = 70f;
    private const float DespawnZ = -12f;

    private Material woodMat;
    private Material darkMat;
    private Material bridgeMat;

    void Awake()
    {
        Instance = this;
        woodMat = Flat(new Color(0.45f, 0.28f, 0.15f));
        darkMat = Flat(new Color(0.2f, 0.12f, 0.08f));
        bridgeMat = Flat(new Color(0.5f, 0.35f, 0.2f));

        for (int i = 0; i < 10; i++) pool.Add(MakeOb(ObType.Rowboat));
        for (int i = 0; i < 8; i++) pool.Add(MakeOb(ObType.Footbridge));
        for (int i = 0; i < 8; i++) pool.Add(MakeOb(ObType.PaddleWheeler));
    }

    void Update()
    {
        GameManager gm = GameManager.Instance;
        if (gm == null || gm.CurrentState != GameManager.State.Playing) return;
        float speed = gm.Speed;

        spawnTimer -= Time.deltaTime;
        if (spawnTimer <= 0f)
        {
            SpawnRow();
            spawnTimer = Random.Range(0.8f, 1.5f) * (12f / speed);
        }

        PlayerController pc = PlayerController.Instance;
        Vector3 pCenter = pc != null ? pc.BoundsCenter : Vector3.zero;
        Vector3 pSize = pc != null ? pc.BoundsSize : Vector3.zero;

        foreach (Ob ob in pool)
        {
            if (!ob.active) continue;
            Transform t = ob.go.transform;
            t.position = new Vector3(t.position.x, t.position.y, t.position.z - speed * Time.deltaTime);

            if (t.position.z < DespawnZ)
            {
                ob.active = false;
                ob.go.SetActive(false);
                continue;
            }

            if (pc != null)
            {
                Vector3 oCenter = new Vector3(t.position.x, ob.centerY, t.position.z);
                if (AabbOverlap(pCenter, pSize, oCenter, ob.size))
                {
                    gm.OnPlayerDied();
                    return;
                }
            }
        }
    }

    public void ResetSpawner()
    {
        foreach (Ob ob in pool)
        {
            ob.active = false;
            ob.go.SetActive(false);
        }
        spawnTimer = 1.5f;
    }

    private void SpawnRow()
    {
        PlayerController pc = PlayerController.Instance;
        if (pc == null) return;

        int lanesToBlock = Random.Range(1, 3); // 1 or 2, never 3
        List<int> lanes = new List<int> { 0, 1, 2 };
        for (int i = 0; i < lanes.Count; i++)
        {
            int j = Random.Range(i, lanes.Count);
            int tmp = lanes[i];
            lanes[i] = lanes[j];
            lanes[j] = tmp;
        }

        for (int i = 0; i < lanesToBlock; i++)
        {
            ObType type = (ObType)Random.Range(0, 3);
            SpawnOb(type, lanes[i]);
        }
    }

    private void SpawnOb(ObType type, int lane)
    {
        PlayerController pc = PlayerController.Instance;
        foreach (Ob ob in pool)
        {
            if (ob.active || ob.type != type) continue;
            ob.lane = lane;
            ob.go.transform.position = new Vector3(pc.LaneX[lane], 0f, SpawnZ + Random.Range(0f, 4f));
            ob.go.SetActive(true);
            ob.active = true;
            return;
        }
    }

    private Ob MakeOb(ObType type)
    {
        GameObject go = new GameObject("Ob_" + type);
        go.transform.SetParent(transform);
        Ob ob = new Ob { go = go, type = type, active = false };

        switch (type)
        {
            case ObType.Rowboat:
                {
                    GameObject hull = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    hull.transform.SetParent(go.transform);
                    hull.transform.localScale = new Vector3(1.8f, 0.7f, 1.1f);
                    hull.transform.localPosition = new Vector3(0f, 0.35f, 0f);
                    hull.GetComponent<Renderer>().material = woodMat;
                    GameObject inner = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    inner.transform.SetParent(go.transform);
                    inner.transform.localScale = new Vector3(1.4f, 0.5f, 0.8f);
                    inner.transform.localPosition = new Vector3(0f, 0.6f, 0f);
                    inner.GetComponent<Renderer>().material = darkMat;
                    ob.size = new Vector3(1.8f, 0.9f, 1.1f);
                    ob.centerY = 0.45f;
                }
                break;
            case ObType.Footbridge:
                {
                    for (int s = -1; s <= 1; s += 2)
                    {
                        GameObject post = GameObject.CreatePrimitive(PrimitiveType.Cube);
                        post.transform.SetParent(go.transform);
                        post.transform.localScale = new Vector3(0.25f, 2.4f, 0.25f);
                        post.transform.localPosition = new Vector3(s * 0.95f, 1.2f, 0f);
                        post.GetComponent<Renderer>().material = bridgeMat;
                    }
                    GameObject beam = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    beam.transform.SetParent(go.transform);
                    beam.transform.localScale = new Vector3(2.2f, 1.0f, 1.2f);
                    beam.transform.localPosition = new Vector3(0f, 1.8f, 0f);
                    beam.GetComponent<Renderer>().material = bridgeMat;
                    ob.size = new Vector3(2.0f, 1.0f, 1.2f);
                    ob.centerY = 1.8f;
                }
                break;
            case ObType.PaddleWheeler:
                {
                    GameObject body = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    body.transform.SetParent(go.transform);
                    body.transform.localScale = new Vector3(2.0f, 3.0f, 2.0f);
                    body.transform.localPosition = new Vector3(0f, 1.5f, 0f);
                    body.GetComponent<Renderer>().material = darkMat;
                    GameObject stack = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                    stack.transform.SetParent(go.transform);
                    stack.transform.localScale = new Vector3(0.6f, 1.5f, 0.6f);
                    stack.transform.localPosition = new Vector3(0f, 3.6f, -0.4f);
                    stack.GetComponent<Renderer>().material = woodMat;
                    ob.size = new Vector3(2.0f, 3.0f, 2.0f);
                    ob.centerY = 1.5f;
                }
                break;
        }

        go.SetActive(false);
        return ob;
    }

    private static bool AabbOverlap(Vector3 c1, Vector3 s1, Vector3 c2, Vector3 s2)
    {
        return Mathf.Abs(c1.x - c2.x) < (s1.x + s2.x) * 0.5f
            && Mathf.Abs(c1.y - c2.y) < (s1.y + s2.y) * 0.5f
            && Mathf.Abs(c1.z - c2.z) < (s1.z + s2.z) * 0.5f;
    }

    private static Material Flat(Color c)
    {
        Material m = new Material(Shader.Find("Standard"));
        m.color = c;
        m.SetFloat("_Glossiness", 0.2f);
        return m;
    }
}
