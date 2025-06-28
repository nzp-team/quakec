
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

void() Menu_Coop_UpdateName =
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

void() Menu_Coop_UpdateHostname =
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

void() Menu_Coop_UpdatePort =
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

void() Menu_Coop_UpdatePassword =
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

// this flushes the server cache
void() Menu_Coop_RefreshCache =
{
	static float refreshtime;

	if (refreshtime > time)
		return;

	refreshtime = time + 0.5;

	// reset cache masks
	resethostcachemasks();

	// set the masks to our gamedir and game strings
	sethostcachemaskstring(0, gethostcacheindexforkey("gamedir"), cvar_string("game"), SLIST_TEST_EQUAL);

	// set sort value to ping (ascending)
	sethostcachesort(gethostcacheindexforkey("ping"), false);

	// flush the current cache and refresh it
	refreshhostcache(true);

	// resort the cache (by ping)
	resorthostcache();

	// get number of cached servers
	num_cached_servers = (int)gethostcachevalue(SLIST_HOSTCACHEVIEWCOUNT);
};

// this updates the current server cache
void() Menu_Coop_UpdateCache =
{
	static float refreshtime;
	static float initialized;

	if (!initialized)
	{
		Menu_Coop_RefreshCache();
		initialized = true;
	}

	if (refreshtime > time)
		return;

	refreshtime = time + 0.5;

	// call this every 0.5 seconds to keep probing the cache, but without flushing everything
	num_cached_servers = (int)gethostcachevalue(SLIST_HOSTCACHEVIEWCOUNT);
};

void() Menu_Coop_Browse =
{
	Menu_Coop_UpdateCache();

	Menu_DrawBackground();

	Menu_DrawTitle("BROWSE SERVERS");

	// draw server list
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	static vector serverlist_scrollofs;
	vector vsize = sui_current_frame_size();
	Menu_ServerList("cbm_serverlist", [0, 0], [vsize.x, vsize.y / 2], serverlist_scrollofs, num_cached_servers);

	Menu_Button(-2, "cbm_refresh", "REFRESH", "Refresh server list.") ? Menu_Coop_RefreshCache() : 0;
	Menu_Button(-1, "cbm_back", "BACK", "Return to Join Game Menu.") ? current_menu = MENU_COOPJOIN : 0;

	// draw tooltip
	if (!sui_is_hovered("cbm_refresh") && !sui_is_hovered("cbm_back"))
	{
		sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
		sui_text([0, -30], MENU_TEXT_MEDIUM, "NOTE: Keyboard or gamepad is not supported for server selection.", [1, 1, 1], 1, 0);
	}

	sui_pop_frame();
};

void(string ip) Menu_Coop_Connect =
{
	Menu_PlaySound(MENU_SND_ENTER);
	m_toggle(false);
	localcmd("connect ", ip, "\n");
	map_name_override = "OVERRIDE";
};

void() Menu_Coop_Direct =
{
	Menu_Coop_UpdatePassword();

	Menu_DrawBackground();

	Menu_DrawTitle("DIRECT IP/ID");

	Menu_Button(1, "cdm_serverip", "SERVER IP/ROOM ID", "IP or ID for the Server (typically starts with /).");
	Menu_TextInput("cdm_serverip", 1, server_ip, server_ip_cursor);

	Menu_Button(2, "cdm_serverpassword", "SERVER PASSWORD", "Password for the Match set by the Host (optional).");
	Menu_PasswordInput("cdm_serverpassword", 2, server_password, server_password_cursor);

	Menu_DrawDivider(3);
	Menu_Button(3.25, "cdm_connect", "CONNECT TO SERVER", "Attempt to connect to Game.") ? Menu_Coop_Connect(server_ip) : 0;

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
	Menu_Coop_UpdateHostname();
	Menu_Coop_UpdatePort();
	Menu_Coop_UpdatePassword();

	Menu_DrawBackground();

	Menu_DrawTitle("CREATE GAME");

	Menu_Button(1, "ccm_servername", "SERVER NAME", "Enter a name that will appear in the Server List.");
	Menu_TextInput("ccm_servername", 1, server_hostname, server_hostname_cursor);

	Menu_Button(2, "ccm_port", "SERVER PORT", "Edit the port that the Server will use.");
	Menu_TextInput("ccm_port", 2, server_port, server_port_cursor);

	Menu_Button(3, "ccm_password", "SERVER PASSWORD", "Enter an (optional) password to limit who can join.");
	Menu_PasswordInput("ccm_password", 3, server_password, server_password_cursor);

	// Max players
	Menu_Button(4, "ccm_maxplayers", "MAX PLAYERS", "Change the maximum number of players who can join your server.") ? 0 : 0;
    Menu_CvarSlider(4, [1, 8, 7], "maxplayers", true, false, false);

	Menu_DrawDivider(5);
	Menu_Button(5.25, "ccm_choosemap", "CHOOSE MAP", "Select a Map to start the Game.") ? Menu_StartCoop() : 0;

	Menu_Button(-1, "ccm_back", "BACK", "Return to Co-Op Menu.") ? current_menu = MENU_COOP : 0;

	sui_pop_frame();

	cvar_set("maxclients", cvar_string("maxplayers"));
};

