/*
	server/clientfuncs.qc

	Used to communicate between server and client

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
string(string asset) convert_old_asset_path;

void() NotifyGameEnd =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_ENDGAME);
	multicast('0 0 0', MULTICAST_ALL);

#endif // FTE
}

void SetUpdate(entity client, float type, float val1, float val2, float val3)
{
#ifdef FTE

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

#endif // FTE
}

#ifdef FTE
void(entity to, float type, float cost, float weapon) useprint = {
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_USEPRINT);
	WriteByte(MSG_MULTICAST, type);
	WriteShort(MSG_MULTICAST, cost);
	WriteByte(MSG_MULTICAST, weapon);
	msg_entity = to;
	multicast('0 0 0', MULTICAST_ONE);
}

void(string track_name) songegg =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_SONGPLAY);
	WriteString(MSG_MULTICAST, track_name);
	multicast('0 0 0', MULTICAST_ALL);
};
#endif // FTE

void(vector org) CallExplosion = {
#ifndef FTE

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

#endif // FTE
}

void NotifyNewRound(float to) {
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_NEWROUND);
	WriteByte(MSG_MULTICAST, to);
	multicast('0 0 0', MULTICAST_ALL);

#endif // FTE
}

void SetRound(entity client, float to) {
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_SETROUND);
	WriteByte(MSG_MULTICAST, to);
	msg_entity = client;
	multicast('0 0 0', MULTICAST_ONE);

#endif // FTE
}

void SetPerk(entity client, float to)
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_PERK);
	WriteLong(MSG_MULTICAST, to);
	msg_entity = client;
	multicast('0 0 0', MULTICAST_ONE);

#endif // FTE
}

void(float to) SwitchWeapon =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_WEAPONCHANGE);
	WriteByte(MSG_MULTICAST, to);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);

	// hotfix for weapon2models not reseting
	self.weapon2model = GetWeapon2Model(to);

#endif // FTE
}

void(string to, float skin) UpdateVmodel =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATEVMODEL);
	WriteString(MSG_MULTICAST, to);
	WriteByte(MSG_MULTICAST, skin);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);

#endif // FTE
}

void(string to, float skin) UpdateV2model =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_UPDATEV2MODEL);
	WriteString(MSG_MULTICAST, to);
	WriteByte(MSG_MULTICAST, skin);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);

#endif // FTE
}

void(float index, float state) ChangeReviveIconState =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_REVIVECHANGE);
	WriteByte(MSG_MULTICAST, index);
	WriteByte(MSG_MULTICAST, state);
	multicast('0 0 0', MULTICAST_ALL);

#endif // FTE
}

void(float index, vector org) EnableReviveIcon =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_REVIVEON);
	WriteByte(MSG_MULTICAST, index);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	multicast('0 0 0', MULTICAST_ALL);

#endif // FTE
}

void(float index) DisableReviveIcon =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_REVIVEOFF);
	WriteByte(MSG_MULTICAST, index);
	multicast('0 0 0', MULTICAST_ALL);

#endif // FTE
}

void(entity who, float broadcast_time, float type, string str) BroadcastMessageToClient =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BROADCAST);
	WriteByte(MSG_MULTICAST, broadcast_time);
	WriteByte(MSG_MULTICAST, type);
	WriteString(MSG_MULTICAST, str);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);

#endif // FTE
}

// FIXME: basically a copy of CL_SendWeaponFire but for FTE
void(entity who, float weapon) SendWeaponRecoil =
{
#ifdef FTE

	vector Wep_Recoil;
	Wep_Recoil = GetWeaponRecoil(weapon);

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_WEAPONRECOIL);
	WriteCoord (MSG_MULTICAST, Wep_Recoil_x);
	WriteCoord (MSG_MULTICAST, Wep_Recoil_y);
	WriteCoord (MSG_MULTICAST, Wep_Recoil_z);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);

#endif // FTE
}

void(float broadcast_time, float type, string str) BroadcastMessage =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BROADCAST);
	WriteByte(MSG_MULTICAST, broadcast_time);
	WriteByte(MSG_MULTICAST, type);
	WriteString(MSG_MULTICAST, str);
	multicast('0 0 0', MULTICAST_ALL);

#endif // FTE
}

void(float count) UpdatePlayerCount = {
#ifdef FTE
	if (count == 0)
		return;
	else {
		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_PLAYERUPDATE);
		WriteByte(MSG_MULTICAST, count);
		multicast('0 0 0', MULTICAST_ALL);
	}

#endif // FTE
}

void(float newtime, float newtype, entity change) PromptLevelChange =
{
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BLACKOUT);
	WriteByte(MSG_MULTICAST, newtime);
	WriteByte(MSG_MULTICAST, newtype);
	msg_entity = change;
	multicast('0 0 0', MULTICAST_ONE);

#endif // FTE
}

#ifdef FTE
void(entity who) grenade_pulse =
{

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_GRENADEPULSE);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);

}
#endif // FTE

#ifdef FTE

void(entity who) nzp_bettyprompt =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BETTYPROMPT);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);
}

#endif // FTE

void(entity who) UpdatePunchangle =
{
#ifdef FTE

	// naievil -- shit logic lol...but result looks clean as fuck...
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

#endif // FTE
}

#ifdef FTE
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
#endif // FTE

void (float achievement_id, optional entity who) GiveAchievement =
{
#ifndef FTE

	// temp
	if (achievement_id > 4)
		return;

#endif // FTE

	// this is an achievement specific to an individual
	if ((who && who != world) || player_count == 0) {
		if (player_count == 0) who = find(world, classname, "player");

#ifndef FTE

		achievement(who, achievement_id);

#else

		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_ACHIEVEMENT);
		WriteByte(MSG_MULTICAST, achievement_id);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);

#endif // FTE

	} else {

#ifndef FTE

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

#endif // FTE
	}
}

#ifdef FTE

void CSQC_SendChatMessage(float player_id, string message) {
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_CHATMESSAGE);
	WriteByte(MSG_MULTICAST, num_for_edict(self) - 1);
	WriteByte(MSG_MULTICAST, player_id);
	WriteString(MSG_MULTICAST, message);
	multicast('0 0 0', MULTICAST_ALL);
}

/*
=================
Player_SendEntity

    Networks the player info
=================
*/
float Player_SendEntity( entity ePVEnt, float flChanged ) {
    WriteByte( MSG_ENTITY, 1 );
    WriteCoord( MSG_ENTITY, self.origin_x ); // Position X
    WriteCoord( MSG_ENTITY, self.origin_y ); // Position Y
    WriteCoord( MSG_ENTITY, self.origin_z ); // Position Z
    WriteAngle( MSG_ENTITY, self.angles_x ); // Angle X
    WriteAngle( MSG_ENTITY, self.angles_y ); // Angle Y
    WriteAngle( MSG_ENTITY, self.angles_z ); // Angle Z
    WriteShort( MSG_ENTITY, self.velocity_x ); // Velocity X
    WriteShort( MSG_ENTITY, self.velocity_y ); // Velocity X
    WriteShort( MSG_ENTITY, self.velocity_z ); // Velocity X
	WriteByte( MSG_ENTITY, self.playernum ); // Player ID
	WriteShort( MSG_ENTITY, self.modelindex ); // Player Model
	WriteByte( MSG_ENTITY, self.frame ); // Player's Frame
	WriteShort( MSG_ENTITY, self.movetype ); // Player Movetype
    WriteShort( MSG_ENTITY, self.flags ); // Flags, important for physics
	WriteByte( MSG_ENTITY, self.stance ); // Player Stance
	WriteFloat( MSG_ENTITY, self.points ); // Player Score
	WriteShort( MSG_ENTITY, self.kills ); // Player Kills
    return TRUE;
}

