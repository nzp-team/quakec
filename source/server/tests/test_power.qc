/*
	server/tests/test_power.qc

	Unit tests for the Power Switch

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
// Test_Power_HandleResetOnRestart()
// Turns on the Power and validates the
// Power Switch handle's angles are reset
// on Soft_Restart.
// (https://github.com/nzp-team/nzportable/issues/1125)
//
void() Test_Power_HandleResetOnRestart =
{
    entity power_switch = find(world, classname, "power_switch");

    Test_Assert((power_switch.boxweapon.angles == power_switch.angles), "Power Switch handle angles are not correct at start of test!");
    
    // Simulated switch flip
    power_switch.boxweapon.angles_x += 180;

    Soft_Restart();

    Test_Assert((power_switch.boxweapon.angles == power_switch.angles), "Power Switch handle angles are not correct at end of test!");
};