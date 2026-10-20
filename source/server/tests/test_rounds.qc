/*
	server/tests/test_rounds.qc

	Unit tests for Round logic.

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
float(float condition, string message) Test_Assert;
void(string message) Test_Skip;

//
// Test_Rounds_NewClientsDontCauseReset()
// Asserts that a client spawning into the world does not alter
// round logic.
// (https://github.com/nzp-team/nzportable/issues/1185)
//
void() Test_Rounds_NewClientsDontCauseReset =
{
    float old_rounds = rounds;
    rounds = 100;

    PlayerSpawn();

    Test_Assert((rounds == 100), "PlayerSpawn function reset Round!");
    rounds = old_rounds;
};

void(float end_delay_rounds, float start_delay_rounds) Test_Rounds_DelayTiming =
{
    entity oldself = self;
    entity oldactivator = activator;
    float oldrounds = rounds;
    entity counter = spawn();
    counter.targetname = "test_round_delay_counter";
    counter.frags = 2;
    counter.health = 10;
    self = counter;
    game_counter();

    entity trigger = spawn();
    trigger.target = counter.targetname;
    trigger.target2 = counter.targetname;
    trigger.triggerstate = TRIGGERSTATE_OFF;
    trigger.round_delay = start_delay_rounds;
    trigger.round_delay_end = end_delay_rounds;
    float end_mode = end_delay_rounds != 0;
    float delay_rounds = end_mode ? end_delay_rounds : start_delay_rounds;
    rounds = 2;
    self = trigger;
    activator = oldself;
    SUB_UseTargets();

    Test_Assert(counter.frags == 2, "Round delay fired immediately instead of being queued!");
    string delay_class = end_mode ? "RoundEndDelayedUse" : "DelayedUse";
    entity pending = find(world, classname, delay_class);
    Test_Assert(pending != world, "Round delay was not queued!");
    if (pending != world) {
        Test_Assert(pending.enemy == oldself, "Round delay lost its activator!");
        rounds = 2 + delay_rounds - 2;
        RoundDelayEndTargets();
        if (!end_mode) {
            self = pending;
            RoundDelayThink();
        }
        Test_Assert(counter.frags == 2, "Round delay fired before its selected round!");

        rounds = 2 + delay_rounds - 1;
        RoundDelayEndTargets();
        if (end_mode) {
            Test_Assert(counter.frags == 0, "End delay did not fire both targets with the Off state!");
            Test_Assert(find(world, classname, delay_class) == world, "End delay was not removed!");
            RoundDelayEndTargets();
            Test_Assert(counter.frags == 0, "End delay fired more than once!");
        } else {
            self = pending;
            RoundDelayThink();
            Test_Assert(counter.frags == 2, "Default delay fired at the end of the previous round!");
            rounds += 1;
            RoundDelayThink();
            Test_Assert(counter.frags == 0, "Default delay did not fire at the start of its target round!");
        }
    }

    self = oldself;
    activator = oldactivator;
    rounds = oldrounds;
    remove(trigger);
    remove(counter);
};

void() Test_Rounds_DelayDefaultsToRoundStart =
{
    Test_Rounds_DelayTiming(0, 3);
};

void() Test_Rounds_DelayCanFireAtPreviousRoundEnd =
{
    Test_Rounds_DelayTiming(3, 0);
};

void() Test_Rounds_OneRoundDelayCanFireAtCurrentRoundEnd =
{
    Test_Rounds_DelayTiming(1, 0);
};

void() Test_Rounds_EndDelayUsesItsOwnCount =
{
    Test_Rounds_DelayTiming(3, 7);
};
