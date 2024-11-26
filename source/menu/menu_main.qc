string menu_main_buttons[5] = {"mm_start", "mm_coop", "mm_options", "mm_credits", "mm_quit"};

string() Menu_Main_GetDashboardName =
{
    switch(running_platform) {
        case PLATFORM_WIN: return "Windows";
        case PLATFORM_MAC: return "macOS";
        case PLATFORM_LIN: return "Linux";
        case PLATFORM_XBX: return "Xbox Dashboard";
        case PLATFORM_AND: return "Android";
        case PLATFORM_BSD: return "BSD";
        case PLATFORM_IOS: return "iOS";
        case PLATFORM_DOS: return "DOS";
        default: return "System";
    }

    return "System";
};

string(string prev_id) Menu_Main_GetNextButton =
{
    if (prev_id == "")
        return menu_main_buttons[0];

    string ret = menu_main_buttons[0];

    for(float i = 0; i < menu_main_buttons.length; i++) {
        if (menu_main_buttons[i] == prev_id) {
            if (i + 1 >= menu_main_buttons.length)
                break;

            ret = menu_main_buttons[i + 1];
            break;
        }
    }

    // Wrap around to first if we selected Quit and this is WASM.
    if (running_platform == PLATFORM_WEB && ret == "mm_quit")
        ret = menu_main_buttons[0];

    return ret;
};

string(string next_id) Menu_Main_GetPreviousButton =
{
    if (next_id == "")
        return menu_main_buttons[menu_main_buttons.length - 1];

    string ret = menu_main_buttons[menu_main_buttons.length - 1];

    for(float i = menu_main_buttons.length - 1; i > 0; i--) {
        if (menu_main_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_main_buttons[i - 1];
            break;
        }
    }

    // Wrap around to first if we selected Quit and this is WASM.
    if (running_platform == PLATFORM_WEB && ret == "mm_quit")
        ret = menu_main_buttons[menu_main_buttons.length - 1];

    return ret;
};

void() Menu_Main =
{
    Menu_DrawBackground();
    Menu_DrawTitle("MAIN MENU");
    Menu_DrawBuildDate();

    Menu_Button(1, "mm_start", "SOLO", "Play Solo.") ? Menu_StartSolo() : 0;
    Menu_Button(2, "mm_coop", "COOPERATIVE", "Play with up to Four Players.") ? current_menu = MENU_COOP : 0;
    Menu_DrawDivider(3);
    Menu_Button(3.25, "mm_options", "CONFIGURATION", "Tweak Game related Options.") ? current_menu = MENU_OPTIONS : 0;
    //Menu_Button(4.25, "mm_achievements", "ACHIEVEMENTS", "View Achievement Progress.") ? localcmd("\n") : 0;
    Menu_GreyButton(4.25, "ACHIEVEMENTS");
    Menu_DrawDivider(5.25);
    Menu_Button(5.50, "mm_credits", "CREDITS", "NZ:P Team + Special Thanks.") ? current_menu = MENU_CREDITS : 0;

    // Don't have a Quit Game button on WASM 
    if (running_platform != PLATFORM_WEB) {
        Menu_DrawDivider(6.50);
        Menu_Button(6.75, "mm_quit", "QUIT GAME", sprintf("Return to %s.", Menu_Main_GetDashboardName())) ? localcmd("quit\n") : 0;
    }

    Menu_SocialBadge(1, "soc_youtube", "youtube.com/@nzpteam", 2);
    Menu_SocialBadge(2, "soc_bluesky", "@nzportable.bsky.social", 3);
    Menu_SocialBadge(3, "soc_patreon", "patreon.com/cypressimplex", 4);
    Menu_SocialBadge(4, "soc_docs", "docs.nzp.gay", 1);

	sui_pop_frame();	
};
