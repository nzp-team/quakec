/*
	server/entities/spawn_points.qc

	Code for Player Spawn points.

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

#define SPAWN_PLR_1         0
#define SPAWN_PLR_2         1
#define SPAWN_PLR_3         2
#define SPAWN_PLR_4         3
#define SPAWN_PLR_LEGACY    4

#define SPAWN_START_WEAPON  W_COLT
#define SPAWN_START_MAG     8
#define SPAWN_START_AMMO    32

float player_spawns[5];
entity spawn_points[5];
string spawn_names[4];

//
// Spawns_ConvertOldClassnames()
// Renames old/legacy spawns to their
// newly assocated names.
//
void() Spawns_ConvertOldClassnames =
{
    entity spawn_point;

    spawn_point = find(world, classname, "info_player_tank");
    if (spawn_point != world) spawn_point.classname = SPAWN_1_CLASS;
    spawn_point = find(world, classname, "info_player_nikolai");
    if (spawn_point != world) spawn_point.classname = SPAWN_2_CLASS;
    spawn_point = find(world, classname, "info_player_takeo");
    if (spawn_point != world) spawn_point.classname = SPAWN_3_CLASS;
    spawn_point = find(world, classname, "info_player_doctor");
    if (spawn_point != world) spawn_point.classname = SPAWN_4_CLASS;
};

//
// Spawns_EntIsInRange(which, units)
// Returns true if there is a solid entity
// within the provided units at a given
// entity's origin.
//
float(entity which, float units) Spawns_EntIsInRange =
{
    float found_something = false;

    entity ents_in_range = findradius(which.origin, units);
    while(ents_in_range != world) {
        if (ents_in_range != which && 
        ents_in_range.solid != SOLID_NOT && 
        ents_in_range.solid != SOLID_TRIGGER)
            found_something = true;

        ents_in_range = ents_in_range.chain;
    }

    return found_something;
}

//
// Spawns_PerformCheck(which, start_org, ...)
// Performs various checks at different positions
// for positioning of a spawn point if one is
// not provided by the map. Sets the origin if
// spot is valid.
//
float (entity which, vector start_org, vector dir, 
float units, vector feet, vector head) Spawns_PerformCheck =
{
    // Try moving the designated units                                              
    vector org = start_org + (dir * units);
    which.origin = org;
    which.solid = SOLID_BBOX;
    setorigin(which, which.origin);

    // If there's no ents in the way, check that we're
    // not stuck inside a brush.
    if (!Spawns_EntIsInRange(which, 64)) {
        feet = start_org /*- '0 0 16'*/;
        traceline (feet, feet + (dir * units), 0, spawn_points[SPAWN_PLR_1]);

        // We were successfully able to trace at the feet.
        if (trace_ent.classname == which.classname) {
            // Now try the head.
            head = start_org + '0 0 32';
            traceline (head, head + (dir * units), 0, spawn_points[SPAWN_PLR_1]);

            // Both feed and head are in the same boundary, one last step --
            // is this ent partially or totally in the world?
            if (trace_ent.classname == which.classname) {
                return Player_CanStandHere(which);
            }
        }
    }

    return false;
};

//
// Spawns_SetAllNonSolid(ignore_first)
// Marks all spawn points as SOLID_NOT,
// use ignore_first to ommit player 1.
//
void(float ignore_first) Spawns_SetAllNonSolid =
{
    float start;

    if (ignore_first) start = 1;
    else start = 0;

    for(float i = start; i < 4; i++) {
        if (spawn_points[i] == world)
            continue;

        spawn_points[i].solid = SOLID_NOT;
        setorigin(spawn_points[i], spawn_points[i].origin);
    }
};

//
// Spawns_SetAllSolid(ignore_first)
// Marks all spawn points as SOLID_BBOX,
// use ignore_first to ommit player 1.
//
void(float ignore_first) Spawns_SetAllSolid =
{
    float start;

    if (ignore_first) start = 1;
    else start = 0;

    for(float i = start; i < 4; i++) {
        if (spawn_points[i] == world)
            continue;

        spawn_points[i].solid = SOLID_BBOX;
        setorigin(spawn_points[i], spawn_points[i].origin);
    }
};

//
// Spawns_FindViableSpawnSpot(which)
// Uses a simple "algorithm" for predicting
// potential viable spawn points, and calls
// Spawns_PerformCheck() to validate and
// set if able.
//
void(entity which) Spawns_FindViableSpawnSpot =
{
    vector org = '0 0 0';
    vector trace_feet = '0 0 0';
    vector trace_head = '0 0 0';

    // Always start with the "main" (player 1) spawn
    vector start_origin = spawn_points[SPAWN_PLR_1].origin;
    makevectors(spawn_points[SPAWN_PLR_1].angles);

    // Spawn point determination "algorithm" is really simple --
    // We have "ideal" positioning that looks like this:
    // ---
    //   3
    // 2 1 4
    // ---
    // If any spot (other than 1) fails, try the next, when 4
    // is reached, start from the left again with a larger
    // distance from one, e.g.:
    // ---
    //     3
    // 4 2 1
    // ---
    // We do this for 2 cycles (64 units, 128 units, 192 units)
    // before giving up and just setting a spawn to slot 1, but
    // this SHOULD never happen(?!).

    float units = 64;

    for (float i = 0; i < 2; i++) {
        // Try moving to the "left".
        if (Spawns_PerformCheck(which, start_origin, v_right, -units, trace_feet, trace_head)) {
            Spawns_SetAllSolid(true);
            return;
        }

        // Now "forward".
        if (Spawns_PerformCheck(which, start_origin, v_forward, units, trace_feet, trace_head)) {
            Spawns_SetAllSolid(true);
            return;
        }

        // Now "right".
        if (Spawns_PerformCheck(which, start_origin, v_right, units, trace_feet, trace_head)) {
            Spawns_SetAllSolid(true);
            return;
        }

        // Now "back".
        if (Spawns_PerformCheck(which, start_origin, v_forward, -units, trace_feet, trace_head)) {
            Spawns_SetAllSolid(true);
            return;
        }

        // Increase the distance by 64 units and try again.
        Spawns_SetAllNonSolid(true);
        units += 64;
    }

    // Every attempt failed, just put them in the same
    // spot as player one.
    setorigin(which, start_origin);
    bprint(PRINT_HIGH, "WARN: Unable to find viable player start position\n");
    bprint(PRINT_HIGH, strcat("      for entity: ", which.classname));
    bprint(PRINT_HIGH, "\n");
};

