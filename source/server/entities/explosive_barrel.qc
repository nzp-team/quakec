/*
	server/entities/explosive_barrel.qc

	Explosive Barrel entity + logic

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
// Barrel_Explode()
// Remove the entity, play explosion
//
void() Barrel_Explode =
{
	sound (self, CHAN_WEAPON, self.oldmodel, 1, ATTN_NORM);	
	DamgageExplode (self, self.enemy, 1, 250, 250);
	
#ifdef FTE

    te_customflash(self.origin, 128, 300, '1 1 1');

#endif // FTE

    CallExplosion(self.origin);

    SUB_UseTargets ();
	SUB_Remove ();
};

//
// Barrel_Think
// Handles barrel particles and health countdown
//
void() Barrel_Think =
{
    // Spawn the flame particles
    if (self.ltime > 10) {
        Effect_Fire(self.origin + '0 0 45');
        self.ltime = 0;
    }
    self.ltime++;

    // Deplete some health over time
    if (self.currentammo > 20) {
        self.health -= 10 + (rint((random() * 10)));
        self.currentammo = 0;
    }
    self.currentammo++;

    // Remove ourselves and play explosion effects.
    if (self.health <= 0) {
        Barrel_Explode();
    }

    // Iterate
    self.think = Barrel_Think;
    self.nextthink = time + 0.05;
}

//
// Barrel_Hit()
// Called when damage is dealt to Explosive Barrels.
//
void() Barrel_Hit =
{
    // Start the Barrel Explosion timer
    self.think = Barrel_Think;
    self.nextthink = time + 0.01;    
}

//
// explosive_barrel()
// Spawn Function for the Explosive Barrel.
//
void() explosive_barrel =
{
    //
	// Set Default Stats for Compatibility
	//

    // Model
    if (!self.model)
        self.model = "models/props/barrel_m.mdl";
    
    // Health
    if (!self.health)
        self.health = 300;

    // Explosion Sound
    if (!self.oldmodel) {
		self.oldmodel = "sounds/weapons/grenade/explode.wav";
	}

    self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid = SOLID_BBOX;
	self.classname = "explosive_barrel";
    Precache_Set(self.model);
	setsize (self, '-10 -10 ', '10 10 38');

    // Instantly die when shot with the Wunderwaffe
    self.th_diewunder = Barrel_Explode;

	self.takedamage = DAMAGE_YES;
	self.state = 0;
};
