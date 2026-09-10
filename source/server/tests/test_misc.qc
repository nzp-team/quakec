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

//
// Test_Door_RotatingUsesAnglesAndPreservesOrigin()
// Verifies doors with the rotating spawnflag keeps its origin
// and instead pivots when opened.
// (https://github.com/nzp-team/nzportable/issues/908)
//
void() Test_Door_RotatingUsesAnglesAndPreservesOrigin =
{
	entity door = spawn();
	entity old_self = self;

	// Values from NZP_func_door.bsp.
	door.origin = '52 -16 56';
	door.angles = '0 0 0';
	door.distance = 90;
	door.spawnflags = 256;

	self = door;
	Door_SetupMovePositions();

	Test_Assert(door.pos1 == '0 0 0', "Rotating door closed pose was not initialized from angles!");
	Test_Assert(door.pos2 == '0 90 0', "Rotating door open pose did not use its angular distance!");
	Test_Assert(door.origin == '52 -16 56', "Rotating door custom origin was moved!");

	// A start-open rotating door must swap angle endpoints without moving its
	// custom pivot.
	door.angles = '0 0 0';
	door.spawnflags = 256 | DOOR_START_OPEN;
	Door_SetupMovePositions();

	Test_Assert(door.angles == '0 90 0', "Start-open rotating door did not begin at its open angle!");
	Test_Assert(door.pos1 == '0 90 0', "Start-open rotating door open pose was not swapped!");
	Test_Assert(door.pos2 == '0 0 0', "Start-open rotating door closed pose was not swapped!");
	Test_Assert(door.origin == '52 -16 56', "Start-open rotating door moved its custom origin!");

	self = old_self;
	remove(door);
};

//
// Test_Door_ToggleCanCompleteMultipleCycles()
// Verifies a door marked toggle-able can be opened, then closed,
// then opened..
// (https://github.com/nzp-team/nzportable/issues/1528)
//
void() Test_Door_ToggleCanCompleteMultipleCycles =
{
	entity door = spawn();
	entity source = spawn();
	entity old_self = self;
	entity old_other = other;

	door.owner = door;
	door.enemy = door;
	door.classname = "door";
	door.spawnflags = DOOR_TOGGLE;
	door.state = STATE_BOTTOM;
	door.speed = 100;
	door.wait = 3;
	door.pos1 = '0 0 0';
	door.pos2 = '10 0 0';

	self = door;
	other = source;

	for (float cycle = 0; cycle < 2; cycle++) {
		door_use();
		Test_Assert(door.state == STATE_UP, "Toggle door did not begin opening!");

		// Re-entry while opening must still be rejected.
		door_use();
		Test_Assert(door.state == STATE_UP, "Opening toggle door was activated recursively!");

		setorigin(door, door.pos2);
		door_hit_top();
		Test_Assert(door.state == STATE_TOP, "Toggle door did not reach its open state!");

		// Purchased doors become non-solid while open so the player can pass.
		door.solid = SOLID_NOT;
		door_use();
		Test_Assert(door.state == STATE_DOWN, "Open toggle door did not begin closing!");
		Test_Assert(door.solid == SOLID_BSP, "Closing toggle door did not restore BSP solidity!");

		setorigin(door, door.pos1);
		door_hit_bottom();
		Test_Assert(door.state == STATE_BOTTOM, "Toggle door did not finish closing!");
		Test_Assert(door.solid == SOLID_BSP, "Re-closed toggle door lost BSP solidity!");
	}

	self = old_self;
	other = old_other;
	remove(source);
	remove(door);
};

float test_trigger_interact_fire_count;
void() Test_TriggerInteract_CountUse =
{
    test_trigger_interact_fire_count++;
};

