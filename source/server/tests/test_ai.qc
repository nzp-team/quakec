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

void() Test_AI_CrowdSearch =
{
	entity actors[5];
	vector search_origin = self.origin + '0 0 1024';
	for (int i = 0; i < 5; i++) {
		actors[i] = spawn();
		actors[i].classname = i < 3 ? "ai_zombie" : "ai_zombie_head";
		actors[i].solid = SOLID_CORPSE;
		setsize(actors[i], '-8 -8 -8', '8 8 8');
		setorigin(actors[i], search_origin + [i == 2 ? 96 : i * 8, 0, 0]);
	}

	entity expected[5];
	float count = 0;
	float total = 0;
	for (entity actor = findradius(search_origin, 64); actor != world; actor = actor.chain) {
		if (actor.classname == "ai_zombie")
			expected[count++] = actor;
		total++;
	}

	float filtered = 0;
	for (entity actor = findradius(search_origin, 64, "ai_zombie"); actor != world; actor = actor.chain) {
		Test_Assert(actor.classname == "ai_zombie", "Crowd radius filter returned a non-zombie!");
		if (filtered < count)
			Test_Assert(actor == expected[filtered], "Crowd radius filter changed neighbor ordering!");
		filtered++;
	}
	Test_Assert(count == 2 && filtered == count, "Crowd radius filter changed range or lost a zombie!");

	float unfiltered = 0;
	for (entity actor = findradius(search_origin, 64); actor != world; actor = actor.chain)
		unfiltered++;
	Test_Assert(unfiltered == total, "Omitted crowd filter retained a stale argument!");

	unfiltered = 0;
	for (entity actor = findradius(search_origin, 64, ""); actor != world; actor = actor.chain)
		unfiltered++;
	Test_Assert(unfiltered == total, "Empty crowd filter changed unfiltered radius behavior!");

	for (int i = 0; i < 5; i++)
		remove(actors[i]);
};

void() Test_AI_MovementBudget =
{
	entity old_self = self;
	float old_updates = ai_movement_updates;
	entity actors[3];
	ai_movement_updates = 0;

	for (int i = 0; i < 3; i++) {
		self = actors[i] = spawn();
		self.classname = i == 2 ? "ai_dog" : "ai_zombie";
		self.flags = FL_ONGROUND;
		self.path_update_pending = true;
		setorigin(self, old_self.origin);
		do_walk_to_vec(13, self.origin + '128 0 0');
	}

	Test_Assert(ai_movement_updates == 1, "Movement planning exceeded the shared frame budget!");
	Test_Assert(!actors[0].path_update_pending && actors[1].path_update_pending && actors[2].path_update_pending, "Deferred movement updates lost their pending requests!");

	ai_movement_updates = 0;
	self = actors[0];
	do_walk_to_vec(13, self.origin + '128 0 0');
	Test_Assert(ai_movement_updates == 0, "Movement planned again without a round-robin request!");
	self = actors[1];
	do_walk_to_vec(13, self.origin + '128 0 0');
	Test_Assert(ai_movement_updates == 1 && !self.path_update_pending, "Deferred zombie did not get its planning update!");

	for (int i = 0; i < 3; i++)
		remove(actors[i]);
	self = old_self;
	ai_movement_updates = old_updates;
};

void() Test_AI_CachedCrowdWish =
{
	entity old_self = self;
	self = spawn();
	self.crowd_wish_time = time;
	self.crowd_wish_origin = self.origin;
	self.crowd_wish_heading = '1 0 0';
	self.crowd_wish_factors = '0.5 0.25 0';
	Test_Assert(AI_CrowdCachedWishVelocity('260 0 0') == '130 65 0', "Cached crowd steering did not scale with animation speed!");
	Test_Assert(AI_CrowdCachedWishVelocity('0 130 0') == '0 130 0', "Cached crowd steering survived a sharp turn!");
	self.enemy = old_self;
	Test_Assert(AI_CrowdCachedWishVelocity('130 0 0') == '130 0 0', "Cached crowd steering survived a target change!");
	self.enemy = world;
	self.origin_x += 65;
	Test_Assert(AI_CrowdCachedWishVelocity('130 0 0') == '130 0 0', "Cached crowd steering survived excessive movement!");
	self.origin = self.crowd_wish_origin;
	self.crowd_wish_time = time - 1.1;
	Test_Assert(AI_CrowdCachedWishVelocity('130 0 0') == '130 0 0', "Cached crowd steering survived its expiry!");
	remove(self);
	self = old_self;
};

void() Test_AI_CrowdSpacing =
{
	entity old_self = self;
	entity actor = spawn();
	entity neighbor = spawn();
	actor.classname = neighbor.classname = "ai_zombie";
	actor.aistatus = neighbor.aistatus = "1";
	actor.health = neighbor.health = 100;
	actor.solid = neighbor.solid = SOLID_CORPSE;
	actor.flags = neighbor.flags = FL_ONGROUND | FL_MONSTER;
	setsize(actor, '-8 -8 -32', '8 8 30');
	setsize(neighbor, '-8 -8 -32', '8 8 30');
	setorigin(actor, old_self.origin);
	setorigin(neighbor, old_self.origin);
	self = actor;

	vector heading = '1 0 0';
	vector side = '0 1 0';
	actor.crowd_update_time = time + 1;

	vector wish = heading * 130;
	Test_Assert(AI_CrowdWishVelocity(wish) == wish, "Solo zombie speed changed!");
	actor.crowd_neighbors[0] = neighbor;
	setorigin(neighbor, actor.origin + heading * 48);
	neighbor.path_move_direction = heading;
	neighbor.velocity = wish;
	Test_Assert(AI_CrowdWishVelocity(wish) == wish, "Spaced follower slowed behind a moving zombie!");
	neighbor.velocity = '0 0 0';

	vector result = AI_CrowdWishVelocity(wish);
	Test_Assert(result * heading < 130 && result * heading > 0, "Follower did not slow before reaching a stationary zombie!");
	Test_Assert(fabs(result * side) > 1, "Follower waited in line instead of separating before contact!");

	float pass_side = result * side;
	Test_Assert(AI_CrowdWishVelocity(wish) * side * pass_side > 0, "Follower changed passing side during the same obstruction!");
	neighbor.velocity = wish;
	setorigin(neighbor, actor.origin + heading * 40);
	result = AI_CrowdWishVelocity(wish);
	Test_Assert(result * heading > 0 && fabs(result * side) > 1, "Moving queue did not widen before contact!");

	entity goal = spawn();
	goal.classname = "zombie_horde_point";
	actor.enemy = goal;
	setorigin(goal, actor.origin + heading * 300);

	float rear_side = fabs(AI_CrowdWishVelocity(wish) * side);
	setorigin(goal, actor.origin + heading * 100);

	vector front = AI_CrowdWishVelocity(wish);
	Test_Assert(fabs(front * side) < rear_side, "Crowd did not narrow toward its destination!");
	goal.classname = "player";
	Test_Assert(AI_CrowdWishVelocity(wish) == front, "Player and non-player goals used different crowd convergence!");
	actor.enemy = world;
	remove(goal);
	setorigin(neighbor, actor.origin + heading * 48 - side * 32);
	neighbor.velocity = heading * 30;
	actor.crowd_blocker = neighbor;
	actor.crowd_avoid_side = 1;
	result = AI_CrowdWishVelocity(heading * 210);
	Test_Assert(result * heading > 130 && result * side > 40, "Faster zombie abandoned its pass before clearing the slower leader!");
	setorigin(neighbor, actor.origin - heading * 24 - side * 32);
	Test_Assert(AI_CrowdWishVelocity(heading * 210) == heading * 210, "Passing zombie did not resume pursuit after clearing its leader!");
	Test_Assert(actor.crowd_blocker == world, "Completed pass retained a crowd blocker!");
	setorigin(neighbor, actor.origin);
	neighbor.velocity = '7 9 11';
	result = AI_CrowdWishVelocity(wish);
	Test_Assert(fabs(result * side) > 1, "Coincident zombies did not separate!");
	Test_Assert(vlen(result) <= 130.01, "Crowd movement exceeded walking speed!");
	Test_Assert(neighbor.velocity == '7 9 11', "Crowd movement changed another zombie's velocity!");
	neighbor.origin_z += 24;
	Test_Assert(AI_CrowdWishVelocity(wish) == wish, "Zombie on another floor affected movement!");
	neighbor.origin_z -= 24;
	neighbor.health = 0;
	Test_Assert(AI_CrowdWishVelocity(wish) == wish, "Dead zombie affected movement!");
	neighbor.health = 100;
	neighbor.outside = true;
	Test_Assert(AI_CrowdWishVelocity(wish) == wish, "Outside zombie affected movement!");
	neighbor.outside = false;
	actor.flags = 0;
	Test_Assert(AI_CrowdWishVelocity(wish) == wish, "Crowd steering changed airborne movement!");
	actor.flags = FL_ONGROUND;
	actor.outside = true;
	Test_Assert(AI_CrowdWishVelocity(wish) == wish, "Crowd steering changed window movement!");
	actor.outside = false;
	actor.classname = "ai_dog";
	actor.path_move_direction = -heading;
	actor.path_move_time = time;
	do_walk_to_vec(13, actor.origin + heading * 100);
	Test_Assert(actor.velocity == wish, "Zombie steering changed hellhound movement!");
	actor.classname = "ai_zombie";
	actor.crowd_update_time = 0;
	AI_UpdateCrowd();
	Test_Assert(actor.crowd_neighbors[0] == neighbor, "Nearby active zombie was not detected!");
	self = old_self;
	remove(neighbor);
	remove(actor);
};

