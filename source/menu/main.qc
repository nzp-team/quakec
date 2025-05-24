
float menu_active;

//
// Menu_GetBuildDate()
// Retrieves build date from version.txt
// and stores it into build_datetime string.
//
void() Menu_GetBuildDate =
{
	float file = fopen("version.txt", FILE_READ);

	if (file != -1) {
		build_datetime = fgets(file);
		fclose(file);
	}
};

//
// Menu_PickBackground()
// Returns a random image in nzp/gfx/menu/custom
// to display in Menu_DrawBackground().
//
string() Menu_PickBackground =
{
	searchhandle 	pics;
	float 			pic_count;

	pics 			= search_begin("gfx/menu/custom/*", 0, 0);
	pic_count 		= search_getsize(pics);

	string image = "";

	while(TRUE) {
		float entry = rint(random() * pic_count);
		string potential_image = search_getfilename(pics, entry);

		string extension = strtolower(substring(potential_image, strlen(potential_image) - 3, strlen(potential_image)));

		if (extension != "tga" && extension != "png" && extension != "jpg")
			continue;

		if (potential_image != menu_background) {
			image = potential_image;
			break;
		}
	}

	return image;
};

//
// UserMapNameLookup(bsp_name)
// Returns the Prettified name for the given
// .BSP
//
string UserMapNameLookup(string bsp_name) =
{
	for(int i = 0; i < USER_MAPS_MAX; i++) {
		if (user_maps[i].map_name != bsp_name)
			continue;

		if (user_maps[i].map_name_pretty != "")
			return user_maps[i].map_name_pretty;

		return user_maps[i].map_name;
	}

	return "NULL";
};

//
// UserMapSupportsCustomGameLookup(bsp_name)
// Returns whether the User Map .BSP supports
// Custom Game Settings.
//
float UserMapSupportsCustomGameLookup(string bsp_name) =
{
	for(int i = 0; i < USER_MAPS_MAX; i++) {
		if (user_maps[i].map_name != bsp_name)
			continue;

		return user_maps[i].map_allow_game_settings;
	}

	return true;
};

//
// Menu_MapFinder()
// Performs a .BSP search in the maps/
// directory and adds them to the custom
// map data structure.
//
string(string s) strip_custominfo =
{
	string s2;
	s2 = substring(s, 5, strlen(s)); // maps/
	s2 = substring(s2, 0, strlen(s2) - 4); // .bsp

	return s2;
}
void() Menu_MapFinder =
{
	searchhandle maps;

	maps = search_begin("maps/*.bsp", 0, 0);
	user_maps_count = search_getsize(maps);

	//custom_map_pages = ceil(map_count/10);

	//float stock_step_back; // So stock maps aren't appended to user maps..
	for (float i = 0; i < user_maps_count; i++) {
		//float index = i - stock_step_back;
		float index = i;

		user_maps[index].occupied = TRUE;
		user_maps[index].map_name = strip_custominfo(search_getfilename(maps, i));

		// float is_stock;
		// for(int j = 0; j < stock_maps.length; j++) {
		// 	if (user_maps[index].map_name == stock_maps[j].bsp_name) {
		// 		stock_step_back++;
		// 		is_stock = true;
		// 		break;
		// 	}
		// }

		// // Don't bother occupying if this map is built in.
		// if (is_stock)
		// 	return;

		float settings = fopen(strcat("maps/", user_maps[index].map_name, ".txt"), FILE_READ);
		if (settings != -1) {
			user_maps[index].map_name_pretty = fgets(settings);
			user_maps[index].map_desc[0] = fgets(settings);
			user_maps[index].map_desc[1] = fgets(settings);
			user_maps[index].map_desc[2] = fgets(settings);
			user_maps[index].map_desc[3] = fgets(settings);
			user_maps[index].map_desc[4] = fgets(settings);
			user_maps[index].map_desc[5] = fgets(settings);
			user_maps[index].map_desc[6] = fgets(settings);
			user_maps[index].map_desc[7] = fgets(settings);
			user_maps[index].map_author = fgets(settings);
			user_maps[index].map_use_thumbnail = stof(fgets(settings));
			user_maps[index].map_allow_game_settings = stof(fgets(settings));
			fclose(settings);
		}
		
	}
	//user_maps_count -= stock_step_back;

	search_end(maps);
};

//
// Menu_GetPlatform()
// Parses sys_platform and returns
// a valid platform from the platform
// enums.
//
float() Menu_GetPlatform =
{
	string sys_platform = cvar_string("sys_platform");

	switch(sys_platform) {
		case "Web": 
			return PLATFORM_WEB;
		case "WinCE":
		case "WinRT":
		case "Win":
		case "Win16":
		case "Cygwin":
			return PLATFORM_WIN;
		case "Xbox":
			return PLATFORM_XBX;
		case "Android":
			return PLATFORM_AND;
		case "Linux":
			return PLATFORM_LIN;
		case "iOSSim":
		case "iOS":
			return PLATFORM_IOS;
		case "Mac":
		case "Apple":
		case "MacOS X":
			return PLATFORM_MAC;
		case "FreeBSD":
		case "OpenBSD":
		case "NetBSD":
		case "BSD":
			return PLATFORM_BSD;
		case "Dos":
			return PLATFORM_DOS;
		default:
			return PLATFORM_UNK;
	}

	return PLATFORM_UNK;
}

