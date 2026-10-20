/*
	server/tests/test_spawn_limits.qc

	Regression tests for map entity spawn restrictions

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

void() Test_SpawnLimits_Legacy =
{
    entity ent = spawn();
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_CLASSIC, 1), "Default selectors should allow Classic in January!");
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_FESTIVE, 12), "Default selectors should allow all modes and months!");
    ent.gamemode_limiter = GAMEMODE_HARDCORE;
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_HARDCORE, 1), "Legacy mode 3 must still mean Hardcore!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_CLASSIC, 1), "Legacy mode 3 must not be interpreted as mask 3!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_GRIEF, 1), "Legacy mode 3 must not select mode 1!");
    ent.gamemode_limiter = 0;
    for (float month = 1; month <= 12; month++) {
        ent.month_limiter = month;
        Test_Assert(Spawn_Allowed(ent, GAMEMODE_CLASSIC, month), "Legacy month should allow its exact month!");
        Test_Assert(!Spawn_Allowed(ent, GAMEMODE_CLASSIC, month == 12 ? 1 : month + 1), "Legacy month should reject other months!");
    }
    ent.gamemode_limiter = GAMEMODE_HARDCORE;
    ent.month_limiter = 10;
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_HARDCORE, 10), "Both matching legacy selectors should spawn!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_CLASSIC, 10), "Legacy mode must match even if month matches!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_HARDCORE, 12), "Legacy month must match even if mode matches!");
    remove(ent);
};

void() Test_SpawnLimits_Masks =
{
    entity ent = spawn();
    ent.gamemode_mask = 9; // Classic or Hardcore.
    ent.month_mask = 2560; // October or December.
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_CLASSIC, 10), "Mask should allow Classic in October!");
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_HARDCORE, 12), "Mask should allow Hardcore in December!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_GUNGAME, 10), "Matching month must not bypass mode mask!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_CLASSIC, 11), "Matching mode must not bypass month mask!");
    ent.gamemode_limiter = GAMEMODE_GUNGAME;
    ent.month_limiter = 1;
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_CLASSIC, 10), "Nonzero masks must override legacy selectors!");
    ent.gamemode_mask = 0;
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_GUNGAME, 10), "Zero mode mask must restore legacy mode only!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_CLASSIC, 10), "Zero mode mask must honor legacy mode restriction!");
    ent.month_mask = 0;
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_GUNGAME, 1), "Zero month mask must restore legacy month!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_GUNGAME, 10), "Zero month mask must honor legacy month restriction!");
    ent.gamemode_mask = 1;
    ent.month_mask = 1;
    Test_Assert(Spawn_Allowed(ent, GAMEMODE_CLASSIC, 1), "Bit zero should mean Classic and January!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_HARDCORE, 1), "Classic-only mask must reject other modes!");
    Test_Assert(!Spawn_Allowed(ent, -1, 1), "Negative mode must not match masks!");
    Test_Assert(!Spawn_Allowed(ent, 24, 1), "Out of range mode must not match masks!");
    Test_Assert(!Spawn_Allowed(ent, 0.5, 1), "Fractional mode must not match masks!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_CLASSIC, 0), "Month zero must not match masks!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_CLASSIC, 13), "Month thirteen must not match masks!");
    Test_Assert(!Spawn_Allowed(ent, GAMEMODE_CLASSIC, 1.5), "Fractional month must not match masks!");
    remove(ent);
};

float test_spawn_limits_calls;
void() SpawnLimits_TestCallback =
{
    test_spawn_limits_calls++;
};

void() Test_SpawnLimits_CheckSpawn =
{
    entity old_self = self;
    float old_mode = cvar("sv_gamemode");
    float old_month = cvar("sv_spoofmonth");
    cvar_set("sv_gamemode", "0");
    cvar_set("sv_spoofmonth", "10");
    test_spawn_limits_calls = 0;

    // A real brush spawn must be rejected before it tries to set its model.
    self = spawn();
    self.classname = "func_illusionary";
    self.targetname = "test_spawn_limits_rejected";
    self.month_limiter = 12;
    CheckSpawn(func_illusionary);
    Test_Assert(find(world, targetname, "test_spawn_limits_rejected") == world, "Rejected brush must be removed!");

    self = spawn();
    self.classname = "misc_model";
    self.targetname = "test_spawn_limits_rejected";
    self.gamemode_limiter = GAMEMODE_HARDCORE;
    CheckSpawn(SpawnLimits_TestCallback);
    Test_Assert(test_spawn_limits_calls == 0, "Rejected entity must not execute spawn function!");
    Test_Assert(find(world, targetname, "test_spawn_limits_rejected") == world, "Rejected model must be removed!");

    self = spawn();
    self.classname = "info_notnull";
    self.gamemode_mask = 9;
    self.month_mask = 2560;
    CheckSpawn(SpawnLimits_TestCallback);
    Test_Assert(test_spawn_limits_calls == 1, "Matching masks must execute spawn function once!");
    remove(self);

    // An unconfigured point entity should keep the existing spawn path.
    self = spawn();
    self.classname = "info_notnull";
    CheckSpawn(SpawnLimits_TestCallback);
    Test_Assert(test_spawn_limits_calls == 2, "Unrestricted point entity must spawn!");
    remove(self);

    self = world;
    CheckSpawn(SpawnLimits_TestCallback);
    Test_Assert(test_spawn_limits_calls == 3, "Worldspawn must bypass entity restrictions!");
    Test_Assert(Spawn_Allowed(world, -1, 0), "Worldspawn must bypass selector validation!");

    cvar_set("sv_gamemode", ftos(old_mode));
    cvar_set("sv_spoofmonth", ftos(old_month));
    self = old_self;
};