void() Test_AI_CrowdCrossing =
{
	entity old_self = self;
	entity actor = spawn();
	entity neighbor = spawn();
	actor.classname = neighbor.classname = "ai_zombie";
	actor.aistatus = neighbor.aistatus = "1";
	actor.health = neighbor.health = 100;
	actor.flags = neighbor.flags = FL_ONGROUND;
	actor.path_move_direction = '1 0 0';
	neighbor.path_move_direction = '-1 0 0';
	actor.crowd_update_time = neighbor.crowd_update_time = time + 1;
	actor.crowd_neighbors[0] = neighbor;
	neighbor.crowd_neighbors[0] = actor;
	setorigin(actor, old_self.origin);
	setorigin(neighbor, actor.origin + '32 24 0');
	self = actor;

	vector result = AI_CrowdWishVelocity('130 0 0');
	Test_Assert(result_x > 0, "Crossing zombie yielded to opposing traffic!");
	self = neighbor;
	result = AI_CrowdWishVelocity('-130 0 0');
	Test_Assert(result_x < 0, "Opposing zombies entered a mutual wait!");
	self = actor;
	neighbor.path_move_direction = '1 0 0';
	actor.crowd_progress_origin = actor.origin;
	actor.crowd_progress_time = time;
	result = AI_CrowdWishVelocity('130 0 0');
	Test_Assert(result_x >= 0 && result_x < 26 && fabs(result_y) > 0, "Follower did not yield forward movement while separating from stationary traffic!");
	actor.crowd_progress_time = time - 1.1;
	result = AI_CrowdWishVelocity('130 0 0');
	Test_Assert(result_x >= 25.99, "Crowd yielding stopped pursuit indefinitely!");
	actor.origin_x += 5;
	AI_CrowdWishVelocity('130 0 0');
	Test_Assert(actor.crowd_progress_time == time, "Crowd progress did not reset the yielding timeout!");
	self = old_self;
	remove(neighbor);
	remove(actor);
};

void() Test_AI_PathSteering =
{
	entity old_self = self;
	entity actor = spawn();
	actor.classname = "ai_zombie";
	actor.flags = FL_ONGROUND;
	setorigin(actor, old_self.origin);
	actor.path_move_origin = actor.origin;
	self = actor;
	actor.path_move_direction = '1 0 0';
	actor.path_move_time = time - 0.1;

	vector target = actor.origin + '0 512 0';
	vector wish = '0 130 0';
	vector candidate = normalize('0.4 0.6 0') * 130;
	vector result = AI_PathVelocity(wish, target);

	if (tracemove(actor.origin, '-16 -16 -32', '16 16 40', actor.origin + candidate * 0.2, true, actor)) {
		Test_Assert(result_x > 0 && result_y > 0, "Level pursuit snapped to the new heading!");
		Test_Assert(fabs(vlen(result) - 130) < 0.01, "Steering changed the requested speed!");
	} else {
		Test_Assert(result == wish, "Blocked steering did not retain the route direction!");
	}

	Test_Assert(AI_PathVelocity(wish, actor.origin + '0 40 0') == wish, "Steering delayed arrival at a close goal!");
	Test_Assert(AI_PathVelocity(wish, target + '0 0 8') == wish, "Steering changed an elevation transition!");
	Test_Assert(AI_PathVelocity('-130 0 0', actor.origin + '-512 0 0') == '-130 0 0', "Steering delayed a reversal!");
	actor.path_move_time = time - 0.4;
	Test_Assert(AI_PathVelocity(wish, target) == wish, "Steering reused a stale heading!");
	actor.path_move_time = time - 0.1;
	actor.path_move_origin = actor.origin + '65 0 0';
	Test_Assert(AI_PathVelocity(wish, target) == wish, "Steering reused a heading from before a teleport!");
	actor.path_move_origin = actor.origin;
	actor.flags = 0;
	Test_Assert(AI_PathVelocity(wish, target) == wish, "Steering changed airborne movement!");
	actor.flags = FL_ONGROUND;
	actor.outside = true;
	Test_Assert(AI_PathVelocity(wish, target) == wish, "Steering changed window movement!");
	actor.outside = false;
	actor.classname = "ai_dog";
	Test_Assert(AI_PathVelocity(wish, target) == result, "Hellhound did not inherit the safe path steering!");
	actor.classname = "test_actor";
	Test_Assert(AI_PathVelocity(wish, target) == wish, "Steering changed an unsupported actor type!");
	self = old_self;
	remove(actor);
};

