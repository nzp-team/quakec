/*
	server/clientfuncs.qc

	used to communicate between server and client

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

void SetUpdate(entity client, float type, float val1, float val2, float val3)
{
	#ifndef PSP
	#ifndef NX
	#ifndef CTR

	if (type != 2)
	{
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_UPDATE);
		WriteByte(MSG_MULTICAST, type); // UT_HUD
		WriteByte(MSG_MULTICAST, val1);
		WriteByte(MSG_MULTICAST, val2);
		WriteByte(MSG_MULTICAST, val3); // misc flags/vars for later if needed
		msg_entity = client;
		multicast('0 0 0', MULTICAST_ONE);
	}
	else
	{
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_UPDATE);
		WriteByte(MSG_MULTICAST, type); // UT_ROUNDS_CHANGE
		WriteByte(MSG_MULTICAST, val1);
		WriteByte(MSG_MULTICAST, val2);
		WriteByte(MSG_MULTICAST, val3); // misc flags/vars for later if needed
		multicast('0 0 0', MULTICAST_ALL);
	}
	#endif
	#endif
	#endif
}

#ifndef PSP
#ifndef NX
#ifndef CTR
void(entity to, float type, float cost, float weapon) useprint = {
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_USEPRINT);
	WriteByte(MSG_MULTICAST, type);
	WriteShort(MSG_MULTICAST, cost);
	WriteByte(MSG_MULTICAST, weapon);
	msg_entity = to;
	multicast('0 0 0', MULTICAST_ONE);
}
#endif
#endif
#endif

void(vector org) CallExplosion = {
    #ifndef PC
    WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_EXPLOSION);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
    #else
    WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_EXPLOSION);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	multicast('0 0 0', MULTICAST_ALL);
    #endif
}

void NotifyNewRound(float to) {
	#ifndef PSP
	#ifndef NX
	#ifndef CTR

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_NEWROUND);
	WriteByte(MSG_MULTICAST, to);
	multicast('0 0 0', MULTICAST_ALL);

	#endif
	#endif
	#endif
}

void SetRound(entity client, float to) {
	#ifndef PSP
	#ifndef NX
	#ifndef CTR

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_SETROUND);
	WriteByte(MSG_MULTICAST, to);
	msg_entity = client;
	multicast('0 0 0', MULTICAST_ONE);

	#endif
	#endif
	#endif
}

void SetPerk(entity client, float to)
{
	#ifndef PSP
	#ifndef NX
	#ifndef CTR

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_PERK);
	WriteLong(MSG_MULTICAST, to);
	msg_entity = client;
	multicast('0 0 0', MULTICAST_ONE);

	#endif
	#endif
	#endif
}

void(float to) SwitchWeapon =
{
	#ifndef PSP
	#ifndef NX
	#ifndef CTR

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_WEAPONCHANGE);
	WriteByte(MSG_MULTICAST, to);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);

	// hotfix for weapon2models not reseting
	self.weapon2model = GetWeapon2Model(to);

	#endif
	#endif
	#endif
}

void(string to, float skin) UpdateVmodel =
{
	#ifndef PSP
	#ifndef NX
	#ifndef CTR

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATEVMODEL);
	WriteString(MSG_MULTICAST, to);
	WriteByte(MSG_MULTICAST, skin);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);

	#endif
	#endif
	#endif
}

void(string to, float skin) UpdateV2model =
{
	#ifndef PSP
	#ifndef NX
	#ifndef CTR

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATEV2MODEL);
	WriteString(MSG_MULTICAST, to);
	WriteByte(MSG_MULTICAST, skin);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);
	#endif
	#endif
	#endif
}

void(float broadcast_time, float type) BroadcastMessage =
{
	#ifndef PSP
	#ifndef NX
	#ifndef CTR
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BROADCAST);
	WriteByte(MSG_MULTICAST, broadcast_time);
	WriteByte(MSG_MULTICAST, type);
	multicast('0 0 0', MULTICAST_ALL);

	#endif
	#endif
	#endif
}

void(float playernum, float points, float am, float kills, string name, entity person) UpdatePlayerPoints =
{
	#ifndef PSP
	#ifndef NX
	#ifndef CTR
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_POINTUPDATE);
		WriteByte(MSG_MULTICAST, playernum);
		WriteLong(MSG_MULTICAST, points);
		WriteLong(MSG_MULTICAST, am);
		WriteLong(MSG_MULTICAST, kills);
		WriteString(MSG_MULTICAST, name);
		msg_entity = person;
		multicast('0 0 0', MULTICAST_ONE);
	}
	else {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_POINTUPDATE);
		WriteByte(MSG_MULTICAST, playernum);
		WriteLong(MSG_MULTICAST, points);
		WriteLong(MSG_MULTICAST, am);
		WriteLong(MSG_MULTICAST, kills);
		WriteString(MSG_MULTICAST, name);
		multicast('0 0 0', MULTICAST_ALL);
	}

	#endif
	#endif
	#endif
}

void(float count) UpdatePlayerCount = {
	#ifndef PSP
	#ifndef NX
	#ifndef CTR
	if (count == 0)
		return;
	else {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_PLAYERUPDATE);
		WriteByte(MSG_MULTICAST, count);
		multicast('0 0 0', MULTICAST_ALL);
	}

	#endif
	#endif
	#endif
}

void(float newtime, float newtype, entity change) PromptLevelChange =
{
	#ifndef PSP
	#ifndef NX
	#ifndef CTR

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BLACKOUT);
	WriteByte(MSG_MULTICAST, newtime);
	WriteByte(MSG_MULTICAST, newtype);
	msg_entity = change;
	multicast('0 0 0', MULTICAST_ONE);

	#endif
	#endif
	#endif
}

void(entity who) UpdatePunchangle =
{

	// naievil -- shit logic lol...but result looks clean as fuck...
	#ifndef PSP
	#ifndef NX
	#ifndef CTR
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_PUNCHANGLE);
	WriteCoord(MSG_MULTICAST, who.punchangle_x);
	WriteCoord(MSG_MULTICAST, who.punchangle_y);
	WriteCoord(MSG_MULTICAST, who.punchangle_z);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);

	vector tempv = who.punchangle;

	if (fabs(who.punchangle_x) > 0.01) {
		if (who.punchangle_x >= 0.05*tempv_x)
			who.punchangle_x -= 0.05*tempv_x;
		else if (who.punchangle_x <= -0.05*tempv_x)
			who.punchangle_x -= 0.05*tempv_x;
		else
			who.punchangle_x = 0;
	} else
		who.punchangle_x = 0;

	if (fabs(who.punchangle_y) > 0.01) {
		if (who.punchangle_y >= 0.05*tempv_y)
			who.punchangle_y -= 0.05*tempv_y;
		else if (who.punchangle_y <= -0.05*tempv_y)
			who.punchangle_y -= 0.05*tempv_y;
		else
			who.punchangle_y = 0;
	} else
		who.punchangle_y = 0;

	if (fabs(who.punchangle_z) > 0.01) {
		if (who.punchangle_z >= 0.05*tempv_z)
			who.punchangle_z -= 0.05*tempv_z;
		else if (who.punchangle_z <= -0.05*tempv_z)
			who.punchangle_z -= 0.05*tempv_z;
		else
			who.punchangle_z = 0;
	} else
		who.punchangle_z = 0;

	#endif
	#endif
	#endif
}

#ifndef PSP
#ifndef NX
#ifndef CTR
void(string h, float h2, entity who) pushHUD = {
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_HUDUPDATE);
		WriteString(MSG_MULTICAST, h);
		WriteByte(MSG_MULTICAST, h2);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_WEAPONUPDATE);
		WriteString(MSG_MULTICAST, h);
		WriteByte(MSG_MULTICAST, h2);
		multicast('0 0 0', MULTICAST_ALL);
	}
}

void (float wepnum, string wepname, string wvmodel, float mag, float reserve, string ads, float min, float max, string flash, float flashsize, string v2, float isd, entity who) sendCustomWeapon = {
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_WEAPONUPDATE);
		WriteByte(MSG_MULTICAST, wepnum);
		WriteString(MSG_MULTICAST, wepname);
		WriteString(MSG_MULTICAST, wvmodel);
		WriteByte(MSG_MULTICAST, mag);
		WriteByte(MSG_MULTICAST, reserve);
		WriteString(MSG_MULTICAST, ads);
		WriteByte(MSG_MULTICAST, min);
		WriteByte(MSG_MULTICAST, max);
		WriteString(MSG_MULTICAST, flash);
		WriteByte(MSG_MULTICAST, flashsize);
		WriteString(MSG_MULTICAST, v2);
		WriteByte(MSG_MULTICAST, isd);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		WriteByte(MSG_ALL, SVC_CGAMEPACKET);
		WriteByte(MSG_ALL, EVENT_WEAPONUPDATE);
		WriteByte(MSG_ALL, wepnum);
		WriteString(MSG_ALL, wepname);
		WriteString(MSG_ALL, wvmodel);
		WriteByte(MSG_ALL, mag);
		WriteByte(MSG_ALL, reserve);
		WriteString(MSG_ALL, ads);
		WriteByte(MSG_ALL, min);
		WriteByte(MSG_ALL, max);
		WriteString(MSG_ALL, flash);
		WriteByte(MSG_ALL, flashsize);
		WriteString(MSG_ALL, v2);
		WriteByte(MSG_ALL, isd);
	}
}

void(string msg, entity who) ScrollText = {
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_SCROLLTEXT);
		WriteString(MSG_MULTICAST, msg);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_SCROLLTEXT);
		WriteString(MSG_MULTICAST, msg);
		multicast('0 0 0', MULTICAST_ALL);
	}
}

void(string chaptertitle, string location, string date, string person, entity who) WorldText = {
	if (player_count == 0) {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_WORLDDATA);
		WriteString(MSG_MULTICAST, chaptertitle);
		WriteString(MSG_MULTICAST, location);
		WriteString(MSG_MULTICAST, date);
		WriteString(MSG_MULTICAST, person);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_WORLDDATA);
		WriteString(MSG_MULTICAST, chaptertitle);
		WriteString(MSG_MULTICAST, location);
		WriteString(MSG_MULTICAST, date);
		WriteString(MSG_MULTICAST, person);
		multicast('0 0 0', MULTICAST_ALL);
	}
}
#endif
#endif
#endif

#ifndef NX
#ifndef CTR
void (float achievement_id, optional entity who) GiveAchievement =
{
#ifdef PSP
	// temp
	if (achievement_id > 4)
		return;
#endif // PSP

	// this is an achievement specific to an individual
	if ((who && who != world) || player_count == 0) {
		if (player_count == 0) who = find(world, classname, "player");
#ifdef PSP
		achievement(who, achievement_id);
#else
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_ACHIEVEMENT);
		WriteByte(MSG_MULTICAST, achievement_id);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
#endif // PSP
	} else {
#ifdef PSP
		entity players;
		players = find(world, classname, "player");
		while(players != world) {
			achievement(players, achievement_id);
			players = find(players, classname, "player");
		}
#else
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_ACHIEVEMENT);
		WriteByte(MSG_MULTICAST, achievement_id);
		multicast('0 0 0', MULTICAST_ALL);
#endif // PSP
	}
}

void (float achievement_id, float progress_value, optional entity who) UpdateAchievementProgress =
{
#ifdef PSP
	// temp
	if (achievement_id > 4)
		return;
#endif // PSP
	// this is a progress update specific to an individual
	if ((who && who != world) || player_count == 0) {
		if (player_count == 0) who = find(world, classname, "player");
#ifdef PSP
		//achievement_progress(who, achievement_id, progress_value);
#else
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_ACHIEVEMENTPROGRESS);
		WriteByte(MSG_MULTICAST, achievement_id);
		WriteFloat(MSG_MULTICAST, progress_value);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);
#endif // PSP
	} else {
#ifdef PSP
		entity players;
		players = find(world, classname, "player");
		while(players != world) {
			//achievement_progress(players, achievement_id, progress_value);
			players = find(players, classname, "player");
		}
#else
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_ACHIEVEMENTPROGRESS);
		WriteByte(MSG_MULTICAST, achievement_id);
		WriteFloat(MSG_MULTICAST, progress_value);
		multicast('0 0 0', MULTICAST_ALL);
#endif // PSP
	}
}
#endif // CTR
#endif // NX

// *****************************************
// Unrelated to engine, but custom functions
// *****************************************

inline void(string modelname) Precache_Set = // Precache model, and set myself to it
{
    precache_model(modelname);
    setmodel(self, modelname);
};


float(entity who, entity target) isFacing =
{
	float who_angle = who.angles_y;
	float target_angle = target.angles_y;

	float difference_angle = target_angle - who_angle;

	#ifdef PSP
	if (difference_angle < -45) {
		difference_angle += 360;
	}
	#endif

	// 180 = directly facing each other, 30 degree buffer.
	if (difference_angle <= 210 && difference_angle >= 150)
		return true;

	return false;
}

float() crandom =
{
	return 2*(random() - 0.5);
}

void WeaponSwitch(entity player) {
	float wep, cmag, cmag2, cammo;

	wep = other.weapon;
	other.weapon = other.secondaryweapon;
	other.secondaryweapon = wep;

	cmag = other.currentmag;
	other.currentmag = other.secondarymag;
	other.secondarymag = cmag;

	cmag2 = other.currentmag2;
	other.currentmag2 = other.secondarymag2;
	other.secondarymag2 = cmag2;

	cammo = other.currentammo;
	other.currentammo = other.secondaryammo;
	other.secondaryammo = cammo;

	entity tempe = self;
	self = player;
	SwitchWeapon(other.weapon);
	self = tempe;
}

void(entity person, float expamt, float doublepoint) addmoney =
{
	if (person.classname != "player" || person.downed)
		return;

	if (expamt > 0 && doublepoint == TRUE && x2_finished > time) {
		expamt *= 2;
		person.score += expamt;
	}

	// Combine the positive score with the powerup score tally
	if (expamt > 0)
		total_powerup_points += expamt;

	person.points += expamt;

	UpdatePlayerPoints(person.playernum, person.points, expamt, person.kills, person.netname, person);
};

//
// Util_GetPlayerAmmoInSlot(person, slot)
// Returns the reserve ammo the player has in a weapon slot.
//
float(entity person, float slot) Util_GetPlayerAmmoInSlot =
{
	switch(slot) {
		case 1: return person.currentammo;
		case 2: return person.secondaryammo;
		case 3: return person.thirdammo;
		default: return 0;
	}
}

//
// Util_SetPlayerAmmoInSlot(person, slot, ammo)
// Sets the player's reserve ammo in a slot to param3.
//
void(entity person, float slot, float ammo) Util_SetPlayerAmmoInSlot =
{
	switch(slot) {
		case 1: person.currentammo = ammo;
		case 2: person.secondaryammo = ammo;
		case 3: person.thirdammo = ammo;
		default: return;
	}
};

//
// Util_PlayerHasWeapon(peron, comparison, include_pap)
// Checks to see if the Player is holding a weapon in any
// of their three slots. `include_pap` dictates whether to
// consider Pack-A-Punch'd varients. Returns 1, 2, 3 depending
// on the slot the weapon is contained in.
//
float(entity person, float comparison, float include_pap) Util_PlayerHasWeapon =
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
// Util_WeaponIsSemiAutomatic(float weapon)
// Checks weapon firetypes and returns true if intended
// to be semi-automatic.
//
float(float weapon) Util_WeaponIsSemiAutomatic =
{
	float firetype = GetFiretype(weapon);

	// Valid firetypes
	if (firetype == FIRETYPE_SEMIAUTO || firetype == FIRETYPE_GRENADE ||
	firetype == FIRETYPE_TESLA)
		return true;

	return false;
}

//
// Util_WeaponFiresTraceshot(weapon)
// Simply returns true if given weapon's firetype requires a
// firetrace to be used properly.
//
float(float weapon) Util_WeaponFiresTraceshot =
{
	float firetype = GetFiretype(weapon);

	// Valid firetypes
	if (firetype == FIRETYPE_FULLAUTO || firetype == FIRETYPE_SEMIAUTO)
		return true;

	return false;
}