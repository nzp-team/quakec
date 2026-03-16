/*
	server/gamemodes/lockdown.qc

	Core Logic for Lockdown.

	Copyright (C) 2021-2026 NZ:P Team

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

float lock_ran_post_init_logic;
float lock_ran_endgame;

void() Gamemode_Lockdown_Init =
{
    // enable the free perk and weapon upgrade drops
    game_modifier_powerup_free_perk = true;
    game_modifier_powerup_weapon_upgrade = true;
    game_modifier_powerup_random_weapon = true;

	// precache audio
    precache_sound("sounds/modes/lockdown/intro.wav");
    precache_sound("sounds/modes/lockdown/carpenter.wav");
	precache_sound("sounds/modes/lockdown/double_points.wav");
	precache_sound("sounds/modes/lockdown/free_perk.wav");
	precache_sound("sounds/modes/lockdown/insta_kill.wav");
	precache_sound("sounds/modes/lockdown/kaboom.wav");
	precache_sound("sounds/modes/lockdown/maxammo.wav");
	precache_sound("sounds/modes/lockdown/random_weapon.wav");
	precache_sound("sounds/modes/lockdown/upgrade.wav");
    precache_sound("sounds/modes/lockdown/lose.wav");
};

void() Gamemode_Lockdown_Frame =
{
    // Intro voiceline
    if (lock_ran_post_init_logic == false) {
        Sound_PlaySound(world, "sounds/modes/lockdown/intro.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
        lock_ran_post_init_logic = true;
    }

    // Disable Doors
    entity doors = find(world, classname, "door_nzp");
    while(doors != world) {
        doors.use = SUB_Null;
        doors.touch = SUB_Null;

        if (doors.trigger_field != world)
            remove(doors.trigger_field);

        doors = find(doors, classname, "door_nzp");
    }
    doors = find(world, classname, "door_nzp_cost");
    while(doors != world) {
        doors.use = SUB_Null;
        doors.touch = SUB_Null;

        if (doors.trigger_field != world)
            remove(doors.trigger_field);

        doors = find(doors, classname, "door_nzp_cost");
    }

    // Losing voiceline
    if ((find(world, classname, "gameover_watcher")) && lock_ran_endgame == false) {
        lock_ran_endgame = true;
        Sound_PlaySound(world, "sounds/modes/lockdown/intro.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
    }
};

void() Gamemode_Lockdown_PlayerSpawn =
{
    return;
};