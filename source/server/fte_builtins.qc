/*
	server/fte_builtins.qc

	FTE Implementation of Vril-Engine prog builtins

	Copyright (C) 2021-2025 NZ:P Team

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
// NUM_FOR_EDICT(edict)
// Accurate reimplementation of Vril
// NUM_FOR_EDICT with edict_num acting
// as a guard.
//
float NUM_FOR_EDICT(entity edict)
{
    float entnum = num_for_edict(edict);
    edict_num(entnum);

    return entnum;
}

//
// nzp_achievement(client, achievement_id)
// Awards achievement by sending approval to client.
//
void(entity client, float achievement_id) nzp_achievement =
{
    float entnum;
    entnum = NUM_FOR_EDICT(client);

    if (entnum < 1 || entnum > cvar("maxclients")) {
        if (cvar("developer")) {
            print("tried to unlock ach to a non-client\n");
            return;
        }
    }

    WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_GIVEACHIEVEMENT);
	WriteByte(MSG_MULTICAST, achievement_id);
	msg_entity = client;
	multicast('0 0 0', MULTICAST_ONE);
};

//
// nzp_setclientmode(gamemode)
// Sends info to Client about the current Game Mode
//
void(float gamemode) nzp_setclientmode =
{
	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, CSQC_EVENT_SETGAMEMODE);
	WriteByte(MSG_MULTICAST, gamemode);
	multicast('0 0 0', MULTICAST_ALL);
};

#endif // FTE