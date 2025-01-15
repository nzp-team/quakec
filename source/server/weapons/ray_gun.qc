/*
	server/weapons/ray_gun.qc

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

//
// Ray_BeamExplode(direct_impact)
// Calculates damage values, calls for an explosion, and
// plays the light effects for the Ray Beam detonation.
// ---
// direct_impact: Denotes whether or not the Beam collided
// with a Monster or if it hit something else (the world).
//
void(float direct_impact) Ray_BeamExplode =
{
	float raybeam_damage_min;
	float raybeam_damage_max;
	float raybeam_damage_radius = 64;

	// Direct shots to the Zombie always deals the same
	// amount of damage, regardless of PaP status.
	if (direct_impact == true) {
		raybeam_damage_min = 1000;
		raybeam_damage_max = 1000;
	} else if (IsPapWeapon(self.weapon)) {
		raybeam_damage_min = 300;
		raybeam_damage_max = 2000;
	} else {
		raybeam_damage_min = 300;
		raybeam_damage_max = 1800;
	}

	// Apply the Damage.
	DamgageExplode(self, self.owner, raybeam_damage_max,
                   raybeam_damage_min, raybeam_damage_radius);

	// Spawn Effects

#ifdef FTE

	// Determine color of the beam
	vector raybeam_color;

	if (IsPapWeapon(self.weapon)) raybeam_color = '1 0 0';
	else raybeam_color = '0 1 0';

	te_customflash(self.origin, raybeam_damage_radius, 300,
                   raybeam_color);
#else

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);

	if (self.effects & EF_RAYGREEN)
		WriteByte (MSG_BROADCAST, TE_RAYSPLASHGREEN);
	else
		WriteByte (MSG_BROADCAST, TE_RAYSPLASHRED);

	WriteCoord (MSG_BROADCAST, self.origin_x);
	WriteCoord (MSG_BROADCAST, self.origin_y);
	WriteCoord (MSG_BROADCAST, self.origin_z);

#endif // FTE

	// Cleanup
	SUB_Remove ();
};

//
// Ray_VelocityIncrease()
// Constant think function to speed up the Beam gradually.
//
void() Ray_VelocityIncrease =
{
	self.velocity *= 1.5;
	self.nextthink = time + 0.1;
}

//
// Ray_Impact()
// When something touches the Beam, check it's validity for
// being used to set up the explosion.
//
void() Ray_Impact =
{
	if (!other.solid || other.solid == SOLID_TRIGGER)
		if (other != world)
			return;

	if (other == self.owner)
		return;

	float direct_impact;

	if (other.flags & FL_MONSTER)
		direct_impact = true;
	else
		direct_impact = false;

	Ray_BeamExplode(direct_impact);
};

//
// W_FireRay()
// Called by weapon_core for the Ray firetype. Sets up the
// beam/missile and prepares it for impact and force forward.
//
void() W_FireRay =
{
    // Initially define the beam.
	entity porter;
	porter = spawn();
	porter.owner = self;
	porter.movetype = MOVETYPE_FLY;
	porter.weapon = self.weapon;
	porter.solid = SOLID_BBOX;
	porter.classname = "projectile_raybeam";

    // Start initial velocity projection.
	makevectors(self.v_angle);
	porter.velocity = v_forward*2000;
	porter.avelocity = '0 0 0';

	// Make sure our angle is always FORWARD
	porter.angles = vectoangles(porter.velocity);
	porter.angles_z += (porter.angles_z + 180 < 360)? 180 : -180;
	porter.angles = vectoangles(v_forward);
	porter.v_angle = '0 0 200';

	// Prepare for Impact and Force forward.
	porter.touch = Ray_Impact;
	porter.think = Ray_VelocityIncrease;
	porter.nextthink = time + 0.1;

    // Set model.
	setmodel(porter, "models/misc/raybeam.mdl");
	setsize(porter, '0 0 0', '0 0 0');

    // Prepare trail effects.
	if (IsPapWeapon(porter.weapon)) {

#ifdef FTE

		Light_Custom(porter, false, 75, 2, 0.25, 0.25);

#else
	
		porter.effects = EF_RAYRED;

#endif // FTE

	} else {

#ifdef FTE

		Light_Custom(porter, false, 75, 0.25, 2, 0.25);

#else

		porter.effects = EF_RAYGREEN;
		
#endif	// FTE

	}

    // final setup!
	porter.origin = self.origin + self.view_ofs;
	porter.origin += v_forward * 0;

	// Start at the barrel offset if not ADS
	if (self.zoom == 0) {
		makevectors(self.v_angle);
		// Y, Z, X
		vector ads_pos = GetWeaponFlash_Offset(self.weapon);
		porter.origin += v_right * (ads_pos.x/1000);
    	porter.origin += v_up * (ads_pos.y/1000);
    	porter.origin += v_forward * (ads_pos.z/1000);
	}

	setorigin(porter, porter.origin);

	self.animend = ReturnWeaponModel;
	self.callfuncat = 0;
}
