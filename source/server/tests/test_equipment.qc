/*
	server/tests/test_equipment.qc

	Unit tests for equipment selection and usage

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
float(float condition, string message) Test_Assert;

entity() Test_EquipmentPlayer =
{
	entity player = spawn();
	player.classname = "player";
	player.health = 100;
	player.weapon = W_COLT;
	player.weapons[0].weapon_id = W_COLT;
	player.weapons[0].weapon_magazine = 8;
	player.primary_grenades = 4;
	player.secondary_grenades = 2;
	player.grenades = 3;
	player.view_ofs = self.view_ofs;
	setorigin(player, self.origin);
	return player;
};

void() Test_Equipment_Selection =
{
	entity old_self = self;
	float old_allowed = game_modifiers.gameplay.player.can_use_equipment;
	game_modifiers.gameplay.player.can_use_equipment = true;
	self = Test_EquipmentPlayer();
	Equipment_Select(1);
	Test_Assert(self.pri_grenade_state == 1 && !self.betty_state && self.secondary_grenades == 2,
		"Selecting Betty must not equip it or spend ammunition");
	self.primary_grenades = 0;
	Equipment_Select(0);
	Test_Assert(self.pri_grenade_state == 1, "Empty grenade selection accepted");
	self.primary_grenades = 4;
	self.grenade_delay = time + 5;
	Equipment_Select(0);
	Test_Assert(self.pri_grenade_state == 1, "Selection changed during a live grenade action");
	self.grenade_delay = 0;
	self.downed = true;
	Equipment_Select(0);
	Test_Assert(self.pri_grenade_state == 1, "Downed player changed equipment");
	remove(self);
	self = old_self;
	game_modifiers.gameplay.player.can_use_equipment = old_allowed;
};

void() TestEquipment_FinishBettyDraw =
{
	for (float frame = 0; frame < 6; frame++) {
		self.anim_weapon_time = 0;
		WeaponCore_UpdateViewModels();
	}
};

void() Test_Equipment_BettyHoldCancelAndFreeze =
{
	entity old_self = self;
	float old_allowed = game_modifiers.gameplay.player.can_use_equipment;
	game_modifiers.gameplay.player.can_use_equipment = true;
	self = Test_EquipmentPlayer();
	self.pri_grenade_state = 1;
	Betty_Toggle();
	Test_Assert(self.betty_state == BETTY_DRAWING && self.weaponframe == 18 && self.weaponframe_end == 13,
		"Drawing Betty must start at the end of the drop animation");
	self.anim_weapon_time = 0;
	WeaponCore_UpdateViewModels();
	Test_Assert(self.weaponframe == 17 && self.betty_state == BETTY_DRAWING,
		"Betty draw did not play the drop frames backwards");
	TestEquipment_FinishBettyDraw();
	Test_Assert(self.betty_state == BETTY_READY && self.secondary_grenades == 2 && !self.isBuying,
		"Drawing Betty must leave movement free and preserve inventory");
	self.anim_weapon_time = 0;
	WeaponCore_UpdateViewModels();
	Test_Assert(self.weaponframe == 13 && self.weaponframe_end == 13,
		"Betty must hold the visible pose after its draw completes");
	self.button0 = true;
	Betty_Input();
	Test_Assert(self.betty_state == BETTY_PRIMING && self.weaponframe == 4 && self.weaponframe_end == 13,
		"Fire must play the visible pin-pull frames");
	for (float frame = 0; frame < 10; frame++) {
		self.anim_weapon_time = 0;
		WeaponCore_UpdateViewModels();
	}
	Test_Assert(self.weaponframe == 13, "Holding Fire must keep the visible Betty pose");
	Test_Assert(self.betty_state == BETTY_HOLDING && self.secondary_grenades == 2 && !self.grenade_delay,
		"Holding Fire must hold Betty without a fuse or spending ammunition");
	self.button3 = true;
	self.semi_actions &= ~SEMIACTION_GRENADE;
	Betty_Input();
	Test_Assert(!self.betty_state && self.secondary_grenades == 2,
		"Equipment button must cancel a held Betty without spending it");
	self.button0 = true;
	Equipment_Update();
	self.weapon = self.weapons[0].weapon_id = W_MP40;
	self.fire_delay = self.reload_delay = 0;
	self.new_anim_stop = false;
	WeaponCore_FireButtonPressed();
	Test_Assert(self.button0 && self.weapons[0].weapon_magazine == 8,
		"Stowing a held Betty leaked Fire into the automatic gun or changed raw input");
	Equipment_Update(); // No new input packet: the raw press must stay consumed.
	Test_Assert(self.equipment_attack_latched & 1, "Fire rearmed without a physical release");
	self.weapon = self.weapons[0].weapon_id = W_COLT;
	self.button0 = self.button3 = false;
	Equipment_Update();
	self.fire_delay = self.reload_delay = self.fire_delay2 = self.reload_delay2 = 0;
	self.new_anim_stop = false;
	Betty_Toggle();
	TestEquipment_FinishBettyDraw();
	self.button0 = true;
	Betty_Input();
	self.map_control_flags = PLAYER_CONTROL_FROZEN;
	self.button0 = false;
	Equipment_Update();
	Betty_Input();
	Test_Assert(self.betty_state == BETTY_READY && self.secondary_grenades == 2 && !(self.equipment_state & 2),
		"Map freeze must cancel placement without spending or losing Betty mode");
	self.map_control_flags = 0;
	self.downed = true;
	Equipment_Update();
	Betty_CheckForRelease();
	Test_Assert(!self.betty_state && self.secondary_grenades == 2,
		"Downed player's canceled animation restored Betty mode");
	remove(self);
	self = old_self;
	game_modifiers.gameplay.player.can_use_equipment = old_allowed;
};

void() Test_Equipment_BettyPlacement =
{
	entity old_self = self;
	float old_allowed = game_modifiers.gameplay.player.can_use_equipment;
	game_modifiers.gameplay.player.can_use_equipment = true;
	self = Test_EquipmentPlayer();
	// Trace from an actual map spawn so this exercises real ground placement.
	entity spawnpoint = find(world, classname, "info_player_start");
	if (spawnpoint != world)
		setorigin(self, spawnpoint.origin);
	self.pri_grenade_state = 1;
	Betty_Toggle();
	TestEquipment_FinishBettyDraw();
	self.button0 = true;
	Betty_Input();
	for (float frame = 0; frame < 18; frame++) {
		self.anim_weapon_time = 0;
		WeaponCore_UpdateViewModels();
	}
	Test_Assert(self.betty_state == BETTY_HOLDING, "Betty animation did not reach its held frame");
	self.button0 = false;
	Betty_CheckForRelease();
	Test_Assert(self.betty_state == BETTY_PLACING && self.secondary_grenades == 2,
		"Release should start placement, not charge before the mine exists");
	for (float frame = 0; frame < 10; frame++) {
		self.anim_weapon_time = 0;
		WeaponCore_UpdateViewModels();
	}
	Test_Assert(self.secondary_grenades == 1 && self.betty_state == BETTY_READY,
		"Placing the first Betty should keep the remaining one equipped");
	Betty_Drop();
	Test_Assert(self.secondary_grenades == 1, "Duplicate drop callback spent another Betty");
	self.button0 = false;
	Betty_Input();
	self.button0 = true;
	Betty_Input();
	self.button0 = false;
	Betty_CheckForRelease();
	Betty_Drop();
	Test_Assert(self.secondary_grenades == 0 && !self.betty_state && self.weapon == W_COLT,
		"Placing the final Betty must restore the inventory weapon");
	entity mine = find(world, classname, "betty");
	while (mine != world) {
		entity next = find(mine, classname, "betty");
		if (mine.owner == self) remove(mine);
		mine = next;
	}
	remove(self);
	self = old_self;
	game_modifiers.gameplay.player.can_use_equipment = old_allowed;
};

void() Test_Equipment_Tossback =
{
	entity old_self = self;
	float old_allowed = game_modifiers.gameplay.player.can_use_equipment;
	game_modifiers.gameplay.player.can_use_equipment = true;
	self = Test_EquipmentPlayer();
	entity grenade = spawn();
	grenade.classname = "grenade";
	grenade.think = Grenade_UpdatePickupTrigger;
	float fuse = time + 1.25;
	grenade.grenade_delay = fuse;
	grenade.owner = old_self;
	setorigin(grenade, self.origin + self.view_ofs);
	entity player = self;
	entity old_other = other;
	self = grenade;
	Grenade_UpdatePickupTrigger();
	Test_Assert(grenade.grenade_pickup_trigger == world, "An airborne grenade created a pickup trigger");
	grenade.flags |= FL_ONGROUND;
	Grenade_UpdatePickupTrigger();
	entity trigger = grenade.grenade_pickup_trigger;
	Test_Assert(trigger != world, "A settled grenade did not create a pickup trigger");
	if (trigger == world) {
		remove(grenade);
		remove(player);
		self = old_self;
		game_modifiers.gameplay.player.can_use_equipment = old_allowed;
		return;
	}
	self = trigger;
	other = player;
	Grenade_PickupTouch();
	other = old_other;
	self = player;
	Test_Assert(self.tossback_grenade == grenade, "Touch did not select the settled grenade");
	grenade.grenade_delay = time;
	Test_Assert(!Grenade_CanReachPickup(self, grenade), "Expired grenade can be returned");
	grenade.grenade_delay = fuse;
	grenade.classname = "projectile_grenade";
	Test_Assert(!Grenade_CanReachPickup(self, grenade), "Launcher projectile can be returned");
	grenade.classname = "grenade";
	self.button3 = true;
	WeaponCore_GrenadeButtonPressed();
	Test_Assert(self.tossback_grenade == world && trigger.solid != SOLID_TRIGGER && self.grenade_delay == fuse &&
		self.primary_grenades == 4 && self.animend == Grenade_CheckHold,
		"Throwback must remove the live grenade and start the normal animation with its original fuse");
	self.button3 = false;
	Grenade_CheckHold();
	Test_Assert(self.animend == W_ThrowGrenade && self.grenade_delay == fuse,
		"Throwback release must use the normal throw callback and preserve the fuse");
	W_ThrowGrenade();
	entity returned = find(world, classname, "grenade");
	while (returned != world && returned.owner != self)
		returned = find(returned, classname, "grenade");
	Test_Assert(returned != world && returned.classname == "grenade" &&
		returned.grenade_delay == fuse && !self.grenade_returning && self.primary_grenades == 4,
		"The normal throw callback must launch with the original fuse and no inventory cost");
	if (returned != world)
		remove(returned);
	remove(self);
	self = old_self;
	game_modifiers.gameplay.player.can_use_equipment = old_allowed;
};
