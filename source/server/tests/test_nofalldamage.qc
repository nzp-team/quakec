/*
	server/tests/test_nofalldamage.qc

	Unit tests for func_nofalldamage landing volumes.

	Copyright (C) 2026 NZ:P Team

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
float(float condition, string message) Test_Assert;

//
// Test_NoFallDamage_BrushBounds()
// Ensures brush initialization preserves world-space bounds and hides
// the model without making the landing volume solid.
// (https://github.com/nzp-team/nzportable/issues/852)
//
void() Test_NoFallDamage_BrushBounds =
{
	entity old_self = self;
	entity old_head = nofall_volumes;
	self = spawn();

	setorigin(self, '100000 0 0');
	setmodel(self, world.model);
	vector lower = self.origin + self.mins;
	vector upper = self.origin + self.maxs;
	func_nofalldamage();

	Test_Assert((self.nofall_mins == lower && self.nofall_maxs == upper), "Brush initialization lost its world-space bounds!");
	Test_Assert((self.solid == SOLID_NOT && self.modelindex == 0 && self.model == ""), "Brush initialization left a visible or solid model!");
	Test_Assert((nofall_volumes == self && self.nofall_next == old_head), "Brush initialization did not register the volume!");
	nofall_volumes = old_head;
	remove(self);
	self = old_self;
};

//
// Test_NoFallVolume()
// Creates a passive landing volume with explicit bounds because these
// test fixtures have no BSP submodel.
//
entity(vector lower, vector upper) Test_NoFallVolume =
{
	entity old_self = self;
	self = spawn();
	func_nofalldamage();
	self.nofall_mins = lower;
	self.nofall_maxs = upper;
	entity volume = self;
	self = old_self;
	return volume;
};

//
// Test_NoFallDamage_FeetAndOverlaps()
// Ensures protection uses the player's feet and handles overlapping
// volumes, boundaries, and removed entities.
// (https://github.com/nzp-team/nzportable/issues/852)
//
void() Test_NoFallDamage_FeetAndOverlaps =
{
	entity old_head = nofall_volumes;
	nofall_volumes = world;
	entity first = Test_NoFallVolume('100000 0 -4', '100064 64 4');
	entity second = Test_NoFallVolume('100032 0 -4', '100096 64 4');
	entity player = spawn();
	setsize(player, '-16 -16 -24', '16 16 32');

	Test_Assert((first.solid == SOLID_NOT && first.modelindex == 0 && !first.touch), "Landing volume is not passive and invisible!");
	setorigin(player, '100016 32 24');
	Test_Assert((Player_InNoFallDamageZone(player)), "Feet inside volume were not protected!");
	setorigin(player, '100048 32 24');
	Test_Assert((Player_InNoFallDamageZone(player)), "Overlapping volumes lost protection!");
	setorigin(player, '100080 32 24');
	Test_Assert((Player_InNoFallDamageZone(player)), "Second volume did not protect its landing area!");
	setorigin(player, '99999 32 24');
	Test_Assert((!Player_InNoFallDamageZone(player)), "Body overlap protected feet outside the volume!");
	setorigin(player, '100016 32 0');
	Test_Assert((!Player_InNoFallDamageZone(player)), "Origin containment incorrectly protected feet below the volume!");
	setorigin(player, '100016 32 29');
	Test_Assert((!Player_InNoFallDamageZone(player)), "Feet above the volume were protected!");
	setorigin(player, '100000 0 20');
	Test_Assert((Player_InNoFallDamageZone(player)), "Volume boundary was excluded!");
	first.entity_removed = true;
	Test_Assert((!Player_InNoFallDamageZone(player)), "Removed volume still protected a landing!");

	nofall_volumes = old_head;
	remove(player);
	remove(second);
	remove(first);
};

//
// Test_NoFallDamage_LandingAndSubsequentFalls()
// Ensures protected landings consume the fall without granting immunity
// to other players or later falls outside the volume.
// (https://github.com/nzp-team/nzportable/issues/852)
//
void() Test_NoFallDamage_LandingAndSubsequentFalls =
{
	entity old_self = self;
	entity old_head = nofall_volumes;
	nofall_volumes = world;
	entity volume = Test_NoFallVolume('100000 0 -4', '100064 64 4');
	entity player = spawn();
	entity outside_player = spawn();

	player.classname = outside_player.classname = "player";
	player.health = player.max_health = 500;
	outside_player.health = outside_player.max_health = 500;
	setsize(player, '-16 -16 -24', '16 16 32');
	setsize(outside_player, '-16 -16 -24', '16 16 32');
	setorigin(player, '100032 32 24');
	setorigin(outside_player, '100128 32 24');
	player.oldz = outside_player.oldz = 1024;

	self = player;
	Player_Land();
	Test_Assert((player.health == 500), "Protected landing inflicted damage!");
	Test_Assert((player.oldz == player.origin_z), "Protected landing did not consume the fall!");
	Player_Land();
	Test_Assert((player.health == 500), "Standing in a volume inflicted delayed fall damage!");

	self = outside_player;
	Player_Land();
	Test_Assert((outside_player.health == 402), "Another player's protected landing suppressed outside damage!");
	Test_Assert((outside_player.oldz == outside_player.origin_z), "Unprotected landing did not consume the fall!");

	// Crossing a volume may not change the recorded height of an ongoing fall.
	self = player;
	player.oldz = 1024;
	Test_Assert((Player_InNoFallDamageZone(player)), "Crossing fixture missed the volume!");
	Test_Assert((player.oldz == 1024), "Volume query reset an ongoing fall!");
	setorigin(player, outside_player.origin);
	Player_Land();
	Test_Assert((player.health == 402), "Protection carried outside the landing volume!");

	player.health = 500;
	player.oldz = player.origin_z + 100;
	Player_Land();
	Test_Assert((player.health == 500), "Short fall gained damage!");
	player.oldz = 1024;
	player.perks = P_FLOP;
	Player_Land();
	Test_Assert((player.health == 500), "PhD Flopper lost fall protection outside the volume!");

	self = old_self;
	nofall_volumes = old_head;
	remove(outside_player);
	remove(player);
	remove(volume);
};
