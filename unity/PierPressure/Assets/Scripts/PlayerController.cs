using UnityEngine;

/// <summary>
/// 3-lane runner player: swipe + keyboard lane change (with lean),
/// jump, roll, squash-and-stretch, rear-view camera follow.
/// Manual AABB collision data exposed for the spawner.
/// </summary>
public class PlayerController : MonoBehaviour
{
    public static PlayerController Instance { get; private set; }

    public readonly float[] LaneX = new float[] { -2.2f, 0f, 2.2f };
    public int Lane { get; private set; } = 1;
    public float XPos => xPos;
    public bool IsRolling => rollTimer > 0f;

    private float xPos;
    private float yPos;
    private float yVel;
    private float rollTimer;

    private const float RollDuration = 0.7f;
    private const float Gravity = -32f;
    private const float JumpVel = 11.5f;
    private const float LaneMoveSpeed = 14f;

    private GameObject visual;
    private Vector3 squashScale = Vector3.one;
    private float squashTimer;

    private Camera cam;

    private Vector2 pressStart;
    private bool pressing;

    public float Height => IsRolling ? 0.7f : 1.7f;
    public Vector3 BoundsCenter => new Vector3(xPos, yPos + Height * 0.5f, 0f);
    public Vector3 BoundsSize => new Vector3(0.9f, Height, 0.9f);

    void Awake()
    {
        Instance = this;
        visual = CharacterFactory.CreatePlayerVisual();
        visual.transform.SetParent(transform, false);
        visual.transform.localPosition = Vector3.zero;
        cam = Camera.main;
        if (cam == null) cam = Object.FindFirstObjectByType<Camera>();
        ResetPlayer();
    }

    public void ResetPlayer()
    {
        Lane = 1;
        xPos = 0f;
        yPos = 0f;
        yVel = 0f;
        rollTimer = 0f;
        squashTimer = 0f;
        squashScale = Vector3.one;
        transform.position = new Vector3(0f, 0f, 0f);
    }

    /// <summary>Rebuild the character visual (called when the player picks a new toon).</summary>
    public void RebuildVisual()
    {
        if (visual != null) Object.Destroy(visual);
        visual = CharacterFactory.CreatePlayerVisual();
        visual.transform.SetParent(transform, false);
        visual.transform.localPosition = Vector3.zero;
    }

    void Update()
    {
        GameManager gm = GameManager.Instance;
        bool playing = gm != null && gm.CurrentState == GameManager.State.Playing;
        if (playing) HandleInput();

        // Lane movement toward target.
        float targetX = LaneX[Lane];
        xPos = Mathf.MoveTowards(xPos, targetX, LaneMoveSpeed * Time.deltaTime);

        // Jump physics.
        if (yPos > 0f || yVel != 0f)
        {
            yVel += Gravity * Time.deltaTime;
            yPos += yVel * Time.deltaTime;
            if (yPos <= 0f)
            {
                yPos = 0f;
                yVel = 0f;
                LandSquash();
            }
        }

        if (rollTimer > 0f) rollTimer -= Time.deltaTime;

        if (squashTimer > 0f)
        {
            squashTimer -= Time.deltaTime;
            if (squashTimer <= 0f) squashScale = Vector3.one;
        }

        transform.position = new Vector3(xPos, yPos, 0f);

        // Lean into lane changes.
        float leanAngle = Mathf.Clamp((xPos - targetX) * 0.25f, -0.45f, 0.45f);
        visual.transform.rotation = Quaternion.Euler(0f, 0f, leanAngle * 57.29578f);

        // Squash & stretch / roll pose.
        Vector3 s = squashScale;
        if (IsRolling) s = new Vector3(1.2f, 0.55f, 1.2f);
        else if (yPos > 0.05f) s = new Vector3(0.88f, 1.18f, 0.88f);
        visual.transform.localScale = s;
    }

    void LateUpdate()
    {
        if (cam == null) return;
        cam.transform.position = new Vector3(xPos * 0.55f, 4.6f + yPos * 0.35f, -7.5f);
        cam.transform.LookAt(new Vector3(xPos * 0.7f, 1.6f, 10f));
    }

    private void HandleInput()
    {
        if (Input.GetKeyDown(KeyCode.LeftArrow) || Input.GetKeyDown(KeyCode.A)) MoveLane(-1);
        if (Input.GetKeyDown(KeyCode.RightArrow) || Input.GetKeyDown(KeyCode.D)) MoveLane(1);
        if (Input.GetKeyDown(KeyCode.UpArrow) || Input.GetKeyDown(KeyCode.W) || Input.GetKeyDown(KeyCode.Space)) DoJump();
        if (Input.GetKeyDown(KeyCode.DownArrow) || Input.GetKeyDown(KeyCode.S)) DoRoll();

        if (Input.touchCount > 0)
        {
            Touch t = Input.GetTouch(0);
            if (t.phase == TouchPhase.Began) { pressStart = t.position; pressing = true; }
            else if (t.phase == TouchPhase.Ended && pressing)
            {
                pressing = false;
                HandleSwipe(t.position - pressStart);
            }
            else if (t.phase == TouchPhase.Canceled) pressing = false;
        }

        if (Input.GetMouseButtonDown(0)) { pressStart = Input.mousePosition; pressing = true; }
        else if (Input.GetMouseButtonUp(0) && pressing)
        {
            pressing = false;
            HandleSwipe((Vector2)Input.mousePosition - pressStart);
        }
    }

    private void HandleSwipe(Vector2 delta)
    {
        if (delta.magnitude < 40f) return; // tap: ignored during play
        if (Mathf.Abs(delta.x) > Mathf.Abs(delta.y))
            MoveLane(delta.x > 0f ? 1 : -1);
        else if (delta.y > 0f) DoJump();
        else DoRoll();
    }

    private void MoveLane(int dir)
    {
        Lane = Mathf.Clamp(Lane + dir, 0, 2);
    }

    private void DoJump()
    {
        if (yPos > 0.001f || IsRolling) return;
        yVel = JumpVel;
        squashScale = new Vector3(0.85f, 1.25f, 0.85f);
        squashTimer = 0.18f;
        if (AudioSynth.Instance != null) AudioSynth.Instance.Play("jump");
    }

    private void DoRoll()
    {
        if (yPos > 0.001f)
        {
            yVel = -22f; // slam down fast
            return;
        }
        rollTimer = RollDuration;
        if (AudioSynth.Instance != null) AudioSynth.Instance.Play("click");
    }

    private void LandSquash()
    {
        squashScale = new Vector3(1.3f, 0.65f, 1.3f);
        squashTimer = 0.16f;
    }
}
