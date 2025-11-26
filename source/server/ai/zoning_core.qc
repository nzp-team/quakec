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
float zone_timer;

float num_zones;
// offset zone check delay to every 3 seconds 
// in attempt to reduce calculation load
float zone_timer_delay = 3;
// zone_changed returns true if the current zone is different
// from the previous zone
float zone_changed;
// the following store players current and previous zone
.float current_zone;
.float previous_zone;

// version 1.0.0 of the zone tool does not yet strip
// data from the map file, so we remove the entity here
void() spawn_zone =
{
    remove(self);
    return;
}

//
// Zoning_UpdateSpawns (players)
// Decides which spawns should 
// be activated or deactivated
// based on the players current 
// and adjacent zones
//
void(entity players) Zoning_UpdateSpawns =
{
    entity zombie_spawns;

    string active_spawn = "";
    string inactive_spawn = "";

    if (roundtype == 2) {
        // this is a dog round
        active_spawn = "spawn_dog";
        inactive_spawn = "spawn_dog_disabled";
    } else {
        // normal zombie round
        active_spawn = "spawn_zombie";
        inactive_spawn = "spawn_zombie_disabled";
    }

    // first we need to check which active spawns
    // need to be kept as active
    zombie_spawns = find(world, classname, active_spawn);
    while (zombie_spawns != world) {

        if(zombie_spawns.targetname == "") {
            // this spawn doesn't have a target set
            zombie_spawns.targetname = stored_zones[players.current_zone].targets;
        }

        // disable all active spawns first
        zombie_spawns.classname = inactive_spawn;
        
        // re-enable spawns in players current zone
        if (stored_zones[players.current_zone].targets == zombie_spawns.targetname) {
                // set these spawns back to active
                zombie_spawns.classname = active_spawn;
        }

        // do the same for adjacent zones
        for (float i = 0; i < stored_zones[players.current_zone].num_adj_zones; i++) {
            float adj_zone = stored_zones[players.current_zone].adj_zone_id[i];
            for (float j = 0; j < num_zones; j++) {
                if (stored_zones[j].id == adj_zone) {
                    // found adjacent zone
                    if (zombie_spawns.targetname == stored_zones[j].targets) {
                        // don't disable these spawns either
                        zombie_spawns.classname = active_spawn;
                        break;
                    }
                }
            }
        }
        zombie_spawns = find(zombie_spawns, classname, active_spawn);
    }

    // now we check to see if a deactivated 
    // spawn needs to be reactivated or not
    zombie_spawns = find(world, classname, inactive_spawn);
    while (zombie_spawns != world) {

        // re-enable zombie spawns that match zone target in current zone 
        if (zombie_spawns.targetname == stored_zones[players.current_zone].targets) {
            zombie_spawns.classname = active_spawn;
        }

        // re-enable zombie spawns that match adjacent zone targets
        for (float k = 0; k < stored_zones[players.current_zone].num_adj_zones; k++) {
            float adj_zone = stored_zones[players.current_zone].adj_zone_id[k];
            for (float l = 0; l < num_zones; l++) {
                if (stored_zones[l].id == adj_zone) {
                    // found adjacent zone
                    if (zombie_spawns.targetname == stored_zones[l].targets) {
                        zombie_spawns.classname = active_spawn;
                        break;
                    }
                }
            }
        }
        zombie_spawns = find(zombie_spawns, classname, inactive_spawn);
    }

    return;
}

//
// Zoning_GetCurrentZone (players)
// Stores each players current zone
// inside of a global .float
// players.current_zone
//
#ifdef DEBUG
void(entity players) Zoning_GetCurrentZone =
{
    vector brush_mins;
    vector brush_maxs;

    brush_mins = '0.0 0.0 0.0';
    brush_maxs = '0.0 0.0 0.0';

    // check which zone this player is currently in.
    // start by looking through possible zones
    for (float i = 0; i < num_zones; i++) {
        // iterate through all brushes in this zone
        for (float k = 0; k < stored_zones[i].num_brushes; k++) {
            brush_mins = stored_zones[i].brush_mins[k];
            brush_maxs = stored_zones[i].brush_maxs[k];
            // check to see if there's a player inside of a known brush
            if (players.origin_x >= brush_mins_x && players.origin_x <= brush_maxs_x) {
                if (players.origin_y >= brush_mins_y && players.origin_y <= brush_maxs_y) {
                    if (players.origin_z >= brush_mins_z && players.origin_z <= brush_maxs_z) {
                        players.current_zone = i;
                        break;
                    }
                }
            }
        }
    }

    return;
}
#endif // DEBUG

//
// Zoning_SetFog (players)
// Sets a zones custom fog value
// which is updated per player
// individually
//
void(entity players) Zoning_SetFog =
{
    if (players == world)
		return;

    string fog_value = "";

    // get which zone this player is currently in
    Zoning_GetCurrentZone(players);

    // if this round is a dog round
    if (rounds == dogRound && map_has_hellhounds) {
        roundtype = 2;
        fog_value = strcat(game_modifier_hellhound_fog_color, "\n");
    } else {
        // zombie round
        roundtype = 1;
        
        if (has_zone_file) {
            // no fog value stored in this zone
            if (stored_zones[players.current_zone].fog_value == "") {
                if (game_modifier_default_fog_color != "")
                            // use whole map fog if available
                            fog_value = strcat(game_modifier_default_fog_color, "\n");
                        else
                            fog_value = "0 0 0 0 0\n";
            } else {
                // we have custom fog for this zone
                fog_value = strcat(stored_zones[players.current_zone].fog_value, "\n");
            }
        } else {
            if (game_modifier_default_fog_color != "") {
				fog_value = strcat(game_modifier_default_fog_color, "\n");
            } else {
                fog_value = "0 0 0 0 0\n";
            }
        }
    }

    stuffcmd(players, strcat("fog ", fog_value));

    return;
}

