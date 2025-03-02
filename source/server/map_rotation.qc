/*
	server/map_rotation.qc

	Map Rotation Logic for Dedicated Servers.

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
#ifdef FTE

#define MAPROTATION_MODE_DONTROTATE     0
#define MAPROTATION_MODE_FIXEDROTATION  1
#define MAPROTATION_MODE_RANDOM         2

//
// MapRotation_RestartMap()
// Loads the current map once again.
//
void() MapRotation_RestartMap =
{
    localcmd(sprintf("changelevel %s\n", mapname));
};

//
// MapRotation_GetRandomMap()
// Loads a random map in the server's
// map directory.
//
void() MapRotation_GetRandomMap =
{
    searchhandle maps;
    string map_path;
    string map_name;
    float map_count;
    float map_index;

    // Grab a random map file
	maps = search_begin("maps/*.bsp", 0, 0);
	map_count = search_getsize(maps);
    map_index = rint(random() * map_count);

    map_path = search_getfilename(maps, map_index);
	map_name = substring(map_path, 5, strlen(map_path)); // maps/
	map_name = substring(map_name, 0, strlen(map_name) - 4); // .bsp

    search_end(maps);

    localcmd(sprintf("changelevel %s\n", map_name));
};

//
// MapRotation_SelectNextMap()
// Loads the next map in the map rotation
// text file.
//
void() MapRotation_SelectNextMap =
{
    float rotation_file = fopen(sprintf("%s.txt", cvar_string("sv_maprotationbasename")), FILE_READ);

    if (rotation_file == -1) {
        MapRotation_GetRandomMap();
    }

    float load_loop = true;
    string map_to_load = "";
    string first_map = fgets(rotation_file);
    string current_map = first_map;

    while(load_loop) {
        // End of file, use the first map in the file.
        if (current_map == "") {
            load_loop = false;
			break;
		}

        // Current line is for our map, so load the next
        // and then break out.
        if (mapname == current_map) {
            map_to_load = fgets(rotation_file);
            load_loop = false;
            break;
        }

        current_map = fgets(rotation_file);
    }

    // If map_to_load is blank, use the first map in the rotation list.
    if (map_to_load == "") {
        map_to_load = first_map;
    }

    fclose(rotation_file);

    localcmd(sprintf("changelevel %s\n", strtrim(map_to_load)));
};

//
// MapRotation_Decide()
// Called at game's end, picks an appropriate
// map rotation mode.
//
void() MapRotation_Decide =
{
    float map_rotation_mode = cvar("sv_maprotationmode");

    switch(map_rotation_mode) {
        case MAPROTATION_MODE_DONTROTATE:
            MapRotation_RestartMap();
            break;
        case MAPROTATION_MODE_FIXEDROTATION:
            MapRotation_SelectNextMap();
            break;
        case MAPROTATION_MODE_RANDOM:
            MapRotation_GetRandomMap();
            break;
        default:
            MapRotation_RestartMap();
            break;
    }
};

#endif // FTE