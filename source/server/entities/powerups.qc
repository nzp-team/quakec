/*
	server/entities/powerups.qc

	Power-Up Spawn and Use Logic

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

#define MAX_POWERUPS		8
#define POWERUPS_PER_ROUND	4

#define PU_NUKE				0
#define PU_INSTAKILL		1
#define PU_DOUBLEPTS		2
#define PU_CARPENTER		3
#define PU_MAXAMMO			4
#define PU_FREEPERK			5
#define PU_UPGRADEWEAPON	6

#define PU_OFFSET_QK		'0 0 12'
#define PU_OFFSET_HL		'0 0 14'

#define PU_BBOX_MINS		'-2 -2 -16'
#define PU_BBOX_MAXS		'2 2 16'

var struct powerup_struct
{
	float 	id;
	float 	occupied;
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
	ent.scale = 1;
	ent.effects = 0;

#ifdef FTE

	ent.SendEntity = __NULL__;
	ent.SendFlags = 0;

#endif // FTE

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
// PU_ResolveVOPath(file)
// Helper for gamemode-specific Power-Up VO
// paths.
//
string(string file) PU_ResolveVOPath =
{
	string path = "";

	switch(cvar("sv_gamemode")) {
		case GAMEMODE_GUNGAME: path = strcat("sounds/modes/gungame/", file); break;
		case GAMEMODE_HARDCORE: path = strcat("sounds/modes/hardcore/", file); break;
		case GAMEMODE_STICKSNSTONES: path = strcat("sounds/modes/sticks/", file); break;
		case GAMEMODE_WILDWEST: path = strcat("sounds/modes/wildwest/", file); break;
		default: path = strcat("sounds/pu/", file); break;
	}

	return path;
};

//
// PU_AddToStruct(id, model_path, voiceover_path)
// Adds the Power-Up and info to the powerup struct
//
void(float id, string model_path, string voiceover_path, void() function, float() requirement_function) 
PU_AddToStruct =
{
	if (id > MAX_POWERUPS - 1)
		return;

	string voiceover_path_full = PU_ResolveVOPath(voiceover_path);

	// Precache Model and VO
	precache_model(model_path);
	precache_sound(voiceover_path_full);

	// Populate the Struct at Index
	powerup_array[powerup_count].id = id;
	powerup_array[powerup_count].occupied = true;
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
	if (game_modifier_can_earn_misc_score == true) {
		players = find(world,classname,"player");
		while(players)
		{
			Player_AddScore(players, 400 * nuke_powerups_activated, true);
			players = find(players,classname,"player");
		}
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

	// set them on fire
	self.onfire = true;

	// kill a target
	self.th_die();

	// override their death sound
	Sound_PlaySound(self, "sounds/pu/nuke.wav", SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);

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
	// Flash the screen white
	nzp_screenflash(world, SCREENFLASH_COLOR_WHITE, 1, SCREENFLASH_FADE_INANDOUT);

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
// PU_CarpenterFinalize
// Remove the Carpenter Watcher and
// rewards Players with Score.
//
void() PU_CarpenterFinalize =
{
	entity players = find(world, classname, "player");

	// Reward Players with Points
	if (game_modifier_can_earn_misc_score) {
		while(players) {
			Player_AddScore(players, 200, true);

			players = find(players, classname, "player");
		}
	}

	entity windows = find(world, classname, "window");

	// Reset all windows
	while(windows) {
		windows.is_spectator = 0;
		windows.box1owner = world;
		windows.usedent = world;
		windows.owner = world;
		windows.ads_release = 0;

		windows = find(windows, classname, "window");
	}

	carp_powerup_active = false;

	// Free ourselves
	PU_FreeEnt(self);
};

//
// PU_CarpenterFindWindow
// Finds a Barricade elligible for Repair
//
entity() PU_CarpenterFindWindow =
{
	entity windows = find(world, classname, "window");

	while(windows != world) {
		// Window needs repaired and is repairable
		if (windows.health < 6 && windows.health != -10 && !windows.is_spectator
		&& !windows.ads_release)
			return windows;

		windows = find(windows, classname, "window");
	}

	// No Windows are elligible, return world.
	return world;
};

//
// PU_CarpenterRepair()
// Attempts to Repair a Barricade
//
void() PU_CarpenterRepair =
{
	// Find a new Barricade to Repair
	if (self.goaldummy == world || self.goaldummy.is_spectator == 0) {

		if (self.goaldummy != world)
			self.goaldummy.owner = world;

		self.goaldummy = PU_CarpenterFindWindow();
		self.kills = false;

		// Didn't find one, so end the Carpenter sequence.
		if (self.goaldummy == world) {
			self.think = PU_CarpenterFinalize;
			self.nextthink = time + 0.1;
			return;
		}

		// Mark the window as being Repaired
		self.goaldummy.is_spectator = 1;
		self.goaldummy.ads_release = 1;
		self.goaldummy.owner = self;
	}
	// Repair our current Barricade
	else if (!self.kills) {
		// Trigger the animation
		entity tempe = self;
		self = self.goaldummy;
		switch(self.health) {
			case 5: window_carpenter_11(); break;
			case 4: window_carpenter_9(); break;
			case 3: window_carpenter_7(); break;
			case 2: window_carpenter_5(); break;
			case 1: window_carpenter_3(); break;
			default: window_carpenter_1(); break;
		}
		self.health = 6;
		self = tempe;

		// We're actively building
		self.kills = true;
		self.ltime = time + 2.1;
	} else {
		if (self.ltime < time) {
			self.goaldummy.frame = 88;
			self.goaldummy.is_spectator = 0;
			self.goaldummy.health = 6;
		}
	}

	self.nextthink = time + 0.05;
};

//
// PU_Carpenter()
// Carpenter Power-Up Function
//
void() PU_Carpenter =
{
	// create our watcher entity
	entity carp_watcher;
	carp_watcher = PU_GetFreeEnt();
	carp_watcher.classname = "pu_carpwatcher";

	carp_watcher.think = PU_CarpenterRepair;
	carp_watcher.nextthink = time + 0.05;

	carp_powerup_active = true;
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
// PU_MaxAmmoRequirement()
// Requirements for Max Ammo Power-Up.
//
float() PU_MaxAmmoRequirement =
{
	return game_modifier_powerup_max_ammo;
}

//
// PU_FreePerkRequirement()
// Requirements for Free Perk Power-Up.
//
float() PU_FreePerkRequirement =
{
	return game_modifier_powerup_free_perk;
}

//
// PU_UpgradeWeaponRequirement()
// Requirements for Weapon Upgrade Power-Up
//
float() PU_UpgradeWeaponRequirement =
{
	return game_modifier_powerup_weapon_upgrade;
}

//
// PU_MaxAmmo()
// Max Ammo Power-Up Function
//
void() PU_MaxAmmo =
{
	entity players;
	entity tempe;
	
	players = find(world, classname, "player");

	while(players) {

		if (!players.downed) {
			// Fill all weapons
			for (float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
				players.weapons[i].weapon_reserve = getWeaponAmmo(players.weapons[i].weapon_id);
			}
			// Give Grenades
			players.primary_grenades = 4;
			// Give Betties
			if (players.grenades & 2) players.secondary_grenades = 2;
		} else {
			// Reset shots fired, fill 2 mags into reserve.
			players.teslacount = 0;
			players.weapons[0].weapon_reserve = getWeaponMag(players.weapon) * 2;
		}	

		// Force the player to reload if their mag is empty
		if (players.weapons[0].weapon_magazine == 0 || (IsDualWeapon(players.weapon) && players.weapons[0].weapon_magazine_left == 0)) {
			tempe = self;
			self = players;
			W_Reload(S_BOTH);
			self = tempe;
		}

		// MAX AMMO! text
		nzp_maxammo();

		players = find(players, classname, "player");
	}
};

//
// PU_FreePerk()
// Free Perk Power-Up Function
//
void() PU_FreePerk =
{
	entity players;
	entity tempe;

	self.oldmodel = "sounds/machines/perk_drink.wav";
	self.weapon2model = "models/machines/v_perk.mdl";
	self.weapon_animduration = 0;
	self.weapon2_animduration = 31;
	
	players = find(world, classname, "player");

	while(players) {

		if (players.downed || players.perks >= 255) {
			players = find(players, classname, "player");
			continue;
		}

		float perk_to_give = 0;
		float found_perk_for_player = false;

		while(!found_perk_for_player) {
			float perk_rand = random();

			if (perk_rand < (1/8) && !(players.perks & P_REVIVE)) { self.sequence = 1; perk_to_give = P_REVIVE; }
			else if (perk_rand < (2/8) && !(players.perks & P_JUG)) { self.sequence = 2; perk_to_give = P_JUG; }
			else if (perk_rand < (3/8) && !(players.perks & P_SPEED)) { self.sequence = 3; perk_to_give = P_SPEED; }
			else if (perk_rand < (4/8) && !(players.perks & P_DOUBLE)) { self.sequence = 4; perk_to_give = P_DOUBLE; }
			else if (perk_rand < (5/8) && !(players.perks & P_STAMIN)) { self.sequence = 5; perk_to_give = P_STAMIN; }
			else if (perk_rand < (6/8) && !(players.perks & P_FLOP)) { self.sequence = 6; perk_to_give = P_FLOP; }
			else if (perk_rand < (7/8) && !(players.perks & P_DEAD)) { self.sequence = 7; perk_to_give = P_DEAD; }
			else if (!(players.perks & P_MULE) && cvar("sv_gamemode") != 2) { self.sequence = 8; perk_to_give = P_MULE; }

			if (perk_to_give != 0)
				found_perk_for_player = true;
		}

		players.style = perk_to_give;
		players.usedent = self;

		tempe = self;
		self = players;
		DrinkPerk();
		self = tempe;

		players = find(players, classname, "player");
	}
};

//
// PU_WeaponUpgrade()
// Weapon Upgrade Power-Up Function
//
void() PU_WeaponUpgrade =
{
	entity players = find(world, classname, "player");
	while(players != world) {
		float current_weapon = players.weapons[0].weapon_id;

		// Already upgraded, don't bother.
		if (EqualPapWeapon(current_weapon) == current_weapon) {
			players = find(players, classname, "player");
			continue;
		}

		entity old_self = self;
		self = players;
		W_SprintStop();
        W_AimOut();
		Weapon_AssignWeapon(0, EqualPapWeapon(current_weapon), 0, 0);
		Weapon_SwapWeapons(true);
		self = old_self;

		players = find(players, classname, "player");
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
	PU_AddToStruct(PU_NUKE, 		"models/pu/nuke!.mdl",			"kaboom.wav",			PU_Nuke,			
					PU_NullRequirement			);
	PU_AddToStruct(PU_INSTAKILL, 	"models/pu/instakill!.mdl",		"insta_kill.wav", 		PU_InstaKill,	
					PU_NullRequirement			);
	PU_AddToStruct(PU_DOUBLEPTS, 	"models/pu/x2!.mdl",			"double_points.wav",	PU_DoublePoints,	
					PU_NullRequirement			);
	PU_AddToStruct(PU_CARPENTER,	"models/pu/carpenter!.mdl",		"carpenter.wav",		PU_Carpenter,	
					PU_CarpenterRequirement		);
	PU_AddToStruct(PU_MAXAMMO,		"models/pu/maxammo!.mdl",		"maxammo.wav", 			PU_MaxAmmo,		
					PU_MaxAmmoRequirement		);
	PU_AddToStruct(PU_FREEPERK, 	"models/pu/perkbottle!.mdl",	"free_perk.wav", 		PU_FreePerk,
					PU_FreePerkRequirement		);
	PU_AddToStruct(PU_UPGRADEWEAPON,"models/pu/pack!.mdl",			"upgrade.wav",			PU_WeaponUpgrade,
					PU_UpgradeWeaponRequirement	);

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

#ifdef FTE

	// Update the drawing of the Power-Up in CSQC to
	// register the flash.
	self.SendFlags = 1;

#endif // FTE

	// Re-set the size after relink.
	setsize(self, PU_BBOX_MINS, PU_BBOX_MAXS);

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
	string sound_path = PU_ResolveVOPath(self.powerup_vo);
	Sound_PlaySound(world, sound_path, SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_ALLOWSKIP);
	PU_FreeEnt(self);
};

//
// PU_SparkleShrink()
// Called on Power-Up contact, makes the Sparkle shrink
// until eventually disappearing.
//
void() PU_SparkleShrink =
{

#ifdef FTE

	self.scale -= frametime;

#else

	self.scale -= frametime*2.25;

#endif // FTE

	if (self.scale <= 0.02)
		PU_FreeEnt(self);
	else
		self.nextthink = time + 0.01;
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
		Sound_PlaySound(self.owner, "sounds/pu/pickup.wav", SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);

		// Prepare for VO and destruction
		self.think = PU_PlayVO;
		self.nextthink = time + 1;

#ifdef FTE

		// Update the drawing of the Power-Up in CSQC to
		// register the flash.
		self.SendFlags = 1;

#endif // FTE

		// Prepare to shrink the Power-Up sparkle
		self.owner.think = PU_SparkleShrink;
		self.owner.nextthink = time + 0.01;
		self.owner.scale = 1;

		// slight cleaup
		setmodel(self, "");
		Light_None(self);
		self.touch = SUB_Null;

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
		Sound_PlaySound(self, "sounds/pu/powerup.wav", SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);
		self.calc_time = time + 2.998;
	}
};

#ifdef FTE

//
// PU_SendEntity(ePVent, flChanged)
// Sends ourself to CSQC for rendering.
//
float PU_SendEntity( entity ePVEnt, float flChanged ) {
    WriteByte( MSG_ENTITY, 2 );
    WriteCoord( MSG_ENTITY, self.origin_x ); // Position X
    WriteCoord( MSG_ENTITY, self.origin_y ); // Position Y
    WriteCoord( MSG_ENTITY, self.origin_z ); // Position Z
	WriteShort( MSG_ENTITY, self.modelindex ); // Power-Up Model
    return TRUE;
};

#endif // FTE

//
// Spawn_Powerup(where, type)
// Power-Up spawning function. Use type to force what spawns.
//
void(vector where, float type) Spawn_Powerup =
{
	entity 	powerup;
	entity	sparkle;

	// Move the Power-Up up a little to be near the player's
	// mid torso.
	if (map_compatibility_mode == MAP_COMPAT_BETA)
		where += PU_OFFSET_QK;
	else
		where += PU_OFFSET_HL;

	// Set Up Power-Up
	powerup = PU_GetFreeEnt();

	powerup.origin = where;
	setorigin(powerup, powerup.origin);

	powerup.solid = SOLID_TRIGGER;
	powerup.classname = "item_powerup";

	setsize(powerup, PU_BBOX_MINS, PU_BBOX_MAXS);
	powerup.movetype = MOVETYPE_NONE;

    Light_Green(powerup);

	// Set Up Sparkle Effect
	sparkle = PU_GetFreeEnt();
	sparkle.classname = "item_powerup_sparkle";

	powerup.owner = sparkle;

	sparkle.origin = where;
	setorigin(sparkle, sparkle.origin);

	setmodel(sparkle,"models/sprites/sprkle.spr");

	// Scale down for NZ:P Beta
	if (map_compatibility_mode == MAP_COMPAT_BETA) {
		powerup.scale = 0.66;
		sparkle.scale = 0.45;
	} 
	// The "normal" sized sparkle also needs scaled down
	// to be less aggressive and more supplemental.
	else {
		sparkle.scale = 0.66;
	}

	sparkle.effects = EF_FULLBRIGHT;
	sparkle.think = PU_SparkleThink;
	sparkle.nextthink = time + 0.1;

	// Drop Sounds
	Sound_PlaySound(sparkle, "sounds/pu/powerup.wav", SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);
	Sound_PlaySound(powerup, "sounds/pu/drop.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);

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

	// We draw the Power-Up in CSQC on FTE to employ our custom EF_ROTATE
	// implementation.
#ifdef FTE

	powerup.SendEntity = PU_SendEntity;
	powerup.SendFlags = 1;

#endif // FTE

	totalpowerups++;
};