void() Test_AI_KeepRoute =
{
	entity old_self = self;
	entity actor = spawn();
	entity target = spawn();
	actor.classname = "ai_zombie";
	actor.goaldummy = spawn();
	actor.enemy = target;
	actor.path_direct_retry_time = time + 100;
	target.classname = "player";
	target.health = 100;
	target.flags = FL_ONGROUND;
	setsize(actor, '-16 -16 -32', '16 16 40');
	setorigin(actor, nzp_ai_land(actor, old_self.origin));
	setorigin(target, actor.origin);
	self = actor;

	Test_Assert(PathfindToEnemy() == 1, "Route reuse fixture did not acquire a graph path!");
	setorigin(actor, actor.goaldummy.origin);
	vector anchor = actor.goaldummy.origin;
	Test_Assert(AI_PathfindTarget(target, true) == 2, "Valid existing route was rebuilt during a target refresh!");
	actor.path_lookahead_time = time + 2;
	Test_Assert(PathfindToEnemy(true) == 1, "Retained route was not normalized to graph pursuit!");
	Test_Assert(actor.goalentity == actor.goaldummy && actor.goaldummy.origin == anchor, "Target refresh replaced the current route anchor!");
	Test_Assert(actor.path_lookahead_time == time + 2, "Retaining a route discarded its movement plan!");
	Test_Assert(AI_PathfindTarget(target) == 1, "Explicit path retry reused the previous route!");
	PathfindToEnemy();

	entity brush = nextent(world);
	while (brush != world && brush.solid != SOLID_BSP)
		brush = nextent(brush);

	if (brush != world) {
		brush.solid = SOLID_NOT;
		setorigin(brush, brush.origin);
		Test_Assert(AI_PathfindTarget(target, true) != 2, "Brush collision change retained a stale route!");
		brush.solid = SOLID_BSP;
		setorigin(brush, brush.origin);
		Test_Assert(AI_PathfindTarget(target, true) != 2, "Restoring brush collision retained a stale route!");
	}

	PathfindToEnemy();
	entity replacement = spawn();
	replacement.classname = "player";
	replacement.health = 100;
	replacement.flags = FL_ONGROUND;
	setorigin(replacement, target.origin);
	actor.enemy = replacement;
	Test_Assert(AI_PathfindTarget(replacement, true) != 2, "Replacing the target retained its predecessor's route!");
	actor.enemy = target;
	PathfindToEnemy();
	setorigin(actor, actor.origin + '1280 0 0');
	Test_Assert(AI_PathfindTarget(target, true) != 2, "Teleport retained a route outside the actor's corridor!");

	nzp_pathfind_clear(actor);
	remove(replacement);
	remove(actor.goaldummy);
	remove(target);
	remove(actor);
	self = old_self;
};

void() Test_AI_PathTargetUpdate =
{
	entity old_self = self;
	entity actor = spawn();
	entity target = spawn();
	self = actor;
	actor.enemy = actor.path_goal_enemy = target;
	actor.path_status = 1;
	actor.path_goal_origin = target.origin;
	actor.path_target_update_time = time;
	Test_Assert(!AI_PathNeedsUpdate(), "Stationary target invalidated a usable route!");
	target.origin_x += 63;
	Test_Assert(!AI_PathNeedsUpdate(), "Small target movement invalidated a usable route!");
	target.origin_x += 1;
	Test_Assert(AI_PathNeedsUpdate(), "Moving target left the route destination stale!");
	actor.path_target_update_time = time + 1;
	Test_Assert(!AI_PathNeedsUpdate(), "Target movement bypassed the route update interval!");
	actor.path_goal_enemy = world;
	Test_Assert(AI_PathNeedsUpdate(), "Enemy replacement retained the previous target's route!");
	actor.path_status = 0;
	Test_Assert(!AI_PathNeedsUpdate(), "Target movement bypassed failed-path recovery!");
	self = old_self;
	remove(target);
	remove(actor);
};

void() Test_AI_WindowPathHandoff =
{
	entity old_self = self;
	entity actor = spawn();
	entity window = spawn();
	entity dummy = spawn();
	actor.classname = "ai_zombie";
	actor.goaldummy = dummy;
	actor.goalentity = window;
	actor.outside = 2;
	actor.hop_step = 6;
	actor.th_walk = SUB_Null;
	actor.path_status = 1;
	actor.path_direct_retry_time = time + 100;
	actor.path_move_direction = '1 0 0';
	actor.path_move_time = time;
	window.usedent = actor;
	setorigin(actor, old_self.origin);
	self = actor;
	Window_Hop(0);
	Test_Assert(actor.outside == false && actor.hop_step == 0, "Barricade handoff retained the window state!");
	Test_Assert(window.usedent == world, "Barricade handoff retained the window reservation!");
	Test_Assert(actor.path_status == 0 && actor.path_direct_retry_time == 0, "Barricade handoff retained a stale route or cooldown!");
	Test_Assert(actor.path_move_direction == '0 0 0' && dummy.origin == actor.origin, "Barricade handoff retained pre-hop steering!");
	Test_Assert(actor.path_wait_ground, "Barricade handoff did not wait for ground support!");
	actor.enemy_timeout = time + 100;
	actor.flags = 0;
	Inside_Walk(0);
	Test_Assert(actor.path_wait_ground && actor.path_status == 0, "Barricade handoff acquired a route before landing!");
	window.classname = "path_corner";
	window.spawnflags = 1;
	setorigin(window, actor.origin);
	actor.goalentity = window;
	actor.outside = true;
	actor.reload_delay = time + 100;
	actor.path_status = 1;
	actor.path_direct_retry_time = time + 100;
	actor.path_move_direction = '1 0 0';
	Window_Walk(0);
	Test_Assert(actor.outside == false && actor.goalentity == world, "Path-corner handoff retained the outside goal!");
	Test_Assert(actor.path_status == 0 && actor.path_direct_retry_time == 0 && actor.path_move_direction == '0 0 0', "Path-corner handoff retained an old route or steering!");
	Test_Assert(actor.path_wait_ground, "Path-corner handoff did not wait for ground support!");
	self = old_self;
	remove(dummy);
	remove(window);
	remove(actor);
};

void() Test_AI_RecycledPathState =
{
	entity old_self = self;
	entity actor = spawn();
	actor.classname = "ai_zombie";
	actor.goaldummy = spawn();
	actor.head = spawn();
	actor.larm = spawn();
	actor.rarm = spawn();
	actor.head.owner = actor.larm.owner = actor.rarm.owner = actor;
	setorigin(actor, old_self.origin);
	actor.path_status = actor.path_wait_ground = actor.path_update_pending = true;
	actor.path_goal_enemy = actor.crowd_neighbors[0] = old_self;
	actor.path_direct_retry_time = actor.path_lookahead_time = actor.crowd_wish_time = time + 10;
	actor.path_move_direction = '1 0 0';
	actor.scale = 1.125;
	self = actor;
	removeZombie();
	Test_Assert(actor.classname == "freeZombieEntity" && actor.path_status == 0, "Recycled zombie retained an active path!");
	Test_Assert(actor.path_goal_enemy == world && actor.crowd_neighbors[0] == world, "Recycled zombie retained its target or crowd neighbors!");
	Test_Assert(actor.path_direct_retry_time == 0 && actor.path_lookahead_time == 0 && actor.crowd_wish_time == 0, "Recycled zombie retained route or steering deadlines!");
	Test_Assert(!actor.path_wait_ground && !actor.path_update_pending && actor.path_move_direction == '0 0 0', "Recycled zombie retained pending movement state!");
	Test_Assert(actor.scale == 0, "Recycled dog scale leaked into the next zombie!");
	remove(actor.goaldummy);
	remove(actor.head);
	remove(actor.larm);
	remove(actor.rarm);
	remove(actor);
	self = old_self;
};

