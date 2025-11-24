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
// the last known zone for a player
float previous_zone;
// zone_changed returns true if the current zone is different
// from the previous zone
float zone_changed;

// remove all instances of spawn_zone.. we already have the neccesary data
void() spawn_zone =
{
    remove(self);
    return;
}

void(float active_zone) Zoning_DecideZombieSpawns =
{
    entity zombie_spawns;
    entity dog_spawns;
    entity reset_spawns;

    dprint("\n");
    dprint("Disabling active zombie spawns");
    dprint("\n");

    entity players = find(world, classname, "player");
    while (players != world) 
    {
        // if this is a dog round
        if (roundtype == 2) {
            dog_spawns = find(world, classname, "spawn_dog");
            while (dog_spawns != world) {

                dog_spawns.classname = "dog_spawn_disabled";

                // re-enable spawns in all players current zone
                if (stored_zones[players.zone].targets == dog_spawns.targetname) {
                        dprint("keeping spawn in zone ");
                        dprint(stored_zones[players.zone].name);
                        dprint("\n");
                        dog_spawns.classname = "spawn_dog";
                }

                // do the same for adjacent zones
                for (float i = 0; i < stored_zones[players.zone].num_adj_zones; i++) {
                    float adj_zone = stored_zones[players.zone].adj_zone_id[i];

                    for (float j = 0; j < num_zones; j++) {
                        if (stored_zones[j].id == adj_zone) {
                            // found adjacent zone
                            if (dog_spawns.targetname == stored_zones[j].targets) {
                                // don't disable these spawns either
                                dprint("keeping spawn in zone ");
                                dprint(stored_zones[j].name);
                                dprint("\n");
                                dog_spawns.classname = "spawn_dog";
                            }
                        }
                    }
                }

                dog_spawns = find(dog_spawns, classname, "spawn_dog");
            }

            dog_spawns = find(world, classname, "spawn_dog_disabled");
            while (dog_spawns != world) {

                // re-enable zombie spawns that match zone target in current zone 
                if (dog_spawns.targetname == stored_zones[active_zone].targets) {
                    dog_spawns.classname = "spawn_dog";
                    dprint("reactivating spawn in zone ");
                    dprint(stored_zones[active_zone].name);
                    dprint("\n");
                }

                // re-enable zombie spawns that match adjacent zone targets
                for (float k = 0; k < stored_zones[active_zone].num_adj_zones; k++) {
                    float adj_zone = stored_zones[active_zone].adj_zone_id[k];

                    for (float l = 0; l < num_zones; l++) {
                        if (stored_zones[l].id == adj_zone) {
                            // found adjacent zone
                            if (dog_spawns.targetname == stored_zones[l].targets) {
                                dprint("reactivating spawn in zone ");
                                dprint(stored_zones[l].name);
                                dprint("\n");
                                dog_spawns.classname = "spawn_dog";
                                break;
                            }
                        }
                    }
                }

                dog_spawns = find(dog_spawns, classname, "spawn_dog_disabled");
            }
        } else {

            // disable all active spawns first
            // but not ones in players zone or adjacent zones
            zombie_spawns = find(world, classname, "spawn_zombie");
            while (zombie_spawns != world) {

                if(zombie_spawns.targetname == "") {
                    // identify spawn room zombies and set their correct targets
                    zombie_spawns.targetname = stored_zones[active_zone].targets;
                }

                zombie_spawns.classname = "spawn_zombie_disabled";
                
                // re-enable spawns in all players current zone
                if (stored_zones[players.zone].targets == zombie_spawns.targetname) {
                        dprint("keeping spawn in zone ");
                        dprint(stored_zones[players.zone].name);
                        dprint("\n");
                        zombie_spawns.classname = "spawn_zombie";
                }

                // do the same for adjacent zones
                for (float i = 0; i < stored_zones[players.zone].num_adj_zones; i++) {
                    float adj_zone = stored_zones[players.zone].adj_zone_id[i];

                    for (float j = 0; j < num_zones; j++) {
                        if (stored_zones[j].id == adj_zone) {
                            // found adjacent zone
                            if (zombie_spawns.targetname == stored_zones[j].targets) {
                                // don't disable these spawns either
                                dprint("keeping spawn in zone ");
                                dprint(stored_zones[j].name);
                                dprint("\n");
                                zombie_spawns.classname = "spawn_zombie";
                            }
                        }
                    }
                }
                zombie_spawns = find(zombie_spawns, classname, "spawn_zombie");
            }
        }

        zombie_spawns = find(world, classname, "spawn_zombie_disabled");
        while (zombie_spawns != world) {

            // re-enable zombie spawns that match zone target in current zone 
            if (zombie_spawns.targetname == stored_zones[active_zone].targets) {
                zombie_spawns.classname = "spawn_zombie";
                dprint("reactivating spawn in zone ");
                dprint(stored_zones[active_zone].name);
                dprint("\n");
            }

            // re-enable zombie spawns that match adjacent zone targets
            for (float k = 0; k < stored_zones[active_zone].num_adj_zones; k++) {
                float adj_zone = stored_zones[active_zone].adj_zone_id[k];

                for (float l = 0; l < num_zones; l++) {
                    if (stored_zones[l].id == adj_zone) {
                        // found adjacent zone
                        if (zombie_spawns.targetname == stored_zones[l].targets) {
                            dprint("reactivating spawn in zone ");
                            dprint(stored_zones[l].name);
                            dprint("\n");
                            zombie_spawns.classname = "spawn_zombie";
                            break;
                        }
                    }
                }
            }

            zombie_spawns = find(zombie_spawns, classname, "spawn_zombie_disabled");
        }

        players = find(players, classname, "player");
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
                // check to see if there's a player inside of a known brush
                if (players.origin_x >= brush_mins_x && players.origin_x <= brush_maxs_x) {
                    if (players.origin_y >= brush_mins_y && players.origin_y <= brush_maxs_y) {
                        if (players.origin_z >= brush_mins_z && players.origin_z <= brush_maxs_z) {
                            players.zone = i;
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

void(float this_zone) Zoning_PrintZones =
{
    bprint(PRINT_HIGH, "Current Zone: ");
    bprint(PRINT_HIGH, stored_zones[this_zone].name);
    bprint(PRINT_HIGH, "\n");

    bprint(PRINT_HIGH, "Previous Zone: ");
    bprint(PRINT_HIGH, stored_zones[previous_zone].name);
    bprint(PRINT_HIGH, "\n");

    for (float i = 0; i < stored_zones[this_zone].num_adj_zones; i++) {

        float adj_zone = stored_zones[this_zone].adj_zone_id[i];

        for (float k = 0; k < num_zones; k++) {
            if (stored_zones[k].id == adj_zone) {
                bprint(PRINT_HIGH, "Adj Zone Name: ");
                bprint(PRINT_HIGH, stored_zones[k].name);
                bprint(PRINT_HIGH, "\n");
                break;
            }
        }
    }

    bprint(PRINT_HIGH, "\n");
    return;
}

void(float power_flipped) Zoning_CheckZones =
{
    // do we have a zone file?
    if (!has_zone_file)         return;
    // is it time to check active zones?
    if (zone_timer > time)      return;
    // is anyone even alive?
    if (!PollPlayersAlive())    return;

    float current_zone = Zoning_ReturnCurrentZone(); 

    if (previous_zone == current_zone) {
        zone_changed = 0;
    }

    Zoning_PrintZones (current_zone);

    previous_zone = current_zone; 

    if (zone_changed || power_flipped) {
        Zoning_DecideZombieSpawns (current_zone);
        power_flipped = 0;
    }

    zone_changed = 1;

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