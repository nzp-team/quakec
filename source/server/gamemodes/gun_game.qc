/*
	server/gamemodes/gun_game.qc

	Core Logic for Gun Game.

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

#define GUNGAME_MAX_WEAPONS     32

#define GUNGAME_ANNOUNCE_END    0
#define GUNGAME_ANNOUNCE_HALF   1
#define GUNGAME_ANNOUNCE_FIVE   2
#define GUNGAME_ANNOUNCE_FINAL  3

float gungame_weapon_pool[GUNGAME_MAX_WEAPONS];
float gungame_ran_post_init_logic;

.float gungame_weapon_idx;
.float gungame_score_threshold;
.float gungame_update_time;

void() info_gungame_nukespot = {};

float(float weapon_id, float current_index) Gamemode_GunGame_WeaponIDIsValid =
{
    // Non-weapons should be excluded.
    if (weapon_id == W_NOWEP || weapon_id == W_GRENADE ||
        weapon_id == W_BETTY || weapon_id == W_BOWIE ||
        weapon_id == W_RESERVED || weapon_id == W_RESERVED2)
        return false;
    
    // Also NO FLAMETHROWER
    if (weapon_id == W_M2)
        return false;

    // Prevent duplicates if the weapon appeared in the previous 2 slots
    float prev1 = current_index - 1;
    float prev2 = current_index - 2;

    if (prev1 >= 0 && prev1 < GUNGAME_MAX_WEAPONS) {
        if (gungame_weapon_pool[prev1] == weapon_id)
            return false;
    }
    if (prev2 >= 0 && prev2 < GUNGAME_MAX_WEAPONS) {
        if (gungame_weapon_pool[prev2] == weapon_id)
            return false;
    }

    return true;
};

void() Gamemode_GunGame_GenerateWeaponList =
{
    for (float i = 0; i < GUNGAME_MAX_WEAPONS; i++) {
        float found_eligible_weapon = false;

        while (!found_eligible_weapon) {
            float weapon_id = rint(random() * 59);
            float final_id = EqualNonPapWeapon(weapon_id);

            if (Gamemode_GunGame_WeaponIDIsValid(final_id, i)) {
                gungame_weapon_pool[i] = final_id;
                found_eligible_weapon = true;
            }
        }
    }
};

void() Gamemode_GunGame_Init =
{
    // Create the list of Weapons to Cycle through.
    Gamemode_GunGame_GenerateWeaponList();

    // Precache content..
    for(float i = 0; i < GUNGAME_MAX_WEAPONS; i++) {
        precache_model(GetWeaponModel(gungame_weapon_pool[i], 0));
		precache_model(GetWeaponModel(gungame_weapon_pool[i], 1));
		precache_extra(gungame_weapon_pool[i]);
    }

    precache_sound("sounds/modes/gungame/intro.wav");
    precache_sound("sounds/modes/gungame/win.wav");
    precache_sound("sounds/modes/gungame/lose.wav");
    precache_sound("sounds/modes/gungame/other_list_half.wav");
    precache_sound("sounds/modes/gungame/other_list_5.wav");
    precache_sound("sounds/modes/gungame/other_list_final.wav");
    precache_sound("sounds/modes/gungame/self_list_half.wav");
    precache_sound("sounds/modes/gungame/self_list_5.wav");
    precache_sound("sounds/modes/gungame/self_list_final.wav");
    precache_sound("sounds/modes/gungame/penalty.wav");
    precache_model("models/pu/nuke!.mdl");

    game_modifier_can_melee = false;
    game_modifier_can_use_equipment = false;
    game_modifier_can_earn_misc_score = false;
    game_modifier_powerup_free_perk = true;
    game_modifier_powerup_max_ammo = false;
    game_modifier_powerup_weapon_upgrade = true;
    game_modifier_can_packapunch = false;
};

void() Gamemode_GunGame_Frame =
{
    if (gungame_ran_post_init_logic == false) {
        // Disable weapon buy triggers
        entity buy_weapon = find(world, classname, "buy_weapon");
        while(buy_weapon != world) {
            buy_weapon.solid = SOLID_NOT;
            buy_weapon = find(buy_weapon, classname, "buy_weapon");
        }

        // Disable Mystery Box
        entity mystery_box = find(world, classname, "mystery");
        while(mystery_box != world) {
            mystery_box.solid = SOLID_NOT;
            mystery_box = find(mystery_box, classname, "mystery");
        }

        Sound_PlaySound(world, "sounds/modes/gungame/intro.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
        gungame_ran_post_init_logic = true;
    }

    // Make sure the Player never runs out of ammo.
    entity players = find(world, classname, "player");
    while(players != world) {
        players.weapons[0].weapon_reserve = getWeaponAmmo(players.weapons[0].weapon_id);

        if (players.gungame_update_time < time) {
            entity old_self = self;
            self = players;
            Weapon_GiveWeapon(gungame_weapon_pool[self.gungame_weapon_idx], 0, 0);
            Weapon_RemoveWeapon(1);
            self = old_self;
            players.gungame_update_time = 9999999999;
        }

        players = find(players, classname, "player");
    }
};

void() Gamemode_GunGame_PlayerSpawn =
{
    Weapon_RemoveWeapon(0);
    Weapon_GiveWeapon(gungame_weapon_pool[self.gungame_weapon_idx], 0, 0);

    // Initialize the score threshold only if
    // this is their first spawn.
    if (self.gungame_weapon_idx == 0) {
        self.gungame_score_threshold = self.points + 500;
    }
};

void() Gamemode_GunGame_PlayerPostThink =
{
#ifndef FTE
    string next_weapon = "";

    if (self.gungame_weapon_idx + 1 == GUNGAME_MAX_WEAPONS) {
        next_weapon = "WIN";
    } else {
        next_weapon = GetWeaponName(gungame_weapon_pool[self.gungame_weapon_idx + 1]);
    }

    string centerprint_text = "";
    centerprint_text = strcat("[", ftos(self.gungame_weapon_idx + 1));
    centerprint_text = strcat(centerprint_text, "/32]: ");
    centerprint_text = strcat(centerprint_text, GetWeaponName(gungame_weapon_pool[self.gungame_weapon_idx]));
    centerprint_text = strcat(centerprint_text, "\nNeed [");
    centerprint_text = strcat(centerprint_text, ftos(self.gungame_score_threshold - self.score));
    centerprint_text = strcat(centerprint_text, "] More Score to Advance\nNext Weapon: ");
    centerprint_text = strcat(centerprint_text, next_weapon);

    centerprint(self, centerprint_text);
#endif // FTE
};

void(entity who) Gamemode_GunGame_AdvertiseAdvancement =
{
#ifdef FTE
	FTE_BroadcastMessage(world, CSQC_BROADCAST_GUNGAMEADVANCEMENT, 2, who.playernum);
#else
    bprint(PRINT_HIGH, who.netname);
    bprint(PRINT_HIGH, "ADVANCED!\n");
#endif // FTE

    Sound_PlaySound(world, "sounds/pu/pickup.wav", SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);
}

void(entity advantagee, float status_update) Gamemode_GunGame_Announce =
{
    entity players = find(world, classname, "player");
    while(players != world) {
        if (players == advantagee) {
            switch(status_update) {
                case GUNGAME_ANNOUNCE_END: Sound_PlaySound(players, "sounds/modes/gungame/win.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS); break;
                case GUNGAME_ANNOUNCE_FINAL: Sound_PlaySound(players, "sounds/modes/gungame/self_list_final.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS); break;
                case GUNGAME_ANNOUNCE_FIVE: Sound_PlaySound(players, "sounds/modes/gungame/self_list_5.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS); break;
                case GUNGAME_ANNOUNCE_HALF: Sound_PlaySound(players, "sounds/modes/gungame/self_list_half.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS); break;
            }
        } else {
            switch(status_update) {
                case GUNGAME_ANNOUNCE_END: Sound_PlaySound(players, "sounds/modes/gungame/lose.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS); break;
                case GUNGAME_ANNOUNCE_FINAL: Sound_PlaySound(players, "sounds/modes/gungame/other_list_final.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS); break;
                case GUNGAME_ANNOUNCE_FIVE: Sound_PlaySound(players, "sounds/modes/gungame/other_list_5.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS); break;
                case GUNGAME_ANNOUNCE_HALF: Sound_PlaySound(players, "sounds/modes/gungame/other_list_half.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS); break;
            }
        }
        players = find(players, classname, "player");
    }
};

void() Gamemode_GunGame_GetUp =
{
    // No need to penalize on the first weapon.
    if (self.gungame_weapon_idx == 0)
        return;

    self.gungame_weapon_idx--;
    self.gungame_update_time = time + 0.1;
    self.fire_delay = self.fire_delay2 = 
    self.switch_delay = self.reload_delay = 
    self.reload_delay2 = self.new_anim_stop =
    self.new_anim2_stop = self.gungame_update_time;
    W_SprintStop();
    W_AimOut();
    Sound_PlaySound(self, "sounds/modes/gungame/penalty.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
    self.gungame_score_threshold = self.score + 500 + (60 * self.gungame_weapon_idx);
};

void() Gamemode_GunGame_NukeSparkle =
{
    self.frame++;
    if (self.frame > 2) {
        self.frame = 0;
    }
    self.nextthink = time + 0.15;
}

void() Gamemode_GunGame_Restart =
{
    localcmd("restart\n");
}

void() Gamemode_GunGame_EndGame =
{
    EndGameSetup();
    self.think = Gamemode_GunGame_Restart;
    self.nextthink = time + 10;
}

void() Gamemode_GunGame_NukeTouch =
{
    if (other != self.owner)
        return;

    Player_UseprintWithWait(other, self, 23, 0, 0);

    if (Player_UseButtonPressed(other, self)) {
        // Flash the screen white
	    nzp_screenflash(world, SCREENFLASH_COLOR_WHITE, 1, SCREENFLASH_FADE_INANDOUT);
        self.think = Gamemode_GunGame_EndGame;
        self.nextthink = time + 1.1;
    }
}

void() Gamemode_GunGame_SpawnNuke =
{
    entity nuke = spawn();
    entity nuke_sparkle = spawn();
    entity player_1_spawn = find(world, classname, "info_player_1_spawn");
    entity gungame_nukespot = find(world, classname, "info_gungame_nukespot");

    if (gungame_nukespot == world)
        setorigin(nuke, player_1_spawn.origin + '0 0 22');
    else
        setorigin(nuke, gungame_nukespot.origin + '0 0 22');
    
    setorigin(nuke_sparkle, nuke.origin);
    setsize(nuke, VEC_HULL_MIN, VEC_HULL_MAX);
    setmodel(nuke, "models/pu/nuke!.mdl");
    setmodel(nuke_sparkle, "models/sprites/lightning.spr");
    nuke.solid = SOLID_TRIGGER;
    nuke.effects = EF_FULLBRIGHT;
    nuke.owner = self;

    Light_Cyan(nuke_sparkle, true);

    nuke_sparkle.think = Gamemode_GunGame_NukeSparkle;
    nuke_sparkle.nextthink = time + 0.15;
    nuke.touch = Gamemode_GunGame_NukeTouch;

#ifdef FTE
    nuke.SendEntity = PU_SendEntity;
#endif // FTE
};

void(float score_earned) Gamemode_GunGame_PlayerAddScore =
{
    if (time < 5)
        return;

    // Advance a Player's weapon if they've met their score threshold
    float score_needed_to_advance = self.gungame_score_threshold - self.score;

    if (score_needed_to_advance <= 0) {
        // Player wins! :D
        if (self.gungame_weapon_idx == GUNGAME_MAX_WEAPONS - 1) {
            self.gungame_score_threshold = 999999999;
            self.gungame_weapon_idx = 1000;

            Gamemode_GunGame_Announce(self, GUNGAME_ANNOUNCE_END);

        #ifdef FTE
            FTE_BroadcastMessage(world, CSQC_BROADCAST_GUNGAMEWINNER, 2, self.playernum);
        #else
            bprint(PRINT_HIGH, self.netname);
            bprint(PRINT_HIGH, "can Activate the Nuke!\n");
        #endif // FTE

            Gamemode_GunGame_SpawnNuke();
        } 
        // Advance their weapon
        else {
            self.gungame_weapon_idx++;
            self.gungame_update_time = time + 0.1;
            self.fire_delay = self.fire_delay2 = 
            self.switch_delay = self.reload_delay = 
            self.reload_delay2 = self.new_anim_stop =
            self.new_anim2_stop = self.gungame_update_time;
            W_SprintStop();
            W_AimOut();
            Sound_PlaySound(self, "sounds/misc/ching.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
            Gamemode_GunGame_AdvertiseAdvancement(self);
            self.gungame_score_threshold = self.score + 500 + (60 * self.gungame_weapon_idx);

            // Announcer updates
            if ((self.gungame_weapon_idx + 1) == (GUNGAME_MAX_WEAPONS / 2)) {
                Gamemode_GunGame_Announce(self, GUNGAME_ANNOUNCE_HALF);
            } else if (self.gungame_weapon_idx == GUNGAME_MAX_WEAPONS - 6) {
                Gamemode_GunGame_Announce(self, GUNGAME_ANNOUNCE_FIVE);
            } else if (self.gungame_weapon_idx == GUNGAME_MAX_WEAPONS - 1) {
                Gamemode_GunGame_Announce(self, GUNGAME_ANNOUNCE_FINAL);
            }
        }
    }
};