/*
	server/tests/test_trigger_push.qc

	Unit tests for trigger_push fields and impulses.

	Copyright (C) 2026 NZ:P Team

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
float(float condition, string message) Test_Assert;
void(string message) Test_Skip;

void() Test_Push_DirectionAndState =
{
	entity old_self = self;
	float old_state = global_triggerstate;
	self = spawn();
	self.spawnflags = PUSH_SPAWNFLAG_STARTOFF;
	self.velocity_retention = 150;
	trigger_push();
	Test_Assert((self.movedir == '1 0 0' && self.speed == 100), "Default push direction or speed is incorrect!");
	Test_Assert((self.velocity_retention == 100), "Velocity retention was not clamped!");
	Test_Assert((self.touch == SUB_Null && self.nextthink <= 0), "Start disabled field is active!");

	global_triggerstate = TRIGGERSTATE_ON;
	push_use();
	Test_Assert((self.touch == push_touch && self.nextthink <= 0), "On did not enable the field!");
	push_use();
	Test_Assert((self.touch == push_touch), "Repeated On toggled the field off!");
	global_triggerstate = TRIGGERSTATE_OFF;
	push_use();
	Test_Assert((self.touch == SUB_Null && self.nextthink <= 0), "Off did not disable the field!");
	global_triggerstate = TRIGGERSTATE_TOGGLE;
	push_use();
	Test_Assert((self.touch == push_touch), "Toggle did not enable the field!");
	push_use();
	Test_Assert((self.touch == SUB_Null), "Toggle did not disable the field!");

	self.angles = '0 -1 0';
	self.velocity_retention = -1;
	trigger_push();
	Test_Assert((self.movedir == '0 0 1' && self.velocity_retention == 0), "Up direction or lower retention bound is incorrect!");
	self.angles = '0 -2 0';
	trigger_push();
	Test_Assert((self.movedir == '0 0 -1'), "Down direction is incorrect!");
	self.angles = '0 90 0';
	trigger_push();
	Test_Assert((vlen(self.movedir - '0 1 0') < 0.001), "Yaw was not converted to a push direction!");

	remove(self);
	self = old_self;
	global_triggerstate = old_state;
};

void() Test_Push_Filters =
{
	entity old_self = self;
	self = spawn();
	entity ent = spawn();
	ent.classname = "player";
	ent.movetype = MOVETYPE_WALK;
	ent.solid = SOLID_SLIDEBOX;
	Test_Assert((!push_affects(ent)), "Players were enabled without a spawnflag!");
	self.spawnflags = PUSH_SPAWNFLAG_NONPLAYER;
	Test_Assert((!push_affects(ent)), "Non-player flag enabled players!");
	self.spawnflags = PUSH_SPAWNFLAG_PLAYER;
	Test_Assert((push_affects(ent)), "Player flag did not enable players!");
	ent.classname = "ai_zombie";
	ent.movetype = MOVETYPE_STEP;
	Test_Assert((!push_affects(ent)), "Player flag enabled non-players!");
	self.spawnflags = PUSH_SPAWNFLAG_NONPLAYER;
	Test_Assert((push_affects(ent)), "Non-player flag did not enable AI!");
	ent.movetype = MOVETYPE_TOSS;
	Test_Assert((push_affects(ent)), "Non-player flag did not enable movable objects!");
	ent.movetype = MOVETYPE_NOCLIP;
	Test_Assert((!push_affects(ent)), "Noclip entity was affected!");
	ent.movetype = MOVETYPE_NONE;
	Test_Assert((!push_affects(ent)), "Static entity was affected!");
	ent.movetype = MOVETYPE_PUSH;
	Test_Assert((!push_affects(ent)), "Brush mover was affected!");
	ent.movetype = MOVETYPE_FOLLOW;
	Test_Assert((!push_affects(ent)), "Attached entity was affected!");
	ent.movetype = MOVETYPE_FLY;
	ent.solid = SOLID_NOT;
	Test_Assert((!push_affects(ent)), "Non-solid entity was affected!");
	ent.solid = SOLID_BSP;
	Test_Assert((!push_affects(ent)), "BSP entity was affected!");
	ent.solid = SOLID_BBOX;
	ent.entity_removed = true;
	Test_Assert((!push_affects(ent)), "Removed entity was affected!");
	remove(ent);
	remove(self);
	self = old_self;
};

void() Test_Push_ImpulseRetention =
{
	entity old_self = self;
	entity old_other = other;
	for (int retention = 0; retention <= 100; retention += 50) {
		self = spawn();
		self.spawnflags = PUSH_SPAWNFLAG_ONCE | PUSH_SPAWNFLAG_PLAYER;
		self.velocity_retention = retention;
		self.angles = '0 -1 0';
		trigger_push();
		self.velocity_retention = retention;
		other = spawn();
		other.classname = "player";
		other.movetype = MOVETYPE_WALK;
		other.solid = SOLID_SLIDEBOX;
		other.flags = FL_ONGROUND;
		other.velocity = '80 -40 20';
		push_touch();
		vector expected = '80 -40 20' * (retention / 100) + '0 0 100';
		Test_Assert((other.velocity == expected), "Impulse did not retain the requested percentage of velocity!");
		Test_Assert((!(other.flags & FL_ONGROUND)), "Upward impulse left the entity grounded!");
		Test_Assert((self.entity_removed && self.solid == SOLID_NOT), "Once Only trigger remained active!");
		remove(other);
		remove(self);
	}
	self = old_self;
	other = old_other;
};

void() Test_Push_ContinuousRetentionAndBounds =
{
	entity old_self = self;
	self = spawn();
	self.spawnflags = PUSH_SPAWNFLAG_NONPLAYER;
	trigger_push();
	setorigin(self, '100000 0 0');
	setsize(self, '-32 -32 -32', '32 32 32');
	// Isolate velocity retention from movement and map geometry.
	self.speed = 0;
	entity ent = spawn();
	ent.movetype = MOVETYPE_STEP;
	ent.solid = SOLID_BBOX;
	setsize(ent, '-2 -2 -2', '2 2 2');
	setorigin(ent, self.origin);
	entity old_other = other;
	other = ent;
	push_touch();
	other = old_other;
	entity field = self;
	for (int retention = 0; retention <= 100; retention += 50) {
		self.velocity_retention = retention;
		ent.velocity = '80 -40 20';
		self = ent.push_contacts;
		push_contact_think();
		self = field;
		Test_Assert((ent.velocity == '80 -40 20' * (retention / 100)), "Continuous field retained the wrong velocity!");
	}
	self.velocity_retention = 0;
	setorigin(ent, self.origin + '40 0 0');
	ent.velocity = '80 -40 20';
	self = ent.push_contacts;
	push_contact_think();
	self = field;
	Test_Assert((ent.push_contacts == world), "Exited contact remained linked!");
	Test_Assert((ent.velocity == '80 -40 20'), "Field affected an entity outside its bounds!");
	remove(ent);
	remove(self);
	self = old_self;
};

void() Test_Push_PlayerVelocityBeforePhysics =
{
	entity old_self = self;
	entity field = spawn();
	self = field;
	field.classname = "trigger_push";
	field.spawnflags = PUSH_SPAWNFLAG_PLAYER;
	trigger_push();
	setorigin(field, '100000 0 0');
	setsize(field, '-32 -32 -32', '32 32 32');
	entity player = spawn();
	player.classname = "player";
	player.solid = SOLID_SLIDEBOX;
	player.movetype = MOVETYPE_WALK;
	setorigin(player, field.origin);
	entity old_other = other;
	other = player;
	push_touch();
	other = old_other;
	self = player;
	for (int retention = 0; retention <= 100; retention += 50) {
		field.velocity_retention = retention;
		player.velocity = '80 -40 20';
		Player_ApplyPushVelocity();
		Test_Assert((player.velocity == '80 -40 20' * (retention / 100)), "Player velocity was not retained before physics!");
		Test_Assert((self == player), "Player prethink changed self!");
	}
	field.velocity_retention = 0;
	field.touch = SUB_Null;
	player.velocity = '80 -40 20';
	Player_ApplyPushVelocity();
	Test_Assert((player.velocity == '80 -40 20'), "Disabled field changed player velocity!");
	field.touch = SUB_Null;
	self = player.push_contacts;
	push_contact_think();
	self = player;
	Test_Assert((player.push_contacts == world), "Disabled field left a player contact linked!");
	field.touch = push_touch;
	field.spawnflags |= PUSH_SPAWNFLAG_ONCE;
	Player_ApplyPushVelocity();
	Test_Assert((player.velocity == '80 -40 20'), "Once Only applied continuous velocity retention!");
	remove(player);
	remove(field);
	self = old_self;
};

void() Test_Push_SteadyMovementAndCollision =
{
	entity old_self = self;
	entity ent = spawn();
	ent.movetype = MOVETYPE_FLY;
	ent.solid = SOLID_BBOX;
	setsize(ent, '-1 -1 -1', '1 1 1');
	vector start = self.origin + '0 0 48';
	tracebox(start, '-1 -1 -1', '1 1 1', start + '64 0 0', false, ent);
	if (trace_startsolid || trace_allsolid || trace_fraction < 1) {
		remove(ent);
		Test_Skip("No empty space above the test player for the collision fixture.");
		return;
	}
	setorigin(ent, start);
	ent.velocity = '0 20 0';
	self = spawn();
	self.spawnflags = PUSH_SPAWNFLAG_NONPLAYER;
	self.velocity_retention = 100;
	trigger_push();
	setorigin(self, start);
	setsize(self, '-8 -8 -8', '64 8 8');
	entity field = self;
	entity old_other = other;
	other = ent;
	push_touch();
	push_touch();
	other = old_other;
	Test_Assert((ent.push_contacts != world && ent.push_contacts.push_contact_next == world), "Repeated touches created duplicate contacts!");
	float old_frametime = frametime;
	frametime = 0.02;
	self = ent.push_contacts;
	push_contact_think();
	self = field;
	Test_Assert((vlen(ent.origin - (start + '2 0 0')) < 0.01), "Field speed did not account for a short frame!");
	frametime = 0.1;
	self = ent.push_contacts;
	push_contact_think();
	self = field;
	Test_Assert((vlen(ent.origin - (start + '12 0 0')) < 0.01), "Field speed did not account for a long frame!");
	Test_Assert((ent.velocity == '0 20 0'), "Continuous field accumulated velocity!");
	Ent_FakeRemove(self);
	self = ent.push_contacts;
	push_contact_think();
	self = field;
	Test_Assert((vlen(ent.origin - (start + '12 0 0')) < 0.01), "Removed field continued pushing!");
	frametime = old_frametime;
	remove(self);
	self = old_self;
	setorigin(ent, start);
	push_move(ent, '16 0 0');
	push_move(ent, '16 0 0');
	Test_Assert((vlen(ent.origin - (start + '32 0 0')) < 0.01), "Repeated field movement did not maintain a steady speed!");
	Test_Assert((ent.velocity == '0 20 0'), "Field movement accumulated into the entity's own velocity!");

	entity wall = spawn();
	wall.solid = SOLID_BBOX;
	setsize(wall, '-2 -16 -16', '2 16 16');
	setorigin(wall, start + '48 0 0');
	push_move(ent, '32 8 0');
	Test_Assert((ent.origin_x < start_x + 46), "Field pushed an entity through a solid obstacle!");
	Test_Assert((ent.origin_y > start_y + 7), "Field did not slide along the obstacle!");
	remove(wall);
	remove(ent);
};

void() Test_Push_DefaultMomentumAndIdle =
{
	entity old_self = self;
	entity old_other = other;
	float old_retouch = force_retouch;
	self = spawn();
	self.spawnflags = PUSH_SPAWNFLAG_PLAYER;
	trigger_push();
	Test_Assert((self.velocity_retention == 100), "Default field does not preserve momentum!");
	Test_Assert((self.nextthink <= 0 && self.think == SUB_Null), "Idle field scheduled a think!");
	setorigin(self, '100000 0 0');
	setsize(self, '-32 -32 -32', '32 32 32');
	entity field = self;
	other = spawn();
	other.classname = "player";
	other.movetype = MOVETYPE_WALK;
	other.solid = SOLID_SLIDEBOX;
	setorigin(other, self.origin);
	other.velocity = '80 -40 20';
	push_touch();
	self = other;
	Player_ApplyPushVelocity();
	Player_ApplyPushVelocity();
	Test_Assert((self.velocity == '80 -40 20'), "Default field erased player momentum!");
	self = other.push_contacts;
	field.entity_removed = true;
	push_contact_think();
	Test_Assert((other.push_contacts == world), "Removed field left a contact linked!");
	self = field;
	self.entity_removed = false;
	self.spawnflags |= PUSH_SPAWNFLAG_ONCE;
	push_touch();
	Test_Assert((other.velocity == '180 -40 20'), "Default impulse erased player momentum!");
	remove(other);
	remove(field);
	self = old_self;
	other = old_other;
	force_retouch = old_retouch;
};

void() Test_Push_OverlappingContactCleanup =
{
	entity old_self = self;
	entity old_other = other;
	float old_retouch = force_retouch;
	entity player = spawn();
	player.classname = "player";
	player.movetype = MOVETYPE_WALK;
	player.solid = SOLID_SLIDEBOX;
	setorigin(player, '100000 0 0');
	entity first = spawn();
	entity second = spawn();
	self = first;
	self.spawnflags = PUSH_SPAWNFLAG_PLAYER;
	self.velocity_retention = 50;
	trigger_push();
	setorigin(self, player.origin);
	setsize(self, '-32 -32 -32', '32 32 32');
	other = player;
	push_touch();
	self = second;
	self.spawnflags = PUSH_SPAWNFLAG_PLAYER;
	self.velocity_retention = 50;
	trigger_push();
	setorigin(self, player.origin);
	setsize(self, '-32 -32 -32', '32 32 32');
	push_touch();
	self = player;
	self.velocity = '80 -40 20';
	Player_ApplyPushVelocity();
	Test_Assert((self.velocity == '20 -10 5'), "Overlapping fields applied incorrect retention!");
	entity head = player.push_contacts;
	self = head.push_contact_next;
	first.touch = SUB_Null;
	push_contact_think();
	Test_Assert((player.push_contacts == head && head.push_contact_next == world), "Removing a non-head contact corrupted the contact list!");
	self = player;
	self.velocity = '80 -40 20';
	Player_ApplyPushVelocity();
	Test_Assert((self.velocity == '40 -20 10'), "Remaining field stopped retaining velocity!");
	self = head;
	player.movetype = MOVETYPE_NOCLIP;
	push_contact_think();
	Test_Assert((player.push_contacts == world), "Ineligible occupant left a contact linked!");
	remove(player);
	remove(first);
	remove(second);
	self = old_self;
	other = old_other;
	force_retouch = old_retouch;
};
