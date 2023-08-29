/*
	server/entities/machines.qc

	perks, pap, power

	Copyright (C) 2021-2023 NZ:P Team

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

float backupWepSkin;
float sound_perk_delay; 
void() W_Switch;
void() W_TakeOut;

//
// --------------------
// Core Perk System
// --------------------
//

// Light Color Spawnflags
#define PERK_SPAWNFLAG_NOLIGHT 		1
#define PERK_SPAWNFLAG_REDLIGHT		2
#define PERK_SPAWNFLAG_GREENLIGHT	4
#define PERK_SPAWNFLAG_BLUELIGHT	8
#define PERK_SPAWNFLAG_ORANGELIGHT	16
#define PERK_SPAWNFLAG_PURPLELIGHT	32
#define PERK_SPAWNFLAG_CYANLIGHT	64
#define PERK_SPAWNFLAG_PINKLIGHT	128
#define PERK_SPAWNFLAG_LIMELIGHT	256
#define PERK_SPAWNFLAG_YELLOWLIGHT	512

#define PERK_JUGGERNOG_HEALTH 		160

//
// GivePerk(p)
// Restores View Model and tells the Client to draw the Perk.
//
void GivePerk(optional float p) {
	float perk;

	// First of, check if our Client is holding anything, this holds
	// priority to prevent interruption.
	if (self.style != 0) {
		perk = self.style;
		self.style = 0;
	} 
	// Next, check if a perk was explicitly set
	else if (p) {
		perk = p;
	}
	// Executed without context.. Nothing to do.
	else {
		return;
	}

	// No Perks? No Problem tracker
	self.ach_tracker_npnp++;

	switch(perk) {
		case P_REVIVE:
			self.perks = self.perks | 8;
			break;
		case P_FLOP:
			self.perks = self.perks | 16;
			break;
		case P_JUG:
			self.perks = self.perks | 1;

			// Instant re-gen, set health to Jugg health.
			self.health = self.max_health = PERK_JUGGERNOG_HEALTH;
			break;
		case P_STAMIN:
			self.perks = self.perks | 32;
			break;
		case P_SPEED:
			self.perks = self.perks | 4;
			break;
		case P_DOUBLE:
			self.perks = self.perks | 2;
			break;
		case P_DEAD:
			self.perks = self.perks | 64;
			break;
		case P_MULE:
			self.perks = self.perks | 128;
			break;
		default:
			break;
	}

	if (self.perks == 255)
		GiveAchievement(6, self);

  	sound_perk_delay = time + 4.5;

	self.isBuying = false;
	self.weaponskin = backupWepSkin;
	self.perk_delay = self.fire_delay;

	Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, SUB_Null, 0);

	SetPerk(self, self.perks);
}

//
// DrinkPerk(perk)
// Gives Perk Bottle and jumps to GivePerk(p)
//
void DrinkPerk(float perk) {
	// Set the Perk Skin based on the Perk sequence.
	// NOTE: If you add perks, you will either need to append
	// the MDL with a tool like QuArK or add an edge-case
	// after this instruction to have a valid skin.
	other.weaponskin = self.sequence - 1;

	other.isBuying = true;
	entity tempe = self;
	self = other;
	
	if (self.sprinting) {
		self.sprinting = 0;
		self.zoom = 0;
	}
		

	self.maxspeed *= GetWeaponWalkSpeed(self.perks, self.weapon);
	
	self.knife_delay = self.reload_delay2 = self.fire_delay2 = self.fire_delay = self.reload_delay = 3 + time;		
	Set_W_Frame (tempe.weapon_animduration, tempe.weapon2_animduration, 2.25, 0, PERK, GivePerk, tempe.weapon2model, true, S_RIGHT);
	self = tempe;
	sound(other, CHAN_ITEM, self.oldmodel, 1, ATTN_NORM);

	// Play Perk Sting if we can and it exists
	if (self.aistatus && self.ltime < time) {
		sound(self, CHAN_AUTO, self.aistatus, 0.5, ATTN_IDLE);
		self.ltime = time + self.anim_weapon_time;
	}
}

//
// SpawnSpark(where, time_alive)
// Technically a utilty function, spawns a spark/elec effect
// at the given origin and lasts until the time given is up.
//
void() SparkThink =
{
	self.frame++;

	if (self.frame >= 3)
		self.frame = 0;
	
	// suicide timer!
	if(self.ltime < time) {
		remove(self);
	}

	self.nextthink = time + 0.05;
}

void(vector where, float time_alive) SpawnSpark =
{
	entity spark = spawn();
	setmodel(spark, "models/sprites/lightning.spr");
	setorigin(spark, where);
	spark.think = SparkThink;
	spark.nextthink = time + 0.05;
	spark.ltime = time + time_alive;
}

//
// ReviveGoAway()
// Called when the max amount of solo revives have been used.
// Does a little animation and then 'teleports' away.
//
void() StopReviveAnimation =
{
	self.velocity = 0;

	setmodel(self, ""); // We don't want to remove Revive in the event of a Soft_Restart..
	SpawnSpark(self.origin, 0.65); // Spawn a Spark at the position
	self.origin = self.oldvelocity; // Restore old position
	Light_None(self); // Remove light effect

	sound(self,CHAN_ITEM,"sounds/pu/drop.wav",1,ATTN_NONE); // Play a fitting sound
}

void() ReviveAnimation =
{
	if (self.score == 0)
		self.angles_z += 6;
	else
		self.angles_z -= 6;

	if (self.angles_z - self.movement_z >= 20)
		self.score = 1;
	else if (self.angles_z - self.movement_z <= -20)
		self.score = 0;

	if(self.ltime < time) {
		StopReviveAnimation();
	} else {
		self.nextthink = time + 0.05;
	}
}

void() ReviveGoAwayForReal =
{
	makevectors(self.angles);
	self.movetype = MOVETYPE_NOCLIP;
	self.velocity = v_up * 7;

	sound(self, CHAN_ITEM, "sounds/pu/byebye.wav", 1, ATTN_NORM);

	// Do our silly little animation for 6 seconds
	self.ltime = time + 6;
	self.think = ReviveAnimation;
	self.nextthink = time + 0.05;
}

void() ReviveGoAway =
{
	// First start a timer, we want to wait until the player finishes drinking
	// before starting the animation.
	self.think = ReviveGoAwayForReal;
	self.nextthink = time + 4;

	// Save our original position to restore on restart
	self.oldvelocity = self.origin;

	// Same with angle
	self.movement = self.angles;
}

//
// touch_perk()
// Executed on touch; prompt purchase and drink if requirements met.
// -----
// MotoLegacy (10-28-20) - Made modular using some existing entity fields we had,
// as the memory is allocated to all entities on load anyway. This comment applies
// to all other relevant jumps as well.
//
void() touch_perk =
{  
	if (other.classname != "player" || other.downed || other.isBuying == true)
		return;

	// If we're proned and the map permits, collect some spare change
	if (other.stance == 0 && self.collected == false && G_PRONEPOINTS != 0) {
		self.collected = true;
		addmoney(other, G_PRONEPOINTS, 0);
		sound(self, 0,"sounds/misc/ching.wav", 1, 1);
	}

	// Do this after the perk change check
	if (other.stance == 0)
		return;
	  
	// Power's off! Nothing to do here.
	if (self.requirespower == true && !isPowerOn) {
		useprint (other, 8, 0, 0);
		return;
	}

	// Back up weapon skin
	backupWepSkin = other.weaponskin;

	// Don't prompt if our hands or busy or we already have the perk
	if (!(other.perks & self.style) && other.fire_delay < time && self.revivesoda < 3) {
		float price;

		// Check if this is Quick Revive and we are playing in Co-Op,
		// adjust price if so.
		if (self.classname == "perk_revive" && player_count >= 1)
			price = self.cost2;
		// Nope, use normal cost.
		else
			price = self.cost;

		// sequence = perk ID in client
		useprint(other, 9, price, self.sequence);

		if (other.points >= price && other.button7 && !other.semiuse) {
			addmoney(other, -price, 0);

			// Pass along the Perk information to the Player to avoid complications later on, then Drink!
			other.style = self.style;
			DrinkPerk(self.style);

			// Do Self-Revive checks
			if (self.classname == "perk_revive" && !coop && !deathmatch) {
				// Increment self-revive count
				self.revivesoda++;

				if (self.revivesoda >= 3) {
					ReviveGoAway();
				}
			}
			other.semiuse = true;
		} else if (other.button7 && !other.semiuse) {
			// We tried to use, but we don't have the cash..
			centerprint(other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			other.semiuse = true;
		}
	}
}

//
// Turn_PerkLight_On(who)
// Turns on the Perk Lights
//
void(entity who) Turn_PerkLight_On =
{
	if (who.spawnflags & PERK_SPAWNFLAG_NOLIGHT) {
		Light_None(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_REDLIGHT) {
		Light_Red(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_GREENLIGHT) {
		Light_Green(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_BLUELIGHT) {
		Light_Blue(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_ORANGELIGHT) {
		Light_Orange(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_PURPLELIGHT) {
		Light_Purple(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_CYANLIGHT) {
		Light_Cyan(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_PINKLIGHT) {
		Light_Pink(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_LIMELIGHT) {
		Light_Lime(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_YELLOWLIGHT) {
		Light_Yellow(who);
	}
}

//
// Perk_Jingle()
// The Think loop for Perk Jingles
//
void() Perk_Jingle =
{
	// If Revive is gone, don't bother to check anymore
	if (self.revivesoda >= 3)
		return;

	local float jinglewaittime;
	jinglewaittime = rint((random() * 30)) + 30;

	// Just try again later if the Power isn't Activated
	if ((self.requirespower == true && !isPowerOn) || self.ltime > time) {
		self.nextthink = time + jinglewaittime;
	} else {
		// 15% Chance to Play Jingle
		local float chance = random();
		if (chance <= 0.15) {
			sound(self, CHAN_AUTO, self.powerup_vo, 0.5, ATTN_IDLE);
			self.ltime = time + self.anim_weapon2_time;
			jinglewaittime += self.anim_weapon2_time;
		}

		self.nextthink = time + jinglewaittime;
	}
}

//
// setup_perk()
// Readies up misc. Perk aesthetics
//
void() setup_perk =
{
	local entity power = find(world, classname, "power_switch");

	// Check for Revive before Power
	if (self.classname == "perk_revive" && !coop && !deathmatch) {
		Turn_PerkLight_On(self);
	} else {
		// Check for Power
		if (power != world) {
			self.requirespower = true;
		} else {
			// There's no Power Switch, so turn the rest On.
			Turn_PerkLight_On(self);
		}
	}

	// Perk Jingle Timer
	if (self.powerup_vo) {
		self.think = Perk_Jingle;
		self.nextthink = time + rint((random() * 30)) + 30;
	}
}

//
// --------------------
// Perk Entity Spawn Functions
// --------------------
//

// Quick Revive
void() perk_revive =
{
	precache_sound ("sounds/pu/byebye.wav");
	precache_model ("models/sprites/lightning.spr");

	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quake_scale/quick_revive.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 500;
		self.cost2 = 1500;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 31;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | PERK_SPAWNFLAG_CYANLIGHT;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	precache_sound("sounds/weapons/papfire.wav");
	precache_extra(W_BIATCH);
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_revive";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 1;
	self.style = P_REVIVE;
};

// PhD Flopper
void() perk_flopper =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quake_scale/flopper.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 2000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 31;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | PERK_SPAWNFLAG_YELLOWLIGHT;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_flopper";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 6;
	self.style = P_FLOP;
};

// Jugger-Nog
void() perk_juggernog =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quake_scale/juggernog.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 2500;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 31;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | PERK_SPAWNFLAG_PINKLIGHT;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_juggernog";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 2;
	self.style = P_JUG;
};

// Stamin-Up
void() perk_staminup =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quake_scale/staminup.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 2000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 31;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | PERK_SPAWNFLAG_YELLOWLIGHT;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_staminup";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 5;
	self.style = P_STAMIN;
};

// Speed Cola
void() perk_speed =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quake_scale/speed_cola.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 3000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 31;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | PERK_SPAWNFLAG_LIMELIGHT;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_speed";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 3;
	self.style = P_SPEED;
};

// Double Tap Door Beer
void() perk_double =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quake_scale/double_tap.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 2000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 31;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | PERK_SPAWNFLAG_YELLOWLIGHT;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_double";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 4;
	self.style = P_DOUBLE;
};

// Deadshot Daiquiri
void() perk_deadshot =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quake_scale/deadshot.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 1500;
		self.cost2 = 1000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 31;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | PERK_SPAWNFLAG_YELLOWLIGHT;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_deadshot";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 7;
	self.style = P_DEAD;
};
// naievil -- older maps compatability
void() perk_dead = { perk_deadshot();}

// Mule Kick
void() perk_mule =
{
	//
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model) {
		self.model = "models/machines/quake_scale/mulekick.mdl";
	}

	// Perk Cost
	if (!self.cost) {
		self.cost = 4000;
	}

	// Player Trigger Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/perk_drink.wav";
	}

	// View Model
	if (!self.weapon2model) {
		self.weapon2model = "models/machines/v_perk.mdl";
	}

	// View Model Start Frame
	if (!self.weapon_animduration) {
		self.weapon_animduration = 0;
	}

	// View Model End Frame
	if (!self.weapon2_animduration) {
		self.weapon2_animduration = 31;
	}

	// Light Effect
	if (!self.spawnflags) {
		self.spawnflags = self.spawnflags | PERK_SPAWNFLAG_LIMELIGHT;
	}

	// Set up the Perk Entity
	self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_model(self.weapon2model);
	precache_sound(self.oldmodel);
	if (self.aistatus) { precache_sound(self.aistatus); }
	if (self.powerup_vo) { precache_sound(self.powerup_vo); }
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_mule";
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;

	// Drink Information
	self.sequence = 8;
	self.style = P_MULE;
}

//
// --------------------
// Power Switch
// --------------------
//

void()	turnpower1	=[	1,		turnpower2	] {self.frame = 1;};
void()	turnpower2	=[	2,		turnpower3	] {self.frame = 2;};
void()	turnpower3	=[	3,		turnpower4	] {self.frame = 3;};
void()	turnpower4	=[	4,		SUB_Null	] {self.frame = 4;};

//
// Turn_Lights()
// Activates Perk Light Effects and LightStyles
//
void() Turn_Lights =
{
	// Perk Lights
	entity tempe = findfloat(world, requirespower, 1);
	while (tempe)
	{
		Turn_PerkLight_On(tempe);
		tempe = findfloat (tempe, requirespower, 1);
	}

	// Light Styles
	tempe = find(world, classname, "light");
	while(tempe)
	{
		if (tempe.spawnflags & LIGHT_SPAWNFLAG_STARTOFF) {
			tempe.style = tempe.score;
			LS_Setup();
		}/* else if (tempe.spawnflags & LIGHT_SPAWNFLAG_STARTON) {
			tempe.style = 64;
			lightstyle(tempe.style, "a");
		}*/

		tempe = find(tempe, classname, "light");
	}
} 