void() Test_AI_LandingHull =
{
	entity actor = spawn();
	vector landing = nzp_ai_land(actor, self.origin);
	tracebox(landing, '-16 -16 -32', '16 16 40', landing, true, actor);

	if (trace_startsolid || trace_allsolid) {
		Test_Skip("Player spawn has insufficient space for the standing zombie hull.");
	} else {
		vector corrected = nzp_ai_land(actor, landing - '0 0 4');
		tracebox(corrected, '-16 -16 -32', '16 16 40', corrected, true, actor);
		Test_Assert(!trace_startsolid && !trace_allsolid, "Landing correction left the standing hull inside the floor!");
		Test_Assert(vlen(corrected - landing) < 1, "Landing correction moved a supported exit away from its location!");
		tracebox(corrected, '-16 -16 -32', '16 16 40', corrected - '0 0 4', true, actor);
		Test_Assert(trace_fraction < 1, "Landing correction returned an unsupported position!");
	}

	remove(actor);
};

void() Test_AI_CrowdWallClearance =
{
	entity old_self = self;
	entity actor = spawn();
	actor.movetype = MOVETYPE_WALK;
	actor.flags = FL_ONGROUND;

	vector start = old_self.origin + '0 0 0.03125';
	vector directions[4] = {'1 0 0', '-1 0 0', '0 1 0', '0 -1 0'};
	float found = false;
	self = actor;

	for (int i = 0; i < 4 && !found; i++) {
		tracebox(start, '-16 -16 -32', '16 16 40', start + directions[i] * 512, true, actor);

		if (trace_startsolid || trace_allsolid || trace_fraction == 1 || fabs(trace_plane_normal_z) >= 0.5)
			continue;

		vector normal = trace_plane_normal;
		vector wall_origin = nzp_ai_land(actor, trace_endpos + normal * 0.25);
		setorigin(actor, wall_origin);
		tracebox(wall_origin + '0 0 20', '-16 -16 -32', '16 16 40', wall_origin - normal * 2 + '0 0 20', true, actor);

		if (!trace_startsolid && !trace_allsolid && trace_fraction == 1)
			continue;

		if (!tracemove(wall_origin, '-16 -16 -32', '16 16 40', wall_origin, true, actor))
			continue;

		found = true;
		Test_Assert(tracemove(wall_origin, '-16 -16 -32', '16 16 40', wall_origin - normal * 2, true, actor), "Wall fixture did not exercise sliding tolerance!");
		Test_Assert(!AI_CrowdCanMove(-normal * 20), "Crowd correction accepted movement into a wall!");
		Test_Assert(AI_CrowdCanMove(normal * 20), "Crowd correction rejected movement away from a wall!");

		vector tangent = [-normal_y, normal_x, 0];

		if (!AI_CrowdCanMove(tangent * 360))
			tangent = -tangent;

		actor.classname = "ai_zombie";
		vector wall_velocity = AI_CrowdVelocity(normalize(tangent * 0.2 - normal) * 130);
		Test_Assert(wall_velocity * normal >= -0.01 && wall_velocity * tangent >= 117, "Unmodified route steering lost its walking speed against a wall!");

		entity neighbor = spawn();
		actor.classname = neighbor.classname = "ai_zombie";
		actor.aistatus = neighbor.aistatus = "1";
		actor.health = neighbor.health = 100;

		vector heading = normalize(tangent - normal);
		neighbor.path_move_direction = heading;
		setorigin(neighbor, wall_origin + tangent * 36);
		actor.crowd_neighbors[0] = neighbor;
		actor.crowd_update_time = time + 1;
		actor.crowd_progress_origin = actor.origin;
		actor.crowd_progress_time = time - 1.1;

		vector result = AI_CrowdVelocity(heading * 130);
		Test_Assert(result * normal >= -0.01 && result * tangent > 1, "Blocked crowd correction did not continue along the wall!");
		remove(neighbor);
	}

	if (!found)
		Test_Skip("No supported wall was available for crowd clearance testing");
	self = old_self;
	remove(actor);
}

float test_downed_walk_count;
void() DownedTarget_TestWalk =
{
	test_downed_walk_count++;
};

void() Test_AI_DownedTargetCancelsAttack =
{
	entity old_self = self;
	entity client = spawn();
	client.classname = "player";
	setorigin(client, old_self.origin);

	entity actor = spawn();
	actor.classname = "ai_zombie";
	actor.health = 100;
	actor.enemy = client;
	actor.th_walk = DownedTarget_TestWalk;
	actor.respawn_timer = actor.bleedingtime = time + 10;
	setorigin(actor, client.origin);
	self = actor;
	test_downed_walk_count = 0;
	actor.is_attacking = true;
	Zombie_Think();
	Test_Assert(actor.is_attacking && test_downed_walk_count == 0, "Viable close player interrupted a zombie attack!");
	client.downed = true;
	Zombie_Think();
	Test_Assert(!actor.is_attacking && test_downed_walk_count == 1, "Downed player did not release the zombie from its attack!");
	client.downed = false;
	client.is_spectator = true;
	actor.is_attacking = true;
	Zombie_Think();
	Test_Assert(!actor.is_attacking && test_downed_walk_count == 2, "Spectating player did not release the zombie from its attack!");
	remove(actor);
	remove(client);
	self = old_self;
};

void() Test_AI_UnreachablePlayerHordeFallback =
{
	entity old_self = self;
	entity client = find(world, classname, "player");

	while (client != world) {
		client.classname = "horde_test_client";
		client = find(world, classname, "player");
	}

	entity horde = find(world, classname, "zombie_horde_point");

	while (horde != world) {
		horde.classname = "horde_test_point";
		horde = find(world, classname, "zombie_horde_point");
	}

	entity actor = spawn();
	actor.classname = "ai_zombie";
	actor.goaldummy = spawn();
	setsize(actor, '-8 -8 -32', '8 8 30');
	setorigin(actor, old_self.origin);
	client = spawn();
	client.classname = "player";
	setorigin(client, actor.origin + '0 0 4096');
	actor.enemy = client;
	horde = spawn();
	horde.classname = "zombie_horde_point";
	setorigin(horde, actor.origin);
	self = actor;
	Test_Assert(AI_PathfindTarget(client) == 0, "Unreachable player fixture was pathable!");
	Test_Assert(PathfindToEnemy() != 0 && actor.enemy == horde, "Unreachable player did not fall back to a horde point!");
	Test_Assert(actor.path_goal_enemy == horde && actor.goalentity == horde, "Horde fallback did not install its path!");

	entity reachable = spawn();
	reachable.classname = "player";
	setorigin(reachable, actor.origin);
	actor.enemy = client;
	Test_Assert(PathfindToEnemy() != 0 && actor.enemy == reachable, "Another reachable player did not take priority over the horde point!");
	reachable.downed = true;
	actor.enemy = client;
	Test_Assert(PathfindToEnemy() != 0 && actor.enemy == horde, "Downed player displaced the horde fallback!");
	reachable.downed = false;
	reachable.is_spectator = true;
	actor.enemy = client;
	Test_Assert(PathfindToEnemy() != 0 && actor.enemy == horde, "Spectating player displaced the horde fallback!");
	remove(reachable);

	actor.enemy_timeout = time - 1;
	setorigin(client, actor.origin);
	actor.attack_delay = time + 10;
	Inside_Walk(10);
	Test_Assert(actor.enemy == client && actor.path_goal_enemy == client, "Horde zombie did not reacquire a newly reachable player!");
	client.downed = true;
	Test_Assert(find_new_enemy(actor) == horde, "Player spawn displaced an available horde point!");
	client.downed = false;
	setorigin(client, actor.origin + '0 0 4096');

	entity unreachable_horde = spawn();
	unreachable_horde.classname = "zombie_horde_point";
	setorigin(unreachable_horde, actor.origin + '0 0 4096');
	setorigin(horde, actor.origin);
	actor.enemy = client;
	Test_Assert(PathfindToEnemy() != 0 && actor.enemy == horde, "Unreachable horde point prevented a reachable fallback!");
	remove(unreachable_horde);

	entity fallback_spawn = spawn();
	fallback_spawn.classname = "info_player_1_spawn";
	setorigin(fallback_spawn, actor.origin);
	setorigin(horde, actor.origin + '0 0 4096');
	actor.enemy = client;
	Test_Assert(PathfindToEnemy() != 0 && actor.enemy == fallback_spawn, "Unreachable horde point prevented player-spawn fallback!");
	remove(fallback_spawn);
	remove(actor.goaldummy);
	remove(actor);
	remove(client);
	remove(horde);
	client = find(world, classname, "horde_test_client");

	while (client != world) {
		client.classname = "player";
		client = find(world, classname, "horde_test_client");
	}

	horde = find(world, classname, "horde_test_point");

	while (horde != world) {
		horde.classname = "zombie_horde_point";
		horde = find(world, classname, "horde_test_point");
	}

	self = old_self;
};

