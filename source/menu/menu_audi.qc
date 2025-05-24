string menu_audio_buttons[5] = {"am_maste", "am_menu", "am_bgm", "am_apply", "am_back"};

void() Menu_Audio_ApplySettings =
{
    localcmd("vid_reload\nsaveconfig user_settings.cfg\n");
    music_duration_time = 0;
};

string(string prev_id) Menu_Audio_GetNextButton =
{
    if (prev_id == "")
        return menu_audio_buttons[0];

    string ret = menu_audio_buttons[0];

    for(float i = 0; i < menu_audio_buttons.length; i++) {
        if (menu_audio_buttons[i] == prev_id) {
            if (i + 1 >= menu_audio_buttons.length)
                break;

            ret = menu_audio_buttons[i + 1];
            break;
        }
    }

    return ret;
};

string(string next_id) Menu_Audio_GetPreviousButton =
{
    if (next_id == "")
        return menu_audio_buttons[menu_audio_buttons.length - 1];

    string ret = menu_audio_buttons[menu_audio_buttons.length - 1];

    for(float i = menu_audio_buttons.length - 1; i > 0; i--) {
        if (menu_audio_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_audio_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void() Menu_Audio =
{
    Menu_DrawBackground();
    Menu_DrawTitle("AUDIO OPTIONS");
    Menu_DrawMapPanel();

    Menu_Button(1, "am_maste", "MASTER VOLUME", "Volume for all Audio.") ? 0 : 0;
    Menu_CvarSlider(1, [0, 1, 10], "volume", false, true, false);

    Menu_Button(2, "am_menu", "INTERFACE VOLUME", "Volume for UI/Menus.") ? 0 : 0;
    Menu_CvarSlider(2, [0, 1, 10], "nzp_uivolume", false, true, false);

    Menu_Button(3, "am_bgm", "MUSIC VOLUME", "Volume for Background Music.") ? 0 : 0;
    Menu_CvarSlider(3, [0, 1, 10], "nzp_bgmvolume", false, true, false);

    Menu_DrawDivider(12.25);
    Menu_Button(-2, "am_apply", "APPLY", "Save & Apply Settings.") ? Menu_Audio_ApplySettings() : 0;
    Menu_Button(-1, "am_back", "BACK", "Return to Configuration.") ? current_menu = MENU_OPTIONS : 0;

	sui_pop_frame();	
};