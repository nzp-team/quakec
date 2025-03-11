/*
	server/tests/test_ai.qc

	Unit tests for various AI behaviors

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
// Test_AI_HellhoundsDetected()
// Validates that if a hellhound spawner is in the
// world that we have detected we can have Hellhound
// rounds.
// (https://github.com/nzp-team/nzportable/issues/623)
//
void() Test_AI_HellhoundsDetected =
{
    entity hound = find(world, classname, "spawn_dog");

    if (hound != world) {
        Test_Assert((map_has_hellhounds == true), "Found Hellhound entities but map_has_hellhounds is false!");
        Test_Assert((dogRound >= 0), "Found Hellhound entities but dogRound is zero!");
    } else {
        Test_Assert((map_has_hellhounds == false), "No Hellhound entities found but map_has_hellhounds is true!");
        Test_Assert((dogRound == 0), "No Hellhound entities found but dogRound is not zero!");
    }
};