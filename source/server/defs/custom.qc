/*
	server/defs/custom.qc

	put custom server-only globals and fields here

	Copyright (C) 2021-2022 NZ:P Team

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

#ifndef QUAKESPASM
#ifndef HANDHELD
#pragma target FTE
#endif // HANDHELD
#endif // QUAKESPASM

#define true 				1
#define false 				0

#define FL_JUMPRELEASED  	4096

#define STR_NOTENOUGHPOINTS	"Not Enough Points\n"	// To help aid consistency with these..

// Quake assumes these are defined.
string 	string_null;
.string killtarget;
entity 	activator;
float 	framecount;
float 	deathmatch;
float 	coop;

#ifndef PC
void(string com) SV_ParseClientCommand;
.float	gravity;
.float	recoil_delay;
#ifndef HANDHELD
.float 	mapversion;
#endif
.float	ammo;
#endif

// achievement tracking
.float 	ach_tracker_npnp;
.float 	ach_tracker_abst;
.float 	ach_tracker_coll;
float 	ach_tracker_col2;
float 	ach_tracker_barr;
float 	ach_tracker_spin;
float 	ach_tracker_luck;

.vector oldvelocity;
.float lastsound_time;
.float isspec;
string mappath;
.float playernum;
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
void(entity person, float expamt , float doublepoint) addmoney;

//stats
.float score;
.float kills;
.float headshots;
#ifdef PC
.float facingenemy;
#endif

//doors
.float state;
#define STATE_TOP		0
#define STATE_BOTTOM	1
#define STATE_UP		2
#define STATE_DOWN		3
.float /*worldtype,*/ delay, wait, lip, /*light_lev,*/ speed, style/*, skill*/;

.float requirespower;

//player funcs
#ifdef PC
.float zoom;
#endif

.float damage_timer;								// Used for time-based damage infliction such as Traps.
.float speed_penalty;								// A multiplier for limiting player speed. Also 
													// prohibits sprinting.
.float speed_penalty_time;							// A timer for how long speed_penalty is applied for.

float sprint_max_time = 4.0;
.float sprinting;
.float weaponskin;
.float secondaryweaponskin;
.float thirdweaponskin;
.float stamina;
.float sprint_timer;
.float sprint_duration;
.float sprint_timer_stopped;
.float sprint_start_time;
.float sprint_stop_time;
.float sprint_rest_time;
void() W_SprintStop;
.float into_sprint;
.float dive;
.float dive_delay;
.vector movement;

//Weaponsystem defines
void SwitchWeapon(float to);
void GetUp();
void Weapon_Logic();
.float downed;
.float fire_delay;
.float fire_delay2;
.float reload_delay;
.float reload_delay2;
.float switch_delay;
.float health_delay;
.float progress_bar;
.float progress_bar_time;
.float progress_bar_percent;
.float weaponbk;
.float currentmag;
.float currentmag2;
.float currentmagbk;
.float currentmagbk2;
.float currentammobk;
.float secondaryammo;
.float thirdammo;
.float semi;
.float semi2;
.float semiuse;
.float semiswitch;		// Weapon Swap Toggle
.float seminade;		// Grenade Toggle
.float semireload;
.float secondarymag;
.float secondarymag2;
.float secondaryweapon;
.float thirdmag;
.float thirdmag2;
.float thirdweapon;
.float NeedLoad;
.string weapon2model;
.float weapon2frame;
.float reloadinterupted;
.float hitcount;
.float weaponnum;	// 0 for weapon one, 1 for second weapon...we invert value for easy comparison, a third gun would need to be hardwired

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
.float semiknife;
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

//Null functions
void() SUB_Null = {};
void() SUB_Null2 = {};

#define 	VEC_HULL_MIN  		'-16 -16 -32'
#define 	VEC_HULL_MAX  		'16 16 40'
#define 	VEC_HULL2_MIN   	'-32 -32 -24'
#define 	VEC_HULL2_MAX  		'32 32 64'

#define     VEC_VIEW_OFS  '0 0 32'

#ifndef HANDHELD
#define 	MAX_ZOMBIES 		24
#else
#define 	MAX_ZOMBIES 		12
#endif // HANDHELD

vector	trace_plane_normal;

//
// AI definitions
// Used for global one-zombie-at-a-time type ai
//
void Do_Zombie_AI();
void Z_ElectroShock();

.float electro_targeted; 							// Marks Zombie as waiting to die via Electro-Shock
.float death_timer; 								// A timer that will kill a Zombie when it expires.
.float death_timer_activated; 						// To prevent Zombies just dying because of this..