void() m_init =
{
	registercommand("togglemenu2");
	setcursormode(TRUE,"gfx/xhair", [16, 16], cvar("vid_conautoscale"));
	current_menu = last_menu = MENU_MAIN;

	// Cvars for controlable/modifiable menu music
	autocvar(menu_trackname, "tensioned_by_the_damned");
	autocvar(menu_tracklength, 490);

	// Same goes for menu nav sounds
	autocvar(menu_navigatesound, "sounds/menu/navigate.wav");
	autocvar(menu_entersound, "sounds/menu/enter.wav");
	autocvar(menu_beepsound, "sounds/misc/talk2.wav");

	// Retrieve build date
	Menu_GetBuildDate();

	// Perform map BSP search
	Menu_MapFinder();

	// Load the font Kerning Map.
	InitKerningMap();

	// Get Platform Information
	running_platform = Menu_GetPlatform();

	if (running_platform == PLATFORM_WEB) {
		localcmd("com_protocolname NZP-REBOOT-WEB\n");
	}

	// Init Cvars
	autocvar(cl_cinematic, 0);
	autocvar(nzp_particles, 1);
	autocvar(nzp_uivolume, 1);
	autocvar(nzp_bgmvolume, 1);
	autocvar(vid_ultrawide_limiter, 0);
	autocvar(cl_hitmarkers, 1);
	autocvar(cl_textopacity, 0.20);
	autocvar(cl_colorblind, 0);

	autocvar(sv_gamemode, 0);
	autocvar(sv_difficulty, 0);
	autocvar(sv_startround, 0);
	autocvar(sv_magic, 1);
	autocvar(sv_headshotonly, 0);
	autocvar(sv_maxai, 24);
	autocvar(sv_fastrounds, 0);

	music_duration_time = 0;
	menu_changetime = 0;
};

void(vector screensize) m_draw =
{
	// In game or connecting.
	if (!menu_active) {
		menu_changetime = 0;
		music_duration_time = 0;

		// Draw the loading screen if we're connecting to a lobby.
		tokenize(serverkey("loadstate"));
		float loadstate = stof(argv(0));

		if (loadstate == 1) {
			loading_into_server = true;
			m_drawloading(screensize, false);
			loading_into_server = false;
		}
		return;
	}

	// Menu Music Playback
	if (time > music_duration_time) {
		localsound(sprintf("tracks/%s.ogg", cvar_string("menu_trackname")), 1, cvar("nzp_bgmvolume"));
		music_duration_time = time + cvar("menu_tracklength");
	}

	// Menu Background Changing
	if (time > menu_changetime) {
		menu_background = Menu_PickBackground();
		menu_changetime = time + 7;
		menu_starttime = time;
	}
	
	sui_begin(screensize_x, screensize_y);

	root_menu(screensize);
	
	sui_end();
};

void() m_close =
{
	setkeydest(0);
	menu_active = FALSE;
};

void() m_open =
{
	setkeydest(2);
	menu_active = TRUE;
};

void(float wantmode) m_toggle =
{
	if (menu_active) {
		map_name_override = "";
		m_close();
		setcursormode(FALSE);
	} else {
		m_open();
		setcursormode(TRUE);
		current_menu = MENU_MAIN;
	}
};

float(float evtype, float scanx, float chary, float devid) Menu_InputEvent =
{
	last_input_deviceid = devid;
	float last_input_storage = last_input_was_gamepad;

	if (last_input_deviceid > 0)
		last_input_was_gamepad = TRUE;
	else
		last_input_was_gamepad = FALSE;

	if (last_input_storage != last_input_was_gamepad) {
		menu_bind_currentwatcher = 0;
		_sui_binding_command = "";
		_sui_binding_command_name = "";
	}

	// HACK: we issue a toggleconsole cmd because the engine doesn't seem to
	// do it on its own. stupid stupid stupid. also, return TRUE so the engine
	// thinks we did something else with the input. -- erysdren
	if (evtype == IE_KEYDOWN && getkeybind(scanx) == "toggleconsole")
	{
		localcmd("toggleconsole\n");
		return TRUE;
	}

	float used = sui_input_event(evtype, scanx, chary, devid);
	
	if (evtype == IE_KEYDOWN && !used)
	{
		string cmd = getkeybind(scanx);
		switch (cmd)
		{
		case "togglemenu":
			m_close();
			return TRUE;
		default: return FALSE;
		}
	}
	return FALSE;
};

float(string cmd) m_consolecommand =
{
	tokenize(cmd);
	switch (argv(0))
	{
	default: break;
	}

	return FALSE;
};

void() m_shutdown =
{
};