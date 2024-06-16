/*
	server/defs/custom.qc

	put custom server-only globals and fields here

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

#ifndef STANDARD
#pragma target fte_5768
#endif // STANDARD

#define true 				1
#define false 				0

#define FL_JUMPRELEASED  	4096

#define STR_NOTENOUGHPOINTS	"Not Enough Points\n"	// To help aid consistency with these..

#define SPAWN_1_CLASS       "info_player_1_spawn"
#define SPAWN_2_CLASS       "info_player_2_spawn"
#define SPAWN_3_CLASS       "info_player_3_spawn"
#define SPAWN_4_CLASS       "info_player_4_spawn"

float cheats_have_been_activated;

// Quake assumes these are defined.
string 	string_null;
.string killtarget;
entity 	activator;
float 	framecount;

float music_override;

.float	recoil_delay;
.float 	cur_spread;

#ifndef FTE

void(string com) SV_ParseClientCommand;
.float	gravity;
.float 	mapversion;
.float	ammo;
.float 	frags;

#endif // FTE

// achievement tracking
.float 	ach_tracker_npnp;
.float 	ach_tracker_abst;
.float 	ach_tracker_coll;
float 	ach_tracker_col2;
float 	ach_tracker_barr;
float 	ach_tracker_spin;

float global_trace_damage_multiplier;

.float has_ads_toggle;
.float ads_release;
.float has_doubletap_damage_buff;

.vector oldvelocity;
.float lastsound_time;
.float isspec;
string mappath;
.float ads_toggle;
float player_count;
entity pl1;
.string fog;		// used for hacking in changing fog from world.fog for legacy maps

entity local_client;
.float stance;
.float stancereset;
.float changestance;
.vector new_ofs;

//money
.float points;
.float cost;
.float cost2;

//stats
.float score;
.float kills;
.float headshots;

#ifdef FTE

.float facingenemy;

#endif // FTE

//doors
.float state;
#define STATE_TOP		0
#define STATE_BOTTOM	1
#define STATE_UP		2
#define STATE_DOWN		3
.float /*worldtype,*/ delay, wait, lip, /*light_lev,*/ speed, style/*, skill*/;

.float requirespower;

//player funcs

#ifdef FTE

.float zoom;

#endif // FTE

.float damage_timer;								// Used for time-based damage infliction such as Traps.
.float speed_penalty;								// A multiplier for limiting player speed. Also 
													// prohibits sprinting.
.float speed_penalty_time;							// A timer for how long speed_penalty is applied for.

float sprint_max_time = 4.0;
.float sprinting;
.float weaponskin;
.float stamina;
.float sprint_timer;
.float sprint_duration;
.float sprint_timer_stopped;
.float sprint_start_time;
.float sprint_stop_time;
.float sprint_rest_time;
.float tp_anim_time;
.float tp_anim_type;
void() W_SprintStop;
.float into_sprint;
.float dive;
.float dive_delay;
.vector movement;

.float hunt_count; // How many Hellhounds are hunting a client

//Weaponsystem defines
void GetUp();
void WeaponCore_ClientLogic();
void (float shotcount, float sprd, float Damage, float side) FireTrace;
.float downed;
.float fire_delay;
.float fire_delay2;
.float reload_delay;
.float reload_delay2;
.float switch_delay;
.float health_delay;
.float health_was_very_low;
.float progress_bar;
.float progress_bar_time;
.float progress_bar_percent;
.float weaponbk;
.float currentmag;
.float currentmag2;
.float currentmagbk;
.float currentmagbk2;
.float currentammobk;
.float NeedLoad;
.string weapon2model;
.float weapon2frame;
.float reloadinterupted;
.float hitcount;

#ifdef FTE

.float weapon2modelindex;

#endif // FTE

#define SEMIACTION_FIRE_RIGHT	1
#define SEMIACTION_FIRE_LEFT 	2
#define SEMIACTION_USE			4
#define SEMIACTION_GRENADE		8
#define SEMIACTION_MELEE		16
#define SEMIACTION_WAYPOINT		32
#define SEMIACTION_WEAPONSWAP	64

