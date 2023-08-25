/*
	server/entities/wall_weapon.qc

	Contains both weapon_wall (Chalk Prop) and buy_weapon (Buy Trigger)
    functionality for purchasing Weapons off the Wall.

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
	sound(self, 1, "sounds/misc/buy.wav", 1, 1);

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
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);

	// Set-Up Weapon Prop.
	entity weapon_prop = spawn();
	self.enemy = weapon_prop;
	self.enemy.angles = self.angles;
	self.enemy.movetype = MOVETYPE_NOCLIP;
	self.enemy.solid = SOLID_NOT;
	self.enemy.owner = self;
	self.enemy.classname = "weapon_wall_prop";
	setsize(self.enemy, VEC_HULL2_MIN, VEC_HULL2_MAX);

	// We want the Prop to be slightly behind the Chalk.
	makevectors(self.angles);
	setorigin(self.enemy, self.origin + v_right*-4);

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
	float tempf, tempf1, tempf2, tempf3;

	float wcost;

	if (other.classname != "player" || other.downed || other.isBuying) {
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
			wcost = (is_pap) ? 4500 : self.cost2;
			float wep = (is_pap) ? EqualPapWeapon(self.weapon) : self.weapon;

			useprint(other, 3, wcost, wep);

			if (!other.button7 || other.semiuse || other.isBuying) {
				return;
			}

			// Store current Ammo value.
			float ammo = Weapon_GetPlayerAmmoInSlot(other, slot);

			// Max carrying capacity of the wall weapon
			float wall_ammo = (is_pap) ? getWeaponAmmo(EqualPapWeapon(self.weapon)) : getWeaponAmmo(self.weapon);

			// Weapon is already full. Abort.
			if (ammo >= wall_ammo)
				return;

			other.semiuse = true;

			// Player doesn't have enough points. Abort.
			if (other.points < wcost) {
				centerprint(other, STR_NOTENOUGHPOINTS);
				sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
				return;
			}

			other.ach_tracker_coll++;

			// Set the weapon's ammo to the max capacity.
			Weapon_SetPlayerAmmoInSlot(other, slot, wall_ammo);

			sound(other, 0, "sounds/misc/ching.wav", 1, 1);
			other.reload_delay = 0;

			// Subtract the cost from player points.
			addmoney(other, wcost*-1, 0);

			if (self.enemy) {
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
	} else 
	// Universal Ammo buy
	{

#ifndef FTE

		other.Weapon_Name_Touch = GetWeaponName(other.weapon);

#endif // FTE

		if (other.currentammo < getWeaponAmmo(other.weapon)) {

			// Set the cost and weapon value (for useprint).
			wcost = (IsPapWeapon(other.weapon)) ? 4500 : self.cost2;

			useprint(other, 3, wcost, other.weapon);

			if (!other.button7 || other.semiuse || other.isBuying) {
				return;
			}

			// Player doesn't have enough points. Abort.
			if (other.points < wcost) {
				centerprint(other, STR_NOTENOUGHPOINTS);
				sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
				return;
			}

			other.currentammo = getWeaponAmmo(other.weapon);

			sound(other, 0, "sounds/misc/ching.wav", 1, 1);
			other.reload_delay = 0;

			// Subtract the cost from player points.
			addmoney(other, wcost*-1, 0);

			if (self.enemy) {
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
	}
	if (self.weapon == W_BETTY)
	{
		if (other.secondary_grenades < 2)
			useprint (other, 3, self.cost2, self.weapon);
		else
			return;
		if (!other.button7 || other.semiuse)
			return;
		if (other.points < self.cost2)
		{
			centerprint(other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			return;
		}
		else
		{
			other.ach_tracker_coll++;
			other.reload_delay = 0;
			sound(other, 0, "sounds/misc/ching.wav", 1, 1);
			//other.boughtweapon = true;
			addmoney(other, 0 - self.cost2, FALSE);
			other.grenades = other.grenades | 2;
			other.secondary_grenades = 2;
			if (self.enemy)
			{
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
		other.semiuse = true;
		return;
	}
	else if (self.weapon == W_GRENADE)
	{
		if (other.primary_grenades < 4)
			useprint (other, 3, self.cost2, self.weapon);
		else
			return;
		if (!other.button7 || other.semiuse)
			return;
		if (other.points < self.cost)
		{
			centerprint(other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			return;
		}
		else
		{
			other.ach_tracker_coll++;
			other.reload_delay = 0;
			sound(other, 0, "sounds/misc/ching.wav", 1, 1);
			//other.boughtweapon = true;
			addmoney(other, 0 - self.cost, FALSE);
			other.primary_grenades = 4;
			if (self.enemy)
			{
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
		other.semiuse = true;
		return;
	}
	else if (self.weapon == W_BOWIE)
	{
		if (!other.bowie) {
			useprint(other, 3, self.cost2, self.weapon);
			if (other.button7)
			{
				if (other.points < self.cost2) {
					centerprint(other, STR_NOTENOUGHPOINTS);
					sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
					return;
				} else {
					addmoney(other, -self.cost2, FALSE);
					other.ach_tracker_coll++;
					entity tempz;
					tempz = self;
					self = other;
					Set_W_Frame(15, 30, 0, 0, 0, ReturnWeaponModel, "models/weapons/knife/v_bowie.mdl", false, S_BOTH);
					self.bowie = 1;
				}
			}
		}
	}
	else if (self.weapon != 99)
	{
		entity tempe;

		//centerprint(other, self.message);
      	useprint (other, 4, self.cost, self.weapon);

		if (!other.button7 || other.semiuse) {
			return;
		}

		other.semiuse = 1;
		if (other.points < self.cost) {
			centerprint (other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			return;
		}

		other.semiuse = true;
		other.ach_tracker_coll++;

		if (other.weapon && !other.secondaryweapon) {
			tempf = other.currentammo;
			other.currentammo = other.secondaryammo;
			other.secondaryammo = tempf;

			tempf1 = other.currentmag;
			other.currentmag = other.secondarymag;
			other.secondarymag = tempf1;

			tempf2 = other.weapon;
			other.weapon = other.secondaryweapon;
			other.secondaryweapon = tempf2;

			tempf3 = other.currentmag2;
			other.currentmag2 = other.secondarymag2;
			other.secondarymag2 = tempf3;
		} else if (other.weapon && other.secondaryweapon) {
			if ((other.perks & P_MULE) && !other.thirdweapon) {
				// store secondary weapon
				tempf = other.secondaryweapon;
				tempf1 = other.secondarymag;
				tempf2 = other.secondaryammo;
				tempf3 = other.secondarymag2;
				// move primary to secondary
				other.secondaryweapon = other.weapon;
				other.secondarymag = other.currentmag;
				other.secondarymag2 = other.currentmag2;
				other.secondaryammo = other.currentammo;
				// move secondary to tertiary
				other.thirdweapon = tempf;
				other.thirdmag = tempf1;
				other.thirdammo = tempf2;
				other.thirdmag2 = tempf3;
			}

			// free current slot
			other.currentammo = 0;
			other.currentmag = 0;
			other.weapon = 0;
		}

		sound(other, 0, "sounds/misc/ching.wav", 1, 1);
		other.reload_delay = 0;
		addmoney(other, -1*self.cost, 0);
		if (self.enemy) {
			oldent = self;
			self = self.enemy;
			self.use();
			self = oldent;
		}
		other.weapon = self.weapon;

		other.currentammo = getWeaponAmmo(self.weapon);
		other.currentmag = getWeaponMag(self.weapon);
		tempe = self;
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

#endif // FTE

		self = tempe;
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
	
	if (ent.classname == "weapon_wall")
	    self.enemy = ent;
}

//
// buy_weapon()
// Quake Spawn Function for Weapon Trigger.
//
void() buy_weapon =
{
	InitTrigger ();

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
	self.nextthink = time + 0.2; 

	ach_tracker_col2++;
	
	precache_sound("sounds/misc/ching.wav");
};