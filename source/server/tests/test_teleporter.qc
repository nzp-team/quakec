/*
	server/tests/test_teleporter.qc

	Unit tests for teleporter behavior.

	Copyright (C) 2026 NZ:P Team

	This program is free software; you can redistribute it and/or
	modify it under the terms of the GNU General Public License
	as published by the Free Software Foundation; either version 2
	of the License, or (at your option) any later version.
*/
float(float condition, string message) Test_Assert;

//
// Test_Teleporter_PlayerCanMoveAfterTeleport()
// Ensures teleporting releases player movement after activation.
// (https://github.com/nzp-team/nzportable/issues/1391)
//
void() Test_Teleporter_PlayerCanMoveAfterTeleport =
{
	entity old_self = self;
	entity teleporter = spawn();
	entity destination = spawn();
	entity player = spawn();

	teleporter.target2 = "test_teleporter_return";
	destination.targetname = teleporter.target2;
	destination.classname = "func_teleporter_destination";
	player.classname = "player";
	player.tele_target = destination;
	player.movetype = MOVETYPE_NONE;

	self = teleporter;
	teleport_entity(player);

	Test_Assert((player.movetype == MOVETYPE_WALK), "Player remained locked after teleporting!");

	self = old_self;
	remove(player);
	remove(destination);
	remove(teleporter);
};

//
// Test_Teleporter_PlayerOffsetsDoNotOverlap()
// Ensures a full group is placed in separate player-width slots.
// (https://github.com/nzp-team/nzportable/issues/1391)
//
void() Test_Teleporter_PlayerOffsetsDoNotOverlap =
{
	vector first = Teleporter_PlayerOffset(0);
	vector second = Teleporter_PlayerOffset(1);
	vector third = Teleporter_PlayerOffset(2);
	vector fourth = Teleporter_PlayerOffset(3);

	// Players sharing an axis must be separated by more than their 32-unit hull.
	Test_Assert((fabs(first_x - second_x) > 32), "Top teleporter slots overlap!");
	Test_Assert((fabs(third_x - fourth_x) > 32), "Bottom teleporter slots overlap!");
	Test_Assert((fabs(first_y - third_y) > 32), "Right teleporter slots overlap!");
	Test_Assert((fabs(second_y - fourth_y) > 32), "Left teleporter slots overlap!");
};