void() Test_AI_SwipeTiming =
{
	entity old_self = self;
	float old_time = time;
	entity target = spawn();
	entity actor = spawn();
	actor.head = spawn();
	actor.rarm = spawn();
	actor.larm = spawn();
	actor.classname = "ai_zombie";
	actor.health = 100;
	actor.enemy = target;
	actor.goalentity = target;
	actor.path_goal_enemy = target;
	actor.enemy_timeout = actor.path_target_update_time = time + 1000;
	actor.th_melee = zombie_attack;
	target.classname = "player";
	target.max_health = 1000;
	actor.th_walk = actor.th_idle = SUB_Null;
	target.solid = SOLID_BBOX;
	actor.respawn_timer = actor.bleedingtime = time + 1000;
	actor.head.deadflag = true;
	setorigin(actor, old_self.origin + '0 0 1024');
	setorigin(target, actor.origin);
	actor.path_goal_origin = target.origin;
	self = actor;

	for (float profile = 0; profile < zombie_swipes.length; profile++) {
		vector profile_hits = zombie_swipes[profile].hits;
		for (float side = 0; side < (profile_hits_y || profile >= 13 ? 1 : 2); side++) {
			time = old_time;
			actor.outside = profile >= 15;
			actor.crawling = profile >= 13 && profile < 15;
			target.health = target.max_health;
			Zombie_SwipeSetup(profile);
			float end_time = actor.swipe_end_time;
			float hit_time = actor.swipe_times_x;
			float slow = hit_time - time > 0.2;
			float hits = 0;
			float expected_hits = 0;
			vector frames = zombie_swipes[profile].hits;
			vector extra = zombie_swipes[profile].extra_hits;
			if (frames_x) expected_hits++;
			if (frames_y) expected_hits++;
			if (frames_z) expected_hits++;
			if (extra_x) expected_hits++;
			if (extra_y) expected_hits++;

			if (profile >= 15)
				Zombie_SwipeStart(zombie_attack_through_w1, 3);
			else if (profile >= 13)
				Zombie_SwipeStart(crawler_atk1, 3);
			else if (actor.swipe_times_y) {
				if (slow) Zombie_SwipeStart(zm_swipe_both_slow, 3);
				else Zombie_SwipeStart(zm_swipe_both_fast, 1);
			} else if (side) {
				if (slow) Zombie_SwipeStart(zm_swipe_left_slow, 3);
				else Zombie_SwipeStart(zm_swipe_left_fast, 1);
			} else {
				if (slow) Zombie_SwipeStart(zm_swipe_right_slow, 3);
				else Zombie_SwipeStart(zm_swipe_right_fast, 1);
			}

			float next_frame = actor.nextthink;
			time += clamp((next_frame - time) * 0.5, 0, 0.01);
			Inside_Walk(0);
			float uninterrupted = Test_Assert(actor.nextthink == next_frame, "AI update restarted an active swipe!");

			float steps = 0;
			float paced = true;
			while (uninterrupted && actor.is_attacking && steps < 100) {
				if (actor.nextthink <= time || actor.nextthink - time > 0.1001)
					paced = false;
				time = actor.nextthink;
				actor.think();
				if (actor.swipe_times_x != hit_time) {
					Test_Assert(fabs(time - hit_time) < 0.001, "Swipe damage did not occur at its scheduled time!");
					hit_time = actor.swipe_times_x;
					hits++;
				}
				steps++;
			}

			Test_Assert(paced, "Swipe animation was stretched or scheduled a non-advancing frame!");
			Test_Assert(!actor.is_attacking && hits == expected_hits, "Swipe sequence lost hits or did not finish!");
			Test_Assert(fabs(time - end_time) < 0.001, "Swipe recovery ended at the wrong time!");
			Test_Assert(target.health == target.max_health - expected_hits * (profile >= 15 ? ZOMBIE_DAMAGE_THROUGH_WINDOW : 50), "Swipe sequence did not damage the player!");
		}
	}

	time = old_time;
	remove(actor.head);
	remove(actor.rarm);
	remove(actor.larm);
	remove(actor);
	remove(target);
	self = old_self;
};

void() Test_AI_JumpingTarget =
{
	entity old_self = self;
	entity actor = spawn();
	entity target = spawn();
	actor.classname = "ai_zombie";
	actor.goaldummy = spawn();
	actor.enemy = target;
	target.classname = "player";
	target.health = 100;
	setsize(target, '-8 -8 -32', '8 8 40');
	vector ground = nzp_ai_land(actor, old_self.origin);
	setorigin(actor, ground);
	self = actor;

	for (float height = 0; height <= 64; height += 16) {
		target.flags = height == 0 ? FL_ONGROUND : 0;
		setorigin(target, ground + [0, 0, height]);
		actor.enemy = target;
		Test_Assert(nzp_can_walk_to_enemy(actor), "Jumping player lost direct pursuit!");
		Test_Assert(PathfindToEnemy() != 0 && actor.enemy == target, "Jumping player triggered an unreachable-target fallback!");
		Test_Assert(fabs(actor.path_goal_origin_z - ground_z) < 0.1, "Route anchor retained the player jump height!");
	}

	target.flags = FL_ONGROUND;
	setorigin(target, ground);
	Test_Assert(AI_PathTargetDistance() < 32, "Landing on the same floor triggered another route search!");
	target.flags = 0;
	setorigin(target, ground + '0 0 64');

	actor.enemy = target;
	actor.path_direct_retry_time = time + 10;
	Test_Assert(AI_PathfindTarget(target) >= 1, "Jumping player lost its waypoint route!");
	actor.path_direct_retry_time = 0;
	nzp_pathfind_clear(actor);
	vector approach = Get_First_Waypoint(actor, actor.origin, VEC_HULL_MIN, VEC_HULL_MAX);
	Test_Assert(fabs(approach_z - ground_z) < 20, "Route completion returned an airborne destination!");

	actor.path_status = 1;
	actor.path_goal_enemy = target;
	actor.path_goal_origin = ground;
	actor.path_target_update_time = time - 1;
	Test_Assert(!AI_PathNeedsUpdate(), "Jump height alone invalidated the route!");
	setorigin(target, target.origin + '96 0 0');
	Test_Assert(AI_PathNeedsUpdate(), "Airborne horizontal movement did not update the route!");
	setorigin(target, ground + '0 0 64');
	target.flags = FL_ONGROUND;
	Test_Assert(AI_PathNeedsUpdate(), "Landing on a higher floor did not update the route!");
	Test_Assert(!nzp_can_walk_to_enemy(actor), "Grounded elevated target was projected onto a lower floor!");

	remove(actor.goaldummy);
	remove(actor);
	remove(target);
	self = old_self;
};

