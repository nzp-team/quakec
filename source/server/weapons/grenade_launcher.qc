/*
	server/weapons/grenade_launcher.qc

	Core logic for the Ray Gun special weapon.
	Modified from Unofficial Patch implementation.

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
void() GrenadeExplode;

//
// W_FireGrenade()
// Called by weapon_core for the Grenade firetype. Sets up the
// nade and prepares it for impact and force forward.
//
void(float side) W_FireGrenade = 
{
	entity nade = spawn();
	nade.owner = self;
	nade.movetype = MOVETYPE_BOUNCE;
	nade.solid = SOLID_BBOX;
	nade.classname = "projectile_grenade";

	makevectors (self.v_angle);

	nade.velocity = v_forward*3000;		
	nade.avelocity = '50 -50 50';

	nade.touch = GrenadeExplode;
	setsize(nade, '0 0 0', '0 0 0');
	nade.origin = self.origin + self.view_ofs;

	setorigin(nade, nade.origin);

#ifdef FTE

	FTE_RunParticleEffect(self, CSQC_PART_MUZZLEFLASH, '0 0 0', side, world);

#endif // FTE
}