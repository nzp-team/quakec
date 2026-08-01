/*
	server/tests/test_player.qc

	Unit tests for player state.

	Copyright (C) 2021-2026 NZ:P Team

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.
*/
float(float condition, string message) Test_Assert;

//
// Test_Player_StanceInterruption()
// Simulates an interrupted chance of stance, then
// asserts our target camera height is not impacted by
// the interruption.
// (https://github.com/nzp-team/nzportable/issues/1410)
//
void(float compatibility_mode, float interrupted_height, float expected_height) Test_Player_StanceInterruption =
{
	float old_compatibility_mode = map_compatibility_mode;
	float old_stance = self.stance;
	float old_view_height = self.view_ofs_z;
	float old_target_height = self.new_ofs_z;
	vector old_mins = self.mins;
	vector old_maxs = self.maxs;

	map_compatibility_mode = compatibility_mode;
	self.stance = PLAYER_STANCE_STAND;
	self.view_ofs_z = expected_height;
	self.new_ofs_z = expected_height;

	// Start from a completed prone transition so the setup uses the production
	// stance heights rather than duplicating them in this test.
	Player_SetStance(self, PLAYER_STANCE_PRONE, false);
	self.view_ofs_z = self.new_ofs_z;

	// Begin rising from prone, then simulate sprint interrupting the transition
	// after the camera has moved only part of the way toward crouch height.
	Player_SetStance(self, PLAYER_STANCE_CROUCH, false);
	self.view_ofs_z = interrupted_height;
	Player_SetStance(self, PLAYER_STANCE_STAND, false);

	Test_Assert((self.new_ofs_z == expected_height), sprintf("Interrupted stance transition targeted height [%d], expected [%d]!", self.new_ofs_z, expected_height));

	map_compatibility_mode = old_compatibility_mode;
	self.stance = old_stance;
	self.view_ofs_z = old_view_height;
	self.new_ofs_z = old_target_height;
	setsize(self, old_mins, old_maxs);
};

void() Test_Player_StanceInterruption_HalfLife =
{
	Test_Player_StanceInterruption(0, 0, VIEW_OFS_HL[2]);
};

void() Test_Player_StanceInterruption_Beta =
{
	Test_Player_StanceInterruption(MAP_COMPAT_BETA, 0, VIEW_OFS_QK[2]);
};
