/*
	server/entities/powerups.qc

	Power-Up Spawn and Use Logic

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

#define MAX_POWERUPS		8
#define POWERUPS_PER_ROUND	4

#define PU_NUKE				0
#define PU_INSTAKILL		1
#define PU_DOUBLEPTS		2
#define PU_CARPENTER		3
#define PU_MAXAMMO			4

var struct powerup_struct
{
	float 	id;
	float 	occupied;
	float	flash_screen;
	string	model_path;
	string 	voiceover_path;
	void()	function;
	float() requirement_function;
} powerup_array[MAX_POWERUPS] = {};

float 	powerup_count;
float	powerup_index;

.float 	zombie_drop_id;

//
// PU_FreeEnt(ent)
// Marks a Power-Up entity as able to be used.
//
inline void(entity ent) PU_FreeEnt =
{
	setmodel(ent, "");
	ent.classname = "freePowerUpEntity";
	ent.hitcount = 0;
	ent.touch = SUB_Null;
	ent.think = SUB_Null;
	ent.frame = 0;
	ent.effects = 0;
};

//
// PU_GetFreeEnt()
// Returns a Power-Up entity to use.
//
entity() PU_GetFreeEnt =
{
	entity ent;
	ent = find(world, classname, "freePowerUpEntity");

	if (ent == world)
		error("PU_GetFreeEnt: No free Power-Up Entity. (Hacks?)\n");
	
	return ent;
};

//
// PU_AddToStruct(id, model_path, voiceover_path)
// Adds the Power-Up and info to the powerup struct
//
void(float id, float flash_screen, string model_path, string voiceover_path, void() function, float() requirement_function) 
PU_AddToStruct =
{
	if (id > MAX_POWERUPS - 1)
		return;

	// Precache Model and VO
	precache_model(model_path);
	precache_sound(voiceover_path);

	// Populate the Struct at Index
	powerup_array[powerup_count].id = id;
	powerup_array[powerup_count].occupied = true;
	powerup_array[powerup_count].flash_screen = flash_screen;
	powerup_array[powerup_count].model_path = model_path;
	powerup_array[powerup_count].voiceover_path = voiceover_path;
	powerup_array[powerup_count].function = function;
	powerup_array[powerup_count].requirement_function = requirement_function;

	// Increment Index
	powerup_count++;
};

//
// PU_CopyStruct(to, from)
// Copies a powerup_struct from to.
//
#define PU_CopyStruct(to, from)								\
	to.id = from.id; 										\
	to.occupied = from.occupied;							\
	to.model_path = from.model_path;						\
	to.voiceover_path = from.voiceover_path;				\
	to.function = from.function;							\
	to.requirement_function = from.requirement_function;	\

//
// PU_PopulateArray()
// Generates a Power-Up array with the Fisher-Yates shuffle
//
void() PU_PopulateArray =
{
	float 			amount = powerup_count;
	float 			i;
	powerup_struct 	t;

	while(amount) {
		i = floor(random() * amount--);

		// macro'd these to avoid hell with __inout :)
		PU_CopyStruct(t, powerup_array[amount])
		PU_CopyStruct(powerup_array[amount], powerup_array[i])
		PU_CopyStruct(powerup_array[i], t)
	}
};

//
// PU_GetNextPowerUp()
// Returns the next valid Power-Up, and refreshes array if needbe.
//
float() PU_GetNextPowerUp =
{
	float id;
	float found;
	id = -1;
	found = false;

	while(found == false) {
		// Refresh the Array if we're at the end
		if (powerup_index >= MAX_POWERUPS - 1) {
			PU_PopulateArray();
			powerup_index = 0;
		}

		// Grab a Power-Up
		powerup_struct pu = powerup_array[powerup_index];
		powerup_index++;

		// Found a valid Power-Up
		if (pu.occupied == true) {
			// Check if we meet the requirements
			if (pu.requirement_function() == true) {
				id = pu.id;
				found = true;
			}
		}
	}

	return id;
};

//
// PU_ShouldFlashScreen(id)
// Returns flash_screen from Power-Up struct.
//
float(float id) PU_ShouldFlashScreen =
{
	if (id == -1)
		return false;

	for(float i = 0; i < MAX_POWERUPS - 1; i++) {
		if (powerup_array[i].id == id)
			return powerup_array[i].flash_screen;
	}
	return false;
};

//
// PU_ModelPath(id)
// Returns model_path from Power-Up struct.
//
string(float id) PU_ModelPath =
{
	if (id == -1)
		return "";
	for(float i = 0; i < MAX_POWERUPS - 1; i++) {
		if (powerup_array[i].id == id)
			return powerup_array[i].model_path;
	}
	return "";
};

//
// PU_VoiceoverPath(id)
// Returns model_path from Power-Up struct.
//
string(float id) PU_VoiceoverPath =
{
	if (id == -1)
		return "";

	for(float i = 0; i < MAX_POWERUPS - 1; i++) {
		if (powerup_array[i].id == id)
			return powerup_array[i].voiceover_path;
	}
	return "";
};

//
// PU_LogicFunction(id)
// Returns function() from Power-Up struct.
//
void(float id) PU_LogicFunction =
{
	if (id == -1)
		return;

	for(float i = 0; i < MAX_POWERUPS - 1; i++) {
		if (powerup_array[i].id == id)
			powerup_array[i].function();
	}
};

//
// PU_NukeFinalize
// Wrap Nuke stuff up.
//
void() PU_NukeFinalize =
{
	entity players;

	// give 'The F Bomb'
	if (self.kills == 1) {
		GiveAchievement(4);
	}
	
	// award points
	players = find(world,classname,"player");
	while(players)
	{
		addmoney(players, 400*nuke_powerups_activated, 1);
		players = find(players,classname,"player");
	}

	nuke_powerup_active = false;
};

//
// PU_NukeExplosionThink()
// Think function for Nuke explosions.
//
void() PU_NukeExplosionThink =
{
	self.frame++;

	if (self.frame >= 5)
		PU_FreeEnt(self);

	self.nextthink = time + 0.10;
}

//
// PU_NukeExplode()
// Spawns an explosion sprite.
//
void(vector org) PU_NukeExplode =
{
	entity explosion = PU_GetFreeEnt();
	explosion.classname = "pu_nuke_explosion";
	setmodel(explosion, "models/sprites/explosion.spr");
	setorigin(explosion, org);
	explosion.think = PU_NukeExplosionThink;
	explosion.nextthink = time + 0.10;
}

//
// PU_NukeKill()
// Kills Targets when Nuke is active.
//
void() PU_NukeKill =
{
	// back up ourselves
	entity oldself;
	oldself = self;

	// switch to goaldummy, is goaldummy world?
	if (self.goaldummy == world) {
		PU_NukeFinalize();
		PU_FreeEnt(self);
		return;
	} else {
		self = self.goaldummy;
	}

	// play explosion effects
	PU_NukeExplode(self.origin + '0 0 13');

	// kill a target
	self.th_die();

	// override their death sound
	sound(self, CHAN_BODY, "sounds/pu/nuke.wav", 1, ATTN_NORM);

	// restore self
	self = oldself;

	// increment kills
	self.kills++;

	// find new target
	self.goaldummy = findfloat(self.goaldummy, iszomb, 1);

	self.nextthink = (rint((random() * 6) + 1)/10) + time; // random number from 0.1 to 0.7
};


//
// PU_Nuke()
// Nuke Power-Up Function
//
void() PU_Nuke =
{
	// if there's already one active, just increment the point multiplier
	if (nuke_powerup_active == true) {
		nuke_powerups_activated++;
		return;
	}

	// mark nuke as being active, to prevent zombie damage and spawning.
	nuke_powerup_active = true;
	nuke_powerup_spawndelay = time + 3;
	nuke_powerups_activated = 1;

	// create our watcher entity
	entity nuke_watcher;
	nuke_watcher = PU_GetFreeEnt();
	nuke_watcher.classname = "pu_nukewatcher";
	nuke_watcher.goaldummy = findfloat(world, iszomb, 1);

	nuke_watcher.think = PU_NukeKill;
	nuke_watcher.nextthink = (rint((random() * 6) + 1)/10) + time; // random number from 0.1 to 0.7
};

//
// PU_InstaKill()
// Insta-Kill Power-Up Fuction
//
void() PU_InstaKill =
{
	instakill_finished = time + 30;
	other.insta_icon = true;
};

//
// PU_DoublePoints()
// Double Points Power-Up Function
//
void() PU_DoublePoints =
{
	x2_finished = time + 30;
	other.x2_icon = true;
};

//
// PU_Carpenter()
// Carpenter Power-Up Function
//
void() PU_Carpenter =
{
	entity tempe;
	entity tempe2;
	tempe2 = self;

	tempe = find(world, classname, "window");

	// Repair Barricades
	while(tempe != world) {
		// Target non-full and board-able Barricades
		if (tempe.health < 6 && tempe.health != -10) {
			self = tempe;
			window_carpenter_1();
			self.health = 6;
			self = tempe2;
		}

		tempe = find(tempe, classname, "window");
	}

	tempe = find(world, classname, "player");

	// Reward Players with Points
	while(tempe) {
		addmoney(tempe, 200, 1);

		tempe = find(tempe, classname, "player");
	}
};

//
// PU_CarpenterRequirement()
// Requirements for Carpenter Power-Up.
//
float() PU_CarpenterRequirement =
{
	if (total_windows_down >= 5)
		return true;
	return false;
}

//
// PU_MaxAmmo()
// Max Ammo Power-Up Function
//
void() PU_MaxAmmo =
{
	entity tempe;
	
	tempe = find(world, classname, "player");

	while(tempe) {

		if (!tempe.downed) {
			// Fill Primary Weapon
			if (tempe.weapon) tempe.currentammo = getWeaponAmmo(tempe.weapon);
			// Fill Secondary Weapon
			if (tempe.secondaryweapon) tempe.secondaryammo = getWeaponAmmo(tempe.secondaryweapon);
			// Fill Third Weapon
			if (tempe.thirdweapon) tempe.thirdammo = getWeaponAmmo(tempe.thirdweapon);
			// Give Grenades
			tempe.primary_grenades = 4;
			// Give Betties
			if (tempe.grenades & 2) tempe.secondary_grenades = 2;
		} else {
			// Reset shots fired, fill 2 mags into reserve.
			tempe.teslacount = 0;
			tempe.currentammo = getWeaponMag(tempe.weapon) * 2;
		}	

		// MAX AMMO! text

#ifdef FTE

		ScrollText("MAX AMMO!", tempe);

#else

		nzp_maxammo();

#endif // FTE

		tempe = find(tempe, classname, "player");
	}
};

//
// PU_NullRequirement()
// Power-Up has no requirements. Always return true.
//
float() PU_NullRequirement =
{
	return true;
};

//
// PU_Init()
// Fill the Power-Up array for the first time and 
// define used Power-Ups
//
void() PU_Init =
{
	// Start with 0 Power-Ups accessible
	powerup_count = 0;

	// Set the Power-Up array IDs to empty
	for (float i = 0; i < MAX_POWERUPS; i++) {
		powerup_array[i].id = -1;
	}

	// Just add all of them for now
	PU_AddToStruct(PU_NUKE, 		true,	"models/pu/nuke!.mdl",		"sounds/pu/kaboom.wav",			PU_Nuke,			
					PU_NullRequirement		);
	PU_AddToStruct(PU_INSTAKILL, 	false,	"models/pu/instakill!.mdl",	"sounds/pu/insta_kill.wav", 	PU_InstaKill,	
					PU_NullRequirement		);
	PU_AddToStruct(PU_DOUBLEPTS, 	false,	"models/pu/x2!.mdl",		"sounds/pu/double_points.wav",	PU_DoublePoints,	
					PU_NullRequirement		);
	PU_AddToStruct(PU_CARPENTER,	false,	"models/pu/carpenter!.mdl",	"sounds/pu/carpenter.wav",		PU_Carpenter,	
					PU_CarpenterRequirement	);
	PU_AddToStruct(PU_MAXAMMO,		false,	"models/pu/maxammo!.mdl",	"sounds/pu/maxammo.wav", 		PU_MaxAmmo,		
					PU_NullRequirement		);

	// Nuke requires an extra Precache
	precache_sound("sounds/pu/nuke.wav");

	// Fill the array
	PU_PopulateArray();

	// Spawn all of our Power-Up spawn entities
	// We multiply by 4 to account for Power-Up operations like the Nuke.
	for (float i = 0; i < (POWERUPS_PER_ROUND * 4); i++) {
		entity tempe = spawn();
		tempe.classname = "freePowerUpEntity";
	}
};

//
// PU_Flash()
// Flash Power-Up model in and out
//
void() PU_Flash =
{
	// Toggle the Power-Up model on and off
	if (self.hitcount % 2) {
		// Disappear
		setmodel(self, "");
	}
	else {
		// Reappear
		setmodel(self, self.oldmodel);
	}

	if (self.hitcount < 15)
		self.nextthink = time + 0.5;
	else if (self.hitcount < 25)
		self.nextthink = time + 0.25;
	else
		self.nextthink = time + 0.1;

	self.hitcount++;

	// Too late, free the Power-Up
	if (self.hitcount >= 40) {
        Light_None(self);
		PU_FreeEnt(self);
		PU_FreeEnt(self.owner);
	}
};

//
// PU_PlayVO()
// Play the assigned Voiceover clip before freeing ourself.
//
void() PU_PlayVO =
{
	sound(self, CHAN_VOICE, self.powerup_vo, 1, ATTN_NONE);
	PU_FreeEnt(self);
};

//
// PU_Touch()
// Run assigned functions and prep for Deletion
//
void() PU_Touch =
{
	if (other.classname == "player")
	{
		// Acquire sound
		sound(self.owner, CHAN_VOICE, "sounds/pu/pickup.wav", 1, ATTN_NONE);

		// Prepare for VO and destruction
		self.think = PU_PlayVO;
		self.nextthink = time + 1;

		// Free the Power-Up sparkle, slight cleanup
		PU_FreeEnt(self.owner);
		setmodel(self, "");
		Light_None(self);
		self.touch = SUB_Null;

		// Flash the Screen if permitted
		if (PU_ShouldFlashScreen(self.walktype) == true)
			stuffcmd(other, "bf\n");

		// Run Power-Up function
		PU_LogicFunction(self.walktype);
	}
};

//
// PU_SparkleThink()
// Increment Frames for the Power-Up Sparkle.
//
void() PU_SparkleThink =
{
	float f;

	f = self.frame;
	while(f == self.frame) {
		// Pick a random frame from [0,4]
		f = floor(5 * random());
	}
	self.frame = f;
	
	self.think = PU_SparkleThink;
	self.nextthink = time + 0.1;
	
	if(self.calc_time <= time)
	{
		sound(self, CHAN_VOICE, "sounds/pu/powerup.wav", 0.6, ATTN_NORM);
		self.calc_time = time + 2.998;
	}
};

//
// Spawn_Powerup(where, type)
// Power-Up spawning function. Use type to force what spawns.
//
void(vector where, float type) Spawn_Powerup =
{
	entity 	powerup;
	entity	sparkle;

	// Set Up Power-Up
	powerup = PU_GetFreeEnt();

	powerup.origin = where;
	setorigin(powerup, powerup.origin);

	powerup.solid = SOLID_TRIGGER;
	powerup.classname = "item_powerup";

	setsize(powerup, VEC_HULL_MIN, VEC_HULL_MAX);
	powerup.movetype = MOVETYPE_NONE;

    Light_Green(powerup);

	// Set Up Sparkle Effect
	sparkle = PU_GetFreeEnt();
	sparkle.classname = "item_powerup_sparkle";

	powerup.owner = sparkle;

	sparkle.origin = where;
	setorigin(sparkle, sparkle.origin);

	setmodel(sparkle,"models/sprites/sprkle.spr");

	sparkle.think = PU_SparkleThink;
	sparkle.nextthink = time + 0.1;

	// Drop Sounds
	sound(sparkle, CHAN_VOICE, "sounds/pu/powerup.wav", 0.6, ATTN_NORM);
	sound(powerup, CHAN_AUTO, "sounds/pu/drop.wav", 1, ATTN_NONE);

	// Check if we were forcefully assigned an ID
	if (type != -1) {
		powerup.walktype = type;
	}
	// No, so let's grab one from the array.
	else {
		powerup.walktype = PU_GetNextPowerUp();
	}

	// Assign the Power-Up model and sound
	powerup.effects = EF_FULLBRIGHT;
	powerup.model = powerup.oldmodel = PU_ModelPath(powerup.walktype);
	setmodel(powerup, powerup.model);
	powerup.powerup_vo = PU_VoiceoverPath(powerup.walktype);

	// Time out
	powerup.think = PU_Flash;
	powerup.nextthink = time + 15;

	// Finally assign collision function
	powerup.touch = PU_Touch;

	totalpowerups++;
};

