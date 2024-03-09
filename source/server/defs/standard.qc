/*
+----+
|Defs|
+----+-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| Scratch                                      Http://www.admdev.com/scratch |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
| This contains necessary definitions from the original V1.06 defs.qc file.  |
| This includes some basic constants, the built in function definitions, and |
| some variable's used by the Quake Engine internally.                       |
| Certain lines in this file are hardcoded into Quake engine, and -must- be  |
| present and unchanged, in the order they are shown. Otherwise Quake will   |
| refuse to run.                                                             |
+=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-+
*/

#define STANDARD

// These lines CANNOT be altered/moved
entity          self;
entity          other;
entity          world;
float           time;
float           frametime;
float           force_retouch;							// force all entities to touch triggers
string          mapname;
float 			deathmatch;
float 			coop;
float 			teamplay;
float           serverflags;							// propagated from level to level, used to
float           rounds;
float           rounds_change;
float           parm1, parm2, parm3, parm4, parm5, parm6, parm7, parm8, parm9, parm10, parm11, parm12, parm13, parm14, parm15, parm16;
vector          v_forward, v_up, v_right;				// set by makevectors()
float           trace_allsolid;
float           trace_startsolid;
float           trace_fraction;
vector          trace_endpos;
vector          trace_plane_normal;
float           trace_plane_dist;
entity          trace_ent;
float           trace_inopen;
float           trace_inwater;
entity          msg_entity;                             // destination of single entity writes
void()          main;                                   // only for testing
void()          StartFrame;
void()          EndFrame;
void()          PlayerPreThink;
void()          PlayerPostThink;
void()          ClientKill;
void()          ClientConnect;
void()          PutClientInServer;						// call after setting the parm1... parms
void()          ClientDisconnect;
void()          SetNewParms;							// called when a client first connects to
void()          SetChangeParms;							// call to set parms for self so they can
void()          ParseClientCommand;						// special command calls
string          CMD_STRING;
void()          Soft_Restart;
void            end_sys_globals;						// flag for structure dumping

.float          modelindex;								// *** model index in the precached list
.vector         absmin, absmax;							// *** origin + mins / maxs
.float          ltime;									// local time for entity
.float          movetype;
.float          solid;
.vector         origin;									// ***
.vector         oldorigin;								// ***
.vector         velocity;
.vector         angles;
.vector         avelocity;
.vector 		punchangle;								// temp angle adjust from damage or recoil
.string         classname;								// spawn function
.string         model;
.float          frame;
.float          skin;
.float          iframetime;
.float          effects;
.vector         mins, maxs;								// bounding box extents reletive to origin
.vector         size;									// maxs - mins
.void()         touch;
.void()         use;
.void()         think;
.void()         blocked;								// for doors or plats, called when can't push other
.float          nextthink;
.entity         groundentity;
.float          health;
.float          points;
.float          kills;
.float          weapon;									// one of the W_COLT, etc flags
.string         weaponmodel;
.string         weapon2model;
.float          weaponframe;
.float          weapon2frame;
.float          currentammo;
.float          currentmag;
.float			zoom;
.float          weaponskin;
.float          weapon2skin;
.float          primary_grenades;
.float          secondary_grenades;
.float          grenades;
.float          perks;									// bit flags
.float          takedamage;
.entity         chain;
.float          deadflag;
.vector         view_ofs;								// add to origin to get eye point
.float          button0;								//
.float          button1;								//
.float          button2;								//
.float 			button3;								//
.float 			button4;								//
.float 			button5;								//
.float 			button6;								//
.float 			button7;								//
.float 			button8;								//
.float          impulse;								// weapon changes
.float          fixangle;
.vector         v_angle;								// view / targeting angle for players
.float 			idealpitch;								// calculated pitch angle for lookup up slopes
.string         netname;
.entity         enemy;
.float          flags;
.float          colormap;
.float          team;
.float          max_health;								// players maximum health is stored here
.float          teleport_time;							// don't back up
.float          waterlevel;								// 0 = not in, 1 = feet, 2 = wast, 3 = eyes
.float          watertype;								// a contents value
.float          ideal_yaw;
.float          yaw_speed;
.entity         aiment;
.entity 		head;
.entity			larm;
.entity 		rarm;
.entity         goalentity; 							// a movetarget or an enemy
//.entity       goalorigin;                             // a movetarget location
.float          spawnflags;
.string         target;
.string         targetname;
.float       	bleed_out;
.float			progress_bar;
.entity         dmg_inflictor;
.entity         owner;									// who launched a missile
.vector         movedir;								// mostly for doors, but also used for waterjump
.string         message;								// trigger messages
.float          sounds;									// either a cd track number or sound number
.string         noise, noise1, noise2, noise3;			// contains names of wavs to play
.float			x2_icon;								// double points icon
.float			insta_icon;
.vector			ADS_Offset;
.vector         Flash_Offset;
.float 			Flash_Size;
.string			Weapon_Name;
.string			Weapon_Name_Touch;
.float          currentmag2;
.float          maxspeed;
.float     		facingenemy;
.float          scale;
void            end_sys_fields; 						// flag for structure dumping
// End. Lines below this MAY be altered, to some extent

