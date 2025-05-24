#define true    1
#define false   0

string build_datetime;
float music_duration_time;

string menu_background;
float menu_changetime;
float menu_starttime;

string current_selected_bsp;

float last_map_menu;
float current_menu;
float running_platform;

float last_input_was_gamepad;

float loading_into_server;
string map_name_override;

#ifdef MENU

float last_input_deviceid;

#endif // MENU

enum {
    PLATFORM_WIN,
    PLATFORM_MAC,
    PLATFORM_LIN,
    PLATFORM_XBX,
    PLATFORM_AND,
    PLATFORM_WEB,
    PLATFORM_BSD,
    PLATFORM_IOS,
    PLATFORM_DOS,
    PLATFORM_UNK
};

enum {
    MENU_NONE,
    MENU_MAIN,
    MENU_SOLO,
    MENU_SOLOUSER,
    MENU_COOP,
    MENU_COOPJOIN,
    MENU_COOPBROWSE,
    MENU_COOPDIRECT,
    MENU_COOPCREATE,
    MENU_COOPSTOCK,
    MENU_COOPUSER,
    MENU_OPTIONS,
    MENU_VIDEO,
    MENU_AUDIO,
    MENU_CONTROL,
    MENU_GAMEPAD,
    MENU_BINDINGS,
    MENU_ACCESSIBILITY,
    MENU_CREDITS,
    MENU_PAUSE,
    MENU_LOBBY,
    MENU_GAMESETTINGS
};

#define MENU_SND_NAVIGATE 	0
#define MENU_SND_ENTER 		1
#define MENU_SND_BEEP       2
void(float type) Menu_PlaySound;

#ifdef MENU

void() Menu_Main;
void() Menu_Maps;
void() Menu_Coop;
void() Menu_Coop_Join;
void() Menu_Coop_Browse;
void() Menu_Coop_Direct;
void() Menu_Coop_Create;
void() Menu_Credits;
void() Menu_Lobby;
void() Menu_GameSettings;

#else

void() Menu_Pause;

#endif // MENU

void() Menu_Options;
void() Menu_Video;
void() Menu_Audio;
void() Menu_Control;
void() Menu_Gamepad;
void() Menu_Bindings;
void() Menu_Accessibility;

#ifdef MENU

string(string prev_id) Menu_Main_GetNextButton;
string(string next_id) Menu_Main_GetPreviousButton;

string(string next_id) Menu_Coop_Browse_GetNextButton;
string(string next_id) Menu_Coop_Direct_GetNextButton;
string(string next_id) Menu_Coop_Join_GetNextButton;
string(string next_id) Menu_Coop_Create_GetNextButton;
string(string next_id) Menu_Coop_GetNextButton;

string(string next_id) Menu_Coop_Browse_GetPreviousButton;
string(string next_id) Menu_Coop_Direct_GetPreviousButton;
string(string next_id) Menu_Coop_Join_GetPreviousButton;
string(string next_id) Menu_Coop_Create_GetPreviousButton;
string(string next_id) Menu_Coop_GetPreviousButton;

string(string prev_id) Menu_Maps_GetNextButton;
string(string next_id) Menu_Maps_GetPreviousButton;

string(string prev_id) Menu_Lobby_GetNextButton;
string(string next_id) Menu_Lobby_GetPreviousButton;

string(string prev_id) Menu_GameSettings_GetNextButton;
string(string next_id) Menu_GameSettings_GetPreviousButton;

#else

string(string prev_id) Menu_Pause_GetNextButton;
string(string next_id) Menu_Pause_GetPreviousButton;

#endif // MENU

string(string prev_id) Menu_Options_GetNextButton;
string(string next_id) Menu_Options_GetPreviousButton;
string(string prev_id) Menu_Video_GetNextButton;
string(string next_id) Menu_Video_GetPreviousButton;
string(string prev_id) Menu_Audio_GetNextButton;
string(string next_id) Menu_Audio_GetPreviousButton;
string(string prev_id) Menu_Control_GetNextButton;
string(string next_id) Menu_Control_GetPreviousButton;
string(string prev_id) Menu_Gamepad_GetNextButton;
string(string next_id) Menu_Gamepad_GetPreviousButton;
string(string prev_id) Menu_Bindings_GetNextButton;
string(string next_id) Menu_Bindings_GetPreviousButton;
string(string prev_id) Menu_Accessibility_GetNextButton;
string(string next_id) Menu_Accessibility_GetPreviousButton;

enum {
    MAP_SOLOSTOCK,
    MAP_SOLOUSER,
    MAP_COOPSTOCK,
    MAP_COOPUSER
};
float menu_map_mode;

#define USER_MAPS_MAX   512

// Map content data structure
var struct
{
	float 	occupied;
	float 	map_allow_game_settings;
	float 	map_use_thumbnail;
	string 	map_name;
	string 	map_name_pretty;
    string  map_desc[8];
	string 	map_author;
} user_maps[USER_MAPS_MAX];
float user_maps_count;
float user_maps_page;

// Built-in (stock) maps, array_index
// is populated later.
var struct
{
    string bsp_name;
    float array_index;
} stock_maps[] =
{
    {"ndu", 0},
    {"nzp_warehouse", 0},
    {"nzp_warehouse2", 0},
    {"christmas_special", 0}
};
