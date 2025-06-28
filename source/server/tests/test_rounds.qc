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