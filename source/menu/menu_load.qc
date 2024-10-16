string UserMapNameLookup(string bsp_name);

string loading_tips[] =
{
    "Now with Font Kerning.",
    "Quick Revive will ressurect you in Solo.",
    "Use Quick Revive to revive faster in Co-Op!",
    "Jugger-Nog increases your health.",
    "Speed Cola increases Reload speed.",
    "Speed Cola allows faster Barricade building",
    "Double Tap will improve Rate of Fire.",
    "Stamin-Up increases your Move Speed.",
    "Stamin-Up allows you to Sprint longer.",
    "PhD Flopper grants explosive immunity.",
    "Dive-to-prone with PhD to cause PAIN!",
    "Deadshot Daiquiri improves your accuracy.",
    "Deadshot Daiquiri removes sniper scope sway.",
    "Deadshot Daiquiri increases weapon accuracy.",
    "Carry three weapons with Mule Kick!",
    "Removed Herobrine.",
    "Pack-A-Punch the Kar98k to get to round 500!",
    "NZ:P is on too many platforms to keep count of.",
    "Dive on top of your friends to win!",
    "Open Source!",
    "Max Ammo doesn't refill your mag, so RELOAD!",
    "KA-BOOM!",
    "NZ:P has been in development since 2009.",
    "Hold a crawler and hunt for secrets.",
    "'Where's the armor station?'",
    "https://docs.nzp.gay/",
    "Also try FreeCS by eukara!",
    "FTE is a pretty awesome Quake sourceport",
    "\"your lg is nothink on the lan\" - Cooller",
    "\"¦]\" - Cooller",
    "\"i'm not your chaotic on dm6\" - Cooller",
    "\"alltimes lucky\" - Cooller",
    "\"not my trouble\" - Cooller",
    "\"it's not internet\" - Cooller",
    "\"relax\" - Cooller",
    "Also try LibreQuake.",
    "Support the Internet Archive!"
};

float loading_tip_endtime;
string current_tip;
string GetLoadingTip() =
{
    if (time > loading_tip_endtime) {
        current_tip = loading_tips[random() * loading_tips.length];
        loading_tip_endtime = time + 5;
    }

    return current_tip;
};

void(vector screensize, float opaque) m_drawloading =
{
    // Black Background
    drawfill([0, 0], screensize, [0, 0, 0], 1);

    string current_map_loading = cvar_string("mapname");

    // If it's blank, just keep the screen black until FTE sends it to us.
    if (current_map_loading == "")
        return;

    // Pick a loading tip.
    string loading_tip = GetLoadingTip();
    string map_name_pretty = UserMapNameLookup(current_map_loading);

    //float(vector position, string pic, vector size, vector rgb, float alpha, optional float flag) drawpic = #456;

    // Loading screen
    drawpic([0, 0], sprintf("gfx/lscreen/%s", current_map_loading), screensize, [1, 1, 1], 1);

    // Cinematic Lines
    drawfill([0, 0], [screensize_x, 36], [0, 0, 0], 175/255);
    drawfill([0, screensize_y - 36], [screensize_x, 36], [0, 0, 0], 175/255);

    // Map Title
    Draw_String([10, 5], map_name_pretty, MENU_TEXT_LARGE, [1, 1, 0], 1, 0);

    // Loading Tip
    Draw_String([screensize_x/2 - getTextWidth(loading_tip, MENU_TEXT_SMALL_x)/2, screensize_y - 25], loading_tip, MENU_TEXT_SMALL, [1, 1, 1], 1, 0);
};