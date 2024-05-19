/*
	shared/defs/custom.qc

	shared definitions

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

#define true    1
#define false   0

//
// CSQC Particle Types
//
#define CSQC_PART_MUZZLEFLASH			0 	// View Entity Muzzleflashes.
#define CSQC_PART_EXPLOSION 			1	// Explosion effect.
#define CSQC_PART_BLOODIMPACT			2 	// Blood Impact effect.
#define CSQC_PART_ZOMBIEGIB				3	// Zombie Gib effect.
#define CSQC_PART_FIRE					4 	// Fire/flame effect.

//
// CSQC Broadcast Messages
//
#define CSQC_BROADCAST_NONE				0 	// ""
#define CSQC_BROADCAST_PLAYERDOWNED		1	// "$ needs to be revived"
#define CSQC_BROADCAST_BEINGREVIVED		2	// "$ is reviving you"
#define CSQC_BROADCAST_REVIVINGPLAYER	3	// "Reviving $"

//
// CSQC Event Types
//
#define CSQC_EVENT_PARTICLE				10	// <byte> particle_type
											// <coord> pos_x
											// <coord> pos_y
											// <coord> pos_z
											// <byte> optional_field
											// <entity> optional_entity

#define CSQC_EVENT_USEPRINT				11	// <byte> useprint_type
											// <short> useprint_cost
											// <byte> useprint_weapon

#define CSQC_EVENT_ROUNDCHANGE			12	// <byte> round

#define CSQC_EVENT_BROADCASTMESSAGE		13	// <byte> broadcast_message_type
											// <byte> broadcast_time
											// <byte> player_number

#define CSQC_EVENT_MAXAMMOTEXT			14	// NO DATA.

#define CSQC_EVENT_MUSICSTREAM			15	// <string> track_name

#define CSQC_EVENT_GIVEACHIEVEMENT		16 	// <byte> achievement_index

#define CSQC_EVENT_PLAYERNAME			17 	// <string> player_name

#define CSQC_EVENT_SCREENFLASH			18 	// <byte> screenflash_color
											// <byte> screenflash_duration
											// <byte> screenflash_type

#define EVENT_UPDATE 					19
#define EVENT_BLACKOUT 					20
#define EVENT_WORLDDATA 				21
#define EVENT_PLAYERUPDATE 				22
#define EVENT_REVIVEON 					23
#define EVENT_REVIVEOFF 				24
#define EVENT_REVIVECHANGE 				25
#define EVENT_WEAPONRECOIL 				26
#define EVENT_GRENADEPULSE 				27
#define EVENT_BETTYPROMPT 				28
#define EVENT_CHATMESSAGE				29
#define EVENT_DOUBLETAPUPDATE 			30
#define EVENT_ENDGAME					31
#define EVENT_MAPTYPE					32

//
// Types of screen-flashes, global.
//

// Colors
#define SCREENFLASH_COLOR_WHITE			0
#define SCREENFLASH_COLOR_BLACK			1

// Types
#define SCREENFLASH_FADE_INANDOUT		0
#define SCREENFLASH_FADE_IN 			1
#define SCREENFLASH_FADE_OUT 			2

// Define our FTE platform
#ifndef STANDARD
#define FTE
#endif // STANDARD

// Player Hull Sizes
// 32x32x72
#define PLAYER_MINS_STANDING 	'-16 -16 -32'
#define PLAYER_MAXS_STANDING 	'16 16 40'

// 32x32x56
#define PLAYER_MINS_QUAKE 		'-16 -16 -24'
#define PLAYER_MAXS_QUAKE 		'16 16 32'

// 32x32x36
#define PLAYER_MINS_CROUCHING	'-16 -16 -32'
#define PLAYER_MAXS_CROUCHING 	'16 16 4'

#define PLAYER_STANCE_STAND		2
#define PLAYER_STANCE_CROUCH	1
#define PLAYER_STANCE_PRONE		0

// map compatibility
#define MAP_COMPAT_BETA     1
float 	map_compatibility_mode;

// Weapon Firetype definitions
#define FIRETYPE_FULLAUTO	0
#define FIRETYPE_SEMIAUTO	1
#define FIRETYPE_ROCKET		2
#define FIRETYPE_GRENADE	3
#define FIRETYPE_RAYBEAM	4
#define FIRETYPE_TESLA		5
#define FIRETYPE_FLAME		6

//nzp weapon defines
//id list
#define W_NOWEP        0
#define W_COLT 		   1
#define W_KAR 		   2
#define W_THOMPSON 	   3
#define W_357		   4
#define W_BAR		   5
#define W_BK		   6
#define W_BROWNING	   7
#define W_DB		   8
#define W_FG		   9
#define W_GEWEHR	   10
#define W_KAR_SCOPE	   11
#define W_M1		   12
#define W_M1A1		   13
#define W_M2		   14
#define W_MP40		   15
#define W_MG		   16
#define W_PANZER	   17
#define W_PPSH		   18
#define W_PTRS		   19
#define W_RAY		   20
#define W_SAWNOFF	   21
#define W_STG		   22
#define W_TRENCH	   23
#define W_TYPE		   24
#define W_BOWIE		   25
#define W_GRENADE      26
#define W_BETTY   	   27
#define W_BIATCH       28
#define W_KILLU        29 //357
#define W_COMPRESSOR   30 // Gewehr
#define W_M1000        31 //garand
#define W_KOLLIDER     32
#define W_PORTER       33 // Ray
#define W_WIDDER       34 // M1A1
#define W_FIW          35 //upgraded flamethrower
#define W_ARMAGEDDON   36 //Kar
#define W_WUNDER       37
#define W_GIBS         38 // thompson
#define W_SAMURAI      39 //Type
#define W_AFTERBURNER  40 //mp40
#define W_SPATZ        41 // stg
#define W_SNUFF        42 // sawn off
#define W_BORE         43 // double barrel
#define W_IMPELLER     44 //fg
#define W_BARRACUDA    45 //mg42
#define W_ACCELERATOR  46 //M1919 browning
#define W_GUT          47 //trench
#define W_REAPER       48 //ppsh
#define W_HEADCRACKER  49 //scoped kar
#define W_LONGINUS     50 //panzer
#define W_PENETRATOR   51 //ptrs
#define W_WIDOW        52 //bar
#define W_KRAUS        53 //ballistic
#define W_MP5K         54
#define W_M14          55

#define W_TESLA  	   56
#define W_DG3    	   57
#define W_SPRING       58
#define W_PULVERIZER   59

//Custom Weapons
//FIXME - use array?
#define W_CUSTOM1 	   70
#define W_CUSTOM2	   71
#define W_CUSTOM3 	   72
#define W_CUSTOM4 	   73


#define BASE_FRAME			1	// The frame the Weapon idles at
#define FIRE_START 			2	// Start of firing animation
#define FIRE_HOLD 			3	// Stay on this frame while holding fire
#define FIRE_END 			4	// End of firing animation
#define RELOAD_START 		5	// Start of normal (one-way) reloads
#define RELOAD_END 			6	// End of normal (one-way) reloads
#define RELOAD_EMPTY_START	7	// Start of empty reloading
#define RELOAD_EMPTY_END	8	// End of empty reloading
#define RELOAD_PART_START	9	// Start of partial full reloading
#define RELOAD_PART_END 	10	// End of partial full reloading
#define SPRINT_IN_START		11	// Start of preparation to sprint
#define SPRINT_IN_END 		12	// End of preparation to sprint
#define SPRINT_START		13	// Start of sprint loop
#define SPRINT_END 			14	// End of sprint loop
#define SPRINT_OUT_START 	15	// Start of sprint stop
#define SPRINT_OUT_END 		16	// End of sprint stop
#define TAKE_OUT_START		17	// Start of taking out weapon
#define TAKE_OUT_END 		18	// End of taking out weapon
#define FIRST_TAKE_START	19  // The "first raise" (first time weapon is taken)
#define FIRST_TAKE_END 		20	// End of "first raise"
#define PUT_OUT_START 		21	// Start of putting away weapon
#define PUT_OUT_END 		22	// End of putting away weapon
#define RELOAD_CANCEL 		23	// Frame where mag variable is filled
#define AIM_IN        		24	// Frame to snap to when in ADS (optional)
#define AIM_FIRE_START      25	// Start of firing while ADS (optional)
#define AIM_FIRE_END        26	// End of firing while ADS (optional)
#define MELEE_NORMAL_START	27 	// Start of normal (non-lunged) melee frame, for melee weapons
#define MELEE_NORMAL_END	28 	// End of normal (non-lunged) melee frame, for melee weapons
#define MELEE_LUNGED_START	29 	// Start of lunged melee frame, for melee weapons
#define MELEE_LUNGED_END	30 	// End of lunged melee frame, for melee weapons

//Animation types
#define RELOAD			1
#define GRENADE			2
#define FIRE			3
#define SWITCHWEP		4
#define KNIFE			5
#define ZOOM			6
#define SPRINT			7
#define PERK			8
#define KNIFE2			9
#define REVIVE			10
#define RELOAD_EMP 		11
#define RELOAD_PAR 		12
#define PUTOUT 			13
#define TAKEOUT 		14
#define MELEE_NORMAL	15
#define MELEE_LUNGED 	16

#define S_HEADSHOT	1
#define S_KNIFE		2
#define S_NORMAL	3
#define S_ZOMBIE	4
#define S_EXPLOSIVE	5
#define S_ZAPPER	6
#define S_TESLA 	7
#define S_FLAME		8

//Perk types
#define 	P_JUG		1
#define 	P_DOUBLE	2
#define 	P_SPEED		4
#define 	P_REVIVE	8
#define 	P_FLOP		16
#define 	P_STAMIN	32
#define 	P_DEAD 		64
#define 	P_MULE 		128

#define STAT_VIEWZOOM 			21

#define STAT_CURRENTMAG         50
#define STAT_CURRENTMAG2        51
#define STAT_POINTS             52
#define STAT_WEAPON2FRAME       53
#define STAT_WEAPON2MODELI      54
#define STAT_GRENADES   	    55
#define STAT_SECGRENADES    	56
#define STAT_PROGRESSBAR   	    57
#define STAT_WEAPONDURATION   	58
#define STAT_WEAPON2DURATION   	59
#define STAT_WEAPONZOOM        	60
#define STAT_INSTA	        	61
#define STAT_X2		        	62
#define STAT_SPECTATING			63
#define STAT_PLAYERNUM			64
#define STAT_PLAYERSTANCE 		65
#define STAT_FACINGENEMY 		66
#define STAT_MAXHEALTH 			67
#define STAT_WEAPONSKIN 		68
#define STAT_PERKS				69

.float playernum;
float game_over;

#ifdef FTE
.float is_in_menu;
#endif // FTE

//
// invert float takes in float value between 0 and 1, inverts position
// eg: 0.1 returns 0.9, 0.34 returns 0.66
float invertfloat(float input) {
    if (input < 0)
        return 0; // adjust to lower boundary
    else if (input > 1)
        return 1; // adjust to upper boundary
    else
        return (1 - input);
}
