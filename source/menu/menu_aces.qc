string menu_accesibility_buttons[6] = {"ac_hitm", "ac_text", "ac_color", "ac_whiteflash", "ac_apply", "ac_back"};

float menu_accessibility_init;

float current_hitmarker;
float current_colorblind;
float current_whiteflash;

string(string prev_id) Menu_Accessibility_GetNextButton =
{
    if (prev_id == "")
        return menu_accesibility_buttons[0];

    string ret = menu_accesibility_buttons[0];

    for(float i = 0; i < menu_accesibility_buttons.length; i++) {
        if (menu_accesibility_buttons[i] == prev_id) {
            if (i + 1 >= menu_accesibility_buttons.length)
                break;

            ret = menu_accesibility_buttons[i + 1];
            break;
        }
    }

    return ret;
};

string(string next_id) Menu_Accessibility_GetPreviousButton =
{
    if (next_id == "")
        return menu_accesibility_buttons[menu_accesibility_buttons.length - 1];

    string ret = menu_accesibility_buttons[menu_accesibility_buttons.length - 1];

    for(float i = menu_accesibility_buttons.length - 1; i > 0; i--) {
        if (menu_accesibility_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_accesibility_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void() Menu_Accessibility_StoreCurrentSettings =
{
    current_hitmarker = cvar("cl_hitmarkers");
    current_colorblind = cvar("cl_colorblind");
    current_whiteflash = cvar("scr_whiteflash");
}

void() Menu_Accessibility_ApplySettings =
{
    localcmd("vid_reload\nsaveconfig user_settings.cfg\n");
    music_duration_time = 0;
};

void() Menu_Accessibility_Init =
{
    Menu_Accessibility_StoreCurrentSettings();
    menu_accessibility_init = true;
};

void() Menu_Accessibility_UpdateHitmarkers =
{
    Menu_PlaySound(MENU_SND_ENTER);
    current_hitmarker = !current_hitmarker;
    cvar_set("cl_hitmarkers", ftos(current_hitmarker));
};

void() Menu_Accessibility_UpdateColorblindFilter =
{
    Menu_PlaySound(MENU_SND_ENTER);
    current_colorblind = !current_colorblind;
    cvar_set("cl_colorblind", ftos(current_colorblind));
}

void() Menu_Accessibility_UpdateWhiteFlash =
{
    Menu_PlaySound(MENU_SND_ENTER);
    current_whiteflash = !current_whiteflash;
    cvar_set("scr_whiteflash", ftos(current_whiteflash));
}

void() Menu_Accessibility =
{
    if (!menu_accessibility_init)
        Menu_Accessibility_Init();

    Menu_DrawBackground();
    Menu_DrawTitle("ACCESSIBILITY");

    // Hitmarkers
    Menu_Button(1, "ac_hitm", "HITMARKERS", "HUD Hitmarkers for visual feedback.") ? Menu_Accessibility_UpdateHitmarkers() : 0;
    string hitmarker_string = "";
    switch(current_hitmarker) {
        case 0: hitmarker_string = "DISABLED"; break;
        case 1: hitmarker_string = "ENABLED"; break;
        default: break;
    }
    Menu_DrawOptionValue(1, hitmarker_string);

    // Text Backdrop
    Menu_Button(2, "ac_text", "TEXT BACKDROP", "Opacity of backdrop for text elements on HUD.") ? 0 : 0;
    Menu_CvarSlider(2, [0, 1, 20], "cl_textopacity", false, false, false);

    // Accessible Colors
    Menu_Button(3, "ac_color", "ACCESSIBLE COLORS", "Uses enhanced Player colors to improve visibilty.") ? Menu_Accessibility_UpdateColorblindFilter() : 0;
    string colorblind_string = "";
    switch(current_colorblind) {
        case 0: colorblind_string = "DISABLED"; break;
        case 1: colorblind_string = "ENABLED"; break;
        default: break;
    }
    Menu_DrawOptionValue(3, colorblind_string);

    // Screen Flashes
    Menu_Button(4, "ac_screenflash", "WHITE SCREEN FLASHES", "Choose the color of white screen flashes.") ? Menu_Accessibility_UpdateWhiteFlash() : 0;
    string whiteflash_string = "";
    switch(current_whiteflash) {
        case 0: whiteflash_string = "WHITE"; break;
        case 1: whiteflash_string = "BLACK"; break;
        default: break;
    }
    Menu_DrawOptionValue(4, whiteflash_string);

    Menu_DrawDivider(12.25);
    Menu_Button(-2, "ac_apply", "APPLY", "Save & Apply Settings.") ? Menu_Accessibility_ApplySettings() : 0;
    Menu_Button(-1, "ac_back", "BACK", "Return to Configuration Menu.") ? current_menu = MENU_OPTIONS : 0;

	sui_pop_frame();	
};