//
// Spawns_DropToFloor(who)
// Drops the spawn point to
// the floor.
//
void(entity who) Spawns_DropToFloor =
{
    entity tempe = self;
    self = who;

#ifdef FTE

    droptofloor();

#else

    droptofloor(0, 0);

#endif // FTE

    self = tempe;
}

//
// Spawns_SetUpPoint(which)
// Sets up base stats for a Spawn
// Point such as size, and any fields
// not provided by map maker.
//
void(entity which) Spawns_SetUpPoint =
{
    which.solid = SOLID_BBOX;
    setsize(which, [-8, -8, -32], [8, 8, 40]);

    // NZ:P Beta was pretty relaxed when it came to spawn validity..
    // so doing this causes breakage on maps like Ankunft.
    if (map_compatibility_mode != MAP_COMPAT_BETA)
        Spawns_DropToFloor(which);

    if (!which.weapon) {
        which.weapon = SPAWN_START_WEAPON;
        which.currentmag = SPAWN_START_MAG;
        which.currentammo = SPAWN_START_AMMO;
    }
};

//
// Spawns_FillMissing()
// Creates any missing Spawn Points,
// setting up their fields if necessary.
//
void() Spawns_FillMissing =
{
    float i;

    // Count how many spawnpoints we have.
    for(i = 0; i < 4; i++) {
        spawn_points[i] = find(world, classname, spawn_names[i]);
        if (spawn_points[i] != world) {
            player_spawns[i] = true;
            Spawns_SetUpPoint(spawn_points[i]);
        }
    }

    // Store the legacy spawn point as well (info_player_start).
    spawn_points[SPAWN_PLR_LEGACY] = find(world, classname, "info_player_start");
    if (spawn_points[SPAWN_PLR_LEGACY] != world) {
        player_spawns[SPAWN_PLR_LEGACY] = true;
        Spawns_SetUpPoint(spawn_points[SPAWN_PLR_LEGACY]);
        Spawns_DropToFloor(spawn_points[i]);
    }

    // If there's no player 1 spawn or legacy spawn, crash.
    if (player_spawns[SPAWN_PLR_LEGACY] == false &&
    player_spawns[SPAWN_PLR_1] == false) {
        error("Spawns_FillMissing: No spawn points set in level.\n");
        return;
    }

    // If there's a legacy spawn, and a player 1 spawn,
    // remove the legacy spawn.
    if (player_spawns[SPAWN_PLR_LEGACY] == true &&
    player_spawns[SPAWN_PLR_1] == true) {
        remove(spawn_points[SPAWN_PLR_LEGACY]);
        player_spawns[SPAWN_PLR_LEGACY] = false;
    }

    // Convert info_player_start to info_player_1_spawn
    if (player_spawns[SPAWN_PLR_LEGACY] == true) {
        spawn_points[SPAWN_PLR_LEGACY].classname = SPAWN_1_CLASS;
        spawn_points[SPAWN_PLR_1] = spawn_points[SPAWN_PLR_LEGACY];
        player_spawns[SPAWN_PLR_1] = true;
        player_spawns[SPAWN_PLR_LEGACY] = false;
    }

    // Spawn points 2-4 if they dont exist
    for(i = 1; i < 4; i++) {
        if (player_spawns[i] == false) {
            spawn_points[i] = spawn();
            spawn_points[i].classname = spawn_names[i];
            spawn_points[i].angles = spawn_points[SPAWN_PLR_1].angles;
            Spawns_SetUpPoint(spawn_points[i]);
            Spawns_FindViableSpawnSpot(spawn_points[i]);
        }
    }

    Spawns_SetAllNonSolid(false);
};

//
// Spawns_SetUpClassnames()
// Fills the spawn_names[] array
// with the classnames for the
// associated index.
//
void() Spawns_SetUpClassnames =
{
    spawn_names[0] = SPAWN_1_CLASS;
    spawn_names[1] = SPAWN_2_CLASS;
    spawn_names[2] = SPAWN_3_CLASS;
    spawn_names[3] = SPAWN_4_CLASS;
};

//
// Spawns_Init()
// Provide backwards compatibility
// checks for old Spawn Points and
// creates any that are absent.
//
void() Spawns_Init =
{
    Spawns_ConvertOldClassnames();
    Spawns_SetUpClassnames();
    Spawns_FillMissing();
};