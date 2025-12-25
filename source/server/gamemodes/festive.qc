/*
	server/gamemodes/festive.qc

	Core Logic for Festive (Cold War) Game Mode.

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

float festive_ran_post_init_logic;
string festive_override_music;
string festive_round_color;

void() Gamemode_Festive_Init =
{
    precache_sound("sounds/modes/festive/rnd_splash.wav");
    precache_sound("sounds/modes/festive/rnd_start.wav");
    precache_sound("sounds/modes/festive/rnd_end.wav");
    precache_sound("sounds/modes/festive/rnd_dog_start.wav");
    precache_sound("sounds/modes/festive/rnd_dog_end.wav");
    precache_sound("sounds/modes/festive/byebye.wav");
    precache_sound("sounds/modes/festive/fetch.wav");
    precache_sound("sounds/modes/festive/tear.wav");
    precache_sound("sounds/modes/festive/halloween/mbox_open.wav");

    precache_model("models/props/derped/ammo_can.mdl");
    game_modifier_powerup_free_perk = true;
    game_modifier_powerup_free_perk_is_rare = true;
    game_modifier_packapunch_uses_tiers = true;
    game_modifier_packapunch_is_instant = true;
    game_modifier_maxammo_fills_magazine = true;
    game_modifier_powerup_bonus_points = true;
    game_modifier_powerup_toast_for_all = true;
    game_modifier_hellhound_fog_color = "200 525 60 25 45";
    game_modifier_default_fog_color = "240 2000 60 45 45";
    festive_round_color = "20 10 0";
    sprint_max_time = 10000000;

    // Holiday settings
    switch(current_month_of_year) {
        case 10:
            mystery_box_open_sound = "sounds/modes/festive/halloween/mbox_open.wav";
            game_modifier_hellhound_fog_color = "200 525 60 45 25";
            game_modifier_default_fog_color = "240 2000 0 0 0";
            festive_round_color = "50 15 0";
            festive_override_music = "festive/dtha";
            break;
    }

    // Spawn the ambient music..
    entity ambience = spawn();
    ambience.noise2 = "sounds/music/tune1.wav";
    entity old_self = self;
    self = ambience;
    ambient_bgm();
    self = old_self;
};

void() Gamemode_Festive_AmmoCrateTouch =
{
    if (other.classname != "player" || other.downed)
		return;

    float ammo_cost = 500;

    switch(other.weapons[0].weapon_tier) {
        case 1:
            ammo_cost = 1000;
            break;
        case 2:
            ammo_cost = 2500;
            break;
        case 3:
            ammo_cost = 5000;
            break;
        default: 
            break;
    }

    if (EqualNonPapWeapon(other.weapon) == W_RAY || EqualNonPapWeapon(other.weapon) == W_TESLA || EqualNonPapWeapon(other.weapon) == W_RAYMK2)
        ammo_cost = 10000;

    other.Weapon_Name_Touch = GetWeaponName(other.weapon, -1);

	if (other.currentammo < getWeaponAmmo(other.weapon)) {
		Player_UseprintWithWait(other, self, 3, ammo_cost, other.weapon);

		if (!Player_UseButtonPressed(other, self) || (other.semi_actions & SEMIACTION_USE) || other.isBuying) {
			return;
		}

		other.semi_actions |= SEMIACTION_USE;

		// Player doesn't have enough points. Abort.
		if (other.points < ammo_cost) {
			centerprint(other, STR_NOTENOUGHPOINTS);
			Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			return;
		}

        other.weapons[0].weapon_magazine = getWeaponMag(other.weapon);
		other.weapons[0].weapon_reserve = getWeaponAmmo(other.weapon);

		Sound_PlaySound(other, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
		other.reload_delay = 0;

		// Subtract the cost from player points.
		Player_RemoveScore(other, ammo_cost);
	}
};

void(vector crate_origin, vector crate_angles) Gamemode_Festive_SpawnAmmoCrate =
{
    entity ammo_crate = spawn();
    setmodel(ammo_crate, "models/props/derped/ammo_can.mdl");
    setsize(ammo_crate, '-32 -32 -32', '32 32 32');
    setorigin(ammo_crate, crate_origin - '0 0 32');
    ammo_crate.angles = crate_angles;
    ammo_crate.scale = 2;
    ammo_crate.touch = Gamemode_Festive_AmmoCrateTouch;
    ammo_crate.solid = SOLID_TRIGGER;
    Light_Purple(ammo_crate);
};

void() Gamemode_Festive_Frame =
{
    if (festive_ran_post_init_logic == false) {
        entity barricades = find(world, classname, "window");
        while (barricades != world) {
            barricades.health = -10;
            setmodel(barricades, "");
            barricades = find(barricades, classname, "window");
        }

        entity double_tap_machines = find(world, classname, "perk_double");
        while (double_tap_machines != world) {
            Gamemode_Festive_SpawnAmmoCrate(double_tap_machines.origin, double_tap_machines.angles);
            remove(double_tap_machines);
            double_tap_machines = find(double_tap_machines, classname, "perk_double");
        }

        // Enable weapon upgrade Power-Up if Pack-A-Punch isn't present..
        if (find(world, classname, "perk_pap") == world) {
            game_modifier_powerup_weapon_upgrade = true;
        }

        if (festive_override_music != "") {
            entity song_eggs = find(world, classname, "game_songplay");
            while (song_eggs != world) {
                song_eggs.aistatus = festive_override_music;
                song_eggs.cost = 240;
                song_eggs = find(song_eggs, classname, "game_songplay");
            }
        }

        localcmd(strcat("fog ", game_modifier_default_fog_color));
        festive_ran_post_init_logic = true;
    }
};

void() Gamemode_Festive_PlayerSpawn =
{
    self.has_bowie_knife = true;
    self.has_doubletap_damage_buff = false;
    nzp_setdoubletapver(self, false);

    // Give the player a random starting weapon
    float weapon_options[6] = {W_COLT, W_KAR, W_M1A1, W_SAWNOFF, W_MP40, W_GEWEHR};
    float weapon_chance = random();

    for (float i = 0; i < 6; i++) {
        if (weapon_chance < (1/(i + 1))) {
            Weapon_AssignWeapon(0, weapon_options[i], 0, 0, 0);
        }
    }

#ifdef FTE
    nzp_setroundcolor(stov(festive_round_color));
    nzp_setperkorientation(HUD_PERK_ORI_CW);
#endif // FTE
};

float(float current_earned_score, float damage_style) Gamemode_Festive_ScoreForDamage =
{
    // No points for just damage.
    if (current_earned_score == DMG_SCORE_STDDAMAGE)
        return 0;

    switch(damage_style) {
        case DMG_TYPE_HEADSHOT:
        case DMG_TYPE_MELEE:
            return 115;
        case DMG_TYPE_UPPERTORSO:
        case DMG_TYPE_LOWERTORSO:
        case DMG_TYPE_EXPLOSIVE:
        case DMG_TYPE_FLAMETHROWER:
        case DMG_TYPE_GRENADE:
        case DMG_TYPE_TESLA:
            return 90;
    }

    return current_earned_score;
};

float(float current_melee_damage, float weapon, float has_bowie) Gamemode_Festive_CalculateMeleeDamage =
{
    // Hard coded because we always have the Bowie Knife.
    return 715;
};

float(float current_count, float current_round, float round_type, float current_player_count) Gamemode_Festive_GetZombieTotalForRound =
{
    // Leave Hellhounds alone..
    if (round_type == 2)
        return current_count;

    // As far as I can tell these are hard coded? No real algo here..
    if (current_round <= 5) {
        switch(current_round) {
            case 1:
                switch(current_player_count) {
                    case 1: return 6;
                    case 2: return 8;
                    case 3: return 11;
                    case 4: return 14;
                    case 5: return 18;
                    case 6: return 24;
                    case 7: return 28;
                    default: return 32;
                }
            case 2:
                switch(current_player_count) {
                    case 1: return 9;
                    case 2: return 11;
                    case 3: return 14;
                    case 4: return 18;
                    case 5: return 22;
                    case 6: return 26;
                    case 7: return 30;
                    default: return 35;
                }
            case 3:
                switch(current_player_count) {
                    case 1: return 13;
                    case 2: return 15;
                    case 3: return 20;
                    case 4: return 25;
                    case 5: return 30;
                    case 6: return 35;
                    case 7: return 40;
                    default: return 45;
                }
            case 4:
                switch(current_player_count) {
                    case 1: return 18;
                    case 2: return 20;
                    case 3: return 25;
                    case 4: return 33;
                    case 5: return 39;
                    case 6: return 46;
                    case 7: return 53;
                    default: return 60;
                }
            default:
                switch(current_player_count) {
                    case 1: return 24;
                    case 2: return 25;
                    case 3: return 32;
                    case 4: return 42;
                    case 5: return 52;
                    case 6: return 59;
                    case 7: return 62;
                    default: return 68;
                }
        }
    } else {
        // .. This is programmatic, me thinks!
        // Start with a base of 24 like normal algorithm..
        float base_count = 24;

        // Cold War seems to cap at Round 29 for solo, and 
        // Round 20 for Co-Op..
        float ai_round_cap = 0;
        float player_weight = 0;
        float algo_magic = 0.5;
        
        if (current_player_count == 1) {
            ai_round_cap = 29;
            player_weight = 0.84;
        } else {
            ai_round_cap = 20;
            player_weight = 0.6;
            algo_magic += (current_player_count / 2);
        }

        float multiplier = 1;

        if (current_round < ai_round_cap) {
            player_weight *= 0.84; // ..?
            multiplier = clamp(current_round / 5, 0, 1);
            multiplier *= current_round * player_weight;
        } else {
            multiplier = current_round * player_weight;
        }

        float zombie_count = rint(algo_magic * 6 * multiplier);
    }

    return zombie_count;
}

float(float current_health, float current_round) Gamemode_Festive_GetZombieHealthForRound =
{
    float zombie_health = 150;

    if (rounds > 2 && rounds < 13) {
        zombie_health += rounds * 60;
    } else if (rounds < 18) {
        zombie_health += rounds * 100;
    } else if (rounds < 23) {
        zombie_health += rounds * 300;
    } else if (rounds < 28) {
        zombie_health += rounds * 750;
    } else if (rounds < 33) {
        zombie_health += rounds * 1400;
    } else if (rounds < 37) {
        zombie_health += rounds * 1750;
    } else if (rounds < 56) {
        zombie_health += rounds * 2000;
    } else {
        zombie_health = 60250;
    }
    return zombie_health;
}

float(entity client, float current_price) Gamemode_Festive_GetPerkMachinePrice =
{
    return 2500 + (Player_GetNumPerks(other) * 500);
}

float(float current_multiplier, float current_perks, float weapon, float location) Gamemode_Festive_GetWeaponLimbMultiplier =
{
    // If it's a Headshot and we have Deadshot Daiquiri..
    if ((current_perks & P_DEAD) && location == HEAD_X) {
        return current_multiplier * 1.35;
    }

    // Dampen damage outside of headshots.
    if (location != HEAD_X) {
        return current_multiplier *= 0.75;
    }

    return current_multiplier;
}

float(float damage, float weapon_id, float weapon_tier) Gamemode_Festive_GetWeaponDamage =
{
    // Buff the Colt M1911 a tiny bit
    if (weapon_id == W_COLT)
        damage = 60;
    else
        damage *= 0.65;

    // Blue Rarity + Tier I Equivalent
    if (weapon_tier == 1)
        return damage * 2;

    // Purple Rarity + Tier II Equivalent
    else if (weapon_tier == 2)
        return damage * 6;

    // Gold Rarity + Tier III Equivalent
    else if (weapon_tier == 3)
        return damage * 16;

    return damage;
}

float(float current_cost, float weapon_cost, float weapon_id, float is_upgraded, float weapon_tier) Gamemode_Festive_GetCostForWeaponAmmo =
{
    if (EqualNonPapWeapon(weapon_id) == W_RAY || EqualNonPapWeapon(weapon_id) == W_TESLA || EqualNonPapWeapon(weapon_id) == W_RAYMK2)
        return 10000;

    if (is_upgraded) {
        switch(weapon_tier) {
            case 1:
                return 5000;
            case 2:
                return 15000;
            case 3:
                return 30000;
        }
    }

    return weapon_cost;
}

float(float weapon, float ammo) Gamemode_Festive_GetWeaponAmmo =
{
    return rint(ammo * 1.5);
};

float(float current_max_health, float current_perks) Gamemode_Festive_GetMaxHealthForPlayer =
{
    if (current_perks & P_JUG)
        return 250;

    return 150;
}

float(float current_dist, string ai_classname) Gamemode_Festive_GetAIWalkSpeed =
{
    return current_dist * 1.25;
}

float(float current_health_delay, float current_perks) Gamemode_Festive_GetHealthRegenDelayForPlayer =
{
    if (current_perks & P_REVIVE)
        return current_health_delay * 0.5;

    return current_health_delay;
}

string(string current_tune) Gamemode_Festive_GetSplashTune =
{
    return "sounds/modes/festive/rnd_splash.wav";
}

string(string current_tune) Gamemode_Festive_GetStartRoundTune =
{
    return "sounds/modes/festive/rnd_start.wav";
}

string(string current_tune) Gamemode_Festive_GetEndRoundTune =
{
    return "sounds/modes/festive/rnd_end.wav";
}

string(string current_tune) Gamemode_Festive_GetStartSpecialRoundTune =
{
    return "sounds/modes/festive/rnd_dog_start.wav";
}

string(string current_tune) Gamemode_Festive_GetEndSpecialRoundTune =
{
    return "sounds/modes/festive/rnd_dog_end.wav";
}

string(string current_taunt) Gamemode_Festive_GetHellhoundTaunt =
{
    float chance = random();

    if (chance < 0.5) {
        return "sounds/modes/festive/fetch.wav";
    } else {
        return "sounds/modes/festive/tear.wav";
    }
}

float(float current_delay) Gamemode_Festive_GetRoundDelay =
{
    return time + 4.5;
}

string(string taunt) Gamemode_Festive_GetGoodByeTaunt =
{
    return "sounds/modes/festive/byebye.wav";
}