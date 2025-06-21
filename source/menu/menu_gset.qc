string menu_gset_buttons[8] = {"ge_mode", "ge_diff", "ge_rond", "ge_magc", "ge_head", "ge_hord", "ge_frnd", "ge_back"};

string(string prev_id) Menu_GameSettings_GetNextButton =
{
    if (prev_id == "")
        return menu_gset_buttons[0];

    string ret = menu_gset_buttons[0];

    for(float i = 0; i < menu_gset_buttons.length; i++) {
        if (menu_gset_buttons[i] == prev_id) {
            if (i + 1 >= menu_gset_buttons.length)
                break;

            ret = menu_gset_buttons[i + 1];
            break;
        }
    }

    return ret;
};

string(string next_id) Menu_GameSettings_GetPreviousButton =
{
    if (next_id == "")
        return menu_gset_buttons[menu_gset_buttons.length - 1];

    string ret = menu_gset_buttons[menu_gset_buttons.length - 1];

    for(float i = menu_gset_buttons.length - 1; i > 0; i--) {
        if (menu_gset_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_gset_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void() Menu_GameSettings_ApplyGameMode =
{
    Menu_PlaySound(MENU_SND_ENTER);

    float current_gamemode = cvar("sv_gamemode");
    current_gamemode += 1;

    if (current_gamemode > 5)
        current_gamemode = 0;

    cvar_set("sv_gamemode", ftos(current_gamemode));
};

void() Menu_GameSettings_ApplyDifficulty =
{
    Menu_PlaySound(MENU_SND_ENTER);

    float current_difficulty = cvar("sv_difficulty");
    current_difficulty += 1;

    if (current_difficulty > 3)
        current_difficulty = 0;

    cvar_set("sv_difficulty", ftos(current_difficulty));
};

void() Menu_GameSettings_ApplyMagic =
{
    Menu_PlaySound(MENU_SND_ENTER);

    float current_magic = cvar("sv_magic");
    current_magic = !current_magic;

    cvar_set("sv_magic", ftos(current_magic));
};

void() Menu_GameSettings_ApplyHeadshots =
{
    Menu_PlaySound(MENU_SND_ENTER);

    float current_headshotonly = cvar("sv_headshotonly");
    current_headshotonly = !current_headshotonly;

    cvar_set("sv_headshotonly", ftos(current_headshotonly));
};

void() Menu_GameSettings_ApplyFastRounds =
{
    Menu_PlaySound(MENU_SND_ENTER);

    float current_fastrounds = cvar("sv_fastrounds");
    current_fastrounds = !current_fastrounds;

    cvar_set("sv_fastrounds", ftos(current_fastrounds));
};

void() Menu_GameSettings = 
{
    Menu_DrawBackground();
    Menu_DrawTitle("GAME SETTINGS");

    Menu_DrawMapPanel();

    // Game Mode
    string gamemode_description = "";
    string gamemode_string = "";
    switch(cvar("sv_gamemode")) {
        case 0: gamemode_description = "Classic Round-Based Zombies."; gamemode_string = "CLASSIC"; break;
        case 1: localcmd("sv_gamemode 2\n"); break;
        //case 1: gamemode_description = "Compete in Teams to outlive your opponents."; gamemode_string = "GRIEF"; break;
        case 2: gamemode_description = "Race to earn Score to cycle through Weaponry."; gamemode_string = "GUN GAME"; break;
        case 3: gamemode_description = "No HUD? Two Perks? 150% Item Cost? No Problem."; gamemode_string = "HARDCORE"; break;
        case 4: gamemode_description = "Ole Fashioned stand-off between you and the Dead."; gamemode_string = "WILD WEST"; break;
        case 5: gamemode_description = "Knives-and-Nades only. Grenades Explode on Contact."; gamemode_string = "STICKS & STONES"; break;
        default: gamemode_description = "???"; break;
    }
    Menu_Button(1, "ge_mode", "GAME MODE", gamemode_description) ? Menu_GameSettings_ApplyGameMode() : 0;
    Menu_DrawOptionValue(1, gamemode_string);

    // Difficulty
    string difficulty_description = "";
    string difficulty_string = "";
    switch(cvar("sv_difficulty")) {
        case 0: difficulty_description = "Normal Zombies gameplay."; difficulty_string = "NORMAL"; break;
        case 1: difficulty_description = "Less & Slower Zombies. More Power-Ups. More Health."; difficulty_string = "EASY"; break;
        case 2: difficulty_description = "More & Faster Zombies. Less Power-Ups. Less Health."; difficulty_string = "HARD"; break;
        case 3: difficulty_description = "Hellish Zombies. Earn Less Score. Rare Power-Ups. 1 hit KO."; difficulty_string = "NIGHTMARE"; break;
        default: difficulty_description = "???"; break;
    }
    Menu_Button(2, "ge_diff", "DIFFICULTY", difficulty_description) ? Menu_GameSettings_ApplyDifficulty() : 0;
    Menu_DrawOptionValue(2, difficulty_string);

    // Start Round
    Menu_Button(3, "ge_rond", "START ROUND", "Round to begin the Game on.") ? 0 : 0;
    Menu_CvarSlider(3, [0, 50, 10], "sv_startround", true, false, true);

    // Magic
    string magic_string = "";
    Menu_Button(4, "ge_magc", "MAGIC", "Whether to allow Perks, Power-Ups, and the Mystery Box.") ? Menu_GameSettings_ApplyMagic() : 0;
    if (cvar("sv_magic")) {
        magic_string = "ENABLED";
    } else {
        magic_string = "DISABLED";
    }
    Menu_DrawOptionValue(4, magic_string);

    // Headshots Only
    string headshot_string = "";
    Menu_Button(5, "ge_head", "HEADSHOTS ONLY", "Headshots are the only means of Death. Explosives don't work, either.") ? Menu_GameSettings_ApplyHeadshots() : 0;
    if (cvar("sv_headshotonly")) {
        headshot_string = "ENABLED";
    } else {
        headshot_string = "DISABLED";
    }
    Menu_DrawOptionValue(5, headshot_string);

    // Horde Size
    Menu_Button(6, "ge_hord", "HORDE SIZE", "Maximum Zombies that can Active at once.") ? 0 : 0;
    Menu_CvarSlider(6, [2, 64, 31], "sv_maxai", true, false, false);

    // Fast Rounds
    string fast_string = "";
    Menu_Button(7, "ge_frnd", "FAST ROUNDS", "Minimize Time between Rounds.") ? Menu_GameSettings_ApplyFastRounds() : 0;
    if (cvar("sv_fastrounds")) {
        fast_string = "ENABLED";
    } else {
        fast_string = "DISABLED";
    }
    Menu_DrawOptionValue(7, fast_string);

    Menu_Button(-1, "ge_back", "BACK", "Return to Pre-Game Menu.") ? current_menu = MENU_LOBBY : 0;

	sui_pop_frame();	
};