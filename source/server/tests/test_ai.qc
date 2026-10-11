/*
	server/tests/test_ai.qc

	Unit tests for various AI behaviors

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
// Test_AI_HellhoundsDetected()
// Validates that if a hellhound spawner is in the
// world that we have detected we can have Hellhound
// rounds.
// (https://github.com/nzp-team/nzportable/issues/623)
//
void() Test_AI_HellhoundsDetected =
{
    entity hound = find(world, classname, "spawn_dog");

    if (hound != world) {
        Test_Assert((map_has_hellhounds == true), "Found Hellhound entities but map_has_hellhounds is false!");
        Test_Assert((dogRound >= 0), "Found Hellhound entities but dogRound is zero!");
    } else {
        Test_Assert((map_has_hellhounds == false), "No Hellhound entities found but map_has_hellhounds is true!");
        Test_Assert((dogRound == 0), "No Hellhound entities found but dogRound is not zero!");
    }
};

void() Test_AI_DistanceDespawn =
{
	float old_distance = game_modifiers.gameplay.ai.zombie.despawn_distance;
	float old_height = game_modifiers.gameplay.ai.zombie.despawn_height;
	game_modifiers.gameplay.ai.zombie.despawn_height = 0;

	entity client = find(world, classname, "player");
	while (client != world) {
		client.classname = "distance_test_client";
		client = find(world, classname, "player");
	}
	entity zombie = spawn();
	zombie.classname = "ai_zombie";
	zombie.aistatus = "1";
	zombie.health = 100;
	zombie.origin = '2000 0 0';
	entity player = spawn();
	player.classname = "player";
	player.health = 100;
	player.v_angle = '0 180 0';

	game_modifiers.gameplay.ai.zombie.despawn_distance = 0;
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Distance cleanup was not disabled at zero!");
	game_modifiers.gameplay.ai.zombie.despawn_distance = 1500;
	Test_Assert(Zombie_CanDistanceDespawn(zombie), "Distant unseen zombie was protected!");
	player.v_angle = '0 0 0';
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Looking player did not protect distant zombie!");
	zombie.origin = '100000 0 0';
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "View protection stopped at a far distance!");
	zombie.origin = '2000 0 0';
	player.v_angle = '0 180 0';
	player.origin = '500 0 0';
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Player at distance boundary did not protect zombie!");
	player.origin = '0 0 0';
	zombie.origin = '500 0 1001';
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Zero height limit did not preserve distance protection!");
	game_modifiers.gameplay.ai.zombie.despawn_height = 1000;
	Test_Assert(Zombie_CanDistanceDespawn(zombie), "Zombie above height limit was protected by proximity!");
	zombie.origin_z = -1001;
	Test_Assert(Zombie_CanDistanceDespawn(zombie), "Zombie below height limit was protected by proximity!");
	zombie.origin_z = 1000;
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Height boundary did not protect nearby zombie!");
	zombie.origin_z = 1001;
	player.v_angle = '0 0 0';
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Height limit bypassed view protection!");
	game_modifiers.gameplay.ai.zombie.despawn_distance = 0;
	player.v_angle = '0 180 0';
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Height limit enabled disabled distance cleanup!");
	game_modifiers.gameplay.ai.zombie.despawn_distance = 1500;
	game_modifiers.gameplay.ai.zombie.despawn_height = 0;
	zombie.origin = '2000 0 0';
	player.downed = true;
	player.v_angle = '0 0 0';
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Downed player's view did not protect zombie!");
	player.is_spectator = true;
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Cleanup allowed without an active player!");
	player.is_spectator = false;
	player.v_angle = '0 180 0';
	entity teammate = spawn();
	teammate.classname = "player";
	teammate.health = 100;
	teammate.v_angle = '0 0 0';
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Second player's view was ignored!");
	teammate.is_spectator = true;
	Test_Assert(Zombie_CanDistanceDespawn(zombie), "Spectator prevented distance cleanup!");
	zombie.outside = true;
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Outside zombie was eligible for cleanup!");
	zombie.outside = false;
	zombie.crawling = true;
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Crawler was eligible for cleanup!");
	zombie.crawling = false;
	zombie.death_timer_activated = true;
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Zombie awaiting electrical death was eligible for cleanup!");
	zombie.death_timer_activated = false;
	zombie.health = 0;
	Test_Assert(!Zombie_CanDistanceDespawn(zombie), "Dead zombie was eligible for cleanup!");
	zombie.health = 100;
	zombie.head = spawn();
	zombie.larm = spawn();
	zombie.rarm = spawn();
	zombie.goaldummy = spawn();
	entity test_head = zombie.head;
	entity test_larm = zombie.larm;
	entity test_rarm = zombie.rarm;
	entity goal = zombie.goaldummy;
	entity old_self = self;
	float old_remaining = Remaining_Zombies;
	float old_current = Current_Zombies;
	float old_powerups = totalpowerups;
	Remaining_Zombies = 7;
	Current_Zombies = 3;
	self = zombie;
	zombie.distance_cleanup_time = time + 1;
	Test_Assert(!Zombie_ProcessDistanceDespawn(), "Cleanup ignored its check interval!");
	zombie.distance_cleanup_time = time;
	Test_Assert(Zombie_ProcessDistanceDespawn(), "Eligible zombie was not recycled!");
	Test_Assert(Remaining_Zombies == 7, "Cleanup reduced the round's remaining total!");
	Test_Assert(Current_Zombies == 2, "Cleanup failed to free a spawn slot!");
	Test_Assert(zombie.classname == "freeZombieEntity", "Cleanup failed to release the zombie pool entity!");
	Test_Assert(zombie.distance_respawn_health == 100, "Cleanup did not save remaining health!");
	Test_Assert(getFreeZombieEnt() == zombie, "Spawn pool did not prioritize the pending replacement!");
	Test_Assert(totalpowerups == old_powerups, "Cleanup dropped a power-up!");
	Test_Assert(!Zombie_ProcessDistanceDespawn(), "Cleanup recycled the same zombie twice!");
	self = old_self;
	Remaining_Zombies = old_remaining;
	Current_Zombies = old_current;
	remove(test_head);
	remove(test_larm);
	remove(test_rarm);
	remove(goal);
	remove(teammate);
	remove(player);
	remove(zombie);
	client = find(world, classname, "distance_test_client");
	while (client != world) {
		client.classname = "player";
		client = find(world, classname, "distance_test_client");
	}
	game_modifiers.gameplay.ai.zombie.despawn_distance = old_distance;
	game_modifiers.gameplay.ai.zombie.despawn_height = old_height;
};

void() Test_AI_DistanceRespawnHealth =
{
	entity zombie = spawn();
	zombie.distance_respawn_round = rounds;
	zombie.distance_respawn_health = 50;
	Test_Assert(Zombie_DistanceRespawnHealth(zombie, 100) == 50, "Replacement lost remaining health!");
	Test_Assert(Zombie_DistanceRespawnHealth(zombie, 100) == 100, "Saved health was reused twice!");
	zombie.distance_respawn_round = rounds - 1;
	zombie.distance_respawn_health = 50;
	Test_Assert(Zombie_DistanceRespawnHealth(zombie, 100) == 100, "Saved health carried into a new round!");
	remove(zombie);
};
