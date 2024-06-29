/*
	server/utilities/weapon_utilities.qc

	Contains some wrapped or easy access functions to streamline weapon
    behaviors a bit.

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

// FTEQCC currently has an optimization bug with -fastarrays
// that leads to corruption with the weapon list. Disable
// if we're not on FTE.
#ifndef FTE

#pragma flag disable fastarrays

#endif // FTE

// TODO: Actually implement some of these..
// Frame types, generalized.
#define ANIM_FIRE                   0
#define ANIM_RELOAD                 1
#define ANIM_SPRINT_START           2
#define ANIM_SPRINT                 3
#define ANIM_SPRINT_STOP            4
#define ANIM_FIRST_TAKE             5
#define ANIM_TAKE_OUT               6
#define ANIM_PUT_AWAY               7
#define ANIM_AIM                    8

void() W_AimOut;
void() ReturnWeaponModel;
void(entity person) W_HideCrosshair;

//
// Weapon_GetPlayerAmmoInSlot(person, slot)
// Returns the reserve ammo the player has in a weapon slot.
//
float(entity person, float slot) Weapon_GetPlayerAmmoInSlot =
{
	switch(slot) {
		case 1: return person.weapons[0].weapon_reserve;
		case 2: return person.weapons[1].weapon_reserve;
		case 3: return person.weapons[2].weapon_reserve;
		default: return 0;
	}
};

//
// Weapon_SetPlayerAmmoInSlot(person, slot, ammo)
// Sets the player's reserve ammo in a slot to param3.
//
void(entity person, float slot, float ammo) Weapon_SetPlayerAmmoInSlot =
{
	switch(slot) {
		case 1: person.weapons[0].weapon_reserve = ammo; break;
		case 2: person.weapons[1].weapon_reserve = ammo; break;
		case 3: person.weapons[2].weapon_reserve = ammo; break;
		default: return; break;
	}
};

//
// Weapon_PlayerHasWeapon(person, comparison, include_pap)
// Checks to see if the Player is holding a weapon in any
// of their three slots. `include_pap` dictates whether to
// consider Pack-A-Punch'd varients. Returns 1, 2, 3 depending
// on the slot the weapon is contained in.
//
float(entity person, float comparison, float include_pap) Weapon_PlayerHasWeapon =
{
	for (float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		// Storage.
		float weapon_id;

		// If we're including pap'd weapons, just convert the weapon set to the base
		// ones to save on comparison checks.
		if (include_pap == true)
			weapon_id = EqualNonPapWeapon(person.weapons[i].weapon_id);
		else
			weapon_id = person.weapons[i].weapon_id;

		// Now do the comparison
		if (weapon_id == comparison)
			return i + 1;
	}

	return 0;
};

//
// Weapon_PlayerHasWeaponWithFiretype(person, comparison)
// Similar check to Weapon_PlayerHasWeapon, but returns
// an index to the first-found firetype instead.
//
float(entity person, float comparison) Weapon_PlayerHasWeaponWithFiretype =
{
	for (float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		// Storage.
		float weapon_firetype = GetFiretype(person.weapons[i].weapon_id);

		// Now do the comparison
		if (weapon_firetype == comparison)
			return i + 1;
	}

	return 0;
};

//
// Weapon_IsSemiAutomatic(float weapon)
// Checks weapon firetypes and returns true if intended
// to be semi-automatic.
//
float(float weapon) Weapon_IsSemiAutomatic =
{
	float firetype = GetFiretype(weapon);

	// Valid firetypes
	if (firetype == FIRETYPE_SEMIAUTO || firetype == FIRETYPE_GRENADE ||
	firetype == FIRETYPE_TESLA)
		return true;

	return false;
};

//
// Weapon_FiresTraceshot(weapon)
// Simply returns true if given weapon's firetype requires a
// firetrace to be used properly.
//
float(float weapon) Weapon_FiresTraceshot =
{
	float firetype = GetFiretype(weapon);

	// Valid firetypes
	if (firetype == FIRETYPE_FULLAUTO || firetype == FIRETYPE_SEMIAUTO)
		return true;

	return false;
};

//
// Weapon_PlayViewModelAnimation(animation_type, end_function, playback_duration)
// Sets up and plays the weapon sequence for you.
//
void (float animation_type, void(optional float t) end_function, float playback_duration) Weapon_PlayViewModelAnimation =
{
    float start_frame = 0;
    float end_frame = 0;
	float duration = 0;

    switch(animation_type) {
        case ANIM_SPRINT_START:
            start_frame = GetFrame(self.weapon, SPRINT_IN_START);
            end_frame = GetFrame(self.weapon, SPRINT_IN_END);
            break;
        case ANIM_SPRINT:
            start_frame = GetFrame(self.weapon, SPRINT_START);
            end_frame = GetFrame(self.weapon, SPRINT_END);
            break;
        case ANIM_SPRINT_STOP:
            start_frame = GetFrame(self.weapon, SPRINT_OUT_START);
            end_frame = GetFrame(self.weapon, SPRINT_OUT_END);
            break;
        case ANIM_TAKE_OUT:
            start_frame = GetFrame(self.weapon, TAKE_OUT_START);
            end_frame = GetFrame(self.weapon, TAKE_OUT_END);
			duration = playback_duration = getWeaponDelay(self.weapon, TAKEOUT);
            break;
        case ANIM_PUT_AWAY:
            start_frame = GetFrame(self.weapon, PUT_OUT_START);
            end_frame = GetFrame(self.weapon, PUT_OUT_END);
			duration = playback_duration = getWeaponDelay(self.weapon, PUTOUT);
            break;
        case ANIM_FIRST_TAKE:
            start_frame = GetFrame(self.weapon, FIRST_TAKE_START);
            end_frame = GetFrame(self.weapon, FIRST_TAKE_END);
            break;
        default:
            break;
    }

	self.switch_delay = self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = self.knife_delay = time + (duration - 0.1);
	self.weapon2model = GetWeapon2Model(self.weapon);

    W_AimOut();
    Set_W_Frame(start_frame, end_frame, playback_duration, 0, 0, end_function, GetWeaponModel(self.weapon, 0), false, S_BOTH);
};

//
// Weapon_SwapWeapons()
// Performs a standard weapon swap.
//
void Weapon_SwapWeapons(float play_animation)
{
 	float weapon_count = 0;

 	// Un-zoom camera
 	self.zoom = false;

	// Fix fire rate exploit
	self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = true;

	// Store current weapons locally
	guninventory_struct weapons_storage[MAX_PLAYER_WEAPONS];
	for(float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		if (self.weapons[i].weapon_id != 0) {
			weapon_count++;
			weapons_storage[i].weapon_id = self.weapons[i].weapon_id;
			weapons_storage[i].weapon_magazine = self.weapons[i].weapon_magazine;
			weapons_storage[i].weapon_magazine_left = self.weapons[i].weapon_magazine_left;
			weapons_storage[i].weapon_reserve = self.weapons[i].weapon_reserve;
			weapons_storage[i].weapon_skin = self.weapons[i].weapon_skin;
			weapons_storage[i].is_mulekick_weapon = self.weapons[i].is_mulekick_weapon;
		}
	}

	// Iterate over the player inventory and shift the array around!
	for(float j = 0; j < weapon_count; j++) {
		if (j != weapon_count - 1) {
			self.weapons[j + 1].weapon_id = weapons_storage[j].weapon_id;
			self.weapons[j + 1].weapon_magazine = weapons_storage[j].weapon_magazine;
			self.weapons[j + 1].weapon_magazine_left = weapons_storage[j].weapon_magazine_left;
			self.weapons[j + 1].weapon_reserve = weapons_storage[j].weapon_reserve;
			self.weapons[j + 1].weapon_skin = weapons_storage[j].weapon_skin;
			self.weapons[j + 1].is_mulekick_weapon = weapons_storage[j].is_mulekick_weapon;
		} else {
		 	self.weapons[0].weapon_id = weapons_storage[j].weapon_id;
			self.weapons[0].weapon_magazine = weapons_storage[j].weapon_magazine;
			self.weapons[0].weapon_magazine_left = weapons_storage[j].weapon_magazine_left;
			self.weapons[0].weapon_reserve = weapons_storage[j].weapon_reserve;
			self.weapons[0].weapon_skin = weapons_storage[j].weapon_skin;
			self.weapons[0].is_mulekick_weapon = weapons_storage[j].is_mulekick_weapon;
		}
	}

	if (play_animation == true) {
		// Properly update the weapon ID
		self.weapon = self.weapons[0].weapon_id;

		W_HideCrosshair(self);
		Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, ReturnWeaponModel, 0);


		self.weaponskin = self.weapons[0].weapon_skin;

#ifndef FTE

		self.weapon2skin = self.weapons[0].weapon_skin;
		self.Weapon_Name = GetWeaponName(self.weapon);
		self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
		self.Flash_Size = GetWeaponFlash_Size(self.weapon);
		self.ADS_Offset = GetWeaponADSOfs(self.weapon);

#endif // FTE

	}

};

//
// Weapon_SetActiveInslot(slot)
// Iterates through the Inventory array until weapon 0
// is what was in the requested slot.
//
void Weapon_SetActiveInSlot(float slot, float play_first_raise)
{
	if (slot != 0)
		Weapon_SwapWeapons(false);

	// Properly update the weapon ID
	self.weapon = self.weapons[0].weapon_id;

	if (GetFrame(self.weapon, FIRST_TAKE_START) != 0 && play_first_raise == true)
		Weapon_PlayViewModelAnimation(ANIM_FIRST_TAKE, ReturnWeaponModel, 0);
	else
		Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, ReturnWeaponModel, 0);

	self.weaponskin = self.weapons[0].weapon_skin;

#ifndef FTE

	self.weapon2skin = self.weapons[0].weapon_skin;
	self.Weapon_Name = GetWeaponName(self.weapon);
	self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
	self.Flash_Size = GetWeaponFlash_Size(self.weapon);
	self.ADS_Offset = GetWeaponADSOfs(self.weapon);

#endif // FTE

};

//
// Weapon_HasNoMulekickWeapon()
// Returns true if the player does not
// have a Mule Kick weapon slot.
//
float Weapon_HasNoMulekickWeapon()
{
	for(float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		if (self.weapons[i].is_mulekick_weapon == true)
			return false;
	}

	return true;
}

//
// Weapon_AssignWeapon(weapon_slot, weapon_id, weapon_mag, weapon_reserve)
// Fills in weapon data for provided slot.
//
void Weapon_AssignWeapon(float weapon_slot, float weapon_id, float weapon_mag, float weapon_reserve)
{
	// Fill the stats as necessary
	self.weapons[weapon_slot].weapon_id = weapon_id;
			
	if (weapon_mag > 0) {
		self.weapons[weapon_slot].weapon_magazine = weapon_mag;
		if (IsDualWeapon(self.weapons[weapon_slot].weapon_id))
			self.weapons[weapon_slot].weapon_magazine_left = weapon_mag;
	} else {
		self.weapons[weapon_slot].weapon_magazine = getWeaponMag(self.weapons[weapon_slot].weapon_id);
		if (IsDualWeapon(self.weapons[weapon_slot].weapon_id))
			self.weapons[weapon_slot].weapon_magazine_left = getWeaponMag(self.weapons[weapon_slot].weapon_id);
		else
			self.weapons[weapon_slot].weapon_magazine_left = 0;
	}

	if (weapon_reserve > 0)
		self.weapons[weapon_slot].weapon_reserve = weapon_reserve;
	else
		self.weapons[weapon_slot].weapon_reserve = getWeaponAmmo(self.weapons[weapon_slot].weapon_id);

	if (weapon_slot == MULEKICK_WEAPON_SLOT - 1 && Weapon_HasNoMulekickWeapon())
		self.weapons[weapon_slot].is_mulekick_weapon = true;

	self.weapons[weapon_slot].weapon_skin = GetWepSkin(weapon_id);

	// Now tell the player to hold it.
	Weapon_SetActiveInSlot(weapon_slot, true);
};

//
// Weapon_GiveWeapon(weapon_id, weapon_mag, weapon_reserve)
// Assigns a weapon to the next free slot
// in player inventory.
//
void Weapon_GiveWeapon(float weapon_id, float weapon_mag, float weapon_reserve)
{
	W_HideCrosshair(self);

	float should_leave = false;

	// Find next available weapon slot
	float weapon_slots;

	if ((self.perks & P_MULE))
		weapon_slots = MULEKICK_WEAPON_SLOT;
	else
		weapon_slots = MULEKICK_WEAPON_SLOT - 1;

	for(float i = 0; i < weapon_slots; i++) {
		if (self.weapons[i].weapon_id == 0) {
			for(float j = 0; j < i; j++) {
				Weapon_SwapWeapons(false);
			}
			Weapon_AssignWeapon(i, weapon_id, weapon_mag, weapon_reserve);
			should_leave = true;
			break;
		}
	}

	if (should_leave)
		return;

	// All slots are occupied, fill in current slot
	Weapon_AssignWeapon(0, weapon_id, weapon_mag, weapon_reserve);
};

//
// Weapons_FixUpList()
// Iterates through client weapon list and 
// re-orders to remove gaps with IDs of 0.
//
void Weapon_FixUpList()
{
	// Store current weapons locally
	guninventory_struct weapons_storage[MAX_PLAYER_WEAPONS];
	for(float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		if (self.weapons[i].weapon_id != 0) {
			weapons_storage[i].weapon_id = self.weapons[i].weapon_id;
			weapons_storage[i].weapon_magazine = self.weapons[i].weapon_magazine;
			weapons_storage[i].weapon_magazine_left = self.weapons[i].weapon_magazine_left;
			weapons_storage[i].weapon_reserve = self.weapons[i].weapon_reserve;
			weapons_storage[i].weapon_skin = self.weapons[i].weapon_skin;
			weapons_storage[i].is_mulekick_weapon = self.weapons[i].is_mulekick_weapon;
		}
	}

	// Reset all of the player's weapons
	for(float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		self.weapons[i].weapon_id = 0;
		self.weapons[i].weapon_magazine = 0;
		self.weapons[i].weapon_magazine_left = 0;
		self.weapons[i].weapon_reserve = 0;
		self.weapons[i].weapon_skin = 0;
		self.weapons[i].is_mulekick_weapon = false;
	}

	float weapon_index = 0;
	for(float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		if (weapons_storage[i].weapon_id != 0) {
			self.weapons[weapon_index].weapon_id = weapons_storage[i].weapon_id;
			self.weapons[weapon_index].weapon_magazine = weapons_storage[i].weapon_magazine;
			self.weapons[weapon_index].weapon_magazine_left = weapons_storage[i].weapon_magazine_left;
			self.weapons[weapon_index].weapon_reserve = weapons_storage[i].weapon_reserve;
			self.weapons[weapon_index].weapon_skin = weapons_storage[i].weapon_skin;
			self.weapons[weapon_index].is_mulekick_weapon = weapons_storage[i].is_mulekick_weapon;
			weapon_index++;
		}
	}
};

void Weapon_RemoveWeapon(float slot)
{
	self.weapons[slot].is_mulekick_weapon = false;
	Weapon_AssignWeapon(slot, 0, 0, 0);
	Weapon_FixUpList();
};

// Re-enable fast array optimization.
#ifndef FTE

#pragma flag enable fastarrays

#endif // FTE
