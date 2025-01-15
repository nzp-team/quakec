/*
	server/weapons/rocket_launcher.qc

	Core logic for Rocket Launcher/Missile weapons.

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
// Rocket_Die()
// Called to de-spawn the rocket, as it's probably
// not going to go anywhere at this point.
//
void() Rocket_Die =
{
	// Cleanup
	SUB_Remove ();
}

//
// Rocket_Impact()
// When something touches the Missile, check it's validity for
// being used to set up the explosion.
//
void() Rocket_Impact =
{
	if (!other.solid || other.solid == SOLID_TRIGGER)
		if (other != world)
			return;

	if (other == self.owner)
		return;

	float rocket_damage_min;
	float rocket_damage_max;
	float rocket_damage_radius;

	// Longinus is OP!!!!
	if (IsPapWeapon(self.weapon)) {
		rocket_damage_min = 75;
		rocket_damage_max = 1200;
		rocket_damage_radius = 400;
	} else {
		rocket_damage_min = 75;
		rocket_damage_max = 600;
		rocket_damage_radius = 256;
	}

	// Apply the Damage.
	DamgageExplode(self, self.owner, rocket_damage_max,
                   rocket_damage_min, rocket_damage_radius);

	// Spawn Effects

#ifdef FTE

    te_customflash(self.origin, rocket_damage_radius, 300, '1 1 1');

#endif // FTE

    CallExplosion(self.origin);
	CallExplosion(self.origin);
	CallExplosion(self.origin);

	// Clean up!
	SUB_Remove ();
};

//
// W_FireRocket()
// Called by weapon_core for the Rocket firetype. Sets up the
// missile and prepares it for impact, also sets up timeout.
//
void() W_FireRocket =
{
	entity rocket = spawn();
	rocket.owner = self;
	rocket.movetype = MOVETYPE_FLY;

	rocket.weapon = self.weapon;
	rocket.classname = "rocket";
	rocket.solid = SOLID_BBOX;

    // Start initial velocity projection.
	makevectors(self.v_angle);
	rocket.velocity = v_forward*2000;
	rocket.avelocity = '0 0 0';

	// Make sure our angle is always FORWARD
	rocket.angles = vectoangles(rocket.velocity);
	rocket.angles_z += (rocket.angles_z + 180 < 360)? 180 : -180;
	rocket.angles = vectoangles(v_forward);
	rocket.v_angle = '0 0 200';

	// Prepare for Impact and initiate de-spawn timer.
	rocket.touch = Rocket_Impact;
	rocket.think = Rocket_Die;
	rocket.nextthink = time + 8;

    // Set model.
	setmodel(rocket, "models/misc/shark.mdl");
	setsize(rocket, '0 0 0', '0 0 0');

	// final setup!
	rocket.origin = self.origin + self.view_ofs;
	rocket.origin += v_forward * 0;
	setorigin(rocket, rocket.origin);

	self.animend = ReturnWeaponModel;
	self.callfuncat = 0;
}