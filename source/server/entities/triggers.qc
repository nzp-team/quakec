/*
	server/entities/triggers.qc

	Misc. Trigger functions

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

#define SPAWNFLAG_NOMESSAGE 	1
#define SPAWNFLAG_NOTOUCH 		1

void() Zombie_ReassignSpawnIDs;

// the wait time has passed, so set back up for another activation
void() multi_wait =
{
	if (self.max_health)
	{
		self.health = self.max_health;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
	}
};


// the trigger was just touched/killed/used
// self.enemy should be set to the activator so it can be held through a delay
// so wait for the delay time before firing
void() multi_trigger =
{
	if (self.nextthink > time)
	{
		return;		// already been triggered
	}

// don't trigger again until reset
	self.takedamage = DAMAGE_NO;

	activator = self.enemy;

	SUB_UseTargets();

	if (self.wait > 0)	
	{
		self.think = multi_wait;
		self.nextthink = time + self.wait;
	}
	else
	{	
		Ent_FakeRemove(self);
	}
};

void() multi_killed =
{
	// motolegacy - FIXME
	//self.enemy = damage_attacker;
	multi_trigger();
};

void() multi_use =
{
	self.enemy = activator;
	multi_trigger();
};

void() multi_touch =
{
	if (other.classname != "player")
		return;

	// if the trigger has an angles field, check player's facing direction
	if (self.movedir != '0 0 0')
	{
		makevectors (other.angles);
		if (v_forward * self.movedir < 0)
			return;		// not facing the right way
	}
	
	self.enemy = other;
	multi_trigger();
};

void() SetMovedir =
{
	if (self.angles == '0 -1 0')
		self.movedir = '0 0 1';
	else if (self.angles == '0 -2 0')
		self.movedir = '0 0 -1';
	else
	{
		makevectors (self.angles);
		self.movedir = v_forward;
	}
	
	self.angles = '0 0 0';
};

void() InitTrigger =
{
// trigger angles are used for one-way touches.  An angle of 0 is assumed
// to mean no restrictions, so use a yaw of 360 instead.
	if (self.angles != '0 0 0')
		SetMovedir ();
	self.solid = SOLID_TRIGGER;
	setmodel (self, self.model);	// set size and link into world
	self.movetype = MOVETYPE_NONE;
	self.modelindex = 0;
	self.model = "";
};

entity last_act_trigger;
void() trigger_activator_touch =
{
	other.cost = other.cost +1; //hack, we can only touch one of thease at the time
	if (other.classname != "player" || last_act_trigger == self || other.cost > 1)
		return;
	last_act_trigger = self;

	entity t;
	float tempcount, temptotal,breakthis;
	string tempstring;
	temptotal = 0;
	breakthis = 0;
	tempcount = 1;
	tempstring = "";
	t = world;
	
	if (self.target2)
		tempcount =+ 1;
	if (self.target3)
		tempcount =+ 1;
	if (self.target4)
		tempcount =+ 1;
	if (self.target5)
		tempcount =+ 1;
	if (self.target6)
		tempcount =+ 1;
	if (self.target7)
		tempcount =+ 1;
	if (self.target8)
		tempcount =+ 1;
	if (self.target2)
		tempcount = tempcount + 1;
	if (self.target3)
		tempcount = tempcount + 1;
	if (self.target4)
		tempcount = tempcount + 1;
	if (self.target5)
		tempcount = tempcount + 1;
	if (self.target6)
		tempcount = tempcount + 1;
	if (self.target7)
		tempcount = tempcount + 1;
	if (self.target8)
		tempcount = tempcount + 1;

	while(tempcount > temptotal)
	{
		temptotal = temptotal + 1;
		if (temptotal == 1)
			tempstring = self.target;
		if (temptotal == 2)
			tempstring = self.target2;
		if (temptotal == 3)
			tempstring = self.target3;
		if (temptotal == 4)
			tempstring = self.target4;
		if (temptotal == 5)
			tempstring = self.target5;
		if (temptotal == 6)
			tempstring = self.target6;
		if (temptotal == 7)
			tempstring = self.target7;
		if (temptotal == 8)
			tempstring = self.target8;
		if (tempstring)
		{
			t = find (world, targetname, tempstring);
			breakthis = 0;
			while (!breakthis)
			{
				if (!t)
				{
					breakthis = true;
				}
				if (t.classname == "spawn_zombie_away")
				{
					t.classname = "spawn_zombie";
					t.spawn_id = zombie_spawn_points;
					zombie_spawn_points++;
					/*if (cvar("developer"))
						setmodel(t, "progs/ai/zfull.mdl");*/
				}
				t = find (t, targetname, tempstring);
			} 
		}
	}
	Zombie_ReassignSpawnIDs();
}

void() trigger_activator =
{
	InitTrigger ();
	self.touch = trigger_activator_touch;
}

