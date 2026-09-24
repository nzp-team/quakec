/*
	server/tests/test_powerups.qc

	Unit tests for the Power-Ups

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
float(float condition, string message) Test_Assert;
void(string message) Test_Skip;

//
// Test_Powerups_DisabledDropsStayOutOfRotation()
// Ensures disabled Power-Ups stay out of rotation.
//
void() Test_Powerups_DisabledDropsStayOutOfRotation =
{
	float old_nuke = game_modifiers.gameplay.powerups.powerup_nuke.enabled;
	float old_instakill = game_modifiers.gameplay.powerups.powerup_instakill.enabled;
	float old_double_points = game_modifiers.gameplay.powerups.powerup_double_points.enabled;
	float old_carpenter = game_modifiers.gameplay.powerups.powerup_carpenter.enabled;
	float old_max_ammo = game_modifiers.gameplay.powerups.powerup_max_ammo.enabled;
	float old_free_perk = game_modifiers.gameplay.powerups.powerup_free_perk.enabled;
	float old_weapon_upgrade = game_modifiers.gameplay.powerups.powerup_weapon_upgrade.enabled;
	float old_bonus_points = game_modifiers.gameplay.powerups.powerup_bonus_points.enabled;
	float old_carpenter_chance = game_modifiers.gameplay.powerups.powerup_carpenter.chance_to_allow_in_rotation;
	float old_carpenter_round = game_modifiers.gameplay.powerups.powerup_carpenter.disabled_before_round;
	float old_carpenter_barricades = game_modifiers.gameplay.powerups.powerup_carpenter.destroyed_barricade_requirement;
	float old_rounds = rounds;
	float old_windows_down = total_windows_down;
	float old_powerup_index = powerup_index;

	game_modifiers.gameplay.powerups.powerup_nuke.enabled = false;
	game_modifiers.gameplay.powerups.powerup_instakill.enabled = false;
	game_modifiers.gameplay.powerups.powerup_double_points.enabled = false;
	game_modifiers.gameplay.powerups.powerup_carpenter.enabled = true;
	game_modifiers.gameplay.powerups.powerup_max_ammo.enabled = false;
	game_modifiers.gameplay.powerups.powerup_free_perk.enabled = false;
	game_modifiers.gameplay.powerups.powerup_weapon_upgrade.enabled = false;
	game_modifiers.gameplay.powerups.powerup_bonus_points.enabled = false;
	game_modifiers.gameplay.powerups.powerup_carpenter.chance_to_allow_in_rotation = 1;
	game_modifiers.gameplay.powerups.powerup_carpenter.disabled_before_round = 0;
	game_modifiers.gameplay.powerups.powerup_carpenter.destroyed_barricade_requirement = 0;
	rounds = 1;
	total_windows_down = 0;
	powerup_index = 0;

	for (float i = 0; i < 64; i++) {
		Test_Assert(PU_GetNextPowerUp() == PU_CARPENTER, "Disabled Power-Up entered the drop rotation!");
	}

	game_modifiers.gameplay.powerups.powerup_nuke.enabled = old_nuke;
	game_modifiers.gameplay.powerups.powerup_instakill.enabled = old_instakill;
	game_modifiers.gameplay.powerups.powerup_double_points.enabled = old_double_points;
	game_modifiers.gameplay.powerups.powerup_carpenter.enabled = old_carpenter;
	game_modifiers.gameplay.powerups.powerup_max_ammo.enabled = old_max_ammo;
	game_modifiers.gameplay.powerups.powerup_free_perk.enabled = old_free_perk;
	game_modifiers.gameplay.powerups.powerup_weapon_upgrade.enabled = old_weapon_upgrade;
	game_modifiers.gameplay.powerups.powerup_bonus_points.enabled = old_bonus_points;
	game_modifiers.gameplay.powerups.powerup_carpenter.chance_to_allow_in_rotation = old_carpenter_chance;
	game_modifiers.gameplay.powerups.powerup_carpenter.disabled_before_round = old_carpenter_round;
	game_modifiers.gameplay.powerups.powerup_carpenter.destroyed_barricade_requirement = old_carpenter_barricades;
	rounds = old_rounds;
	total_windows_down = old_windows_down;
	powerup_index = old_powerup_index;
};