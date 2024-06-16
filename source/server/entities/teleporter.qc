/*
	server/entities/teleporter.qc

	all logic for teleporters of every form.

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

/* 
   ============
    Teleporter
   ============ 

	Teleporters have 3 different modes

	0: Default Patch 1.0.4 Mode
		- Interact with teleporter and go to pad (credit: Naievil and PerikiyoXD)

	1: Linked Mode
		- One-Time-Link teleporter with pad, teleport to pad

	2: Timed Mode
		- Link teleporter with pad, teleport to other destination
		  for a set amount of time, then return to pad. Link every time.
   
   TODO:
		- Sounds
		- Keep track of whether player is touching instead of locking movement
*/

void(vector where, float time_alive) SpawnSpark;

void() teleporter_cooldown =
{
	self.activated = false;

	if (self.mode == 2) {
		self.isLinked = false;
	}

	self.cooldown = false;
}

void() start_cooldown =
{
	self.cooldown = true;
	self.think = teleporter_cooldown;
	self.nextthink = time + 5;
}

void() teleport_entities_back =
{
    entity en, player; 
	en = find(world, targetname, self.target2);

    SUB_UseTargets();
    self.iszomb = 0;

	sound(self.entities[0], CHAN_WEAPON, "sounds/machines/elec_shock.wav", 1, ATTN_NORM);

    for(float i = 0; i < 4; i++) {
        if (self.entities[i].classname == "player") {
            player = self.entities[i];

            setorigin(player, en.origin);

            if (self.isTimed || en.classname == "func_teleporter_pad") {
                setorigin(player, player.origin + '0 0 40');
            }

            switch(self.iszomb) {
                case 0:
                    player.origin += '20 0 0';
                    break;
                case 1:
                    player.origin -= '20 0 0';
                    break;
                case 2:
                    player.origin += '0 20 0';
                    break;
                case 3:
                    player.origin -= '0 20 0';
                    break;
                default:
                    break;
            }

            player.fire_delay = player.fire_delay2 = 
            player.reload_delay = player.reload_delay2 =
            2.0 + time;
			player.speed_penalty = 0.75;
			player.speed_penalty_time = time + 2;

            player.zoom = 0;
            player.movetype = MOVETYPE_WALK;
			player.oldz = player.origin_z;
			player.flags = player.flags & FL_ONGROUND;
			player.velocity = '0 0 0';

            if (self.mode == 0)
                self.activated = false;
            
            self.iszomb++;
        }
    }

	SpawnSpark(en.origin + '0 0 32', 1);

    self.iszomb = 0;
    start_cooldown();
    self.isTimed = false;
}

void(entity who) teleport_entity =
{
    entity en; 
	en = find(world, targetname, self.target2);
  
  
    SUB_UseTargets ();
        
    setorigin (who, who.tele_target.origin);

	if (self.isTimed || en.classname == "func_teleporter_pad") {
		setorigin(who, who.origin + '0 0 40');
	}

	// Prohibit taking fall damage
	who.oldz = who.origin_z;

    switch(self.iszomb) {
        case 0:
            who.origin += '20 0 0';
            break;
        case 1:
            who.origin -= '20 0 0';
            break;
        case 2:
            who.origin += '0 20 0';
            break;
        case 3:
            who.origin -= '0 20 0';
            break;
        default:
            bprint(PRINT_HIGH, "cheater!!\n");
            break;
    }

    who.fire_delay = who.fire_delay2 = who.reload_delay = who.reload_delay2 = 2.0 + time;
	who.speed_penalty = 0.75;
	who.speed_penalty_time = time + 2;
    who.zoom = 0;
	who.movetype = MOVETYPE_WALK;
    who.flags = who.flags & FL_ONGROUND;
	who.velocity = '0 0 0';
}

void() teleport_entities =
{
    // Store all of the players
    entity people = findradius(self.origin, self.stance);
    float i = 0;

    self.entities[0] = world;
    self.entities[1] = world;
    self.entities[2] = world;
    self.entities[3] = world;

    while(people != world) {
        if (people.classname == "player") {
            self.entities[i] = people;
            i++;
            teleport_entity(people);
            self.iszomb++;
        }
        people = people.chain;
    }
    self.iszomb = 0;

    if (self.mode == 0) {
		self.activated = false;
	} else if (self.mode == 2 && !self.isTimed) {
		self.nextthink = time + self.tpTimer;
		self.think = teleport_entities_back;
		self.isTimed = true;
	} else {
		start_cooldown();
		self.isTimed = false;
	}
}

void() teleport_pad_touch =
{
	if (other.classname != "player" || self.host.isLinked)
		return;

	if (!isPowerOn) {
     	useprint(other, 8, 0, 0);
    	return;
    } 

	if (self.host.waitLink) {
		useprint(other, 19, 0, 0);

		if (other.button7) {
			self.host.isLinked = true;
			self.host.waitLink = false;
			sound(self, CHAN_WEAPON, "sounds/weapons/tesla/switchon.wav", 1, ATTN_NORM);
		}
	} else {
		if (self.host.mode == 2) {
			useprint(other, 18, 0, 0);
		}
	}
}

