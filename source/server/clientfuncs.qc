/*
	server/clientfuncs.qc

	Used to communicate between server and client

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

#ifdef FTE

//
// FTE_RunParticleEffect(target, particle_type, position, optional_field, optional_entity)
// Fires a CSQC_EVENT_PARTICLE to clients specified (or
// world for global).
//
void(entity target, float particle_type, vector position, float optional_field, entity optional_entity) FTE_RunParticleEffect =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_PARTICLE);
	WriteByte(MSG_MULTICAST, particle_type);
	WriteCoord(MSG_MULTICAST, position_x);
	WriteCoord(MSG_MULTICAST, position_y);
	WriteCoord(MSG_MULTICAST, position_z);
	WriteByte(MSG_MULTICAST, optional_field);
	WriteEntity(MSG_MULTICAST, optional_entity);

	if (target != world) {
		msg_entity = target;
		multicast(position, MULTICAST_ONE);
	} else {
		multicast(position, MULTICAST_ALL);
	}
};

#endif // FTE

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
void(float mode, entity to) ReportMapMode = {
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_MAPTYPE);
	WriteByte(MSG_MULTICAST, mode);
	msg_entity = to;
	multicast('0 0 0', MULTICAST_ONE);
}

void(entity to, float type, float cost, float weapon) useprint = {
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_USEPRINT);
	WriteByte(MSG_MULTICAST, type);
	WriteShort(MSG_MULTICAST, cost);
	WriteByte(MSG_MULTICAST, weapon);
	msg_entity = to;
	multicast('0 0 0', MULTICAST_ONE);
}

void(string track_name) songegg =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_MUSICSTREAM);
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

	FTE_RunParticleEffect(world, CSQC_PART_EXPLOSION, org, 0, world);

#endif // FTE
}

#ifdef FTE

//
// FTE_IncrementRound()
// Alerts all clients of new value for Rounds.
// -- RELIABLE --
//
void(float round) FTE_IncrementRound =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_ROUNDCHANGE);
	WriteByte(MSG_MULTICAST, round);
	multicast('0 0 0', MULTICAST_ALL_R);
};


#endif // FTE

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

void(entity who, float weapon) CL_SendWeaponFire =
{
	float recoil_return_time = getWeaponRecoilReturn(weapon);
	vector weapon_recoil = GetWeaponRecoil(weapon);

	msg_entity = who;

#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_WEAPONRECOIL);
	WriteCoord (MSG_MULTICAST, weapon_recoil_x);
	WriteCoord (MSG_MULTICAST, weapon_recoil_y);
	WriteCoord (MSG_MULTICAST, weapon_recoil_z);
	multicast('0 0 0', MULTICAST_ONE);

#else

	WriteByte(MSG_ONE, SVC_WEAPONFIRE);
	WriteLong(MSG_ONE, recoil_return_time); // FIXME: A long for this is overkill.
	WriteCoord(MSG_ONE, weapon_recoil_x);
	WriteCoord(MSG_ONE, weapon_recoil_y);
	WriteCoord(MSG_ONE, weapon_recoil_z);

#endif // FTE

	self.recoil_delay = 60/recoil_return_time + time;
}

#ifdef FTE

//
// FTE_BroadcastMessage(target, broadcast_type, broadcast_type, player_id)
// Sends a CSQC Event to display text on the screen for the
// desired clients. Use 'world' to send to everyone.
// -- RELIABLE --
//
void(entity target, float broadcast_type, float broadcast_time, float player_id) FTE_BroadcastMessage =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_BROADCASTMESSAGE);
	WriteByte(MSG_MULTICAST, broadcast_type);
	WriteByte(MSG_MULTICAST, broadcast_time);
	WriteByte(MSG_MULTICAST, player_id);

	if (target != world) {
		msg_entity = target;
		multicast('0 0 0', MULTICAST_ONE_R);
	} else {
		multicast('0 0 0', MULTICAST_ALL_R);
	}
};

//
// nzp_screenflash(target, color, duration, type)
// FTE equivalent of nzp_screenflash builtin.
//
void(entity target, float color, float duration, float type) nzp_screenflash =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_SCREENFLASH);
	WriteByte(MSG_MULTICAST, color);
	WriteByte(MSG_MULTICAST, duration);
	WriteByte(MSG_MULTICAST, type);

	if (target != world) {
		msg_entity = target;
		multicast('0 0 0', MULTICAST_ONE);
	} else {
		multicast('0 0 0', MULTICAST_ALL);
	}
};

#endif // FTE

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

#ifdef FTE

//
// FTE_InterpolatePunchAngle(person)
// Punch Angle interpolation from our native sourceports,
// handled in SSQC for FTE.
//
void(entity person) FTE_InterpolatePunchAngle =
{
	vector last_punchangle = person.punchangle;
	float lerp_factor = 0.9*frametime; // It's fine that this is server-dependent, since it's server-executed..

	// Early-out: Let's not spam fabs calls if we have no punchangle.
	if (person.punchangle_x == 0 && person.punchangle_y == 0)
		return;

	// Begin interpolation.
	for(int i = 0; i < 2; i++) {
		float difference = last_punchangle[i] * lerp_factor;

		if (fabs(person.punchangle[i]) > 0.01) {
			if (person.punchangle[i] >= difference)
				person.punchangle[i] -= difference;
			else if (person.punchangle[i] <= -difference)
				person.punchangle[i] -= difference;
			else
				person.punchangle[i] = 0;
		} else {
			person.punchangle[i] = 0;
		}
	}
};

//
// FTE_UpdateDynamicFOV(person)
// Context-sensitive adjustment of client's viewzoom
// factor.
//
void(entity person) FTE_UpdateDynamicFOV =
{
	// Early-out if client is not zoomed in at all
	// and viewzoom is correctly applied
	if (!person.zoom && person.viewzoom == 1)
	 	return;

	// Calculate viewzoom FOV differential
	float viewzoom_differential = 1 - (0.018*GetWeaponZoomAmount(person.weapon));
	float has_scoped_weapon = WepDef_HasSniperScore(person.weapon);

	// Sniper scope-in: Force-set as soon as the Scope draws
	if (person.zoom == 2) {
		person.viewzoom = viewzoom_differential;
		return;
	}
	// Force-set viewzoom back to one if client is holding a scoped
	// weapon and need their viewzoom adjusted.
	else if (person.viewzoom != 1 && has_scoped_weapon) {
		person.viewzoom = 1;
		return;
	} else if (has_scoped_weapon) {
		return;
	}

	// Utilize a sigmoid curve to minimize motion sickness.
	float sigmoid_input, sigmoid_output;
	float viewzoom_adjustment_rate;

	// If we're Aiming down the Sight and viewzoom has not reached it's end
	if (person.zoom == 1 && person.viewzoom != viewzoom_differential) {
		sigmoid_input = (person.viewzoom - viewzoom_differential) * 10;
		sigmoid_output = 1 / (1 + exp(-sigmoid_input));
		viewzoom_adjustment_rate = 0.06 * (sigmoid_output + 0.5) * (frametime*20);

		if (person.viewzoom > viewzoom_differential) {
			person.viewzoom -= viewzoom_adjustment_rate;
			if (person.viewzoom < viewzoom_differential)
				person.viewzoom = viewzoom_differential;
		} else {
			person.viewzoom = viewzoom_differential;
		}
	}
	// If we're not Aiming down the Sight and viewzoom is not reset
	else if (person.zoom != 1 && person.viewzoom != 1) {
		// We can zoom out at a constant rate without consequence.
		person.viewzoom += 0.85 * frametime;
		if (person.viewzoom > 1)
			person.viewzoom = 1;
	}
};

#endif // FTE

#ifdef FTE

//
// nzp_maxammo()
// FTE equivalent of nzp_maxammo builtin.
//
void() nzp_maxammo =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_MAXAMMOTEXT);
	multicast('0 0 0', MULTICAST_ALL);
};

//
// nzp_setplayername(target, player_name)
// FTE equivalent of nzp_setplayername builtin.
//
void(entity target, string player_name) nzp_setplayername =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_PLAYERNAME);
	WriteString(MSG_MULTICAST, player_name);
	msg_entity = target;
	multicast('0 0 0', MULTICAST_ONE);
};

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
		WriteByte(MSG_MULTICAST, CSQC_EVENT_GIVEACHIEVEMENT);
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
		WriteByte(MSG_MULTICAST, CSQC_EVENT_GIVEACHIEVEMENT);
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
	WriteByte( MSG_ENTITY, self.is_in_menu ); // Player is in a Menu State
    return TRUE;
}

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

	FTE_RunParticleEffect(world, CSQC_PART_FIRE, org, 0, world);

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
	modelname = Compat_ConvertOldAssetPath(modelname);
    precache_model(modelname);
    setmodel(self, modelname);
};

float() crandom =
{
	return 2*(random() - 0.5);
}

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