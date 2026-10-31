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
	
	if (self.target2 != "")
		tempcount =+ 1;
	if (self.target3 != "")
		tempcount =+ 1;
	if (self.target4 != "")
		tempcount =+ 1;
	if (self.target5 != "")
		tempcount =+ 1;
	if (self.target6 != "")
		tempcount =+ 1;
	if (self.target7 != "")
		tempcount =+ 1;
	if (self.target8 != "")
		tempcount =+ 1;
	if (self.target2 != "")
		tempcount = tempcount + 1;
	if (self.target3 != "")
		tempcount = tempcount + 1;
	if (self.target4 != "")
		tempcount = tempcount + 1;
	if (self.target5 != "")
		tempcount = tempcount + 1;
	if (self.target6 != "")
		tempcount = tempcount + 1;
	if (self.target7 != "")
		tempcount = tempcount + 1;
	if (self.target8 != "")
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
		if (tempstring != "")
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

#define SPAWNFLAG_TRIGGERINTERACT_STARTINACTIVE	1

void() trigger_interact_touch =
{
	if (other.classname != "player" || other.downed || other.isBuying == true || !PlayerIsLooking(other, self))
		return;

	float interaction_cost = floor(self.cost * game_modifiers.gameplay.global.all_items_cost_multiplier);
	if (self.useprint_index_1) {
		Player_UseprintWithWait(other, self, self.useprint_index_1, interaction_cost);
	}

	if (Player_UseButtonPressed(other, self)) {
		if (interaction_cost > 0 && other.points < interaction_cost) {
			if (!(other.semi_actions & SEMIACTION_USE)) {
				other.semi_actions |= SEMIACTION_USE;
				centerprint(other, STR_NOTENOUGHPOINTS);
				Sound_PlaySound(other, "sounds/misc/denybuy.wav", SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);
			}
			return;
		}

		if (interaction_cost > 0)
			Player_RemoveScore(other, interaction_cost);

		if (self.noise != "")
			Sound_PlaySound(other, self.noise, SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);

		self.enemy = other;
		activator = other;
		SUB_UseTargets();

		// Keep the brush linked, but require another entity to fire us before
		// accepting another player interaction.
		self.touch = SUB_Null;
	}
}

void() trigger_interact_activate =
{
	self.touch = trigger_interact_touch;
}

void() trigger_interact =
{
	if (self.useprint_string_1 != "")
		self.useprint_index_1 = Useprint_Register(self.useprint_string_1, self.useprint_color_1);

	if (self.noise != "") {
		precache_sound(self.noise);
	}
	
	InitTrigger();
	self.use = trigger_interact_activate;

	if (!(self.spawnflags & SPAWNFLAG_TRIGGERINTERACT_STARTINACTIVE)) {
		self.touch = trigger_interact_touch;
	}
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
	} else if (self.target != "") {
		SUB_UseTargets();
	}

    entity dummy = spawn();
    setorigin(dummy, self.origin);
    dummy.think = SUB_Remove;
    dummy.nextthink = time + 10;


	if (self.noise != "")
    	Sound_PlaySound(dummy, self.noise, SOUND_TYPE_ENV_OBJECT, SOUND_PRIORITY_PLAYALWAYS);

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

#define SPAWNFLAG_EACHPLAYER_STARTOFF	1

.entity eachplayer_contacts;

//
// EachPlayer_ClearContacts(trigger, client)
// Removes cooldown records for one player, or every player when client is world.
// Contact records use owner for the player, enemy for the next record, and
// ltime for the next allowed activation.
//
void(entity trigger, entity client) EachPlayer_ClearContacts =
{
	entity previous = world;
	entity contact = trigger.eachplayer_contacts;
	while (contact != world) {
		entity next = contact.enemy;
		if (client == world || contact.owner == client) {
			if (previous == world)
				trigger.eachplayer_contacts = next;
			else
				previous.enemy = next;
			remove(contact);
		} else {
			previous = contact;
		}
		contact = next;
	}
};

void() eachplayer_touch =
{
	if (self.entity_removed || self.touch != eachplayer_touch || !Player_CanUseMapControls(other))
		return;

	if (self.movedir != '0 0 0') {
		makevectors(other.angles);
		if (v_forward * self.movedir < 0)
			return;
	}

	entity contact = self.eachplayer_contacts;
	while (contact != world && contact.owner != other)
		contact = contact.enemy;
	if (contact != world) {
		if (self.wait < 0 || contact.ltime > time)
			return;
	} else {
		contact = spawn();
		contact.classname = "eachplayer_contact";
		contact.owner = other;
		contact.enemy = self.eachplayer_contacts;
		self.eachplayer_contacts = contact;
	}

	// Commit before dispatch: targets may re-enter, disable or remove us.
	contact.ltime = time + self.wait;
	entity old_activator = activator;
	activator = other;
	SUB_UseTargets();
	activator = old_activator;
};

