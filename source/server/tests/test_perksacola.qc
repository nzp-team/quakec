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