// Built In functions
void    (vector ang)                                                                            makevectors         = #1;	// sets v_forward, etc globals
void    (entity e, vector o)                                                                    setorigin           = #2;
void    (entity e, string m)                                                                    setmodel            = #3;	// set movetype and solid first
void    (entity e, vector min, vector max)                                                      setsize             = #4;
void    ()                                                                                      break               = #6;
float   ()                                                                                      random              = #7;	// returns 0 - 1
void    (entity e, float chan, string samp, float vol, float atten)                             sound               = #8;
vector  (vector v)                                                                              normalize           = #9;
void    (string e)                                                                              error               = #10;
void    (string e)                                                                              objerror            = #11;
float   (vector v)                                                                              vlen                = #12;
float   (vector v)                                                                              vectoyaw            = #13;
entity  ()                                                                                      spawn               = #14;
void    (entity e)                                                                              remove              = #15;
void    (vector v1, vector v2, float nomonsters, entity forent)                                 traceline           = #16;
entity  ()                                                                                      checkclient         = #17;  // returns a client to look for
entity  (entity start, .string fld, string match)                                               find                = #18;
string  (string s)                                                                              precache_sound      = #19;
string  (string s)                                                                              precache_model      = #20;
void    (entity client, string s)                                                               stuffcmd            = #21;
entity  (vector org, float rad)                                                                 findradius          = #22;
void	(float level, string s)																	bprint				= #23;
void	(entity client, float level, string s)													sprint				= #24;
void    (string s)                                                                              dprint              = #25;
string  (float f)                                                                               ftos                = #26;
string  (vector v)                                                                              vtos                = #27;
void    ()                                                                                      coredump            = #28;  // prints all edicts
void    ()                                                                                      traceon             = #29;  // turns statment trace on
void    ()                                                                                      traceoff            = #30;
void    (entity e)                                                                              eprint              = #31;  // prints an entire edict
float   (float yaw, float dist)                                                                 walkmove            = #32;  // returns TRUE or FALSE
float   (entity zombie, float which, entity limb)                                               updateLimb          = #33;
float   (float yaw, float dist)                                                                 droptofloor         = #34;  // TRUE if landed on floor
void    (float style, string value)                                                             lightstyle          = #35;
float   (float v)                                                                               rint                = #36;  // round to nearest int
float   (float v)                                                                               floor               = #37;  // largest integer <= v
float   (float v)                                                                               ceil                = #38;  // smallest integer >= v
float   (entity e)                                                                              checkbottom         = #40;  // true if self is on ground
float   (vector v)                                                                              pointcontents       = #41;  // returns a CONTENT_*
float   (float f)                                                                               fabs                = #43;
vector  (entity e, float speed)                                                                 aim                 = #44;  // returns the shooting vector
float   (string s)                                                                              cvar                = #45;  // return cvar.value
void    (string s)                                                                              localcmd            = #46;  // put string into local que
entity  (entity e)                                                                              nextent             = #47;  // for looping through all ents
void  (vector o, vector d, float color, float count)                                         	particle            = #48;  // start a particle effect
void    ()                                                                                      ChangeYaw           = #49;  // turn towards self.ideal_yaw
float   (string name)                                                                         	GetSoundLen         = #50;
vector  (vector v)                                                                              vectoangles         = #51;
void    (float to, float f)                                                                     WriteByte           = #52;
void    (float to, float f)                                                                     WriteChar           = #53;
void    (float to, float f)                                                                     WriteShort          = #54;
void    (float to, float f)                                                                     WriteLong           = #55;
void    (float to, float f)                                                                     WriteCoord          = #56;
void    (float to, float f)                                                                     WriteAngle          = #57;
void    (float to, string s)                                                                    WriteString         = #58;
void    (float to, entity s)                                                                    WriteEntity         = #59;
string  (entity s)                                                                            	etos                = #65;
void    (float step)                                                                            movetogoal          = #67;
string  (string s)                                                                              precache_file       = #68;  // no effect except for -copy
void    (entity e)                                                                              makestatic          = #69;
void    (string s)                                                                              changelevel         = #70;
void    (float step, vector origin)                                                          	MoveToOrigin        = #71;
void    (string var, string val)                                                                cvar_set            = #72;  // sets cvar.value
void    (entity client, string s)                                                               centerprint         = #73;  // sprint, but in middle
void    (entity client, string s, string s)                                                  	centerprint2        = #73;
void    (entity client, string s, string s, string s)                                           centerprint3        = #73;
void    (entity client, string s, string s, string s, string s)                                 centerprint4        = #73;
void    (entity client, string s, string s, string s, string s, string s)                       centerprint5        = #73;
void    (entity client, string s, string s, string s, string s, string s, string s)             centerprint6        = #73;
void    (entity client, string s, string s, string s, string s, string s, string s, string s)   centerprint7        = #73;
void    (vector pos, string samp, float vol, float atten)                                       ambientsound        = #74;
string  (string s)                                                                              precache_model2     = #75;  // registered version only
string  (string s)                                                                              precache_sound2     = #76;  // registered version only
string  (string s)                                                                              precache_file2      = #77;  // registered version only
void    (entity e)                                                                              setspawnparms       = #78;  // set parm1... to the
void    (entity plr, float achievement)                                                         achievement         = #79;
float   (string s)                                                                              stof                = #81;  // 2001-09-20 QuakeC string manipulation by FrikaC
//void	(vector where, float set)																multicast			= #82;
vector  (entity what)                                                                           Get_Waypoint_Near   = #83;
float   (entity zombie, entity target)                                                          Do_Pathfind_psp     = #84;
void    (string s)                                                                              Open_Waypoint       = #85;
vector  (entity zombie,vector start,vector min, vector max)                                     Get_Next_Waypoint   = #86;
void    (entity client, float type, float cost, float weapon)                                   useprint            = #87;
vector  (entity zombie,vector start,vector min, vector max)                                     Get_First_Waypoint  = #88;
void    (string s)                                                                            	Close_Waypoint      = #89;
void    (vector start, vector min, vector max, vector end, float nomonsters, entity forent)   	tracebox            = #90;
entity  (entity start, .float field, float match)                                               findfloat           = #98;
float   (vector start, vector min, vector max, vector end, float nomonsters, entity forent)     tracemove           = #99;
// 2001-09-20 QuakeC file access by FrikaC  start
float   (string filename, float mode)                                                           fopen               = #110;
void    (float fhandle)                                                                         fclose              = #111;
string  (float fhandle)                                                                         fgets               = #112;
void    (float fhandle, string s)                                                               fputs               = #113;
float   (string s)                                                                              strlen              = #114;
string  (string s1, string s2)                                                                  strcat              = #115;
string  (string s, float start, float length)                                                   substring           = #116;
vector  (string s)                                                                              stov                = #117;
string  (string s)                                                                              strzone             = #118;
string  (string s)                                                                              strunzone           = #119;
string  (string s)                                                                              strtrim             = #120;
// 2001-09-20 QuakeC file access by FrikaC  end
// 2001-11-15 DarkPlaces general builtin functions by Lord Havoc  start
float(string s)                                                                                 tokenize            = #441;
string(float num)                                                                               argv                = #442;
// 2001-11-15 DarkPlaces general builtin functions by Lord Havoc  end
// DP_QC_STRING_CASE_FUNCTIONS
string  (string s)                                                                              strtolower          = #480;
float   (float caseinsensitive, string s)                                                       crc16               = #494;
void    (string trackname)                                                                    	songegg             = #500;
void    ()                                                                                   	nzp_maxammo         = #501;
void    (entity who)                                                                            grenade_pulse       = #502;
float   ()                                                                                      nzp_maxai           = #503;
void    (entity who)                                                                            nzp_bettyprompt     = #504;
void    (entity who, string name)                                                               nzp_setplayername   = #505;
void    (entity who, float version)                                                             nzp_setdoubletapver = #506;
void    (entity who, float color, float duration, float type)                                   nzp_screenflash     = #507;
//
// constants
//

