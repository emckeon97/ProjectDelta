namespace PierPressure.Windows.Characters;

/// <summary>Public-domain cartoon roster (mirrors the iOS/Android roster).</summary>
public sealed class GameCharacter
{
    public GameCharacter(string id, string name, int price, string tagline)
    { Id = id; Name = name; Price = price; Tagline = tagline; }
    public string Id { get; }
    public string Name { get; }
    public int Price { get; }
    public string Tagline { get; }
}

public static class Roster
{
    public static readonly IReadOnlyList<GameCharacter> All = new List<GameCharacter>
    {
        new("popeye", "Popeye the Sailor", 0, "Strong to the finish, with spinach to spare."),
        new("felix", "Felix the Cat", 500, "The mischievous cat keeps his grin."),
        new("oswald", "Oswald the Lucky Rabbit", 1000, "Lucky ears, luckier feet."),
        new("minnie", "Minnie Mouse", 1500, "Steamboat sweetheart, quick on her feet."),
        new("willie", "Mickey Mouse", 2500, "The original star — quick on his feet."),
        new("koko", "Koko the Clown", 3000, "Straight out of the inkwell."),
        new("bimbo", "Bimbo", 4000, "Betty's best pal, always up for a run."),
        new("pooh", "Winnie the Pooh", 5000, "A bear of very little brain, but big heart."),
        new("olive", "Olive Oyl", 6500, "Tall, quick, and never still."),
        new("bosko", "Bosko", 8000, "The talk-ink kid himself."),
        new("betty", "Betty Boop", 10000, "Boop-boop-a-doop!"),
        new("pete", "Peg-Leg Pete", 12000, "The river's meanest captain. Mind the peg leg."),
    };

    public static GameCharacter? ById(string id) => All.FirstOrDefault(c => c.Id == id);

    public static string ReelTitle(int reel) => reel switch
    {
        1 => "DOWN AT THE LANDING",
        2 => "THE BUSY HARBOR",
        3 => "FOG ON THE RIVER",
        4 => "THE OLD FOOTBRIDGES",
        5 => "PREMIERE NIGHT",
        _ => "THE SHOW GOES ON",
    };

    public static string ReelBlurb(int reel) => reel switch
    {
        1 => "The year is 1932. The Grand Picture Palace premieres its biggest " +
             "cartoon tonight — and our star is running late! Sprint down the old pier!",
        2 => "Rowboats crowd the landing — the whole river is headed to the premiere. " +
             "Leap 'em and keep moving!",
        3 => "Fog rolls in thick as theater curtains. The paddle-wheelers can't see you… " +
             "and you can't see them!",
        4 => "Duck, star! The crew left every last footbridge down. The show must go on!",
        5 => "There it is — the marquee lights of the Grand Picture Palace! " +
             "One last sprint down the pier and you're a star!",
        _ => "The crowd roars for an encore! How long can you keep running?",
    };
}
