/*
	server/tests/test_misc.qc

	Hard to categorize tests.

	Copyright (C) 2021-2025 NZ:P Team

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

//
// Test_Door_FakeRemoveDoorDisablesTriggerField()
// A killtargeted buyable door must not leave its interaction volume behind.
//
void() Test_Door_FakeRemoveDoorDisablesTriggerField =
{
    entity door = spawn();
    entity trigger = spawn();

    door.trigger_field = trigger;
    door.solid = SOLID_BSP;
    trigger.solid = SOLID_TRIGGER;

    Ent_FakeRemove(door);

    Test_Assert(door.entity_removed, "Door was not fake removed!");
    Test_Assert(trigger.entity_removed, "Door trigger field was not fake removed!");
    Test_Assert(trigger.solid == SOLID_NOT, "Door trigger field remained interactive!");

    remove(trigger);
    remove(door);
};

//
// Test_Door_TriggeredCostDoorOpensOnce()
// Priced doors activated by another map entity should open without charging a
// player, and should not recursively loop.
// (https://github.com/nzp-team/nzportable/issues/1374)
//
void() Test_Door_TriggeredCostDoorOpensOnce =
{
    entity door = spawn();
    entity source = spawn();
    entity old_self = self;
    entity old_other = other;

    door.owner = door;
    door.enemy = door;
    door.classname = "door_nzp_cost";
    door.cost = 100;
    door.state = STATE_BOTTOM;
    door.speed = 100;
    door.pos1 = door.pos2 = door.origin;

    self = door;
    other = source;

    door_use();
    Test_Assert((door.state == STATE_UP || door.state == STATE_TOP), "A targeted cost door did not open!");

    door_use();
    Test_Assert((door.state == STATE_UP || door.state == STATE_TOP), "An opening door was activated again!");

    self = old_self;
    other = old_other;
    remove(source);
    remove(door);
};
