/*
	server/gamemodes/sticks_and_stones.qc

	Core Logic for Sticks & Stones.

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

float sns_ran_post_init_logic;
float sns_ran_endgame;
float sns_has_taunted_for_low_ammo;

void() Gamemode_Sticks_Init =
{
	precache_extra(W_BK);

	precache_sound("sounds/modes/sticks/intro.wav");
	precache_sound("sounds/modes/sticks/drink_0.wav");
	precache_sound("sounds/modes/sticks/drink_1.wav");
	precache_sound("sounds/modes/sticks/drink_2.wav");
	precache_sound("sounds/modes/sticks/bowie_buy.wav");
	precache_sound("sounds/modes/sticks/last_stand_0.wav");
	precache_sound("sounds/modes/sticks/last_stand_1.wav");
	precache_sound("sounds/modes/sticks/last_stand_2.wav");
	precache_sound("sounds/modes/sticks/lose.wav");
	precache_sound("sounds/modes/sticks/explode_0.wav");
	precache_sound("sounds/modes/sticks/explode_1.wav");
	precache_sound("sounds/modes/sticks/explode_2.wav");
	precache_sound("sounds/modes/sticks/trap.wav");
	precache_sound("sounds/modes/sticks/low_knives.wav");

	game_modifier_powerup_max_ammo = false;
	game_modifier_powerup_free_perk = true;
	game_modifier_grenades_explode_on_contact = true;
};

void() Gamemode_Sticks_Frame =
{
    if (sns_ran_post_init_logic == false) {
        // Disable weapon buy triggers
        entity buy_weapon = find(world, classname, "buy_weapon");
        while(buy_weapon != world) {
			// Keep Bowie Knives
			if (buy_weapon.weapon != W_BOWIE)
            	buy_weapon.solid = SOLID_NOT;
            buy_weapon = find(buy_weapon, classname, "buy_weapon");
        }

        // Disable Mystery Box
        entity mystery_box = find(world, classname, "mystery");
        while(mystery_box != world) {
            mystery_box.solid = SOLID_NOT;
            mystery_box = find(mystery_box, classname, "mystery");
        }

        Sound_PlaySound(world, "sounds/modes/sticks/intro.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
        sns_ran_post_init_logic = true;
    }

	if ((find(world, classname, "gameover_watcher")) && sns_ran_endgame == false) {
		sns_ran_endgame = true;
		Sound_PlaySound(world, "sounds/modes/sticks/lose.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
	}

	if (sns_has_taunted_for_low_ammo == false) {
		entity players = find(world, classname, "player");

		while(players != world) {
			if (players.weapons[0].weapon_reserve == 0) {
				Sound_PlaySound(players, "sounds/modes/sticks/low_knives.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
				sns_has_taunted_for_low_ammo = true;
			}

			players = find(players, classname, "player");
		}
	}
};

void() Gamemode_Sticks_PlayerSpawn =
{
	Weapon_AssignWeapon(0, W_BK, 0, 0);
};

void(entity attacker, float death_style) Gamemode_Sticks_DieHandler =
{
	if (death_style == DMG_TYPE_MELEE && attacker.weapons[0].weapon_reserve < getWeaponAmmo(attacker.weapons[0].weapon_id)) {
		attacker.weapons[0].weapon_reserve++;
	}

	if (death_style == DMG_TYPE_GRENADE) {
		float chance_to_taunt = random();

		// 2% Chance to taunt
		if (chance_to_taunt > 0.02)
			return;

			string taunt = "";
			float taunt_variant = random();

			if (taunt_variant > 0.3) 
				taunt = "sounds/modes/sticks/explode_0.wav";
			else if (taunt_variant > 0.6)
				taunt = "sounds/modes/sticks/explode_1.wav";
			else
				taunt = "sounds/modes/sticks/explode_2.wav";

			Sound_PlaySound(attacker, taunt, SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
	}
};

void(entity client) Gamemode_Sticks_DrinkPerk =
{
	float chance_to_taunt = random();

	// 20% Chance to taunt
	if (chance_to_taunt > 0.2)
		return;

	string taunt = "";
	float taunt_variant = random();

	if (taunt_variant > 0.3) 
		taunt = "sounds/modes/sticks/drink_0.wav";
	else if (taunt_variant > 0.6)
		taunt = "sounds/modes/sticks/drink_1.wav";
	else
		taunt = "sounds/modes/sticks/drink_2.wav";

	Sound_PlaySound(client, taunt, SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
};

void(entity client, float weapon) Gamemode_Sticks_BuyWeapon =
{
	if (weapon != W_BOWIE)
		return;

	Sound_PlaySound(client, "sounds/modes/sticks/bowie_buy.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
};

void() Gamemode_Sticks_LastStand =
{
	float chance_to_taunt = random();

	// 60% Chance to taunt
	if (chance_to_taunt > 0.6)
		return;

	string taunt = "";
	float taunt_variant = random();

	if (taunt_variant > 0.3) 
		taunt = "sounds/modes/sticks/last_stand_0.wav";
	else if (taunt_variant > 0.6)
		taunt = "sounds/modes/sticks/last_stand_1.wav";
	else
		taunt = "sounds/modes/sticks/last_stand_2.wav";

	Sound_PlaySound(self, taunt, SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
};