void() Test_AI_ExplosiveDamage =
{
	float old_rounds = rounds;
	entity blast = spawn();
	entity victim = spawn();
	victim.classname = "ai_zombie";
	blast.classname = "grenade";
	rounds = 1;

	for (int i = 0; i < 4; i++) {
		victim.origin = blast.origin;
		float damage = Damage_ExplosiveDamage(blast, victim, 300, 75, 256);
		Test_Assert(damage >= 401 && damage < 501, "Point-blank grenade damage lost its base damage or round bonus!");
		victim.origin = blast.origin + '256 0 0';
		damage = Damage_ExplosiveDamage(blast, victim, 300, 75, 256);
		Test_Assert(damage >= 176 && damage < 276, "Grenade damage lost its distance falloff!");
	}

	victim.origin = blast.origin;
	blast.classname = "rocket";
	for (int i = 0; i < 4; i++) {
		float damage = Damage_ExplosiveDamage(blast, victim, 600, 75, 256);
		Test_Assert(damage >= 600 && damage < 700, "Rocket damage replaced its base damage with the round bonus!");
		damage = Damage_ExplosiveDamage(blast, victim, 1200, 75, 400);
		Test_Assert(damage >= 1200 && damage < 1300, "Upgraded rocket incorrectly multiplied the round bonus!");
	}

	rounds = 20;
	blast.classname = "projectile_grenade";
	for (int i = 0; i < 4; i++) {
		float damage = Damage_ExplosiveDamage(blast, victim, 1200, 1000, 75);
		Test_Assert(damage >= 1200 && damage < 3200, "Projectile grenade damage ignored round scaling!");
	}

	blast.classname = "projectile_raybeam";
	float damage = Damage_ExplosiveDamage(blast, victim, 1000, 1000, 64);
	Test_Assert(damage >= 1000 && damage < 3000, "Ray Gun damage lost its projectile round bonus!");
	blast.classname = "betty";
	damage = Damage_ExplosiveDamage(blast, victim, 12000, 11000, 128);
	Test_Assert(damage >= 14000 && damage < 16000, "Mine damage ignored its round-based bonus!");
	blast.classname = "player";
	victim.origin = blast.origin + '150 0 0';
	Test_Assert(Damage_ExplosiveDamage(blast, victim, 5000, 1000, 300) == 3000, "Flopper damage lost its distance falloff!");
	victim.classname = "func_breakable";
	blast.classname = "grenade";
	victim.origin = blast.origin;
	Test_Assert(Damage_ExplosiveDamage(blast, victim, 300, 75, 256) == 300, "Zombie round scaling leaked into non-AI damage!");

	rounds = 0;
	victim.classname = "ai_zombie";
	blast.classname = "projectile_raybeam";
	blast.weapon = W_RAY;
	blast.enemy = victim;
	Test_Assert(Damage_ExplosiveDamage(blast, victim, 1500, 300, 64) == 1000, "Ray Gun direct damage was replaced by splash damage!");
	blast.enemy = world;
	Test_Assert(Damage_ExplosiveDamage(blast, victim, 1500, 300, 64) == 1500, "A nearby zombie received the struck target's direct-hit damage!");
	victim.origin = blast.origin + '64 0 0';
	Test_Assert(Damage_ExplosiveDamage(blast, victim, 1500, 300, 64) == 300, "Ray Gun splash damage lost its distance falloff!");
	blast.classname = "projectile_grenade";
	blast.enemy = victim;
	Test_Assert(Damage_ExplosiveDamage(blast, victim, 1200, 75, 200) == 1000, "Mustang and Sally direct damage was replaced by splash damage!");

	remove(blast);
	remove(victim);
	rounds = old_rounds;
};

void() Test_AI_CrawlerEligibility =
{
	entity victim = spawn();
	victim.classname = "ai_zombie";
	victim.health = 1000;
	vector hit_origin = victim.origin - '0 0 24';

	Test_Assert(!Damage_CanMakeCrawler(victim, 99, hit_origin), "Sub-threshold damage made a crawler!");
	Test_Assert(Damage_CanMakeCrawler(victim, 100, hit_origin), "Exactly ten percent damage could not make a crawler!");
	Test_Assert(!Damage_CanMakeCrawler(victim, 1000, hit_origin), "Lethal damage could make a crawler!");
	Test_Assert(!Damage_CanMakeCrawler(victim, 100, victim.origin + '0 0 24'), "Upper-body explosion could remove the legs!");
	victim.crawling = 1;
	Test_Assert(!Damage_CanMakeCrawler(victim, 100, hit_origin), "An existing crawler was eligible for conversion again!");
	victim.crawling = 2;
	Test_Assert(!Damage_CanMakeCrawler(victim, 100, hit_origin), "A pending crawler was eligible for conversion again!");
	victim.crawling = 0;
	victim.classname = "ai_dog";
	Test_Assert(!Damage_CanMakeCrawler(victim, 100, hit_origin), "A hellhound was eligible to become a crawler!");
	remove(victim);
};

