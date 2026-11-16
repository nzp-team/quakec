/*
	server/weapons/grenade.qc

	Stielhandgranate throwing, cooking and tossback

	Copyright (C) 2021-2026 NZ:P Team

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

void() ReturnWeaponModel;
void() W_SprintStop;
void(entity person) W_HideCrosshair;

void() Grenade_UpdatePickupTrigger;

#define GRENADE_PICKUP_RADIUS 64
#define GRENADE_PICKUP_UPDATE 0.05

void(entity grenade) Grenade_RemovePickupTrigger =
{
	if (grenade.grenade_pickup_trigger != world) {
		remove(grenade.grenade_pickup_trigger);
		grenade.grenade_pickup_trigger = world;
	}
};

void() GrenadeExplode =
{
	Grenade_RemovePickupTrigger(self);
	Sound_PlaySound(self, "sounds/weapons/grenade/explode.wav", SOUND_TYPE_WEAPON_EXPLODE, SOUND_PRIORITY_ALLOWSKIP);

	self.enemy = world;
	if (self.classname == "projectile_grenade" && (other.flags & FL_MONSTER))
		self.enemy = other;

	if (self.classname == "grenade")
		DamgageExplode (self, self.owner, 300, 75, 256);
	else
		DamgageExplode (self, self.owner, 1200, 75, 200);

	CallExplosion(self.origin);

	if (self.classname != "player")
		SUB_Remove();
};

void() NadeStraighten =
{
	self.angles_x = (self.angles_x > 0) ? 90 : -90;
};
void() Velocity_reduce =
{
	// If explode-on-contact is on, just explode here..
	if (game_modifier_grenades_explode_on_contact) {
		GrenadeExplode();
		return;
	}

	// Do one (1) damage on monster contact, to kill when Insta-Kill is active.
	if (other.flags & FL_MONSTER)
		DamageHandler(other, self.owner, 1, DMG_TYPE_OTHER);

	if (!other.solid || other.solid == SOLID_TRIGGER)
		if (other != world)
			return;

	self.velocity = self.velocity*0.5;
	
	NadeStraighten();
};

void() W_ThrowGrenade =
{
	string modelname;
	float startframe;
	float endframe;
	local	entity nade;

	W_HideCrosshair(self);

	nade = spawn ();
	nade.owner = self;
	nade.grenade_delay = self.grenade_delay;
	self.grenade_delay = 0;
	self.grenade_returning = false;
	nade.movetype = MOVETYPE_BOUNCE;
	nade.solid = SOLID_BBOX;
	nade.classname = "grenade";

	// set nade speed	

	makevectors (self.v_angle);

	nade.velocity = v_forward*1400;
	
	nade.avelocity = '400 -400 400';

	nade.angles = vectoangles(v_forward);
	nade.angles_z -= 15;
	// set nade duration
	nade.nextthink = (nade.grenade_delay < time + GRENADE_PICKUP_UPDATE) ? nade.grenade_delay : time + GRENADE_PICKUP_UPDATE;
	nade.think = Grenade_UpdatePickupTrigger;

	nade.touch = Velocity_reduce;
	setmodel (nade, "models/weapons/grenade/g_grenade.mdl");
	setsize (nade, '0 0 0', '0 0 0');
	vector eye = self.origin + self.view_ofs;
	vector release_origin = eye + v_forward * 12;
	traceline(eye, release_origin, false, self);
	if (trace_fraction < 1 || trace_startsolid)
		release_origin = eye;
	setorigin(nade, release_origin);

	self.animend = ReturnWeaponModel;
	self.callfuncat = 0;
	self.isBuying = false;

	startframe = GetFrame(self.weapon,TAKE_OUT_START);
	endframe = GetFrame(self.weapon,TAKE_OUT_END);
	modelname = GetWeaponModel(self.weapon, 0);
	Set_W_Frame (startframe, endframe, 0, 0, 0, ReturnWeaponModel, modelname, false, S_BOTH, false);

	SetUpdate(self, UT_HUD, 7, 0, 0);
}

void() Grenade_CheckHold =
{
	if (!self.button3 || self.grenade_delay < time)
	{
		if (!self.grenade_returning && self.grenade_delay < time)
			self.grenade_delay = time + 0.05;
			
		self.isBuying = true;  
		Set_W_Frame (3, 6, 0, 5, GRENADE, W_ThrowGrenade, "models/weapons/grenade/v_grenade.mdl", true, S_RIGHT, true);
		Sound_PlaySound(self, "sounds/weapons/grenade/throw.wav", SOUND_TYPE_WEAPON_OTHER, SOUND_PRIORITY_PLAYALWAYS);
		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
		self.throw_delay = time + 0.9;
		nzp_rumble(self, 1000, 1200, 75);
	}
	else
	{
		if (self.isBuying == false) {
			W_ShowCrosshair(self);
			self.isBuying = true;
		}

		// Pulse the grenade crosshair every 1 second
		float difference = rint(self.grenade_delay - time);
		if (difference != self.beingrevived) {
			self.beingrevived = difference;
			grenade_pulse(self);
		}

		Set_W_Frame (2, 2, 0, 0, GRENADE, Grenade_CheckHold, "models/weapons/grenade/v_grenade.mdl", true, S_RIGHT, true);
	}
}

float() Grenade_CanStart =
{
	return game_modifiers.gameplay.player.can_use_equipment &&
		self.throw_delay <= time && !self.zoom && self.health > 0 && !self.is_spectator &&
		!(self.map_control_flags & PLAYER_CONTROL_FROZEN) && !self.downed && !self.isBuying;
};

void(float fuse) Grenade_Begin =
{
	W_SprintStop();
	W_HideCrosshair(self);
	self.grenade_delay = fuse;
	Set_W_Frame (0, 2, 0.6, 0, GRENADE, Grenade_CheckHold, "models/weapons/grenade/v_grenade.mdl", true, S_RIGHT, true);
	Sound_PlaySound(self, "sounds/weapons/grenade/prime.wav", SOUND_TYPE_WEAPON_OTHER, SOUND_PRIORITY_PLAYALWAYS);
	self.reload_delay2 = self.fire_delay2 = self.throw_delay = self.reload_delay = self.fire_delay = fuse + 1;
	nzp_rumble(self, 1000, 1200, 75);
};

void() W_Grenade =
{
	if (!Grenade_CanStart() || self.primary_grenades < 1)
		return;

	self.primary_grenades -= 1;
	Grenade_Begin(time + 5);
};

float(entity player, entity grenade) Grenade_CanReachPickup =
{
	if (grenade == world || grenade.classname != "grenade" ||
		grenade.grenade_pickup_trigger == world || !(grenade.flags & FL_ONGROUND) ||
		grenade.grenade_delay <= time || vlen(grenade.origin - player.origin) >= GRENADE_PICKUP_RADIUS)
		return false;

	traceline(player.origin + player.view_ofs, grenade.origin, false, player);
	return trace_fraction == 1 || trace_ent == grenade;
};

void() Grenade_PickupTouch =
{
	entity grenade = self.owner;
	if (other.classname != "player" || other.health <= 0 || other.downed || other.is_spectator ||
		grenade.grenade_pickup_trigger != self || !Grenade_CanReachPickup(other, grenade))
		return;

	entity current = other.tossback_grenade;
	if (current != grenade && (!Grenade_CanReachPickup(other, current) ||
		vlen(grenade.origin - other.origin) < vlen(current.origin - other.origin)))
		other.tossback_grenade = grenade;
};

void() Grenade_UpdatePickupTrigger =
{
	if (self.grenade_delay <= time) {
		GrenadeExplode();
		return;
	}

	if (self.flags & FL_ONGROUND) {
		entity trigger = self.grenade_pickup_trigger;
		if (trigger == world) {
			trigger = spawn();
			trigger.classname = "grenade_pickup_trigger";
			trigger.owner = self;
			trigger.solid = SOLID_TRIGGER;
			trigger.touch = Grenade_PickupTouch;
			vector bounds = '1 1 1' * GRENADE_PICKUP_RADIUS;
			setsize(trigger, -bounds, bounds);
			self.grenade_pickup_trigger = trigger;
			setorigin(trigger, self.origin);
		} else if (trigger.origin != self.origin) {
			setorigin(trigger, self.origin);
		}
	} else {
		Grenade_RemovePickupTrigger(self);
	}
	self.nextthink = (self.grenade_delay < time + GRENADE_PICKUP_UPDATE) ? self.grenade_delay : time + GRENADE_PICKUP_UPDATE;
};

entity() Grenade_TossbackTarget =
{
	if (!Grenade_CanReachPickup(self, self.tossback_grenade))
		self.tossback_grenade = world;
	if (!Grenade_CanStart() || self.betty_state || self.grenade_delay > time ||
		self.reload_delay > time || self.new_anim_stop)
		return world;
	return self.tossback_grenade;
};

void(entity grenade) Grenade_Tossback =
{
	float fuse = grenade.grenade_delay;
	self.tossback_grenade = world;
	Grenade_RemovePickupTrigger(grenade);
	remove(grenade);
	self.grenade_returning = true;
	Grenade_Begin(fuse);
};

void() Grenade_CheckReturnedFuse =
{
	if (!self.grenade_returning || self.grenade_delay > time)
		return;

	entity player = self;
	entity blast = spawn();
	blast.classname = "grenade";
	blast.owner = player;
	setorigin(blast, player.origin + player.view_ofs);

	player.grenade_returning = false;
	player.grenade_delay = 0;
	if (player.health > 0 && !player.downed && !player.is_spectator) {
		player.callfuncat = 0;
		player.animend = SUB_Null;
		player.isBuying = false;
		ReturnWeaponModel();
	}

	self = blast;
	GrenadeExplode();
	self = player;
};