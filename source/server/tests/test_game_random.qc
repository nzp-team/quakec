/*
	server/tests/test_game_random.qc

	Unit tests for game_random entity

	Copyright (C) 2021-2026 NZ:P Team

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

float test_game_random_fire_count;

void() test_game_random_count_use =
{
	test_game_random_fire_count++;
	self.frags++;
};

//
// Test_game_random_FiresOneValidTargetPerUse()
// Ensures every random result maps to a valid suffixed target and that the
// temporary target value is cleared after use.
//
void() Test_game_random_FiresOneValidTargetPerUse =
{
	entity game_random_ent = spawn();
	entity trigger = spawn();
	entity old_self = self;
	entity targets[8];
	float i;

	for (i = 0; i < 8; i++) {
		targets[i] = spawn();
		targets[i].targetname = sprintf("test_game_random_%d", i + 1);
		targets[i].use = test_game_random_count_use;
	}

	self = game_random_ent;
	self.health = 8;
	self.name = "test_game_random";
	self.targetname = "test_game_random_dispatcher";
	game_random();
	test_game_random_fire_count = 0;

	self = trigger;
	self.target = "test_game_random_dispatcher";
	for (i = 0; i < 512; i++)
		SUB_UseTargets();

	Test_Assert(test_game_random_fire_count == 512, "game_random did not fire exactly one valid target per use!");
	for (i = 0; i < 8; i++) {
		Test_Assert(targets[i].frags > 0, sprintf("game_random never fired target %d!", i + 1));
	}
	Test_Assert(game_random_ent.target == "", "game_random did not clear its temporary target!");

	self = old_self;
	for (i = 0; i < 8; i++)
		remove(targets[i]);
	remove(trigger);
	remove(game_random_ent);
};