.string aistatus;
entity lastzombie;
float zombie_spawn_delay; // time before spawning, in seconds.
float zombie_spawn_timer; // the actual timer for spawn delay
//Other AI definitions
.vector box1, box2, box3;//used for windows and zombies
.vector idlebox;
.vector hop_spot;//used for windows (zombies hop to these)
.vector goalorigin;
.float teslacount;
.float iszomb;
.float onfire;
.entity firer;
float crawler_num;
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
float z_health;
.float bleedingtime;
.float time_to_die;


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
float isPowerOn;
.float isBuying; // naievil -- used for checking if a perk is being consumed, limits glitching
.float perks;
.float perk_delay;
.float revivesoda;
.float collected;

.float boxstatus;
.entity boxweapon;
.float spins;
.float papState;
float BoxWeapons[25];
entity boxLocations[32];
float boxCount;
vector boxOrigin;

#ifdef PC
//powerups
.float x2_icon;
.float insta_icon;
#endif // PC
.string powerup_vo;
float instakill_finished;
float insta_blink;
float x2_finished;
float x2_blink;
float total_windows_down;
float total_powerup_points;
float powerup_score_threshold;
float powerup_activate;
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
float game_over;
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
float cl_navmesh_edit_mode;
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

#ifdef PC
waypoint_ai waypoints[MAX_WAYPOINTS];

// fog
string world_fog;

// lights 
#define EF_PURPLELIGHT		256		// fte already has some effect styles defined...
#endif

#define UT_HUD 				1
#define UT_ROUNDS_CHANGE 	2
#define UT_HM				3
#define UT_ZOOM2			4
#define UT_CROSSHAIR		5

//======================= Navmesh defs ============================
#ifdef PC
void() Navmesh_Editor_Logic;
void() sv_load_navmesh_data;
//One struct for temp pathfinding calculations per zombie 
//navmesh_pathfind_result sv_zombie_pathfind_result[MAX_ZOMBIES];
navmesh_pathfind_result *sv_zombie_pathfind_result; // Used as primary. The one that's followed
navmesh_pathfind_result *sv_zombie_pathfind_result_aux; // Used as secondary, so we can pathfind without losing current path
#endif // PC

//=================================================================
//========================== AI defs ==============================


// -----------–-----------–-----------–-----------–-----------–-----------–----
// Animation Definitions
// -----------–-----------–-----------–-----------–-----------–-----------–----
// For the animation system, we could define each animation as the start and 
// end frame range, but we'd like to be able to compose animations out of 
// frame numbers that are not contiguous (e.g. frames=[0,1,5,6,2,3]).
// To pull this off, we need to treat animations as a list of frame numbers.

// For the animation system, we want to pass around pointers to thse arrays so
// that an entity can keep track of the frame list for its current animation.
// However, QC only allows for function pointers. Meaning, that if we want to 
// pass around these animations, then we can only pass them around as function 
// pointers. Thus, we must create two functions for each frame list, one for 
// each thing we would need to do to a read-only array: 
//      - access an index
//      - get the array length

// To pull this off, we'd need to define the following two functions for 
// every animation:
// float get_anim_frame_zombie_walk1(float frame_idx) {float frames[] = {38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53}; return frames[frame_idx]};
// float get_anim_length_zombie_walk1(float frame_idx) {float frames[] = {38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53}; return frames.length};

// But, instead of doing that for _every_ animation, the following preprocessor
// directive will generate the above two functions from the single statement:
// DEFINE_ANIM(zombie_walk1, 38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53);

// After the above statement, the functions `get_anim_frame_zombie_walk1` and
// `get_anim_length_zombie_walk1` have been defined and are now available to 
// use and pass around.
// -----------–-----------–-----------–-----------–-----------–-----------–----
#define DEFINE_ANIM( ANIM_NAME, ...); \
    float get_anim_frame_##ANIM_NAME## (float frame_idx) {float frames[] = {__VA_ARGS__}; return frames[frame_idx];}; \
    float get_anim_length_##ANIM_NAME## () {float frames[] = {__VA_ARGS__}; return frames.length;};
// -----------–-----------–-----------–-----------–-----------–-----------–----

enum anim_stop_type:float {
    ANIM_STOP_TYPE_STOP, // Animation stops and freezes at final frame.
    ANIM_STOP_TYPE_LOOP, // Animation starts again from the first frame.
    ANIM_STOP_TYPE_NEXT_ANIM, // Another animation is played when this one finishes.
};


class AI_Chase : entity {
    // framegroup_registry *th_reg;
    entity path_target; // If specified, path towards entity
    vector path_pos; // Otherwise, path towards location specified
    float state;
    float substate;

    // -----------------------------
    // Traversal state vars
    // -----------------------------
    float cur_traversal_idx;
    float cur_traversal_end_time;
    float cur_traversal_start_time;


    // Regardless of what animation we're playing (or not playing), we have a think callback
    virtual void() think_callback = SUB_Null;
    // We also have a frame callback that's called each time we reach a new animation frame.
    virtual void() frame_callback = SUB_Null;

