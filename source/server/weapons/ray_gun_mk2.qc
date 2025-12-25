/*
	server/weapons/ray_gun_mk2.qc

	Core logic for the Ray Gun Mk II special weapon.

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
// Ray2_LaserImpact(victim)
// Calculates damage values, applies them, and kills the Laser.
//
void(entity victim) Ray2_LaserImpact =
{
    float damage_type = 0;
    float damage_region = 0;

	entity damage_target = victim;

    switch(victim.classname) {
		case "ai_zombie_head":
            damage_region = HEAD_X;
            damage_type = DMG_TYPE_HEADSHOT;
			damage_target = victim.owner;
			break;
		case "ai_zombie_larm":
		case "ai_zombie_rarm":
            damage_region = LIMBS_X;
            damage_type = DMG_TYPE_OTHER;
			damage_target = victim.owner;
			break;
		case "ai_zombie":
			if (trace_endpos_z < victim.origin_z) {
                damage_region = LOWER_TORSO_X;
                damage_type = DMG_TYPE_LOWERTORSO;
			}
			else {
                damage_region = UPPER_TORSO_X;
                damage_type = DMG_TYPE_UPPERTORSO;
			}
			break;
		default:
            damage_region = LOWER_TORSO_X;
            damage_type = DMG_TYPE_LOWERTORSO;
			break;
	}

    DamageHandler(damage_target, self.owner, getWeaponDamage(self.weapon, self.weapons[0].weapon_tier) * getWeaponMultiplier(self.weapon, self.perks, damage_region), damage_type);
};

//
// Ray2_VelocityIncrease()
// Constant think function to speed up the Laser gradually.
//
void() Ray2_VelocityIncrease =
{
	self.velocity *= 1.5;
	self.nextthink = time + 0.1;
}

//
// Ray2_Impact()
// When something touches the Laser, check it's validity for
// being used to damage.
//
void() Ray2_Impact =
{
	if (!other.solid || other.solid == SOLID_TRIGGER)
		if (other != world)
			return;

	if (other == self.owner)
		return;

    // The Laser only seems to penetrate on kill, not in general..?
	if ((other.flags & FL_MONSTER) && other.health > 0 && getWeaponPenetration(self.weapon, self.health) != 0) {
        self.health++;
		Ray2_LaserImpact(other);

        // Kill the Laser if the entity didn't die..?
        if (other.health > 0)
            SUB_Remove();
    } else {
		SUB_Remove();
    }
};

//
// W_FireRay2()
// Called by weapon_core for the Ray Laser firetype. Sets up the
// laser and prepares it for impact and force forward.
//
void() W_FireRay2 =
{
    // Initially define the beam.
	entity porter;
	porter = spawn();
	porter.owner = self;
	porter.movetype = MOVETYPE_FLY;
	porter.weapon = self.weapon;
	porter.boxstatus = self.weapons[0].weapon_tier;
	porter.solid = SOLID_BBOX;
	porter.classname = "projectile_raylaser";
    porter.health = 0;

    // Start initial velocity projection.
	makevectors(self.v_angle);
	porter.velocity = v_forward*4000;
	porter.avelocity = '0 0 0';

	// Make sure our angle is always FORWARD
	porter.angles = vectoangles(porter.velocity);
	porter.angles_z += (porter.angles_z + 180 < 360)? 180 : -180;
	porter.angles = vectoangles(v_forward);
	porter.v_angle = '0 0 200';

	// Prepare for Impact and Force forward.
	porter.touch = Ray2_Impact;
	porter.think = Ray2_VelocityIncrease;
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
	porter.scale = 0.16;

	setorigin(porter, porter.origin);

	self.animend = ReturnWeaponModel;
	self.callfuncat = 0;
}
