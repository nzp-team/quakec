#define true    1
#define false   0

string build_datetime;
float music_duration_time;

string menu_background;
float menu_changetime;


float current_menu;
float running_platform;

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
    MENU_OPTIONS,
    MENU_VIDEO,
    MENU_AUDIO,
    MENU_CONTROL,
    MENU_GAMEPAD,
    MENU_CREDITS,
    MENU_HELP
};

#define MENU_SND_NAVIGATE 	0
#define MENU_SND_ENTER 		1
void(float type) Menu_PlaySound;

void() Menu_Main;
void() Menu_Maps;
void() Menu_Options;
void() Menu_Video;
void() Menu_Audio;
void() Menu_Control;
void() Menu_Gamepad;
void() Menu_Credits;

enum {
    MAP_SOLOSTOCK,
    MAP_SOLOUSER,
    MAP_COOPSTOCK,
    MAP_COOPUSER
};
float menu_map_mode;

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
} user_maps[500];
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