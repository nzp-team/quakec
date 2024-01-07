/*
	server/utilities/map_compatibility.qc

	Converts entities and other gameplay functions from earlier versions 
    of NZ:P to work here.

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

//
// NZ:P Beta Waypoints
//

//
// Compat_TryLoadBetaWaypoints()
// Called by FTE in LoadWaypointData(), if
// it can't find a traditional .way file, it'll
// look for an old one here.
//
#ifdef FTE
void() Compat_TryLoadBetaWaypoints =
{
    // NZ:P Beta Waypoint files are simple, but contain redundant and
    // hard to understand data. As far as I can gather both by interpretation
    // and by reading aging source code, the structure for waypoints are as
    // follows:
    // <origin> : Origin of waypoint entity, always comes before all else.
    // <id>     : Starts at one, index/id of waypoint.
    // <link1>  : First Waypoint link ID, of four. Zero refers to a non-link.
    // <link2>  : Second Waypoint link ID, of four. Zero refers to a non-link.
    // <link3>  : Third Waypoint link ID, of four. Zero refers to a non-link.
    // <link1>  : Fourth Waypoint link ID, of four. Zero refers to a non-link.
    // <owner1> : First marked "owner" ID, of four. Seems to only serve as a duplicate of links.
    // <owner2> : Second marked "owner" ID, of four. Seems to only serve as a duplicate of links.
    // <owner3> : Third marked "owner" ID, of four. Seems to only serve as a duplicate of links.
    // <owner4> : Fourth marked "owner" ID, of four. Seems to only serve as a duplicate of links.
    
    // File path refers to just "mapname" (no extension), the source port at
    // the time always defaulted this to data/mapname.
    float file_handle;
    file_handle = fopen(mapname, FILE_READ);

    if (file_handle == -1) {
        dprint("Compat_TryLoadBetaWaypoints: No Beta waypoint data found.\n");
        return;
    }

    float i;

    // Clear all waypoints
	for(i = 0; i < MAX_WAYPOINTS; i++) {
		waypoints[i].id = -1;

        for(float j = 0; j < 10; j++) {
            waypoints[i].target_id[j] = -1;
        }
	}

    string  file_line;
    vector  way_origin;
    float   way_id;
    float   way_targets[4];

    while(1) {
        file_line = fgets(file_handle);

        // End of file.
        if (!file_line)
            break;

        way_origin = stov(file_line); // <origin>
        file_line = fgets(file_handle);
        way_id = stof(file_line); // <id>

        // <link1> - <link4>, <owner1> - <owner4>
        for(i = 0; i < 8; i++) {
            file_line = fgets(file_handle);

            if (i < 4) {
                way_targets[i] = stof(file_line);
            }
        }

        // Fill our data structure.
        waypoint_ai waypoint;
		waypoint = waypoints[way_id];

		waypoints[way_id].id = way_id;
		waypoints[way_id].org = way_origin;

		if (waypoint_mode) {
			entity new_way = spawn();
			new_way.solid = SOLID_TRIGGER;
			new_way.touch = creator_way_touch;
			new_way.classname = "waypoint";
			new_way.waynum = ftos(way_id);
			new_way.targets[0] = ftos(way_targets[0]);
			new_way.targets[1] = ftos(way_targets[1]);
			new_way.targets[2] = ftos(way_targets[2]);
			new_way.targets[3] = ftos(way_targets[3]);
			setorigin(new_way, way_origin);
			setmodel(new_way, "models/way/normal_way.spr");
		}

        for(i = 0; i < 4; i++) {
            if (way_targets[i] > 0)
                waypoints[way_id].target_id[i] = way_targets[i];
        }
    }

    fclose(file_handle);
};
#endif // FTE

//
// NZ:P Beta Props
//

//
// Compat_ConvertPropScale(model_path, scale_factor)
// Does the dirty work for Compat_ConvertPropScaling().
//
void(string model_path, float scale_factor) Compat_ConvertPropScale =
{
    entity props = find(world, model, model_path);

    while(props != world) {
        props.scale = scale_factor;
        props = find(props, model, model_path);
    }
};

//
// Compat_ConvertWorldModelScales()
// Scales down every weapon world model in
// mass.
//
void() Compat_ConvertWorldModelScales =
{
    entity props = find(world, classname, "place_model");

    while(props != world) {
        // We only check the first path, this *technically* makes
        // a nasty assumption no one used the viewmodels ever..
        // which I damn sure hope is true, for the sake of that guy's sanity..
        if (substring(props.model, 0, 15) == "models/weapons/") {
            props.scale = 0.75;
        }

        props = find(props, classname, "place_model");
    }
};

//
// Compat_ConvertPropScaling()
// A lot of props nowadays are larger than
// originally designed, so scale them back
// down.
//
void() Compat_ConvertPropScaling =
{
    // Manual Tweaking
    Compat_ConvertPropScale("models/props/sandbags.mdl", 0.88);
    Compat_ConvertPropScale("models/props/lamp_oil.mdl", 0.75);

    // Automatic
    Compat_ConvertWorldModelScales();
};

//
// NZ:P Beta Wall Weapons
//

//
// Compat_ConvertBetaWallWeapons()
// NZ:P Beta used different weapon IDs to refer
// to weapon indexes, this fixes that.
//
void() Compat_ConvertBetaWallWeapons =
{
    entity weapons;
    weapons = find(world, classname, "buy_weapon");

    while(weapons != world) {
        switch(weapons.weapon) {
            case 1:     weapons.weapon = W_COLT; break;
            case 64:    weapons.weapon = W_RAY; break;
            case 129:   weapons.weapon = W_KAR_SCOPE; break;
            case 130:   weapons.weapon = W_BAR; break;
            case 131:   weapons.weapon = W_M1A1; break;
            case 132:   weapons.weapon = W_M2; break;
            case 133:   weapons.weapon = W_TESLA; break;
            case 134:   weapons.weapon = W_THOMPSON; break;
            case 135:   weapons.weapon = W_SAWNOFF; break;
            case 136:   weapons.weapon = W_PPSH; break;
            case 137:   weapons.weapon = W_DB; break;
            case 138:   weapons.weapon = W_KAR; break;
            case 139:   weapons.weapon = W_FG; break;
            case 140:   weapons.weapon = W_TRENCH; break;
            case 141:   weapons.weapon = W_MG; break;
            case 142:   weapons.weapon = W_GEWEHR; break;
            case 143:   weapons.weapon = W_BROWNING; break;
            case 144:   weapons.weapon = W_MP5K; break;
            case 145:   weapons.weapon = W_357; break;
            case 146:   weapons.weapon = W_M1; break;
            case 147:   weapons.weapon = W_BIATCH; break;
            case 148:   weapons.weapon = W_MP40; break;
            case 149:   weapons.weapon = W_PANZER; break;
            case 150:   weapons.weapon = W_PTRS; break;
            case 153:   weapons.weapon = W_BK; break;
            case 154:   weapons.weapon = W_STG; break;
            case 155:   weapons.weapon = W_BETTY; break;
            case 156:   weapons.weapon = W_GRENADE; break;
            case 182:   weapons.weapon = W_TYPE; break;
            case 157:   weapons.weapon = W_PORTER; break;
            case 158:   weapons.weapon = W_HEADCRACKER; break;
            case 159:   weapons.weapon = W_WIDOW; break;
            case 160:   weapons.weapon = W_WIDDER; break;
            case 161:   weapons.weapon = W_FIW; break;
            case 162:   weapons.weapon = W_WUNDER; break;
            case 163:   weapons.weapon = W_GIBS; break;
            case 164:   weapons.weapon = W_SNUFF; break;
            case 165:   weapons.weapon = W_REAPER; break;
            case 166:   weapons.weapon = W_BORE; break;
            case 167:   weapons.weapon = W_ARMAGEDDON; break;
            case 168:   weapons.weapon = W_IMPELLER; break;
            case 169:   weapons.weapon = W_GUT; break;
            case 170:   weapons.weapon = W_BARRACUDA; break;
            case 171:   weapons.weapon = W_COMPRESSOR; break;
            case 172:   weapons.weapon = W_ACCELERATOR; break;
            case 173:   weapons.weapon = W_KILLU; break;
            case 174:   weapons.weapon = W_KOLLIDER; break;
            case 175:   weapons.weapon = W_M1000; break;
            case 176:   weapons.weapon = W_AFTERBURNER; break;
            case 177:   weapons.weapon = W_LONGINUS; break;
            case 178:   weapons.weapon = W_PENETRATOR; break;
            case 179:   weapons.weapon = W_KRAUS; break;
            case 180:   weapons.weapon = W_SPATZ; break;
            case 181:   weapons.weapon = W_BOWIE; break;
            case 183:   weapons.weapon = W_SAMURAI; break;
            default:    break;
        }

        weapons = find(weapons, classname, "buy_weapon");
    }
};

//
// NZ:P Beta Barricades
//

//
// Compat_ConvertBetaBarricade
// Barricades need relocated, scaled, 
// and their goal boxes re-positioned.
//
void() Compat_ConvertBetaBarricade =
{
    makevectors(self.angles);
    self.origin += v_up*48;
    self.origin -= v_forward*2;
    setsize(self, '-30 -30 -10','30 30 10');
    self.box1 = self.origin + (v_forward * -50) + (v_up * -50);
	self.box2 = self.box1 + (v_right * 25);	
	self.box3 = self.box1 + (v_right * -25);
	self.idlebox = self.box1 + (v_forward * -50);
    self.hop_spot = self.origin + v_forward * 50;
    self.hop_spot_x -= 5;
	self.hop_spot_z -= 20;
    self.scale = 0.75;
};

void() item_cover = {map_compatibility_mode = MAP_COMPAT_BETA; item_barricade(); Compat_ConvertBetaBarricade();};

//
// NZ:P Beta Mystery Box
//

//
// Compat_FixMysteryBox
// Fixes the Mystery Box scale, and removes glow from
// all of the spawn points.
//
void() Compat_FixMysteryBox =
{
    entity mystery_box = find(world, classname, "mystery");

    while(mystery_box != world) {
        mystery_box.scale = 0.75;
        mystery_box.spawnflags += MBOX_SPAWNFLAG_NOLIGHT;

        if (mystery_box.goaldummy) {
            MBOX_FreeEnt(mystery_box.goaldummy);
            mystery_box.goaldummy = world;
        }

        mystery_box = find(mystery_box, classname, "mystery");
    }

    entity mystery_box_spots = find(world, classname, "mystery_box_tp_spot");

    while(mystery_box_spots != world) {
        mystery_box_spots.spawnflags += MBOX_SPAWNFLAG_NOLIGHT;

        mystery_box_spots = find(mystery_box_spots, classname, "mystery_box_tp_spot");
    }
};

//
// NZ:P Beta Power Switch
//

//
// Compat_FixPowerSwitch
// Power Switches had the same classname as they
// do now, so we need to iterate over the world
// and modify their scale and origin.
//
void() Compat_FixPowerSwitch =
{
    entity power_switches = find(world, classname, "power_switch");

    while(power_switches != world) {
        makevectors(power_switches.angles);
        power_switches.scale = 0.88;
        power_switches.origin += v_up*6;
        power_switches.origin += v_forward*10;

        power_switches = find(power_switches, classname, "power_switch");
    }
};

//
// NZ:P Beta Perk-A-Cola Machines
//

//
// Compat_RelocateBetaPerkMachine()
// Perk-A-Cola models in NZ:P Beta used to have
// non-center origin offsets, so they need re-placed
// to be (nearly) matching what they were intended to be.
// This also sets the scaling correctly, sue me.
//
#define COMPAT_RELOCAT_NORM     0
#define COMPAT_RELOCAT_PAP      1
#define COMPAT_RELOCAT_SPEED    2

void(float mode) Compat_RelocateBetaPerkMachine =
{
    makevectors(self.angles);

    switch(mode) {
        case COMPAT_RELOCAT_PAP:
            self.origin += v_forward*8;
            self.origin += v_up*24;
            break;
        case COMPAT_RELOCAT_SPEED:
            self.origin += v_forward*17;
            self.origin += v_up*2;
            break;
        default:
            self.origin += v_forward*10;
            self.origin += v_up*4;
            break;
    }

    self.scale = 0.85;
};

void() item_revive = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_revive();};
void() item_speed = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_SPEED); perk_speed();};
void() item_flopper = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_flopper();};
void() item_juggernog = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_juggernog();};
void() item_douple = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_double(); self.spawnflags += PERK_SPAWNFLAG_DOUBLETAPV1;};
void() item_staminup = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_staminup();};
void() item_pap = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_PAP); perk_pap();};

//
// NZ:P Beta Triggers
//

#ifdef FTE

//
// Compat_TriggerCommandIsSafe()
// Pass a trigger_command .message to this,
// it's a whitelist that determines whether
// or not we should let the map use this.
//
float(string msg) Compat_TriggerCommandIsSafe =
{
    // First check: Don't allow multiple commands, at all. So
    // fail if there's a ';' anywhere.
    for(float i = 0; i < strlen(msg) - 1; i++) {
        if (substring(msg, i, i + 1) == ";")
            return false;
    }

    // Allow playing audio and whatnot.
    if (substring(msg, 0, 4) != "play")
        return false;

    return true;
};

void() touch_command =
{
    if (other.classname != "player" || self.electro_targeted)
		return;

	self.electro_targeted = true;

    // Follow up with cl_insta because whoever wrote this way back
    // forgot to perform a line break..
    stuffcmd(other, strcat(self.message, "cl_insta\n"));
};

#endif // FTE

//
// trigger_command
// Whoever was behind this was nasty...
// on contact, this trigger runs a stuffcmd()
// to the touching client. Obviously, this can't
// fly.
//
void() trigger_command =
{
    map_compatibility_mode = MAP_COMPAT_BETA;

#ifdef FTE

    // If there's no message, or the message
    // is invalid, remove this garbage.
    if (!self.message || !Compat_TriggerCommandIsSafe(self.message)) {
       return;
    }

    InitTrigger();
	self.touch = touch_command;

#else

    remove(self);

#endif // FTE

};

//
// General NZ:P Compatibility
//

//
// Compat_ConvertOldAssetPath(path)
// Takes in a path as a string, hashes it,
// then performs a binary search to pick
// a redirected (updated) path.
//
string(string path) Compat_ConvertOldAssetPath =
{
    string return_string = path;

    // Generate a CRC16 IBM 3740 hash of the path
    float input_hash = crc16(true, path);
    float input_len = strlen(path); // Assists with hash collision detection.

    // Perform the binary search to locate it
    float bs_left = 0;
    float bs_right = asset_conversion_table.length - 1;

    while(bs_left <= bs_right) {
        float bs_middle = (bs_left + bs_right) / 2;
        bs_middle = bs_middle & ~0;

        if (asset_conversion_table[bs_middle].old_path_crc == input_hash && asset_conversion_table[bs_middle].crc_strlen == input_len) {
            return_string = asset_conversion_table[bs_middle].current_path;
            break;
        }

        if (asset_conversion_table[bs_middle].old_path_crc < input_hash)
            bs_left = bs_middle + 1;
        else
            bs_right = bs_middle - 1;
    }

    return return_string;
};

//
// Compat_Init()
// Called as soon as the server spawns in
// a client, does more conversion for
// map compatibility that cannot just be
// done in QC logic or in spawn functions.
//
void() Compat_Init =
{
    if (map_compatibility_mode != MAP_COMPAT_BETA)
        return;

    Compat_ConvertBetaWallWeapons();
    Compat_ConvertPropScaling();
    Compat_FixPowerSwitch();
    Compat_FixMysteryBox();
};