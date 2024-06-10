/*
	server/entities/map_entities.qc

	logic and entities pertaining to in-game traps

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

#define TRAP_SPAWNFLAG_REQUIRESPOWER	1

//
// --------------------
// Electric Trap
// --------------------
//

#define ELECTRICTRAP_MODE_TIMER         0       // Der Riese style; trap cools down after X seconds.
#define ELECTRICTRAP_MODE_ROUND         1       // SNN/Verruckt style; trap cools down at end of Round.

//
// Electric Switch On Animation
//
void()  A_ElecSwitchOn1     =   [   1,   A_ElecSwitchOn2    ]   {self.frame = 0;};
void()  A_ElecSwitchOn2     =   [   2,   A_ElecSwitchOn3    ]   {self.frame = 1;};
void()  A_ElecSwitchOn3     =   [   3,   A_ElecSwitchOn4    ]   {self.frame = 2;};
void()  A_ElecSwitchOn4     =   [   4,   SUB_Null           ]   {self.frame = 2;};

//
// Electric Swich Off Animation
//
void()  A_ElecSwitchOff1    =   [   1,  A_ElecSwitchOff2    ]   {self.frame = 2;};
void()  A_ElecSwitchOff2    =   [   2,  A_ElecSwitchOff3    ]   {self.frame = 1;};
void()  A_ElecSwitchOff3    =   [   3,  SUB_Null            ]   {self.frame = 0;};

//
// zapper_do_damage
// Called when entities touch the Electric barrier.
//
void() zapper_do_damage
{
	entity tempe;

	// Player Logic:
	// - Trap instantly kills player on contact without Jugg,
	//   having Jugg/Toughness reduces damage to only 50.
	// - 1.25s delay before damage can be dealt again.
	// - Player is slowed down by 50% for 2.5 seconds. (Stop sprinting)
	if (other.classname == "player")
	{
		// Inflict Damage
		if (other.damage_timer < time) {
			if (other.perks & P_JUG)
				DamageHandler(other, self, 50, S_ZAPPER);
			else
				DamageHandler(other, self, other.health, S_ZAPPER);
			other.damage_timer = time + 1.25;
		}
		// Inflict Speed Penalty
		if (other.speed_penalty_time < time) {
			other.speed_penalty = 0.5;
			other.speed_penalty_time = time + 2.5;

			// Make sure we can't sprint
			if (other.sprinting) {
				tempe = self;
				self = other;
				W_SprintStop();
				self = tempe;
			}
		}
	}
	// Zombie Logic:
	// - Zombie can take up to 1.25 seconds to die after contact,
	// cannot damage in this state.
	// - Has a chance to gib.
	// - No normal death sound, play elec sound on contact, then
	// again on death.
	// - Zombies do not drop Power-Ups when killed via traps.
	if (other.classname == "ai_zombie_head" || other.classname == "ai_zombie_rarm"
	|| other.classname == "ai_zombie_larm") {
		// If we're a limb, grab our body.
		other = other.owner;
	}
	if (other.classname == "ai_zombie" && !other.electro_targeted) {
		tempe = self;
		self = other;
		Z_ElectroShock();
		self = tempe;	
	}
	// Dog Logic:
	// - Dogs should always explode on contact, instantly.
	// - Trap plays Electro-Shock sound, dog plays explosion.
	else if (other.classname == "ai_dog") {
		sound(self, CHAN_WEAPON, "sounds/machines/elec_shock.wav", 1, ATTN_NORM);

		tempe = self;
		self = other;
		self.electro_targeted = true;
		self.th_die();
		self = tempe;
	}
}


void zapper_play () {
	entity zents = find(world, targetname, self.target);
	local vector org = self.origin;
	local vector targetorg = zents.origin;

	if (zents) {

#ifdef FTE

		te_lightning1(self, self.origin, zents.origin);

#else

		WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
		WriteByte (MSG_BROADCAST, TE_LIGHTNING1);
		WriteEntity (MSG_BROADCAST, self);
		WriteCoord (MSG_BROADCAST, org_x);
		WriteCoord (MSG_BROADCAST, org_y);
		WriteCoord (MSG_BROADCAST, org_z);
		WriteCoord (MSG_BROADCAST, targetorg_x);
		WriteCoord (MSG_BROADCAST, targetorg_y);
		WriteCoord (MSG_BROADCAST, targetorg_z);

#endif // FTE

	}

	zents.touch = zapper_do_damage;
	
	self.think = zapper_play;
	self.nextthink = time + (0.5*random());
}

void() zapper_touch;
void() zapper_cooldown =
{
	A_ElecSwitchOff1();
	self.touch = zapper_touch;
}

void zapper_stop() {
	entity zents;
	entity tempe;

	zents = find(world, zappername, self.zappername);
	while (zents)
	{
		if (zents.classname == "zapper_light") {
			zents.skin = 0;
		} else if (zents.classname == "zapper_switch") {
			tempe = self;
			self = zents;
			self.state = 0;

            if (self.mode == ELECTRICTRAP_MODE_TIMER) {
                self.think = zapper_cooldown;
                self.nextthink = time + self.cooldown;
            }

			self = tempe;
		} else if (zents.classname == "zapper_node" && zents.target) {
			zents.think = SUB_Null;
			entity zent_target = find(world, targetname, self.target);
			if (zent_target != world)
				zent_target.touch = SUB_Null;
			zents.nextthink = 0;
		}
		zents.touch = SUB_Null;
		zents = find(zents, zappername, self.zappername);
	}

	remove(self);
}

void zapper_start(string zapper) {
	entity zents;
	entity tempe;

	float lasting_time = 0;

	zents = find(world, zappername, zapper);
	while (zents)
	{
		if (zents.classname == "zapper_light") {
			zents.skin = 1;
		} else if (zents.classname == "zapper_switch") {
			tempe = self;
			self = zents;
			self.state = 1;
			lasting_time = self.calc_time;
			A_ElecSwitchOn1();
			self = tempe;
		} else if (zents.classname == "zapper_node" && zents.target) {
			zents.think = zapper_play;
			zents.nextthink = time + 0.65;
		}
		zents = find(zents, zappername, zapper);
	}

	tempe = spawn();
	tempe.think = zapper_stop;
	tempe.nextthink = time + lasting_time;
	tempe.zappername = zapper;
}

void zapper_touch () {
	if (other.classname != "player") {
		return;
	}

	if (self.requirespower == true && !isPowerOn) {
		useprint (other, 8, 0, 0);
		return;
	}	

	if (self.state == 0) {
		useprint (other, 11, self.cost, self.weapon);

		if (!other.button7 || (other.semi_actions & SEMIACTION_USE)) {
			return;
		}

		other.semi_actions |= SEMIACTION_USE;
		if (other.points < self.cost) {
			centerprint(other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			return;
		}

		zapper_start(self.zappername);
		Player_RemoveScore(other, self.cost);
	}
}

void() zapper_switch = 
{
    //
	// Set Default Stats for Compatibility
	//

    // Model
    if (!self.model)
        self.model = "models/machines/quake_scale/zapper/z_switch.mdl";

    // Cost
    if (!self.cost)
        self.cost = 1000;

    // Cooldown Time
    if (!self.cooldown)
        self.cooldown = 30;

    // Lasting Time
    if (!self.calc_time)
        self.calc_time = 60;

	// Requires Power
	if (self.spawnflags & TRAP_SPAWNFLAG_REQUIRESPOWER)
		self.requirespower = true;

    self.solid = SOLID_TRIGGER;
	precache_model(self.model);
	precache_sound("sounds/machines/elec_shock.wav");
    setorigin(self, self.origin);
    setmodel(self, self.model);
	setsize(self, '-4 -4 -4', '4 4 4');
    self.state = 0;
	self.touch = zapper_touch;
	self.movetype = MOVETYPE_NONE;
	self.classname = "zapper_switch";
};

void() set_zapper_bbox =
{
	vector bbmin, bbmax;
	// Retrieve the distance between this zapper and the one
	// it's linked to.
	entity other_zapper = find(world, targetname, self.target);
	float distance = abs(vlen(other_zapper.origin - self.origin));

	// Point upward by default
	bbmin = '-20 -20 -4';
	bbmax_x = 20;
	bbmax_y = 20;
	bbmax_z = distance/2;

	// X Axis
	if (self.angles_x) {
		switch(self.angles_x) {
			// Pointed 'Upward'
			case 0:
				bbmin = '-20 -20 -4';
				bbmax_x = 20;
				bbmax_y = 20;
				bbmax_z = distance/2;
				break;
			// Pointed 'Leftward'
			case 90:
				bbmin_x = -distance/2;
				bbmin_y = -20;
				bbmin_z = -20;
				bbmax = '4 20 20';
				break;
			// Pointed 'Downward'
			case 180:
				bbmin_x = -20;
				bbmin_y = -20;
				bbmin_z = -distance/2;
				bbmax = '20 20 4';
				break;
			// Pointed 'Rightward'
			case 270:
				bbmin = '-4 20 20';
				bbmax_x = distance/2;
				bbmax_y = 20;
				bbmax_z = 20;
				break;
			default: 
				bprint(PRINT_HIGH, "WARN: Invalid X axis rotation for zapper_node.\n");
				bprint(PRINT_HIGH, "      Collision box is going to be incorrect.\n");
				break;
		}
	} else if (self.angles_z) {
		// Z Axis
		switch(abs(self.angles_z)) {
			// Pointed 'Upward'
			case 0:
				bbmin = '-20 -20 -4';
				bbmax_x = 20;
				bbmax_y = 20;
				bbmax_z = distance/2;
				break;
			// Pointed 'Leftward'
			case 90:
				bbmin_x = -20;
				bbmin_y = -distance/2;
				bbmin_x = -20;
				bbmax = '20 4 20';
				break;
			// Pointed 'Downward'
			case 180:
				bbmin_x = -20;
				bbmin_y = -20;
				bbmin_z = -distance/2;
				bbmax = '20 20 4';
				break;
			// Pointed 'Rightward'
			case 270:
				bbmin = '-20 -4 -20';
				bbmax_x = 20;
				bbmax_y = distance/2;
				bbmax_x = 20;
				break;
			default: 
				bprint(PRINT_HIGH, "WARN: Invalid Z axis rotation for zapper_node.\n");
				bprint(PRINT_HIGH, "      Collision box is going to be incorrect.\n");
				break;
		}
	}

	if (self.angles_y) {
		bprint(PRINT_HIGH, "WARN: zapper_node object with Y axis rotation.\n");
		bprint(PRINT_HIGH, "      Use r_showbboxes to verify zap collision.\n");
	}

	setsize(self, bbmin, bbmax);
}

void() zapper_node = 
{
    //
	// Set Default Stats for Compatibility
	//

    // Model
    if (!self.model)
        self.model = "models/machines/quake_scale/zapper/z_zap.mdl";

    self.solid = SOLID_TRIGGER;
	precache_model(self.model);
    setorigin(self, self.origin);
    setmodel(self, self.model);
	makevectors(self.angles);
	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
    
	self.movetype = MOVETYPE_NONE;
	self.think = set_zapper_bbox;
	self.nextthink = time + 2;
	self.classname = "zapper_node";
};

void() zapper_light = 
{
    //
    // Set Default Stats for Compatibility
    //

    // Model
    if (!self.model)
        self.model = "models/machines/quake_scale/zapper/z_light.mdl";

    self.solid = SOLID_TRIGGER;
	precache_model(self.model);
    setorigin(self, self.origin);
	setmodel(self, self.model);
	setsize(self, '-4 -4 -4', '4 4 4');
    self.movetype = MOVETYPE_NONE;
	self.classname = "zapper_light";
};

void() trigger_electro =
{
	self.classname = "zapper_field";
	InitTrigger ();
	self.solid = SOLID_TRIGGER;
};
