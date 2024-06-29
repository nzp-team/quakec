/*
	server/dummies/generic.qc

	generic (all platform) dummys

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

// Triggers
void() trigger_changelevel      = {remove(self);};
void() trigger_counter          = {remove(self);};
void() trigger_secret           = {remove(self);};
void() trigger_setskill         = {remove(self);};
void() trigger_monsterjump      = {remove(self);};
void() trigger_onlyregistered   = {remove(self);};
void() trigger_push             = {remove(self);};
// Player Starts
void() info_player_start        = {};
void() info_player_start2       = {};
void() info_player_deathmatch   = {};
void() info_player_coop         = {};
void() info_player_tank         = {};
void() info_player_nikolai		= {};
void() info_player_doctor		= {};
void() info_player_takeo		= {};
void() info_player_1_spawn 		= {};
void() info_player_2_spawn 		= {};
void() info_player_3_spawn 		= {};
void() info_player_4_spawn 		= {};

void() zombie_horde_point 		= {};

void() zapper1 = {remove(self);};
void() zapper2 = {remove(self);};
void() item_switch = {remove(self);};
void() zap_light = {remove(self);};
void() info_end = {remove(self);};

//// beta removal 
void() monster_dog = {remove(self);};
void() palm_tree_closed = {remove(self);};
void() func_model = {remove(self);};
void() wooden_crate = {remove(self);};

void() change_frame;
void() change_frame2 =
{
	self.frame++;
	self.think = change_frame;
	self.nextthink = time + 1;
}
void() change_frame =
{
	self.frame++;
	self.think = change_frame2;
	self.nextthink = time + 1;
}

#ifdef FTE

void(void() spawnfunc) CheckSpawn =
{
  //do your own skill/deathmatch spawnflag checks here because the engine won't when this function exists
  if (spawnfunc)
    spawnfunc();
  else
  {
    print(sprintf("no spawnfunc defined for %S\n", self.classname));
    remove(self);
  }
};

#endif // FTE

#ifndef FTE

void LoadWaypointData() = {};

#endif // FTE

// Old Demo defs
.float fogdogs;
.float MaxRange;
void() trigger_teleport = {remove(self);};
void() tigger_mainframe = {remove(self);}; //lol this typo is in their old fgd too, apparently.
void() trigger_teleport_area = {remove(self);};
