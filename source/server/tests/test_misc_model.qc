/*
	server/tests/test_misc_model.qc

	Unit tests for misc_model entity

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
// Test_misc_model_ModelNotHiddenByDefault()
// Spawns a misc_model with properties and validates
// the model does not start hidden.
// (https://github.com/nzp-team/nzportable/issues/996)
//
void() Test_misc_model_ModelNotHiddenByDefault =
{
    entity miscmodel = spawn();
    entity old_self = self;
    self = miscmodel;

    self.last_frame = 154;
    self.first_frame = 1;
    self.frame = 0;
    self.spawnflags = 6;
    self.speed = 0.1;
    self.model = "models/ai/zfull.mdl";
    self.classname = "misc_model";

    misc_model();

    Test_Assert((self.model != ""), "Model property started hidden!");

    self = old_self;
    remove(miscmodel);
};