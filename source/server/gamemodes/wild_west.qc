/*
	server/gamemodes/wild_west.qc

	Core Logic for Wild West.

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

float ww_ran_post_init_logic;
float ww_inside_check_delay;

.float ww_upgrade_tier;

void() Gamemode_WW_Init =
{
    // Disable All magic
    localcmd("sv_magic 0\n");

    precache_model("models/pu/nuke!.mdl");
    precache_model("models/pu/maxammo!.mdl");
    precache_model("models/pu/pack!.mdl");
    precache_model("models/pu/perkbottle!.mdl");

    precache_sound("sounds/modes/wildwest/intro.wav");
    precache_sound("sounds/modes/wildwest/lose.wav");
    precache_sound("sounds/modes/wildwest/nuke.wav");
    precache_sound("sounds/modes/wildwest/free_perk.wav");

    game_modifier_powerup_free_perk = true;
};

void() Gamemode_WW_NukeDrop =
{
    if (other.classname != "player" || other.downed)
        return;

    float price = 5000;

    Player_UseprintWithWait(other, self, 9, price, 9);

    if (other.points >= price && Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
		Player_RemoveScore(other, price);
		Sound_PlaySound(self, "sounds/machines/vend.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);

        Spawn_Powerup(other.origin, PU_NUKE);

		other.semi_actions |= SEMIACTION_USE;
	}
};

void() Gamemode_WW_AmmoDrop =
{
    if (other.classname != "player" || other.downed)
        return;

    float price = 5000;

    Player_UseprintWithWait(other, self, 9, price, 12);

    if (other.points >= price && Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
		Player_RemoveScore(other, price);
		Sound_PlaySound(self, "sounds/machines/vend.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);

        Spawn_Powerup(other.origin, PU_MAXAMMO);

		other.semi_actions |= SEMIACTION_USE;
	}
};

void() Gamemode_WW_UpgrDrop =
{
    if (other.classname != "player" || other.downed)
        return;

    float price = 5000;

    Player_UseprintWithWait(other, self, 9, price, 11);

    if (other.points >= price && Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
		Player_RemoveScore(other, price);
		Sound_PlaySound(self, "sounds/machines/vend.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
        other.ww_upgrade_tier++;
		other.semi_actions |= SEMIACTION_USE;
	}
};

void() Gamemode_WW_PerkDrop =
{
    if (other.classname != "player" || other.downed)
        return;

    float price = 5000;

    Player_UseprintWithWait(other, self, 9, price, 10);

    if (other.points >= price && Player_UseButtonPressed(other, self) && !(other.semi_actions & SEMIACTION_USE)) {
		Player_RemoveScore(other, price);
		Sound_PlaySound(self, "sounds/machines/vend.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);

        Spawn_Powerup(other.origin, PU_FREEPERK);

		other.semi_actions |= SEMIACTION_USE;
	}
};

void() Gamemode_WW_SpawnTools =
{
    entity player_5_spawn = find(world, classname, "info_player_5_spawn");
    entity player_6_spawn = find(world, classname, "info_player_6_spawn");
    entity player_7_spawn = find(world, classname, "info_player_7_spawn");
    entity player_8_spawn = find(world, classname, "info_player_8_spawn");

    entity nuke_drop = spawn();
    nuke_drop.classname = "ww_nuke_drop";
    entity ammo_drop = spawn();
    ammo_drop.classname = "ww_ammo_drop";
    entity upgr_drop = spawn();
    upgr_drop.classname = "ww_upgr_drop";
    entity perk_drop = spawn();
    perk_drop.classname = "ww_perk_drop";

    entity nuke_sparkle = spawn();
    entity ammo_sparkle = spawn();
    entity upgr_sparkle = spawn();
    entity perk_sparkle = spawn();

    setorigin(nuke_drop, player_5_spawn.origin + '0 0 22');
    setmodel(nuke_drop, "models/pu/nuke!.mdl");
    nuke_sparkle.effects = EF_FULLBRIGHT;
    setsize(nuke_drop, VEC_HULL_MIN, VEC_HULL_MAX);
    setorigin(nuke_sparkle, nuke_drop.origin);

    setorigin(ammo_drop, player_6_spawn.origin + '0 0 22');
    setmodel(ammo_drop, "models/pu/maxammo!.mdl");
    ammo_sparkle.effects = EF_FULLBRIGHT;
    setsize(ammo_drop, VEC_HULL_MIN, VEC_HULL_MAX);
    setorigin(ammo_sparkle, ammo_drop.origin);

    setorigin(upgr_drop, player_7_spawn.origin + '0 0 22');
    setmodel(upgr_drop, "models/pu/pack!.mdl");
    upgr_sparkle.effects = EF_FULLBRIGHT;
    setsize(upgr_drop, VEC_HULL_MIN, VEC_HULL_MAX);
    setorigin(upgr_sparkle, upgr_drop.origin);

    setorigin(perk_drop, player_8_spawn.origin + '0 0 22');
    setmodel(perk_drop, "models/pu/perkbottle!.mdl");
    perk_sparkle.effects = EF_FULLBRIGHT;
    setsize(perk_drop, VEC_HULL_MIN, VEC_HULL_MAX);
    setorigin(perk_sparkle, perk_drop.origin);

    setmodel(nuke_sparkle, "models/sprites/lightning.spr");
    nuke_sparkle.think = Gamemode_GunGame_NukeSparkle;
    nuke_sparkle.nextthink = time + 0.15;

    setmodel(ammo_sparkle, "models/sprites/lightning.spr");
    ammo_sparkle.think = Gamemode_GunGame_NukeSparkle;
    ammo_sparkle.nextthink = time + 0.15;

    setmodel(upgr_sparkle, "models/sprites/lightning.spr");
    upgr_sparkle.think = Gamemode_GunGame_NukeSparkle;
    upgr_sparkle.nextthink = time + 0.15;

    setmodel(perk_sparkle, "models/sprites/lightning.spr");
    perk_sparkle.think = Gamemode_GunGame_NukeSparkle;
    perk_sparkle.nextthink = time + 0.15;

    nuke_drop.effects = EF_FULLBRIGHT;
    nuke_drop.solid = SOLID_TRIGGER;
    ammo_drop.effects = EF_FULLBRIGHT;
    ammo_drop.solid = SOLID_TRIGGER;
    upgr_drop.effects = EF_FULLBRIGHT;
    upgr_drop.solid = SOLID_TRIGGER;
    perk_drop.effects = EF_FULLBRIGHT;
    perk_drop.solid = SOLID_TRIGGER;

    nuke_drop.touch = Gamemode_WW_NukeDrop;
    ammo_drop.touch = Gamemode_WW_AmmoDrop;
    upgr_drop.touch = Gamemode_WW_UpgrDrop;
    perk_drop.touch = Gamemode_WW_PerkDrop;
};

void() Gamemode_WW_KillAllPlayers =
{
    entity player = find(world, classname, "player");

    while(player != world) {
        player.perks = 0;
        LastStand_Begin(player);
        player = find(player, classname, "player");
    }
};  

void() Gamemode_WW_Frame =
{
    if (ww_ran_post_init_logic == false) {
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

        Gamemode_WW_SpawnTools();

        Sound_PlaySound(world, "sounds/modes/wildwest/intro.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
        ww_ran_post_init_logic = true;
    }

    if (ww_inside_check_delay < time && !(find(world, classname, "gameover_watcher"))) {
        entity zombs = find(world, aistatus, "1");

        while(zombs != world) {
            if (zombs.outside == false && zombs.classname != "ai_dog") {
                Gamemode_WW_KillAllPlayers();
                Sound_PlaySound(world, "sounds/modes/wildwest/lose.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
                return;
            }

            zombs = find(zombs, aistatus, "1");
        }

        ww_inside_check_delay = time + 5;
    }
};

void() Gamemode_WW_PlayerSpawn =
{
    Weapon_AssignWeapon(0, W_SAWNOFF, 0, 0);
    Weapon_GiveWeapon(W_357, 0, 0);
};

float(float weapon_damage) Gamemode_WW_GetWeaponDamage =
{
    return weapon_damage + ((weapon_damage * 0.15) * self.ww_upgrade_tier);
};