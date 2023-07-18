/*
	shared/defs/custom.qc

	shared definitions

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

#define true    1
#define false   0

const float EVENT_WEAPONCHANGE 			= 9;
const float EVENT_PISTOLFIRE 			= 10;
const float EVENT_USEPRINT 				= 11;
const float EVENT_NEWROUND 				= 12;
const float EVENT_SETROUND 				= 13;
const float EVENT_UPDATEVMODEL 			= 20;
const float EVENT_UPDATEV2MODEL 		= 21;
const float EVENT_PERK	 				= 22;
const float EVENT_UPDATE 				= 23;
const float EVENT_BROADCAST 			= 24;
const float EVENT_POINTUPDATE 			= 25;
const float EVENT_BLACKOUT 				= 26;
const float EVENT_PUNCHANGLE 			= 27;
const float EVENT_SCROLLTEXT 			= 28;
const float EVENT_WORLDDATA 			= 29;
const float EVENT_ACHIEVEMENT 			= 30;
const float EVENT_PLAYERUPDATE 			= 31;
const float EVENT_WEAPONUPDATE 			= 32;
const float EVENT_HUDUPDATE 			= 33;
const float EVENT_EXPLOSION 			= 34;
const float EVENT_BLOOD 				= 35;
const float EVENT_ACHIEVEMENTPROGRESS 	= 36;
const float EVENT_REVIVEON 				= 37;
const float EVENT_REVIVEOFF 			= 38;
const float EVENT_REVIVECHANGE 			= 39;
const float EVENT_WEAPONRECOIL 			= 40;
const float EVENT_SONGPLAY 				= 41;

// Define our FTE platform
#ifndef STANDARD
#define FTE
#endif // STANDARD

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
//#define W_KRAUS      53 //ballistic
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

//Animation types
#define RELOAD		1
#define GRENADE		2
#define FIRE		3
#define SWITCHWEP	4
#define KNIFE		5
#define ZOOM		6
#define SPRINT		7
#define PERK		8
#define KNIFE2		9
#define REVIVE		10
#define RELOAD_EMP 	11
#define RELOAD_PAR 	12

#define S_HEADSHOT	1
#define S_KNIFE		2
#define S_NORMAL	3
#define S_ZOMBIE	4
#define S_EXPLOSIVE	5
#define S_ZAPPER	6
#define S_TESLA 	7

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
#define STAT_WEAPON2MODEL       54
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

//
// invert float takes in float value between 0 and 1, inverts position
// eg: 0.1 returns 0.9, 0.34 returns 0.66
float invertfloat(float input) {
	
	if (input <= 0 || input >= 1)
		return input; 					// out of boundaries 
	
	return (1 - input);	
}
