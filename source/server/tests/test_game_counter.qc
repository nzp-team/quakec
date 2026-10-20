/*
	server/tests/test_game_counter.qc

	Unit tests for game_counter and game_counter_set entities

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

//
// Test_game_counter_set_SetsMatchingCounters()
// Sets all matching counters without incrementing them or changing other entities.
//
void() Test_game_counter_set_SetsMatchingCounters =
{
    entity old_self = self;
    entity counters[2];
    float i;

    for (i = 0; i < 2; i++) {
        counters[i] = spawn();
        self = counters[i];
        self.classname = "game_counter";
        self.targetname = "test_counter_set_target";
        self.frags = i + 1;
        self.health = 10;
        game_counter();
    }

    entity unrelated = spawn();
    unrelated.targetname = "test_counter_set_target";
    unrelated.frags = 9;

    entity setter = spawn();
    self = setter;
    self.targetname = "test_counter_set";
    self.target = "test_counter_set_target";
    game_counter_set();

    entity trigger = spawn();
    self = trigger;
    self.target = "test_counter_set";
    setter.frags = 5;
    SUB_UseTargets();
    for (i = 0; i < 2; i++)
        Test_Assert(counters[i].frags == 5, "game_counter_set did not set every matching counter!");

    setter.frags = 0;
    SUB_UseTargets();
    for (i = 0; i < 2; i++)
        Test_Assert(counters[i].frags == 0, "game_counter_set could not set a counter to zero!");

    setter.frags = -2;
    SUB_UseTargets();
    for (i = 0; i < 2; i++)
        Test_Assert(counters[i].frags == -2, "game_counter_set could not set a negative value!");
    Test_Assert(unrelated.frags == 9, "game_counter_set changed a non-counter entity!");

    self = old_self;
    for (i = 0; i < 2; i++)
        remove(counters[i]);
    remove(unrelated);
    remove(setter);
    remove(trigger);
};

//
// Test_game_counter_set_FiresAndResetsAtLimit()
// Setting the limit fires the counter's targets and restores its initial value.
//
void() Test_game_counter_set_FiresAndResetsAtLimit =
{
    entity old_self = self;
    entity output = spawn();
    self = output;
    self.targetname = "test_counter_set_output";
    self.health = 100;
    game_counter();

    entity counter = spawn();
    self = counter;
    self.classname = "game_counter";
    self.targetname = "test_counter_set_target";
    self.target = "test_counter_set_output";
    self.frags = 2;
    self.health = 10;
    self.spawnflags = SPAWNFLAG_COUNTER_RESETONFIRE;
    game_counter();

    entity setter = spawn();
    self = setter;
    self.target = "test_counter_set_target";
    self.frags = 9;
    game_counter_set();
    self.use();
    Test_Assert(output.frags == 0, "game_counter_set fired a counter below its limit!");

    self.frags = 10;
    self.use();
    Test_Assert(output.frags == 1, "game_counter_set did not fire the counter's targets at its limit!");
    Test_Assert(counter.frags == 2, "game_counter_set did not reset the counter to its initial value!");

    self = old_self;
    remove(output);
    remove(counter);
    remove(setter);
};

//
// Test_game_counter_set_RemoveOnFire()
// Both the setter and the counter honor their remove-on-fire flags.
//
void() Test_game_counter_set_RemoveOnFire =
{
    entity old_self = self;
    entity counter = spawn();
    self = counter;
    self.classname = "game_counter";
    self.targetname = "test_counter_set_target";
    self.health = 10;
    self.spawnflags = SPAWNFLAG_COUNTER_REMOVEONFIRE;
    game_counter();

    entity setter = spawn();
    self = setter;
    self.targetname = "test_counter_set";
    self.target = "test_counter_set_target";
    self.frags = 10;
    self.spawnflags = SPAWNFLAG_COUNTERSET_REMOVEONFIRE;
    game_counter_set();
    self.use();

    Test_Assert(find(world, targetname, "test_counter_set_target") == world, "Counter was not removed at its limit!");
    Test_Assert(find(world, targetname, "test_counter_set") == world, "game_counter_set was not removed after use!");

    self = old_self;
};