void() eachplayer_use =
{
	if (self.entity_removed)
		return;
	float enabled = self.touch == eachplayer_touch;
	if (global_triggerstate == TRIGGERSTATE_ON)
		enabled = true;
	else if (global_triggerstate == TRIGGERSTATE_OFF)
		enabled = false;
	else
		enabled = !enabled;

	if (enabled == (self.touch == eachplayer_touch))
		return;
	EachPlayer_ClearContacts(self, world);
	self.touch = SUB_Null;
	if (enabled) {
		self.touch = eachplayer_touch;
		// Include stationary occupants on the next physics frame.
		force_retouch = 2;
	}
};

//
// trigger_eachplayer()
// Repeatable player trigger with independent cooldowns. A negative wait fires
// once per player until the trigger is disabled and enabled again.
//
void() trigger_eachplayer =
{
	EachPlayer_ClearContacts(self, world);
	if (!self.wait)
		self.wait = 0.2;
	InitTrigger();
	self.use = eachplayer_use;
	self.touch = eachplayer_touch;
	if (self.spawnflags & SPAWNFLAG_EACHPLAYER_STARTOFF)
		self.touch = SUB_Null;
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

	if (game_modifiers.gameplay.player.can_earn_score_from_sources_other_than_ai == true)
		Player_AddScore(other, self.points, (self.spawnflags & SPAWNFLAG_TRIGGERSCORE_APPLY2XPOINTS));

	if (self.noise != "")
		Sound_PlaySound(self, self.noise, SOUND_TYPE_ENV_CHING, SOUND_PRIORITY_PLAYALWAYS);

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

#define PUSH_SPAWNFLAG_ONCE			1
#define PUSH_SPAWNFLAG_PLAYER			2
#define PUSH_SPAWNFLAG_NONPLAYER		4
#define PUSH_SPAWNFLAG_STARTOFF		8

.entity push_contacts;
.entity push_contact_next;

void() push_touch;
void() push_contact_think;

float(entity ent) push_affects =
{
	if (ent.entity_removed || ent.solid == SOLID_NOT || ent.solid == SOLID_BSP)
		return false;

	if (ent.movetype == MOVETYPE_NONE || ent.movetype == MOVETYPE_PUSH ||
		ent.movetype == MOVETYPE_NOCLIP || ent.movetype == MOVETYPE_FOLLOW)
		return false;

	if (ent.classname == "player")
		return (self.spawnflags & PUSH_SPAWNFLAG_PLAYER) != 0;

	return (self.spawnflags & PUSH_SPAWNFLAG_NONPLAYER) != 0;
};

float(entity ent) push_contains =
{
	vector lower = self.origin + self.mins;
	vector upper = self.origin + self.maxs;
	vector ent_lower = ent.origin + ent.mins;
	vector ent_upper = ent.origin + ent.maxs;
	return ent_lower_x < upper_x && ent_upper_x > lower_x &&
		ent_lower_y < upper_y && ent_upper_y > lower_y &&
		ent_lower_z < upper_z && ent_upper_z > lower_z;
};

void(entity contact) push_contact_remove =
{
	entity ent = contact.enemy;
	entity previous = world;
	entity current = ent.push_contacts;
	while (current != world) {
		if (current == contact) {
			if (previous == world)
				ent.push_contacts = current.push_contact_next;
			else
				previous.push_contact_next = current.push_contact_next;
			break;
		}
		previous = current;
		current = current.push_contact_next;
	}
	remove(contact);
};

void() Player_ApplyPushVelocity =
{
	entity player = self;
	entity contact = player.push_contacts;
	while (contact != world) {
		entity next = contact.push_contact_next;
		self = contact.owner;
		if (!self.entity_removed && self.touch == push_touch &&
			!(self.spawnflags & PUSH_SPAWNFLAG_ONCE) && push_affects(player) && push_contains(player))
			player.velocity *= self.velocity_retention / 100;
		contact = next;
	}
	self = player;
};

void() push_touch =
{
	if (self.entity_removed || self.touch != push_touch || !push_affects(other))
		return;

	if (self.spawnflags & PUSH_SPAWNFLAG_ONCE) {
		other.velocity = other.velocity * (self.velocity_retention / 100) + self.movedir * self.speed;
		if (other.velocity_z > 0)
			other.flags &= ~FL_ONGROUND;
		Ent_FakeRemove(self);
		return;
	}

	entity contact = other.push_contacts;
	while (contact != world) {
		if (contact.owner == self)
			return;
		contact = contact.push_contact_next;
	}
	contact = spawn();
	contact.classname = "push_contact";
	contact.owner = self;
	contact.enemy = other;
	contact.push_contact_next = other.push_contacts;
	other.push_contacts = contact;
	contact.think = push_contact_think;
	contact.nextthink = time + 0.001;
};

void(entity ent, vector displacement) push_move =
{
	vector start = ent.origin;
	vector remaining = displacement;
	vector first_normal = '0 0 0';

	for (int bump = 0; bump < 4; bump++) {
		tracebox(ent.origin, ent.mins, ent.maxs, ent.origin + remaining, false, ent);
		if (trace_allsolid || trace_startsolid)
			break;

		setorigin(ent, trace_endpos);
		if (trace_fraction == 1)
			break;

		remaining *= 1 - trace_fraction;
		vector normal = trace_plane_normal;
		remaining -= normal * (remaining * normal);

		// At a corner, slide along the intersection of both planes.
		if (bump > 0 && remaining * first_normal < 0) {
			vector crease;
			crease_x = first_normal_y * normal_z - first_normal_z * normal_y;
			crease_y = first_normal_z * normal_x - first_normal_x * normal_z;
			crease_z = first_normal_x * normal_y - first_normal_y * normal_x;
			crease = normalize(crease);
			remaining = crease * (remaining * crease);
		}
		if (remaining * displacement <= 0)
			break;
		first_normal = normal;
	}

	if (ent.origin != start) {
		if (ent.origin_z > start_z) {
			ent.flags &= ~FL_ONGROUND;
		} else if (ent.flags & FL_ONGROUND) {
			tracebox(ent.origin, ent.mins, ent.maxs, ent.origin - '0 0 2', false, ent);
			if (trace_fraction == 1 || trace_plane_normal_z < 0.7)
				ent.flags &= ~FL_ONGROUND;
		}
	}
};

void() push_contact_think =
{
	entity contact = self;
	entity ent = contact.enemy;
	self = contact.owner;
	if (self.entity_removed || self.touch != push_touch || (self.spawnflags & PUSH_SPAWNFLAG_ONCE) ||
		!push_affects(ent) || !push_contains(ent)) {
		push_contact_remove(contact);
		self = contact;
		return;
	}

	if (ent.classname != "player")
		ent.velocity *= self.velocity_retention / 100;
	vector displacement = self.movedir * self.speed * frametime;
	if (displacement != '0 0 0')
		push_move(ent, displacement);
	contact.nextthink = time + 0.001;
	self = contact;
};

void() push_use =
{
	float enabled = self.touch == push_touch;
	if (global_triggerstate == TRIGGERSTATE_OFF ||
		(global_triggerstate == TRIGGERSTATE_TOGGLE && self.touch == push_touch)) {
		self.touch = SUB_Null;
		self.nextthink = -1;
	} else {
		self.touch = push_touch;
		if (!enabled && !(self.spawnflags & PUSH_SPAWNFLAG_ONCE))
			force_retouch = 2;
	}
};

void() trigger_push =
{
	SetMovedir();
	InitTrigger();
	if (!self.speed)
		self.speed = 100;
	if (!self.velocity_retention)
		self.velocity_retention = 100;
	self.velocity_retention = clamp(self.velocity_retention, 0, 100);
	self.touch = push_touch;
	self.use = push_use;
	self.think = SUB_Null;
	self.nextthink = -1;
	if (self.spawnflags & PUSH_SPAWNFLAG_STARTOFF)
		self.touch = SUB_Null;
	else if (!(self.spawnflags & PUSH_SPAWNFLAG_ONCE))
		force_retouch = 2;
};

// NZ:P START -- Spawnflags for not hurting clients and not hurting AI
#define HURT_SPAWNFLAG_NOAI			1		// Does not affect AI
#define HURT_SPAWNFLAG_NOCLIENT		2		// Does not affect clients (players)
#define HURT_SPAWNFLAG_DIEINSTANTLY	4		// Player will instantly die and spectate, regardless of other conditions
#define HURT_SPAWNFLAG_STARTOFF		8		// Starts disabled until triggered
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
		if ((self.spawnflags & HURT_SPAWNFLAG_DIEINSTANTLY) && other.classname == "player") {
			LastStand_Begin(other);
			LastStand_KillPlayer(other);
		} else {
			self.solid = SOLID_NOT;
			DamageHandler(other, self, self.dmg, DMG_TYPE_OTHER);
			self.think = hurt_on;
			self.nextthink = time + 1;
		}

		if (self.message != "")
			centerprint(other, strcat(self.message, "\n"));
	}

	return;
};

void() hurt_use =
{
	if (global_triggerstate == TRIGGERSTATE_OFF)
		self.touch = SUB_Null;
	else if (global_triggerstate == TRIGGERSTATE_ON)
		self.touch = hurt_touch;
	else if (self.touch == hurt_touch)
		self.touch = SUB_Null;
	else
		self.touch = hurt_touch;
};

void() trigger_hurt =
{
	InitTrigger ();
	self.touch = hurt_touch;
	self.use = hurt_use;
	if (self.spawnflags & HURT_SPAWNFLAG_STARTOFF)
		self.touch = SUB_Null;
	if (!self.dmg)
		self.dmg = 5;
};
