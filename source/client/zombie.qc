/*
	client/zombie.qc

	Client-side functions for AI (Zombies).

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

//
// List of Zombie limb meshes for custom skinning
//
string zombie_skins[] =
{
	"models/ai/zb%.mdl",
	"models/ai/zbc%.mdl",
	"models/ai/zcfull.mdl",
	"models/ai/zhc^.mdl",
	"models/ai/zalc(.mdl",
	"models/ai/zarc(.mdl",
	"models/ai/zfull.mdl",
	"models/ai/zh^.mdl",
	"models/ai/zal(.mdl", 
	"models/ai/zar(.mdl"
};

//
// List of AI Models to snap to for Aim Snapping
// and the offset distance from ent origin (if necessary).
//
var struct
{
    string model_path;
    vector snap_offset;
	vector deadshot_snap_offset;
} zombie_snap_struct[] =
{
    {"models/ai/zfull.mdl", [0, 0, 18], [0, 0, 35]},
	{"models/ai/zb%.mdl", [0, 0, 18], [0, 0, 35]},
	{"models/ai/zcfull.mdl", [0, 0, 0], [0, 0, 0]},
	{"models/ai/zbc%.mdl", [0, 0, 0], [0, 0, 0]},
	{"models/ai/dog.mdl", [0, 0, 0], [0, 0, 0]},
};

float(float isnew) SetZombieSkinning =
{
	string model_path = modelnameforindex(self.modelindex);
	self.drawmask = MASK_ENGINE;
	setcustomskin(self, __NULL__, sprintf("replace \"\" \"models/ai/zfull.mdl_%d.pcx\"\n", self.skin));

	if (isnew) {
		//print(sprintf("adding a new zombie ent: [%s] [%f]\n", model_path, time));
		addentity(self);
	}

	return PREDRAW_NEXT;
};