void() Menu_Audio_ApplySettings =
{
    localcmd("vid_reload\nsaveconfig user_settings.cfg\n");
    music_duration_time = 0;
};

void() Menu_Audio =
{
    Menu_DrawBackground();
    Menu_DrawTitle("AUDIO OPTIONS");
    Menu_DrawMapPanel();

    Menu_Button(1, "am_maste", "MASTER VOLUME", "Volume for all Audio.") ? 0 : 0;
    Menu_CvarSlider(1, [0, 1, 10], "volume", false, true);

    Menu_Button(2, "am_menu", "INTERFACE VOLUME", "Volume for UI/Menus.") ? 0 : 0;
    Menu_CvarSlider(2, [0, 1, 10], "nzp_uivolume", false, true);

    Menu_Button(3, "am_bgm", "MUSIC VOLUME", "Volume for Background Music.") ? 0 : 0;
    Menu_CvarSlider(3, [0, 1, 10], "nzp_bgmvolume", false, true);

    Menu_DrawDivider(12.25);
    Menu_Button(-2, "am_apply", "APPLY", "Save & Apply Settings.") ? Menu_Audio_ApplySettings() : 0;
    Menu_Button(-1, "am_back", "BACK", "Return to Configuration.") ? current_menu = MENU_OPTIONS : 0;

	sui_pop_frame();	
};