//
// Zoning_PrintZones (players)
// Unused debug function
// leftover in case of future bugs
//
void(entity players) Zoning_PrintZones =
{
    dprint("Current Zone: ");
    dprint(stored_zones[players.current_zone].name);
    dprint("\n");

    dprint("Previous Zone: ");
    dprint(stored_zones[players.previous_zone].name);
    dprint("\n");

    for (float i = 0; i < stored_zones[players.current_zone].num_adj_zones; i++) {
        float adj_zone = stored_zones[players.current_zone].adj_zone_id[i];
        for (float k = 0; k < num_zones; k++) {
            if (stored_zones[k].id == adj_zone) {
                dprint("Adj Zone Name: ");
                dprint(stored_zones[k].name);
                dprint("\n");
                break;
            }
        }
    }

    dprint("\n");
    return;
}

//
// Zoning_UpdateAllZones (power_flipped)
// Updates each players current zone 
// on a timer set for ~3 seconds
// which fires spawn and fog logic
//
void(float power_flipped) Zoning_UpdateAllZones =
{
    // do we have a zone file?
    if (!has_zone_file)         return;
    // is it time to check active zones?
    if (zone_timer > time)      return;

    entity players;
	players = find(world, classname, "player");

    while(players != world) {
        // get this players current zone stored in
        // stored_zones[players.current_zone]
        Zoning_GetCurrentZone(players); 

        // zone hasn't changed
        if (players.previous_zone == players.current_zone) {
            zone_changed = 0;
        }
        
#ifdef DEBUG
        // debug information
        Zoning_PrintZones (players.current_zone);
#endif // DEBUG

        // set previous zone to current zone
        players.previous_zone = players.current_zone; 

        // if the zone has changed then we want
        // to decide which spawns to keep active
        // and also update the fog per player
        if (zone_changed || power_flipped) {
            Zoning_UpdateSpawns(players);
            Zoning_SetFog(players);
            // if the power was just turned on then 
            // we need to update regardless of if you've 
            // changed zones or not
            power_flipped = 0;
        }

        zone_changed = 1;

        // wait 3 seconds before checking again
        zone_timer = zone_timer_delay + time;

        players = find(players, classname, "player");
    }
    return;
}

//
// Zoning_ParseZoneFile (zone_file)
// Parses a zone file supplied by mapper
// and stores the data of each zone
// into stored_zones[num_zones]
//
void(float zone_file) Zoning_ParseZoneFile =
{
    string h;
    string zone_header;
    float parsing = 1;

    while (parsing) {
        // read the header to validate that
        // this is a zone file
        h = fgets(zone_file);
        zone_header = substring(h, 0, 17);
        if (zone_header != "zone_file_version") {
            parsing = 0;
        }
        // version of the zone file
        zone_version = substring(h, 19, 23);
        // number of zones in map
        h = fgets(zone_file);
        num_zones = stof(substring(h, 17, 20));

        for(float i = 0; i < num_zones; i++) {
            // zone name
            h = fgets(zone_file);
            stored_zones[i].name = strzone(strtrim(h));
            // zone id
            h = fgets(zone_file);
            stored_zones[i].id = stof(strzone(strtrim(h)));
            // zone targets
            h = fgets(zone_file);
            stored_zones[i].targets = strzone(strtrim(h));
            // zone custom fog value
            h = fgets(zone_file);
            stored_zones[i].fog_value = strzone(strtrim(h));
            // number of adjacent zones
            h = fgets(zone_file);
            stored_zones[i].num_adj_zones = stof(strzone(strtrim(h)));
            // adjacent zones id's
            for(float j = 0; j < stored_zones[i].num_adj_zones; j++) {
                h = fgets(zone_file);
                stored_zones[i].adj_zone_id[j] = stof(strzone(strtrim(h)));
            }
            // number of brushes in this zone
            h = fgets(zone_file);
            stored_zones[i].num_brushes = stof(strzone(strtrim(h)));
            // all brush mins/maxs
            for (float k = 0; k < stored_zones[i].num_brushes; k++) {
                h = fgets(zone_file);
                string brush_mins = strzone(strtrim(h));
                vector brush_mins_vec = stov(brush_mins);
                stored_zones[i].brush_mins[k][0] = brush_mins_vec_x;
                stored_zones[i].brush_mins[k][1] = brush_mins_vec_y;
                stored_zones[i].brush_mins[k][2] = brush_mins_vec_z;
                h = fgets(zone_file);
                string brush_maxs = strzone(strtrim(h));
                vector brush_maxs_vec = stov(brush_maxs);
                stored_zones[i].brush_maxs[k][0] = brush_maxs_vec_x;
                stored_zones[i].brush_maxs[k][1] = brush_maxs_vec_y;
                stored_zones[i].brush_maxs[k][2] = brush_maxs_vec_z;
            }
        }
        parsing = 0;
    }

    has_zone_file = 1;

    return;
}

//
// Zoninng_LoadData ()
// Open the zone file we
// want to parse
//
void() Zoning_LoadData =
{
    float file;
    string h;

    h = strcat(mappath, ".nsz");
	file = fopen (h, FILE_READ);

    if (file == -1) {
        dprint("Zone file not present\n");
        has_zone_file = 0;
        return;
    }

    Zoning_ParseZoneFile(file);

    fclose(file);
}