//
// touch_power_Switch()
// Power Switch touch function; play Animation and do Power things..
//
void() touch_power_Switch =
{
	if (other.classname != "player" || other.downed)
		return;

	if (isPowerOn == true)
    	return;
	
	local entity tempe;
	local entity old_self;

	useprint (other, 10, 0, 0);
	if (other.button7 && !isPowerOn) {
		turnpower1();
		isPowerOn = true;
		sound(self, CHAN_ITEM, self.oldmodel, 1, ATTN_NONE);

		// Print message
		if (self.message) {
			entity players = find(world, classname, "player");
			while (players != world) {
				centerprint(players, strcat(self.message, "\n"));
				players = find(players, classname, "player");
			}
		}

		tempe = find (world, classname, "door_nzp");// trigger all paired doors
		while (tempe) {
			local entity starte;

			if (!tempe.targetname) {
				if (!tempe.cost) {
					old_self = self;
					self = tempe;
					starte = self;
					door_go_up ();
					tempe.classname = "door_open";
					tempe = find (tempe, classname, "door_nzp");// trigger all paired doors
					self = old_self;
				}
			}
			if (tempe.targetname) {
				old_self = self;
				self = tempe;
				remove(self);
				self = old_self;
				tempe = find (tempe, classname, "door_nzp");// trigger all paired doors
			}
		}
		Turn_Lights();
		SUB_UseTargets();
	}
}

