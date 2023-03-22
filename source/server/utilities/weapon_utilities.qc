/*
	server/utilities/weapon_utilities.qc

	Contains some wrapped or easy access functions to streamline weapon
    behaviors a bit.

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

//
// Weapon_GetPlayerAmmoInSlot(person, slot)
// Returns the reserve ammo the player has in a weapon slot.
//
float(entity person, float slot) Weapon_GetPlayerAmmoInSlot =
{
	switch(slot) {
		case 1: return person.currentammo; break;
		case 2: return person.secondaryammo; break;
		case 3: return person.thirdammo; break;
		default: return 0; break;
	}
}

//
// Weapon_SetPlayerAmmoInSlot(person, slot, ammo)
// Sets the player's reserve ammo in a slot to param3.
//
void(entity person, float slot, float ammo) Weapon_SetPlayerAmmoInSlot =
{
	switch(slot) {
		case 1: person.currentammo = ammo; break;
		case 2: person.secondaryammo = ammo; break;
		case 3: person.thirdammo = ammo; break;
		default: return; break;
	}
};

//
// Weapon_PlayerHasWeapon(peron, comparison, include_pap)
// Checks to see if the Player is holding a weapon in any
// of their three slots. `include_pap` dictates whether to
// consider Pack-A-Punch'd varients. Returns 1, 2, 3 depending
// on the slot the weapon is contained in.
//
float(entity person, float comparison, float include_pap) Weapon_PlayerHasWeapon =
{
	// Storage.
	float first, second, third;

	// If we're including pap'd weapons, just convert the weapon set to the base
	// ones to save on comparison checks.
	if (include_pap == true) {
		first = EqualNonPapWeapon(person.weapon);
		second = EqualNonPapWeapon(person.secondaryweapon);
		third = EqualNonPapWeapon(person.thirdweapon);
	} else {
		first = person.weapon;
		second = person.secondaryweapon;
		third = person.thirdweapon;
	}

	// Now do the comparisons
	if (first == comparison)
		return 1;
	if (second == comparison)
		return 2;
	if (third == comparison)
		return 3;

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
}

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
}
