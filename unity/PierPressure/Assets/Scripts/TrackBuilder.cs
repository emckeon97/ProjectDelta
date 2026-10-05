using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Procedural world: wrapping wooden pier planks/posts/rails,
/// scrolling river plane, dusk lighting + fog, moon + stars,
/// riverside riverboat silhouette. World scrolls toward the
/// player (player stays near z=0).
/// </summary>
public class TrackBuilder : MonoBehaviour
{
    private readonly List<Transform> scrollers = new List<Transform>();
    private const float WrapLength = 160f;
    private const float KillZ = -10f;
    private Material riverMat;
    private float riverOffset;

    void Awake()
    {
        BuildLighting();
        BuildPier();
        BuildRiver();
        BuildSky();
        BuildRiverboat();
    }

    void Update()
    {
        float speed = 0f;
        GameManager gm = GameManager.Instance;
        if (gm != null)
        {
            if (gm.CurrentState == GameManager.State.Playing) speed = gm.Speed;
            else if (gm.CurrentState == GameManager.State.Menu) speed = 3f;
        }

        float dz = speed * Time.deltaTime;
        if (dz <= 0f) return;

        foreach (Transform t in scrollers)
        {
            Vector3 p = t.position;
            p.z -= dz;
            if (p.z < KillZ) p.z += WrapLength;
            t.position = p;
        }

        if (riverMat != null)
        {
            riverOffset = (riverOffset + dz * 0.015f) % 1f;
            riverMat.mainTextureOffset = new Vector2(0f, riverOffset);
        }
    }

    private static Material Flat(Color c)
    {
        Material m = new Material(Shader.Find("Standard"));
        m.color = c;
        m.SetFloat("_Glossiness", 0.1f);
        return m;
    }

    private void BuildLighting()
    {
        GameObject lightGO = GameObject.Find("Directional Light");
        if (lightGO != null)
        {
            Light l = lightGO.GetComponent<Light>();
            if (l != null)
            {
                l.transform.rotation = Quaternion.Euler(-48f, -32f, 0f);
                l.color = new Color(1f, 0.72f, 0.5f);
                l.intensity = 1.15f;
            }
        }
        RenderSettings.fog = true;
        RenderSettings.fogMode = FogMode.Exponential;
        RenderSettings.fogColor = new Color(0.14f, 0.08f, 0.2f);
        RenderSettings.fogDensity = 0.011f;
        RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
        RenderSettings.ambientSkyColor = new Color(0.35f, 0.22f, 0.4f);
        RenderSettings.ambientEquatorColor = new Color(0.25f, 0.16f, 0.3f);
        RenderSettings.ambientGroundColor = new Color(0.08f, 0.06f, 0.12f);
    }

    private void BuildPier()
    {
        Material wood = Flat(new Color(0.42f, 0.27f, 0.15f));
        Material woodDark = Flat(new Color(0.3f, 0.18f, 0.1f));
        Material postMat = Flat(new Color(0.25f, 0.15f, 0.08f));

        GameObject pier = new GameObject("Pier");
        pier.transform.SetParent(transform);

        int planks = 80;
        float spacing = WrapLength / planks;
        for (int i = 0; i < planks; i++)
        {
            GameObject p = GameObject.CreatePrimitive(PrimitiveType.Cube);
            p.name = "Plank";
            p.transform.SetParent(pier.transform);
            p.transform.localScale = new Vector3(7.6f, 0.25f, spacing * 0.85f);
            p.transform.position = new Vector3(Random.Range(-0.05f, 0.05f), 0f, KillZ + i * spacing);
            p.GetComponent<Renderer>().material = (i % 2 == 0) ? wood : woodDark;
            scrollers.Add(p.transform);
        }

        int posts = 20;
        for (int side = -1; side <= 1; side += 2)
        {
            for (int i = 0; i < posts; i++)
            {
                GameObject post = GameObject.CreatePrimitive(PrimitiveType.Cube);
                post.name = "Post";
                post.transform.SetParent(pier.transform);
                post.transform.localScale = new Vector3(0.35f, 1.6f, 0.35f);
                post.transform.position = new Vector3(side * 4.1f, 0.55f, KillZ + i * (WrapLength / posts));
                post.GetComponent<Renderer>().material = postMat;
                scrollers.Add(post.transform);
            }
            int railSegs = 8;
            float segLen = WrapLength / railSegs;
            for (int i = 0; i < railSegs; i++)
            {
                GameObject rail = GameObject.CreatePrimitive(PrimitiveType.Cube);
                rail.name = "Rail";
                rail.transform.SetParent(pier.transform);
                rail.transform.localScale = new Vector3(0.25f, 0.25f, segLen);
                rail.transform.position = new Vector3(side * 4.1f, 1.35f, KillZ + i * segLen + segLen * 0.5f);
                rail.GetComponent<Renderer>().material = postMat;
                scrollers.Add(rail.transform);
            }
        }
    }

