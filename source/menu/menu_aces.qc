string menu_accesibility_buttons[4] = {"ac_hitm", "ac_text", "ac_apply", "ac_back"};

float menu_accessibility_init;

float current_hitmarker;

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
    Menu_CvarSlider(2, [0, 1, 20], "cl_textopacity", false, false);

    Menu_DrawDivider(12.25);
    Menu_Button(-2, "ac_apply", "APPLY", "Save & Apply Settings.") ? Menu_Accessibility_ApplySettings() : 0;
    Menu_Button(-1, "ac_back", "BACK", "Return to Configuration Menu.") ? current_menu = MENU_OPTIONS : 0;

	sui_pop_frame();	
};
