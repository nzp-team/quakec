/*
	server/entities/mystery_box.qc

	Mystery Box Entity Logic

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

void(vector where, float time_alive) SpawnSpark;
void() MBOX_Touch;

#define MBOX_SPAWNFLAG_NOTHERE 		1
#define MBOX_SPAWNFLAG_NOLIGHT 		2

//
// MBOX_UpdateGlowFrame()
// Updates the Glow model frame to match
// the box if it exists.
//
void() MBOX_UpdateGlowFrame =
{
	if (self.goaldummy) self.goaldummy.frame = self.frame;
};

//
// MBOX_PlayOpenAnimation()
// Plays the open animation for the Mystery Box,
// frames 1-8.
//
void() MBOX_PlayOpenAnimation  = [1, MBOX_OpenAnimation2 ] { self.frame = 1; MBOX_UpdateGlowFrame(); Light_Yellow(self); };
void() MBOX_OpenAnimation2 = [2, MBOX_OpenAnimation3 ] { self.frame = 2; MBOX_UpdateGlowFrame(); };
void() MBOX_OpenAnimation3 = [3, MBOX_OpenAnimation4 ] { self.frame = 3; MBOX_UpdateGlowFrame(); };
void() MBOX_OpenAnimation4 = [4, MBOX_OpenAnimation5 ] { self.frame = 4; MBOX_UpdateGlowFrame(); };
void() MBOX_OpenAnimation5 = [5, MBOX_OpenAnimation6 ] { self.frame = 5; MBOX_UpdateGlowFrame(); };
void() MBOX_OpenAnimation6 = [6, MBOX_OpenAnimation7 ] { self.frame = 6; MBOX_UpdateGlowFrame(); };
void() MBOX_OpenAnimation7 = [7, MBOX_OpenAnimation8 ] { self.frame = 7; MBOX_UpdateGlowFrame(); };
void() MBOX_OpenAnimation8 = [8, SUB_Null            ] { self.frame = 8; MBOX_UpdateGlowFrame(); };

//
// MBOX_WaitEnd()
// Ends the per-use delay for the Mystery Box.
//
void() MBOX_WaitEnd =
{
	self.boxstatus = 0;
	self.think = SUB_Null;
}

//
// MBOX_Reset()
// Resets the Mystery Box to be ready for
// another use.
//
inline void() MBOX_Reset = 
{
	self.frame = 0;
	self.boxstatus = -1;

	// Add a 3 second delay before the Mystery Box
	// can be interact with again.
	self.think = MBOX_WaitEnd;
	self.nextthink = time + 3;
};

//
// MBOX_PlayCloseAnimation()
// Plays the open animation for the Mystery Box,
// frames 9-12.
//
void() MBOX_PlayCloseAnimation  = [9, MBOX_CloseAnimation2 ] { self.frame = 9; MBOX_UpdateGlowFrame(); sound (self, CHAN_ITEM, mystery_box_close_sound, 1, ATTN_NORM); Light_None(self); };
void() MBOX_CloseAnimation2 = [10, MBOX_CloseAnimation3 ] { self.frame = 10; MBOX_UpdateGlowFrame(); };
void() MBOX_CloseAnimation3 = [10, MBOX_CloseAnimation4 ] { self.frame = 11; MBOX_UpdateGlowFrame(); };
void() MBOX_CloseAnimation4 = [10, MBOX_Reset           ] { self.frame = 12; MBOX_UpdateGlowFrame(); };

//
// MBOX_FreeEnt(ent)
// Marks an MBOX entity as able to be used.
//
void(entity ent) MBOX_FreeEnt =
{
	setmodel(ent, "");
	ent.classname = "freeMboxEntity";
	ent.touch = SUB_Null;
	ent.think = SUB_Null;
	ent.scale = 1;
    ent.effects = 0;
	ent.frame = 0;

#ifdef FTE

	ent.alpha = 1;

#endif // FTE

};

//
// MBOX_GetFreeEnt()
// Returns an MBOX entity to use.
//
entity() MBOX_GetFreeEnt =
{
	entity ent;
	ent = find(world, classname, "freeMboxEntity");

	if (ent == world)
		error("MBOX_GetFreeEnt: No free MBOX Entity. (Hacks?)\n");
	
	return ent;
};

//
// MBOX_GetRandomBoxWeapon(user)
// Returns a weapon from the Mystery Box allow-list
// that the user is not holding.
//
float(entity user) MBOX_GetRandomBoxWeapon =
{
    float weapon_index = rint((random() * (MAX_BOX_WEAPONS - 1)));
    float weapon_id = mystery_box_weapons[weapon_index].weapon_id;
    float weapon_allowed = mystery_box_weapons[weapon_index].allowed && 
							!mystery_box_weapons[weapon_index].already_obtained;

    if (weapon_allowed == true && !Weapon_PlayerHasWeapon(user, weapon_id, true))
        return weapon_id;
    else
        return MBOX_GetRandomBoxWeapon(user);
};

//
// Reset_MBox()
// Resets the Mystery Box to it's inital State.
//
void() Reset_MBox =
{
	entity tempe;
	self.velocity = '0 0 0';
	tempe = self;
	self = self.owner;
	MBOX_PlayCloseAnimation();
	self = tempe;
	self.owner.owner = world;
	self.owner.boxstatus = 0;
	MBOX_FreeEnt(self);
}

//
// Float_Decreate()
// Make the Gun in the Box slowly descend, eventually
// resetting the Box.
//
void() Float_Decrease =
{
	makevectors(self.angles);
	self.velocity = v_up*-5;
	self.nextthink = time + 7;
	self.think = Reset_MBox;
}

//
// findboxspot()
// Locate a new MBox spot and turn this spot into
// a tp_spot.
//
void() findboxspot =
{	
	local entity newspot;
	local float box = rint(random(mystery_box_count));
	newspot = mystery_boxes[box];

	// Ensure the spot we choose is valid.
	while(newspot == world || newspot == self.owner) {
		box = rint(random(mystery_box_count));
		newspot = mystery_boxes[box];
	}

	// Make our current spot a tp_spot
	self.owner.model = "models/props/teddy.mdl";
	self.owner.frame = 2;
	setmodel(self.owner, self.owner.model);
	self.owner.classname = "mystery_box_tp_spot";
	self.owner.touch = SUB_Null;
	self.owner.angles_y -= 90;
	Light_None(self.owner);
	
	newspot.angles_y += 90;

	// Spawn the Box Glow if permitted
	if (!(self.owner.spawnflags & MBOX_SPAWNFLAG_NOLIGHT))
	{
		entity g;
		g = MBOX_GetFreeEnt();
		g.classname = "mystery_glow";
		newspot.goaldummy = g;
		setmodel(g, mystery_box_glow_model);
		setorigin(g,newspot.origin);
		g.angles = newspot.angles;
		g.effects = EF_FULLBRIGHT;

#ifdef FTE

		g.alpha = 0.5;

#endif // FTE

	}
	
	// Remove teddy
	MBOX_FreeEnt(self);
	
	// Set some values and change the found Spot to an MBox
	newspot.spins = 0;
	newspot.boxstatus = 0;
	newspot.touch = MBOX_Touch;
	newspot.solid=SOLID_TRIGGER;
	newspot.classname = "mystery";
	newspot.spawnflags = self.owner.spawnflags;
	setorigin(newspot, newspot.origin);
	setmodel (newspot, mystery_box_model);
	newspot.frame = 0;
	setsize (newspot, VEC_HULL2_MIN, VEC_HULL2_MAX);

	// Scale down for NZ:P Beta
	if (map_compatibility_mode == MAP_COMPAT_BETA)
		newspot.scale = 0.75;
}

//
// MBOX_MakeActive()
// Sets the Mystery Box touch to MBOX_Touch (delay)
//
void() MBOX_MakeActive =
{
	self.touch = MBOX_Touch;
}

//
// MBOX_FindNewSpot()
// Locate a new location for the Mystery Box.
//
void() MBOX_FindNewSpot =
{
	entity new_box = world;

	// Find a new Mystery Box location
	while(new_box == world || new_box == self) {
		float box_index = rint(random(mystery_box_count));
		new_box = mystery_boxes[box_index];
	}

	// Stupid Teddy Bear being rotated!!
	new_box.angles_y += 90;

	// Convert the spawn to a Mystery Box
	new_box.spawnflags = self.spawnflags;
	new_box.spins = new_box.boxstatus = 0;
	new_box.think = MBOX_MakeActive;
	new_box.nextthink = time + 2;
	new_box.solid = SOLID_TRIGGER;
	new_box.classname = "mystery";
	new_box.frame = 0;
	setmodel(new_box, mystery_box_model);
	setsize(new_box, VEC_HULL2_MIN, VEC_HULL2_MAX);

	// Scale down for NZ:P Beta
	if (map_compatibility_mode == MAP_COMPAT_BETA)
		new_box.scale = 0.75;

	// Spawn the Box Glow if permitted
	if (!(new_box.spawnflags & MBOX_SPAWNFLAG_NOLIGHT))
	{
		entity light;
		light = MBOX_GetFreeEnt();
		light.classname = "mystery_glow";
		new_box.goaldummy = light;
		setmodel(light, mystery_box_glow_model);
		setorigin(light, new_box.origin);
		light.angles = new_box.angles;
		light.effects = EF_FULLBRIGHT;

#ifdef FTE

		light.alpha = 0.5;

#endif // FTE

	}

	// Spawn some sparkles so it doesn't just "appear"
	SpawnSpark(new_box.origin, 0.75);
	// "Woosh" Effect
	sound(new_box, CHAN_AUTO, "sounds/pu/drop.wav", 1, ATTN_NORM);
}

//
// MBOX_StopFlying()
// We've done our dance, go away and
// delay respawning.
//
void() MBOX_StopFlying = 
{
	// Spark Effect
	SpawnSpark(self.origin, 0.75);
	// "Woosh" Effect
	sound(self, CHAN_AUTO, "sounds/pu/drop.wav", 1, ATTN_NORM);
	// Disappear!
	self.model = "models/props/teddy.mdl";
	setmodel(self, self.model);
	self.frame = 2;
	// Clean up
	self.origin = self.oldvelocity;
	self.angles = self.movement;
	self.velocity = 0;
	self.angles_y -= 90;
	self.classname = "mystery_box_tp_spot";
	self.touch = SUB_Null;
	// 12 Second delay to finding a new spot
	self.think = MBOX_FindNewSpot;
	self.nextthink = time + 12;
}

//
// MBOX_AnimateFly()
// Rotate the Mystery Box as it flies away.
//
void() MBOX_AnimateFly =
{
	if (self.score == 0)
		self.angles_x += 6;
	else
		self.angles_x -= 6;

	if (self.angles_x - self.movement_x >= 20)
		self.score = 1;
	else if (self.angles_x - self.movement_x <= -20)
		self.score = 0;

	if(self.ltime < time) {
		MBOX_StopFlying();
	} else {
		self.nextthink = time + 0.05;
	}
}

//
// MBOX_FlyAway()
// The actual leave animation.
//
void() MBOX_FlyAway =
{
	// Begin rising
	makevectors(self.angles);
	self.movetype = MOVETYPE_NOCLIP;
	self.velocity = v_up * 7;
	// Animation lasts 4 seconds
	self.ltime = time + 4;
	// Animation Update
	self.think = MBOX_AnimateFly;
	self.nextthink = time + 0.05;
}

//
// MBOX_Leave()
// Starts Mystery Box Leave animation.
//
void() MBOX_Leave =
{
	// Broadcast the laughter
	sound(self, CHAN_ITEM, "sounds/pu/byebye.wav", 1, ATTN_NONE);
	// "Woosh" Effect
	sound(self, CHAN_AUTO, "sounds/pu/drop.wav", 1, ATTN_NORM);
	// Spark Effect
	SpawnSpark(self.origin, 0.75);
	// Turn off Light & Glow
	Light_None(self);
	if (!(self.spawnflags & MBOX_SPAWNFLAG_NOLIGHT)) 
		if (self.goaldummy != world)
			MBOX_FreeEnt(self.goaldummy);
	// Save old position and angle
	self.oldvelocity = self.origin;
	self.movement = self.angles;
	// Start flying
	self.think = MBOX_FlyAway;
	self.nextthink = time + 0.05;
}

//
// MBOX_TeddyDespawn()
// Frees the Teddy Bear entity.
//
void() MBOX_TeddyDespawn =
{
	self.velocity = 0;
	MBOX_FreeEnt(self);
}

//
// MBOX_TeddyLeave()
// Make the Teddy Bear float away and start the
// timer for the Mystery Box to follow.
//
void() MBOX_TeddyLeave =
{
	// Fly slowly
	self.velocity = v_up*75;
	self.think = MBOX_TeddyDespawn;
	self.nextthink = time + 5;
	// Linger for 3 seconds, and then the Box follows.
	self.owner.think = MBOX_Leave;
	self.owner.nextthink = time + 3;
}

//
// MBOX_PresentTeddy()
// Lets the Teddy Bear idle for a few seconds,
// return player points, kick-off leave.
//
void() MBOX_PresentTeddy =
{
	// Return the Player's points.
	Player_AddScore(self.owner.owner, mystery_box_cost, false);

	// Broadcast the bad luck.
	sound(self, CHAN_ITEM, "sounds/misc/buy.wav", 1, ATTN_NONE);
	sound(self, 2, "sounds/misc/giggle.wav", 1, ATTN_NONE);
	// Linger for 2 seconds, and then fly away.
	self.think = MBOX_TeddyLeave;
	self.nextthink = time + 2;
}

//
// MBOX_GetLeaveChancePercentage()
// Generates a percentage chance for the Mystery Box
// to leave.
//
float(float uses) MBOX_GetLeaveChancePercentage =
{
    // If there's only one Mystery Box, never try to leave.
    // Additionally, you're always given 4 free uses.
    if (mystery_box_count == 1 || uses <= 4)
        return 0;

    float chance_to_leave = 0;
    
    // There is a hardcoded 100% chance to leave after 8 uses
    // if the box hasn't moved yet in a game.
    if (mystery_box_leave_count == 0 && uses >= 8)
        chance_to_leave = 100;

    // There's a 15% chance for leaving if this is between the uses
    // of 4 and 8.
    if (uses >= 4 && uses < 8)
        chance_to_leave = 15;

    // Mystery Box behavior changes after it leaves for the first time
    if (mystery_box_leave_count > 0) {
        // 30% chance of leaving between uses 8 and 12.
        if (uses >= 8 && uses < 12)
            chance_to_leave = 30;
        // 50% chance after the 12th use.
        else if (uses >= 12)
            chance_to_leave = 50;
    }

    return chance_to_leave/100;
}

void() Float_Change =
{
	float tempf;
	string temps;

    float leave_chance;

	tempf = MBOX_GetRandomBoxWeapon(self.owner.owner);
	temps = GetWeaponModel(tempf, 1);
	setmodel (self, temps);

	self.boxstatus = self.boxstatus + 0.01;
	if (self.wait <= time)
	{
        leave_chance = MBOX_GetLeaveChancePercentage(self.owner.spins);
				
		self.velocity = '0 0 0';
		
		if (random() > leave_chance) {		//teddy gen threshold, high means less chance
			self.owner.boxstatus = 2;
			self.weapon = tempf;
			self.nextthink = time + 5;
			self.think = Float_Decrease;
			//bprint(PRINT_HIGH, "spot not found, or teddygun is > 0.7\n");
			return;
		}
		else {
			self.model = "models/props/teddy.mdl";
			setmodel(self, self.model);
			self.angles_y = self.angles_y - 90;
			self.nextthink = time + 1;
			self.think = MBOX_PresentTeddy;
			mystery_box_leave_count++;

			if (mystery_box_leave_count >= 10)
				GiveAchievement(11);
			return;
		}
	}
	if (self.ltime <= time)
	{
		self.velocity_z = self.velocity_z*0.5;
		self.ltime = 0.5;
	}
	self.nextthink = time + self.boxstatus;
	self.think = Float_Change;
}

void() finish_mbox_setup =
{
	// Temporary hack for random box spawns until rewrite - Mikey (27/03/2023, DD/MM/YYYY)
    if(self.spawnflags & MBOX_SPAWNFLAG_NOTHERE) {
        entity temp = MBOX_GetFreeEnt();
		temp.classname = "mystery_helper";

        temp.owner = self;
        temp.think = findboxspot;
        temp.nextthink = time + 0.1;
    } else if(!(self.spawnflags & MBOX_SPAWNFLAG_NOLIGHT)) {
        entity g = MBOX_GetFreeEnt();
		g.classname = "mystery_glow";

		self.goaldummy = g;
		setmodel(g, mystery_box_glow_model);
		setorigin(g,self.origin);
		g.angles = self.angles;
		g.effects = EF_FULLBRIGHT;

#ifdef FTE

		g.alpha = 0.5;

#endif // FTE

    }
}

//
// MBOX_AllocateTempEntities()
// Spawns in all of the temp entities that are
// used for the floating weapons, teddy bear,
// and glow.
//
void() MBOX_AllocateTempEntities =
{
	self.think = SUB_Null;

	for (float i = 0; i < mystery_box_count * 3; i++) {
		entity tempe = spawn();
		tempe.classname = "freeMboxEntity";
	}

	finish_mbox_setup();
};

void() Create_Floating_Weapon =
{
	entity gun;
	float tempf;
	string temps;

	tempf = MBOX_GetRandomBoxWeapon(self.owner.owner);
	temps = GetWeaponModel(tempf, 1);
		
	gun = MBOX_GetFreeEnt();
	gun.classname = "mystery_weapon";
	
	setorigin (gun, self.origin);
	setmodel (gun, temps);
	setsize (gun, '0 0 0', '0 0 0');
	gun.angles = self.angles;
	
	gun.movetype = MOVETYPE_NOCLIP;
	gun.solid = SOLID_NOT;
	makevectors(self.angles);

	// Float up less in NZ:P Beta, and scale down.
	if (map_compatibility_mode == MAP_COMPAT_BETA) {
		gun.velocity = v_up*10;
		gun.scale = 0.75;
	} else {
		gun.velocity = v_up*15;
	}
	
	gun.owner = self;
	self.boxweapon = gun;
	
	gun.ltime = time+2;
	gun.boxstatus = 0.01;
	gun.wait = time + 5;
	gun.nextthink = time + 0.01;
	gun.think = Float_Change;
}

void() mystery_box_tp_spot = 
{
	precache_model ("models/props/teddy.mdl"); 
	precache_sound ("sounds/pu/byebye.wav");
	precache_sound ("sounds/misc/giggle.wav");
	
	self.solid=SOLID_TRIGGER;
	self.classname = "mystery_box_tp_spot";
	setorigin(self, self.origin);
	setmodel (self, "models/props/teddy.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
	if (self.model == "models/props/teddy.mdl") {
		self.frame = 2;
		self.angles_y -= 90;
	}
	
	mystery_boxes[mystery_box_count] = self;
	mystery_box_count++;
};

void() MBOX_UpdatePosessionStatus =
{
	// Set all weapon statuses as unobtained.
	for(float i = 0; i < MAX_BOX_WEAPONS; i++) {
		mystery_box_weapons[i].already_obtained = false;
	}

	entity player = find(world, classname, "player");

	while(player != world) {
		for(float i = 0; i < MAX_BOX_WEAPONS; i++) {
			float weapon_id = mystery_box_weapons[i].weapon_id;
			if (Weapon_PlayerHasWeapon(player, weapon_id, true) && WepDef_OnlyOneAllowed(weapon_id)) {
				mystery_box_weapons[i].already_obtained = true;
			}
		}
		player = find(player, classname, "player");
	}
}

void() MBOX_Touch =
{
	entity tempe;
	
	if (other.classname != "player" || other.downed)
		return;
		
	if (!self.boxstatus) {
		useprint (other, 6, mystery_box_cost, 0);
	}
	if (self.boxstatus == 2 && self.owner == other) {

#ifndef FTE

		other.Weapon_Name_Touch = GetWeaponName(self.boxweapon.weapon);

#endif // FTE

		useprint (other, 7, 0, self.boxweapon.weapon);
	}
	
	if (other.button7 && !(other.semi_actions & SEMIACTION_USE))
	{
		other.semi_actions |= SEMIACTION_USE;
		if (!self.boxstatus)
		{
			if (other.points >= mystery_box_cost)
			{					
				sound (self, CHAN_ITEM, mystery_box_open_sound, 1, ATTN_NORM);
				Player_RemoveScore(other, mystery_box_cost);
				self.boxstatus = 1;
				self.owner = other;
				MBOX_PlayOpenAnimation();
				Create_Floating_Weapon();
				MBOX_UpdatePosessionStatus();
				self.spins++;
			}
			else {
        		centerprint (other, STR_NOTENOUGHPOINTS);
				sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			}
		}
		if (self.boxstatus == 2)
		{
			if (self.owner == other)
			{
				other.reload_delay = 0;
				self.owner = world;
				sound(self, 0,"sounds/misc/ching.wav", 1, 1);
				tempe = self;
				self = other;

				Weapon_GiveWeapon(tempe.boxweapon.weapon, 0, 0);
				self = tempe;
				MBOX_FreeEnt(self.boxweapon);
				MBOX_PlayCloseAnimation();
			}
		}
	}
}

//
// MBOX_GetWeaponIDFromMB1(mbox_id)
// .mbox weapon IDs did not 100% correlate
// to internal weapon IDs, so this converts
// them appropriately.
//
float MBOX_GetWeaponIDFromMB1(float mbox_id) =
{
    switch(mbox_id) {
        case 0: return W_COLT;
        case 1: return W_KAR;
        case 2: return W_DB;
        case 3: return W_MG;
        case 4: return W_RAY;
        case 5: return W_THOMPSON;
        case 6: return W_M2;
        case 7: return W_PPSH;
        case 8: return W_SAWNOFF;
        case 9: return W_TESLA;
        case 10: return W_M1A1;
        case 11: return W_GEWEHR;
        case 12: return W_FG;
        case 13: return W_BROWNING;
        case 14: return W_KAR_SCOPE;
        case 15: return W_357;
        case 16: return W_STG;
        case 17: return W_PANZER;
        case 18: return W_BK;
        case 19: return W_PTRS;
        case 20: return W_MP40;
        case 21: return W_TRENCH;
        case 22: return W_BAR;
        case 23: return W_M1;
        case 24: return W_TYPE;
        case 25: return W_MP5K;
        case 26: return W_SPRING;
        default: return W_COLT;
    }
    return W_COLT;
}

//
// MBOX_PrecacheWeaponData()
// Iterates through the weapon array and
// allocates necessary content for each
// allowed weapon.
//
void() MBOX_PrecacheWeaponContent =
{
    for (float i = 0; i < MAX_BOX_WEAPONS; i++) {
        if (mystery_box_weapons[i].allowed == true) {
            precache_model(GetWeaponModel(mystery_box_weapons[i].weapon_id, 0));
		    precache_model(GetWeaponModel(mystery_box_weapons[i].weapon_id, 1));
		    precache_extra(mystery_box_weapons[i].weapon_id);
        }
    }
}

//
// MBOX_ParseMB1File(mbox_file)
// Parses the old (2014) .mbox file and loads
// it into the necessary structure.
//
void(float mbox_file) MBOX_ParseMB1File =
{
    string  file_line;

    // Parse the .mbox line-by-line and fill the data structure.
    for (float i = 0; i < MAX_BOX_WEAPONS; i++) {
        file_line = strtrim((fgets(mbox_file)));
        mystery_box_weapons[i].weapon_id = MBOX_GetWeaponIDFromMB1(i);
        mystery_box_weapons[i].allowed = stof(file_line);
        mystery_box_weapons[i].rarity = -1;
    }

    // Precache the allowed weapons
    MBOX_PrecacheWeaponContent();
}

//
// MBOX_GetUnusedWeaponID()
// Returns a weapon ID for a potential
// box weapon that is not currently
// in the list.
//
float() MBOX_GetUnusedWeaponID =
{
    // Iterate over every potential Box Weapon
    for (float i = 0; i < MAX_BOX_WEAPONS; i++) {
        float weapon_in_use = false;
        float weapon_id = MBOX_GetWeaponIDFromMB1(i);

        // Now over every weapon in the list
        for (float j = 0; j < MAX_BOX_WEAPONS; j++) {
            if (mystery_box_weapons[j].weapon_id == weapon_id)
                weapon_in_use = true;
        }

        if (weapon_in_use == false) {
            return weapon_id;
        }
    }

    error("MBOX_GetunusedWeaponID: Could not find a free weapon slot!\n");
    return 0;
}

//
// MBOX_ParseMB2File(mbox_file)
// Parses the current .mb2 file and loads it
// into the necessary structure.
//
void(float mbox_file) MBOX_ParseMB2File =
{
    string file_line;

    // Read the first line: It's our "header", should be
    // "nzp_mbox2".
    file_line = strtrim((fgets(mbox_file)));

    if (file_line != "nzp_mbox2")
        error(strcat("MBOX_ParseMB2File: Expected \"nzp_mbox2\" but got ", file_line));

    // Read each line of the file in a loop
    float finished_parsing = false;
    float parsing_state = 0;
    float is_allow_not_deny = false;
    float weapons_parsed = 0;
    float weapon_id = 0;
    while(!finished_parsing) {
        // Grab a new line
        file_line = fgets(mbox_file);

        // End of file.
        if not (file_line) {
            finished_parsing = true;
            break;
        }

        file_line = strzone(strtrim(file_line));

        // Check for comments, they always start with '#'.
        // Also ignore whitespace.
        string first_char = strzone(substring(file_line, 0, 1));
        if (first_char == "#" || file_line == "") {
            continue;
        }
        strunzone(first_char);

        //
        // Actual Content Parsing
        //

        // Retrieving if its an allow or deny list.
        if (parsing_state == 0) {
            if (file_line == "allow:")
                is_allow_not_deny = true;
            else if (file_line == "deny:")
                is_allow_not_deny = false;
            else
                error(strcat("MBOX_ParseMB2File: Not an allow/deny specifier - ", file_line));

            // Now that we know the list, we can begin
            // parsing the weapons inside of it.
            parsing_state++;
        } else if (parsing_state == 1) {
            // Get the weapon ID from it's name.
            weapon_id = WepDef_GetWeaponIDFromName(file_line);

            if (weapon_id == W_NOWEP)
                error(strcat("MBOX_ParseMB2File: Not a weapon - ", file_line));

            // Fill the list with it.
            mystery_box_weapons[weapons_parsed].weapon_id = weapon_id;
            mystery_box_weapons[weapons_parsed].allowed = is_allow_not_deny;
            weapons_parsed++;
        }

        strunzone(file_line);
    }

    // At this point, the file has been parsed with all of the
    // allowed/denied weapons, now we have to automatically
    // fill in the rest for the opposite list.
    for (float i = weapons_parsed; i < MAX_BOX_WEAPONS; i++) {
        // We need to pick an ID to assign that hasn't already
        // been used.
        weapon_id = MBOX_GetUnusedWeaponID();
        mystery_box_weapons[i].weapon_id = weapon_id;
        mystery_box_weapons[i].allowed = !is_allow_not_deny;
    }

    // Precache the allowed weapons
    MBOX_PrecacheWeaponContent();
}

//
// MBOX_LoadData()
// Seeks for either an .mb2 or .mbox file,
// and adds the contents into the Mystery Box
// weapon list.
//
void() MBOX_LoadData =
{
    float mbox_file;
    string file_path;

    // Attempt 1: Seek for maps/mapname.mb2 (mbox-2)
    file_path = strcat(mapname, ".mb2");
    file_path = strcat("maps/", file_path);
    mbox_file = fopen(file_path, FILE_READ);
    if (mbox_file != -1) {
        MBOX_ParseMB2File(mbox_file);
        fclose(mbox_file);
        return;
    }

    // Attempt 2: Seek for maps/mapname.mbox (mbox-1)
    file_path = strcat(mapname, ".mbox");
    file_path = strcat("maps/", file_path);
    mbox_file = fopen(file_path, FILE_READ);
    if (mbox_file != -1) {
        MBOX_ParseMB1File(mbox_file);
        fclose(mbox_file);
        return;
    }

    // Attempt 3: Include All Weapons
    for (float i = 0; i < MAX_BOX_WEAPONS; i++) {
        mystery_box_weapons[i].weapon_id = MBOX_GetWeaponIDFromMB1(i);
        mystery_box_weapons[i].allowed = true;
        mystery_box_weapons[i].rarity = -1;
    }

    // Precache it all.
    MBOX_PrecacheWeaponContent();
    
    // Close the file pointer just in case.
    fclose(mbox_file);
}

void() mystery_box =
{
    // Load and cache all of the allowed weapons into the hunk.
    MBOX_LoadData();

    //
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/mystery.mdl";
	}

    // Light Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/mglow$.mdl";
	}

    // Cost
	if (!self.cost) {
		self.cost = 950;
	}

    // Open Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/mbox_open.wav";
	}

	// Close Sound
	if (!self.powerup_vo) {
		self.powerup_vo = "sounds/machines/mbox_close.wav";
	}

    // Store the custom presentation as globals
    mystery_box_model = self.model;
    mystery_box_glow_model = self.weapon2model;
    mystery_box_open_sound = self.oldmodel;
    mystery_box_close_sound = self.powerup_vo;
    mystery_box_cost = self.cost;

	precache_model(mystery_box_model);

    if (!(self.spawnflags & MBOX_SPAWNFLAG_NOLIGHT))
		precache_model (mystery_box_glow_model);

	precache_sound(mystery_box_open_sound); 
	precache_sound(mystery_box_close_sound); 
	
	self.solid = SOLID_TRIGGER;
	self.classname = "mystery";
	setorigin(self, self.origin);
	setmodel (self, mystery_box_model);
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);

	self.touch = MBOX_Touch;

	mystery_box_start_origin = self.origin;
	mystery_boxes[mystery_box_count] = self;
	mystery_box_count++;

	self.think = MBOX_AllocateTempEntities;
	self.nextthink = time + 0.2;
};