// Semi-automatic actions (requires button release)
.float semi_actions;

#define MAX_PLAYER_WEAPONS 		3
#define MULEKICK_WEAPON_SLOT	3

var struct guninventory_struct
{
	float 	weapon_id;
	float 	weapon_magazine;
	float 	weapon_magazine_left;
	float 	weapon_reserve;
	float 	weapon_skin;
	float 	is_mulekick_weapon;
};

.guninventory_struct weapons[MAX_PLAYER_WEAPONS];
.float weapon_count;

//Reviving
.float invoke_revive;
.float reviving;
.float revived;
.float beingrevived;
.float downedloop;

#define S_LEFT 0
#define S_RIGHT 1
#define S_BOTH 2

//Knife 
.float knife_delay;
.float bowie;

//Grenades
.float grenades;
.float pri_grenade_state;
.float bk_nade;
.float grenade_delay;
.float secondary_grenades;
.float primary_grenades;
.float throw_delay;

//weapon frames
void Set_W_Frame (float startframe, float endframe, float duration, float funccalledin, float animtype, void(optional float t) endanimfunc, string set_model, float dontstartnew, float side);
.float weapon_animduration;
.float weapon2_animduration;
.float weapon_anim_type;
.float weapon2_anim_type;
.float anim_weapon_time;
.float anim_weapon2_time;
.float weaponframe_end;
.float weapon2frame_end;
.float callfuncat;
.float callfuncat2;
.float new_anim_stop;
.float new_anim2_stop;
.float anim_reversed;
.float anim2_reversed;
.void() animend;
.void(optional float t) animend2;

string(string path) Compat_ConvertOldAssetPath;

//Null functions
void() SUB_Null = {};
void() SUB_Null2 = {};

#define 	VEC_HULL_MIN  		'-16 -16 -36'
#define 	VEC_HULL_MAX  		'16 16 36'
#define 	VEC_HULL2_MIN   	'-32 -32 -24'
#define 	VEC_HULL2_MAX  		'32 32 64'

#define 	VIEW_OFS_HL 		'0 0 32'
#define 	VIEW_OFS_QK			'0 0 22'

.string name;
vector	trace_plane_normal;

.float dmg;
.float fire_timeout;

//
// AI definitions
// Used for global one-zombie-at-a-time type ai
//
void Do_Zombie_AI();
void Z_ElectroShock();

.float electro_targeted; 							// Marks Zombie as waiting to die via Electro-Shock
.float death_timer; 								// A timer that will kill a Zombie when it expires.
.float death_timer_activated; 						// To prevent Zombies just dying because of this..
.float is_attacking; 								// Returns true if Zombie is in the middle of an attack.

#ifndef FTE

entity lastzombie;									// Used by non-FTE to update zombie AI one ent at a time.

#endif // FTE

.string aistatus;
float zombie_spawn_delay; // time before spawning, in seconds.
float zombie_spawn_timer; // the actual timer for spawn delay
//Other AI definitions
.vector box1, box2, box3;//used for windows and zombies
.vector idlebox;
.vector hop_spot;//used for windows (zombies hop to these)
.vector goalorigin;

.float teslacount; // TODO - Remove this

.float tesla_n_kills; // Player - Number of kills remaining for the current tesla shot
.float tesla_next_arc_time; // Zombie - Time at which zombie should try arcing
.float tesla_arc_num; // Zombie - current arc number
.entity tesla_arc_parent; // Zombie - Track the entity that we arced from
.entity tesla_arc_owner; // Zombie - Player ent that fired the tesla
void(vector pos) tesla_spark;



.float iszomb;
.float onfire;
.entity firer;
float crawler_num;
float zombie_spawn_points;
//==== Reference Vars ====
#define 	WWINDOW		1
#define 	WBOX1 		2
#define 	WBOX2 		4
#define 	WBOX3 		8
#define		WIDLEBOX 	16
//========================

