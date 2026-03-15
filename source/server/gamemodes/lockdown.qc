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

void() Gamemode_Lockdown_Init =
{
    // enable the free perk and weapon upgrade drops
    game_modifier_powerup_free_perk = true;
    game_modifier_powerup_weapon_upgrade = true;

	// precache laugh
	precache_sound("sounds/modes/lockdown/laugh.wav");
};

void() Gamemode_Lockdown_Frame =
{
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
};

void() Gamemode_Lockdown_PlayerSpawn =
{
    return;
};