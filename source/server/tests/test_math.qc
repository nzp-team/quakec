/*
	server/tests/test_math.qc

	Unit test list for math functions. Mostly serves for testing the test infrastructure.

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
// Test_Math_ClampReturnsMin()
// Asserts when sending a value less than min to clamp,
// min is returned.
//
void() Test_Math_ClampReturnsMin =
{
	float clamp_value = clamp(0, 1, 100);
	Test_Assert((clamp_value == 1), "Clamp returned incorrect value!");
};

//
// Test_Math_ClampReturnsMax()
// Asserts when sending a value greater than max to clamp,
// max is returned.
//
void() Test_Math_ClampReturnsMax =
{
	float clamp_value = clamp(900, 1, 100);
	Test_Assert((clamp_value == 100), "Clamp returned incorrect value!");
};