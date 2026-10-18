/*
	server/utilities/sound_helper.qc

	Logic designed to assist in audio balancing and different types
    of audio channels.

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

#define SOUND_PRIORITY_ALLOWSKIP    0
#define SOUND_PRIORITY_PLAYALWAYS   1

#define SOUND_TYPE_ZOMBIE_QUIET     0
#define SOUND_TYPE_ZOMBIE_LOUD      1
#define SOUND_TYPE_ZOMBIE_CRAWLER   2
#define SOUND_TYPE_MUSIC_ROUND      3
#define SOUND_TYPE_WEAPON_FIRE      4
#define SOUND_TYPE_WEAPON_OTHER     5
#define SOUND_TYPE_WEAPON_PACK      6
#define SOUND_TYPE_WEAPON_EXPLODE   7
#define SOUND_TYPE_PLAYER_VOICE     8
#define SOUND_TYPE_PLAYER_FOOTSTEP  9
#define SOUND_TYPE_ENV_OBJECT       10
#define SOUND_TYPE_ENV_CHING        11
#define SOUND_TYPE_ENV_VOICE        12
#define SOUND_TYPE_ENV_MUSIC        13
#define SOUND_TYPE_ENV_IMPORTANT    14

#define SOUND_MAX_ZOMBIE_GROANS     4
#define SOUND_MAX_WEAPON_EXPLODE    8
#define SOUND_MAX_ENV_VOICE         1

#define PLAYSOUND(ent, channel, path, volume, attenuation, speedpct) sound(ent, channel, path, volume, attenuation, speedpct, SOUNDFLAG_FOLLOW)

float zombie_groan_times[SOUND_MAX_ZOMBIE_GROANS];
float weapon_explode_times[SOUND_MAX_WEAPON_EXPLODE];
float environment_voice_times[SOUND_MAX_ENV_VOICE];

float() Sound_GetEnvironmentVoice =
{
    // Search for an available Explosion slot.
    for(float i = 0; i < SOUND_MAX_ENV_VOICE; i++) {
        if (environment_voice_times[i] < time) {
            return i;
        }
    }

    // None available.
    return -1;
};

void(float priority, float index) Sound_SetEnvironmentVoice =
{
    if (priority == SOUND_PRIORITY_PLAYALWAYS)
        return;

    environment_voice_times[index] = time + 2;
};

float() Sound_GetWeaponExplosion =
{
    // Search for an available Explosion slot.
    for(float i = 0; i < SOUND_MAX_WEAPON_EXPLODE; i++) {
        if (weapon_explode_times[i] < time) {
            return i;
        }
    }

    // None available.
    return -1;
};

void(float priority, float index) Sound_SetWeaponExplosion =
{
    if (priority == SOUND_PRIORITY_PLAYALWAYS)
        return;

    weapon_explode_times[index] = time + 1.2;
};

float() Sound_GetZombieGroan =
{
    // Search for an available Groan slot.
    for(float i = 0; i < SOUND_MAX_ZOMBIE_GROANS; i++) {
        if (zombie_groan_times[i] < time) {
            return i;
        }
    }

    // None available.
    return -1;
};

void(float priority, float index) Sound_SetZombieGroan =
{
    if (priority == SOUND_PRIORITY_PLAYALWAYS)
        return;

    zombie_groan_times[index] = time + 4.5;
};

void(entity source_ent, string path, float type, float priority, optional float speedpct) Sound_PlaySound =
{
    if (path == "") return;
    switch(type) {
        case SOUND_TYPE_ZOMBIE_QUIET:
            float zombie_quiet_groan = Sound_GetZombieGroan();
            if (priority == SOUND_PRIORITY_PLAYALWAYS || zombie_quiet_groan != -1) {
                PLAYSOUND(source_ent, CHAN_VOICE, path, 0.08, 2, speedpct);
                Sound_SetZombieGroan(priority, zombie_quiet_groan);
            }
            break;
        case SOUND_TYPE_ZOMBIE_LOUD:
            float zombie_loud_groan = Sound_GetZombieGroan();
            if (priority == SOUND_PRIORITY_PLAYALWAYS || zombie_loud_groan != -1) {
                PLAYSOUND(source_ent, CHAN_WEAPON, path, 0.16, 1, speedpct);
                Sound_SetZombieGroan(priority, zombie_loud_groan);
            }
            break;
        case SOUND_TYPE_ZOMBIE_CRAWLER:
            float zombie_crawler_groan = Sound_GetZombieGroan();
            if (priority == SOUND_PRIORITY_PLAYALWAYS || zombie_crawler_groan != -1) {
                PLAYSOUND(source_ent, CHAN_ITEM, path, 0.10, 1, speedpct);
                Sound_SetZombieGroan(priority, zombie_crawler_groan);
            }
            break;
        case SOUND_TYPE_MUSIC_ROUND:
            PLAYSOUND(source_ent, CHAN_ITEM, path, 0.30, 0, speedpct);
            break;
        case SOUND_TYPE_WEAPON_FIRE:
            PLAYSOUND(source_ent, CHAN_AUTO, path, 0.40, 2, speedpct);
            break;
        case SOUND_TYPE_WEAPON_OTHER:
            PLAYSOUND(source_ent, CHAN_ITEM, path, 0.30, 2, speedpct);
            break;
        case SOUND_TYPE_WEAPON_PACK:
            PLAYSOUND(source_ent, CHAN_ITEM, path, 0.22, 2, speedpct);
            break;
        case SOUND_TYPE_WEAPON_EXPLODE:
            float weapon_explosion_index = Sound_GetWeaponExplosion();
            if (priority == SOUND_PRIORITY_PLAYALWAYS || weapon_explosion_index != -1) {
                PLAYSOUND(source_ent, 0, path, 0.45, 1, speedpct);
                Sound_SetWeaponExplosion(priority, weapon_explosion_index);
            }
            break;
        case SOUND_TYPE_PLAYER_VOICE:
            PLAYSOUND(source_ent, CHAN_VOICE, path, 0.45, 2, speedpct);
            break;
        case SOUND_TYPE_PLAYER_FOOTSTEP:
            PLAYSOUND(source_ent, 0, path, 0.20, 3, speedpct);
            break;
        case SOUND_TYPE_ENV_OBJECT:
            PLAYSOUND(source_ent, CHAN_ITEM, path, 0.30, 2, speedpct);
            break;
        case SOUND_TYPE_ENV_CHING:
            PLAYSOUND(source_ent, CHAN_AUTO, path, 0.35, 3, speedpct);
            break;
        case SOUND_TYPE_ENV_VOICE:
            float environment_voice_index = Sound_GetEnvironmentVoice();
            if (priority == SOUND_PRIORITY_PLAYALWAYS || environment_voice_index != -1) {
                PLAYSOUND(source_ent, CHAN_VOICE, path, 0.45, 0, speedpct);
                Sound_SetEnvironmentVoice(priority, environment_voice_index);
            }
            break;
        case SOUND_TYPE_ENV_MUSIC:
            PLAYSOUND(source_ent, CHAN_WEAPON, path, 0.35, 3, speedpct);
            break;
        case SOUND_TYPE_ENV_IMPORTANT:
            PLAYSOUND(source_ent, CHAN_ITEM, path, 0.60, 2, speedpct);
            break;
        default:
            break;
    }
};