#define     FALSE                       0
#define     TRUE                        1

// edict.flags
#define	    FL_FLY                      1
#define	    FL_SWIM					    2
#define	    FL_CLIENT                   8               // set for all client edicts
#define	    FL_INWATER                  16              // for enter / leave water splash
#define	    FL_MONSTER                  32
#define	    FL_GODMODE                  64              // player cheat
#define	    FL_NOTARGET                 128             // player cheat
#define	    FL_ITEM                     256             // extra wide size for bonus items
#define	    FL_ONGROUND                 512             // standing on something
#define	    FL_PARTIALGROUND            1024            // not all corners are valid
#define	    FL_WATERJUMP                2048            // player jumping out of water

// edict.movetype values
#define		MOVETYPE_NONE				0               // never moves
#define   	MOVETYPE_ANGLENOCLIP    	1
#define   	MOVETYPE_ANGLECLIP        	2
#define		MOVETYPE_WALK				3               // players only
#define		MOVETYPE_STEP				4               // discrete, not real time unless fall
#define		MOVETYPE_FLY				5
#define		MOVETYPE_TOSS				6               // gravity
#define		MOVETYPE_PUSH				7               // no clip to world, push and crush
#define		MOVETYPE_NOCLIP				8
#define		MOVETYPE_FLYMISSILE			9               // fly with extra size against monsters
#define		MOVETYPE_BOUNCE				10
#define		MOVETYPE_BOUNCEMISSILE		11              // bounce with extra size
#define		MOVETYPE_FOLLOW				12

