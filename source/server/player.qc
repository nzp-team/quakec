/*
	server/player.qc

	Various stuff done for the player, including per-frame functions 
	like PlayerPreThink and PlayerPostThink, also client specific 
	stuff like PutClientInServer etc.

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

void(entity e) Light_None;

#define PLAYER_START_HEALTH		100

//
// Player 3rd Person Animations
//

// Enter Last Stand
void() PAnim_GetDown1	=[	1, 		PAnim_GetDown2	]	{self.frame = 32;};
void() PAnim_GetDown2	=[	1, 		PAnim_GetDown3	]	{self.frame = 33;};
void() PAnim_GetDown3	=[	1, 		PAnim_GetDown4	]	{self.frame = 34;};
void() PAnim_GetDown4	=[	1, 		PAnim_GetDown5	]	{self.frame = 35;};
void() PAnim_GetDown5	=[	1, 		PAnim_GetDown6	]	{self.frame = 36;};
void() PAnim_GetDown6	=[	1, 		PAnim_GetDown6	]	{self.frame = 37;};

//
void() playreload   	=[	1,		playreload1	  	] {self.frame = 11;}
void() playreload1  	=[	2,		playreload2	  	] {self.frame = 12;}
void() playreload2  	=[	3,		playreload3	  	] {self.frame = 13;}
void() playreload3  	=[	4,		playreload4	  	] {self.frame = 14;}
void() playreload4  	=[	5,		playreload5	  	] {self.frame = 15;}
void() playreload5  	=[	6,		playreload6	  	] {self.frame = 16;}
void() playreload6  	=[	7,		playreload7	  	] {self.frame = 17;}
void() playreload7  	=[	8,		playreload8	 	] {self.frame = 18;}
void() playreload8  	=[	9,		playreload9 	] {self.frame = 19;}
void() playreload9   	=[	10,		playreload10	] {self.frame = 20;}
void() playreload10 	=[	11,		playreload11	] {self.frame = 21;}
void() playreload11 	=[	12,		playreload12	] {self.frame = 22;}
void() playreload12 	=[	13,		playreload13	] {self.frame = 23;}
void() playreload13 	=[	14,		playreload13	] {self.frame = 24;}
//
void() playdownfire 	=[	1,		playdownfire1	] {self.frame = 38;}
void() playdownfire1  	=[	2,		playdownfire1	] {self.frame = 39;} 
//
void() playaim 	 		=[	1,		playaim1		] {self.frame = 8;} // naievil -- player aimin anim
void() playaim1 		=[	2,		playaim1		] {self.frame = 9;} // naievil -- second player aimin anim
//
void() playout 	  		=[	1,		playout1		] {self.frame = 10;} // naievil -- player aim out anim
void() playout1 		=[	2,		playout1		] {self.frame = 11;} // naievil -- second player aim out anim
//
void() playrun1 		=[	1,		playrun2		] {self.frame = 25;}
void() playrun2 		=[	2,		playrun3		] {self.frame = 26;}
void() playrun3		 	=[	3,		playrun4		] {self.frame = 27;}
void() playrun4 		=[	4,		playrun5		] {self.frame = 28;}
void() playrun5 		=[	5,		playrun6		] {self.frame = 29;}
void() playrun6 		=[	6,		playrun7		] {self.frame = 30;}
void() playrun7 		=[	7,		playrun8		] {self.frame = 31;}
void() playrun8 		=[	8,		playrun9		] {self.frame = 25;}
void() playrun9 		=[	9,		playrun10		] {self.frame = 26;}
void() playrun10 		=[	10,		playrun11		] {self.frame = 27;}
void() playrun11 		=[	11,		playrun12		] {self.frame = 28;}
void() playrun12 		=[	12,		playrun13		] {self.frame = 29;}
void() playrun13 		=[	13,		playrun14		] {self.frame = 30;}
void() playrun14 		=[	14,		playrun15		] {self.frame = 25;}
void() playrun15 		=[	15,		playrun16		] {self.frame = 26;}
void() playrun16 		=[	16,		playrun17		] {self.frame = 27;}
void() playrun17 		=[	17,		playrun18		] {self.frame = 28;}
void() playrun18 		=[	18,		playrun19		] {self.frame = 29;}
void() playrun19 		=[	19,		playrun20		] {self.frame = 30;}
void() playrun20 		=[	20,		playrun21		] {self.frame = 31;}
void() playrun21 		=[	21,		playrun22		] {self.frame = 25;}
void() playrun22 		=[	22,		playrun23		] {self.frame = 26;}
void() playrun23 		=[	23,		playrun24 		] {self.frame = 27;}
void() playrun24 		=[	24,		playrun25		] {self.frame = 28;}
void() playrun25 		=[	25,		playrun26		] {self.frame = 29;}
void() playrun26 		=[	26,		playrun27		] {self.frame = 30;}
void() playrun27 		=[	27,		playrun28		] {self.frame = 25;}
void() playrun28 		=[	28,		playrun29		] {self.frame = 26;}
void() playrun29 		=[	29,		playrun30		] {self.frame = 27;}
void() playrun30 		=[	30,		playrun31		] {self.frame = 28;}
void() playrun31 		=[	31,		playrun32		] {self.frame = 29;}
void() playrun32 		=[	32,		playrun33		] {self.frame = 30;}
void() playrun33 		=[	33,		playrun33		] {self.frame = 31;}
//
void() playwalk		    =[   1,     playwalk1		] {if (self.velocity) { self.frame = 0; }}
void() playwalk1		=[   2,     playwalk2		] {if (self.velocity) { self.frame = 1; }}
void() playwalk2		=[   3,     playwalk3		] {if (self.velocity) { self.frame = 2; }}
void() playwalk3		=[   4,     playwalk4		] {if (self.velocity) { self.frame = 3; }}
void() playwalk4		=[   5,     playwalk5		] {if (self.velocity) { self.frame = 4; }}
void() playwalk5		=[   6,     playwalk6		] {if (self.velocity) { self.frame = 5; }}
void() playwalk6		=[   7,     playwalk7		] {if (self.velocity) { self.frame = 6; }}
void() playwalk7		=[   8,     playwalk8		] {if (self.velocity) { self.frame = 7; }}
void() playwalk8		=[   9,     playwalk8		] {if (self.velocity) { self.frame = 8; }}
//
void() playgetup 		=[	1,		playgetup1		] {self.frame = 38;}
void() playgetup1 		=[	2,		playgetup2		] {self.frame = 39;}
void() playgetup2		=[	3,		playgetup3		] {self.frame = 40;}
void() playgetup3		=[	4,		playgetup4		] {self.frame = 41;}
void() playgetup4		=[	5,		playgetup5		] {self.frame = 42;}
void() playgetup5		=[	6,		playgetup6		] {self.frame = 43;}
void() playgetup6		=[	7,		playgetup7		] {self.frame = 44;}
void() playgetup7		=[	8,		playgetup8		] {self.frame = 45;}
void() playgetup8		=[	9,		playgetup9		] {self.frame = 46;}
void() playgetup9		=[	10,		playgetup10		] {self.frame = 47;}
void() playgetup10		=[	11,		playgetup10		] {self.frame = 48;}

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

void() PlayerJump =
{
	if (!(self.flags & FL_ONGROUND) 
	    || !(self.flags & FL_JUMPRELEASED)
		|| self.downed 
		|| self.dive ) {
		return;
	}
			
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	sound(self, CHAN_VOICE, "sounds/player/jump.wav", 1, 1.75);

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
			
		if (self.stance == 2) {
      // naievil -- stop sprinting if we jump, which is a real mechanic from the game that we never implemented 
		  if (self.sprinting) {
			  W_SprintStop();
		  }
			PlayerJump();
		} else if (self.view_ofs_z == self.new_ofs_z && (self.flags & FL_ONGROUND)) {
			switch(self.stance) {
				case 0:
					self.new_ofs_z = self.view_ofs_z + 42;
					self.stance = 2;
					break;
				case 1:
					self.new_ofs_z = self.view_ofs_z + 24;
					self.stance = 2;
					break;
				default: break;
			}
		}
	} else
		self.flags = self.flags | FL_JUMPRELEASED;
}


void() PlayerPreThink =
{
	if (self.downed) {
		self.maxspeed = 30;
	} else {
		self.maxspeed = 190;
		if (self.sprinting) {

#ifdef FTE

			if (self.viewzoom > 0.97)
				self.viewzoom -= 0.015;
			else if (self.viewzoom < 0.97)
				self.viewzoom = 0.97;
				
			// viewbob when running 
			self.punchangle_y = 0.6*sin(time*10);

#endif // FTE

			playrun1();
			self.maxspeed *= 1.5; // down from 1.66x, to match WaW
		} else if (!self.sprinting && !self.zoom) {

#ifdef FTE

			if (self.viewzoom < 1)
				self.viewzoom += 0.015;
			else 
				self.viewzoom = 1;
				
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
				self.maxspeed *= 0.5;
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

		self.maxspeed *= GetWeaponWalkSpeed(self.perks, self.weapon);
	}
	if(self.isspec != 0 && !self.downed)
	{
		if(self.button0)
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
		Weapon_Logic();
	}

	JumpCheck(0);

	// refuel/cool m2
	if (self.ltime < time) {
		if (self.currentmag == 0 && !self.cooldown) {
			self.cooldown = true;
		}

		if (self.cooldown && self.currentmag > 20)
			self.cooldown = false;
		
		if (self.weapon == W_M2 || self.weapon == W_FIW && self.currentmag < getWeaponMag(self.weapon))
			self.currentmag += 1;

		self.ltime = time + 0.1;
	}
};

float player_trace_time;
void() PlayerPostThink =
{
	if(self.isspec)
		return;
			
	//landsound
	if((self.oldvelocity_z < -10) && (self.flags & FL_ONGROUND))
	{
		if(self.oldvelocity_z < -270)
			sound(self, CHAN_BODY, "sounds/player/land.wav", 1, 1.75);
		self.lastsound_time = time - 0.15;
	}
	
#ifdef FTE

	//footsteps
	if((vlen(self.velocity) > 100) &&(( time - self.lastsound_time > 0.4) || (time - self.lastsound_time > 0.3 && self.sprinting)) && (self.flags & FL_ONGROUND))
	{
		local float movelen = vlen(input_movevalues);
		if(movelen > 300)
		{
			if (!self.sprinting)
				playwalk();
				
			local float ran = random();
			if(ran > 0.8)
				sound(self, CHAN_BODY, "sounds/player/footstep1.wav", 0.8, 2.5);
			else if(ran > 0.6)
				sound(self, CHAN_BODY, "sounds/player/footstep2.wav", 0.8, 2.5);
			else if(ran > 0.4)
				sound(self, CHAN_BODY, "sounds/player/footstep3.wav", 0.8, 2.5);
			else if(ran > 0.2)
				sound(self, CHAN_BODY, "sounds/player/footstep4.wav", 0.8, 2.5);
			else
				sound(self, CHAN_BODY, "sounds/player/footstep5.wav", 0.8, 2.5);
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

void() PollPlayerPoints =
{
	float i, breakpoint;
	entity pollent;
	breakpoint = 0;
	
	for (i = 1; i <= 4 && !breakpoint; i++)
	{
		pollent = findfloat(world, playernum, i);
		
		if (pollent == world) {
			breakpoint = 1;
			break;
		}
		UpdatePlayerPoints(i, pollent.points, pollent.kills, 0, pollent.netname, pollent);
	}
}

void() PlayerSpawn =
{	
	entity spawnpoint = world;
	local_client = self;

	self.isspec = FALSE;
	self.classname = "player";
	self.solid = SOLID_BBOX;

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
			coop = 1;
			player_count++;
			break;
		}
	}

	if (!self.playernum) {
		self.playernum = player_count + 1;
		if (self.playernum == 1)
			pl1 = self;
	}

	float viable_spawnpoint = false;

	// if the mapper doesn't have the co-op ents set up, just plop everyone at the
	// normal start.
	if (find(world, classname, "info_player_tank") == world && 
	find(world, classname, "info_player_nikolai") == world &&
	find(world, classname, "info_player_takeo") == world && 
	find(world, classname, "info_player_doctor") == world) {
		spawnpoint = find(world, classname, "info_player_start");
		viable_spawnpoint = true;
	}

	//
	// pick a random spawn point regardless of solo or co-op
	//

	while(!viable_spawnpoint) {
		float number = random();

		// assign one of the spawnpoints
		if (number < 0.25)
			spawnpoint = find(world, classname, "info_player_tank");
		else if (number < 0.50)
			spawnpoint = find(world, classname, "info_player_nikolai");
		else if (number < 0.75)
			spawnpoint = find(world, classname, "info_player_takeo");
		else
			spawnpoint = find(world, classname, "info_player_doctor");

		float found_player_here = false;

		entity ents_in_spawn_range = findradius(spawnpoint.origin, 32);

		// check if there's a player in the way
		while(ents_in_spawn_range != world) {
			if (ents_in_spawn_range.classname == "player")
				found_player_here = true;

			ents_in_spawn_range = ents_in_spawn_range.chain;
		}

		// no player in the way, this spawn is good.
		if (found_player_here == false)
			viable_spawnpoint = true;
	}

	// Mapper doesn't have our specific co-op spawn set up..
	if (spawnpoint == world)
		spawnpoint = find(world, classname, "info_player_start");

	
	self.origin = spawnpoint.origin + [0,0,1];
	self.angles = spawnpoint.angles;
	self.fixangle = TRUE;
	setsize(self, [-16, -16, -32], [16, 16, 40]);
	self.view_ofs = VEC_VIEW_OFS; // naievil -- set view_ofs to 32 to maintain half life (64) sizes
	self.stance = 2;
	self.new_ofs_z = self.view_ofs_z;
	self.oldz = self.origin_z;

	self.currentammo = G_STARTWEAPON[2];
	self.currentmag = G_STARTWEAPON[1];
	self.weapon = G_STARTWEAPON[0];
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

	SwitchWeapon(self.weapon);

	self.stamina = 3;
	self.reviving = 0;
	self.weaponnum = 0;
	self.perks = G_PERKS;
	SetPerk(self, self.perks);

	if (rounds < 1 && player_count == 0) {
		sound(self, CHAN_AUTO, "sounds/rounds/splash.wav", 1, ATTN_NONE);
		sound(self, CHAN_ITEM, "sounds/rounds/nround.wav", 0.75, ATTN_NONE);
	}

	PromptLevelChange(self.nextthink + 3, 1, self);	
	UpdatePlayerCount(player_count);
	
#ifdef FTE

	PollPlayerPoints();
	UpdateV2model("", 0);
	stuffcmd(self, "cl_gunx 8;cl_guny 16;cl_gunz 25\n");
	SetRound(self, G_STARTROUND);
	self.viewzoom = 1;
	self.weapon_animduration = getWeaponDelay(self.weapon, FIRE);

	if (G_WORLDTEXT)
		WorldText(world.chaptertitle, world.location, world.date, world.person, self);

#else 

	self.Weapon_Name = GetWeaponName(self.weapon);
	self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
	self.Flash_Size = GetWeaponFlash_Size(self.weapon);

#endif // FTE

	if (G_STARTROUND != 1) {
		rounds = G_STARTROUND - 1;
	}

};

void() SpectatorSpawn =
{
	local entity spawnpoint;
	spawnpoint = find(world, classname, "info_player_start");
	
	self.isspec = TRUE;
	self.health = 420;
	self.classname = "spectator";
	self.solid = SOLID_NOT;
	setmodel(self, "");
	self.movetype = MOVETYPE_FLY;
	self.origin = spawnpoint.origin + [0,0,1];
	self.fixangle = TRUE;
	setsize(self, [-16, -16, -24], [16, 16, 32]);
	self.view_ofs = '0 0 22';
	self.aiment = world;
};

//called when a client loads a map
void() PutClientInServer =
{
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
	self.movetype = MOVETYPE_TOSS;
	self.nextthink = -1;
	setmodel(self, "models/sprites/null.spr");
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
