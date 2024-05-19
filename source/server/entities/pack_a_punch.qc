/*
	server/entities/pack_a_punch.qc

	Pack-A-Punch Entity Logic

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

#define PAP_SPAWNFLAG_USEROLLER     1
#define PAP_SPAWNFLAG_USEFLAG 		2
#define PAP_SPAWNFLAG_NOSPARK       4

void() W_PutOutHack;
void(vector where, float time_alive) SpawnSpark;

//
// PAP_FlagStopMoving()
// Resets flag's angular velocity.
//
void() PAP_FlagStopMoving =
{
	self.avelocity = '0 0 0';

	if (self.ltime)
		self.angles_z = 180;
	else
		self.angles_z = 0;

	self.think = SUB_Null;
}

//
// PAP_FlagMoveDown()
// Moves the Flag Downwards
//
void() PAP_FlagMoveDown =
{
	// Make a note that we're moving "down"
	self.ltime = 1;
	self.avelocity = '0 0 500';
	self.think = PAP_FlagStopMoving;
	self.nextthink = time + 0.35;
}

//
// PAP_FlagMoveUp()
// Moves the Flag upwards
//
void() PAP_FlagMoveUp =
{
	// Make a note that we're moving "up"
	self.ltime = 0;
	self.avelocity = '0 0 -500';
	self.think = PAP_FlagStopMoving;
	self.nextthink = time + 0.35;
}

//
// PAP_WeaponFallIntoMachine()
// Slowy reel the Upgraded Weapon back into
// the Pack-A-Punch.
//
void() PAP_WeaponFallIntoMachine = 
{
    makevectors(self.usedent.angles);
	self.velocity = '0 0 0';
	setorigin(self, self.usedent.oldorigin + v_forward*self.usedent.oldz);
    self.velocity = v_forward*-1.5;
};

//
// PAP_WeaponStopMoving()
// Stop all velocity on the floating Weapon
// and let it sit in the machine.
//
void() PAP_WeaponStopMoving = 
{
	self.velocity = [0,0,0];
	setorigin(self, self.usedent.oldorigin);
};

//
// PAP_Reset()
// Allow the Pack-A-Punch to Upgrade another Weapon.
//
void() PAP_Reset =
{
	self.weapon = 0;
	self.usedent = 0;


	if (self.goaldummy) {
		remove(self.goaldummy);
		self.goaldummy = 0;
	}


	self.papState = 0;
};

//
// PAP_Tick()
// Weapon is slowly going back to machine, tick for
// anxiety.
//
void() PAP_Tick =
{
	// Time is up, Weapon is gone.
	if (self.ltime < time)
		PAP_Reset();
	else {
		sound(self, CHAN_BODY, "sounds/machines/packapunch/tick.wav", 1, 1);
		self.nextthink = time + 0.87;
	}
};

//
// PAP_SendWeaponOut()
// Spits out the floating Weapon for pick-up.
//
void() PAP_SendWeaponOut = 
{
    makevectors(self.angles);

	self.goaldummy.origin = self.oldorigin;
	setorigin(self.goaldummy, self.goaldummy.origin);
    self.goaldummy.velocity = v_forward*self.oldz;
    
	// Reel the Weapon in
    self.goaldummy.think = PAP_WeaponFallIntoMachine;
    self.goaldummy.nextthink = time + 1;

	self.papState = 2;
	self.nextthink = time + 0.05;
	self.ltime = time + 15;
    self.think = PAP_Tick;
    Light_None(self);

	if ((self.spawnflags & PAP_SPAWNFLAG_USEFLAG)) {
		self.boxweapon.think = PAP_FlagMoveDown;
		self.boxweapon.nextthink = time + 0.05;
	}
};

//
// PAP_UpgradeWeapon(pap, buyer)
// Prepares a weapon for Upgrade and initiates Player
// animation.
//
void(entity pap, entity buyer) PAP_UpgradeWeapon =
{
   	entity tempe;

	tempe = self;
	self = buyer;
	addmoney (self, -pap.cost, 0);

	// Spawn Upgrade Spark if permitted
    if (!(pap.spawnflags & PAP_SPAWNFLAG_NOSPARK))
        SpawnSpark(pap.box2, 3.5);

	// Machine is using the flag, so spawn it in.
	if ((pap.spawnflags & PAP_SPAWNFLAG_USEFLAG)) {
		pap.boxweapon.think = PAP_FlagMoveUp;
		pap.boxweapon.nextthink = time + 0.05;
	}

	// Give a nice blue glow and play upgrade sound
    Light_Cyan(pap, false);
    sound(pap, CHAN_ITEM, pap.oldmodel, 0.8, 1);

	// Mapper-provided musical sting.
	if (pap.powerup_vo)
		sound(pap, CHAN_AUTO, pap.powerup_vo, 1, ATTN_IDLE);

	//
	// Spawn and prepare the floating Weapon
	//    
	entity floating_weapon = spawn();
	string floating_weapon_model = GetWeaponModel(self.weapon, 1);
	setmodel(floating_weapon, floating_weapon_model);
	setsize(floating_weapon, '0 0 0', '0 0 0');
	floating_weapon.movetype = MOVETYPE_NOCLIP;
	floating_weapon.solid = SOLID_NOT;

	// Send the model into the Machine
	makevectors(pap.angles);
	floating_weapon.origin = pap.oldorigin;
	setorigin(floating_weapon, floating_weapon.origin + v_forward * pap.oldz);
	floating_weapon.angles = pap.angles;
	floating_weapon.angles_y = 90 + pap.angles_y;
    floating_weapon.velocity = v_forward*-pap.oldz;
    floating_weapon.think = PAP_WeaponStopMoving;
    floating_weapon.nextthink = time + 1;

	// Link the Weapon with the Machine
	floating_weapon.usedent = pap;
    pap.usedent = self;
	pap.goaldummy = floating_weapon;

	// Upgrade Timer
    pap.think = PAP_SendWeaponOut;
    pap.nextthink = time + 3.5;

	// Play Player's view model animation and sound.
	self.fire_delay = self.reload_delay = 2.0 + time;
	sound(self,CHAN_WEAPON,"sounds/machines/papsound.wav",1,ATTN_NORM);

	pap.weapon = self.weapon;

	Weapon_RemoveWeapon(0);
	W_HideCrosshair(self);
	Set_W_Frame (0, 39, 2.0, 0, 0, W_PutOutHack, "models/machines/v_pap.mdl", true, S_BOTH);
	self.weapon2model = "";

#ifndef FTE

	self.Weapon_Name = "";

#endif // FTE

	self = tempe;

	// Notify that the Machine is currently Upgrading.
	self.papState = 1;	
};

//
// PAP_Touch()
// Touch/Interaction function for Clients + Pack-A-Punch.
//
void() PAP_Touch =
{
  
	if (other.classname != "player" || other.downed || !PlayerIsLooking(other, self)) {
		return;
	}

	if (other.reload_delay > time || other.reload_delay2 > time || 
	other.fire_delay > time || other.fire_delay2 > time)
		return;
    
	// Power is not turned on.
	if (self.requirespower == true && !isPowerOn) {
		useprint (other, 8, 0, 0);
		return;
	}
  
	// Purchasing Machine + putting Weapon in
	if (!self.papState) {
		if (IsPapWeapon(other.weapon) == 1) {
			return;
		}

		useprint (other, 12, self.cost, 5);

		// Player has enough points, begin Upgrade process
		if (other.points >= self.cost && other.button7 && other.weapon) {
			PAP_UpgradeWeapon(self, other);
		} 
		// They're broke! Notify.
		else if (other.button7 && other.weapon && !(other.semi_actions & SEMIACTION_USE)) {
			other.semi_actions |= SEMIACTION_USE;
			centerprint (other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
		}
	} 

	// Claiming upgraded Weapon
	else if (self.papState == 2) {

#ifndef FTE

		other.Weapon_Name_Touch = GetWeaponName(EqualPapWeapon(self.weapon));

#endif // FTE

		useprint (other, 7, 0, EqualPapWeapon(self.weapon));

		if (other.button7) {
 			entity tempe = self;
 			self = other;
			Weapon_GiveWeapon(EqualPapWeapon(tempe.weapon), 0, 0);
			self = tempe;

			// Prep Pack-A-Punch to Upgrade again
			self.think = PAP_Reset;
			self.nextthink = time + 0.1;
		}
	}
};

//
// PAP_RotateRoller()
// Think function for the Rollers - rotate indefinitely.
//
void() PAP_Click =
{
	if (!self.active_door.papState)
    	sound(self, CHAN_ITEM, "sounds/machines/packapunch/gear_shift.wav", 1, 1);
    self.nextthink = time + 0.75;
};

//
// PAP_TurnOn()
// Turns on the Pack-A-Punch machine.
//
void() PAP_TurnOn =
{
	if (self.active_door != world) {
		self.active_door.movetype = MOVETYPE_NOCLIP;
		self.active_door.avelocity = '-200 0 0';
		self.active_door.think = PAP_Click;
		self.active_door.nextthink = time + 0.75;
	}
};

//
// PAP_Initialize()
// Turns the Pack-A-Punch On if the Power is on.
//
void() PAP_Initalize =
{
    // Start on if there's no Power Switch
	entity tempe = find (world, classname, "power_switch");
    if (tempe) self.requirespower = true;
    else PAP_TurnOn();
};

//
// perk_pap()
// QuakeC Spawn Function for Pack-A-Punch Machine
//
void() perk_pap = 
{ 
    //
	// Set Default Stats for Compatibility
	//
	
	// Model
	if (!self.model || self.model == "models/machines/hl_scale/pap.mdl") {
		self.model = "models/machines/quake_scale/pap.mdl";
	}

	// Floating Weapon Offset
	if (!self.oldorigin) {
		self.oldorigin = '0 0 -1';
	}

	// Floating model forward velocity
	if (!self.oldz) {
		self.oldz = 20;
	}

    // Roller Model
    if (!self.weapon2model) {
        self.weapon2model = "models/machines/hl_scale/pap/p_roller.mdl";
    }

    // Roller Offset
    if (!self.box1) {
        self.box1 = '7.5 0.1 6.0';
    }

    // Flag Model
    if (!self.door_model_name) {
        self.door_model_name = "models/machines/hl_scale/pap/p_flag.mdl";
    }

    // Flag Offset
    if (!self.box3) {
        self.box3 = '-18 -31.7 18';
    }

    // Spark Offset
    if (!self.box2) {
        self.box2 = '8 0 2';
    }

    // Cost
	if (!self.cost) {
		self.cost = 5000;
	}

    // Upgrade Sound
	if (!self.oldmodel) {
		self.oldmodel = "sounds/machines/packapunch/upgrade.wav";
	}

	self.model = Compat_ConvertOldAssetPath(self.model);
	self.weapon2model = Compat_ConvertOldAssetPath(self.weapon2model);
	self.door_model_name = Compat_ConvertOldAssetPath(self.door_model_name);

    // Precaches
	// FIXME: Don't hardcode weapon precaches here.
	precache_extra(W_SNUFF);

	precache_model (self.model);
	precache_model ("models/machines/v_pap.mdl");

	if (!(self.spawnflags & PAP_SPAWNFLAG_NOSPARK))
		precache_model("models/sprites/lightning.spr");

	precache_sound(self.oldmodel);

	if (self.powerup_vo)
		precache_sound(self.powerup_vo);

	precache_sound ("sounds/machines/papsound.wav");
	precache_sound("sounds/weapons/papfire.wav");
    precache_sound("sounds/machines/packapunch/gear_shift.wav");
	precache_sound("sounds/machines/packapunch/tick.wav");

    // Lock its Pitch and Roll (sorry!)
    self.angles_x = 0;
    self.angles_z = 0;

    // Spawn the Roller
    if (self.spawnflags & PAP_SPAWNFLAG_USEROLLER) {
        precache_model(self.weapon2model);
        entity roller = spawn();
        setmodel(roller, self.weapon2model);
        makevectors(self.angles);
        roller.origin = self.origin;
        roller.origin += v_right * self.box1_y;
        roller.origin += v_forward * self.box1_x;
        roller.origin += v_up * self.box1_z;
        roller.angles = self.angles;
        setorigin(roller, roller.origin);
        self.active_door = roller;
		roller.active_door = self;
    }  

    // Spawn the Flag
    if (self.spawnflags & PAP_SPAWNFLAG_USEFLAG) {
        precache_model(self.door_model_name);
        entity flag = spawn();
        setmodel(flag, self.door_model_name);
        makevectors(self.angles);
        flag.origin = self.origin;
        flag.origin += v_right * self.box3_y;
        flag.origin += v_forward * self.box3_x;
        flag.origin += v_up * self.box3_z;
        flag.angles = self.angles;
        setorigin(flag, flag.origin);
		flag.movetype = MOVETYPE_NOCLIP;
        self.boxweapon = flag;

        // Start down
		flag.angles_z = 180;
    }

	vector tempv;

    // Calculate the Spark offset if permitted
    if (!(self.spawnflags & PAP_SPAWNFLAG_NOSPARK)) {
        tempv = self.origin;
        makevectors(self.angles);
        tempv += v_right * self.box2_y;
        tempv += v_forward * self.box2_x;
        tempv += v_up * self.box2_z;
        self.box2 = tempv;
    }

	// Calculate the floating weapon offset
	tempv = self.origin;
	makevectors(self.angles);
	tempv += v_right * self.oldorigin_y;
	tempv += v_forward * self.oldorigin_x;
	tempv += v_up * self.oldorigin_z;
	self.oldorigin = tempv;

    self.classname = "perk_pap";
	self.touch = PAP_Touch;
    self.solid = SOLID_TRIGGER;
	setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, '-44 -44 -24', '44 44 64');

    self.think = PAP_Initalize;
    self.nextthink = time + 0.2;
};
