/*
	server/tests/test_perksacola.qc

	Perk-A-Cola unit tests.

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
void(entity object) Test_SimulateUse;

// MARK: Quick Revive

//
// Test_Perks_QuickRevive_ValidatePrice()
// Spawns a Quick Revive machine and validates its
// default fields.
//
void() Test_Perks_QuickRevive_ValidateFields =
{
    entity machine = spawn();
    entity old_self = self;
    self = machine;

    perk_revive();

    Test_Assert((self.model == PERK_QUICKREVIVE_DEFAULT_MODEL), "Perk has incorrect model!");
    Test_Assert((self.cost == 500), "Perk has incorrect Solo cost!");
    Test_Assert((self.cost2 == 1500), "Perk has incorrect Co-Op cost!");

    self = old_self;
    remove(machine);
};

//
// Test_Perks_QuickRevive_NoCostChangeOnRestart()
// Validates that on a Soft_Restart the price of Quick
// Revive does not change.
// (https://github.com/nzp-team/nzportable/issues/1116)
//
void() Test_Perks_QuickRevive_NoCostChangeOnRestart =
{
    entity perk_revive = find(world, classname, "perk_revive");

    // We need to simulate buying the perk to see the cost reduction,
    // so give us points.
    self.points = 10000;
    float start_score = self.points;

    // Simulate purchase
    Test_SimulateUse(perk_revive);

    float score_diff_before = start_score - self.points;

    Test_Assert((score_diff_before != 0), "Could not buy Quick Revive before restart!");

    Soft_Restart();

    // Do everything again and then assert
    // the diffs are the same.
    self.points = 10000;
    start_score = self.points;

    Test_SimulateUse(perk_revive);

    float score_diff_after = start_score - self.points;

    Test_Assert((score_diff_before != 0), "Could not buy Quick Revive after restart!");
    Test_Assert((score_diff_before == score_diff_after), sprintf("Quick Revive price changed after Soft_Restart, expected [%d] but got [%d]!", score_diff_before, score_diff_after));

    // Restart at end of test to not cause conflicts with tests ran afterwards.
    Soft_Restart();
};

// MARK: Jugger-Nog

//
// Test_Perks_JuggerNog_ValidatePrice()
// Spawns a Jugger-Nog machine and validates its
// default fields.
//
void() Test_Perks_JuggerNog_ValidateFields =
{
    entity machine = spawn();
    entity old_self = self;
    self = machine;

    perk_juggernog();

    Test_Assert((self.model == PERK_JUGGERNOG_DEFAULT_MODEL), "Perk has incorrect model!");
    Test_Assert((self.cost == 2500), "Perk has incorrect Solo cost!");
    Test_Assert((self.cost2 == 2500), "Perk has incorrect Co-Op cost!");

    self = old_self;
    remove(machine);
};

// MARK: Speed Cola

//
// Test_Perks_SpeedCola_ValidatePrice()
// Spawns a Speed Cola machine and validates its
// default fields.
//
void() Test_Perks_SpeedCola_ValidateFields =
{
    entity machine = spawn();
    entity old_self = self;
    self = machine;

    perk_speed();

    Test_Assert((self.model == PERK_SPEEDCOLA_DEFAULT_MODEL), "Perk has incorrect model!");
    Test_Assert((self.cost == 3000), "Perk has incorrect Solo cost!");
    Test_Assert((self.cost2 == 3000), "Perk has incorrect Co-Op cost!");

    self = old_self;
    remove(machine);
};

// MARK: Double Tap

//
// Test_Perks_DoubleTap_ValidateFields()
// Spawns a Double Tap machine and validates its
// default fields.
//
void() Test_Perks_DoubleTap_ValidateFields =
{
    entity machine = spawn();
    entity old_self = self;
    self = machine;

    perk_double();

    Test_Assert((self.model == PERK_DOUBLETAP_DEFAULT_MODEL), "Perk has incorrect model!");
    Test_Assert((self.cost == 2000), "Perk has incorrect Solo cost!");
    Test_Assert((self.cost2 == 2000), "Perk has incorrect Co-Op cost!");

    self = old_self;
    remove(machine);
};

// MARK: Stamin-Up

//
// Test_Perks_StaminUp_ValidateFields()
// Spawns a Stamin-Up machine and validates its
// default fields.
//
void() Test_Perks_StaminUp_ValidateFields =
{
    entity machine = spawn();
    entity old_self = self;
    self = machine;

    perk_staminup();

    Test_Assert((self.model == PERK_STAMINUP_DEFAULT_MODEL), "Perk has incorrect model!");
    Test_Assert((self.cost == 2000), "Perk has incorrect Solo cost!");
    Test_Assert((self.cost2 == 2000), "Perk has incorrect Co-Op cost!");

    self = old_self;
    remove(machine);
};

// MARK: PhD Flopper

//
// Test_Perks_PhDFlopper_ValidateFields()
// Spawns a PhD Flopper machine and validates its
// default fields.
//
void() Test_Perks_PhDFlopper_ValidateFields =
{
    entity machine = spawn();
    entity old_self = self;
    self = machine;

    perk_flopper();

    Test_Assert((self.model == PERK_PHDFLOPPER_DEFAULT_MODEL), "Perk has incorrect model!");
    Test_Assert((self.cost == 2000), "Perk has incorrect Solo cost!");
    Test_Assert((self.cost2 == 2000), "Perk has incorrect Co-Op cost!");

    self = old_self;
    remove(machine);
};

// MARK: Deadshot Daiquiri

//
// Test_Perks_DeadshotDaiquiri_ValidateFields()
// Spawns a Deadshot Daiquiri machine and validates its
// default fields.
//
void() Test_Perks_DeadshotDaiquiri_ValidateFields =
{
    entity machine = spawn();
    entity old_self = self;
    self = machine;

    perk_deadshot();

    Test_Assert((self.model == PERK_DEADSHOT_DEFAULT_MODEL), "Perk has incorrect model!");
    Test_Assert((self.cost == 1500), "Perk has incorrect Solo cost!");
    Test_Assert((self.cost2 == 1500), "Perk has incorrect Co-Op cost!");

    self = old_self;
    remove(machine);
};

// MARK: Mule Kick

//
// Test_Perks_MuleKick_ValidateFields()
// Spawns a Deadshot Daiquiri machine and validates its
// default fields.
//
void() Test_Perks_MuleKick_ValidateFields =
{
    entity machine = spawn();
    entity old_self = self;
    self = machine;

    perk_mule();

    Test_Assert((self.model == PERK_MULEKICK_DEFAULT_MODEL), "Perk has incorrect model!");
    Test_Assert((self.cost == 4000), "Perk has incorrect Solo cost!");
    Test_Assert((self.cost2 == 4000), "Perk has incorrect Co-Op cost!");

    self = old_self;
    remove(machine);
};

// MARK: Random Perk

//
// Test_Perks_Random_LegacyFields()
// Attempts to spawn a random Perk-A-Cola
// with the perk_random fields using
// legacy data.
// (https://github.com/nzp-team/nzportable/issues/664)
//
void() Test_Perks_Random_LegacyFields =
{
    entity random = spawn();
    entity old_self = self;
    self = random;
    self.spawnflags = 240;
    perk_random();
    self = old_self;

    remove(random);
};

//
// Test_Perks_Random_ResetDoesNotTeleport()
// Asserts that if GameRestart_ResetPerkaColas() is called,
// machines set by perk_random are not teleported to
// their original positions.
// (https://github.com/nzp-team/nzportable/issues/1186)
//
void() Test_Perks_Random_ResetDoesNotTeleport =
{
    entity deadshot, random;
    entity old_self = self;

    // Spawn Deadshot Daiquiri at world origin
    deadshot = spawn();
    self = deadshot;
    perk_deadshot();
    setorigin(self, '0 0 0');

    // Spawn a perk_random at client's origin
    random = spawn();
    self = random;
    self.spawnflags = SPAWNFLAG_PERKRANDOM_DEADSHOT; // Put Deadshot Daiquiri here!
    perk_random();
    setorigin(random, old_self.origin);

    // Activate perk_random
    Perk_RandomDecide();

    // Call GameRestart_ResetPerkaColas, Deadshot Daiquiri should not
    // be reset to world origin..
    GameRestart_ResetPerkaColas();

    Test_Assert((deadshot.origin != '0 0 0'), "Deadshot Daiquiri was moved to world origin!");

    self = old_self;

    remove(deadshot);
    remove(random);
};

// MARK: Misc.

//
// Test_Perks_Drink_WorkOnReset()
// Verifies that drinking a Perk and then
// triggering a Soft_Restart does not
// prevent purchase of additional Perks.
// (https://github.com/nzp-team/nzportable/issues/1126)
// 
void() Test_Perks_Drink_WorkOnReset =
{
    self.isBuying = true;
    Soft_Restart();
    Test_Assert((self.isBuying == false), "isBuying state not reset!");
};