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

//
// Test_misc_model_ModelNotHiddenByDefault()
// Verifies custom bounding boxes on misc_model do not
// get reset.
// (https://github.com/nzp-team/nzportable/issues/1651)
//
void() Test_misc_model_CustomBounds =
{
    entity miscmodel = spawn();
    entity old_self = self;
    self = miscmodel;

    self.classname = "misc_model";
    self.model = "models/ai/zfull.mdl";
    self.spawnflags = MISC_MODEL_SOLID;
    self.mdlsz = '256 128 64';
    self.centeroffset = '8 -16 24';
    misc_model();

    Test_Assert(self.mins == '-120 -80 -8', "Custom mins were overwritten during spawn!");
    Test_Assert(self.maxs == '136 48 56', "Custom maxs were overwritten during spawn!");
    Test_Assert(self.size == '256 128 64', "Custom size was overwritten during spawn!");

    setorigin(self, '64 32 16');
    Test_Assert(self.absmin == '-57 -49 7', "Relinking did not use custom mins!");
    Test_Assert(self.absmax == '201 81 73', "Relinking did not use custom maxs!");

    misc_model_use();
    misc_model_use();
    Test_Assert(self.mins == '-120 -80 -8', "Toggling visibility overwrote custom mins!");
    Test_Assert(self.maxs == '136 48 56', "Toggling visibility overwrote custom maxs!");
    Test_Assert(self.solid == SOLID_BBOX, "Toggling visibility did not restore solidity!");

    self = old_self;
    remove(miscmodel);
};

void() Test_misc_model_CustomBoundsPreventStatic =
{
    entity miscmodel = spawn();
    entity old_self = self;
    self = miscmodel;

    self.classname = "test_misc_model_custom_bounds";
    self.model = "models/ai/zfull.mdl";
    self.mdlsz = '256 256 256';
    self.centeroffset = '1 1 1';
    misc_model();

    Test_Assert(find(world, classname, "test_misc_model_custom_bounds") == miscmodel,
        "Custom bounds were lost by converting the prop to a static entity!");
    Test_Assert(self.mins == '-127 -127 -127', "Stationary prop did not retain custom mins!");
    Test_Assert(self.maxs == '129 129 129', "Stationary prop did not retain custom maxs!");

    self = old_self;
    if (find(world, classname, "test_misc_model_custom_bounds") == miscmodel)
        remove(miscmodel);
};

void() Test_misc_model_CenterOffsetPreventStatic =
{
    entity miscmodel = spawn();
    entity old_self = self;
    self = miscmodel;

    self.classname = "test_misc_model_center_offset";
    self.model = "models/ai/zfull.mdl";
    self.centeroffset = '32 -16 8';
    misc_model();

    Test_Assert(find(world, classname, "test_misc_model_center_offset") == miscmodel,
        "Custom center offset was lost by converting the prop to a static entity!");
    Test_Assert(self.mins == '16 -32 -8', "Center offset did not apply to default mins!");
    Test_Assert(self.maxs == '48 0 24', "Center offset did not apply to default maxs!");

    self = old_self;
    if (find(world, classname, "test_misc_model_center_offset") == miscmodel)
        remove(miscmodel);
};

void() Test_misc_model_DefaultBoundsRemainStatic =
{
    entity miscmodel = spawn();
    entity old_self = self;
    self = miscmodel;

    self.classname = "test_misc_model_default_bounds";
    self.model = "models/ai/zfull.mdl";
    misc_model();

    Test_Assert(find(world, classname, "test_misc_model_default_bounds") == world,
        "Stationary prop without custom bounds was not converted to a static entity!");

    self = old_self;
    if (find(world, classname, "test_misc_model_default_bounds") == miscmodel)
        remove(miscmodel);
};
