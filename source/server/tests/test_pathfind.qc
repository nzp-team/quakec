/*
	server/tests/test_pathfind.qc

	RUNTIME (not unit) tests for Pathfinding debugging.
	Invoked via commands.

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

float pathfind_test_stage;
float pathfind_test_direct;
float pathfind_test_count;
float pathfind_test_source;
float pathfind_test_destination;
float pathfind_test_source_filter;
float pathfind_test_destination_filter;
float pathfind_test_started;
float pathfind_test_deadline;
float pathfind_test_progress_time;
float pathfind_test_walks;
float pathfind_test_skipped;
vector pathfind_test_progress_origin;
entity pathfind_test_actor;
entity pathfind_test_goal;
entity pathfind_test_dummy;

void() Pathfind_TestIgnoreBrushes =
{
	for (entity brush = nextent(world); brush != world; brush = nextent(brush)) {
		if (brush.solid != SOLID_BSP || brush.movetype != MOVETYPE_PUSH)
			continue;

		string reason = "";

		if (brush.teddyremovetarget != "")
			reason = strcat("teddyremovetarget:", brush.teddyremovetarget);
		else if (brush.targetname != "")
			reason = strcat("targetname:", brush.targetname);
		else if (brush.killtarget != "")
			reason = strcat("killtarget:", brush.killtarget);
		else if (brush.classname == "door" || substring(brush.classname, 0, 5) == "door_")
			reason = "door";

		if (reason == "")
			continue;

		nzp_pathfind_test(12, 0, 0, 0, brush.origin, '0 0 0', brush, reason);
		print(sprintf("[INFO] Ignoring gameplay brush: %s %s (%s)\n", brush.classname, brush.model, reason));
	}
}

void() Pathfind_TestThink;
void(float outcome) Pathfind_TestRecord;

void() Pathfind_TestLand =
{
	self.think = Pathfind_TestThink;
	self.nextthink = time + 0.7;
}

void() Pathfind_TestFalling =
{
	if (!pathfind_test_running || pathfind_test_stage != 2)
		return;

	self.nextthink = time + 0.1;
	CheckLand();
}

void() Pathfind_TestFall =
{
	nzp_pathfind_test(7, pathfind_test_source, pathfind_test_destination, 0, self.origin);
	print(sprintf("[INFO] Zombie fall: %g -> %g, at (%g, %g, %g)\n", pathfind_test_source, pathfind_test_destination, self.origin_x, self.origin_y, self.origin_z));
	self.fall = true;
	self.think = Pathfind_TestFalling;
	CheckLand();
}

void() Pathfind_TestThink =
{
	if (!pathfind_test_running || pathfind_test_stage != 2)
		return;

	self.nextthink = time + 0.1;

	if (!pathfind_test_started) {
		pathfind_test_started = true;

		if (nzp_pathfind_test(9, 0, 0, 0, self.origin) == 0) {
			Pathfind_TestRecord(-4);
			return;
		}

		if (!pathfind_test_direct && (self.flags & FL_ONGROUND) && vlen(self.origin - pathfind_test_goal.origin) < 60) {
			Pathfind_TestRecord(1);
			return;
		}

		if (pathfind_test_direct) {
			nzp_pathfind_test(11, pathfind_test_source, pathfind_test_destination);
			setorigin(self.goaldummy, pathfind_test_goal.origin);
			self.goalentity = self.goaldummy;
		} else if (PathfindToEnemy() == 0) {
			Pathfind_TestRecord(-5);
			return;
		}
	}

	if (!pathfind_test_direct)
		Inside_Walk(0);
	Zombie_Walk(13);

	if (cvar("developer") == 3)
		print(sprintf("[DEBUG] Walk origin (%g, %g, %g), goal (%g, %g, %g), velocity_z %g\n", self.origin_x, self.origin_y, self.origin_z, self.goalentity.origin_x, self.goalentity.origin_y, self.goalentity.origin_z, self.velocity_z));

}

void() Pathfind_TestAdvance =
{
	if (pathfind_test_destination_filter >= 0 || ++pathfind_test_destination >= pathfind_test_count) {
		pathfind_test_destination = pathfind_test_destination_filter < 0 ? 0 : pathfind_test_destination_filter;
		pathfind_test_source++;

		if (pathfind_test_source_filter >= 0)
			pathfind_test_source = pathfind_test_count;
	}

	pathfind_test_stage = 1;
}

void(float outcome) Pathfind_TestRecord =
{
	if (outcome != 1 && cvar("developer") == 3) {
		vector direction = pathfind_test_actor.goalentity.origin - pathfind_test_actor.origin;
		direction_z = 0;
		tracebox(pathfind_test_actor.origin, '-16 -16 -32', '16 16 40', pathfind_test_actor.origin + normalize(direction) * 32, true, pathfind_test_actor);
		print(sprintf("[DEBUG] Movement blocker %s, model %s, fraction %g, origin %s\n", trace_ent.classname, trace_ent.model, trace_fraction, vtos(trace_ent.origin)));
	}

	nzp_pathfind_test(5, pathfind_test_source, pathfind_test_destination, outcome, pathfind_test_actor.origin, pathfind_test_actor.goalentity.origin, pathfind_test_actor);
	pathfind_test_walks++;
	print(sprintf("%s Zombie walk: %g -> %g, outcome %g, stopped at (%g, %g, %g)\n", outcome == 1 ? "[PASS]" : "[FAIL]", pathfind_test_source, pathfind_test_destination, outcome, pathfind_test_actor.origin_x, pathfind_test_actor.origin_y, pathfind_test_actor.origin_z));
	pathfind_test_actor.velocity = '0 0 0';
	pathfind_test_actor.think = SUB_Null;
	pathfind_test_actor.nextthink = -1;
	pathfind_test_actor.solid = SOLID_NOT;
	Pathfind_TestAdvance();
}

void() Pathfind_TestFinish =
{
	float passed = nzp_pathfind_test(6);

	if (pathfind_test_actor != world) {
		nzp_pathfind_clear(pathfind_test_actor);
		remove(pathfind_test_actor);
	}

	if (pathfind_test_goal != world)
		remove(pathfind_test_goal);

	if (pathfind_test_dummy != world)
		remove(pathfind_test_dummy);
	pathfind_test_actor = pathfind_test_goal = pathfind_test_dummy = world;
	pathfind_test_running = false;
	print(sprintf("Zombie walk summary: %g attempted, %g closed or unreachable pairs skipped.\n", pathfind_test_walks, pathfind_test_skipped));

	if (passed == 1)
		print("Pathfind test command passed.\n");
	else
		print("Pathfind test command failed.\n");

	if (cvar("pathfind_test_exit") == 1)
		localcmd("quit\n");
}

float() Pathfind_TestCommandFailure =
{
	if (cvar("pathfind_test_exit") == 1)
		localcmd("quit\n");
	return COMMAND_FAILURE;
}

float(string params) Pathfind_TestBegin =
{
	if (params == "stop") {
		if (!pathfind_test_running)
			return Pathfind_TestCommandFailure();

		if (pathfind_test_stage == 2)
			Pathfind_TestRecord(-3);
		else
			nzp_pathfind_test(8);
		Pathfind_TestFinish();
		return COMMAND_SUCCESS;
	}

	if (pathfind_test_running || waypoint_mode) {
		print("Pathfind tests require normal play mode and no active test.\n");
		return Pathfind_TestCommandFailure();
	}

	pathfind_test_source_filter = pathfind_test_destination_filter = -1;

	float edges = params == "edges";
	pathfind_test_direct = argv(3) == "direct";

	if (edges)
		pathfind_test_direct = true;
	pathfind_test_count = nzp_pathfind_test(2);

	if (params != "" && !edges) {
		if (argv(2) == "") {
			print("Usage: pathfind_test [source destination [direct]], pathfind_test edges, or pathfind_test stop\n");
			return Pathfind_TestCommandFailure();
		}

		pathfind_test_source_filter = stof(argv(1));
		pathfind_test_destination_filter = stof(argv(2));

		if (pathfind_test_source_filter < 0 || pathfind_test_source_filter >= pathfind_test_count || pathfind_test_destination_filter < 0 || pathfind_test_destination_filter >= pathfind_test_count || floor(pathfind_test_source_filter) != pathfind_test_source_filter || floor(pathfind_test_destination_filter) != pathfind_test_destination_filter)
			return Pathfind_TestCommandFailure();
	}

	if (nzp_pathfind_test(0) != 1)
		return Pathfind_TestCommandFailure();

	Pathfind_TestIgnoreBrushes();

	if (pathfind_test_direct)
		nzp_pathfind_test(10, edges);
	pathfind_test_source = pathfind_test_source_filter < 0 ? 0 : pathfind_test_source_filter;
	pathfind_test_destination = pathfind_test_destination_filter < 0 ? 0 : pathfind_test_destination_filter;
	pathfind_test_stage = pathfind_test_walks = pathfind_test_skipped = 0;
	pathfind_test_actor = pathfind_test_goal = pathfind_test_dummy = world;
	pathfind_test_running = true;
	return COMMAND_SUCCESS;
}

void() Pathfind_TestFrame =
{
	if (!pathfind_test_running)
		return;

	if (pathfind_test_stage == 0) {
		float status = nzp_pathfind_test(1);

		if (status == 0)
			return;

		if (status < 0) {
			Pathfind_TestFinish();
			return;
		}

		pathfind_test_actor = spawn();
		pathfind_test_dummy = spawn();
		pathfind_test_goal = spawn();
		pathfind_test_actor.classname = "ai_zombie";
		pathfind_test_actor.aistatus = "0";
		pathfind_test_actor.movetype = MOVETYPE_WALK;
		pathfind_test_actor.goaldummy = pathfind_test_dummy;
		pathfind_test_actor.enemy = pathfind_test_goal;
		pathfind_test_actor.walktype = 5;
		pathfind_test_actor.health = 100;
		pathfind_test_actor.takedamage = DAMAGE_NO;
		pathfind_test_actor.th_melee = SUB_Null;
		pathfind_test_actor.th_fall = Pathfind_TestFall;
		pathfind_test_actor.th_land = Pathfind_TestLand;
		pathfind_test_goal.classname = "pathfind_test_goal";
		pathfind_test_goal.health = 1;
		setmodel(pathfind_test_actor, "models/ai/zb%.mdl");

		if (map_compatibility_mode == MAP_COMPAT_BETA)
			setsize(pathfind_test_actor, '-6 -6 -24', '6 6 22');
		else
			setsize(pathfind_test_actor, '-8 -8 -32', '8 8 30');
		pathfind_test_stage = 1;
	}

	if (pathfind_test_stage == 1) {
		float checked = 0;
		float cost = -1;

		while (pathfind_test_source < pathfind_test_count && checked < 32) {
			cost = nzp_pathfind_test(4, pathfind_test_source, pathfind_test_destination);

			if (cost >= 0)
				break;

			pathfind_test_skipped++;
			Pathfind_TestAdvance();
			checked++;
		}

		if (pathfind_test_source >= pathfind_test_count) {
			Pathfind_TestFinish();
			return;
		}

		if (checked == 32)
			return;

		nzp_pathfind_clear(pathfind_test_actor);
		setorigin(pathfind_test_actor, nzp_pathfind_origin(pathfind_test_source, pathfind_test_actor));
		setorigin(pathfind_test_goal, nzp_pathfind_origin(pathfind_test_destination, pathfind_test_actor));
		setorigin(pathfind_test_dummy, '0 0 0');
		pathfind_test_actor.goalentity = pathfind_test_dummy;
		pathfind_test_actor.flags = FL_PARTIALGROUND | FL_MONSTER;
		pathfind_test_actor.velocity = '0 0 0';
		pathfind_test_actor.enemy_timeout = time + 1000000;
		pathfind_test_actor.attack_delay = time + 1000000;
		pathfind_test_actor.chase_time = 0;
		pathfind_test_actor.chase_enemy_time = 0;
		pathfind_test_actor.path_progress_origin = pathfind_test_actor.origin;
		pathfind_test_actor.path_progress_time = time;
		pathfind_test_actor.path_retry_time = 0;
		pathfind_test_actor.path_direct_retry_time = 0;
		pathfind_test_actor.path_move_time = 0;
		pathfind_test_actor.path_move_direction = '0 0 0';
		pathfind_test_actor.path_move_origin = pathfind_test_actor.origin;
		pathfind_test_actor.droptime = 0;
		pathfind_test_actor.fall = false;
		pathfind_test_actor.solid = SOLID_CORPSE;
		pathfind_test_actor.think = Pathfind_TestThink;
		pathfind_test_actor.nextthink = time + 0.2;
		pathfind_test_deadline = time + (cost / 65 + 10 < 30 ? 30 : cost / 65 + 10);
		pathfind_test_progress_time = time;
		pathfind_test_progress_origin = pathfind_test_actor.origin;
		pathfind_test_started = 0;
		pathfind_test_stage = 2;
		return;
	}

	if (pathfind_test_stage == 2) {
		vector delta = pathfind_test_actor.origin - pathfind_test_goal.origin;

		if (pathfind_test_started && (pathfind_test_actor.flags & FL_ONGROUND) && (pathfind_test_direct ? (vlen(delta - '0 0 1' * delta_z) < 4 && fabs(delta_z) < 20) : vlen(delta) < 60)) {
			Pathfind_TestRecord(1);
			return;
		}

		if (vlen(pathfind_test_actor.origin - pathfind_test_progress_origin) >= 4) {
			pathfind_test_progress_origin = pathfind_test_actor.origin;
			pathfind_test_progress_time = time;
		}

		if (time - pathfind_test_progress_time >= 4)
			Pathfind_TestRecord(0);
		else if (time >= pathfind_test_deadline)
			Pathfind_TestRecord(-1);
	}
}
