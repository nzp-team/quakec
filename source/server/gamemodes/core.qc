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
        case GAMEMODE_FESTIVE: Gamemode_Festive_Init(); break;
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
        case GAMEMODE_FESTIVE: Gamemode_Festive_Frame(); break;
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
        case GAMEMODE_FESTIVE: Gamemode_Festive_PlayerSpawn(); break;
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
// Gamemode_ScoreForDamage(current_earned_score, damage_style)
// Called before assigning appropriate score to players
// for dealing damage.
//
float(float current_earned_score, float damage_style) Gamemode_ScoreForDamage =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_ScoreForDamage(current_earned_score, damage_style);
        default: break;
    }

    return current_earned_score;
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
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetWeaponAmmo(weapon, ammo);
        default: return ammo;
    }

    return ammo;
};

float(float damage, float weapon_id, float weapon_tier) Gamemode_GetWeaponDamage =
{
    switch(current_gamemode) {
        case GAMEMODE_WILDWEST: return Gamemode_WW_GetWeaponDamage(damage, weapon_id, weapon_tier);
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetWeaponDamage(damage, weapon_id, weapon_tier);
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

float(float current_melee_damage, float weapon, float has_bowie) Gamemode_CalculateMeleeDamage =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_CalculateMeleeDamage(current_melee_damage, weapon, has_bowie);
        default: break;
    }

    return current_melee_damage;
}

float(float current_count, float current_round, float round_type, float current_player_count) Gamemode_GetZombieTotalForRound =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetZombieTotalForRound(current_count, current_round, round_type, current_player_count);
        default: break;
    }

    return current_count;
}

float(float current_health, float current_round) Gamemode_GetZombieHealthForRound =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetZombieHealthForRound(current_health, current_round);
        default: break;
    }

    return current_health;
}

float(entity client, float current_price) Gamemode_GetPerkMachinePrice =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetPerkMachinePrice(client, current_price);
        default: break;
    }

    return current_price;
}

float(float current_multiplier, float current_perks, float weapon, float location) Gamemode_GetWeaponLimbMultiplier =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetWeaponLimbMultiplier(current_multiplier, current_perks, weapon, location);
        default: break;
    }

    return current_multiplier;
}

float(float current_cost, float weapon_cost, float weapon_id, float is_upgraded, float weapon_tier) Gamemode_GetCostForWeaponAmmo =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetCostForWeaponAmmo(current_cost, weapon_cost, weapon_id, is_upgraded, weapon_tier);
        default: break;
    }

    return current_cost;
}

float(float current_max_health, float current_perks) Gamemode_GetMaxHealthForPlayer =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetMaxHealthForPlayer(current_max_health, current_perks);
        default: break;
    }

    return current_max_health;
}

float(float current_dist, string ai_classname) Gamemode_GetAIWalkSpeed =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetAIWalkSpeed(current_dist, ai_classname);
        default: break;
    }

    return current_dist;
}

float(float current_health_delay, float current_perks) Gamemode_GetHealthRegenDelayForPlayer =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetHealthRegenDelayForPlayer(current_health_delay, current_perks);
        default: break;
    }

    return current_health_delay;
}

string(string current_tune) Gamemode_GetSplashTune =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetSplashTune(current_tune);
        default: break;
    }

    return current_tune; 
}

string(string current_tune) Gamemode_GetStartRoundTune =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetStartRoundTune(current_tune);
        default: break;
    }

    return current_tune; 
}

string(string current_tune) Gamemode_GetEndSpecialRoundTune =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetEndSpecialRoundTune(current_tune);
        default: break;
    }

    return current_tune;
}

string(string current_tune) Gamemode_GetStartSpecialRoundTune =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetStartSpecialRoundTune(current_tune);
        default: break;
    }

    return current_tune; 
}

string(string current_taunt) Gamemode_GetHellhoundTaunt =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetHellhoundTaunt(current_taunt);
        default: break;
    }

    return current_taunt; 
}

string(string current_tune) Gamemode_GetEndRoundTune =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetEndRoundTune(current_tune);
        default: break;
    }

    return current_tune;
}

float(float current_delay) Gamemode_GetRoundDelay =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetRoundDelay(current_delay);
        default: break;
    }

    return current_delay;
}

string(string taunt) Gamemode_GetGoodByeTaunt =
{
    switch(current_gamemode) {
        case GAMEMODE_FESTIVE: return Gamemode_Festive_GetGoodByeTaunt(taunt);
        default: break;
    }

    return taunt;
}