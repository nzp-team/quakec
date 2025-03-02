/*
	server/entities/power_switch.qc

	Power Switch Entity Logic

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

#define POWER_SPAWNFLAG_NOHANDLE     1

void(entity who) Turn_PerkLight_On;

//
// Power_ActivateLights()
// Activates Perk Light Effects and LightStyles
//
void() Power_ActivateLights =
{
	// Perk Lights
	entity tempe = findfloat(world, requirespower, 1);
	while (tempe)
	{
		Turn_PerkLight_On(tempe);
		tempe = findfloat (tempe, requirespower, 1);
	}

	// Light Styles
	tempe = find(world, classname, "light");
	while(tempe)
	{
		if (tempe.spawnflags & LIGHT_SPAWNFLAG_STARTOFF) {
			tempe.style = tempe.score;
			LS_Setup();
		}

		tempe = find(tempe, classname, "light");
	}
} 

//
// Power_HandleStop()
// Stops "flipping" the Power Switch handle.
//
void() Power_HandleStop =
{
    self.avelocity = '0 0 0';
    self.think = SUB_Null;
}

//
// Power_HandleFlip()
// Programmatically "flips" the Power Switch handle.
//
void() Power_HandleFlip =
{
    self.boxweapon.avelocity = '185 0 0';
    self.boxweapon.think = Power_HandleStop;
    self.boxweapon.nextthink = time + 0.50;
}

//
// Power_Touch()
// Power Switch touch function, triggers global activation.
//
void() Power_Touch =
{
	if (other.classname != "player" || other.downed)
		return;

	if (isPowerOn == true)
    	return;
	
	entity tempe;
	entity old_self;

	Player_UseprintWithWait(other, self, 10, 0, 0);
	if (Player_UseButtonPressed(other, self) && !isPowerOn) {

        // Animate the handle programmatically.
        if (!(self.spawnflags & POWER_SPAWNFLAG_NOHANDLE))
		    Power_HandleFlip();

        // Play the sound of the Power Switch flipping
        if (self.powerup_vo != "")
            Sound_PlaySound(self, self.powerup_vo, SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);

		isPowerOn = true;
		Sound_PlaySound(world, self.oldmodel, SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);

        // Trigger all doors that are marked as requiring power.
		tempe = find (world, classname, "door_nzp");
		while (tempe) {
			entity starte;

			if (!tempe.targetname) {
				if (!tempe.cost) {
					old_self = self;
					self = tempe;
					starte = self;
					door_go_up ();
					tempe.classname = "door_open";
					tempe = find (tempe, classname, "door_nzp");
					self = old_self;
				}
			}
			if (tempe.targetname != "") {
				old_self = self;
				self = tempe;
				remove(self);
				self = old_self;
				tempe = find (tempe, classname, "door_nzp");
			}
		}

		tempe = find(world, classname, "perk_pap");
		while(tempe != world) {
			entity tempe2 = self;
			self = tempe;
			PAP_TurnOn();
			self = tempe2;
			tempe = find(tempe, classname, "perk_pap");
		}

		Power_ActivateLights();
		SUB_UseTargets();
	}
}

void() power_switch =
{
	//
	// Set Default Stats for Compatibility
	//

    // Model
    if (!self.model)
        self.model = "models/machines/quake_scale/power_switch.mdl";

    // Handle Model
    if (!self.weapon2model)
        self.weapon2model = "models/machines/quake_scale/power_handle.mdl";

    // Compatibility Hack -- it doesn't make sense if the Power Switch is HL
    // and the handle is Quake.
    if (self.model == "models/machines/hl_scale/power_switch.mdl" && 
    self.weapon2model == "models/machines/quake_scale/power_handle.mdl") {
        self.weapon2model = "models/machines/hl_scale/power_handle.mdl";
        self.box1 = '-3 0 -2';
    }

	// Power Sound (Plays Everywhere)
	if (!self.oldmodel)
		self.oldmodel = "sounds/machines/power.wav";

    // Handle Offset
    if (!self.box1)
        self.box1 = '-4 0 12';

    // Switch Flip Sound (Spatialized)
    if (self.powerup_vo != "")
        precache_sound(self.powerup_vo);

	self.solid = SOLID_TRIGGER;
	Precache_Set(self.model);
	precache_sound(self.oldmodel);
	setorigin (self, self.origin);
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	self.classname = "power_switch";
	self.touch = Power_Touch;

    // Spawn the Handle
    if (!(self.spawnflags & POWER_SPAWNFLAG_NOHANDLE)) {
        precache_model(self.weapon2model);
        entity handle = spawn();
        setmodel(handle, self.weapon2model);
        makevectors(self.angles);
        handle.origin = self.origin;
        handle.origin += v_right * self.box1_y;
        handle.origin += v_forward * self.box1_x;
        handle.origin += v_up * self.box1_z;
        handle.angles = self.angles;
        setorigin(handle, handle.origin);
        handle.movetype = MOVETYPE_NOCLIP;
        self.boxweapon = handle;
    }

    // Set the global flag that indicates the Power isn't on
    isPowerOn = false;
}