#endif // FTE

void (float achievement_id, float progress_value, optional entity who) UpdateAchievementProgress =
{

#ifndef FTE

	// temp
	if (achievement_id > 4)
		return;

#endif // FTE

	// this is a progress update specific to an individual
	if ((who && who != world) || player_count == 0) {
		if (player_count == 0) who = find(world, classname, "player");

#ifndef FTE

		//achievement_progress(who, achievement_id, progress_value);

#else

		WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
		WriteByte(MSG_MULTICAST, EVENT_ACHIEVEMENTPROGRESS);
		WriteByte(MSG_MULTICAST, achievement_id);
		WriteFloat(MSG_MULTICAST, progress_value);
		msg_entity = who;
		multicast('0 0 0', MULTICAST_ONE);

#endif // FTE

	} else {

#ifndef FTE

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

#endif // FTE
	}

}

#ifdef FTE

void(entity who, float version) nzp_setdoubletapver =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_DOUBLETAPUPDATE);
	WriteByte(MSG_MULTICAST, version);
	msg_entity = who;
	multicast('0 0 0', MULTICAST_ONE);
};

#endif // FTE

void(vector org) Effect_Fire =
{

#ifndef FTE

	particle (self.origin, v_up*8, 111, 0);

#else

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_FLAME);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	multicast('0 0 0', MULTICAST_ALL);

	//te_flamejet(self.origin, v_up*8, 10);

#endif // FTE

};

// *****************************************
// Unrelated to engine, but custom functions
// *****************************************

// "Removes" an entity that is placed back on restart.
void(entity ent) Ent_FakeRemove =
{
	ent.entity_removed = true;
	ent.oldmodel = ent.model;
	ent.oldorigin = ent.origin;
	ent.bbmins = ent.mins;
	ent.bbmaxs = ent.maxs;
	ent.sprintflag = ent.solid;

	ent.solid = SOLID_NOT;
	setsize(ent, '0 0 0', '0 0 0');
	setmodel(ent, "");
}

void(string modelname) Precache_Set = // Precache model, and set myself to it
{
	modelname = convert_old_asset_path(modelname);
    precache_model(modelname);
    setmodel(self, modelname);
};

float() crandom =
{
	return 2*(random() - 0.5);
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
};

float(entity them, entity me) PlayerIsLooking =
{
	float ret = false;
	float old_solid = me.solid;
	me.solid = SOLID_BBOX;
	setorigin(me, me.origin);

	vector source;
	makevectors (them.v_angle);
	source = them.origin + them.view_ofs;

	// Standard 'are we facing' test..
	traceline(source, source + v_forward*50, 0, them);

	// We're inside of an object.. is it the target?
	if (trace_startsolid) {
		if (v_forward*normalize(me.origin - them.origin) > 0.7)
			ret = true;
	} else if (trace_ent == me) {
		ret = true;
	}

	me.solid = old_solid;
	setorigin(me, me.origin);
	return ret;
};