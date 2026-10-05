using UnityEngine;

/// <summary>
/// Builds the entire game world procedurally at runtime.
/// The scene contains only a camera, this marker, and a light;
/// everything else is constructed here so no hand-authored
/// scene/prefab YAML is required.
/// </summary>
public class Bootstrap : MonoBehaviour
{
    void Awake()
    {
        GameObject root = new GameObject("Game");

        GameObject audio = new GameObject("AudioSynth");
        audio.transform.SetParent(root.transform);
        audio.AddComponent<AudioSynth>();

        GameObject gm = new GameObject("GameManager");
        gm.transform.SetParent(root.transform);
        gm.AddComponent<GameManager>();

        GameObject track = new GameObject("TrackBuilder");
        track.transform.SetParent(root.transform);
        track.AddComponent<TrackBuilder>();

        GameObject player = new GameObject("Player");
        player.transform.SetParent(root.transform);
        player.AddComponent<PlayerController>();

        GameObject spawner = new GameObject("ObstacleSpawner");
        spawner.transform.SetParent(root.transform);
        spawner.AddComponent<ObstacleSpawner>();

        GameObject coins = new GameObject("CoinManager");
        coins.transform.SetParent(root.transform);
        coins.AddComponent<CoinManager>();

        GameObject ui = new GameObject("UIManager");
        ui.transform.SetParent(root.transform);
        ui.AddComponent<UIManager>();

        GameObject cameos = new GameObject("CameoManager");
        cameos.transform.SetParent(root.transform);
        cameos.AddComponent<CameoManager>();

        GameObject juice = new GameObject("JuiceFX");
        juice.transform.SetParent(root.transform);
        juice.AddComponent<JuiceFX>();
    }
}
