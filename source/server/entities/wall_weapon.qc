/*
	server/entities/wall_weapon.qc

	Contains both weapon_wall (Chalk Prop) and buy_weapon (Buy Trigger)
    functionality for purchasing Weapons off the Wall.

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

void() W_PlayTakeOut;
void(entity client, float weapon) Gamemode_BuyWeapon;

// =================================
// Wall Chalk Functionality
// =================================

//
// WallWeapon_PropResetVelocity()
// Halts the velocity for the moving Prop.
//
void() WallWeapon_PropResetVelocity =
{
	self.velocity = 0;
}

//
// WallWeapon_Use()
// Starts the Animation Sequence for the Wall Chalk's Prop.
//
void() WallWeapon_Use =
{
	// Already animated the Prop
	if (self.enemy.boxstatus != 0)
		return;

	// Play a sound for it "spawning"
	Sound_PlaySound(self, "sounds/misc/buy.wav", SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);

	// MP5K and Waffe were added in late in the mix-up.. needs special case. Also grenade bag.
	switch(self.sequence + 1) {
		case 26: // Grenade bag
			setmodel(self.enemy, "models/props/grenade_bag.mdl");
			break;
		case 29: // MP5K
			setmodel(self.enemy, GetWeaponModel(W_MP5K, 1));
			break;
		case 28: // Waffe
			setmodel(self.enemy, GetWeaponModel(W_TESLA, 1));
			break;
		case 30: // Springfield
			setmodel(self.enemy, GetWeaponModel(W_SPRING, 1));
			break;
		default:
			setmodel(self.enemy, GetWeaponModel(self.sequence + 1, 1));
			break;
	}

	// Send it forward a bit
	makevectors(self.angles);
	self.enemy.velocity = v_right * 6;
	self.enemy.think = WallWeapon_PropResetVelocity;
	self.enemy.nextthink = time + 0.8;

	// Make sure we don't repeat this!
	self.enemy.boxstatus = 1;
}

//
// weapon_wall()
// Quake Spawn Function for Wall Chalk.
//
void() weapon_wall =
{
	// Needed for the Prop
	precache_sound("sounds/misc/buy.wav");

	// We are, indeed, Wall Chalk.
	Precache_Set("models/misc/chalk.mdl");	
	setsize (self, '-12 -12 -12', '12 12 12');

	// Set-Up Weapon Prop.
	entity weapon_prop = spawn();
	self.enemy = weapon_prop;
	self.enemy.angles = self.angles;
	self.enemy.movetype = MOVETYPE_NOCLIP;
	self.enemy.solid = SOLID_NOT;
	self.enemy.owner = self;
	self.enemy.classname = "weapon_wall_prop";
	setsize(self.enemy, '0 0 0', '0 0 0');

	// We want the Prop to be slightly behind the Chalk.
	makevectors(self.angles);
	setorigin(self.enemy, self.origin + v_right*-4);

	// Backwards compatibility for betties brokenly using
	// cost2.
	if (self.cost == 0 && self.weapon == W_BETTY)
		self.cost = self.cost2;

	// Prep it for usage.
	self.skin = 0;
	self.frame = self.sequence;
	self.use = WallWeapon_Use;
	self.classname = "weapon_wall";
	self.effects = EF_FULLBRIGHT;
}

// =================================
// Weapon Buy Trigger Functionality
// =================================

//
// WallWeapon_TouchTrigger()
// Rough and bloaty logic for the process of purchasing
// a weapon from the Weapon Trigger.
//
void () WallWeapon_TouchTrigger =
{
	entity oldent;

	float wcost;

	if (other.classname != "player" || other.downed || other.isBuying || (map_compatibility_mode != MAP_COMPAT_BETA && !PlayerIsLooking(other, self))) {
		return;
	}

	if (self.weapon != 99) {

#ifndef FTE

		other.Weapon_Name_Touch = GetWeaponName(self.weapon);

#endif // FTE

		float slot;

		// Player has this weapon in any of their slots, PaP'd or not.
		if ((slot = Weapon_PlayerHasWeapon(other, self.weapon, true)) != 0) {
			float is_pap = true;


			// But the utility function returns the same value if we are NOT PaP'd
			if (Weapon_PlayerHasWeapon(other, self.weapon, false) == slot)
				is_pap = false;

			// Set the cost and weapon value (for useprint).
			wcost = (is_pap) ? self.pap_cost : self.cost2;
			wcost *= game_modifier_cost_multiplier;
			float wep = (is_pap) ? EqualPapWeapon(self.weapon) : self.weapon;

			Player_UseprintWithWait(other, self, 3, wcost, wep);

			if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE) || other.isBuying) {
				return;
			}

			// Store current Ammo value.
			float ammo = Weapon_GetPlayerAmmoInSlot(other, slot);

			// Max carrying capacity of the wall weapon
			float wall_ammo = (is_pap) ? getWeaponAmmo(EqualPapWeapon(self.weapon)) : getWeaponAmmo(self.weapon);

			// Weapon is already full. Abort.
			if (ammo >= wall_ammo)
				return;

			other.semi_actions |= SEMIACTION_USE;

			// Player doesn't have enough points. Abort.
			if (other.points < wcost) {
				centerprint(other, STR_NOTENOUGHPOINTS);
				Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
				return;
			}

			other.ach_tracker_coll++;

			// Set the weapon's ammo to the max capacity.
			Weapon_SetPlayerAmmoInSlot(other, slot, wall_ammo);

			Sound_PlaySound(other, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			other.reload_delay = 0;

			// Subtract the cost from player points.
			Player_RemoveScore(other, wcost);

			if (self.enemy) {
				SUB_UseTargets();
			}

			Gamemode_BuyWeapon(other, self.weapon);
		}
	} else 
	// Universal Ammo buy
	{

#ifndef FTE

		other.Weapon_Name_Touch = GetWeaponName(other.weapon);

#endif // FTE

		if (other.currentammo < getWeaponAmmo(other.weapon)) {

			// Set the cost and weapon value (for useprint).
			wcost = (IsPapWeapon(other.weapon)) ? self.pap_cost : self.cost2;
			wcost *= game_modifier_cost_multiplier;

			Player_UseprintWithWait(other, self, 3, wcost, other.weapon);

			if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE) || other.isBuying) {
				return;
			}

			other.semi_actions |= SEMIACTION_USE;

			// Player doesn't have enough points. Abort.
			if (other.points < wcost) {
				centerprint(other, STR_NOTENOUGHPOINTS);
				Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
				return;
			}

			other.weapons[0].weapon_reserve = getWeaponAmmo(other.weapon);

			Sound_PlaySound(other, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			other.reload_delay = 0;

			// Subtract the cost from player points.
			Player_RemoveScore(other, wcost);

			if (self.enemy) {
				SUB_UseTargets();
			}
		}
	}
	if (self.weapon == W_BETTY)
	{
		// Betties are a one-time purchase.
		if (other.grenades & 2)
			return;

		wcost = floor(self.cost * game_modifier_cost_multiplier);

		Player_UseprintWithWait(other, self, 4, wcost, self.weapon);

		if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
			return;
		if (other.points < wcost)
		{
			centerprint(other, STR_NOTENOUGHPOINTS);
			Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			return;
		}
		else
		{
			other.ach_tracker_coll++;
			other.reload_delay = 0;
			Sound_PlaySound(other, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			//other.boughtweapon = true;
			Player_RemoveScore(other, wcost);
			other.grenades = other.grenades | 2;
			other.secondary_grenades = 2;
			nzp_bettyprompt(other);
			if (self.enemy)
			{
				SUB_UseTargets();
			}
			Gamemode_BuyWeapon(other, self.weapon);
		}
		other.semi_actions |= SEMIACTION_USE;
		return;
	}
	else if (self.weapon == W_GRENADE)
	{
		wcost = floor(self.cost2 * game_modifier_cost_multiplier);
		if (other.primary_grenades < 4)
			Player_UseprintWithWait(other, self, 3, wcost, self.weapon);
		else
			return;
		if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE))
			return;
		if (other.points < wcost)
		{
			centerprint(other, STR_NOTENOUGHPOINTS);
			Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			return;
		}
		else
		{
			other.ach_tracker_coll++;
			other.reload_delay = 0;
			Sound_PlaySound(other, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			//other.boughtweapon = true;
			Player_RemoveScore(other, wcost);
			other.primary_grenades = 4;
			if (self.enemy)
			{
				SUB_UseTargets();
			}
			Gamemode_BuyWeapon(other, self.weapon);
		}
		other.semi_actions |= SEMIACTION_USE;
		return;
	}
	else if (self.weapon == W_BOWIE)
	{
		wcost = floor(self.cost2 * game_modifier_cost_multiplier);
		if (!other.has_bowie_knife) {
			Player_UseprintWithWait(other, self, 4, wcost, self.weapon);
			if (Player_UseButtonPressed(other, self))
			{
				if (other.points < wcost) {
					centerprint(other, STR_NOTENOUGHPOINTS);
					Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
					return;
				} else {
					W_HideCrosshair(other);
					Player_RemoveScore(other, wcost);
					Sound_PlaySound(other, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
					Sound_PlaySound(other, "sounds/weapons/knife/bowie.wav", SOUND_TYPE_WEAPON_OTHER, SOUND_PRIORITY_PLAYALWAYS);
					other.ach_tracker_coll++;
					if (self.enemy)
					{
						SUB_UseTargets();
					}
					entity tempz;
					tempz = self;
					self = other;
					Set_W_Frame(16, 43, 2.75, 0, 0, W_PlayTakeOut, "models/weapons/knife/v_bowie.mdl", false, S_BOTH, true);
					self.has_bowie_knife = true;
					Gamemode_BuyWeapon(self, tempz.weapon);
				}
			}
		}
	}
	else if (self.weapon != 99)
	{
		entity tempe;
		wcost = floor(self.cost * game_modifier_cost_multiplier);

		//centerprint(other, self.message);
      	Player_UseprintWithWait(other, self, 4, wcost, self.weapon);

		if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE)) {
			return;
		}

		other.semi_actions |= SEMIACTION_USE;
		if (other.points < wcost) {
			centerprint (other, STR_NOTENOUGHPOINTS);
			Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			return;
		}
		other.ach_tracker_coll++;

		Sound_PlaySound(other, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
		other.reload_delay = 0;
		Player_RemoveScore(other, wcost);
		if (self.enemy) {
			SUB_UseTargets();
		}
		tempe = self;
		self = other;

		Weapon_GiveWeapon(tempe.weapon, 0, 0);

		self = tempe;

		Gamemode_BuyWeapon(other, self.weapon);
	}

	if (other.ach_tracker_coll == ach_tracker_col2) {
		GiveAchievement(12, other);
	}
};

//
// WallWeapon_LinkChalk()
// Creates a proper entity link between the Trigger
// and the Chalk the mapper targeted it towards.
//
void() WallWeapon_LinkChalk =
{
	entity ent;
	
	ent = find (world, targetname, self.target);
	
	if (ent.classname == "weapon_wall") {
		self.enemy = ent;
		self.mins = self.enemy.mins;
		self.maxs = self.enemy.maxs;
		self.origin = self.enemy.origin;
		setsize(self, self.mins, self.maxs);
		setorigin(self, self.origin);
	}
	    
}

//
// buy_weapon()
// Quake Spawn Function for Weapon Trigger.
//
void() buy_weapon =
{
	InitTrigger ();

	// Default Pack-A-Punch Ammo Cost
	if (!self.pap_cost)
		self.pap_cost = 4500;

	string weaponname = GetWeaponModel (self.weapon, 0);
	if (weaponname != "")
		precache_model(weaponname);

	// Use the grenade bag instead for nades
	if (self.weapon == W_GRENADE)
		weaponname = "models/props/grenade_bag.mdl";
	else
		weaponname = GetWeaponModel(self.weapon, 1);
	if (weaponname != "")
		precache_model (weaponname);
	
	precache_extra (self.weapon);
	self.touch = WallWeapon_TouchTrigger;
	
	self.think = WallWeapon_LinkChalk;
	self.message = "";
	self.nextthink = time + 0.2; 

	ach_tracker_col2++;
};