void() power_switch =
{
	//
	// Set Default Stats for Compatibility
	//

    // Model
    if (!self.model)
        self.model = "models/machines/quake_scale/power_switch.mdl";

	// Sound
	if (!self.oldmodel)
		self.oldmodel = "sounds/machines/power.wav";

	// Skin
	if (!self.skin)
		self.skin = 0;

	self.solid = SOLID_TRIGGER;
	Precache_Set(self.model);
	precache_sound(self.oldmodel);
	setorigin (self, self.origin);
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "power_switch";
	self.touch = touch_power_Switch;

	isPowerOn = false;
}

//
// --------------------
// Pack-a-Punch
// --------------------
//

void removeinpap() {
	//remove(self);
};

//Self = floating gun
void velocity_reduce_output() {
    makevectors(self.owner.angles);
	self.velocity = [0,0,0];
	setorigin(self, self.owner.origin + v_forward*25);

    //start floating back into pap
    self.velocity = v_forward*-1.5;
}

//Self = floating gun
void velocity_reduce_output_in() {
	self.velocity = [0,0,0];
	setorigin(self, self.owner.origin);
}

void() reset_pap =
{
	self.weapon = 0;
	self.owner = 0;


	if (self.goaldummy) {
		remove(self.goaldummy);
		self.goaldummy = 0;
	}


	self.papState = 0;
}

