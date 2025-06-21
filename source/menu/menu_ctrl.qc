string menu_ctrl_buttons[7] = {"cm_adsm", "cm_sens", "cm_invs", "cm_gpad", "cm_bind", "cm_apply", "cm_back"};

float menu_ctrl_init;

float current_adsmode;
float current_invert;

void() Menu_Control_StoreCurrentSettings =
{
    // Figure out ADS mode.
    tokenize(findkeysforcommandex("+button8"));
	string button8_key = strtoupper(argv(0));
	if (button8_key == "MOUSE2") {
        current_adsmode = 0;
    } else {
        current_adsmode = 1;
    }

    current_invert = (cvar("m_pitch") == 0.022);
};

void() Menu_Control_Init =
{
    Menu_Control_StoreCurrentSettings();
    menu_ctrl_init = true;
};

void() Menu_Control_ApplyADS =
{
    Menu_PlaySound(MENU_SND_ENTER);

    tokenize(findkeysforcommandex("+button8"));
	string button8_key = strtoupper(argv(0));

	// ADS Mode
	if (button8_key == "MOUSE2") {
		localcmd("bind MOUSE2 \"impulse 26\"\n");
        current_adsmode = 1;
    } else {
		localcmd("bind MOUSE2 \"+button8\"\n");
        current_adsmode = 0;
    }
};

void() Menu_Control_InvertLook =
{
    Menu_PlaySound(MENU_SND_ENTER);
    current_invert = !current_invert;

    if (current_invert)
        localcmd("m_pitch 0.022\n");
    else
        localcmd("m_pitch -0.022\n");
};

void() Menu_Control_ApplySettings =
{
    localcmd("vid_reload\nsaveconfig user_settings.cfg\n");
    music_duration_time = 0;
};

string(string prev_id) Menu_Control_GetNextButton =
{
    if (prev_id == "")
        return menu_ctrl_buttons[0];

    string ret = menu_ctrl_buttons[0];

    for(float i = 0; i < menu_ctrl_buttons.length; i++) {
        if (menu_ctrl_buttons[i] == prev_id) {
            if (i + 1 >= menu_ctrl_buttons.length)
                break;

            ret = menu_ctrl_buttons[i + 1];
            break;
        }
    }

    return ret;
};

string(string next_id) Menu_Control_GetPreviousButton =
{
    if (next_id == "")
        return menu_ctrl_buttons[menu_ctrl_buttons.length - 1];

    string ret = menu_ctrl_buttons[menu_ctrl_buttons.length - 1];

    for(float i = menu_ctrl_buttons.length - 1; i > 0; i--) {
        if (menu_ctrl_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_ctrl_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void() Menu_Control =
{
    if (!menu_ctrl_init)
        Menu_Control_Init();

    Menu_DrawBackground();
    Menu_DrawTitle("CONTROL OPTIONS");
    Menu_DrawMapPanel();

    Menu_Button(1, "cm_adsm", "AIM DOWN SIGHT", "Switch between Hold and Toggle ADS Modes.") ? Menu_Control_ApplyADS() : 0;
    string ads_string = "";
    switch(current_adsmode) {
        case 0: ads_string = "HOLD"; break;
        case 1: ads_string = "TOGGLE"; break;
        default: break;
    }
    Menu_DrawOptionValue(1, ads_string);

    Menu_Button(2, "cm_sens", "SENSITIVITY", "Alter Look Sensitivity.") ? 0 : 0;
    Menu_CvarSlider(2, [1, 10, 10], "sensitivity", false, false, false);

    Menu_Button(3, "cm_invs", "INVERT LOOK", "Invert Y-Axis Camera Input.") ? Menu_Control_InvertLook() : 0;
    string invert_string = "";
    switch(current_invert) {
        case 0: invert_string = "ENABLED"; break;
        case 1: invert_string = "DISABLED"; break;
        default: break;
    }
    Menu_DrawOptionValue(3, invert_string);

    Menu_Button(4, "cm_gpad", "GAMEPAD", "Gamepad specific options.") ? current_menu = MENU_GAMEPAD : 0;
    Menu_Button(5, "cm_bind", "BINDINGS", "Change Input Bindings.") ? current_menu = MENU_BINDINGS : 0;

    Menu_DrawDivider(12.25);
    Menu_Button(-2, "cm_apply", "APPLY", "Save & Apply Settings.") ? Menu_Control_ApplySettings() : 0;
    Menu_Button(-1, "cm_back", "BACK", "Return to Configuration.") ? current_menu = MENU_OPTIONS : 0;

	sui_pop_frame();	
};