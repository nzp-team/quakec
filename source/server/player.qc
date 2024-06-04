/*
	server/player.qc

	Various stuff done for the player, including per-frame functions 
	like PlayerPreThink and PlayerPostThink, also client specific 
	stuff like PutClientInServer etc.

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

void(entity e) Light_None;
void() Spawns_Init;
void() SUB_UseTargets;
void() rec_downed;

#define PLAYER_START_HEALTH				100

#define PLAYER_CROUCH_DIFFERENCE_HL 	25
#define PLAYER_PRONE_DIFFERENCE_HL 		23
#define PLAYER_CROUCH_DIFFERENCE_QK 	15
#define PLAYER_PRONE_DIFFERENCE_QK 		13

#define PLAYER_ANIM_WALK 				1
#define PLAYER_ANIM_SPRINT				2

//
// Player 3rd Person Animations
//

// Walking
void() PAnim_Walk		=[   1,     PAnim_Walk1			] {self.frame = 0; self.tp_anim_time = time + 0.5;}
void() PAnim_Walk1		=[   2,     PAnim_Walk2			] {self.frame = 1;}
void() PAnim_Walk2		=[   3,     PAnim_Walk3			] {self.frame = 2;}
void() PAnim_Walk3		=[   4,     PAnim_Walk4			] {self.frame = 3;}
void() PAnim_Walk4		=[   5,     PAnim_Walk5			] {self.frame = 4;}
void() PAnim_Walk5		=[   6,     PAnim_Walk6			] {self.frame = 5;}
void() PAnim_Walk6		=[   7,     PAnim_Walk7			] {self.frame = 6;}
void() PAnim_Walk7		=[   8,     PAnim_Walk8			] {self.frame = 7;}
void() PAnim_Walk8		=[   9,     SUB_Null			] {self.frame = 8;}

// Sprinting
void() PAnim_Sprint 	=[	1,		PAnim_Sprint1		] {self.frame = 25; self.tp_anim_time = time + 0.65;}
void() PAnim_Sprint1 	=[	2,		PAnim_Sprint2		] {self.frame = 26;}
void() PAnim_Sprint2	=[	3,		PAnim_Sprint3		] {self.frame = 27;}
void() PAnim_Sprint3 	=[	4,		PAnim_Sprint4		] {self.frame = 28;}
void() PAnim_Sprint4 	=[	5,		PAnim_Sprint5		] {self.frame = 29;}
void() PAnim_Sprint5 	=[	6,		PAnim_Sprint6		] {self.frame = 30;}
void() PAnim_Sprint6 	=[	7,		SUB_Null			] {self.frame = 31;}

// Reloading
void() PAnim_Reload   	=[	1,		PAnim_Reload1	  	] {self.frame = 11; self.tp_anim_time = time + 1;}
void() PAnim_Reload1  	=[	2,		PAnim_Reload2	  	] {self.frame = 12;}
void() PAnim_Reload2  	=[	3,		PAnim_Reload3	  	] {self.frame = 13;}
void() PAnim_Reload3  	=[	4,		PAnim_Reload4	  	] {self.frame = 14;}
void() PAnim_Reload4  	=[	5,		PAnim_Reload5	  	] {self.frame = 15;}
void() PAnim_Reload5  	=[	6,		PAnim_Reload6	  	] {self.frame = 16;}
void() PAnim_Reload6  	=[	7,		PAnim_Reload7	  	] {self.frame = 17;}
void() PAnim_Reload7  	=[	8,		PAnim_Reload8	 	] {self.frame = 18;}
void() PAnim_Reload8  	=[	9,		PAnim_Reload9 		] {self.frame = 19;}
void() PAnim_Reload9   	=[	10,		PAnim_Reload10		] {self.frame = 20;}
void() PAnim_Reload10 	=[	11,		PAnim_Reload11		] {self.frame = 21;}
void() PAnim_Reload11 	=[	12,		PAnim_Reload12		] {self.frame = 22;}
void() PAnim_Reload12 	=[	13,		PAnim_Reload13		] {self.frame = 23;}
void() PAnim_Reload13 	=[	14,		SUB_Null			] {self.frame = 24;}

// Firing
void() PAnim_Fire 		=[	1,		PAnim_Fire1	  		] {self.frame = 9; self.tp_anim_time = time + 0.25;}
void() PAnim_Fire1 		=[	2,		SUB_Null	  		] {self.frame = 10;}

// Melee
void() PAnim_Melee 		=[	1,		PAnim_Melee1	  	] {self.frame = 49; self.tp_anim_time = time + 0.65;}
void() PAnim_Melee1 	=[	2,		PAnim_Melee2	  	] {self.frame = 50;}
void() PAnim_Melee2 	=[	3,		PAnim_Melee3	  	] {self.frame = 51;}
void() PAnim_Melee3 	=[	4,		PAnim_Melee4	  	] {self.frame = 52;}
void() PAnim_Melee4 	=[	5,		PAnim_Melee5	  	] {self.frame = 53;}
void() PAnim_Melee5 	=[	6,		PAnim_Melee6	  	] {self.frame = 54;}
void() PAnim_Melee6 	=[	7,		SUB_Null	  		] {self.frame = 55;}

// Weapon Swap
void() PAnim_Swap 		=[	1,		PAnim_Swap1	  		] {self.frame = 56; self.tp_anim_time = time + 1;}
void() PAnim_Swap1 		=[	2,		PAnim_Swap2	  		] {self.frame = 57;}
void() PAnim_Swap2 		=[	3,		PAnim_Swap3	  		] {self.frame = 58;}
void() PAnim_Swap3 		=[	4,		PAnim_Swap4	  		] {self.frame = 59;}
void() PAnim_Swap4 		=[	5,		PAnim_Swap5	  		] {self.frame = 60;}
void() PAnim_Swap5 		=[	6,		PAnim_Swap6	  		] {self.frame = 61;}
void() PAnim_Swap6 		=[	7,		PAnim_Swap7	  		] {self.frame = 62;}
void() PAnim_Swap7 		=[	8,		PAnim_Swap8	  		] {self.frame = 63;}
void() PAnim_Swap8 		=[	9,		SUB_Null	  		] {self.frame = 64;}

// Enter Dolphin Dive 
void() PAnim_EnterDive 	=[	1,		PAnim_EnterDive1	] {self.frame = 203; self.tp_anim_time = time + 5;}
void() PAnim_EnterDive1 =[	2,		PAnim_EnterDive2	] {self.frame = 204;}
void() PAnim_EnterDive2 =[	3,		PAnim_EnterDive3	] {self.frame = 205;}
void() PAnim_EnterDive3 =[	4,		PAnim_EnterDive4	] {self.frame = 206;}
void() PAnim_EnterDive4 =[	5,		SUB_Null			] {self.frame = 207;}

// Flop from Dive
void() PAnim_Flop 		=[	1,		PAnim_Flop1			] {self.frame = 208; self.tp_anim_time = time + 1;}
void() PAnim_Flop1 		=[	2,		PAnim_Flop2			] {self.frame = 209;}
void() PAnim_Flop2 		=[	3,		PAnim_Flop3			] {self.frame = 210;}
void() PAnim_Flop3 		=[	4,		SUB_Null			] {self.frame = 211;}

// Enter Stand
void() PAnim_Stand 		=[  1, 		PAnim_Stand1		] {self.frame = 114; self.tp_anim_time = time + 1;}
void() PAnim_Stand1 	=[  2, 		PAnim_Stand2		] {self.frame = 113;}
void() PAnim_Stand2 	=[  3, 		SUB_Null			] {self.frame = 0;}

// Enter Crouch
void() PAnim_Crouch 	=[  1, 		PAnim_Crouch1		] {self.frame = 113; self.tp_anim_time = time + 0.5;}
void() PAnim_Crouch1 	=[  2, 		PAnim_Crouch2		] {self.frame = 114;}
void() PAnim_Crouch2 	=[  3, 		SUB_Null			] {self.frame = 115;}

// Walking, while Crouch
void() PAnim_CrouchWalk =[  1, 		PAnim_CrouchWalk1	] {self.frame = 116; self.tp_anim_time = time + 0.5;}
void() PAnim_CrouchWalk1=[  2, 		PAnim_CrouchWalk2	] {self.frame = 117;}
void() PAnim_CrouchWalk2=[  3, 		PAnim_CrouchWalk3	] {self.frame = 118;}
void() PAnim_CrouchWalk3=[  4, 		PAnim_CrouchWalk4	] {self.frame = 119;}
void() PAnim_CrouchWalk4=[  5, 		PAnim_CrouchWalk5	] {self.frame = 120;}
void() PAnim_CrouchWalk5=[  6, 		PAnim_CrouchWalk6	] {self.frame = 121;}
void() PAnim_CrouchWalk6=[  7, 		PAnim_CrouchWalk7	] {self.frame = 122;}
void() PAnim_CrouchWalk7=[  8, 		PAnim_CrouchWalk8	] {self.frame = 123;}
void() PAnim_CrouchWalk8=[  9, 		SUB_Null			] {self.frame = 124;}

// Reloading, while Crouch
void() PAnim_CrReload   =[	1,		PAnim_CrReload1	  	] {self.frame = 128; self.tp_anim_time = time + 1;}
void() PAnim_CrReload1  =[	2,		PAnim_CrReload2	  	] {self.frame = 129;}
void() PAnim_CrReload2  =[	3,		PAnim_CrReload3	  	] {self.frame = 130;}
void() PAnim_CrReload3  =[	4,		PAnim_CrReload4	  	] {self.frame = 131;}
void() PAnim_CrReload4  =[	5,		PAnim_CrReload5	  	] {self.frame = 132;}
void() PAnim_CrReload5  =[	6,		PAnim_CrReload6	  	] {self.frame = 133;}
void() PAnim_CrReload6  =[	7,		PAnim_CrReload7	  	] {self.frame = 134;}
void() PAnim_CrReload7  =[	8,		PAnim_CrReload8	 	] {self.frame = 135;}
void() PAnim_CrReload8  =[	9,		PAnim_CrReload9 	] {self.frame = 136;}
void() PAnim_CrReload9  =[	10,		SUB_Null			] {self.frame = 115;}

// Firing, while Crouch
void() PAnim_CrouchFire =[	1,		PAnim_CrouchFire1	] {self.frame = 126; self.tp_anim_time = time + 0.25;}
void() PAnim_CrouchFire1=[	2,		SUB_Null	  		] {self.frame = 127;}

// Enter Prone
void() PAnim_Prone 		=[  1, 		PAnim_Prone1		] {self.frame = 154; self.tp_anim_time = time + 1.5;}
void() PAnim_Prone1 	=[  2, 		PAnim_Prone2		] {self.frame = 155;}
void() PAnim_Prone2 	=[  3, 		PAnim_Prone3		] {self.frame = 156;}
void() PAnim_Prone3 	=[  4, 		PAnim_Prone4		] {self.frame = 157;}
void() PAnim_Prone4 	=[  5, 		PAnim_Prone5		] {self.frame = 158;}
void() PAnim_Prone5 	=[  6, 		PAnim_Prone6		] {self.frame = 159;}
void() PAnim_Prone6 	=[  7, 		PAnim_Prone7		] {self.frame = 160;}
void() PAnim_Prone7 	=[  8, 		PAnim_Prone8		] {self.frame = 161;}
void() PAnim_Prone8 	=[  9, 		SUB_Null			] {self.frame = 162;}

// Walking, while Prone
void() PAnim_ProneWalk	=[  1, 		PAnim_ProneWalk1	] {self.frame = 162; self.tp_anim_time = time + 1.5;}
void() PAnim_ProneWalk1	=[  2, 		PAnim_ProneWalk2	] {self.frame = 163;}
void() PAnim_ProneWalk2	=[  3, 		PAnim_ProneWalk3	] {self.frame = 164;}
void() PAnim_ProneWalk3	=[  4, 		PAnim_ProneWalk4	] {self.frame = 165;}
void() PAnim_ProneWalk4	=[  5, 		PAnim_ProneWalk5	] {self.frame = 166;}
void() PAnim_ProneWalk5	=[  6, 		PAnim_ProneWalk6	] {self.frame = 167;}
void() PAnim_ProneWalk6	=[  7, 		PAnim_ProneWalk7	] {self.frame = 168;}
void() PAnim_ProneWalk7	=[  8, 		PAnim_ProneWalk8	] {self.frame = 169;}
void() PAnim_ProneWalk8	=[  9, 		PAnim_ProneWalk9	] {self.frame = 170;}
void() PAnim_ProneWalk9	=[  10, 	PAnim_ProneWalk10	] {self.frame = 171;}
void() PAnim_ProneWalk10=[  11, 	PAnim_ProneWalk11	] {self.frame = 172;}
void() PAnim_ProneWalk11=[  12, 	PAnim_ProneWalk12	] {self.frame = 173;}
void() PAnim_ProneWalk12=[  13, 	SUB_Null			] {self.frame = 174;}

// Reloading, while Prone
void() PAnim_PrReload   =[	1,		PAnim_PrReload1	  	] {self.frame = 176; self.tp_anim_time = time + 1;}
void() PAnim_PrReload1  =[	2,		PAnim_PrReload2	  	] {self.frame = 177;}
void() PAnim_PrReload2  =[	3,		PAnim_PrReload3	  	] {self.frame = 178;}
void() PAnim_PrReload3  =[	4,		PAnim_PrReload4	  	] {self.frame = 179;}
void() PAnim_PrReload4  =[	5,		PAnim_PrReload5	  	] {self.frame = 180;}
void() PAnim_PrReload5  =[	6,		PAnim_PrReload6	  	] {self.frame = 181;}
void() PAnim_PrReload6  =[	7,		SUB_Null	  		] {self.frame = 162;}

// Enter Crouch, from Prone
void() PAnim_UpCrouch 	=[  1, 		PAnim_UpCrouch1		] {self.frame = 161; self.tp_anim_time = time + 1;}
void() PAnim_UpCrouch1 	=[  2, 		PAnim_UpCrouch2		] {self.frame = 160;}
void() PAnim_UpCrouch2 	=[  3, 		PAnim_UpCrouch3		] {self.frame = 159;}
void() PAnim_UpCrouch3 	=[  4, 		PAnim_UpCrouch4		] {self.frame = 158;}
void() PAnim_UpCrouch4 	=[  5, 		PAnim_UpCrouch5		] {self.frame = 157;}
void() PAnim_UpCrouch5 	=[  6, 		PAnim_UpCrouch6		] {self.frame = 156;}
void() PAnim_UpCrouch6 	=[  7, 		PAnim_UpCrouch7		] {self.frame = 155;}
void() PAnim_UpCrouch7 	=[  8, 		PAnim_UpCrouch8		] {self.frame = 154;}
void() PAnim_UpCrouch8 	=[  9, 		SUB_Null			] {self.frame = 115;}

// Enter Last Stand
void() PAnim_GetDown	=[	1, 		PAnim_GetDown1		] {self.frame = 32; self.tp_anim_time = time + 1;};
void() PAnim_GetDown1	=[	2, 		PAnim_GetDown2		] {self.frame = 33;};
void() PAnim_GetDown2	=[	3, 		PAnim_GetDown3		] {self.frame = 34;};
void() PAnim_GetDown3	=[	4, 		PAnim_GetDown4		] {self.frame = 35;};
void() PAnim_GetDown4	=[	5, 		PAnim_GetDown5		] {self.frame = 36;};
void() PAnim_GetDown5	=[	6, 		SUB_Null			] {self.frame = 37; rec_downed();};

// Firing, while in Last Stand
void() PAnim_LastFire 	=[	1,		PAnim_LastFire1		] {self.frame = 36; self.tp_anim_time = time + 0.25;}
void() PAnim_LastFire1  =[	2,		SUB_Null			] {self.frame = 37;} 

// Leave Last Stand
void() PAnim_GetUp 		=[	1,		PAnim_GetUp1		] {self.frame = 39; self.tp_anim_time = time + 1;}
void() PAnim_GetUp1		=[	2,		PAnim_GetUp2		] {self.frame = 40;}
void() PAnim_GetUp2		=[	3,		PAnim_GetUp3		] {self.frame = 41;}
void() PAnim_GetUp3		=[	4,		PAnim_GetUp4		] {self.frame = 42;}
void() PAnim_GetUp4		=[	5,		PAnim_GetUp5		] {self.frame = 43;}
void() PAnim_GetUp5		=[	6,		PAnim_GetUp6		] {self.frame = 44;}
void() PAnim_GetUp6		=[	7,		PAnim_GetUp7		] {self.frame = 45;}
void() PAnim_GetUp7		=[	8,		PAnim_GetUp8		] {self.frame = 46;}
void() PAnim_GetUp8		=[	9,		PAnim_GetUp9		] {self.frame = 47;}
void() PAnim_GetUp9		=[	10,		SUB_Null			] {self.frame = 48;}


#define forward 	0
#define backward 	1
#define left 		2
#define right 		3
#define all_move    -1

float(float dir) checkMovement =
{	
	switch(dir) {
		case forward:
			if (self.movement_x > 0)
				return 1;
		break;
		case backward:
			if (self.movement_x < 0)
				return 1;
		break;
		case right:
			if (self.movement_y > 0)
				return 1;
		break;
		case left:
			if (self.movement_y < 0)
				return 1;
		break;
		case all_move:
			if (self.movement_x || self.movement_y)
				return 1;
		break;
		default:
			return 0;
	}
}

//
// Player_CanStandHere
// Performs a tracebox and will return true
// if the player can stance in their current
// space.
//
float(entity who) Player_CanStandHere =
{
	// There shouldn't be any real reason we'd care about this since beta maps don't support
	// stance changing impacting the bbox, but still, consistency..
	if (map_compatibility_mode == MAP_COMPAT_BETA)
		tracebox(who.origin, PLAYER_MINS_QUAKE, PLAYER_MAXS_QUAKE, who.origin, true, who);
	else
		tracebox(who.origin, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING, who.origin, true, who);

	return !trace_startsolid;
}

//
// Player_SetStance(who, preferred_stance, play_animation)
// Lowers the camera height as needed, registers
// preferred stance, plays animation, and sets 
// bounding box (if applicable).
//
void(entity who, float preferred_stance, float play_animation) Player_SetStance =
{
	// Don't bother if we're already the desired stance, or if it wasn't valid
	if (who.stance == preferred_stance || preferred_stance < 0 || preferred_stance > 2)
		return;

	// First check -- if we want to stand, only crouch if there
	// is no space for it.
	if (preferred_stance == PLAYER_STANCE_STAND && !Player_CanStandHere(who))
		preferred_stance = PLAYER_STANCE_CROUCH;

	// Set the bounding box
	if (map_compatibility_mode != MAP_COMPAT_BETA) {
		if (preferred_stance != PLAYER_STANCE_STAND)
			setsize(self, PLAYER_MINS_CROUCHING, PLAYER_MAXS_CROUCHING);
		else
			setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
	}

	// NZ:P Beta should change the stances by a different amount,
	// to avoid looking like you're in the ground..
	float height_diff_crouch, height_diff_prone;
	if (map_compatibility_mode == MAP_COMPAT_BETA) {
		height_diff_crouch = PLAYER_CROUCH_DIFFERENCE_QK;
		height_diff_prone = PLAYER_PRONE_DIFFERENCE_QK;
	} else {
		height_diff_crouch = PLAYER_CROUCH_DIFFERENCE_HL;
		height_diff_prone = PLAYER_PRONE_DIFFERENCE_HL;
	}

	// Prone while standing? Lower to crouch + prone height.
	if (who.stance == PLAYER_STANCE_STAND && preferred_stance == PLAYER_STANCE_PRONE)
		who.new_ofs_z = who.view_ofs_z - (height_diff_crouch + height_diff_prone);

	// Prone while crouching? Lower to prone height.
	else if (who.stance == PLAYER_STANCE_CROUCH && preferred_stance == PLAYER_STANCE_PRONE)
		who.new_ofs_z = who.view_ofs_z - height_diff_prone;

	// Crouch while proning? Raise to crouch height/take away prone difference.
	else if (who.stance == PLAYER_STANCE_PRONE && preferred_stance == PLAYER_STANCE_CROUCH)
		who.new_ofs_z = who.view_ofs_z + height_diff_prone;

	// Crouch while standing? Lower to crouch height.
	else if (who.stance == PLAYER_STANCE_STAND && preferred_stance == PLAYER_STANCE_CROUCH)
		who.new_ofs_z = who.view_ofs_z - height_diff_crouch;

	// Stand while crouching? Raise to stand height/take away crouch difference.
	else if (who.stance == PLAYER_STANCE_CROUCH && preferred_stance == PLAYER_STANCE_STAND)
		who.new_ofs_z = who.view_ofs_z + height_diff_crouch;

	// Stand while proning? Raise to stand height/take away crouch + prone difference.
	else if (who.stance == PLAYER_STANCE_PRONE && preferred_stance == PLAYER_STANCE_STAND)
		who.new_ofs_z = who.view_ofs_z + (height_diff_crouch + height_diff_prone);

	// Set the stance value
	who.stance = preferred_stance;

	// Animation playback
	if (play_animation == true) {
		entity tempe = self;
		self = who;

		switch(who.stance) {
			case PLAYER_STANCE_STAND: PAnim_Stand(); break;
			case PLAYER_STANCE_CROUCH: PAnim_Crouch(); break;
			case PLAYER_STANCE_PRONE: PAnim_Prone(); break;
			default: break;
		}

		self = tempe;
	}
}

void() PlayerJump =
{
	if (!(self.flags & FL_ONGROUND) 
	    || !(self.flags & FL_JUMPRELEASED)
		|| self.downed 
		|| self.dive ) {
		return;
	}
			
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);

	if (self.button2)
		self.button2 = 0;
	
	self.oldz = self.origin_z;

	self.velocity_z = 230;
}

void(float override) JumpCheck =
{

#ifndef FTE

	override = 0;

#endif // FTE

	if(self.button2 || override) {
		if (self.downed)
			return;
			
		if (self.stance == PLAYER_STANCE_STAND) {
			PlayerJump();
		} else if (self.view_ofs_z == self.new_ofs_z && (self.flags & FL_ONGROUND)) {
			Player_SetStance(self, PLAYER_STANCE_STAND, true);
		}
	} else
		self.flags = self.flags | FL_JUMPRELEASED;
}


void() PlayerPreThink =
{
	if (self.downed) {
		self.maxspeed = 30;
	} else {

		// Walk slower to account for NZ:P Beta Scaling.
		if (map_compatibility_mode == MAP_COMPAT_BETA)
			self.maxspeed = 150;
		else
			self.maxspeed = 190;

		if (self.sprinting) {

#ifdef FTE

			// viewbob when running 
			self.punchangle_y = 0.6*sin(time*10);

#endif // FTE

			//playrun1();
			self.maxspeed *= 1.5; // down from 1.66x, to match WaW
		} else if (!self.sprinting && !self.zoom) {

#ifdef FTE
				
			if (checkMovement(-1))
				self.punchangle_x = 0.25*sin(time*15);	

#endif // FTE

		} else if (self.zoom != 3) {
			self.maxspeed *= 0.5;
		} 

		// Speed Penalty
		if (self.speed_penalty_time > time)
		{
			self.maxspeed *= self.speed_penalty;
		} else {
			self.speed_penalty = 1;
		}
		
		switch(self.stance) {
			case 1:
				self.maxspeed *= 0.65;
				break;
			case 0:
				self.maxspeed *= 0.25;
				break;		
		}

#ifdef FTE

		if (checkMovement(backward)) {
			self.maxspeed *= 0.7;
		} else if (checkMovement(left) || checkMovement(right)) {
			self.maxspeed *= 0.8;
		}

#endif // FTE

		if (!self.isBuying)
			self.maxspeed *= GetWeaponWalkSpeed(self.perks, self.weapon);
	}
	if(self.isspec != 0 && !self.downed)
	{
		if(self.button0 && self.fire_delay < time)
		{
			self.aiment = find(self.aiment, classname, "player");
			if(self.aiment != world)
			{
				sprint(self, PRINT_HIGH, "Now spectating ");
				sprint(self, PRINT_HIGH, self.aiment.netname);
				sprint(self, PRINT_HIGH, "\n");
				
				self.solid = SOLID_NOT;
				self.movetype = MOVETYPE_NONE;
			}
			else
			{
				sprint(self, PRINT_HIGH, "Freefly spectate\n");
				self.movetype = MOVETYPE_FLY;
			}
			self.fire_delay = time + 0.25;
		}
		if(self.aiment != world)
		{
			self.origin = self.aiment.origin;
			self.angles = self.aiment.v_angle;
			self.velocity = self.aiment.velocity;
			self.fixangle = TRUE;
		}
		return;
	}
	
	if (cvar("waypoint_mode")) {
		Waypoint_Logic();
	} else {
		WeaponCore_ClientLogic();
	}

	JumpCheck(0);

	// Fire effect
	if (self.onfire) {
		Effect_Fire(self.origin);

		if (self.fire_timeout < time)
			self.onfire = false;
	}

	// Flamethrower-based weapon cooldown/refuel process.
	if (self.ltime < time) {
		float weapon_slot = Weapon_PlayerHasWeaponWithFiretype(self, FIRETYPE_FLAME);

		if (weapon_slot == 0)
			return;

		weapon_slot--;
		if (self.weapons[weapon_slot].weapon_magazine == 0 && !self.cooldown) {
			self.cooldown = true;
		}

		if (self.cooldown && self.weapons[weapon_slot].weapon_magazine > 20)
			self.cooldown = false;
		
		if (self.weapons[weapon_slot].weapon_magazine < getWeaponMag(self.weapons[weapon_slot].weapon_id)) {
			self.weapons[weapon_slot].weapon_magazine += 1;
		}

		self.ltime = time + 0.1;
	}
};

float player_trace_time;
void() PlayerPostThink =
{

#ifdef FTE

	// Network everything
	self.SendFlags = 1;
	
	// Obtain menu state from CSQC via infokeys.
	self.is_in_menu = stof(infokey(self, "in_menu"));
	if (self.is_in_menu != 1)
		if (infokey(self, "chat") == "1")
			self.is_in_menu = 2;
	

#endif // FTE

	if(self.isspec)
		return;

	//landsound
	if((self.oldvelocity_z < -212) && (self.flags & FL_ONGROUND))
	{
		sound(self, CHAN_BODY, "sounds/player/land.wav", 0.6, 1.75);
		self.lastsound_time = time - 0.15;
	}

	// Walking Animations
	if (self.tp_anim_time < time && self.reload_delay < time && self.reload_delay2 < time 
	&& self.fire_delay < time && self.fire_delay2 < time && self.knife_delay < time) {
		if (vlen(self.velocity) > 20) {
			if (self.sprinting) {
				PAnim_Sprint();
				self.tp_anim_type = PLAYER_ANIM_SPRINT;
			} else {
				self.tp_anim_type = PLAYER_ANIM_WALK;
				switch(self.stance) {
					case 2: PAnim_Walk(); break;
					case 1: PAnim_CrouchWalk(); break;
					case 0: PAnim_ProneWalk(); break;
				}
			}
		} else {
			// Stand still so Crouch Walk isn't stuck in place
			switch(self.stance) {
				case 2: self.frame = 0; break;
				case 1: self.frame = 115; break;
				case 0: self.frame = 162; break;
			}

			// If we're downed force set the last stand idle frame as well
			// so the player doesn't look like they're just prone.
			if (self.downed)
				self.frame = 37;
		}
	}
	
#ifdef FTE

	//footsteps
	if((vlen(self.velocity) > 20) &&(( time - self.lastsound_time > 0.4) || (time - self.lastsound_time > 0.3 && self.sprinting)) && (self.flags & FL_ONGROUND))
	{
		float movelen = vlen(input_movevalues);
		if(movelen > 300)
		{		
			local float ran = random();
			if(ran > 0.8)
				sound(self, CHAN_BODY, "sounds/player/footstep1.wav", 0.6, 2.5);
			else if(ran > 0.6)
				sound(self, CHAN_BODY, "sounds/player/footstep2.wav", 0.6, 2.5);
			else if(ran > 0.4)
				sound(self, CHAN_BODY, "sounds/player/footstep3.wav", 0.6, 2.5);
			else if(ran > 0.2)
				sound(self, CHAN_BODY, "sounds/player/footstep4.wav", 0.6, 2.5);
			else
				sound(self, CHAN_BODY, "sounds/player/footstep5.wav", 0.6, 2.5);
			self.lastsound_time = time;
		}
	}

#endif // FTE
	
	// Health Regeneration
	if (self.health_delay < time && self.health != self.max_health && !self.downed)
	{
		// If we weren't super low on health, regen is instant.
		if (self.health_was_very_low == true) {
			self.health += 120 * frametime;
		} else {
			// Was 100% instant, but this delays it by only a few
			// frames so the graphic doesn't just vanish when healed.
			self.health += 300 * frametime;
		}

		// Make sure we mark that we weren't just super hurt anymore.
		if (self.max_health <= self.health) {
			self.health = self.max_health;
			self.health_was_very_low = false;
		}
	}
	
	if (self.progress_bar) {
		if (self.progress_bar < time) {
			if (self.downed)
				GetUp();
			
			if (self.reviving)
				self.revived = 1;
			
			self.progress_bar = 0;
			self.progress_bar_time = 0;
			self.progress_bar_percent = 0;
			
				
		} else {
			float remaining = self.progress_bar - time;
			self.progress_bar_percent = invertfloat((remaining / self.progress_bar_time));
		}
	}

	if (self.sprinting) {
		self.sprint_timer = self.sprint_duration + (time - self.sprint_start_time);
		
#ifndef FTE

		if (!self.velocity || self.stance != 2) {
			W_SprintStop();
		}

#else

		if (!self.velocity || !checkMovement(0) || self.stance != 2) { //moto (FIXME) -- move me!
			W_SprintStop();
		}

#endif // FTE
		
		if (self.perks & P_STAMIN) {
			if (self.sprint_timer > sprint_max_time * 2) {
				W_SprintStop();
			}
		}
		else
		{
			if (self.sprint_timer > sprint_max_time) {
				W_SprintStop();
			}
		}

	} else if (self.sprint_duration > 0.0) 	{
		self.sprint_rest_time = (time - self.sprint_stop_time);
	}

	self.oldvelocity = self.velocity;

	// Perform a traceline to keep track of entities directly
	// in front of the player.
	// Also don't do it every frame because that's really tough
	// on perf.
	if (player_trace_time < time) {
		vector source;

		makevectors (self.v_angle);
		source = self.origin + self.view_ofs;

#ifdef FTE

		self.dimension_hit = HITBOX_DIM_LIMBS | HITBOX_DIM_ZOMBIES;

#endif // FTE

		traceline (source, source + v_forward*800*1.2, 0, self);

#ifdef FTE

		self.dimension_hit = HITBOX_DIM_ZOMBIES;

#endif // FTE


		// use .head here to avoid expanding ent struct
		self.head = trace_ent;

		// check whether we're looking at an entity separately to communicate
		// with the client more reasonably
		if (trace_ent.classname == "ai_zombie" || trace_ent.classname == "ai_zombie_head" 
		|| trace_ent.classname == "ai_zombie_rarm" ||trace_ent.classname == "ai_zombie_larm" 
		|| trace_ent.classname == "ai_dog")
			self.facingenemy = true;
		else
			self.facingenemy = false;

		// 1/4 of a second is enough of a delay to not kill the effect.
		player_trace_time = time + 0.25;
	}
};

void() ClientKill = {};

//called when a client connects to the server
void() ClientConnect =
{	
	if(cvar("developer") || player_count > 1) {
		bprint(PRINT_HIGH, self.netname); //print player name
		bprint(PRINT_HIGH, " connected.\n");
	}	
};

//
// Player_PickSpawnPoint()
// Picks a valid spawn point for the
// newly spawning player, as well as
// assigns any spawn-specific fields
// (e.g., starting weapon).
//
void() Player_PickSpawnPoint =
{
	entity spawn_point = world;
	float found_viable_spawn = false;

	// Assign a location
	while(!found_viable_spawn) {
		float index = random();

		// assign one of the spawnpoints
		if (index < 0.25)
			spawn_point = find(world, classname, SPAWN_1_CLASS);
		else if (index < 0.50)
			spawn_point = find(world, classname, SPAWN_2_CLASS);
		else if (index < 0.75)
			spawn_point = find(world, classname, SPAWN_3_CLASS);
		else
			spawn_point = find(world, classname, SPAWN_4_CLASS);

		float found_player_here = false;

		entity ents_in_spawn_range = findradius(spawn_point.origin, 32);

		// check if there's a player in the way
		while(ents_in_spawn_range != world) {
			if (ents_in_spawn_range.classname == "player")
				found_player_here = true;

			ents_in_spawn_range = ents_in_spawn_range.chain;
		}

		// no player in the way, this spawn is good.
		if (found_player_here == false)
			found_viable_spawn = true;
	}

	// Give them their name
	self.name = spawn_point.name;

	// Set their location
	self.origin = spawn_point.origin + '0 0 1';
	self.angles = spawn_point.angles;

	// Assign their starting weapon
	Weapon_AssignWeapon(0, spawn_point.weapon, spawn_point.currentmag, spawn_point.currentammo);

	// Activate anything the Spawn was targeting
	entity tempe = self;
	self = spawn_point;
	SUB_UseTargets();
	self = tempe;
};

void() PlayerSpawn =
{	
	entity spawnpoint = world;
	local_client = self;

	self.isspec = FALSE;
	self.classname = "player";
	self.solid = SOLID_BBOX;
	self.flags = FL_CLIENT;

	self.onfire = false;
	self.fire_timeout = 0;

	// We can only collide with zombies (and not their limbs)

#ifdef FTE

	self.dimension_hit = HITBOX_DIM_ZOMBIES;

#endif // FTE

	setmodel(self, "models/player.mdl");
	self.movetype = MOVETYPE_WALK;
	self.max_health = self.health = PLAYER_START_HEALTH;

	entity who = find(world,classname,"player");
	while(who != self && !self.playernum)
	{
		if(who)
		{
			player_count++;
			break;
		}
	}

	if (!self.playernum) {
		self.playernum = player_count + 1;
		if (self.playernum == 1)
			pl1 = self;
	}

	// Assign them a spawn location.
	Player_PickSpawnPoint();
	
	self.fixangle = true;

	// NZ:P Beta used Quake BSP 29, so set bounding box accordingly.
	if (map_compatibility_mode == MAP_COMPAT_BETA) {
		self.view_ofs = VIEW_OFS_QK;
		setsize(self, PLAYER_MINS_QUAKE, PLAYER_MAXS_QUAKE);
	} else {
		self.view_ofs = VIEW_OFS_HL;
		setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
	}

	self.stance = 2;
	self.new_ofs_z = self.view_ofs_z;
	self.oldz = self.origin_z;
	self.grenades = self.grenades | 1;  // add frag grenades to player inventory
	
	if (rounds)
		self.primary_grenades = 2;
	else
		self.primary_grenades = 0; 		// start off without grenades
		
	self.pri_grenade_state = 0; 		// defines that frag grenades are for player first, not betty
	self.secondary_grenades = -1;		// shows that we both don't have betties AND shouldn't draw the image onscreen

	if (!self.points)
		addmoney(self, G_STARTPOINTS, 0);

	self.weaponmodel = GetWeaponModel(self.weapon, 0);// Give weapon model
	self.weapon2model = GetWeapon2Model(self.weapon);

	self.stamina = 3;
	self.reviving = 0;
	self.perks = G_PERKS;

	UpdatePlayerCount(player_count);
	
#ifdef FTE

	self.viewzoom = 1;
	self.SendEntity = Player_SendEntity;
	self.weapon_animduration = getWeaponDelay(self.weapon, FIRE);

	if (G_WORLDTEXT)
		WorldText(world.chaptertitle, world.location, world.date, world.person, self);

	ReportMapMode(map_compatibility_mode, self);

#else 

	self.Weapon_Name = GetWeaponName(self.weapon);
	self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
	self.Flash_Size = GetWeaponFlash_Size(self.weapon);
	self.ADS_Offset = GetWeaponADSOfs(self.weapon);

#endif // FTE

	if (G_STARTROUND != 1) {
		rounds = G_STARTROUND - 1;
	}

	// Make sure players joining after game start are still allowed
	// to see their name.
	if (time >= 5 && self.name != "")
		nzp_setplayername(self, self.name);
};

void() SpectatorSpawn =
{
	local entity spawnpoint;
	spawnpoint = find(world, classname, "info_player_1_spawn");
	
	self.isspec = TRUE;
	self.health = 420;
	self.classname = "spectator";
	self.solid = SOLID_CORPSE;
	setmodel(self, "models/sprites/null.spr");
	self.movetype = MOVETYPE_FLY;
	self.origin = spawnpoint.origin + [0,0,1];
	self.fixangle = TRUE;
	setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
	self.view_ofs = '0 0 22';
	self.aiment = world;
};

//called when a client loads a map
float spawns_initialized;
void() PutClientInServer =
{
	// Init Spawn Points
	if (!spawns_initialized) {
		Spawns_Init();
		spawns_initialized = true;
	}

	if(cvar("developer") || player_count > 1) {
		bprint(PRINT_HIGH, self.netname);
		bprint(PRINT_HIGH, " has joined the game.\n");
	}
	
	if (spawn_time > time || !rounds)
		PlayerSpawn();

#ifdef FTE

	else 
		SpectatorSpawn();

#endif // FTE

	GameRestart_ResetPerkaColas();
};

//called when client disconnects from the server
void() ClientDisconnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has left the game.\n");
	player_count--;
	UpdatePlayerCount(player_count);
	
	self.classname = "disconnected";
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_BOUNCE;
	self.nextthink = -1;
	setmodel(self, "models/sprites/null.spr");

	GameRestart_ResetPerkaColas();

	if (self.downed) {
		DisableReviveIcon(self.electro_targeted);
		revive_index--;
	}

#ifdef FTE

	// Network everything
	self.SendFlags = 1;
	self.is_in_menu = 0;

#endif // FTE
};


void() SetNewParms =
{
};

void() SetChangeParms =
{
};

#ifdef FTE

void() SV_RunClientCommand =
{
	runstandardplayerphysics(self);
}

#endif // FTE