//Self = pap
void PapSendOut() {
    makevectors(self.angles);
	setorigin(self.goaldummy, self.origin);
    self.goaldummy.velocity = v_forward*25;
    
    self.goaldummy.think = velocity_reduce_output;
    self.goaldummy.nextthink = time + 1;

	self.papState = 2;
	self.nextthink = time + 15;
    self.think = reset_pap;
}

void PapUpgrade(entity pap, entity buyer) {
   	entity tempe;
   	string modelname; 

	tempe = self;
	self = buyer;
	addmoney (self, -5000, 0);

	//////////WepModel IN Floating test////////    

	entity floatmodelin;

	modelname = GetWeaponModel(self.weapon, 1);

	floatmodelin = spawn ();


	//model goes in
	makevectors(pap.angles);
	setorigin (floatmodelin, pap.origin + v_forward*25);
	setmodel (floatmodelin, modelname);
	setsize (floatmodelin, '0 0 0', '0 0 0');
	floatmodelin.angles = pap.angles;
	floatmodelin.angles_y = 90 + pap.angles_y;

	floatmodelin.movetype = MOVETYPE_NOCLIP;
	floatmodelin.solid = SOLID_NOT;

	floatmodelin.owner = pap;
    floatmodelin.velocity = v_forward*-25;
    
    floatmodelin.think = velocity_reduce_output_in;
    floatmodelin.nextthink = time + 1;

	//model goes velocity_reduce_output
    pap.owner = self;
	pap.goaldummy = floatmodelin;
    pap.think = PapSendOut;
    pap.nextthink = time + 3.5;


	////////////////////////////////////////

	self.fire_delay = self.reload_delay = 4.5 + time;
	sound(self,CHAN_WEAPON,"sounds/machines/papsound.wav",1,ATTN_NORM);

	pap.weapon = self.weapon;

	self.weapon = self.secondaryweapon;
	self.currentammo = self.secondaryammo;
	self.currentmag = self.secondarymag;
	self.currentmag2 = self.secondarymag2;
	self.secondaryweapon = 0;
	self.secondaryammo = 0;
	self.secondarymag = 0;
	self.secondarymag2 = 0;

    self.isBuying = true;

	Set_W_Frame (0, 39, 0, 0, 0, W_TakeOut, "models/machines/v_pap.mdl", true, S_BOTH);
	self.weapon2model = "";
	UpdateV2model(self.weapon2model, 0);

#ifndef FTE

	self.Weapon_Name = "";

#endif // FTE

	self = tempe;

	self.papState = 1;
	
}