// Definitions for the `.dimension_hit` and `.dimension_solid` fields
// Used to let limbs be non-solid to player bbox but still be hit by player tracelines
#define HITBOX_DIM_LIMBS 1
#define HITBOX_DIM_ZOMBIES 2

//we're using usedent for who is currently hopping the window
//Used for windows to keep track of what zombies are at windows
.entity box1owner, box2owner, box3owner;

.entity usedent;
//.float used;//used for the window boxes//not anymore
.float outside;//used for knowing if a zomibe has hopped window yet
.float chase_enemy_time;
.float chase_time;
.float enemy_timeout;
//.float pathing;
.float calc_time; 									// used as a delay thing (so zombie ai doesn't run
													// 100% of the time
.string zappername;									// An identifier similar to targetname used to link
													// Electric Trap components.
.string target2;
.string target3;
.string target4;
.string target5;
.string target6;
.string target7;
.string target8;
.string wayTarget;
.entity active_door;								// Set in waypoint mode
.string targetname;									// the name of an entitys
entity lastspawn;									// last spawn point used by spawning code
.entity goaldummy; 									// Used to store the origin of the zombies target
.float goalway; 									// Used to store the origin of the zombies target
.float walktype;									// decides animations and moving speeds for zombies
.float spawn_id;									// assigned to spawn point ents, for grabbing one at random.
.void() th_walk;
//.void() th_run;
.void() th_die;
.void() th_melee;
.void() th_idle;
.void() th_windowhop;
.void() th_diewunder;

.void() th_fall;
.void() th_falling;
.void() th_land;

.void() th_jump;
.void() th_grabledge;
.float tries;
.float hop_step;//KEEPS TRACK OF WHERE WE ARE ON THE HOPPING PART

float INACTIVE = 1;

float tracemove(vector start, vector min, vector max, vector end, float nomonsters, entity forent);

.float way_path[40];
.float way_cur;

.float sound_time;
.float s_time;
float sounds_playing;

.float fall;
//.vector lastOrg;//Zombie's last origin, for checking stuckness
//.float OrgStuckCount;
.float crawling;

.float washit;
.float hitamount;

.float laststep;
void(entity who) makeCrawler;
.float state;//used to delay making a crawler, ex) when zombie is rising from ground or climbing over barrier, turn zombie into a crawler afterwards

void() spawnAllZombEnts;
void() set_z_health;
float() spawn_a_zombieA;
float gotdog;
float dogRound;
float dogWave;
float dog_round_count;
float z_health;
.float bleedingtime;
.float time_to_die;

.float respawn_timer;
.float respawn_iterator;

float crandom();


// Door
.void() think1;
.vector finaldest;
.vector pos1, pos2/*, mangle*/;
.vector finalangle;
.float distance;
.float sequence;
.entity active_door;
.string door_model_target;
.string door_model_name;

//Perk and Power system

#define PERK_QUICKREVIVE_DEFAULT_MODEL	"models/machines/quake_scale/quick_revive.mdl"
#define PERK_JUGGERNOG_DEFAULT_MODEL	"models/machines/quake_scale/juggernog.mdl"
#define PERK_SPEEDCOLA_DEFAULT_MODEL	"models/machines/quake_scale/speed_cola.mdl"
#define PERK_DOUBLETAP_DEFAULT_MODEL	"models/machines/quake_scale/double_tap.mdl"
#define PERK_PHDFLOPPER_DEFAULT_MODEL	"models/machines/quake_scale/flopper.mdl"
#define PERK_STAMINUP_DEFAULT_MODEL		"models/machines/quake_scale/staminup.mdl"
#define PERK_DEADSHOT_DEFAULT_MODEL		"models/machines/quake_scale/deadshot.mdl"
#define PERK_MULEKICK_DEFAULT_MODEL		"models/machines/quake_scale/mulekick.mdl"

float isPowerOn;
.float isBuying; // naievil -- used for checking if a perk is being consumed, limits glitching
.float perks;
.float perk_delay;