void() Test_AI_CrawlerConversion =
{
	entity old_self = self;
	float old_crawlers = crawler_num;
	float old_instakill = instakill_finished;
	instakill_finished = 0;
	entity actor = spawn();
	actor.classname = "ai_zombie";
	actor.health = 1000;
	actor.head = spawn();
	actor.larm = spawn();
	actor.rarm = spawn();
	actor.head.deadflag = true;
	actor.bleedingtime = time + 100;
	actor.enemy = spawn();
	actor.enemy.origin = actor.origin;
	actor.crawling = 2;
	actor.state = 1;

	DamageHandler(actor, world, 100, DMG_TYPE_GRENADE);
	Test_Assert(actor.crawling == 2 && actor.health == 900 && crawler_num == old_crawlers, "Deferred grenade conversion changed the model before traversal finished!");
	actor.is_attacking = true;
	actor.velocity = '150 100 0';
	actor.goalentity = spawn();
	actor.goalentity.hop_spot = old_self.origin;
	self = actor;
	zombie_hop10_5();
	self = old_self;
	Test_Assert(actor.crawling == 1 && actor.th_walk == Crawler_Walk_Setup && actor.think == crawlerify2, "Deferred crawler did not begin the conversion animation!");
	Test_Assert(!actor.is_attacking && actor.velocity_x == 0 && actor.velocity_y == 0, "Crawler conversion retained its standing attack or velocity!");
	makeCrawler(actor);
	Test_Assert(crawler_num == old_crawlers + 1, "Repeated conversion counted the crawler twice!");

	actor.crawling = 2;
	DamageHandler(actor, world, 100, DMG_TYPE_EXPLOSIVE);
	Test_Assert(actor.crawling == 1 && actor.health == 800, "Explosive-weapon damage did not begin crawler conversion!");
	actor.crawling = 2;
	DamageHandler(actor, world, 100, DMG_TYPE_GRENADE);
	Test_Assert(actor.crawling == 1 && actor.health == 700, "Grenade damage left a standing zombie pending conversion!");

	float converted = crawler_num;
	actor.crawling = 2;
	actor.th_die = SUB_Null;
	instakill_finished = time + 10;
	DamageHandler(actor, world, 1, DMG_TYPE_GRENADE);
	Test_Assert(crawler_num == converted && actor.crawling == 2, "Insta-Kill damage converted a zombie before killing it!");
	instakill_finished = 0;
	DamageHandler(actor, world, 1000, DMG_TYPE_EXPLOSIVE);
	Test_Assert(crawler_num == converted && actor.health <= 0, "Lethal explosive damage initiated crawler conversion!");

	remove(actor.head);
	remove(actor.larm);
	remove(actor.rarm);
	remove(actor.enemy);
	remove(actor.goalentity);
	remove(actor);
	self = old_self;
	crawler_num = old_crawlers;
	instakill_finished = old_instakill;
};

void() Test_AI_HellhoundTargeting =
{
	entity client = find(world, classname, "player");
	while (client != world) {
		client.classname = "dog_test_client";
		client = find(client, classname, "player");
	}

	entity dog = spawn();
	entity players[3];
	for (int i = 0; i < 3; i++) {
		players[i] = spawn();
		players[i].classname = "player";
		players[i].health = 100;
	}

	players[0].is_spectator = true;
	players[1].health = 0;
	dog.enemy = Dog_FindEnemy(dog);
	Test_Assert(dog.enemy == players[2] && players[2].hunt_count == 1, "Hellhound selected an invalid player or assigned its count to the spawner!");
	players[0].is_spectator = false;
	players[2].downed = true;
	dog.ads_release = true;
	dog.dog_run_check_time = time + 10;
	dog.enemy = Dog_FindEnemy(dog);
	Test_Assert(dog.enemy == players[0] && players[0].hunt_count == 1 && players[2].hunt_count == 0, "Hellhound retargeting corrupted the player hunt counts!");
	Test_Assert(!dog.ads_release && dog.dog_run_check_time == 0, "Hellhound retained its old target's charge state!");

	float old_remaining = Remaining_Zombies;
	float old_dogs = dogCount;
	dog.aistatus = "1";
	Dog_Death_Cleanup(dog);
	Dog_Death_Cleanup(dog);
	Test_Assert(players[0].hunt_count == 0 && dog.enemy == world, "Hellhound death did not release its preferred player!");
	Test_Assert(Remaining_Zombies == old_remaining - 1 && dogCount == old_dogs - 1, "Repeated hellhound cleanup changed the alive counts twice!");
	Remaining_Zombies = old_remaining;
	dogCount = old_dogs;

	for (int i = 0; i < 3; i++)
		remove(players[i]);
	remove(dog);
	client = find(world, classname, "dog_test_client");
	while (client != world) {
		client.classname = "player";
		client = find(client, classname, "dog_test_client");
	}
};

void() Test_AI_HellhoundCharge =
{
	entity old_self = self;
	entity dog = spawn();
	entity target = spawn();
	dog.classname = "ai_dog";
	dog.health = dog.max_health = 400;
	dog.sound_time = time + 10;
	dog.enemy = target;
	target.classname = "player";
	target.health = 100;
	setorigin(dog, old_self.origin);
	setorigin(target, dog.origin + '1000 0 0');
	self = dog;
	Dog_Think();
	Test_Assert(dog.walktype == 1 && !dog.ads_release, "Distant hellhound skipped stalking!");
	float next_check = dog.dog_run_check_time;
	dog.health = 399;
	Dog_Think();
	Test_Assert(!dog.ads_release && dog.dog_run_check_time == next_check, "Hellhound repeated its charge check before its scheduled update!");
	dog.dog_run_check_time = 0;
	Dog_Think();
	Test_Assert(dog.walktype == 2 && dog.ads_release, "Damaged hellhound did not charge!");
	dog.health = 400;
	dog.dog_run_check_time = 0;
	Dog_Think();
	Test_Assert(dog.walktype == 2 && dog.ads_release, "Charging hellhound reverted to stalking!");

	remove(dog);
	remove(target);
	self = old_self;
};

void() Test_AI_HellhoundPathRecovery =
{
	entity old_self = self;
	entity client = find(world, classname, "player");
	while (client != world) {
		client.classname = "dog_path_test_client";
		client = find(client, classname, "player");
	}

	entity dog = spawn();
	dog.classname = "ai_dog";
	dog.goaldummy = spawn();
	setsize(dog, '-16 -16 -32', '16 16 16');
	setorigin(dog, old_self.origin);
	entity unreachable = spawn();
	unreachable.classname = "player";
	unreachable.health = 100;
	unreachable.hunt_count = 1;
	setorigin(unreachable, dog.origin + '0 0 4096');
	entity dead_player = spawn();
	dead_player.classname = "player";
	setorigin(dead_player, dog.origin);
	entity reachable = spawn();
	reachable.classname = "player";
	reachable.health = 100;
	setorigin(reachable, dog.origin);
	dog.enemy = unreachable;
	dog.ads_release = true;
	self = dog;
	Test_Assert(AI_PathfindTarget(unreachable) == 0, "Hellhound recovery fixture was already pathable!");
	Test_Assert(PathfindToEnemy() != 0 && dog.enemy == reachable, "Hellhound did not recover from an unreachable preferred player!");
	Test_Assert(unreachable.hunt_count == 0 && reachable.hunt_count == 1, "Hellhound path recovery lost its target accounting!");
	Test_Assert(!dog.ads_release, "Hellhound path recovery retained the old target's charge state!");

	nzp_pathfind_clear(dog);
	remove(dog.goaldummy);
	remove(dog);
	remove(unreachable);
	remove(reachable);
	remove(dead_player);
	self = old_self;
	client = find(world, classname, "dog_path_test_client");
	while (client != world) {
		client.classname = "player";
		client = find(client, classname, "dog_path_test_client");
	}
};

void() Test_AI_CrawlerExplosion =
{
	float old_crawlers = crawler_num;
	float old_instakill = instakill_finished;
	float old_rounds = rounds;
	instakill_finished = 0;
	rounds = 1;
	entity actor = spawn();
	actor.classname = "ai_zombie";
	actor.health = 1000;
	actor.solid = SOLID_BBOX;
	actor.takedamage = DAMAGE_YES;
	actor.state = 1;
	setsize(actor, '-16 -16 -32', '16 16 40');
	setorigin(actor, self.origin + '0 0 64');
	entity blast = spawn();
	blast.classname = "grenade";
	setorigin(blast, actor.origin - '0 0 24');

	DamgageExplode(blast, world, 300, 75, 48);
	Test_Assert(actor.health > 0 && actor.health < 1000 && actor.crawling == 2, "A surviving zombie did not enter pending crawler state from an actual grenade explosion!");
	Test_Assert(crawler_num == old_crawlers, "Explosion converted a zombie while its traversal was still active!");
	remove(actor);
	remove(blast);
	crawler_num = old_crawlers;
	instakill_finished = old_instakill;
	rounds = old_rounds;
};

