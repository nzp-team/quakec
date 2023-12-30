/*
	server/utilities/map_compatibility.qc

	Converts entities and other gameplay functions from earlier versions 
    of NZ:P to work here.

	Copyright (C) 2021-2023 NZ:P Team

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
        props = props = find(props, model, model_path);
    }
}

//
// Compat_ConvertPropScaling()
// A lot of props nowadays are larger than
// originally designed, so scale them back
// down.
//
void() Compat_ConvertPropScaling =
{
    Compat_ConvertPropScale("models/props/sandbags.mdl", 0.88);
}

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
}

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
	self.box2 = self.box1 + (v_right * 50);	
	self.box3 = self.box1 + (v_right * -50);
	self.idlebox = self.box1 + (v_forward * -50);
    self.hop_spot = self.origin + v_forward * 50;
    self.hop_spot_x -= 5;
	self.hop_spot_z -= 25;
    self.scale = 0.75;
}

void() item_cover = {map_compatibility_mode = MAP_COMPAT_BETA; item_barricade(); Compat_ConvertBetaBarricade();};

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
}

void() item_revive = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_revive();};
void() item_speed = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_SPEED); perk_speed();};
void() item_flopper = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_flopper();};
void() item_juggernog = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_juggernog();};
void() item_douple = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_double();};
void() item_staminup = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_NORM); perk_staminup();};
void() item_pap = {map_compatibility_mode = MAP_COMPAT_BETA; Compat_RelocateBetaPerkMachine(COMPAT_RELOCAT_PAP); perk_pap();};


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
}