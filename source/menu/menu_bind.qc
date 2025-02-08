float menu_bind_currentwatcher;
string menu_bind_buttons[13] = {"bm_jump", "bm_spri", "bm_crou", "bm_wnex", "bm_use", "bm_relo", "bm_mele", "bm_prig", "bm_secg", "bm_fire", "bm_ads", "bm_apply", "bm_back"};

float(float keynum) Menu_Bindings_IsGamepad =
{
    if (keynum >= 768 && keynum <= 839)
        return true;

    return false;
};

void(float order, string command) Menu_Bindings_PrintBindForCommand =
{
    // If we're currently watching this key, drawn an indicator ("< >")
    if (menu_bind_currentwatcher == order) {
        Menu_DrawOptionKey(order, "< >");
        return;
    }

    string bind = "";
    float argc = tokenize(findkeysforcommandex(command));
    for (int i = 0; i < argc; i++) {
		string temp_button = strtoupper(argv(i));
		float bind_is_gamepad = Menu_Bindings_IsGamepad(stringtokeynum(temp_button));

		// Always display the last button in the last.
		if (bind_is_gamepad && last_input_was_gamepad)
			bind = temp_button;
		else if (!bind_is_gamepad && !last_input_was_gamepad)
			bind = temp_button;
	}

    if (bind == "")
        bind = "UNBOUND";

    Menu_DrawOptionKey(order, bind);
};

void(float id, string command) Menu_Bindings_Listen =
{
    Menu_PlaySound(MENU_SND_ENTER);
    menu_bind_currentwatcher = id;
    _sui_binding_command = command;
};

void() Menu_Bindings_Back =
{
    menu_bind_currentwatcher = 0;
    current_menu = MENU_CONTROL;
};

string(string prev_id) Menu_Bindings_GetNextButton =
{
    if (prev_id == "")
        return menu_bind_buttons[0];

    string ret = menu_bind_buttons[0];

    for(float i = 0; i < menu_bind_buttons.length; i++) {
        if (menu_bind_buttons[i] == prev_id) {
            if (i + 1 >= menu_bind_buttons.length)
                break;

            ret = menu_bind_buttons[i + 1];
            break;
        }
    }

    return ret;
};

string(string next_id) Menu_Bindings_GetPreviousButton =
{
    if (next_id == "")
        return menu_bind_buttons[menu_bind_buttons.length - 1];

    string ret = menu_bind_buttons[menu_bind_buttons.length - 1];

    for(float i = menu_bind_buttons.length - 1; i > 0; i--) {
        if (menu_bind_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_bind_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void() Menu_Bindings =
{
    Menu_DrawBackground();
    Menu_DrawTitle("CONTROL BINDINGS");
    Menu_DrawMapPanel();

    Menu_Button(1, "bm_jump", "JUMP", "") ? Menu_Bindings_Listen(1, "impulse 10") : 0;
    Menu_Bindings_PrintBindForCommand(1, "impulse 10");

    Menu_Button(2, "bm_spri", "SPRINT", "") ? Menu_Bindings_Listen(2, "impulse 23") : 0;
    Menu_Bindings_PrintBindForCommand(2, "impulse 23");

    Menu_Button(3, "bm_crou", "CHANGE STANCE", "") ? Menu_Bindings_Listen(3, "impulse 30") : 0;
    Menu_Bindings_PrintBindForCommand(3, "impulse 30");
    
    Menu_Button(4, "bm_wnex", "SWAP WEAPON", "") ? Menu_Bindings_Listen(4, "+button4") : 0;
    Menu_Bindings_PrintBindForCommand(4, "+button4");
    
    Menu_Button(5, "bm_use", "INTERACT", "") ? Menu_Bindings_Listen(5, "+button7") : 0;
    Menu_Bindings_PrintBindForCommand(5, "+button7");
    
    Menu_Button(6, "bm_relo", "RELOAD", "") ? Menu_Bindings_Listen(6, "+button5") : 0;
    Menu_Bindings_PrintBindForCommand(6, "+button5");
    
    Menu_Button(7, "bm_mele", "MELEE", "") ? Menu_Bindings_Listen(7, "+button6") : 0;
    Menu_Bindings_PrintBindForCommand(7, "+button6");
    
    Menu_Button(8, "bm_prig", "PRIMARY GRENADE", "") ? Menu_Bindings_Listen(8, "+button3") : 0;
    Menu_Bindings_PrintBindForCommand(8, "+button3");
    
    Menu_Button(9, "bm_secg", "SECONDARY GRENADE", "") ? Menu_Bindings_Listen(9, "impulse 33") : 0;
    Menu_Bindings_PrintBindForCommand(9, "impulse 33");

    Menu_Button(10, "bm_fire", "WEAPON FIRE", "") ? Menu_Bindings_Listen(10, "+attack") : 0;
    Menu_Bindings_PrintBindForCommand(10, "+attack");

    Menu_Button(11, "bm_ads", "AIM DOWN SIGHTS", "") ? Menu_Bindings_Listen(11, "+button8") : 0;
    Menu_Bindings_PrintBindForCommand(11, "+button8");

    Menu_DrawDivider(12.25);
    Menu_Button(-2, "bm_apply", "APPLY", "Save & Apply Settings.") ? Menu_Gamepad_ApplySettings() : 0;
    Menu_Button(-1, "bm_back", "BACK", "Return to Control Options.") ? Menu_Bindings_Back() : 0;

	sui_pop_frame();	
};