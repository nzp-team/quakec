string() Menu_Main_GetDashboardName =
{
    switch(running_platform) {
        case PLATFORM_WIN: return "Windows";
        case PLATFORM_MAC: return "MacOS";
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

void() Menu_Main =
{
    Menu_DrawBackground();
    Menu_DrawTitle("MAIN MENU");
    Menu_DrawBuildDate();

    Menu_Button(1, "mm_start", "SOLO", "Play Solo.") ? current_menu = MENU_SOLO : 0;
    Menu_Button(2, "mm_coop", "COOPERATIVE", "Play with up to Four Players.") ? localcmd("\n") : 0;
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
    Menu_SocialBadge(2, "soc_mastadon", "FIXME", 3);
    Menu_SocialBadge(3, "soc_patreon", "patreon.com/cypressimplex", 4);
    Menu_SocialBadge(4, "soc_matrix", "matrix.nzp.gay", 1);

	sui_pop_frame();	
};