void() trigger_interact_touch =
{
	if (other.classname != "player" || other.downed || other.isBuying == true || !PlayerIsLooking(other, self))
		return;

	if (other.button7) {
		if (self.noise)
			sound (other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
		multi_trigger();
	}
}

void() trigger_interact =
{
	InitTrigger();
	self.touch = trigger_interact_touch;
}

/* ===================
   Custom Teddy Triggers
   ===================*/

void() teddy_react =
{
  	local entity t;
	if (self.spawnflags & 1) {
		t = find (world, teddyremovetarget, self.target);
    
		if (t)
			Ent_FakeRemove(t);
	} else if (self.target) {
		SUB_UseTargets();
	}

    entity dummy = spawn();
    setorigin(dummy, self.origin);
    dummy.think = SUB_Remove;
    dummy.nextthink = time + 10;


	if (self.noise)
    	sound (dummy, CHAN_ITEM, self.noise, 1, ATTN_NORM);

	Ent_FakeRemove(self);
}

/*
	Variable sized repeatable trigger.  Must be targeted at one or more entities.  If "health" is set, the trigger must be killed to activate each time.
	If "delay" is set, the trigger waits some time after activating before firing.
	"wait" : Seconds between triggerings. (.2 default)
	If notouch is set, the trigger is only fired by other entities, not by touching.
	NOTOUCH has been obsoleted by trigger_relay!
	set "message" to text string
*/
void() trigger_multiple =
{	
	if (!self.wait)
		self.wait = 0.2;

	self.use = multi_use;

	InitTrigger ();

	if(self.health)
	{
		if (self.spawnflags & SPAWNFLAG_NOTOUCH)
			objerror("health and notouch don't make sense\n");
		self.max_health = self.health;
		self.th_die = multi_killed;
		self.takedamage = DAMAGE_YES;
		self.solid = SOLID_BBOX;
		setorigin(self, self.origin);	// make sure it links into the world
	}
	else
	{
		if (!(self.spawnflags & SPAWNFLAG_NOTOUCH))
		{
			self.touch = multi_touch;
		}
	}
};

/*
	Variable sized trigger. Triggers once, then removes itself.  You must set the key "target" to the name of another object in the level that has a matching
	"targetname".  If "health" is set, the trigger must be killed to activate.
	If notouch is set, the trigger is only fired by other entities, not by touching.
	if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
	if "angle" is set, the trigger will only fire when someone is facing the direction of the angle.  Use "360" for an angle of 0.
	set "message" to text string
*/
void() trigger_once =
{
	self.wait = -1;

	trigger_multiple();
}

/*QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
This fixed size trigger cannot be touched, it can only be fired by other events.  It can contain killtargets, targets, delays, and messages.
*/
void() trigger_relay =
{
	self.use = SUB_UseTargets;
};

void() trigger_atroundend =
{
	self.classname = "trigger_atroundend";
	//self.use = multi_use;
}

#define SPAWNFLAG_TRIGGERFIRE_PLAYER 		1
#define SPAWNFLAG_TRIGGERFIRE_NODAMAGE		2
#define SPAWNFLAG_TRIGGERFIRE_HEALTHNERF	4

void() trigger_setfire_touch =
{
	if (other.aistatus != "1" && (other.classname == "player" && !(self.spawnflags & SPAWNFLAG_TRIGGERFIRE_PLAYER)))
		return;

	other.onfire = true;
	other.fire_timeout = time + self.fire_timeout;

	if ((self.spawnflags & SPAWNFLAG_TRIGGERFIRE_NODAMAGE) && other.aistatus == "1")
		other.ltime = time + 10000;
}

void() trigger_setfire =
{
	InitTrigger ();
	self.touch = trigger_setfire_touch;
}

//
// trigger_awardpoints
// Awards touching client Score on contact.
//
#define SPAWNFLAG_TRIGGERSCORE_REQUIRESTAND		1
#define SPAWNFLAG_TRIGGERSCORE_REQUIRECROUCH	2
#define SPAWNFLAG_TRIGGERSCORE_REQUIREPRONE		4
#define SPAWNFLAG_TRIGGERSCORE_APPLY2XPOINTS	8

void() trigger_awardpoints_touch =
{
	if (other.classname != "player" || other.downed || !self.health)
		return;

	if (other.stance != PLAYER_STANCE_STAND && (self.spawnflags & SPAWNFLAG_TRIGGERSCORE_REQUIRESTAND))
		return;
	if (other.stance != PLAYER_STANCE_CROUCH && (self.spawnflags & SPAWNFLAG_TRIGGERSCORE_REQUIRECROUCH))
		return;
	if (other.stance != PLAYER_STANCE_PRONE && (self.spawnflags & SPAWNFLAG_TRIGGERSCORE_REQUIREPRONE))
		return;

	Player_AddScore(other, self.points, (self.spawnflags & SPAWNFLAG_TRIGGERSCORE_APPLY2XPOINTS));

	if (self.noise != "")
		sound(self, 0, self.noise, 1, 1);

	self.health = 0;
}

void() trigger_awardpoints =
{
	InitTrigger ();
	self.touch = trigger_awardpoints_touch;
	self.health = 1;

	if (self.noise != "")
		precache_sound(self.noise);
}

//
// Quake Triggers
//

// NZ:P START -- Spawnflags for not hurting clients and not hurting AI
#define HURT_SPAWNFLAG_NOAI		1
#define HURT_SPAWNFLAG_NOCLIENT	2
// NZ:P END

void() hurt_on =
{
	self.solid = SOLID_TRIGGER;
	self.nextthink = -1;
};

void() hurt_touch =
{
	if ((other.classname == "player" && !(self.spawnflags & HURT_SPAWNFLAG_NOCLIENT)) ||
	(other.aistatus == "1" && !(self.spawnflags & HURT_SPAWNFLAG_NOAI)))
	{
		self.solid = SOLID_NOT;
		DamageHandler(other, self, self.dmg, S_ZOMBIE);
		self.think = hurt_on;
		self.nextthink = time + 1;

		if (self.message)
			centerprint(other, strcat(self.message, "\n"));
	}

	return;
};

void() trigger_hurt =
{
	InitTrigger ();
	self.touch = hurt_touch;
	if (!self.dmg)
		self.dmg = 5;
};