void touch_pap() {
  
	if (other.classname != "player" || other.downed) {
		return;
	}

	if (other.reload_delay > time || other.reload_delay2 > time || 
	other.fire_delay > time || other.fire_delay2 > time)
		return;
    
	if (self.requirespower == true && !isPowerOn) {
		useprint (other, 8, 0, 0);
		return;
	}
  
	if (!self.papState) {
		if (IsPapWeapon(other.weapon) == 1) {
			return;
		}
		useprint (other, 12, 5000, 5);
		if (other.points >= 5000 && other.button7 && other.weapon)
		{
			PapUpgrade(self, other);
		
		}
		else if (other.button7 && other.weapon && !other.semiuse) {
			other.semiuse = true;
			centerprint (other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
		}
	} else if (self.papState == 2) {
		useprint (other, 7, 0, 0);

		if (other.button7) {
			// Back-up current weapon into second slot, it's getting replaced.
			if (!other.secondaryweapon && other.weapon != EqualPapWeapon(self.weapon)) {
				other.secondaryweapon = other.weapon;
				other.secondarymag = other.currentmag;
				other.secondarymag2 = other.currentmag2;
				other.secondaryammo = other.currentammo;
			}

			other.weapon = EqualPapWeapon(self.weapon);
			other.currentammo = getWeaponAmmo(other.weapon);
			other.currentmag = getWeaponMag(other.weapon);

			if (IsDualWeapon(other.weapon)) {
				other.currentmag2 = other.currentmag;
			}

			entity tempe = self;
			self = other;

			SwitchWeapon(self.weapon);

			if (GetFrame(self.weapon, FIRST_TAKE_START) != 0)
				Weapon_PlayViewModelAnimation(ANIM_FIRST_TAKE, SUB_Null, 0);
			else
				Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, SUB_Null, 0);

#ifndef FTE

			self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
			self.Flash_Size = GetWeaponFlash_Size(self.weapon);
			self.Weapon_Name = GetWeaponName(self.weapon);
			self.weaponskin = GetWepSkin(self.weapon);

#endif // FTE

			self = tempe;

			// because PaP broke itself
			self.think = reset_pap;
			self.nextthink = time + 0.1;
		}
	}
}	

