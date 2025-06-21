/*
	server/weapons/ray_gun.qc

	Core logic for the Ballistic Knife special weapon.

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

void() Parse_Damage;

void(entity victim) Blade_Damage =
{
    float damage_type = 0;
    float damage_region = 0;

    switch(victim.classname) {
		case "ai_zombie_head":
            damage_region = HEAD_X;
            damage_type = DMG_TYPE_HEADSHOT;
			break;
		case "ai_zombie_larm":
		case "ai_zombie_rarm":
            damage_region = LIMBS_X;
            damage_type = DMG_TYPE_OTHER;
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

    DamageHandler(victim, self.owner, getWeaponDamage(self.weapon) * getWeaponMultiplier(self.weapon, damage_region), damage_type);
    self.angles_y = 180;
};

void(entity client) Blade_Revive =
{
	// Reward the revivee with the points the downed client lost,
	// and increment their revives stat.
	Player_AddScore(self.owner, other.requirespower, false);
	self.owner.revives++;

    entity old_self = self;
	self = other;
	GetUp();
	self = old_self;

	// Remove the revive icon from above the previously downed client
	DisableReviveIcon(other.playernum);
};

//
// Blade_VelocityIncrease()
// Constant think function to speed up the Beam gradually.
//
void() Blade_VelocityIncrease =
{
    self.angles = vectoangles(self.velocity);
    self.angles_z += (self.angles_z + 180 < 360)? 180 : -180;

	self.velocity *= 1.5;
	self.nextthink = time + 0.1;
}

void() Blade_Die =
{
    remove(self);
};

void() Blade_Pickup =
{
    if (other != self.owner)
        return;

    if (EqualNonPapWeapon(self.owner.weapon) != EqualNonPapWeapon(self.weapon))
        return;

    if (self.owner.weapons[0].weapon_reserve >= getWeaponAmmo(self.owner.weapon))
        return;

    self.owner.weapons[0].weapon_reserve++;
    Blade_Die();
};

//
// Blade_Impact()
// When something touches the Blade, check it's state
// to decide whether to inflict damage or revive a player.
//
void() Blade_Impact =
{
	if (!other.solid || other.solid == SOLID_TRIGGER)
		if (other != world)
			return;

	if (other == self.owner)
		return;

    // Damage monster..
    if (other.flags & FL_MONSTER) {
        Blade_Damage(other);
    } 
    // Revive teammate..
    else if ((other.flags & FL_CLIENT) && self.has_bowie_knife == true) {
        if (other.downed)
            Blade_Revive(other);
    }

    // Lose all velocity, drop to floor..
    self.velocity = '0 0 0';
    self.movetype = MOVETYPE_NONE;
    Spawns_DropToFloor(self);

    self.skin = 1;
    self.solid = SOLID_TRIGGER;
    self.touch = Blade_Pickup;
    self.effects = EF_FULLBRIGHT;
    self.think = Blade_Die;
    self.nextthink = time + 60;
};

//
// W_FireBlade()
// Called by weapon_core for the Blade firetype. Sets up the
// blade and prepares it for impact and force forward.
//
void() W_FireBlade =
{
    // Initially define the blade.
	entity blade;
	blade = spawn();
	blade.owner = self;
	blade.movetype = MOVETYPE_BOUNCE;
	blade.weapon = self.weapon;
	blade.solid = SOLID_BBOX;
	blade.classname = "projectile_blade";

    // Start initial velocity projection.
	makevectors(self.v_angle);
	blade.velocity = v_forward*1750 + v_up*20;
	blade.avelocity = '0 0 0';

	// Make sure our angle is always FORWARD
	blade.angles = vectoangles(blade.velocity);
	blade.angles_z += (blade.angles_z + 180 < 360)? 180 : -180;
	blade.angles = vectoangles(v_forward);
	blade.v_angle = '0 0 200';

    blade.weapon = blade.owner.weapon;

    // Upgraded Blades can revive teammates
    if (blade.owner.weapon == EqualPapWeapon(blade.owner.weapon)) {
        blade.has_bowie_knife = true; // reuse of an entvar
    }

	// Prepare for Impact and Force forward.
	blade.touch = Blade_Impact;
	blade.think = Blade_VelocityIncrease;
	blade.nextthink = time + 0.1;

    // Set model.
	setmodel(blade, "models/weapons/bk/blade.mdl");

    // final setup!
	blade.origin = self.origin + self.view_ofs;
	blade.origin += v_forward * 0;

    makevectors(self.v_angle);
    blade.origin += v_up * -1;

	setorigin(blade, blade.origin);

	self.animend = ReturnWeaponModel;
	self.callfuncat = 0;
}
