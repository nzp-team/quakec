/*
	server/ai/standard/zoning_core.qc

	Zoning System

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

string zone_version;
float has_zone_file;
float zone_timer;

float num_zones;
// zombie spawn delay is every 2 seconds by default
// offset zone check delay to every 3 seconds 
// in attempt to reduce calculation load
float zone_timer_delay = 3;

// remove all instances of spawn_zone.. we already have the neccesary data
void() spawn_zone =
{
    remove(self);
    return;
}

void(float active_zone) Zoning_DecideZombieSpawns =
{
    vector brush_mins;
    vector brush_maxs;

    entity zombie_spawns;
    entity reset_spawns;
    zombie_spawns = find(world, classname, "spawn_zombie");

    brush_mins = '0.0 0.0 0.0';
    brush_maxs = '0.0 0.0 0.0';

    // do we have any active zombie spawns?
    while (zombie_spawns != world) {

        if(zombie_spawns.targetname == "") {
            // identify spawn room zombies and set their correct targets
            zombie_spawns.targetname = stored_zones[active_zone].targets;
        }

        reset_spawns = find(world, classname, "spawn_zombie_disabled");

        while (reset_spawns != world) {
            dprint("found a spawn_zombie_disabled");
            dprint("\n");
            // reset zombie spawns in the active zone
            if (reset_spawns.target == stored_zones[active_zone].targets) {
                dprint("resetting disabled zombie in active zone");
                dprint("\n");
                reset_spawns.classname = "spawn_zombie";
            }
            reset_spawns = find(reset_spawns, classname, "spawn_zombie_disabled");
        }

        // check if this zombie spawn is NOT inside of the active zone
        // if so, set the spawn inactive for now

        if (zombie_spawns.targetname != stored_zones[active_zone].targets) {
            dprint("setting spawn inactive");
            dprint("\n");
            zombie_spawns.classname = "spawn_zombie_disabled";
        }

        // check if this zombie spawn is NOT inside of any zones adjacent 
        // to the active zone
        for (float i = 0; i < stored_zones[active_zone].num_adj_zones; i++) {
            for (float j = 0; j < num_zones; j++) {
                // which zone id does this adjacent zone belong to?
                if (stored_zones[j].id == stored_zones[i].adj_zone_id[i]) {

                    reset_spawns = find(world, classname, "spawn_zombie_disabled");

                    while (reset_spawns != world) {
                        // this zone's zombie spawn needs reactivated
                        if (reset_spawns.targetname == stored_zones[j].targets) {
                            dprint("found inactive in adj zone, setting active");
                            dprint("\n");
                            reset_spawns.classname = "spawn_zombie";
                        }
                        reset_spawns = find(reset_spawns, classname, "spawn_zombie_disabled");
                    }
                 
                    dprint("targetname: ");
                    dprint(zombie_spawns.targetname);
                    dprint("\n");

                    // we found a match.
                    if (zombie_spawns.targetname != stored_zones[j].targets) {
                        // set the zombie spawn inactive for now
                        dprint("setting zombie outside of adjacent zone inactive");
                        dprint("\n");
                        zombie_spawns.classname = "spawn_zombie_disabled";
                    }

                }
            }
        }
        zombie_spawns = find(zombie_spawns, classname, "spawn_zombie");
    }

    return;
}

float() Zoning_ReturnCurrentZone =
{
    vector brush_mins;
    vector brush_maxs;
    float current_zone = 0;

    entity players;
	players = find(world, classname, "player");

    brush_mins = '0.0 0.0 0.0';
    brush_maxs = '0.0 0.0 0.0';

    while (players != world) {
        
        // check which zone this player is currently in
        for (float i = 0; i < num_zones; i++) {
            // iterate through all brushes in zone
            for (float k = 0; k < stored_zones[i].num_brushes; k++) {

                brush_mins = stored_zones[i].brush_mins[k];
                brush_maxs = stored_zones[i].brush_maxs[k];
                // check to see if there's a player inside of a brush
                if (players.origin_x >= brush_mins_x && players.origin_x <= brush_maxs_x) {
                    if (players.origin_y >= brush_mins_y && players.origin_y <= brush_maxs_y) {
                        if (players.origin_z >= brush_mins_z && players.origin_z <= brush_maxs_z) {
                            // player found. assign zone information
                            players.current_zone_name = stored_zones[i].name;
                            players.current_zone_id = stored_zones[i].id;
                            current_zone = i;
                            break;
                        }
                    }
                }
            }
        }

        players = find(players, classname, "player");
    }
    
    return current_zone;
}

void() Zoning_CheckZones =
{
    // do we have a zone file?
    if (!has_zone_file)         return;
    // is it time to check active zones?
    if (zone_timer > time)      return;
    // is anyone even alive?
    if (!PollPlayersAlive())    return;

    float current_zone = Zoning_ReturnCurrentZone();

    dprint("Current Zone: ");
    dprint(stored_zones[current_zone].name);
    dprint("\n");

    Zoning_DecideZombieSpawns (current_zone);

    zone_timer = zone_timer_delay + time;
    return;
}

void(float zone_file) Zoning_ParseZoneFile =
{
    string h;
    string zone_header;
    float parsing = 1;

    while (parsing) {
        dprint("Loading zone information");
        dprint("\n");

        h = fgets(zone_file);
        zone_header = substring(h, 0, 17);
        if (zone_header != "zone_file_version") {
            dprint("Invalid zone file!");
            dprint("\n");
            parsing = 0;
        }

        zone_version = substring(h, 19, 23);

        dprint("Zone format version: ");
        dprint(zone_version);
        dprint("\n");

        h = fgets(zone_file);
        num_zones = stof(substring(h, 17, 20));

        dprint("num_zones: ");
        dprint(ftos(num_zones));
        dprint("\n");

        for(float i = 0; i < num_zones; i++) {

            dprint("Loading zone: ");
            dprint(ftos(i+1));
            dprint("\n");

            h = fgets(zone_file);
            stored_zones[i].name = strzone(strtrim(h));

            dprint("zone_name: ");
            dprint(stored_zones[i].name);
            dprint("\n");

            h = fgets(zone_file);
            stored_zones[i].id = stof(strzone(strtrim(h)));

            dprint("zone_id: ");
            dprint(ftos(stored_zones[i].id));
            dprint("\n");

            h = fgets(zone_file);
            stored_zones[i].targets = strzone(strtrim(h));

            dprint("zone_targets: ");
            dprint(stored_zones[i].targets);
            dprint("\n");
            
            h = fgets(zone_file);
            stored_zones[i].fog_value = strzone(strtrim(h));

            dprint("fog_value ");
            dprint(stored_zones[i].fog_value);
            dprint("\n");

            h = fgets(zone_file);
            stored_zones[i].num_adj_zones = stof(strzone(strtrim(h)));

            dprint("num_adj_zones: ");
            dprint(ftos(stored_zones[i].num_adj_zones));
            dprint("\n");

            for(float j = 0; j < stored_zones[i].num_adj_zones; j++) {
                h = fgets(zone_file);
                stored_zones[i].adj_zone_id[j] = stof(strzone(strtrim(h)));

                dprint("adj_zone_id: ");
                dprint(ftos(stored_zones[i].adj_zone_id[j]));
                dprint("\n");
            }

            h = fgets(zone_file);
            stored_zones[i].num_brushes = stof(strzone(strtrim(h)));

            dprint("num_brushes: ");
            dprint(ftos(stored_zones[i].num_brushes));
            dprint("\n");

            for (float k = 0; k < stored_zones[i].num_brushes; k++) {
                h = fgets(zone_file);
                stored_zones[i].brush_mins[k] = stov(substring(h, 0, 50));
                h = fgets(zone_file);
                stored_zones[i].brush_maxs[k] = stov(substring(h, 0, 50));

                dprint("brush_mins: ");
                dprint(vtos(stored_zones[i].brush_mins[k]));
                dprint("\n");

                dprint("brush_maxs: ");
                dprint(vtos(stored_zones[i].brush_maxs[k]));
                dprint("\n");
            }

        }

        parsing = 0;
    }

    has_zone_file = 1;

    return;
}

void() Zoning_LoadData =
{
    float file;
    string h;

    h = strcat(mappath, ".nsz");
	file = fopen (h, FILE_READ);

    if (file == -1) {
        dprint("Unable to load zoning file\n");
        has_zone_file = 0;
        return;
    }

    Zoning_ParseZoneFile(file);

    fclose(file);
}