#define 	MOVE_HITMODEL               0

// edict.solid values
#define     SOLID_NOT                   0               // no interaction with other objects
#define     SOLID_TRIGGER               1               // touch on edge, but not blocking
#define     SOLID_BBOX                  2               // touch on edge, block
#define     SOLID_SLIDEBOX              3               // touch on edge, but not an onground
#define     SOLID_BSP                   4               // bsp clip, touch on edge, block
#define     SOLID_CORPSE                5               // bsp clip, touch on edge, block

// range values
#define     RANGE_MELEE                 0
#define     RANGE_NEAR                  1
#define     RANGE_MID                   2
#define     RANGE_FAR                   3

// deadflag values
#define     DEAD_NO                     0
#define     DEAD_DYING                  1
#define     DEAD_DEAD                   2
#define     DEAD_RESPAWNABLE            3

// takedamage values
#define     DAMAGE_NO                   0
#define     DAMAGE_YES                  1
#define     DAMAGE_AIM                  2
#define     DAMAGE_NOMARKER             3

// point content values
#define     CONTENT_EMPTY               -1
#define     CONTENT_SOLID               -2
#define     CONTENT_WATER               -3
#define     CONTENT_SLIME               -4
#define     CONTENT_LAVA                -5
#define     CONTENT_SKY                 -6

//doors
#define		STATE_TOP					0
#define		STATE_BOTTOM				1
#define		STATE_UP					2
#define		STATE_DOWN					3

#define     VEC_ORIGIN                  '0 0 0'

// protocol bytes
#define     SVC_BAD                     0
#define     SVC_NOP                     1
#define     SVC_DISCONNECT              2
#define     SVC_UPDATESTAT              3
#define     SVC_VERSION                 4
#define     SVC_SETVIEW                 5
#define     SVC_SOUND                   6
#define     SVC_TIME                    7
#define     SVC_PRINT                   8
#define     SVC_STUFFTEXT               9
#define     SVC_SETANGLE                10
#define     SVC_SERVERINFO              11
#define     SVC_LIGHTSTYLE              12
#define     SVC_UPDATENAME              13
#define     SVC_UPDATEPOINTS            14
#define     SVC_CLIENTDATA              15
#define     SVC_STOPSOUND               16
#define     SVC_PARTICLE                18
#define     SVC_DAMAGE                  19
#define     SVC_SPAWNSTATIC             20
#define     SVC_SPAWNBINARY             21
#define     SVC_SPAWNBASELINE           22
#define     SVC_TEMPENTITY              23
#define     SVC_SETPAUSE                24
#define     SVC_SIGNONNUM               25
#define     SVC_CENTERPRINT             26
#define     SVC_SPAWNSTATICSOUND        29              // 1998-08-08 Complete SVC list by Zhenga
#define     SVC_INTERMISSION            30
#define     SVC_FINALE                  31
#define     SVC_CDTRACK                 32
#define     SVC_SELLSCREEN              33
#define     SVC_CUTSCENE               	34              // 1998-08-08 Complete SVC list by Zhenga
#define     SVC_WEAPONFIRE              35
#define		SVC_HITMARK					36
#define     SVC_USEPRINT                38
#define 	SVC_LIMBUPDATE  			51 				// naievil -- keep me
#define 	SVC_BSPDECAL    			50				// naievil -- keep me
#define 	SVC_ACHIEVEMENT 			52