void() Test_AI_HellhoundSeparation =
{
	entity old_self = self;
	entity dog = spawn();
	entity other_dog = spawn();
	entity goal = spawn();
	dog.classname = other_dog.classname = "ai_dog";
	dog.aistatus = other_dog.aistatus = "1";
	dog.health = other_dog.health = 400;
	dog.flags = other_dog.flags = FL_ONGROUND;
	setorigin(dog, nzp_ai_land(dog, old_self.origin));
	setorigin(other_dog, dog.origin + '40 0 0');
	setorigin(goal, dog.origin + '200 0 0');
	dog.enemy = other_dog.enemy = goal;
	dog.crowd_neighbors[0] = other_dog;
	other_dog.crowd_neighbors[0] = dog;
	dog.crowd_update_time = other_dog.crowd_update_time = time + 10;
	self = dog;

	vector result = Dog_SeparationVelocity('200 0 0', true);
	Test_Assert(result_x >= 0 && vlen(result) <= 200.01, "Dog separation reversed pursuit or exceeded its movement speed!");
	Test_Assert(result_y != 0 && result_x < 200, "Dog passing did not make room for the dog ahead!");

	setorigin(other_dog, dog.origin);
	result = Dog_SeparationVelocity('200 0 0', true);
	self = other_dog;
	vector opposite = Dog_SeparationVelocity('200 0 0', true);
	Test_Assert(result_y * opposite_y < 0, "Coincident dogs chose the same separation direction!");
	self = dog;
	setorigin(other_dog, dog.origin + '40 0 0');
	result = Dog_SeparationVelocity('200 0 0', true);
	self = other_dog;
	opposite = Dog_SeparationVelocity('-200 0 0', true);
	Test_Assert(result_y * opposite_y < 0, "Oncoming dogs chose the same side of the hallway!");
	self = dog;

	result = Dog_SeparationVelocity('0 0 0', true);
	Test_Assert(result_x == 0 && vlen(result) <= 80.01, "Idle dog separation pushed it into its target!");
	other_dog.aistatus = "0";
	Test_Assert(Dog_SeparationVelocity('200 0 0', true) == '200 0 0', "A dead dog continued blocking pursuit!");
	Test_Assert(Dog_SeparationVelocity('0 0 0', true) == '0 0 0', "An isolated idle dog kept moving!");
	dog.crowd_update_time = 0;
	Dog_SeparationVelocity('200 0 0', true);
	Test_Assert(dog.crowd_update_time == 0, "Cached dog steering repeated the neighbor search!");
	Dog_SeparationVelocity('200 0 0', false);
	Test_Assert(dog.crowd_update_time > time, "Scheduled dog steering did not refresh its neighbors!");

	remove(dog);
	remove(other_dog);
	remove(goal);
	self = old_self;
};

void() Test_AI_DogMeleeCount =
{
	self.cnt++;
};

void() Test_AI_HellhoundLunge =
{
	entity old_self = self;
	float old_nuke = nuke_powerup_active;
	nuke_powerup_active = 0;
	entity dog = spawn();
	entity target = spawn();
	dog.classname = "ai_dog";
	dog.owner = old_self;
	dog.health = dog.max_health = 400;
	dog.flags = FL_ONGROUND;
	dog.sound_time = time + 10;
	dog.enemy = target;
	dog.goaldummy = spawn();
	setsize(dog, '-16 -16 -32', '16 16 18');
	setorigin(dog, nzp_ai_land(dog, old_self.origin));
	target.classname = "player";
	target.health = target.max_health = 100;
	target.solid = SOLID_BBOX;
	setsize(target, '-16 -16 -24', '16 16 32');

	vector directions[4] = {'1 0 0', '-1 0 0', '0 1 0', '0 -1 0'};
	vector direction = '0 0 0';
	for (int i = 0; i < 4; i++) {
		traceline(dog.origin + '0 0 8', dog.origin + directions[i] * 80, true, dog);
		if (trace_startsolid || trace_fraction < 1)
			continue;
		tracebox(dog.origin + '0 0 0.03125', dog.mins, dog.maxs, dog.origin + directions[i] * 30 + '0 0 0.03125', false, dog);
		if (!trace_startsolid && !trace_allsolid && trace_fraction == 1) {
			direction = directions[i];
			break;
		}
	}

	if (direction == '0 0 0') {
		Test_Skip("Spawn has no clear space for the lunge fixture.");
	} else {
		setorigin(target, dog.origin + direction * 80);
		dog.angles_y = vectoyaw(direction);
		self = dog;
		dog.th_melee = Test_AI_DogMeleeCount;
		dog.enemy_timeout = time + 100;
		entity blocker = spawn();
		blocker.classname = "ai_dog";
		blocker.solid = SOLID_CORPSE;
		setsize(blocker, '-16 -16 -32', '16 16 18');
		setorigin(blocker, dog.origin + direction * 40);
		dog.goalentity = target;
		dog.chase_enemy_time = time + 100;
		traceline(dog.origin + '0 0 8', target.origin, false, dog);
		Test_Assert(trace_ent == blocker, "Lunge fixture did not place its blocker in front of the dog!");
		Inside_Walk(0);
		Test_Assert(dog.cnt == 0, "Dog started a lunge through another dog's body!");
		remove(blocker);
		Inside_Walk(0);
		Test_Assert(dog.cnt == 1, "A clear target did not allow the dog to attack!");
		dog.th_melee = Dog_Attack;
		Dog_Attack();
		Test_Assert(dog.is_attacking && dog.movetype == MOVETYPE_TOSS && !(dog.flags & FL_ONGROUND) && dog.velocity_z == 160, "Dog attack did not launch a committed hop!");
		Test_Assert(dog.velocity * direction > 0 && dog.think == dog_meleeanim2, "Dog attack did not launch toward its target!");
		Hellhound_AI();
		Test_Assert(dog.think == dog_meleeanim2, "Path following interrupted the lunge!");
		dog_meleeanim2();
		Test_Assert(dog.velocity * direction > 0, "The second attack frame canceled the lunge velocity!");
		setorigin(target, dog.origin + direction * 40);
		Dog_LungeMove();
		Test_Assert(dog.velocity * direction < 100, "The lunge ignored the player's collision hull!");

		setorigin(target, dog.origin + direction * 50);
		Dog_Bite();
		Test_Assert(target.health == 60, "Lunge bite changed the hellhound's 40 damage!");
		target.downed = true;
		Dog_Bite();
		Test_Assert(target.health == 60, "Lunge bite damaged a downed player!");
		dog.velocity = '0 0 0';
		Dog_AttackFinish();
		Test_Assert(!dog.is_attacking && dog.movetype == MOVETYPE_WALK, "Lunge recovery did not restore normal walking physics!");
	}

	remove(dog.goaldummy);
	remove(dog);
	remove(target);
	self = old_self;
	nuke_powerup_active = old_nuke;
};
