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
