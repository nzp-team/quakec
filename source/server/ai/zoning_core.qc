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

void(float zone_file) Zoning_ParseZoneFile
{
    string h;
    string zone_header;
    float parsing = 1;
    float num_zones;

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

    return;
}

void() Zoning_LoadData
{
    float file;
    string h;

    h = strcat(mappath, ".nsz");
	file = fopen (h, FILE_READ);

    if (file == -1) {
        dprint("Unable to load zoning file\n");
        return;
    }

    Zoning_ParseZoneFile(file);

    fclose(file);
}