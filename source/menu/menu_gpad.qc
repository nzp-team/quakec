string menu_gpad_buttons[7] = {"gp_glyp", "gp_rumb", "gp_aima", "gp_senx", "gp_seny", "gp_apply", "gp_back"};

void() Menu_Gamepad_ApplyGlpyh =
{
    Menu_PlaySound(MENU_SND_ENTER);
    string current_glyph_brand = cvar_string("cl_controllerglyphs");
	string new_glyph_brand = "";

	switch(current_glyph_brand) {
		case "xbox":
			new_glyph_brand = "sony";
			break;
		case "sony":
			new_glyph_brand = "nintendo";
			break;
		case "nintendo":
			new_glyph_brand = "generic";
			break;
		default:
			new_glyph_brand = "xbox";
			break;
	}

	cvar_set("cl_controllerglyphs", new_glyph_brand);
};

void() Menu_Gamepad_ApplyRumble =
{
    Menu_PlaySound(MENU_SND_ENTER);
    float rumble = cvar("in_rumbleenabled");
	cvar_set("in_rumbleenabled", ftos(!rumble));
};

void() Menu_Gamepad_ApplyAimAssist =
{
    Menu_PlaySound(MENU_SND_ENTER);
    float rumble = cvar("in_aimassist");
	cvar_set("in_aimassist", ftos(!rumble));
};

void() Menu_Gamepad_ApplySettings =
{
    localcmd("vid_reload\nsaveconfig user_settings.cfg\n");
    music_duration_time = 0;
};

string(string prev_id) Menu_Gamepad_GetNextButton =
{
    if (prev_id == "")
        return menu_gpad_buttons[0];

    string ret = menu_gpad_buttons[0];

    for(float i = 0; i < menu_gpad_buttons.length; i++) {
        if (menu_gpad_buttons[i] == prev_id) {
            if (i + 1 >= menu_gpad_buttons.length)
                break;

            ret = menu_gpad_buttons[i + 1];
            break;
        }
    }

    return ret;
};

string(string next_id) Menu_Gamepad_GetPreviousButton =
{
    if (next_id == "")
        return menu_gpad_buttons[menu_gpad_buttons.length - 1];

    string ret = menu_gpad_buttons[menu_gpad_buttons.length - 1];

    for(float i = menu_gpad_buttons.length - 1; i > 0; i--) {
        if (menu_gpad_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_gpad_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void() Menu_Gamepad =
{
    Menu_DrawBackground();
    Menu_DrawTitle("GAMEPAD OPTIONS");
    Menu_DrawMapPanel();

    Menu_Button(1, "gp_glyp", "GLYPH TYPE", "Change the Style/Branding for Gamepad Glyphs.") ? Menu_Gamepad_ApplyGlpyh() : 0;
    string glyph_string = "";
    switch(cvar_string("cl_controllerglyphs")) {
        case "xbox": glyph_string = "MICROSOFT"; break;
        case "sony": glyph_string = "SONY"; break;
        case "nintendo": glyph_string = "NINTENDO"; break;
        case "generic": glyph_string = "LIBRE"; break;
        default: glyph_string = sprintf("USER (\"%s\")", cvar_string("cl_controllerglyphs")); break;
    }
    Menu_DrawOptionValue(1, glyph_string);
    Menu_DrawControllerGlyphDemo(1);

    Menu_Button(2, "gp_rumb", "RUMBLE", "Toggle Rumble during Gameplay Actions.") ? Menu_Gamepad_ApplyRumble() : 0;
    string rumble_string = "";
    switch(cvar("in_rumbleenabled")) {
        case 0: rumble_string = "DISABLED"; break;
        case 1: rumble_string = "ENABLED"; break;
        default: break;
    }
    Menu_DrawOptionValue(2, rumble_string);

    Menu_Button(3, "gp_aima", "AIM ASSIST", "Toggle Camera Aim Assist.") ? Menu_Gamepad_ApplyAimAssist() : 0;
    string aa_string = "";
    switch(cvar("in_aimassist")) {
        case 0: aa_string = "DISABLED"; break;
        case 1: aa_string = "ENABLED"; break;
        default: break;
    }
    Menu_DrawOptionValue(3, aa_string);

    Menu_Button(4, "gp_senx", "X AXIS SENSITIVITY", "Alter X-Axis Look Sensitivity.") ? 0 : 0;
    Menu_CvarSlider(4, [0, 4, 16], "joypitchsensitivity", false, false, false);

    Menu_Button(5, "gp_seny", "Y AXIS SENSITIVITY", "Alter Y-Axis Look Sensitivity.") ? 0 : 0;
    Menu_CvarSlider(5, [0, 4, 16], "joyyawsensitivity", false, false, false);

    Menu_DrawDivider(12.25);
    Menu_Button(-2, "gp_apply", "APPLY", "Save & Apply Settings.") ? Menu_Gamepad_ApplySettings() : 0;
    Menu_Button(-1, "gp_back", "BACK", "Return to Control Options.") ? current_menu = MENU_CONTROL : 0;

	sui_pop_frame();	
};