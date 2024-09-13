float menu_gpad_init;

// float current_adsmode;
// float current_invert;

// void() Menu_Control_StoreCurrentSettings =
// {
//     // Figure out ADS mode.
//     tokenize(findkeysforcommandex("+button8"));
// 	string button8_key = strtoupper(argv(0));
// 	if (button8_key == "MOUSE2") {
//         current_adsmode = 0;
//     } else {
//         current_adsmode = 1;
//     }

//     	if (cvar("m_pitch") == 0.022)
// 		localcmd("m_pitch -0.022\n");
// 	else
// 		localcmd("m_pitch 0.022\n");

//     current_invert = (cvar("m_pitch") == 0.022);
// };

void() Menu_Gamepad_Init =
{
    //Menu_Control_StoreCurrentSettings();
    menu_gpad_init = true;
};

// void() Menu_Control_ApplyADS =
// {
//     Menu_PlaySound(MENU_SND_ENTER);

//     tokenize(findkeysforcommandex("+button8"));
// 	string button8_key = strtoupper(argv(0));

// 	// ADS Mode
// 	if (button8_key == "MOUSE2") {
// 		localcmd("bind MOUSE2 \"impulse 26\"\n");
//         current_adsmode = 1;
//     } else {
// 		localcmd("bind MOUSE2 \"+button8\"\n");
//         current_adsmode = 0;
//     }
// };

// void() Menu_Control_InvertLook =
// {
//     Menu_PlaySound(MENU_SND_ENTER);
//     current_invert = !current_invert;

//     if (current_invert)
//         localcmd("m_pitch -0.022\n");
//     else
//         localcmd("m_pitch 0.022\n");
// };

	// {[6, 135], "Controller Glyphs", -1, setting_glyph, null, MENU_CONSETTINGS, 0, OPTION_WEB_AND_EXE}, // 67
	// {[6, 155], "Rumble", -1, settings_rumble, null, MENU_CONSETTINGS, 0, OPTION_WEB_AND_EXE}, // 68
	// {[6, 175], "Gamepad", -1, settings_gamepad, null, MENU_CONSETTINGS, 0, OPTION_WEB_AND_EXE}, // 69
	// {[6, 195], "Aim Assist", -1, settings_aimassist, null, MENU_CONSETTINGS, 0, OPTION_WEB_AND_EXE}, // 70

void() Menu_Gamepad_ApplySettings =
{
    localcmd("vid_reload\nsaveconfig user_settings.cfg\n");
    music_duration_time = 0;
};

void() Menu_Gamepad =
{
    if (!menu_gpad_init)
        Menu_Gamepad_Init();

    Menu_DrawBackground();
    Menu_DrawTitle("GAMEPAD OPTIONS");
    Menu_DrawMapPanel();

    // Menu_Button(1, "cm_adsm", "AIM DOWN SIGHT", "Switch between Hold and Toggle ADS Modes.") ? Menu_Control_ApplyADS() : 0;
    // string ads_string = "";
    // switch(current_adsmode) {
    //     case 0: ads_string = "HOLD"; break;
    //     case 1: ads_string = "TOGGLE"; break;
    //     default: break;
    // }
    // Menu_DrawOptionValue(1, ads_string);

    // Menu_Button(2, "cm_sens", "SENSITIVITY", "Alter Look Sensitivity.") ? 0 : 0;
    // Menu_CvarSlider(2, [1, 10, 10], "sensitivity", false, false);

    // Menu_Button(3, "cm_invs", "INVERT LOOK", "Invert Y-Axis Camera Input.") ? Menu_Control_InvertLook() : 0;
    // string invert_string = "";
    // switch(current_invert) {
    //     case 0: invert_string = "ENABLED"; break;
    //     case 1: invert_string = "DISABLED"; break;
    //     default: break;
    // }
    // Menu_DrawOptionValue(3, invert_string);

    // Menu_Button(4, "cm_gpad", "GAMEPAD", "Gamepad specific options.") ? current_menu = MENU_GAMEPAD : 0;

    Menu_DrawDivider(12.25);
    Menu_Button(-2, "gp_apply", "APPLY", "Save & Apply Settings.") ? Menu_Gamepad_ApplySettings() : 0;
    Menu_Button(-1, "gp_back", "BACK", "Return to Configuration.") ? current_menu = MENU_CONTROL : 0;

	sui_pop_frame();	
};