    // ------------------------------
    // Animation variables
    // ------------------------------
    // --- Current animation vars ---
    virtual float(float) cur_anim_get_frame_func = (float(float)) SUB_Null; // Gets frame number from frame index.      Assign to `get_anim_frame_{ANIM_NAME}`, as generated by DEFINE_ANIM
    float cur_anim_length;                                                  // The length of the current animation.     Assign to `get_anim_length_{ANIM_NAME}()`, as generated by DEFINE_ANIM)
    float cur_anim_frametime;                                               // Time (in seconds) between frames, 0.1 for 10FPS
    anim_stop_type cur_anim_stop_type;                                      // ANIM_STOP_TYPE_STOP, ANIM_STOP_TYPE_LOOP, or ANIM_STOP_TYPE_NEXT_ANIM
    // --- Next / Queued animation vars ---
    virtual float(float) next_anim_get_frame_func = (float(float)) SUB_Null;    // Gets frame number from frame index.      Assign to `get_anim_frame_{ANIM_NAME}`, as generated by DEFINE_ANIM
    float next_anim_length;                                                     // The length of the current animation.     Assign to `get_anim_length_{ANIM_NAME}()`, as generated by DEFINE_ANIM)
    float next_anim_frametime;                                                  // Time (in seconds) between frames, 0.1 for 10FPS
    anim_stop_type next_anim_stop_type;                                         // ANIM_STOP_TYPE_STOP or ANIM_STOP_TYPE_LOOP
    // --- Current animation state vars ---
    float cur_anim_start_time;
    float cur_anim_frame_idx; // Counter from 0 to `cur_anim_n_frames`
    // ------------------------------


    float pathfind_result_idx; // TODO - Need to increment this on instantiation
    float pathfind_cur_point_idx;


    // Constructor. Called when calling `spawn(AI_Chase);`
    virtual void() AI_Chase;
    virtual void() think;


    // Stop what you're doing and play this animation immediately.
    virtual void(float(float) anim_frame_func, float anim_length, anim_stop_type stop_type) play_anim = {
        // Assign Animation Vars
        this.cur_anim_get_frame_func = anim_frame_func;
        this.cur_anim_length = anim_length;
        this.cur_anim_stop_type = stop_type;
        this.cur_anim_frametime = 0.1;

        // Reset Animation state Vars
        this.cur_anim_start_time = time;
        this.cur_anim_frame_idx = 0;
        this.frame = anim_frame_func(0);
    };

    // Queue up another animation to play when the current one finishes
    virtual void(float(float) anim_frame_func, float anim_length, anim_stop_type stop_type) queue_anim {
        // This isn't allowed, we can't queue more than one animation.
        // Queued animation stop type must be: ANIM_STOP_TYPE_STOP, or ANIM_STOP_TYPE_LOOP
        if(stop_type == ANIM_STOP_TYPE_NEXT_ANIM) {
            return;
        }
        // Indicate that we have a next animation queued up the next time the current animation finishes.
        this.cur_anim_stop_type = ANIM_STOP_TYPE_NEXT_ANIM;

        this.next_anim_get_frame_func = anim_frame_func;
        this.next_anim_length = anim_length;
        this.next_anim_stop_type = stop_type;
        this.next_anim_frametime = 0.1;
    };



    // virtual void () fg_die = {};
    // virtual void () fg_walk = {};
    // virtual void () fg_attack = {};
    // virtual void () fg_idle = {};

    virtual void (float dist) do_walk_to_goal;
};


class AI_Zombie : AI_Chase {
    entity enemy; // If near, attack

    // Constructor. Called when calling `spawn(AI_Zombie);`
    // virtual void() AI_Zombie = {};
    // This should be called explicitly:
    virtual void(vector org) init;

    // virtual void () fg_die;
    // virtual void () fg_walk;
    // virtual void () fg_attack;
    // virtual void () fg_idle;

    // static void () setup_frames = {
    //     // this.zombie_idle_frames = {1,2,3,4,5,6,7,8,9,10,11,12,13};
    //     // this.cur_frames = zombie_idle_frames;
    //     // FIXME - I can't figure out a way to assign an array...
    //     // Even if I convert an animation to a struct, I can't do arbitrary-length arrays...
    //     // I also can't fill them in in this convenient syntax... it's ridiculous.
    // };
};

// AI_Zombie.zombie_idle_frames = {1,2,3,4,5,6,7,8,9,10,11,12,13};

//=================================================================


//Misc patch definitions
.string teddyremovetarget;

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

//song easter egg
float sndTriggerCnt;
float sndActivCnt;
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

#ifdef QUAKESPASM
.float sprintflag;
#endif

// PC Fog force
.float PC_fog;

// hl stuff
.float rendermode;
.float renderamt;
.vector rendercolor;

float revive_index;


void() test_new_ent;
