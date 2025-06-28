/*
	server/entities/perk_a_cola.qc

	Perks-A-Cola Entity Logic

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

float backupWepSkin;
float sound_perk_delay; 
void(entity person) W_HideCrosshair;
void(entity client) Gamemode_DrinkPerk;

//
// --------------------
// Core Perk System
// --------------------
//

// Light Color Spawnflags
#define PERK_SPAWNFLAG_NOLIGHT 			1
#define PERK_SPAWNFLAG_REDLIGHT			2
#define PERK_SPAWNFLAG_GREENLIGHT		4
#define PERK_SPAWNFLAG_BLUELIGHT		8
#define PERK_SPAWNFLAG_ORANGELIGHT		16
#define PERK_SPAWNFLAG_PURPLELIGHT		32
#define PERK_SPAWNFLAG_CYANLIGHT		64
#define PERK_SPAWNFLAG_PINKLIGHT		128
#define PERK_SPAWNFLAG_LIMELIGHT		256
#define PERK_SPAWNFLAG_YELLOWLIGHT		512

// Double-Tap Damage Boost
#define PERK_SPAWNFLAG_DOUBLETAPV1		1024

#define PERK_SPAWNFLAG_ALLOWPRONE		2048
#define PERK_SPAWNFLAG_SILENTLEAVE		4096

#define PERK_JUGGERNOG_HEALTH_EASY		200
#define PERK_JUGGERNOG_HEALTH_NORMAL 	160
#define PERK_JUGGERNOG_HEALTH_HARD		100

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

	self.perks = self.perks | perk;

	// Instant re-gen, set health to Jugg health.
	if (perk & P_JUG) {
		switch(cvar("sv_difficulty")) {
			case 0: self.max_health = self.health = PERK_JUGGERNOG_HEALTH_NORMAL; break;
			case 1: self.max_health = self.health = PERK_JUGGERNOG_HEALTH_EASY; break;
			case 2: self.max_health = self.health = PERK_JUGGERNOG_HEALTH_HARD; break;
			default: break;
		}
	}

	if (self.perks == 255)
		GiveAchievement(6, self);

  	sound_perk_delay = time + 4.5;

	self.isBuying = false;
	self.weaponskin = backupWepSkin;
	self.perk_delay = self.fire_delay;

	Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, ReturnWeaponModel, 0);
}

//
// DrinkPerk()
// Gives Perk Bottle and jumps to GivePerk(p)
//
void DrinkPerk() {
	float perk = self.style;
	entity machine = self.usedent;

	// Set the Perk Skin based on the Perk sequence.
	// NOTE: If you add perks, you will either need to append
	// the MDL with a tool like QuArK or add an edge-case
	// after this instruction to have a valid skin.
	self.weaponskin = machine.sequence - 1;	

	self.maxspeed *= GetWeaponWalkSpeed(self.perks, self.weapon);
	
	self.knife_delay = self.reload_delay2 = self.fire_delay2 = self.fire_delay = self.reload_delay = 3 + time;	
	W_HideCrosshair(self);	
	Set_W_Frame (machine.weapon_animduration, machine.weapon2_animduration, 2.25, 0, PERK, GivePerk, machine.weapon2model, true, S_RIGHT, true);
	Sound_PlaySound(self, machine.oldmodel, SOUND_TYPE_WEAPON_OTHER, SOUND_PRIORITY_PLAYALWAYS);

	// Communicate to our engines that this client should display correct Double-Tap icon.
	if (self.style == P_DOUBLE) {
		nzp_setdoubletapver(self, self.has_doubletap_damage_buff);
	}

	Gamemode_DrinkPerk(self);
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
	spark.effects = EF_FULLBRIGHT;
	spark.think = SparkThink;
	spark.nextthink = time + 0.05;
	spark.ltime = time + time_alive;
}

//
// ReviveGoAway()
// Called when the max amount of solo revives have been used.
// Does a little animation and then 'teleports' away.
//
void() Perk_StopLeaveAnimation =
{
	self.velocity = 0;
	self.think = SUB_Null;
	self.nextthink = 0;

	setmodel(self, ""); // We don't want to remove Revive in the event of a Soft_Restart..
	SpawnSpark(self.origin, 0.65); // Spawn a Spark at the position
	self.origin = self.oldvelocity; // Restore old position
	Light_None(self); // Remove light effect
	SUB_UseTargets();

	Sound_PlaySound(self, "sounds/pu/drop.wav", SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS); // Play a fitting sound
}

void() Perk_MachineLeaveAnimation =
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
		Perk_StopLeaveAnimation();
	} else {
		self.nextthink = time + 0.05;
	}
}

void() Perk_MachineGoAwayForReal =
{
	makevectors(self.angles);
	self.movetype = MOVETYPE_NOCLIP;
	self.velocity = v_up * 7;

	Sound_PlaySound(world, "sounds/pu/byebye.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);

	// Do our silly little animation for 6 seconds
	self.ltime = time + 6;
	self.think = Perk_MachineLeaveAnimation;
	self.nextthink = time + 0.05;
}

void() Perk_MachineGoAway =
{
	// First start a timer, we want to wait until the player finishes drinking
	// before starting the animation.
	self.think = Perk_MachineGoAwayForReal;
	self.nextthink = time + 4;

	// Save our original position to restore on restart
	self.oldvelocity = self.origin;

	// Same with angle
	self.movement = self.angles;

	// Skip the animation if silent leave is on
	if (self.spawnflags & PERK_SPAWNFLAG_SILENTLEAVE)
		Perk_StopLeaveAnimation();
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
	if (other.classname != "player" || other.downed || other.isBuying == true || !PlayerIsLooking(other, self))
		return;

	// Typically not allowed to purchase Perk-A-Colas while prone.
	if (other.stance == PLAYER_STANCE_PRONE && !(self.spawnflags & PERK_SPAWNFLAG_ALLOWPRONE))
		return;

	// Perk Purchase Limit met
	if (Player_GetNumPerks(other) >= game_modifier_perk_purchase_limit)
		return;

	if (cvar("sv_magic") == 0) {
		useprint(other, 21, 0, 0);
		return;
	}

	if (self.classname == "perk_juggernog" && cvar("sv_difficulty") == 3) {
		useprint(other, 22, 0, 0);
		return;
	}

	if (self.classname == "perk_revive" && cvar("sv_difficulty") == 3 && player_count == 1) {
		useprint(other, 22, 0, 0);
		return;
	}
	  
	// Power's off! Nothing to do here.
	if (self.requirespower == true && !isPowerOn) {
		useprint(other, 8, 0, 0);
		return;
	}

	float perk_purchase_limit;

	if (player_count > 1)
		perk_purchase_limit = self.perk_purchase_limit_coop;
	else
		perk_purchase_limit = self.perk_purchase_limit_solo;

	// Back up weapon skin
	backupWepSkin = other.weaponskin;

	// Don't prompt if our hands or busy or we already have the perk
	if (!(other.perks & self.style) && other.fire_delay < time && self.perk_purchase_count < perk_purchase_limit) {
		float price;

		// Check if we're playing in Co-Op, adjust price if so.
		if (player_count > 1)
			price = floor(self.cost2 * game_modifier_cost_multiplier);
		// Nope, use normal/solo cost.
		else
			price = floor(self.cost * game_modifier_cost_multiplier);

		// sequence = perk ID in client
		Player_UseprintWithWait(other, self, 9, price, self.sequence);

		if (other.points >= price && Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
			Player_RemoveScore(other, price);

			// Play the sound of the bottle "vending"
			Sound_PlaySound(self, "sounds/machines/vend.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);

			// Play Perk Sting if we can and it exists
			if (self.aistatus && self.ltime < time) {
				Sound_PlaySound(self, self.aistatus, SOUND_TYPE_ENV_MUSIC, SOUND_PRIORITY_PLAYALWAYS);
				self.ltime = time + self.anim_weapon_time;
			}

			// Pass along the Perk information to the Player to avoid complications later on, then Drink!
			other.style = self.style;

			// Double-Tap 2.0 flag set here
			if (self.classname == "perk_double") {
				other.has_doubletap_damage_buff = !(self.spawnflags & PERK_SPAWNFLAG_DOUBLETAPV1);
			}

			entity tempe = self; // Set machine to tempe
			self = other; // Set self to client
			self.usedent = tempe; // Set usedent to machine
			self.isBuying = true; // To avoid canceling the animation from triggering
			self.sprinting = false;
			self.zoom = 0;
			Weapon_PlayViewModelAnimation(ANIM_PUT_AWAY, DrinkPerk, getWeaponDelay(self.weapon, PUTOUT));
			other = self; // Set other to client
			self = tempe; // Set self to machine

			// If the player is Prone, for them to Crouch
			if (other.stance == PLAYER_STANCE_PRONE)
				Player_SetStance(other, PLAYER_STANCE_CROUCH, true);

			// Increment usage count
			self.perk_purchase_count++;

			// Time to disappear!
			if (self.perk_purchase_count >= perk_purchase_limit)
				Perk_MachineGoAway();

			other.semi_actions |= SEMIACTION_USE;
		} else if (Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
			// We tried to use, but we don't have the cash..
			centerprint(other, STR_NOTENOUGHPOINTS);
			Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			other.semi_actions |= SEMIACTION_USE;
		}
	}
}

//
// Turn_PerkLight_On(who)
// Turns on the Perk Lights
//
void(entity who) Turn_PerkLight_On =
{
	if (cvar("sv_magic") == 0)
		return;

	if (who.classname == "perk_pap")
		return;
	
	if (who.spawnflags & PERK_SPAWNFLAG_NOLIGHT) {
		Light_None(who);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_REDLIGHT) {
		Light_Red(who, true);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_GREENLIGHT) {
		Light_Green(who, true);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_BLUELIGHT) {
		Light_Blue(who, true);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_ORANGELIGHT) {
		Light_Orange(who, true);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_PURPLELIGHT) {
		Light_Purple(who, true);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_CYANLIGHT) {
		Light_Cyan(who, true);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_PINKLIGHT) {
		Light_Pink(who, true);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_LIMELIGHT) {
		Light_Lime(who, true);
	}
	if (who.spawnflags & PERK_SPAWNFLAG_YELLOWLIGHT) {
		Light_Yellow(who, true);
	}
}

//
// Perk_Jingle()
// The Think loop for Perk Jingles
//
void() Perk_Jingle =
{
	float perk_purchase_limit;

	if (player_count > 1)
		perk_purchase_limit = self.perk_purchase_limit_coop;
	else
		perk_purchase_limit = self.perk_purchase_limit_solo;

	// If the Vending Machine is gone, don't bother to check anymore
	if (self.perk_purchase_count >= perk_purchase_limit)
		return;

	local float jinglewaittime;
	jinglewaittime = rint((random() * 30)) + 30;

	// Just try again later if the Power isn't Activated
	if ((self.requirespower == true && !isPowerOn) || self.ltime > time) {
		self.nextthink = time + jinglewaittime;
	} else {
		// 15% Chance to Play Jingle
		float chance = random();
		if (chance <= 0.15) {
			Sound_PlaySound(self, self.powerup_vo, SOUND_TYPE_ENV_MUSIC, SOUND_PRIORITY_PLAYALWAYS);
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
	if (cvar("sv_magic") == 0)
		return;

	entity power = find(world, classname, "power_switch");

	// Check for Power
	if (power != world && !isPowerOn) {
		// Power Switch is present -- but does this machine have an override?
		if ((self.perk_requires_power_coop < 0 && player_count > 1) || 
		(self.perk_requires_power_solo < 0 && player_count == 1))
			self.requirespower = false;
		else
			self.requirespower = true;
	} else {
		self.requirespower = false;
	}

	// Turn on the Lights!
	if (!self.requirespower)
		Turn_PerkLight_On(self);

	// Perk Jingle Timer
	if (self.powerup_vo != "") {
		self.think = Perk_Jingle;
		self.nextthink = time + rint((random() * 30)) + 30;
	}
}

//
// --------------------
// Perk Entity Spawn Functions
// --------------------
//

//
// Perk_InitMachine()
// Wrapper to provide clean-up for
// Perk-A-Cola Spawn functions.
//
void(string perk_classname,
string default_model, float cost_solo, 
float cost_coop, float light_spawnflag,
float purchase_limit_solo, float purchase_limit_coop,
float require_power_solo, float require_power_coop,
float drink_skin, float perk_id) Perk_InitMachine =
{
	//
	// Set Default Stats for Compatibility
	//

	// Model
	if (!self.model)
		self.model = default_model;

	// Perk Cost (Solo)
	if (!self.cost)
		self.cost = cost_solo;

	// Perk Cost (Co-Op)
	if (!self.cost2)
		self.cost2 = cost_coop;

	// Player Trigger Sound
	if (!self.oldmodel)
		self.oldmodel = "sounds/machines/perk_drink.wav";

	// View Model
	if (!self.weapon2model)
		self.weapon2model = "models/machines/v_perk.mdl";

	// View Model Start Frame
	if (!self.weapon_animduration)
		self.weapon_animduration = 0;

	// View Model End Frame
	if (!self.weapon2_animduration)
		self.weapon2_animduration = 31;

	// Light Effect
	if (!self.spawnflags)
		self.spawnflags = self.spawnflags | light_spawnflag;

	// Perk Purchase Limit (Solo)
	if (!self.perk_purchase_limit_solo)
		self.perk_purchase_limit_solo = purchase_limit_solo;

	// Perk Purchase Limit (Co-Op)
	if (!self.perk_purchase_limit_coop)
		self.perk_purchase_limit_coop = purchase_limit_coop;

	// Perk Requires Power (Solo)
	if (!self.perk_requires_power_solo)
		self.perk_requires_power_solo = require_power_solo;

	// Perk Requires Power (Co-Op)
	if (!self.perk_requires_power_coop)
		self.perk_requires_power_coop = require_power_coop;

	// Precache if spawned naturally by the world.
	if (time < 2) {
		precache_model(self.model);
		precache_model(self.weapon2model);

		precache_sound(self.oldmodel);
		precache_sound("sounds/machines/vend.wav");
		if (self.aistatus != "") { precache_sound(self.aistatus); }
		if (self.powerup_vo != "") { precache_sound(self.powerup_vo); }
	}

	// General Machine Setup
	self.solid = SOLID_TRIGGER;
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.oldorigin = self.origin;
	self.finalangle = self.angles;
	self.door_model_name = self.model;
	self.classname = perk_classname;
	self.touch = touch_perk;
	self.think = setup_perk;
	self.nextthink = time + 0.1;
	self.sequence = drink_skin;
	self.style = perk_id;
};

// Quick Revive
void() perk_revive =
{
	Perk_InitMachine("perk_revive", PERK_QUICKREVIVE_DEFAULT_MODEL, 500, 1500,
	PERK_SPAWNFLAG_CYANLIGHT, 3, 1000, -1, true, 1, P_REVIVE);
};

// PhD Flopper
void() perk_flopper =
{
	Perk_InitMachine("perk_flopper", PERK_PHDFLOPPER_DEFAULT_MODEL, 2000, 2000,
	PERK_SPAWNFLAG_YELLOWLIGHT, 1000, 1000, true, true, 6, P_FLOP);
};

// Jugger-Nog
void() perk_juggernog =
{
	Perk_InitMachine("perk_juggernog", PERK_JUGGERNOG_DEFAULT_MODEL, 2500, 2500,
	PERK_SPAWNFLAG_PINKLIGHT, 1000, 1000, true, true, 2, P_JUG);
};

// Stamin-Up
void() perk_staminup =
{
	Perk_InitMachine("perk_staminup", PERK_STAMINUP_DEFAULT_MODEL, 2000, 2000,
	PERK_SPAWNFLAG_YELLOWLIGHT, 1000, 1000, true, true, 5, P_STAMIN);
};

// Speed Cola
void() perk_speed =
{
	Perk_InitMachine("perk_speed", PERK_SPEEDCOLA_DEFAULT_MODEL, 3000, 3000,
	PERK_SPAWNFLAG_LIMELIGHT, 1000, 1000, true, true, 3, P_SPEED);
};

// Double Tap Door Beer
void() perk_double =
{
	Perk_InitMachine("perk_double", PERK_DOUBLETAP_DEFAULT_MODEL, 2000, 2000,
	PERK_SPAWNFLAG_YELLOWLIGHT, 1000, 1000, true, true, 4, P_DOUBLE);
};

// Deadshot Daiquiri
void() perk_deadshot =
{
	Perk_InitMachine("perk_deadshot", PERK_DEADSHOT_DEFAULT_MODEL, 1500, 1500,
	PERK_SPAWNFLAG_YELLOWLIGHT, 1000, 1000, true, true, 7, P_DEAD);
};
// naievil -- older maps compatability
void() perk_dead = { perk_deadshot();}

// Mule Kick
void() perk_mule =
{
	Perk_InitMachine("perk_mule", PERK_MULEKICK_DEFAULT_MODEL, 4000, 4000,
	PERK_SPAWNFLAG_LIMELIGHT, 1000, 1000, true, true, 8, P_MULE);
}

//
// Random Perk-A-Cola
//

#define SPAWNFLAG_PERKRANDOM_QUICKREVIVE 	1
#define SPAWNFLAG_PERKRANDOM_JUGGERNOG		2
#define SPAWNFLAG_PERKRANDOM_SPEEDCOLA		4
#define SPAWNFLAG_PERKRANDOM_DOUBLETAP		8
#define SPAWNFLAG_PERKRANDOM_PHDFLOPPER		16
#define SPAWNFLAG_PERKRANDOM_STAMINUP		32
#define SPAWNFLAG_PERKRANDOM_DEADSHOT		64
#define SPAWNFLAG_PERKRANDOM_MULEKICK		128

float perk_random_placed; // bitfield to track what perk_random ents have placed.

//
// Perk_RandomAssign(perk_classname, spawnfunc)
// Transforms perk_random into the designated entity passed.
// If the entity already exists in the world, it will
// instead teleport it at the desired location.
//
void(string perk_classname, void() spawnfunc) Perk_RandomAssign =
{
	entity machine = find(world, classname, perk_classname);

	// Machine does not already exist, so spawn a new one
	// with default parameters.
	if (!machine) {
		self.spawnflags = 0; // reset spawnflags, for default lights.
		spawnfunc();
	}
	// The machine is in the world, so move it here instead.
	else {
		setorigin(machine, self.origin);
		machine.angles = self.angles;

		// .oldorigin is used by resets or updates, we do not
		// want to teleport the machine back to its idle state
		// whenever a client joins.
		machine.oldorigin = machine.origin;
	}
}

//
// Perk_RandomDecide()
// Called by perk_random, will conduct the process of
// deciding what Perk-A-Cola machine it will become.
//
void() Perk_RandomDecide =
{
	float i;

	// If a perk_random entity has already placed down a Perk-A-Cola
	// given it's respective spawnflag, remove it from the ent selection.
	for(i = 1; i < 256; i *= 2) {
		if ((perk_random_placed & i) && (self.spawnflags & i))
			self.spawnflags -= self.spawnflags & i;
	}

	// Choose which of the eight machines we want to become, if permitted.
	float num_attempts;
	for(num_attempts = 64; num_attempts > 0; num_attempts--) {
		i = random();
		// Quick Revive
		if (i < (1/8) && (self.spawnflags & SPAWNFLAG_PERKRANDOM_QUICKREVIVE)) {
			Perk_RandomAssign("perk_revive", perk_revive);
			perk_random_placed += SPAWNFLAG_PERKRANDOM_QUICKREVIVE;
			break;
		}
		// Jugger-Nog 
		else if (i < (2/8) && (self.spawnflags & SPAWNFLAG_PERKRANDOM_JUGGERNOG)) {
			Perk_RandomAssign("perk_juggernog", perk_juggernog);
			perk_random_placed += SPAWNFLAG_PERKRANDOM_JUGGERNOG;
			break;
		}
		// Speed Cola
		else if (i < (3/8) && (self.spawnflags & SPAWNFLAG_PERKRANDOM_SPEEDCOLA)) {
			Perk_RandomAssign("perk_speed", perk_speed);
			perk_random_placed += SPAWNFLAG_PERKRANDOM_SPEEDCOLA;
			break;
		}
		// Double Tap
		else if (i < (4/8) && (self.spawnflags & SPAWNFLAG_PERKRANDOM_DOUBLETAP)) {
			Perk_RandomAssign("perk_double", perk_double);
			perk_random_placed += SPAWNFLAG_PERKRANDOM_DOUBLETAP;
			break;
		}
		// PhD Flopper
		else if (i < (5/8) && (self.spawnflags & SPAWNFLAG_PERKRANDOM_PHDFLOPPER)) {
			Perk_RandomAssign("perk_flopper", perk_flopper);
			perk_random_placed += SPAWNFLAG_PERKRANDOM_PHDFLOPPER;
			break;
		}
		// Stamin-Up
		else if (i < (6/8) && (self.spawnflags & SPAWNFLAG_PERKRANDOM_STAMINUP)) {
			Perk_RandomAssign("perk_staminup", perk_staminup);
			perk_random_placed += SPAWNFLAG_PERKRANDOM_STAMINUP;
			break;
		}
		// Deadshot Daiquiri
		else if (i < (7/8) && (self.spawnflags & SPAWNFLAG_PERKRANDOM_DEADSHOT)) {
			Perk_RandomAssign("perk_deadshot", perk_deadshot);
			perk_random_placed += SPAWNFLAG_PERKRANDOM_DEADSHOT;
			break;
		}
		// Mule Kick
		else if (i < 1 && (self.spawnflags & SPAWNFLAG_PERKRANDOM_MULEKICK)) {
			Perk_RandomAssign("perk_mule", perk_mule);
			perk_random_placed += SPAWNFLAG_PERKRANDOM_MULEKICK;
			break;
		}
	}

	if (!num_attempts)
		objerror("perk_random: Failed 64 times to pick a Perk-A-Cola. Bailing!\n");
};

void() Perk_RandomPrecaches =
{
	if (self.spawnflags & SPAWNFLAG_PERKRANDOM_QUICKREVIVE)
		precache_model(PERK_QUICKREVIVE_DEFAULT_MODEL);
	if (self.spawnflags & SPAWNFLAG_PERKRANDOM_JUGGERNOG)
		precache_model(PERK_JUGGERNOG_DEFAULT_MODEL);
	if (self.spawnflags & SPAWNFLAG_PERKRANDOM_SPEEDCOLA)
		precache_model(PERK_SPEEDCOLA_DEFAULT_MODEL);
	if (self.spawnflags & SPAWNFLAG_PERKRANDOM_DOUBLETAP)
		precache_model(PERK_DOUBLETAP_DEFAULT_MODEL);
	if (self.spawnflags & SPAWNFLAG_PERKRANDOM_PHDFLOPPER)
		precache_model(PERK_PHDFLOPPER_DEFAULT_MODEL);
	if (self.spawnflags & SPAWNFLAG_PERKRANDOM_STAMINUP)
		precache_model(PERK_STAMINUP_DEFAULT_MODEL);
	if (self.spawnflags & SPAWNFLAG_PERKRANDOM_DEADSHOT)
		precache_model(PERK_DEADSHOT_DEFAULT_MODEL);
	if (self.spawnflags & SPAWNFLAG_PERKRANDOM_MULEKICK)
		precache_model(PERK_MULEKICK_DEFAULT_MODEL);
};

void() perk_random =
{
	// Quit out because there are no Perk-A-Cola machines for us to choose between.
	if (!self.spawnflags) {
		objerror("No available Perks to choose from!");
	}

	// Perform default model precaches for 
	// Perk-A-Colas in our spawnflags, in the event
	// they are not already in the world (legacy mode).
	Perk_RandomPrecaches();

	// Link this entity so that moving existing Perk-A-Cola machines
	// receive a viable teleport location.
	setorigin(self, self.origin);

	// We can't transform right away, because we need to assert that
	// all other entities are loaded in the world.
	self.think = Perk_RandomDecide;
	self.nextthink = time + 3;
};
