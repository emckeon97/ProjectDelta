using UnityEngine;
using System.Collections.Generic;

/// <summary>
/// Three random non-player characters waving from the pier sidelines
/// and the riverboat. They scroll with the world and wrap around,
/// mirroring TrackBuilder's scroll length.
/// </summary>
public class CameoManager : MonoBehaviour
{
    private readonly List<Transform> cameos = new List<Transform>();
    private const float WrapLength = 160f;
    private const float KillZ = -10f;

    void Start()
    {
        // Two on the pier sidelines (outside the rails), one on the riverboat.
        PlaceCameo(0, new Vector3(-5.6f, 0.15f, 18f));
        PlaceCameo(1, new Vector3(5.6f, 0.15f, 34f));
        PlaceCameo(2, new Vector3(20f, 4.05f, 60f));
    }

    private void PlaceCameo(int index, Vector3 pos)
    {
        GameObject go = CharacterFactory.CreateCameoVisual(index);
        go.transform.SetParent(transform, false);
        go.transform.position = pos;
        go.transform.localScale = Vector3.one * 1.1f;
        cameos.Add(go.transform);
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
        foreach (Transform t in cameos)
        {
            Vector3 p = t.position;
            p.z -= dz;
            if (p.z < KillZ) p.z += WrapLength;
            t.position = p;
        }
    }
}
