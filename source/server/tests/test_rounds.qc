/*
	server/tests/test_rounds.qc

	Unit tests related to rounds.

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
// Test_Round_PlayerSpawnSetsRoundProperly()
// Validate that PlayerSpawn() only sets the round when needed (at the game start).
// This prevents the round resetting whenever a player joins the game.
// (https://github.com/nzp-team/nzportable/issues/1185)
//
void() Test_Round_PlayerSpawnSetsRoundProperly =
{
	float backup_round, backup_startround;

	// Backup our rounds / start round, and then set them.
	backup_round = rounds;
    backup_startround = cvar("sv_startround");
    rounds = 21;
    cvar_set("sv_startround", "0");

    // Make sure that our rounds value is still 21.
    PlayerSpawn();
    Test_Assert(rounds == 21, "Rounds value is being incorrectly reset!");

    // Make sure that a negative round value properly sets as well.
    rounds = -3;
    PlayerSpawn();
    Test_Assert(rounds == 0, "Rounds value is not being correctly reset!");

    // Restore original values.
    rounds = backup_round;
    cvar_set("sv_startround", ftos(backup_startround));
};