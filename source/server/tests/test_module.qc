/*
	server/tests/test_main.qc

	Test running and validation infrastructure for QuakeC unit tests.

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
#ifdef FTE
#ifdef QUAKEC_TEST

float total_tests_ran;
float total_tests_passed;
float total_tests_failed;
float total_tests_skipped;
float tests_starttime;
float tests_endtime;

float test_skipped_notify;
string skipped_message_buffer;

float test_failed_an_assert;
string failed_message_buffer;

float(float condition, string message) Test_Assert =
{
	if (condition == false) {
		failed_message_buffer = sprintf("%s[ERROR]: %s\n", failed_message_buffer, message);
		test_failed_an_assert = true;
		return false;
	}

	return true;
};

void(string message) Test_Skip =
{
	test_skipped_notify = true;
	skipped_message_buffer = sprintf("[SKIP]: %s\n", message);
}

void(entity object) Test_SimulateUse =
{
	float old_power_on = isPowerOn;
	isPowerOn = true;

	entity old_self = self;

	self.button7 = true;
	self.fire_delay = self.reload_delay = self.dive_delay = self.reload_delay = self.switch_delay = 0;

	self = object;
	other = old_self;
	object.touch();
	self = old_self;
	other = world;

	self.button7 = false;
	self.semi_actions &= ~SEMIACTION_USE;

	isPowerOn = old_power_on;
}

void(void() test_func, string test_name) Test_Run =
{
	print(sprintf("[INFO]: Running test [%s]..", test_name));
	test_func();

	if (test_skipped_notify == true) {
		print("SKIP!\n");
		total_tests_skipped++;
		print(sprintf("%s", skipped_message_buffer));
		skipped_message_buffer = "";
		test_skipped_notify = false;
		total_tests_ran--;
	} else if (test_failed_an_assert == false) {
		print("PASS!\n");
		total_tests_passed++;
	} else {
		print("FAIL!\n");
		total_tests_failed++;
		print(sprintf("%s", failed_message_buffer));
		failed_message_buffer = "";
		test_failed_an_assert = false;
	}

	total_tests_ran++;

	print("\n");
};

void() Test_PrintSummary =
{
	print("====================== TEST SUMMARY ======================\n");
	print(sprintf("* Passed: %d\n* Failed: %d\n* Skipped: %d\n* Total Ran: %d\n", total_tests_passed, total_tests_failed, total_tests_skipped, total_tests_ran));
	print(sprintf("* %d%% Passing Grade\n", (total_tests_passed/total_tests_ran) * 100));
	print(sprintf("* %fs Total Runtime\n", tests_endtime));
	print("==================== END TEST SUMMARY ====================\n");
	localcmd("quit\n");
};

//
// Test Table
// Add unit tests to this table for them to be
// executed during Pull Request testing.
//
var struct {
	void()					test_func;
	string 					test_name;
} qc_unit_tests[] = {
	{ Test_Math_ClampReturnsMin, "Test_Math_ClampReturnsMin" },
	{ Test_Math_ClampReturnsMax, "Test_Math_ClampReturnsMax" },
	{ Test_Perks_QuickRevive_ValidateFields, "Test_Perks_QuickRevive_ValidateFields" },
	{ Test_Perks_QuickRevive_NoCostChangeOnRestart, "Test_Perks_QuickRevive_NoCostChangeOnRestart" },
	{ Test_Perks_JuggerNog_ValidateFields, "Test_Perks_JuggerNog_ValidateFields" },
	{ Test_Perks_SpeedCola_ValidateFields, "Test_Perks_SpeedCola_ValidateFields" },
	{ Test_Perks_DoubleTap_ValidateFields, "Test_Perks_DoubleTap_ValidateFields" },
	{ Test_Perks_StaminUp_ValidateFields, "Test_Perks_StaminUp_ValidateFields" },
	{ Test_Perks_PhDFlopper_ValidateFields, "Test_Perks_PhDFlopper_ValidateFields" },
	{ Test_Perks_DeadshotDaiquiri_ValidateFields, "Test_Perks_DeadshotDaiquiri_ValidateFields" },
	{ Test_Perks_Random_LegacyFields, "Test_Perks_Random_LegacyFields" },
	{ Test_Perks_Random_ResetDoesNotTeleport, "Test_Perks_Random_ResetDoesNotTeleport" },
	{ Test_Perks_MuleKick_ValidateFields, "Test_Perks_MuleKick_ValidateFields" },
	{ Test_Perks_Drink_WorkOnReset, "Test_Perks_Drink_WorkOnReset" },
	{ Test_Weapons_Gewehr_MagazineSize, "Test_Weapons_Gewehr_MagazineSize" },
	{ Test_Weapons_BowieKnife_RemovedAfterRespawn, "Test_Weapons_BowieKnife_RemovedAfterRespawn" },
	{ Test_Weapons_HoldTwoWeapons, "Test_Weapons_HoldTwoWeapons" },
	{ Test_Weapons_HoldThreeWeapons, "Test_Weapons_HoldThreeWeapons" },
	{ Test_Weapons_UpgradedSound, "Test_Weapons_UpgradedSound" },
	{ Test_Weapons_ShotgunPenetration, "Test_Weapons_ShotgunPenetration" },
	{ Test_Weapons_WunderWaffe_UpgradedReserve, "Test_Weapons_WunderWaffe_UpgradedReserve" },
	{ Test_Weapons_WunderWaffe_FireAtBarrel, "Test_Weapons_WunderWaffe_FireAtBarrel" },
	{ Test_WallWeapons_Message, "Test_WallWeapons_Message" },
	{ Test_WallWeapons_ActivatesAllTargets, "Test_WallWeapons_ActivatesAllTargets" },
	{ Test_Weapons_DualWield_ReloadLowReserveRightLeft, "Test_Weapons_DualWield_ReloadLowReserveRightLeft" },
	{ Test_Weapons_DualWield_ReloadLowReserveLeftRight, "Test_Weapons_DualWield_ReloadLowReserveLeftRight" },
	{ Test_misc_model_ModelNotHiddenByDefault, "Test_misc_model_ModelNotHiddenByDefault" },
	{ Test_AddScore_NonClient, "Test_AddScore_NonClient" },
	{ Test_AddScore_DamageTypes, "Test_AddScore_DamageTypes" },
	{ Test_AddScore_MysteryBoxLeave, "Test_AddScore_MysteryBoxLeave" },
	{ Test_AI_HellhoundsDetected, "Test_AI_HellhoundsDetected" },
	{ Test_Power_HandleResetOnRestart, "Test_Power_HandleResetOnRestart" },
	{ Test_EndGame_CounterResetsOnRestart, "Test_EndGame_CounterResetsOnRestart" },
	{ Test_Rounds_NewClientsDontCauseReset, "Test_Rounds_NewClientsDontCauseReset" }
};

void() Test_RunAllTests =
{
	if (tests_starttime != 0)
		return;

	total_tests_ran = 0;
	total_tests_passed = 0;
	total_tests_failed = 0;

	tests_starttime = gettime();
	for(int i = 0; i < qc_unit_tests.length; i++) {
		Test_Run(qc_unit_tests[i].test_func, qc_unit_tests[i].test_name);
	}
	tests_endtime = gettime();
	Test_PrintSummary();
};

#endif // QUAKEC_TEST
#endif // FTE