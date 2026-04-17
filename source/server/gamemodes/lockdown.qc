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
float lock_last_perk_shuffle_round;

void() Gamemode_Lockdown_RandomizePerkLocations =
{
    entity perks[32];
    vector positions[32];
    vector angs[32];

    float count;
    count = 0;

    entity e;

    // Collect all perk machines
    e = find(world, classname, "perk_revive");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_revive");
    }

    e = find(world, classname, "perk_juggernog");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_juggernog");
    }

    e = find(world, classname, "perk_speed");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_speed");
    }

    e = find(world, classname, "perk_double");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_double");
    }

    e = find(world, classname, "perk_flopper");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_flopper");
    }

    e = find(world, classname, "perk_staminup");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_staminup");
    }

    e = find(world, classname, "perk_deadshot");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_deadshot");
    }

    e = find(world, classname, "perk_mule");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_mule");
    }

    e = find(world, classname, "perk_pap");
    while (e != world) {
        perks[count] = e;
        positions[count] = e.origin;
        angs[count] = e.angles;
        count = count + 1;
        e = find(e, classname, "perk_pap");
    }

    // Shuffle positions of all perks
    float i;
    for (i = count - 1; i > 0; i = i - 1) {
        float j;
        j = floor(random() * (i + 1));

        vector tmp_v;
        tmp_v = positions[i];
        positions[i] = positions[j];
        positions[j] = tmp_v;

        tmp_v = angs[i];
        angs[i] = angs[j];
        angs[j] = tmp_v;
    }

    // Apply shuffled positions
    for (i = 0; i < count; i = i + 1) {
        entity p;
        p = perks[i];

        setorigin(p, positions[i]);
        p.angles = angs[i];
        p.oldorigin = p.origin;

        // Fix Pack-a-Punch attachments or they'll
        // float in their old locations (which is obviously incorrect!)
        if (p.classname == "perk_pap") {
            makevectors(p.angles);

            vector newpos;

            // Move roller
            if (p.active_door) {
                entity roller;
                roller = p.active_door;

                newpos = p.origin;
                newpos = newpos + v_right * p.box1_y;
                newpos = newpos + v_forward * p.box1_x;
                newpos = newpos + v_up * p.box1_z;

                setorigin(roller, newpos);
                roller.angles = p.angles;
            }

            // Move flag
            if (p.boxweapon) {
                entity flag;
                flag = p.boxweapon;

                newpos = p.origin;
                newpos = newpos + v_right * p.box3_y;
                newpos = newpos + v_forward * p.box3_x;
                newpos = newpos + v_up * p.box3_z;

                setorigin(flag, newpos);
                flag.angles = p.angles;
            }

            // Recalculate spark offset
            vector tempv;
            tempv = p.origin;
            tempv = tempv + v_right * p.box2_y;
            tempv = tempv + v_forward * p.box2_x;
            tempv = tempv + v_up * p.box2_z;
            p.box2 = tempv;
        }

        setorigin(perks[i], positions[i]);
        perks[i].angles = angs[i];
        perks[i].oldorigin = perks[i].origin;
    }
}

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
        // Play intro voiceline
        Sound_PlaySound(world, "sounds/modes/lockdown/intro.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
        // Randomize perk locations
        Gamemode_Lockdown_RandomizePerkLocations();

        lock_ran_post_init_logic = true;
    }
    
    // Every 5 rounds, reroll the perks to help the player
    // progress in the game
    if (floor(rounds / 5) * 5 == rounds) {
        // Prevents the perks from shuffling all round
        if (rounds != lock_last_perk_shuffle_round) {
            lock_last_perk_shuffle_round = rounds;

            // Avoid running on round 0 & round 1 since we run on
            // game start anyways
            if (rounds > 0 && rounds != 1) {
                Gamemode_Lockdown_RandomizePerkLocations();
            }
        }
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
        Sound_PlaySound(world, "sounds/modes/lockdown/lose.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
    }
};

void() Gamemode_Lockdown_PlayerSpawn =
{
    return;
};