void() perk_pap = 
{ 
	entity tempe; 

	tempe = find (world, classname, "power_switch");// trigger all paired doors

	self.solid = SOLID_TRIGGER;

	if (tempe) {
		self.requirespower = true;
	} else {
		self.requirespower = false;
	}

	// Only cache the dual wield pap weapons if we have pap..
	precache_extra(W_BIATCH);
	precache_extra(W_SNUFF);

	precache_model ("models/machines/quake_scale/pap.mdl");
	precache_model ("models/machines/v_pap.mdl");
	precache_sound ("sounds/machines/papsound.wav");
	precache_sound("sounds/weapons/papfire.wav");
	setorigin(self, self.origin);
	setmodel (self, "models/machines/quake_scale/pap.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "perk_pap";
	self.touch = touch_pap;
}

// Sorta ugly function but whatever
void() perk_random =
{
	float i;
	float foundperk;
	
	// remove perks from our selection if they already exist
	// ugly ugly
	if ((find(world,classname,"perk_revive") && (self.spawnflags & 1))) {
		self.spawnflags -= self.spawnflags & 1;
	}
	if ((find(world,classname,"perk_juggernog") && (self.spawnflags & 2))) {
		self.spawnflags -= self.spawnflags & 2;
	}
	if ((find(world,classname,"perk_speed") && (self.spawnflags & 4))) {
		self.spawnflags -= self.spawnflags & 4;
	}
	if ((find(world,classname,"perk_double") && (self.spawnflags & 8))) {
		self.spawnflags -= self.spawnflags & 8;
	}
	if ((find(world,classname,"perk_flopper") && (self.spawnflags & 16))) {
		self.spawnflags -= self.spawnflags & 16;
	}
	if ((find(world,classname,"perk_staminup") && (self.spawnflags & 32))) {
		self.spawnflags -= self.spawnflags & 32;
	}
	if ((find(world,classname,"perk_deadshot") && (self.spawnflags & 64))) {
		self.spawnflags -= self.spawnflags & 64;
	}
	if ((find(world,classname,"perk_mule") && (self.spawnflags & 128))) {
		self.spawnflags -= self.spawnflags & 128;
	}

	// obj error because there are no possible perks for us to obtain
	if (self.spawnflags == 0) {
		objerror("No available Perks to choose from!");
	}

	foundperk = false;
	while (foundperk == false) {
		i = random();
		// Quick Revive
		if (i < (1/8) && (self.spawnflags & 1)) {
			if !(find(world, classname, "perk_revive")) {
				self.spawnflags = 8;
				perk_revive();
				foundperk = true;
			}
		}
		// Jugger-Nog 
		else if (i < (2/8) && (self.spawnflags & 2)) {
			if !(find(world, classname, "perk_juggernog")) {
				self.spawnflags = 2;
				perk_juggernog();
				foundperk = true;
			}
		}
		// Speed Cola
		else if (i < (3/8) && (self.spawnflags & 4)) {
			if !(find(world, classname, "perk_speed")) {
				self.spawnflags = 4;
				perk_speed();
				foundperk = true;
			}
		}
		// Double Tap
		else if (i < (4/8) && (self.spawnflags & 8)) {
			if !(find(world, classname, "perk_double")) {
				self.spawnflags = 16;
				perk_double();
				foundperk = true;
			}
		}
		// PhD Flopper
		else if (i < (5/8) && (self.spawnflags & 16)) {
			if !(find(world, classname, "perk_flopper")) {
				self.spawnflags = 16;
				perk_flopper();
				foundperk = true;
			}
		}
		// Stamin-Up
		else if (i < (6/8) && (self.spawnflags & 32)) {
			if !(find(world, classname, "perk_staminup")) {
				self.spawnflags = 16;
				perk_staminup();
				foundperk = true;
			}
		}
		// Deadshot Daiquiri
		else if (i < (7/8) && (self.spawnflags & 64)) {
			if (!find(world, classname, "perk_deadshot")) {
				self.spawnflags = 16;
				perk_deadshot();
				foundperk = true;
			}
		}
		// Mule Kick
		else if (i < 1 && (self.spawnflags & 128)) {
			if (!find(world, classname, "perk_mule")) {
				self.spawnflags = 4;
				perk_mule();
				foundperk = true;
			}
		}
	}
}

void() item_revive =
{
	perk_revive();
	self.origin_z += 8;
}

void() item_juggernog =
{
	perk_juggernog();
	self.origin_z += 8;
}

void() item_speed =
{
	perk_speed();
	self.origin_z += 8;
}

void() item_douple =
{
	perk_double();
	self.origin_z += 8;
}

void() item_flopper =
{
	perk_flopper();
	self.origin_z += 8;
}