#define     TE_SPIKE                    0
#define     TE_SUPERSPIKE               1
#define     TE_GUNSHOT                  2
#define     TE_EXPLOSION                3
#define     TE_TAREXPLOSION             4
#define     TE_LIGHTNING1               5
#define     TE_LIGHTNING2               6
#define     TE_WIZSPIKE                 7
#define     TE_KNIGHTSPIKE              8
#define     TE_LIGHTNING3               9
#define     TE_LAVASPLASH               10
#define     TE_TELEPORT                 11
#define     TE_RAYSPLASHGREEN           14
#define     TE_RAYSPLASHRED             15

// sound channels
// channel 0 never willingly overrides
// other channels (1-7) allways override a playing sound on that channel
// Player uses channel 5 for all weapon reload sfx
#define     CHAN_AUTO                   0
#define     CHAN_WEAPON                 1
#define     CHAN_VOICE                  2
#define     CHAN_ITEM                   3
#define     CHAN_BODY                   4
#define 	CHAN_NO_PHS_ADD				8				// ie: CHAN_BODY+CHAN_NO_PHS_ADD

#define     ATTN_NONE                   0
#define     ATTN_NORM                   1
#define     ATTN_IDLE                   2
#define     ATTN_STATIC                 3

// update types
#define     UPDATE_GENERAL              0
#define     UPDATE_STATIC               1
#define     UPDATE_BINARY               2
#define     UPDATE_TEMP                 3

// entity effects
#define	EF_BLUELIGHT			        1
#define	EF_MUZZLEFLASH 			        2
#define	EF_BRIGHTLIGHT 			        4
#define	EF_REDLIGHT 			        8
#define	EF_ORANGELIGHT			        16
#define	EF_GREENLIGHT			        32
#define	EF_PINKLIGHT			        64				// formerly EF_LIGHT
#define	EF_NODRAW				        128
#define EF_LIMELIGHT			        256				// formerly EF_BRIGHTFIELD
#define EF_FULLBRIGHT			        512
#define EF_CYANLIGHT			        1024			// formerly EF_DARKLIGHT
#define EF_YELLOWLIGHT			        2048			// formerly EF_DARKFIELD
#define EF_PURPLELIGHT    		        4096
#define EF_RAYRED	 			        8196			// red trail for porter x2
#define EF_RAYGREEN  			        16384			// green trail for ray gun

// messages
#define     MSG_BROADCAST               0               // unreliable to all
#define     MSG_ONE                     1               // reliable to one (msg_entity)
#define     MSG_ALL                     2               // reliable to all
#define     MSG_INIT                    3               // write to the init string
#define		MSG_MULTICASE				4				// for multicast() call

// message levels
#define     PRINT_LOW					0				// pickup messages
#define     PRINT_MEDIUM				1				// death messages
#define     PRINT_HIGH					2				// critical messages
#define     PRINT_CHAT					3				// also goes to chat console

#define     AS_STRAIGHT                 1
#define     AS_SLIDING                  2
#define     AS_MELEE                    3
#define     AS_MISSILE                  4

// multicast sets
#define		MULTICAST_ALL				0				// every client
#define		MULTICAST_PHS				1				// within hearing
#define		MULTICAST_PVS				2				// within sight
#define		MULTICAST_ALL_R				3				// every client, reliable
#define		MULTICAST_PHS_R				4				// within hearing, reliable
#define		MULTICAST_PVS_R				5				// within sight, reliable

// file operations
#define		FILE_READ 	 				0
#define		FILE_APPEND 				1
#define		FILE_WRITE 					2
