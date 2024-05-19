/*
	server/weapons/bouncing_betty.qc

	Core logic for the "Bouncing Betty" grenade.

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
void() W_PlayTakeOut;

//
// Betty_Rise()
// Rise from the ground and explode.
//
void() Betty_Rise =
{
	if (self.ltime < time) {
		self.velocity = '0 0 0';
		self.movetype = MOVETYPE_NONE;
		self.think = SUB_Null;
		GrenadeExplode();
	}

	self.nextthink = time + 0.05;
	makevectors(self.angles);
	self.velocity = v_up*100;
}

//
// Betty_Touch()
// Check if contact is with an enemy,
// trigger if so.
//
void() Betty_Touch = 
{
	// Only trigger if an enemy is making contact.
	if (other.classname != "ai_zombie" && other.classname != "ai_dog")
		return;
    // Additional sanity check -- don't activate because of us.
  	if (other == self.owner || other.solid == SOLID_TRIGGER)
    	return;
	// Don't activate if our center point can't even reach the enemy
	if (!CanDamage(other, self))
		return;

    // Next step is to rise!
	self.think = Betty_Rise;
	self.touch = SUB_Null;
	self.nextthink = time + 0.1;

    // Set a timer for when to explode.
	self.ltime = time + 0.28;
}

//
// Betty_Drop()
// Spawns the Betty grenade and puts it
// on the ground.
//
void() Betty_Drop =
{
    // Spawn it and set its attributes.
	entity betty;
	betty = spawn ();
	betty.owner = self;
	betty.grenade_delay = betty.owner.grenade_delay;
	betty.owner.grenade_delay = 0;
	betty.movetype = MOVETYPE_NOCLIP;
	betty.solid = SOLID_TRIGGER;
	betty.classname = "betty";

	betty.velocity = v_forward*0;
	betty.touch = Betty_Touch;

	setmodel (betty, "models/weapons/grenade/g_betty.mdl");
	setsize (betty, '-64 -64 -4', '64 64 32');

	betty.origin = betty.owner.origin - self.view_ofs + '0 0 1';

	// If we're in the air, just drop the betty to the ground
    // cypress -- This felt a little whack so I checked World at War..
    // ..and it does this too, so..
	if (!(self.flags & FL_ONGROUND)) {
		entity oldself;
		oldself = self;
		self = betty;
		
#ifdef FTE

		droptofloor();

#else

		droptofloor(0, 0);

#endif // FTE

		self = oldself;
    }

    // Sink into the ground a bit
    betty.origin += v_forward * 0;
    betty.origin += v_up * -1;
	setorigin (betty, betty.origin);

    // Return the player's weapon to them
	self.animend = W_PlayTakeOut;
	self.callfuncat = 0;
	self.isBuying = false;  
}

//
// Betty_CheckForRelease()
// Holds the Bouncing Betty until the
// action button is released, then kicks
// off spawning the entity.
//
void() Betty_CheckForRelease =
{
    // Release the Betty
	if (!self.button3) {
		if(self.grenade_delay < time)
			self.grenade_delay = time + 0.05;
		self.isBuying = true;
		Set_W_Frame (13, 19, 0.3, 5, GRENADE, Betty_Drop, "models/weapons/grenade/v_betty.mdl", true, S_RIGHT);
		sound (self, CHAN_WEAPON, "sounds/weapons/grenade/throw.wav", 1, ATTN_NORM);
		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
		self.throw_delay = time + 0.9;
	}
    // Keep holding it
	else {    
		self.isBuying = true;
		Set_W_Frame (13, 13, 0, 0, GRENADE, Betty_CheckForRelease, "models/weapons/grenade/v_betty.mdl", true, S_RIGHT);
	}	
}

//
// W_PrimeBetty()
// Priming/Init state for the Bouncing Betty,
// called inside of weapon_core.
//
void() W_PrimeBetty = 
{
	if (self.throw_delay > time || self.zoom || self.downed || self.secondary_grenades < 1 || self.isBuying)
		return;

	// Prevent the Player from Sprinting and also avoid issues with
	// the equipment being completely cancelled..
	if (self.sprinting)
		W_SprintStop();

	W_HideCrosshair(self);

    // Play the "prime" animation for the betty viewmodel.
	Set_W_Frame (0, 13, 1, 0, GRENADE, Betty_CheckForRelease, "models/weapons/grenade/v_betty.mdl", true, S_RIGHT);

    // Subtract a betty from our inventory, set up delays, prevent use spam.
	self.secondary_grenades -= 1;
	self.grenade_delay = self.reload_delay2 = self.fire_delay2 = self.throw_delay = self.reload_delay = self.fire_delay = time + 6;
}