void() Menu_Coop_EnterCreate =
{
	localcmd("saveconfig user_settings.cfg\n");
	localcmd("maxplayers 4\n");
	current_menu = MENU_COOPCREATE;
};

void() Menu_Coop_EnterJoin =
{
	localcmd("saveconfig user_settings.cfg\n");
	current_menu = MENU_COOPJOIN;
};

void() Menu_Coop_EnterBack =
{
	localcmd("saveconfig user_settings.cfg\n");
	current_menu = MENU_MAIN;
};

void() Menu_Coop =
{
	Menu_Coop_UpdateName();

	Menu_DrawBackground();

	Menu_DrawTitle("COOPERATIVE");

	Menu_Button(1, "cm_playername", "PLAYER NAME", "Name that appears in-game and on the Scoreboard.");
	Menu_TextInput("cm_playername", 1, player_name, player_name_cursor);

	Menu_DrawDivider(2);
	Menu_Button(2.25, "cm_join", "JOIN GAME", "Join an in-progress Match.") ? Menu_Coop_EnterJoin() : 0;
	Menu_Button(3.25, "cm_create", "CREATE GAME", "Create a new Match for others to join.") ? Menu_Coop_EnterCreate() : 0;

	Menu_Button(-1, "cm_back", "BACK", "Return to Main Menu.") ? Menu_Coop_EnterBack() : 0;

	sui_pop_frame();
};

string menu_coop_browse_buttons[] = {
	"cbm_serverlist", "cbm_refresh", "cbm_back"
};

string menu_coop_direct_buttons[] = {
	"cdm_serverip", "cdm_serverpassword", "cdm_connect", "cdm_back"
};

string menu_coop_join_buttons[] = {
	"cjm_browse", "cjm_direct", "cjm_back"
};

string menu_coop_create_buttons[] = {
	"ccm_servername", "ccm_port", "ccm_password", "ccm_choosemap", "ccm_back"
};

string menu_coop_buttons[] = {
	"cm_playername", "cm_join", "cm_create", "cm_back"
};

// can you tell i'm a C user at heart? -- erysdren

#define NEXTBUTTON_FUNC(fn, arr) 				\
string(string prev_id) fn ## _GetNextButton =	\
{ 												\
	if (prev_id == "") 							\
		return arr[0]; 							\
												\
	string ret = arr[0];						\
												\
	for(float i = 0; i < arr.length; i++) {		\
		if (arr[i] == prev_id) {				\
			if (i + 1 >= arr.length)			\
				break;							\
												\
			ret = arr[i + 1];					\
			break;								\
		}										\
	}											\
												\
	return ret;									\
};

NEXTBUTTON_FUNC(Menu_Coop_Browse, menu_coop_browse_buttons)
NEXTBUTTON_FUNC(Menu_Coop_Direct, menu_coop_direct_buttons)
NEXTBUTTON_FUNC(Menu_Coop_Join, menu_coop_join_buttons)
NEXTBUTTON_FUNC(Menu_Coop_Create, menu_coop_create_buttons)
NEXTBUTTON_FUNC(Menu_Coop, menu_coop_buttons)

#undef NEXTBUTTON_FUNC

#define PREVBUTTON_FUNC(fn, arr) 					\
string(string next_id) fn ## _GetPreviousButton =	\
{													\
	if (next_id == "")								\
		return arr[arr.length - 1];					\
													\
	string ret = arr[arr.length - 1];				\
													\
	for(float i = arr.length - 1; i > 0; i--) {		\
		if (arr[i] == next_id) {					\
			if (i - 1 < 0)							\
				break;								\
													\
			ret = arr[i - 1];						\
			break;									\
		}											\
	}												\
													\
	return ret;										\
};

PREVBUTTON_FUNC(Menu_Coop_Browse, menu_coop_browse_buttons)
PREVBUTTON_FUNC(Menu_Coop_Direct, menu_coop_direct_buttons)
PREVBUTTON_FUNC(Menu_Coop_Join, menu_coop_join_buttons)
PREVBUTTON_FUNC(Menu_Coop_Create, menu_coop_create_buttons)
PREVBUTTON_FUNC(Menu_Coop, menu_coop_buttons)

#undef PREVBUTTON_FUNC
