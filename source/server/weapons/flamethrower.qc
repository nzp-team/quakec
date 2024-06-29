/*
	server/weapons/flamethrower.qc

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
// Flame_LingerThink()
// Play particle effect, remove after expire time.
//
void() Flame_LingerThink =
{
	Effect_Fire(self.origin);

	if (self.ltime < time)
		remove(self);

	self.nextthink = time + 0.1;
}

//
// Flame_Linger(org, whodunit)
// Spawns in the lingering Flame particle effects.
//
void(vector org, entity whodunit) Flame_Linger =
{
	entity linger = spawn();

	setorigin(linger, org);

	linger.owner = whodunit.owner;
	linger.think = Flame_LingerThink;
	linger.nextthink = time + 0.1;
	linger.ltime = time + 5;
}

//
// Flame_Touch
// Something makes contact with the Flames.
//
void() Flame_Touch =
{
	entity target = other;

	// Flame hit a BSP object, so persist/linger to wait for a catch.
	if (target == world) {
		Flame_Linger(self.origin, self);
		remove(self);
	} 
	// Some other entity
	else {
		// Only impact monsters (this also serves as a limb skip :D)
		if (!(target.flags & FL_MONSTER))
			return;

		// Guard this stuff behind first-light
		if (!target.onfire) {
			// They're ours
			target.firer = self.owner;

			// Initialize next-light (this is done to make sure we arent
			// doing intense fire damage right away)
			target.ltime = time + 2;

			// Start the Fire Effect
			Effect_Fire(target.origin);

			// Only do 1 damage to trigger insta-kill damage.
			DamageHandler(target, target.firer, 1, S_FLAME);
		}

		// Set the monster alight
		target.onfire = true;
		target.fire_timeout = time + 10;
	}
}

//
// Flame_DropDissapate()
// Fallen Flame touches a brush, have it linger.
//
void() Flame_DropCatch =
{
	if (other == world) {
		Flame_Linger(self.origin + '0 0 5', self);
		remove(self);
	}
}

//
// Flame_DropDissapate()
// Droplets did not make it to the ground in time.
//
void() Flame_DropDissapate =
{
	remove(self);
}

//
// Flame_Drop()
// Some bits of the flame should fall to the ground, and make it
// dangerous to contact.
//
void() Flame_Drop =
{
	entity drop = spawn();

	drop.owner = self.owner;

	setmodel(drop, "models/sprites/flamer.spr");
	setsize(drop, '0 0 0', '0 0 0');
	setorigin(drop, self.origin);

	drop.touch = Flame_DropCatch;
	drop.think = Flame_DropDissapate;
	drop.nextthink = time + 0.8;
	drop.solid = SOLID_TRIGGER;
	drop.movetype = MOVETYPE_BOUNCE;

	drop.velocity = v_up*-55;
}


//
// Flame_Buildup()
// This is the Flames beginning to combus before falling
// to the ground.
//
void() Flame_Buildup =
{
	self.frame++;

	if (self.frame > 11) {
		if (random() > 0.75)
			Flame_Drop();
		remove(self);
	}

	self.nextthink = time + 0.05;
}

//
// W_FireFlame()
// Called by weapon_core for the Flamethrower firetype. Sets up the
// beam/missile and prepares it for impact and force forward.
//
void() W_FireFlame =
{

	entity flamespr;
	vector rand_angle;

	flamespr = spawn();
	flamespr.owner = self;
	flamespr.movetype = MOVETYPE_FLYMISSILE;
	flamespr.solid = SOLID_TRIGGER;
	flamespr.classname = "flamethrower_sprite";
	flamespr.state = 0;
	flamespr.finaldest = self.v_angle;

	// Randomize the output a tad.
	rand_angle = self.v_angle;
	rand_angle_x += random()*10;
	rand_angle_y += random()*10;
	makevectors(rand_angle);

	flamespr.velocity = aim(self, 1000);
	flamespr.velocity *= 600;

	flamespr.owner = self;

	flamespr.think = Flame_Buildup;
	flamespr.nextthink = time + 0.01;
	flamespr.touch = Flame_Touch;

	setmodel(flamespr, "models/sprites/flamer.spr");
	setorigin(flamespr, self.origin + self.view_ofs - v_up*5 + v_forward*10);
	setsize(flamespr, '0 0 0', '0 0 0');
}