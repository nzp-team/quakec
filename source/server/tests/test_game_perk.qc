/*
	server/tests/test_game_perk.qc

	Unit tests for game_perk entity

	Copyright (C) 2021-2026 NZ:P Team

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

float test_game_perk_target_uses;
entity test_game_perk_target_activator;

void() test_game_perk_target_use =
{
	test_game_perk_target_uses++;
	test_game_perk_target_activator = activator;
};

entity(float starting_perks) Test_GamePerk_CreatePlayer =
{
	entity player = spawn();
	player.classname = "player";
	player.perks = starting_perks;
	player.health = player.max_health = 100;
	return player;
};

void() Test_GamePerk_RandomSkipsOwnedPerks =
{
	entity player = Test_GamePerk_CreatePlayer(P_JUG);
	entity perk_giver = spawn();
	entity old_self = self;
	entity old_activator = activator;

	self = perk_giver;
	self.spawnflags = P_JUG | P_SPEED;
	game_perk();
	activator = player;
	self.use();

	Test_Assert((player.perks & P_SPEED), "game_perk random mode selected a perk the activator already owned!");

	activator = old_activator;
	self = old_self;
	remove(player);
	remove(perk_giver);
};

void() Test_GamePerk_AllSequencesPerks =
{
	entity player = Test_GamePerk_CreatePlayer(0);
	entity perk_giver = spawn();
	entity old_self = self;
	entity old_activator = activator;

	self = perk_giver;
	self.spawnflags = P_SPEED | P_DEAD;
	self.mode = GAME_PERK_MODE_ALL;
	game_perk();
	activator = player;
	self.use();

	Test_Assert((player.perks & P_SPEED), "game_perk did not give the first selected perk immediately!");
	Test_Assert(!(player.perks & P_DEAD), "game_perk gave all selected perks without sequencing them!");

	entity controller = find(world, classname, "game_perk_controller");
	Test_Assert((controller != world), "game_perk did not retain a controller for its delayed perks!");
	Test_Assert((controller.nextthink == time + GAME_PERK_INTERVAL), "game_perk did not schedule the next perk after the expected delay!");
	self = controller;
	self.think();
	Test_Assert((player.perks & P_DEAD), "game_perk did not give the next selected perk!");

	activator = old_activator;
	self = old_self;
	remove(player);
	remove(perk_giver);
};

void() Test_GamePerk_AllPlayersSkipsDownedPlayers =
{
	entity player_one = Test_GamePerk_CreatePlayer(0);
	entity player_two = Test_GamePerk_CreatePlayer(0);
	player_two.downed = true;
	entity perk_giver = spawn();
	entity old_self = self;
	entity old_activator = activator;

	self = perk_giver;
	self.spawnflags = P_STAMIN;
	self.player_mode = GAME_PERK_PLAYERS_ALL;
	game_perk();
	activator = world;
	self.use();

	Test_Assert((player_one.perks & P_STAMIN), "game_perk did not reward an active player in all-player mode!");
	Test_Assert(!(player_two.perks & P_STAMIN), "game_perk rewarded a downed player!");

	activator = old_activator;
	self = old_self;
	remove(player_one);
	remove(player_two);
	remove(perk_giver);
};

void() Test_GamePerk_ActivatorModeOnlyRewardsActivator =
{
	entity player_one = Test_GamePerk_CreatePlayer(0);
	entity player_two = Test_GamePerk_CreatePlayer(0);
	entity perk_giver = spawn();
	entity old_self = self;
	entity old_activator = activator;

	self = perk_giver;
	self.spawnflags = P_FLOP;
	game_perk();
	activator = player_one;
	self.use();

	Test_Assert((player_one.perks & P_FLOP), "game_perk did not reward its player activator!");
	Test_Assert(!(player_two.perks & P_FLOP), "game_perk rewarded a player other than its activator!");

	activator = old_activator;
	self = old_self;
	remove(player_one);
	remove(player_two);
	remove(perk_giver);
};

void() Test_GamePerk_InvalidActivatorDoesNothing =
{
	entity player = Test_GamePerk_CreatePlayer(0);
	entity non_player = spawn();
	entity perk_giver = spawn();
	entity old_self = self;
	entity old_activator = activator;

	self = perk_giver;
	self.spawnflags = P_MULE;
	game_perk();
	activator = non_player;
	self.use();

	Test_Assert(!(player.perks & P_MULE), "game_perk rewarded a player without a valid player activator!");

	activator = old_activator;
	self = old_self;
	remove(player);
	remove(non_player);
	remove(perk_giver);
};

void() Test_GamePerk_AllModeRewardsAllPlayersInSequence =
{
	entity player_one = Test_GamePerk_CreatePlayer(0);
	entity player_two = Test_GamePerk_CreatePlayer(0);
	entity perk_giver = spawn();
	entity old_self = self;
	entity old_activator = activator;

	self = perk_giver;
	self.spawnflags = P_SPEED | P_STAMIN;
	self.mode = GAME_PERK_MODE_ALL;
	self.player_mode = GAME_PERK_PLAYERS_ALL;
	game_perk();
	activator = world;
	self.use();

	Test_Assert((player_one.perks & P_SPEED) && (player_two.perks & P_SPEED), "game_perk did not give the first perk to all players!");
	Test_Assert(!(player_one.perks & P_STAMIN) && !(player_two.perks & P_STAMIN), "game_perk did not sequence its all-player rewards!");

	entity controller = find(world, classname, "game_perk_controller");
	self = controller;
	self.think();
	Test_Assert((player_one.perks & P_STAMIN) && (player_two.perks & P_STAMIN), "game_perk did not give the delayed perk to all players!");

	activator = old_activator;
	self = old_self;
	remove(player_one);
	remove(player_two);
	remove(perk_giver);
};

void() Test_GamePerk_AllModeSkipsOwnedPerks =
{
	entity player = Test_GamePerk_CreatePlayer(P_SPEED);
	entity perk_giver = spawn();
	entity old_self = self;
	entity old_activator = activator;

	self = perk_giver;
	self.spawnflags = P_SPEED | P_DEAD;
	self.mode = GAME_PERK_MODE_ALL;
	game_perk();
	activator = player;
	self.use();

	Test_Assert((player.ach_tracker_npnp == 0), "game_perk reapplied an owned perk!");

	entity controller = find(world, classname, "game_perk_controller");
	self = controller;
	self.think();
	Test_Assert((player.perks & P_DEAD), "game_perk did not continue after skipping an owned perk!");
	Test_Assert((player.ach_tracker_npnp == 1), "game_perk tracked the wrong number of newly applied perks!");

	activator = old_activator;
	self = old_self;
	remove(player);
	remove(perk_giver);
};

void() Test_GamePerk_FiresTargetsAfterSequence =
{
	string target_id = "test_game_perk_target";
	entity player = Test_GamePerk_CreatePlayer(0);
	entity target_entity = spawn();
	entity perk_giver = spawn();
	entity old_self = self;
	entity old_activator = activator;

	target_entity.targetname = target_id;
	target_entity.use = test_game_perk_target_use;
	test_game_perk_target_uses = 0;
	test_game_perk_target_activator = world;

	self = perk_giver;
	self.spawnflags = P_FLOP | P_DEAD;
	self.mode = GAME_PERK_MODE_ALL;
	self.target = target_id;
	game_perk();
	activator = player;
	self.use();

	Test_Assert((test_game_perk_target_uses == 0), "game_perk fired its targets before finishing its perk sequence!");

	entity controller = find(world, classname, "game_perk_controller");
	self = controller;
	self.think();
	Test_Assert((test_game_perk_target_uses == 1), "game_perk did not fire its targets after finishing!");
	Test_Assert((test_game_perk_target_activator == player), "game_perk did not preserve its original activator for its targets!");

	activator = old_activator;
	self = old_self;
	remove(player);
	remove(target_entity);
	remove(perk_giver);
};
