
float player_name_cursor;
string player_name;

float server_ip_cursor;
string server_ip;

float server_hostname_cursor;
string server_hostname;

float server_password_cursor;
string server_password;

float server_port_cursor;
string server_port;

int num_cached_servers;

void() Menu_Coop_Name_Update =
{
	static float initialized;
	if (!initialized)
	{
		player_name = cvar_string("name");
		player_name_cursor = strlen(player_name);
		initialized = true;
	}
	else
	{
		cvar_set("name", player_name);
	}
};

void() Menu_Coop_Hostname_Update =
{
	static float initialized;
	if (!initialized)
	{
		server_hostname = cvar_string("hostname");
		server_hostname_cursor = strlen(server_hostname);
		initialized = true;
	}
	else
	{
		cvar_set("hostname", server_hostname);
	}
};

void() Menu_Coop_Port_Update =
{
	static float initialized;
	if (!initialized)
	{
		server_port = cvar_string("sv_port");
		server_port_cursor = strlen(server_port);
		initialized = true;
	}
	else
	{
		cvar_set("sv_port", server_port);
	}
};

void() Menu_Coop_Password_Update =
{
	static float initialized;
	if (!initialized)
	{
		server_password = cvar_string("password");
		server_password_cursor = strlen(server_password);
		initialized = true;
	}
	else
	{
		cvar_set("password", server_password);
	}
};

void() Menu_Coop_Browse_Refresh =
{
	static float refreshtime;

	if (refreshtime > time)
		return;

	refreshtime = time + 0.1;

	resethostcachemasks();
	// TODO: figure out why this returns 0 servers
	// sethostcachemaskstring(0, gethostcacheindexforkey("gamedir"), cvar_string("game"), SLIST_TEST_EQUAL);
	sethostcachesort(gethostcacheindexforkey("ping"), false);
	refreshhostcache(false);
	resorthostcache();

	num_cached_servers = (int)gethostcachevalue(SLIST_HOSTCACHEVIEWCOUNT);
};

void() Menu_Coop_Browse =
{

	Menu_Coop_Browse_Refresh();

	Menu_DrawBackground();

	Menu_DrawTitle("BROWSE SERVERS");

	// draw server list
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	static vector serverlist_scrollofs;
	vector vsize = sui_current_frame_size();
	Menu_ServerList("cbm_serverlist", [0, 0], [vsize.x, vsize.y / 2], serverlist_scrollofs, num_cached_servers);

	Menu_Button(-1, "cbm_back", "BACK", "Return to Join Game Menu.") ? current_menu = MENU_COOPJOIN : 0;

	sui_pop_frame();
};

void() Menu_Coop_Direct =
{
	Menu_Coop_Password_Update();

	Menu_DrawBackground();

	Menu_DrawTitle("DIRECT IP/ID");

	Menu_Button(1, "cdm_serverip", "SERVER IP/ROOM ID", "IP or ID for the Server (typically starts with /).");
	Menu_TextInput("cdm_serverip", 1, server_ip, server_ip_cursor);

	Menu_Button(2, "cdm_serverpassword", "SERVER PASSWORD", "Password for the Match set by the Host (optional).");
	Menu_PasswordInput("cdm_serverpassword", 2, server_password, server_password_cursor);

	Menu_DrawDivider(3);
	Menu_Button(3.25, "cdm_connect", "CONNECT TO SERVER", "Attempt to connect to Game.") ? localcmd("connect ", server_ip, "\n") : 0;

	Menu_Button(-1, "cdm_back", "BACK", "Return to Join Game Menu.") ? current_menu = MENU_COOPJOIN : 0;

	sui_pop_frame();
};

void() Menu_Coop_Join =
{
	Menu_DrawBackground();

	Menu_DrawTitle("JOIN GAME");

	Menu_Button(1, "cjm_browse", "BROWSE SERVERS", "Browse the list of active Servers.") ? current_menu = MENU_COOPBROWSE : 0;
	Menu_Button(2, "cjm_direct", "DIRECT IP/ID", "Connect directly to an active Server.") ? current_menu = MENU_COOPDIRECT : 0;

	Menu_Button(-1, "cjm_back", "BACK", "Return to Co-Op Menu.") ? current_menu = MENU_COOP : 0;

	sui_pop_frame();
};

void() Menu_Coop_Create =
{
	Menu_Coop_Hostname_Update();
	Menu_Coop_Port_Update();
	Menu_Coop_Password_Update();

	Menu_DrawBackground();

	Menu_DrawTitle("CREATE GAME");

	Menu_Button(1, "ccm_servername", "SERVER NAME", "Enter a name that will appear in the Server List.");
	Menu_TextInput("ccm_servername", 1, server_hostname, server_hostname_cursor);

	Menu_Button(2, "ccm_port", "SERVER PORT", "Edit the port that the Server will use.");
	Menu_TextInput("ccm_port", 2, server_port, server_port_cursor);

	Menu_Button(3, "ccm_password", "SERVER PASSWORD", "Enter an (optional) password to limit who can join.");
	Menu_PasswordInput("ccm_password", 3, server_password, server_password_cursor);

	Menu_DrawDivider(4);
	Menu_Button(4.25, "ccm_choosemap", "CHOOSE MAP", "Select a Map to start the Game.") ? Menu_StartCoop() : 0;

	Menu_Button(-1, "ccm_back", "BACK", "Return to Co-Op Menu.") ? current_menu = MENU_COOP : 0;

	sui_pop_frame();
};

void() Menu_Coop =
{
	Menu_Coop_Name_Update();

	Menu_DrawBackground();

	Menu_DrawTitle("COOPERATIVE");

	Menu_Button(1, "cm_playername", "PLAYER NAME", "Name that appears in-game and on the Scoreboard.");
	Menu_TextInput("cm_playername", 1, player_name, player_name_cursor);

	Menu_DrawDivider(2);
	Menu_Button(2.25, "cm_join", "JOIN GAME", "Join an in-progress Match.") ? current_menu = MENU_COOPJOIN : 0;
	Menu_Button(3.25, "cm_create", "CREATE GAME", "Create a new Match for others to join.") ? current_menu = MENU_COOPCREATE : 0;

	Menu_Button(-1, "cm_back", "BACK", "Return to Main Menu.") ? current_menu = MENU_MAIN : 0;

	sui_pop_frame();
};