//
// Test_TriggerInteract_RequiresReactivation()
// An interaction fires its targets and disables its touch handler. Another
// trigger can then re-arm it so the player can fire its targets again.
//
void() Test_TriggerInteract_RequiresReactivation =
{
    entity trigger = spawn();
	entity target_ent = spawn();
    entity player = spawn();
	entity old_self = self;
	entity old_other = other;
	entity old_activator = activator;
	float old_cost_multiplier = game_modifier_cost_multiplier;
	game_modifier_cost_multiplier = 1;

    trigger.touch = trigger_interact_touch;
    trigger.use = trigger_interact_activate;
    trigger.target = "test_trigger_interact_target";
	target_ent.targetname = trigger.target;
	target_ent.use = Test_TriggerInteract_CountUse;
	player.classname = "player";
	player.button7 = true;
	player.points = 1000;
	trigger.cost = 250;
    test_trigger_interact_fire_count = 0;

    self = trigger;
    other = player;
    trigger.touch();

    Test_Assert(test_trigger_interact_fire_count == 1, "Trigger interact did not fire its target!");
    Test_Assert(trigger.touch == SUB_Null, "Trigger interact remained active after firing!");
    Test_Assert(trigger.use == trigger_interact_activate, "Trigger interact lost its reactivation handler!");
	Test_Assert(activator == player, "Trigger interact did not forward the player as activator!");
	Test_Assert(player.points == 750, "Trigger interact did not deduct its cost!");

    trigger.use();
    Test_Assert(trigger.touch == trigger_interact_touch, "Trigger interact was not reactivated when fired!");

    other = player;
    trigger.touch();
    Test_Assert(test_trigger_interact_fire_count == 2, "Reactivated trigger interact did not fire its target again!");
	Test_Assert(trigger.touch == SUB_Null, "Trigger interact remained active after firing again!");
	Test_Assert(player.points == 500, "Reactivated trigger interact did not deduct its cost exactly once!");

    self = old_self;
    other = old_other;
	activator = old_activator;
	game_modifier_cost_multiplier = old_cost_multiplier;
    remove(player);
	remove(target_ent);
    remove(trigger);
};

void() Test_TriggerInteract_RejectsInsufficientFunds =
{
	entity trigger = spawn();
	entity player = spawn();
	entity old_self = self;
	entity old_other = other;
	float old_cost_multiplier = game_modifier_cost_multiplier;
	game_modifier_cost_multiplier = 1;

	trigger.touch = trigger_interact_touch;
	trigger.cost = 500;
	player.classname = "player";
	player.button7 = true;
	player.points = 499;
	test_trigger_interact_fire_count = 0;

	self = trigger;
	other = player;
	trigger.touch();

	Test_Assert(test_trigger_interact_fire_count == 0, "Unaffordable trigger interact fired its targets!");
	Test_Assert(player.points == 499, "Unaffordable trigger interact changed player points!");
	Test_Assert(trigger.touch == trigger_interact_touch, "Unaffordable trigger interact disabled itself!");

	self = old_self;
	other = old_other;
	game_modifier_cost_multiplier = old_cost_multiplier;
	remove(player);
	remove(trigger);
};

void() Test_TriggerInteract_RegistersOptionalUseprintWithCost =
{
	entity trigger = spawn();
	entity old_self = self;
	float old_count = useprint_count;
	float old_lock = useprint_registration_locked;
	useprint_registration_locked = false;
	self = trigger;
	self.cost = 750;
	self.useprint_string_1 = "Hold %b to test interaction";

	trigger_interact();

	Test_Assert(self.useprint_string_1 == "Hold %b to test interaction", "Trigger interact replaced its mapper useprint!");
	Test_Assert(self.useprint_index_1 != 0, "Trigger interact did not register its useprint!");
	Test_Assert(self.cost == 750, "Trigger interact did not retain its optional cost!");

	self = old_self;
	useprint_count = old_count;
	useprint_registration_locked = old_lock;
	remove(trigger);
};

void() Test_TriggerInteract_DoesNotRegisterDefaultUseprint =
{
	entity trigger = spawn();
	entity old_self = self;
	float old_count = useprint_count;
	float old_lock = useprint_registration_locked;
	useprint_registration_locked = false;
	self = trigger;

	trigger_interact();

	Test_Assert(self.useprint_string_1 == "", "Trigger interact created a default useprint!");
	Test_Assert(self.useprint_index_1 == 0, "Trigger interact registered a missing useprint!");
	Test_Assert(useprint_count == old_count, "A trigger without a useprint changed the registry!");

	self = old_self;
	useprint_count = old_count;
	useprint_registration_locked = old_lock;
	remove(trigger);
};
