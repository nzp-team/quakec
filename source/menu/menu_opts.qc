void() Menu_Options =
{
    Menu_DrawBackground();
    Menu_DrawTitle("CONFIGURATION");

    Menu_Button(1, "om_video", "VIDEO", "Visual Fidelity options.") ? current_menu = MENU_VIDEO : 0;
    Menu_Button(2, "om_audio", "AUDIO", "Volume sliders.") ? current_menu = MENU_AUDIO : 0;
    Menu_Button(3, "om_binds", "CONTROLS", "Control Options and Bindings.") ? current_menu = MENU_CONTROL : 0;
    Menu_Button(4, "om_acces", "ACCESSIBILITY", "Light Sensitivity options.") ? 1 : 0;
    Menu_DrawDivider(5);
    Menu_Button(5.25, "om_console", "OPEN CONSOLE", "Access the Developer Console.") ? localcmd("toggleconsole\n") : 0;

    Menu_Button(-1, "om_back", "BACK", "Return to Main Menu.") ? current_menu = MENU_MAIN : 0;

	sui_pop_frame();	
};