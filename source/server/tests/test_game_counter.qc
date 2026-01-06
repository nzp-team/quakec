/*
	server/tests/test_game_counter.qc

	Unit tests for game_counter entity

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
void(string message) Test_Skip;

//
// Test_game_counter_IncrementsOnUse()
// Spawns a game_counter entity and tests that during
// normal usage it's frags are incremented.
//
void() Test_game_counter_IncrementsOnUse =
{
    string test_targetname = "test_game_counter";

    entity gamecounter = spawn();
    entity old_self = self;
    self = gamecounter;

    self.frags = 0;
    self.health = 10;
    self.targetname = test_targetname;
    game_counter();

    entity triggertest = spawn();
    self = triggertest;
    self.target = test_targetname;
    SUB_UseTargets();

    Test_Assert((gamecounter.frags == 1), "Frags was not incremented after game_counter was used!");

    self = old_self;
    remove(gamecounter);
    remove(triggertest);
};

//
// Test_game_counter_IncrementsOnTriggerRelayStateOn()
// Spawns a game_counter entity and tests that during
// usage with a triggerstate of On it's frags are incremented.
//
void() Test_game_counter_IncrementsOnTriggerRelayStateOn =
{
    string test_targetname = "test_game_counter";

    entity gamecounter = spawn();
    entity old_self = self;
    self = gamecounter;

    self.frags = 0;
    self.health = 10;
    self.targetname = test_targetname;
    game_counter();

    entity triggertest = spawn();
    self = triggertest;
    self.triggerstate = TRIGGERSTATE_ON;
    self.target = test_targetname;
    SUB_UseTargets();

    Test_Assert((gamecounter.frags == 1), "Frags was not incremented after game_counter was used!");

    self = old_self;
    remove(gamecounter);
    remove(triggertest);
};

//
// Test_game_counter_IncrementsOnTriggerRelayStateOff()
// Spawns a game_counter entity and tests that during
// usage with a triggerstate of Off it's frags are decremented.
//
void() Test_game_counter_IncrementsOnTriggerRelayStateOff =
{
    string test_targetname = "test_game_counter";

    entity gamecounter = spawn();
    entity old_self = self;
    self = gamecounter;

    self.frags = 1;
    self.health = 10;
    self.targetname = test_targetname;
    game_counter();

    entity triggertest = spawn();
    self = triggertest;
    self.triggerstate = TRIGGERSTATE_OFF;
    self.target = test_targetname;
    SUB_UseTargets();

    Test_Assert((gamecounter.frags == 0), "Frags was not decremented after game_counter was used!");

    self = old_self;
    remove(gamecounter);
    remove(triggertest);
};