/*
	client/defs/custom.qc

	Various globals that are used in this FTEQW example are defined 
    here, they are not used by the engine itself.

	Copyright (C) 2021 NZ:P Team

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program; if not, write to:

		Free Software Foundation, Inc.
		59 Temple Place - Suite 330
		Boston, MA  02111-1307, USA

*/

#pragma warning disable Q302

vector cursor_pos; /* Current mouse cursor position, updated in csqc_inputevent */
float g_width, g_height; /* Globals for screen width and height */

float walk;

//Menu stuff
float in_menu; //what menu are we in
float time_in_menu;

// Loading screen definitions
float in_loadscreen;
float loadscreen_timetrigger;
string loadscreen_mapname;
string loadscreen_maptitle;
string loadscreen_tip;

entity player;
entity vmodel;
entity v2model;
entity mzlflash;
entity dummy;

float weapon;

float tracercounter;
.float rate;
.vector targetpos;

vector vmodel_targetpos;
vector v2model_targetpos;
vector vmodel_currentpos;
vector v2model_currentpos;
vector vmodel_velocity;
vector v2model_velocity;
vector vmodel_avelocity;
vector v2model_avelocity;
vector vmodel_muzzleoffset;
vector v2model_muzzleoffset;

const float MENU_NONE 			= 0;
const float MENU_MAIN 			= 1;
const float MENU_SINGLE 		= 2;
const float MENU_MULTI 			= 4;
const float MENU_SETTINGS 		= 8;
const float MENU_ABOUT 			= 16;
const float MENU_JOIN 			= 32;
const float MENU_PAUSE 			= 64;
const float MENU_IGS 			= 128;
const float MENU_RES 			= 256;
const float MENU_GSETTINGS 		= 512;
const float MENU_CSETTINGS 		= 1024;
const float MENU_CUSTOMS 		= 2048;
const float MENU_ACHIEVEMENTS	= 4096;
const float MENU_CONSETTINGS 	= 8192;
const float MENU_AUDSETTINGS 	= 16384;
const float MENU_CREATE 		= 32768;

float matchmake_enabled;
float double_tap_version;

float useprint_type;
float useprint_weapon;
float useprint_cost;
float useprint_time;

float bettyprompt_time;

string scrolltext;
float stext;
float scrollopacity;
float scrollheight;

float nameprint_time;
float HUD_Change_time; 
float Hitmark_time;
float crosshair_spread_time;
float crosshair_pulse_grenade;
float zoom_2_time;
float broadcast_time;
float broadcast_type;
string broadcast_string;

var struct revive_s {
	float draw;
	float timer;
	float state;
	float org[3];
} revive_icons[4];

float active_revive_icons;

float weaponframetime;
float weapon2frametime;
float oldweaponframe;
float oldweapon2frame;
float curweaponframe;
float curweapon2frame;
float interpolating;
float interpolating2;


float rounds;
float perks;
float rounds_change;
float player_count;
float score_show;

#define MAX_ACHIEVEMENTS    42

var struct achievementlist_t
{
    string      img;
    float       unlocked;
    string      name;
    string      description;
    float       progress;
} achievements[MAX_ACHIEVEMENTS];

float active_achievement;
float current_achievement_page;
float achievement_pages;


float K_LEFTDOWN, K_RIGHTDOWN, K_BACKDOWN, K_FORWARDDOWN;

#define 	P_JUG		1
#define 	P_DOUBLE	2
#define 	P_SPEED		4
#define 	P_REVIVE	8
#define 	P_FLOP		16
#define 	P_STAMIN	32

vector TEXT_LIGHTBLUE = [(2/255), (118/255), (181/255)];
vector TEXT_ORANGE    = [(235/255), (189/255), 0];
vector TEXT_GREEN     = [0, (230/255), (34/255)];
vector TEXT_RED       = [1, 0, 0];

float fade_time;
float fade_type;

.float stance;
.float points;
.float kills;

float menu_initialized;

float customs_interact;

vector camang;		// used for punches

//world text
string chaptertitle;
string location;
string date;
string person;

//custom hud
string huddir;

//this just cleans up settings a bit..
#define     S_ENABLED       "Enabled"
#define     S_DISABLED      "Disabled"
float wasigs;

//controls
#define MAX_BINDS   14

float editBind[MAX_BINDS];
string buttonBind[MAX_BINDS];
string tempBind[MAX_BINDS];

// resolution
float aspectratio;
float fullscreenval;
float active_swidth;
float active_sheight;

int 	platform_is_web;

#define 	OPTION_EXE_ONLY 	0
#define 	OPTION_WEB_ONLY 	1
#define 	OPTION_WEB_AND_EXE	2

// Stopwatch server time counter
float 	stopwatch_sec;
int 	stopwatch_min;
int 	stopwatch_hr;

// Same dealio, but for rounds
float 	stopwatch_round_sec;
int 	stopwatch_round_min;
int 	stopwatch_round_hr;
int 	stopwatch_round_isactive;
float 	stopwatch_round_starttime;

//controller buttons

/*
    reference:
    0: A
    1: B
    2: X
    3: Y
    4: DPAD UP
    5: DPAD DOWN
    6: DPAD LEFT
    7: DPAD RIGHT

*/
float GPActive[32];

string build_datetime;
#define VERSION_STRING  "v1.0"

vector gun_kick;

float hide_viewmodel;

// csqc player prediction by eukara
vector playerOrigin;
vector playerOriginOld;
vector playerVelocity;

//
// Screen sizes, self-explanatory.
//
var struct screenres_s
{
	float width;
	float height;
};

screenres_s screen_resolution_5x4[] =
{
	{1280, 1024}
};

screenres_s screen_resolution_4x3[] =
{
	{640, 480},
	{800, 600},
	{1024, 768}
};

screenres_s screen_resolution_16x9[] =
{
	{640, 360},
	{1280, 720},
	{1360, 768},
	{1366, 768},
	{1536, 864},
	{1600, 900},
	{1920, 1080},
	{2048, 1152},
	{2560, 1440},
	{3840, 2160}
};

screenres_s screen_resolution_16x10[] =
{
	{1280, 800},
	{1440, 900},
	{1680, 1050},
	{1920, 1200},
	{2560, 1600}
};

screenres_s screen_resolution_21x9[] =
{
	{2560, 1080},
	{3840, 1440}
};