.float perk_purchase_count;
.float perk_purchase_limit_solo;
.float perk_purchase_limit_coop;
.float perk_requires_power_solo;
.float perk_requires_power_coop;

// Mystery Box
#define MAX_BOX_WEAPONS 		27

.float 	boxstatus;
.entity boxweapon;
.float 	spins;
.float 	papState;

var struct mbox_struct
{
	float weapon_id; 			// ID for the relevant weapon.
	float allowed;				// 1 for allowed, 0 for denied.
	float rarity;				// 0-100 (float) percent change for obtaining. -1 for normal.
	float already_obtained;		// true if only one allowed and a client already holds it.
} mystery_box_weapons[MAX_BOX_WEAPONS] = {};

float 	mystery_box_count;
float 	mystery_box_leave_count;
float 	mystery_box_cost;
string 	mystery_box_model;
string 	mystery_box_glow_model;
string 	mystery_box_open_sound;
string 	mystery_box_close_sound;
entity 	mystery_boxes[16];
vector 	mystery_box_start_origin;

#ifdef FTE

//powerups
.float x2_icon;
.float insta_icon;

#endif // FTE

.string powerup_vo;
float instakill_finished;
float insta_blink;
float x2_finished;
float x2_blink;
float total_windows_down;
float total_powerup_points;
float powerup_score_threshold;
float powerup_activate;
float carp_powerup_active;
float nuke_powerup_active;
float nuke_powerups_activated;
float nuke_powerup_spawndelay;

//rounds
float roundinit;
float roundtype;
float Current_Zombies;
float Total_Zombies;
float Remaining_Zombies;
float Delay_Time;
float spawn_time;
float round_changetime;
float blink_return;
float delay_at_round;
float spawn_delay;
float maxreward;
float totalreward;
float totalpowerups;
float sounds_playing;

float rounds;
float rounds_change;

//Waypoints
void () Waypoint_Logic;
entity current_way;
float waypoint_mode;
entity active_way;

#define MAX_WAY_TARGETS		10
.string waynum;
.string targets[MAX_WAY_TARGETS];


//pathfinds
#define MAX_WAYPOINTS 256 //max waypoints
void LoadWaypointData();
typedef struct
{
	vector org;
	float id;
	float g, f;
	float next, prev;
	float step;
	float target_id [MAX_WAY_TARGETS]; // Targets array number
	string targetdoor; //special tag is required for the closed waypoints
	float dist [MAX_WAY_TARGETS]; // Distance to the next waypoints
	float set;
} waypoint_ai;

#define SET_NONE	0
#define SET_OPEN	1
#define SET_CLOSED	2

#ifdef FTE

waypoint_ai waypoints[MAX_WAYPOINTS];

#endif // FTE

#define UT_HUD 				1
#define UT_ROUNDS_CHANGE 	2
#define UT_HM				3
#define UT_ZOOM2			4
#define UT_CROSSHAIR		5

//Misc patch definitions
.string teddyremovetarget;
.float entity_removed;

.float oldz;		// used for fall damage that does not truly work correctly

.float sprint_delay;

//soft restart stuff for doors
.string oldmodel;
.vector oldorigin;
.float oldstate;
.float state;
.float isopen;

//world
.string chaptertitle;
.string location;
.string date;
.string person;
.string song;

//altered game elements
float G_STARTPOINTS;
float G_STARTROUND;
float G_PRONEPOINTS;
float G_STARTWEAPON[3];
float G_WORLDTEXT;
float G_PERKS;
float G_PERKPOWER;

.float activated;

//teleporter
.entity tele_target;
.float mode;
.float cooldown;
.float isLinked;
.float waitLink;
.float tpTimer;
.float isTimed;
.entity host;
.entity entities[4];

// GIBBING
.entity larm;
.entity rarm;
.entity head;
.vector	bbmins, bbmaxs;	
.float currentHitBoxSetup;

.float sprintflag;

// hl stuff
.float rendermode;
.float renderamt;
.vector rendercolor;

float revive_index;

#ifdef FTE
.float last_solid;
.float had_solid_modified;
#endif // FTE