    private void BuildRiver()
    {
        Texture2D tex = new Texture2D(128, 128, TextureFormat.RGBA32, false);
        for (int y = 0; y < 128; y++)
        {
            for (int x = 0; x < 128; x++)
            {
                float wave = Mathf.Sin((x + y * 3) * 0.15f) * 0.5f + 0.5f;
                float streak = Mathf.Pow(Mathf.Sin(y * 0.2f + Mathf.Sin(x * 0.1f)), 2f);
                Color c = new Color(0.05f + wave * 0.04f, 0.1f + wave * 0.05f, 0.22f + streak * 0.12f);
                tex.SetPixel(x, y, c);
            }
        }
        tex.wrapMode = TextureWrapMode.Repeat;
        tex.Apply();

        riverMat = new Material(Shader.Find("Standard"));
        riverMat.mainTexture = tex;
        riverMat.SetFloat("_Glossiness", 0.8f);
        riverMat.SetFloat("_Metallic", 0.3f);

        GameObject river = GameObject.CreatePrimitive(PrimitiveType.Plane);
        river.name = "River";
        river.transform.SetParent(transform);
        river.transform.localScale = new Vector3(40f, 1f, 60f);
        river.transform.position = new Vector3(0f, -1.6f, 140f);
        river.GetComponent<Renderer>().material = riverMat;
    }

    private void BuildSky()
    {
        GameObject sky = new GameObject("Sky");
        sky.transform.SetParent(transform);

        Material moonMat = Flat(Color.white);
        moonMat.SetColor("_EmissionColor", Color.white);
        moonMat.EnableKeyword("_EMISSION");
        GameObject moon = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        moon.name = "Moon";
        moon.transform.SetParent(sky.transform);
        moon.transform.localScale = Vector3.one * 10f;
        moon.transform.position = new Vector3(-45f, 55f, 220f);
        moon.GetComponent<Renderer>().material = moonMat;

        Material starMat = Flat(Color.white);
        starMat.SetColor("_EmissionColor", new Color(0.9f, 0.9f, 1f));
        starMat.EnableKeyword("_EMISSION");
        System.Random rng = new System.Random(7);
        for (int i = 0; i < 70; i++)
        {
            GameObject s = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            s.name = "Star";
            s.transform.SetParent(sky.transform);
            float sc = 0.3f + (float)rng.NextDouble() * 0.5f;
            s.transform.localScale = Vector3.one * sc;
            s.transform.position = new Vector3(
                (float)(rng.NextDouble() * 260.0 - 130.0),
                (float)(rng.NextDouble() * 80.0 + 25.0),
                (float)(rng.NextDouble() * 120.0 + 160.0));
            s.GetComponent<Renderer>().material = starMat;
        }
    }

    private void BuildRiverboat()
    {
        GameObject boat = new GameObject("Riverboat");
        boat.transform.SetParent(transform);

        Material hullMat = Flat(new Color(0.16f, 0.1f, 0.08f));
        Material trimMat = Flat(new Color(0.7f, 0.55f, 0.3f));

        GameObject hull = GameObject.CreatePrimitive(PrimitiveType.Cube);
        hull.transform.SetParent(boat.transform);
        hull.transform.localScale = new Vector3(9f, 3f, 22f);
        hull.transform.position = new Vector3(20f, 0f, 60f);
        hull.GetComponent<Renderer>().material = hullMat;

        GameObject cabin = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cabin.transform.SetParent(boat.transform);
        cabin.transform.localScale = new Vector3(6f, 2.5f, 14f);
        cabin.transform.position = new Vector3(20f, 2.7f, 60f);
        cabin.GetComponent<Renderer>().material = trimMat;

        for (int i = -1; i <= 1; i += 2)
        {
            GameObject ch = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            ch.transform.SetParent(boat.transform);
            ch.transform.localScale = new Vector3(1.2f, 4f, 1.2f);
            ch.transform.position = new Vector3(20f + i * 1.8f, 5.5f, 56f);
            ch.GetComponent<Renderer>().material = hullMat;
        }

        scrollers.Add(boat.transform);
    }
}
