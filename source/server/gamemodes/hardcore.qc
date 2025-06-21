/*
	server/gamemodes/gun_game.qc

	Core Logic for Hardcore.

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

void() Gamemode_Hardcore_Init =
{
    game_modifier_perk_purchase_limit = 2;
    game_modifier_cost_multiplier = 1.5;
};

void() Gamemode_Hardcore_Frame =
{
    return;
};

void() Gamemode_Hardcore_PlayerSpawn =
{
    return;
};

float(float weapon, float ammo) Gamemode_Hardcore_GetWeaponAmmo =
{
	return ammo - (getWeaponMag(weapon) * 2);
};