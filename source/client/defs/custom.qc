/*
	client/defs/custom.qc

	Various globals that are used in this FTEQW example are defined 
    here, they are not used by the engine itself.

	Copyright (C) 2021-2024 NZ:P Team

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

float g_width, g_height; /* Globals for screen width and height */

float weapon;

float tracercounter;
.float rate;
.vector targetpos;

entity cl_viewent;
entity cl_viewent2;

float matchmake_enabled;
float double_tap_version;

float useprint_type;
float useprint_weapon;
float useprint_cost;
float useprint_time;

float active_gamemode;

float bettyprompt_time;

float hud_maxammo_endtime;
float hud_maxammo_starttime;

float nameprint_time;
float HUD_Change_time; 
float hitmark_time;
float hitmark_ignore_time;
float hitmark_type;
float recoil_kick_time;
float crosshair_pulse_grenade;
float zoom_2_time;

float broadcast_time;
float broadcast_type;
float broadcast_num;

string character_name;

#define MAX_REVIVE_ICONS	16

var struct revive_s {
	float draw;
	float timer;
	float state;
} revive_icons[MAX_REVIVE_ICONS];

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

float sniper_hold_breath;


float K_LEFTDOWN, K_RIGHTDOWN, K_BACKDOWN, K_FORWARDDOWN;

vector TEXT_LIGHTBLUE = [0, 0.46, 0.70];
vector TEXT_ORANGE    = [0.92, 0.74, 0];
vector TEXT_GREEN     = [0, 0.90, 0.13];
vector TEXT_RED       = [1, 0, 0];

float screenflash_type;
float screenflash_color;
float screenflash_duration;
float screenflash_worktime;
float screenflash_starttime;

.float stance;

vector camang;		// used for punches

//world text
string chaptertitle;
string location;
string date;
string person;

//custom hud
string huddir;

int 	platform_is_web;

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

//
// GamePad Input Variables
//
float GPButtonHeldBeginTime[24];	// Tracks time button down event is called, to track holding down for different actions.
float last_input_deviceid;			// The Device ID of the input hardware that last called CSQC_InputEvent, to target it directly.

string build_datetime;

vector gun_kick;

float hide_viewmodel;

// csqc player prediction by eukara
vector playerOrigin;
vector playerOriginOld;
vector playerVelocity;

//
// List of Zombie limb meshes for custom skinning
//
string zombie_skins[] =
{
	"models/ai/zb%.mdl",
	"models/ai/zbc%.mdl",
	"models/ai/zcfull.mdl",
	"models/ai/zhc^.mdl",
	"models/ai/zalc(.mdl",
	"models/ai/zarc(.mdl",
	"models/ai/zfull.mdl",
	"models/ai/zh^.mdl",
	"models/ai/zal(.mdl", 
	"models/ai/zar(.mdl"
};
