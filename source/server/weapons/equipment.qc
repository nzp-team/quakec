/*
	server/weapons/bouncing_betty.qc

	Core logic for player equipment.

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
float() Equipment_CanUse =
{
	return self.health > 0 && !self.downed && !self.is_spectator &&
		!(self.map_control_flags & PLAYER_CONTROL_FROZEN) &&
		game_modifiers.gameplay.player.can_use_equipment;
};

void(float selection) Equipment_Select =
{
	if (!Equipment_CanUse() || self.isBuying || self.grenade_delay > time ||
		self.betty_state > BETTY_READY)
		return;
	if (selection != 0 && selection != 1)
		return;
	if (selection == 1 && (!(self.grenades & 2) || self.secondary_grenades < 1))
		return;
	if (selection == 0 && self.primary_grenades < 1)
		return;
	if (selection != self.pri_grenade_state && self.betty_state)
		Betty_Stow();
	self.pri_grenade_state = selection;
};

void() Equipment_Update =
{
	if (!self.button0) self.equipment_attack_latched &= ~1;
	if (!self.button8) self.equipment_attack_latched &= ~2;
	self.equipment_state = 16 + self.pri_grenade_state;
	if (!Equipment_CanUse()) {
		if (self.health <= 0 || self.downed || self.is_spectator) {
			if (self.betty_state && self.weaponmodel == "models/weapons/grenade/v_betty.mdl") {
				self.animend = SUB_Null;
				self.callfuncat = 0;
				self.weaponmodel = "";
			}
			self.betty_state = 0;
		} else if (self.betty_state) {
			if (self.map_control_flags & PLAYER_CONTROL_FROZEN)
				Betty_Ready();
			else
				Betty_Stow();
		}
		return;
	}
	if (self.betty_state && (self.isBuying || self.weaponmodel != "models/weapons/grenade/v_betty.mdl"))
		self.betty_state = 0;
	if (!self.isBuying && self.grenade_delay <= time && self.betty_state <= BETTY_READY)
		self.equipment_state |= 2;
	entity grenade = Grenade_TossbackTarget();
	if (grenade != world)
		Player_UseprintWithWait(self, grenade, useprint_grenade_tossback, 0);
};
