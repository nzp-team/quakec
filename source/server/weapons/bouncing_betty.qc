/*
	server/weapons/bouncing_betty.qc

	Core logic for the "Bouncing Betty" grenade.

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
void() W_PlayTakeOut;
void() W_SprintStop;
void() W_AimOut;
void() Betty_Ready;

#define BETTY_PIN_PULL_START 4
#define BETTY_DROP_START 13
#define BETTY_DROP_END 18
#define BETTY_DROP_DURATION 0.3

void() Betty_Explode =
{
	Sound_PlaySound(self, "sounds/weapons/grenade/explode.wav", SOUND_TYPE_WEAPON_EXPLODE, SOUND_PRIORITY_ALLOWSKIP);
	DamgageExplode(self, self.owner, 12000, 11000, 128);
	CallExplosion(self.origin);
	SUB_Remove();
};

void() Betty_Rise =
{
	if (self.ltime <= time) {
		Betty_Explode();
		return;
	}
	self.velocity = '0 0 100';
	self.nextthink = time + 0.05;
};

void() Betty_Touch =
{
	if (other.classname != "ai_zombie" && other.classname != "ai_dog")
		return;
	if (other == self.owner || other.solid == SOLID_TRIGGER || !CanDamage(other, self))
		return;
	self.think = Betty_Rise;
	self.touch = SUB_Null;
	self.nextthink = time + 0.1;
	self.ltime = time + 0.28;
};

void() Betty_Stow =
{
	if (!self.betty_state)
		return;
	W_SprintStop();
	self.betty_state = 0;
	self.equipment_attack_latched = self.button0 + self.button8 * 2;
	self.grenade_delay = 0;
	self.new_anim_stop = false;
	self.semi_actions |= SEMIACTION_FIRE_RIGHT | SEMIACTION_FIRE_LEFT;
	self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.3;
	W_PlayTakeOut();
};

void() Betty_Ready =
{
	if (!self.betty_state)
		return;
	if (self.secondary_grenades < 1) {
		Betty_Stow();
		return;
	}
	self.betty_state = BETTY_READY;
	Set_W_Frame(BETTY_DROP_START, BETTY_DROP_START, 0, 0, GRENADE, SUB_Null, self.weaponmodel, false, S_RIGHT, false);
	W_HideCrosshair(self);
};

void() Betty_Drop =
{
	if (self.betty_state != BETTY_PLACING || self.secondary_grenades < 1)
		return;

	// Trace from the player's centre, rather than subtracting stance-dependent eye height.
	traceline(self.origin, self.origin - '0 0 256', true, self);
	if (trace_fraction == 1 || trace_allsolid || trace_plane_normal_z < 0.5) {
		Betty_Ready();
		return;
	}
	entity betty = spawn();
	betty.owner = self;
	betty.movetype = MOVETYPE_NOCLIP;
	betty.solid = SOLID_TRIGGER;
	betty.classname = "betty";
	betty.touch = Betty_Touch;
	vector placement = trace_endpos;

	setmodel(betty, "models/weapons/grenade/g_betty.mdl");
	setsize(betty, '-64 -64 -4', '64 64 32');
	setorigin(betty, placement);

	self.secondary_grenades -= 1;
	self.betty_attack_released = false;

	nzp_rumble(self, 1000, 1200, 75);
	Betty_Ready();
};

void() Betty_CheckForRelease =
{
	if (!self.betty_state)
		return;
	self.betty_state = BETTY_HOLDING;
	if (!self.button0) {
		self.betty_state = BETTY_PLACING;
		Set_W_Frame(BETTY_DROP_START, BETTY_DROP_END, BETTY_DROP_DURATION, 0, GRENADE, Betty_Drop,
			"models/weapons/grenade/v_betty.mdl", true, S_RIGHT, false);
		Sound_PlaySound(self, "sounds/weapons/grenade/throw.wav", SOUND_TYPE_WEAPON_OTHER, SOUND_PRIORITY_PLAYALWAYS);
	} else {
		Set_W_Frame(BETTY_DROP_START, BETTY_DROP_START, 0, 0, GRENADE, Betty_CheckForRelease,
			"models/weapons/grenade/v_betty.mdl", true, S_RIGHT, false);
	}
};

void() Betty_Toggle =
{
	if (self.betty_state) {
		if (self.betty_state != BETTY_PLACING)
			Betty_Stow();
		return;
	}

	if (!game_modifiers.gameplay.player.can_use_equipment || self.health <= 0 ||
		self.downed || self.is_spectator || (self.map_control_flags & PLAYER_CONTROL_FROZEN) ||
		self.secondary_grenades < 1 || self.isBuying || self.throw_delay > time ||
		self.reload_delay > time || self.fire_delay > time || self.new_anim_stop ||
		self.reload_delay2 > time || self.fire_delay2 > time || self.new_anim2_stop)
		return;

	W_AimOut();
	W_SprintStop();
	self.ads_release = self.has_ads_toggle = false;
	self.betty_state = BETTY_DRAWING;
	self.betty_attack_released = !self.button0;
	self.semi_actions |= SEMIACTION_GRENADE;
	self.weaponmodel = "models/weapons/grenade/v_betty.mdl";
	self.weapon2model = "";
	self.animend2 = SUB_Null;
	self.callfuncat2 = 0;
	self.new_anim2_stop = false;
	self.viewmodel_effects = self.viewmodel2_effects = 0;
	Set_W_Frame(BETTY_DROP_END, BETTY_DROP_START, BETTY_DROP_DURATION, 0, GRENADE, Betty_Ready,
		self.weaponmodel, true, S_RIGHT, false);
	self.anim_weapon_time = time + self.weapon_animduration;
	W_HideCrosshair(self);
};

float() Betty_Input =
{
	if (!self.betty_state)
		return false;
	if (self.map_control_flags & PLAYER_CONTROL_FROZEN)
		return true;
	if (!self.button7)
		self.semi_actions &= ~SEMIACTION_USE;
	if (!self.button3)
		self.semi_actions &= ~SEMIACTION_GRENADE;
	if (!self.button0)
		self.betty_attack_released = true;
	if ((self.button3 && !(self.semi_actions & SEMIACTION_GRENADE)) || self.button4) {
		self.semi_actions |= SEMIACTION_GRENADE | SEMIACTION_WEAPONSWAP;
		Betty_Toggle();
		return true;
	}
	if (self.betty_state == BETTY_READY && self.button0 && self.betty_attack_released) {
		W_SprintStop();
		self.betty_attack_released = false;
		self.betty_state = BETTY_PRIMING;

		Set_W_Frame(BETTY_PIN_PULL_START, BETTY_DROP_START, 0.7, 0, GRENADE, Betty_CheckForRelease, self.weaponmodel, true, S_RIGHT, false);
	}
	return true;
};
