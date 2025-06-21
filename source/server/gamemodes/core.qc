/*
	server/gamemodes/core.qc

	The back-end for Game Mode support.

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

float current_gamemode;

#define PARTY_MODE_SONG_COUNT   4

string gamemode_track_names[PARTY_MODE_SONG_COUNT] = {"glory_days", "ascend", "flying_temple", "starting_over"};
float gamemode_track_durations[PARTY_MODE_SONG_COUNT] = {214, 222, 133, 287};
float gamemode_track_endtime;

//
// Gamemode_IsPartyMode()
// Returns TRUE if current gamemode
// is a party mode, for use with party music.
//
float() Gamemode_IsPartyMode =
{
    switch(current_gamemode) {
        case GAMEMODE_GUNGAME: return true;
        case GAMEMODE_STICKSNSTONES: return true;
        default: return false;
    }

    return false;
};

//
// Gamemode_Init()
// Called at server spawn, runs the relevant
// game mode's init function.
//
void() Gamemode_Init =
{
    current_gamemode = cvar("sv_gamemode");

    switch(current_gamemode) {
        case GAMEMODE_CLASSIC: break;
        case GAMEMODE_GUNGAME: Gamemode_GunGame_Init(); break;
        case GAMEMODE_HARDCORE: Gamemode_Hardcore_Init(); break;
        case GAMEMODE_STICKSNSTONES: Gamemode_Sticks_Init(); break;
        case GAMEMODE_WILDWEST: Gamemode_WW_Init(); break;
        default: error("Received unrecognized gamemode."); break;
    }
};

//
// Gamemode_Frame()
// Called at StartFrame(), runs the relevant
// game mode's frame function.
//
void() Gamemode_Frame =
{
    switch(current_gamemode) {
        case GAMEMODE_CLASSIC: break;
        case GAMEMODE_GUNGAME: Gamemode_GunGame_Frame(); break;
        case GAMEMODE_HARDCORE: Gamemode_Hardcore_Frame(); break;
        case GAMEMODE_STICKSNSTONES: Gamemode_Sticks_Frame(); break;
        case GAMEMODE_WILDWEST: Gamemode_WW_Frame(); break;
        default: error("Received unrecognized gamemode."); break;
    }

    // Party mode music
    if (Gamemode_IsPartyMode()) {
        if (time > gamemode_track_endtime) {
            float track_idx = rint(random() * 3);
            songegg(gamemode_track_names[track_idx]);
            gamemode_track_endtime = time + gamemode_track_durations[track_idx]; 
            music_override = gamemode_track_endtime;
        }
    }
};

//
// Gamemode_PlayerSpawn()
// Called at PlayerSpawn(), a callback for
// modifying player's spawn process.
//
void() Gamemode_PlayerSpawn =
{
    switch(current_gamemode) {
        case GAMEMODE_CLASSIC: break;
        case GAMEMODE_GUNGAME: Gamemode_GunGame_PlayerSpawn(); break;
        case GAMEMODE_HARDCORE: Gamemode_Hardcore_PlayerSpawn(); break;
        case GAMEMODE_STICKSNSTONES: Gamemode_Sticks_PlayerSpawn(); break;
        case GAMEMODE_WILDWEST: Gamemode_WW_PlayerSpawn(); break;
        default: error("Received unrecognized gamemode."); break;
    }
};

//
// Gamemode_PlayerPostThink()
// Called at PlayerPostThink(), a callback for
// modifying player's think process.
//
void() Gamemode_PlayerPostThink =
{
    switch(current_gamemode) {
        case GAMEMODE_CLASSIC: break;
        case GAMEMODE_GUNGAME: Gamemode_GunGame_PlayerPostThink(); break;
        default: break;
    }
};

//
// Gamemode_PlayerAddScore()
// Called at Player_AddScore(), a callback for
// logic when a player earns score.
//
void(float score_earned) Gamemode_PlayerAddScore =
{
    switch(current_gamemode) {
        case GAMEMODE_CLASSIC: break;
        case GAMEMODE_GUNGAME: Gamemode_GunGame_PlayerAddScore(score_earned); break;
        default: break;
    }
};

//
// Gamemode_GetUp()
// Called at LastStand_GetUp(), a callback for
// logic when a player is revived.
//
void() Gamemode_GetUp =
{
    switch(current_gamemode) {
        case GAMEMODE_CLASSIC: break;
        case GAMEMODE_GUNGAME: Gamemode_GunGame_GetUp(); break;
        default: break;
    }
};

//
// Gamemode_GetWeaponAmmo(weapon, ammo)
// Called by getWeaponAmmo(), a callback to
// modify the return value for maximum reserve ammo.
//
float(float weapon, float ammo) Gamemode_GetWeaponAmmo =
{
    switch(current_gamemode) {
        case GAMEMODE_HARDCORE: return Gamemode_Hardcore_GetWeaponAmmo(weapon, ammo);
        default: return ammo;
    }

    return ammo;
};

float(float damage) Gamemode_GetWeaponDamage =
{
    switch(current_gamemode) {
        case GAMEMODE_WILDWEST: return Gamemode_WW_GetWeaponDamage(damage);
        default: return damage;
    }

    return damage;
};

void(entity attacker, float death_style) Gamemode_DieHandler =
{
    switch(current_gamemode) {
        case GAMEMODE_STICKSNSTONES: Gamemode_Sticks_DieHandler(attacker, death_style); break;
        default: break;
    }
};

void(entity client) Gamemode_DrinkPerk =
{
    switch(current_gamemode) {
        case GAMEMODE_STICKSNSTONES: Gamemode_Sticks_DrinkPerk(client); break;
        default: break;
    }
}

void(entity client, float weapon) Gamemode_BuyWeapon =
{
    switch(current_gamemode) {
        case GAMEMODE_STICKSNSTONES: Gamemode_Sticks_BuyWeapon(client, weapon); break;
        default: break;
    }
}

void() Gamemode_LastStand =
{
    switch(current_gamemode) {
        case GAMEMODE_STICKSNSTONES: Gamemode_Sticks_LastStand(); break;
        default: break;
    }
};