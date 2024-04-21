/*
	server/weapons/frames_core.qc

	advanced viewmodel frame iteration

	Copyright (C) 2021-2024 NZ:P Team

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

void(entity person) W_ShowCrosshair;

void() ContinueRun =
{
	float startframe;
	float endframe;
	string modelname;
	startframe = GetFrame(self.weapon,SPRINT_START);
	endframe = GetFrame(self.weapon,SPRINT_END);
	if(!startframe && !endframe)
	{
		startframe = GetFrame(self.weapon,SPRINT_IN_END);
		endframe = GetFrame(self.weapon,SPRINT_IN_END);
	}
	if (!self.downed) {
		modelname = GetWeaponModel(self.weapon, 0);
	} else
		modelname = "";
	Set_W_Frame (startframe, endframe, 0, 0, SPRINT, ContinueRun, modelname, false, S_BOTH);
}


void () W2_Frame_Update =
{
	local void temp(optional float t);

// note: call whenever weapon frames are called!

	if (self.anim_weapon2_time > time)
		return; //don't call every frame, if it is the animations will play too fast

#ifndef FTE

	if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER) {
		self.weapon2frame = self.weaponframe;
		return;
	}

#endif // FTE
	
	self.anim_weapon2_time = time + self.weapon2_animduration;

	if (self.weapon2frame != self.weapon2frame_end && !self.anim2_reversed)
	{   // continue an animation
        if (self.anim2_reversed) {
		    self.weapon2frame = self.weapon2frame - 1;
        } else {
		    self.weapon2frame = self.weapon2frame + 1;
        }

		if (self.callfuncat2)
		{
			if (self.weapon2frame == self.callfuncat2)
			{
				if (self.animend2)
				{
					temp = self.animend2;
					self.animend2 = SUB_Null2;
					if (temp)
						temp(S_LEFT);
				}
			}
		}
		PlayWeaponSound(self.weapon, self.weapon2_anim_type, FALSE, self.weapon2frame);
		return;
	}
	else
	{
		if (self.callfuncat2 != self.weapon2frame && self.reload_delay <= time)
			W_ShowCrosshair(self);
		self.weapon2frame = self.weapon2frame_end = self.weapon2frame = GetFrame(self.weapon,BASE_FRAME);
		self.new_anim2_stop = FALSE;
		self.weapon2_anim_type = 0;
		self.weapon2_animduration = 0;
		self.callfuncat2 = 0;
		temp = self.animend2;
		self.animend2 = SUB_Null;
		if (temp)
			temp(S_LEFT);
	}
};
void () W_Frame_Update =
{
	local void temp(optional float t);

	// note: call whenever weapon frames are called!
	if (self.anim_weapon_time > time)
		return; //don't call every frame, if it is the animations will play too fast

	//if (IsDualWeapon(self.weapon))
	//	W2_Frame_Update();
	
	self.anim_weapon_time = time + self.weapon_animduration;

	if (self.weaponframe != self.weaponframe_end && !self.anim_reversed)
	{   // continue an animation

        if (self.anim_reversed) {
		    self.weaponframe = self.weaponframe - 1;
        } else {
		    self.weaponframe = self.weaponframe + 1;
        }

		if (self.weaponmodel == "models/weapons/kar/v_kar.mdl" && (self.weapon == W_KAR_SCOPE ||  self.weapon == W_HEADCRACKER))
		{
			self.weapon2model = "models/weapons/kar/v_karscope.mdl";
			self.weapon2frame = self.weaponframe;
			//self.weapon2skin = self.weaponskin;
		}
		else if (self.weaponmodel == "progs/VModels/v_knife.mdl" || self.weaponmodel == "models/machines/v_perk.mdl") {
			self.weapon2model = "";
		}

		if (self.callfuncat)
		{
			if (self.weaponframe == self.callfuncat)
			{
				if (self.animend)
				{
					temp = self.animend;
					self.animend = SUB_Null;
					if (temp)
						temp(S_RIGHT);
				}
			}
		}
		PlayWeaponSound(self.weapon, self.weapon_anim_type, FALSE, self.weaponframe);

		// FIXME: We need a way to play sounds at specific frames for any viewmodel, not just weapons
		if (self.weaponmodel == "models/weapons/grenade/v_betty.mdl" && self.weaponframe == 9)
			sound (self, CHAN_WEAPON, "sounds/weapons/grenade/prime.wav", 1, ATTN_NORM);
		return;
	}
	else
	{
		if (self.callfuncat != self.weaponframe && self.reload_delay2 <= time)
			W_ShowCrosshair(self);
		self.weaponframe_end = self.weaponframe = GetFrame(self.weapon,BASE_FRAME);
		self.new_anim_stop = FALSE;
		self.weapon_anim_type = 0;
		self.weapon_animduration = 0;
		self.callfuncat = 0;
		temp = self.animend;
		self.animend = SUB_Null;
		if (temp)
			temp(S_RIGHT);
	}

	//if (!IsDualWeapon(self.weapon))
	//	W2_Frame_Update();
};

float(string path) model_should_hide_weapon2 =
{
	switch(path) {
		case "models/weapons/grenade/v_grenade.mdl":
		case "models/weapons/grenade/v_betty.mdl":
		case "models/weapons/bk/v_bk.mdl":
		case "models/weapons/knife/v_bowie.mdl":
		case "models/weapons/knife/v_knife.mdl":
		case "models/weapons/morphine/v_morphine.mdl":
			return true;
	}

	return false;
}

void Set_W_Frame (float startframe, float endframe, float duration, float funccalledin, float animtype, void(optional float t) endanimfunc, string set_model, float dontstartnew, float side) =
{
	float math, reversed;

	if (startframe >= endframe) {
		reversed = true;
	} else {
		reversed = false;
	}
	
	math = 0;
	if (duration) {
		math = duration / (fabs(endframe - startframe) + 1);
	} else {
		math = 0.1;
	}

	if (side == S_RIGHT || side == S_BOTH) {
		self.weaponframe = startframe;
		self.weaponframe_end = endframe;
		self.animend = endanimfunc;
		self.callfuncat = funccalledin;
		self.weapon_anim_type = animtype;
		self.new_anim_stop = dontstartnew;
		self.weapon_animduration = math;
		self.anim_reversed = reversed;
	}
	if (side == S_LEFT || side == S_BOTH) {
		self.weapon2frame = startframe;
		self.weapon2frame_end = endframe;
		self.weapon2_anim_type = animtype;
		self.new_anim2_stop = dontstartnew;
		self.weapon2_animduration = math;
		self.anim2_reversed = reversed;

		if (side != S_BOTH) {
			self.animend2 = endanimfunc;
			self.callfuncat2 = funccalledin;
		}
	}
	
	if ((startframe != endframe) && !(self.zoom == 2)) { // naievil -- latter used for checkhold 
		if (side == S_LEFT) {
			self.weapon2model = set_model;
		} else {
			self.weaponmodel = set_model;

			if (model_should_hide_weapon2(set_model) == true) {
				self.weapon2model = "";
			} else if (self.weapon == W_KAR_SCOPE) {	
				self.weapon2model = "models/weapons/kar/v_karscope.mdl";
			} else if (IsDualWeapon(self.weapon)) {	
				self.weapon2model = GetLeftWeaponModel(self.weapon); 
			}
		}
	}
}