void() teleporter_link_touch =
{

	if (!self.waitLink)
		useprint(other, 17, 0, 0);

	if (other.button7) {
		local entity en;

		en = find(world, targetname, self.target2);
		sound(self, CHAN_WEAPON, "sounds/weapons/tesla/switchoff.wav", 1, ATTN_NORM);
		self.waitLink = true;
		en.host = self;
	}
}

void() teleport_touch =
{
	entity tempe;

	if (self.cooldown) {
		useprint(other, 16, 0, 0);
		return;
	}

  	if (other.classname != "player" || self.activated)
		return;
  
  	if (!isPowerOn) {
     	useprint(other, 8, 0, 0);
    	return;
    } 

	if (self.mode != 0 && !self.isLinked) {
		teleporter_link_touch();
		return;
	}
    
	if (!self.cost)
  		useprint(other, 14, 0, 0);
	else
		useprint(other, 15, self.cost, 0);
	

	if (other.button7 && !(other.semi_actions & SEMIACTION_USE)) {
		other.semi_actions |= SEMIACTION_USE;
		
		if (other.points < self.cost) {
			centerprint(other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			return;
		}

		Player_RemoveScore(other, self.cost);

		SUB_UseTargets();

		self.activated = true;

        entity people = findradius(self.origin, self.stance);
        while (people != world) {
            if (people.classname == "player") {
                people.tele_target = find(world, targetname, self.target);
                people.movetype = MOVETYPE_NONE;
            }
			else if (people.classname == "ai_dog" && !people.electro_targeted) {
				sound(self, CHAN_WEAPON, "sounds/machines/elec_shock.wav", 1, ATTN_NORM);

				tempe = self;
				self = people;
				self.electro_targeted = true;
				self.th_die();
				self = tempe;
			}
			else if (people.aistatus == "1" && !people.electro_targeted) 
			{
				tempe = self;
				self = people;
				Z_ElectroShock();
				self = tempe;	
			}
			people = people.chain;
        }

        if (!other.tele_target)
			objerror("Couldn't find target!");

		self.think = teleport_entities;
		self.nextthink = time + 1;
		SpawnSpark(self.origin + '0 0 32', 1.5);
		sound(self, CHAN_WEAPON, "sounds/machines/elec_shock.wav", 1, ATTN_NORM);
	}

	if (other.button1) {
    	if (self.targetname) {
      		if (self.nextthink < time)
        		return;		// not fired yet
      	}
    }
}

void() teleport_use =
{
	self.nextthink = time + 2;
	force_retouch = 2;		// make sure even still objects get hit
	self.think = SUB_Null;
}

//
// func_teleporter_entrance()
// Spawn function for the main teleporter.
//
void() func_teleporter_entrance =
{		
    //
	// Set Default Stats for Compatibility
	//
    
    // Model
    if (!self.model) {
        self.model = "models/props/teleporter.mdl";
    }

    // Radius
    if (!self.stance) {
        self.stance = 75;
    }

    precache_model(self.model);
	precache_model("models/sprites/lightning.spr");
	precache_sound("sounds/machines/elec_shock.wav");
	precache_sound("sounds/weapons/tesla/switchoff.wav");
	
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.classname = "func_teleporter_entrance";
  	setmodel(self, self.model);
  	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
    self.touch = teleport_touch;

    // Verify the User has teleporter targets set.
    if (!self.target)
		objerror("No target!");

	if (self.mode != 0) {
		if (!self.target2)
			objerror("No mainframe!");

		if (self.mode == 2) {
			entity tempe;
			tempe = find(world, targetname, self.target2);
			tempe.host = self;
		}
	}

    self.use = teleport_use;
}

//
// func_teleporter_destination()
// Empty Entity to use as a destination for standard
// teleporter modes.
//
void() func_teleporter_destination =
{
	// this does nothing, just serves as a target spot
	self.origin = self.origin + '0 0 40';
	self.classname = "func_teleporter_destination";
}

//
// func_teleporter_timed()
// Empty Entity to use as a destination for time-based
// teleporter modes.
//
void() func_teleporter_timed =
{
	self.origin = self.origin + '0 0 40';
	self.classname = "func_teleporter_timed";
}

//
// func_teleporter_pad()
// Teleporter Pad that's often used as a Link Point
// or Return Point.
//
void() func_teleporter_pad =
{
	precache_model ("models/props/mainframe_pad.mdl");
	precache_sound("sounds/weapons/tesla/switchon.wav");
	
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.classname = "func_teleporter_pad";
  	setmodel(self, "models/props/mainframe_pad.mdl");
  	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
    self.touch = teleport_pad_touch;
}
