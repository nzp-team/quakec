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

#define MAX_POWERUPS		12

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
	// JSON paths are already complete. Older callers can still supply a basename.
	if (file == "" || substring(file, 0, 7) == "sounds/") return file;
	string path = "";

	switch(cvar("sv_gamemode")) {
		case GAMEMODE_GUNGAME: path = strcat("sounds/modes/gungame/", file); break;
		case GAMEMODE_HARDCORE: path = strcat("sounds/modes/hardcore/", file); break;
		case GAMEMODE_STICKSNSTONES: path = strcat("sounds/modes/sticks/", file); break;
		case GAMEMODE_WILDWEST: path = strcat("sounds/modes/wildwest/", file); break;
		case GAMEMODE_FESTIVE: path = strcat("sounds/modes/festive/", file); break;
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
	if (model_path != "") precache_model(model_path);
	if (voiceover_path_full != "") precache_sound(voiceover_path_full);

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
// PU_IsEnabled(id)
// Returns whether a Power-Up is allowed in the random drop rotation.
//
float(float id) PU_IsEnabled =
{
	switch (id) {
		case PU_NUKE: return game_modifiers.gameplay.powerups.powerup_nuke.enabled;
		case PU_INSTAKILL: return game_modifiers.gameplay.powerups.powerup_instakill.enabled;
		case PU_DOUBLEPTS: return game_modifiers.gameplay.powerups.powerup_double_points.enabled;
		case PU_CARPENTER: return game_modifiers.gameplay.powerups.powerup_carpenter.enabled;
		case PU_MAXAMMO: return game_modifiers.gameplay.powerups.powerup_max_ammo.enabled;
		case PU_FREEPERK: return game_modifiers.gameplay.powerups.powerup_free_perk.enabled;
		case PU_UPGRADEWEAPON: return game_modifiers.gameplay.powerups.powerup_weapon_upgrade.enabled;
		case PU_BONUSPOINTS: return game_modifiers.gameplay.powerups.powerup_bonus_points.enabled;
	}

	return false;
};

//
// PU_GetNextPowerUp()
// Returns the next valid Power-Up, and refreshes array if needbe.
//
float() PU_GetNextPowerUp =
{
	float id;
	float found;
	float attempt_limit;
	id = -1;
	found = false;

	attempt_limit = powerup_count;
	if (powerup_index > 0)
		attempt_limit += powerup_count - powerup_index;

	// A configuration may leave no eligible drops. Try the deck once.
	for (float attempt = 0; attempt < attempt_limit && !found; attempt++) {
		// Refresh the Array if we're at the end
		if (powerup_index >= powerup_count) {
			PU_PopulateArray();
			powerup_index = 0;
		}

		// Grab a Power-Up
		float current_index = powerup_index;
		powerup_index++;

		// Found a valid Power-Up
		if (powerup_array[current_index].occupied == true && PU_IsEnabled(powerup_array[current_index].id)) {
			// Check if we meet the requirements
			if (powerup_array[current_index].requirement_function() == true) {
				id = powerup_array[current_index].id;
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
	if (game_modifiers.gameplay.player.can_earn_score_from_sources_other_than_ai == true) {
		players = find(world,classname,"player");
		while(players)
		{
			Player_AddScore(players, game_modifiers.gameplay.powerups.powerup_nuke.score_awarded * nuke_powerups_activated, true);
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
	Sound_PlaySound(self, game_modifiers.gameplay.powerups.powerup_nuke.explosion_sfx, SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);

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
	instakill_finished = time + game_modifiers.gameplay.powerups.powerup_instakill.duration;
	other.insta_icon = true;
};

//
// PU_DoublePoints()
// Double Points Power-Up Function
//
void() PU_DoublePoints =
{
	x2_finished = time + game_modifiers.gameplay.powerups.powerup_double_points.duration;
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
	if (game_modifiers.gameplay.player.can_earn_score_from_sources_other_than_ai) {
		while(players) {
			Player_AddScore(players, game_modifiers.gameplay.powerups.powerup_carpenter.score_awarded, true);

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
// PU_NukeRequirement()
// Requirements for Nuke Power-Up.
//
float() PU_NukeRequirement =
{
	if (game_modifiers.gameplay.powerups.powerup_nuke.enabled == false)
		return false;

	if (rounds < game_modifiers.gameplay.powerups.powerup_nuke.disabled_before_round)
		return false;

	if (random() >= game_modifiers.gameplay.powerups.powerup_nuke.chance_to_allow_in_rotation)
		return false;

	return true;
};

//
// PU_InstaKillRequirement()
// Requirements for Insta-Kill Power-Up.
//
float() PU_InstaKillRequirement =
{
	if (game_modifiers.gameplay.powerups.powerup_instakill.enabled == false)
		return false;

	if (rounds < game_modifiers.gameplay.powerups.powerup_instakill.disabled_before_round)
		return false;

	if (random() >= game_modifiers.gameplay.powerups.powerup_instakill.chance_to_allow_in_rotation)
		return false;

	return true;
};

//
// PU_DoublePointsRequirement()
// Requirements for Double Points Power-Up.
//
float() PU_DoublePointsRequirement =
{
	if (game_modifiers.gameplay.powerups.powerup_double_points.enabled == false)
		return false;

	if (rounds < game_modifiers.gameplay.powerups.powerup_double_points.disabled_before_round)
		return false;

	if (random() >= game_modifiers.gameplay.powerups.powerup_double_points.chance_to_allow_in_rotation)
		return false;

	return true;
};

//
// PU_CarpenterRequirement()
// Requirements for Carpenter Power-Up.
//
float() PU_CarpenterRequirement =
{
	if (game_modifiers.gameplay.powerups.powerup_carpenter.enabled == false)
		return false;

	if (rounds < game_modifiers.gameplay.powerups.powerup_carpenter.disabled_before_round)
		return false;

	if (random() >= game_modifiers.gameplay.powerups.powerup_carpenter.chance_to_allow_in_rotation)
		return false;

	if (total_windows_down < game_modifiers.gameplay.powerups.powerup_carpenter.destroyed_barricade_requirement)
		return false;

	return true;
}

//
// PU_MaxAmmoRequirement()
// Requirements for Max Ammo Power-Up.
//
float() PU_MaxAmmoRequirement =
{
	if (game_modifiers.gameplay.powerups.powerup_max_ammo.enabled == false)
		return false;

	if (rounds < game_modifiers.gameplay.powerups.powerup_max_ammo.disabled_before_round)
		return false;

	if (random() >= game_modifiers.gameplay.powerups.powerup_max_ammo.chance_to_allow_in_rotation)
		return false;

	return true;
}

//
// PU_FreePerkRequirement()
// Requirements for Free Perk Power-Up.
//
float() PU_FreePerkRequirement =
{
	if (game_modifiers.gameplay.powerups.powerup_free_perk.enabled == false)
		return false;

	if (rounds < game_modifiers.gameplay.powerups.powerup_free_perk.disabled_before_round)
		return false;

	if (random() >= game_modifiers.gameplay.powerups.powerup_free_perk.chance_to_allow_in_rotation)
		return false;

	return true;
}

//
// PU_UpgradeWeaponRequirement()
// Requirements for Weapon Upgrade Power-Up
//
float() PU_UpgradeWeaponRequirement =
{
	if (game_modifiers.gameplay.powerups.powerup_weapon_upgrade.enabled == false)
		return false;

	if (rounds < game_modifiers.gameplay.powerups.powerup_weapon_upgrade.disabled_before_round)
		return false;

	if (random() >= game_modifiers.gameplay.powerups.powerup_weapon_upgrade.chance_to_allow_in_rotation)
		return false;

	return true;
}

//
// PU_BonusPointsRequirement()
// Requirements for Bonus Points Power-Up
//
float() PU_BonusPointsRequirement =
{
	if (game_modifiers.gameplay.powerups.powerup_bonus_points.enabled == false)
		return false;

	if (rounds < game_modifiers.gameplay.powerups.powerup_bonus_points.disabled_before_round)
		return false;

	if (random() >= game_modifiers.gameplay.powerups.powerup_bonus_points.chance_to_allow_in_rotation)
		return false;

	return true;
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

				// Some game configurations support also filling the magazine..
				if (game_modifiers.gameplay.powerups.powerup_max_ammo.fills_magazine) {
					players.weapons[i].weapon_magazine = getWeaponMag(players.weapons[i].weapon_id);

					if (IsDualWeapon(players.weapons[i].weapon_id)) {
						players.weapons[i].weapon_magazine_left = getWeaponMag(players.weapons[i].weapon_id);
					}
				}
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

		// don't to anything if any of these conditions is true
		//  1. player is down
		//  2. player has already all perks
		//  3. player has all perks useful for Gun Game mode (all but mule kick)
		if (players.downed || players.perks >= P_ALL || (cvar("sv_gamemode") == GAMEMODE_GUNGAME && players.perks >= P_ALL_GUNGAME)) {
			players = find(players, classname, "player");
			continue;
		}

		// Determine list of Perk-A-Colas we're allowed to give to this
		// player.
		float perks_can_give = 0;

		for(float i = 0; i < 8; i++) {
			if (game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[i] == "")
				break;

			switch(game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[i])
			{
				case "quickrevive":
					if (!(players.perks & P_REVIVE))
						perks_can_give |= P_REVIVE;
					break;
				case "juggernog":
					if (!(players.perks & P_JUG))
						perks_can_give |= P_JUG;
					break;
				case "speedcola":
					if (!(players.perks & P_SPEED))
						perks_can_give |= P_SPEED;
					break;
				case "doubletap":
					if (!(players.perks & P_DOUBLE))
						perks_can_give |= P_DOUBLE;
					break;
				case "phdflopper":
					if (!(players.perks & P_FLOP))
						perks_can_give |= P_FLOP;
					break;
				case "staminup":
					if (!(players.perks & P_STAMIN))
						perks_can_give |= P_STAMIN;
					break;
				case "deadshot":
					if (!(players.perks & P_DEAD))
						perks_can_give |= P_DEAD;
					break;
				case "mulekick":
					if (!(players.perks & P_MULE))
						perks_can_give |= P_MULE;
					break;
			}
		}

		// Potentially award points if the player cannot
		// earn anything.
		if (perks_can_give <= 0) {
			Player_AddScore(players, game_modifiers.gameplay.powerups.powerup_free_perk.awarded_score_if_no_perk_obtained, true);
			players = find(players, classname, "player");
			continue;
		}


		float perk_to_give = 0;
		float found_perk_for_player = false;

		while(!found_perk_for_player) {
			float perk_rand = random();

			if (perk_rand < (1/8) && (perks_can_give & P_REVIVE)) { self.sequence = 1; perk_to_give = P_REVIVE; }
			else if (perk_rand < (2/8) && (perks_can_give & P_JUG)) { self.sequence = 2; perk_to_give = P_JUG; }
			else if (perk_rand < (3/8) && (perks_can_give & P_SPEED)) { self.sequence = 3; perk_to_give = P_SPEED; }
			else if (perk_rand < (4/8) && (perks_can_give & P_DOUBLE)) { self.has_doubletap_damage_buff = true; self.sequence = 4; perk_to_give = P_DOUBLE; }
			else if (perk_rand < (5/8) && (perks_can_give & P_STAMIN)) { self.sequence = 5; perk_to_give = P_STAMIN; }
			else if (perk_rand < (6/8) && (perks_can_give & P_FLOP)) { self.sequence = 6; perk_to_give = P_FLOP; }
			else if (perk_rand < (7/8) && (perks_can_give & P_DEAD)) { self.sequence = 7; perk_to_give = P_DEAD; }
			else if ((perks_can_give & P_MULE)) { self.sequence = 8; perk_to_give = P_MULE; }

			if (perk_to_give != 0)
				found_perk_for_player = true;
		}

		players.style = perk_to_give;
		players.usedent = self;

		tempe = self;
		self = players;
		W_SprintStop();
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
		float current_weapon_tier = players.weapons[0].weapon_tier;

		// Already upgraded, don't bother.
		if (EqualPapWeapon(current_weapon) == current_weapon) {
			if (!(game_modifiers.gameplay.packapunch.packapunch_supports_upgrade_tiers == true && current_weapon_tier < 3)) {
				Player_AddScore(players, game_modifiers.gameplay.powerups.powerup_weapon_upgrade.awarded_score_if_no_upgrade_received, true);
				players = find(players, classname, "player");
				continue;
			}
		}

		entity old_self = self;
		self = players;
		W_SprintStop();
        W_AimOut();
		Weapon_AssignWeapon(0, EqualPapWeapon(current_weapon), 0, 0, current_weapon_tier + 1);
		Weapon_SwapWeapons(true);
		self = old_self;

		players = find(players, classname, "player");
	}
};

//
// PU_BonusPoints()
// Bonus Points Power-Up Function
//
void() PU_BonusPoints =
{
	entity players = find(world, classname, "player");
	while(players != world) {
		Player_AddScore(players, game_modifiers.gameplay.powerups.powerup_bonus_points.score_awarded, true);
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
	powerup_index = 0;

	// Set the Power-Up array IDs to empty
	for (float i = 0; i < MAX_POWERUPS; i++) {
		powerup_array[i].id = -1;
	}

	// Just add all of them for now
	PU_AddToStruct(PU_NUKE,
					game_modifiers.gameplay.powerups.powerup_nuke.model,
					game_modifiers.gameplay.powerups.powerup_nuke.voiceover,
					PU_Nuke,
					PU_NukeRequirement);

	PU_AddToStruct(PU_INSTAKILL,
					game_modifiers.gameplay.powerups.powerup_instakill.model,
					game_modifiers.gameplay.powerups.powerup_instakill.voiceover,
					PU_InstaKill,
					PU_InstaKillRequirement);

	PU_AddToStruct(PU_DOUBLEPTS,
					game_modifiers.gameplay.powerups.powerup_double_points.model,
					game_modifiers.gameplay.powerups.powerup_double_points.voiceover,
					PU_DoublePoints,
					PU_DoublePointsRequirement);

	PU_AddToStruct(PU_CARPENTER,
					game_modifiers.gameplay.powerups.powerup_carpenter.model,
					game_modifiers.gameplay.powerups.powerup_carpenter.voiceover,
					PU_Carpenter,
					PU_CarpenterRequirement);

	PU_AddToStruct(PU_MAXAMMO,
					game_modifiers.gameplay.powerups.powerup_max_ammo.model,
					game_modifiers.gameplay.powerups.powerup_max_ammo.voiceover,
					PU_MaxAmmo,
					PU_MaxAmmoRequirement);

	PU_AddToStruct(PU_FREEPERK,
					game_modifiers.gameplay.powerups.powerup_free_perk.model,
					game_modifiers.gameplay.powerups.powerup_free_perk.voiceover,
					PU_FreePerk,
					PU_FreePerkRequirement);

	PU_AddToStruct(PU_UPGRADEWEAPON,
					game_modifiers.gameplay.powerups.powerup_weapon_upgrade.model,
					game_modifiers.gameplay.powerups.powerup_weapon_upgrade.voiceover,
					PU_WeaponUpgrade,
					PU_UpgradeWeaponRequirement);

	PU_AddToStruct(PU_BONUSPOINTS,
					game_modifiers.gameplay.powerups.powerup_bonus_points.model,
					game_modifiers.gameplay.powerups.powerup_bonus_points.voiceover,
					PU_BonusPoints,
					PU_BonusPointsRequirement);

	// Nuke requires an extra Precache
	Modifiers_PrecacheSound(game_modifiers.gameplay.powerups.powerup_nuke.explosion_sfx);

	// Fill the array
	PU_PopulateArray();

	// Spawn all of our Power-Up spawn entities
	// Keep room for forced drops even when random drops are disabled.
	// Multiply by 4 for Power-Up operations like the Nuke.
	for (float i = 0; i < (clamp(game_modifiers.gameplay.powerups.max_powerups_per_round, 1, 64) * 4); i++) {
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
	if (sound_path != "")
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
// PU_GetToast(powerup_id)
// Returns the Power-Up toast for a given
// Power-Up.
//
string(float powerup_id) PU_GetToast =
{
	if (powerup_id == PU_NUKE && game_modifiers.gameplay.powerups.powerup_nuke.show_toast)
		return game_modifiers.gameplay.powerups.powerup_nuke.toast;
	if (powerup_id == PU_INSTAKILL && game_modifiers.gameplay.powerups.powerup_instakill.show_toast)
		return game_modifiers.gameplay.powerups.powerup_instakill.toast;
	if (powerup_id == PU_DOUBLEPTS && game_modifiers.gameplay.powerups.powerup_double_points.show_toast)
		return game_modifiers.gameplay.powerups.powerup_double_points.toast;
	if (powerup_id == PU_CARPENTER && game_modifiers.gameplay.powerups.powerup_carpenter.show_toast)
		return game_modifiers.gameplay.powerups.powerup_carpenter.toast;
	if (powerup_id == PU_MAXAMMO && game_modifiers.gameplay.powerups.powerup_max_ammo.show_toast)
		return game_modifiers.gameplay.powerups.powerup_max_ammo.toast;
	if (powerup_id == PU_FREEPERK && game_modifiers.gameplay.powerups.powerup_free_perk.show_toast)
		return game_modifiers.gameplay.powerups.powerup_free_perk.toast;
	if (powerup_id == PU_UPGRADEWEAPON && game_modifiers.gameplay.powerups.powerup_weapon_upgrade.show_toast)
		return game_modifiers.gameplay.powerups.powerup_weapon_upgrade.toast;
	if (powerup_id == PU_BONUSPOINTS && game_modifiers.gameplay.powerups.powerup_bonus_points.show_toast)
		return game_modifiers.gameplay.powerups.powerup_bonus_points.toast;

	return "";
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
		Sound_PlaySound(self.owner, game_modifiers.gameplay.powerups.sounds.pick_up, SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);

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

		string toast = PU_GetToast(self.walktype);
		if (toast != "") {
			nzp_poweruptoast(toast);
		}
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
		Sound_PlaySound(self, game_modifiers.gameplay.powerups.sounds.idle, SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);
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

	if (type == -1)
		type = PU_GetNextPowerUp();
	if (type == -1)
		return;

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
	Sound_PlaySound(sparkle, game_modifiers.gameplay.powerups.sounds.idle, SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);
	Sound_PlaySound(powerup, game_modifiers.gameplay.powerups.sounds.drop, SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);

	powerup.walktype = type;

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

