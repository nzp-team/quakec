/*
	server/ai/ai_core.qc

	ai stuff

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

void(float type) Zombie_PlaySoundType;
void() LinkZombiesHitbox;
entity(entity dog) Dog_FindEnemy;
vector(vector wish_velocity, optional float reuse) Dog_SeparationVelocity;
void() AI_ResetPath;

float(float current_dist, string ai_classname) Gamemode_GetAIWalkSpeed;

void() path_corner_touch =
{
	self.origin_z = self.origin_z + 32;
	setorigin(self, self.origin);
	self.classname = "path_corner";
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	self.touch = SUB_Null;
	setsize(self, '0 0 0 ', '0 0 0');
	if(!self.target)
	{
		if (self.spawnflags & 1)
			return;
		bprint(PRINT_HIGH, "path_corner with name: ");
		bprint(PRINT_HIGH, self.targetname);
		bprint(PRINT_HIGH, " has no target!\n");
	}
}

//We want the path corner to drop to the ground and then we set it up 32 units so it's exact
void() path_corner =
{
	self.classname = "path_corner_set";
	self.movetype = MOVETYPE_BOUNCE;
	self.solid = SOLID_BBOX;
	self.touch = path_corner_touch;
	setsize(self, '0 0 0 ', '0 0 0');
};

void() Respawn = 
{
	// cypress (20 dec 2023) -- whoever wrote this originally wasn't considering
	// many factors.. if a zombie respawns there's a chance it'll be in a 
	// completely different playspace, where the initial window isn't visible
	// at all, and removeZombie() does not clear that field (rightfully so).
	// so i've replaced this with the same function i use to respawn zombies
	// inside of the playable area, which calls self.th_die() and fibs to the
	// zombie counter a little better, fixes that issue.

	// Kill it.
	self.th_die();

	// This is a pseudo-hack that just tells the rounds core that we should
	// spawn another.
	Current_Zombies--;
	Remaining_Zombies++;
};

entity(entity blarg) find_new_enemy =
{
	entity  targets;
	entity  best_target;
	float 	best_distance;
	float 	distance;
	
	best_distance = 10000;
	best_target = world;

	if (blarg.classname == "ai_zombie" || blarg.classname == "ai_dog") {
		// Monkey Bomb (TODO -- if multiple, target first one thrown)
		targets = find(world, classname, "monkey_bomb");
		if (targets != world && blarg.classname != "ai_dog") {
			best_target = targets;
			return best_target;
		}

		// Now, try and find a viable player
		targets = find(world, classname, "player");

		while(targets != world) {
			// Don't target downed players.
			if (targets.downed == true || targets.is_spectator == true) {
				targets = find(targets, classname, "player");
				continue;
			}

			// Found one, let's see if it's closer than our last ideal target.
			distance = vlen(blarg.origin - targets.origin);

			if (distance < best_distance) {
				best_target = targets;
				best_distance = distance;
			}

			// Continue iterating
			targets = find(targets, classname, "player");
		}

		// Return a good player if we found one.
		if (best_target != world)
			return best_target;

		// We couldn't find a good player. How about a horde point?
		targets = find(world, classname, "zombie_horde_point");

		while(targets != world) {
			// Found one, let's see if it's closer than our last ideal target.
			distance = vlen(blarg.origin - targets.origin);

			if (distance < best_distance) {
				best_target = targets;
				best_distance = distance;
			}

			// Continue iterating
			targets = find(targets, classname, "zombie_horde_point");
		}

		if (best_target != world)
			return best_target;

		// Last chance -- try a player spawn point.
		targets = find(world, classname, "info_player_1_spawn");

		while(targets != world) {
			// Found one, let's see if it's closer than our last ideal target.
			distance = vlen(blarg.origin - targets.origin);

			if (distance < best_distance) {
				best_target = targets;
				best_distance = distance;
			}

			// Continue iterating
			targets = find(targets, classname, "info_player_1_spawn");
		}

		// Return a horde point if we found one.
		if (best_target != world)
			return best_target;
	}

	// We didn't have much luck, just return the world.
	return best_target;
};

void() AI_UpdateCrowd =
{
	entity neighbors[4];
	float distances[4];

	for (int i = 0; i < 4; i++) {
		neighbors[i] = world;
		distances[i] = 4096;
	}

	entity actor = findradius(self.origin, 64, self.classname);

	while (actor != world) {
		entity next = actor.chain;

		if (actor == self || actor.classname != self.classname) {
			actor = next;
			continue;
		}

		if (actor.aistatus == "1" && actor.health > 0 && actor.outside == false && !actor.fall) {
			if (fabs(actor.origin_z - self.origin_z) >= 24) {
				actor = next;
				continue;
			}

			vector delta = actor.origin - self.origin;
			delta_z = 0;

			float distance = delta * delta;

			for (int i = 0; i < 4; i++) {
				if (distance >= distances[i])
					continue;

				for (int j = 3; j > i; j--) {
					neighbors[j] = neighbors[j - 1];
					distances[j] = distances[j - 1];
				}

				neighbors[i] = actor;
				distances[i] = distance;
				break;
			}
		}

		actor = next;
	}

	for (int i = 0; i < 4; i++) {
		actor = neighbors[i];

		if (actor != world) {
			traceline(self.origin, actor.origin, true, self);

			if (trace_startsolid || trace_fraction < 1)
				actor = world;
		}

		self.crowd_neighbors[i] = actor;
	}

	self.crowd_update_time = time + 0.2;
}

vector(vector wish_velocity, optional float speed) AI_CrowdWishVelocity =
{
	if (self.classname != "ai_zombie" || self.outside != false || self.fall || !(self.flags & FL_ONGROUND))
		return wish_velocity;

	if (speed == 0)
		speed = vlen(wish_velocity);

	if (speed == 0)
		return wish_velocity;

	if (self.crowd_progress_time == 0 || vlen(self.origin - self.crowd_progress_origin) >= 4) {
		self.crowd_progress_origin = self.origin;
		self.crowd_progress_time = time;
	}

	if (time >= self.crowd_update_time)
		AI_UpdateCrowd();

	vector path_direction = wish_velocity / speed;
	vector side = [-path_direction_y, path_direction_x, 0];
	vector separation = '0 0 0';
	float limit = speed;
	float pressure_ahead = 0;
	entity blocker = world;
	float blocker_side = 0;

	for (int i = 0; i < 4; i++) {
		entity actor = self.crowd_neighbors[i];

		if (actor == world)
			continue;

		if (actor.classname != "ai_zombie" || actor.aistatus != "1" || actor.health <= 0 || actor.outside != false || actor.fall)
			continue;

		if (fabs(actor.origin_z - self.origin_z) >= 24)
			continue;

		vector delta = actor.origin - self.origin;
		delta_z = 0;

		float distance_squared = delta * delta;

		if (distance_squared >= 4096)
			continue;

		float ahead = delta * path_direction;
		float lateral = delta * side;

		if (ahead > 0 && fabs(lateral) < 28 && actor.path_move_direction * path_direction > 0.5) {
			float other_speed = actor.velocity * path_direction;
			float spacing = sqrt(1406.25 - lateral * lateral);
			float following_speed = clamp(other_speed + (ahead - spacing) * 3, 0, speed);

			if (following_speed < limit)
				limit = following_speed;

			float closing = clamp(speed - other_speed, 0, speed);
			float pressure = clamp((48 - ahead + closing * 0.3) / 32, 0, 1) * (1 - fabs(lateral) / 28);

			if (pressure > pressure_ahead) {
				pressure_ahead = pressure;
				blocker = actor;
				blocker_side = lateral;
			}
		}

		if (distance_squared >= 1406.25)
			continue;

		float distance = vlen(delta);
		vector away;

		if (distance < 1) {
			away = side * ((int)self < (int)actor ? -1 : 1);
		} else {
			away = -delta / distance;

			if (distance < 32 && fabs(lateral) < 4)
				away += side * ((int)self < (int)actor ? -1 : 1);
		}

		separation += away * (1 - distance / 37.5);
	}

	entity passing = self.crowd_blocker;

	if (passing != world) {
		if ((blocker == world || blocker == passing) && passing.classname == "ai_zombie" && passing.aistatus == "1" && passing.health > 0 && passing.outside == false && !passing.fall && fabs(passing.origin_z - self.origin_z) < 24 && passing.path_move_direction * path_direction > 0.5) {
			vector delta = passing.origin - self.origin;
			delta_z = 0;

			float ahead = delta * path_direction;
			float lateral = fabs(delta * side);
			float closing = speed - passing.velocity * path_direction;

			if (ahead > -16 && ahead < 64 && lateral >= 24 && lateral < 48 && closing > 16) {
				blocker = passing;

				float pass_pressure = clamp((48 - lateral) / 16, 0, 1) * clamp(closing / 64, 0, 1);

				if (pass_pressure > pressure_ahead)
					pressure_ahead = pass_pressure;
			}
		}
	}

	if (blocker != world) {
		if (self.crowd_blocker != blocker || self.crowd_avoid_side == 0) {
			self.crowd_blocker = blocker;
			self.crowd_avoid_side = fabs(blocker_side) >= 4 ? (blocker_side > 0 ? -1 : 1) : ((int)self & 1 ? -1 : 1);
		}

		float approach = self.enemy != world ? clamp((vlen(self.enemy.origin - self.origin) - 60) / 180, 0, 1) : 1;
		separation += side * self.crowd_avoid_side * pressure_ahead * approach;
	} else {
		self.crowd_blocker = world;
		self.crowd_avoid_side = 0;
	}

	if (separation == '0 0 0' && limit == speed)
		return wish_velocity;

	float pressure = vlen(separation);

	if (pressure > 1)
		separation /= pressure;

	vector result = path_direction * limit + separation * speed * 0.75;

	if (time - self.crowd_progress_time >= 1 && result * path_direction < speed * 0.2)
		result += path_direction * (speed * 0.2 - result * path_direction);

	float length = vlen(result);

	if (length > speed)
		result *= speed / length;
	return result;
}

float(vector velocity, optional float flat_traced) AI_CrowdCanMove =
{
	vector start = self.origin + '0 0 0.03125';
	vector end = start + velocity * 0.1;

	if (!flat_traced)
		tracebox(start, '-16 -16 -32', '16 16 40', end, true, self);

	if (trace_startsolid || trace_allsolid)
		return false;

	if (trace_fraction < 1 && trace_plane_normal_z <= 0.7) {
		tracebox(start, '-16 -16 -32', '16 16 40', start + '0 0 20', true, self);

		if (trace_startsolid || trace_allsolid)
			return false;

		vector raised_start = trace_endpos;
		vector raised_end = end;
		raised_end_z = raised_start_z;
		tracebox(raised_start, '-16 -16 -32', '16 16 40', raised_end, true, self);

		if (trace_startsolid || trace_allsolid || trace_fraction < 1)
			return false;
	}

	return tracemove(self.origin, '-16 -16 -32', '16 16 40', self.origin + velocity * 0.1, true, self);
}

vector(vector wish_velocity, optional float speed) AI_CrowdCachedWishVelocity =
{
	if (self.crowd_wish_time <= 0 || time - self.crowd_wish_time > 1 || self.enemy != self.crowd_wish_enemy)
		return wish_velocity;

	if (vlen(self.origin - self.crowd_wish_origin) > 64)
		return wish_velocity;

	if (speed == 0)
		speed = vlen(wish_velocity);

	if (speed == 0)
		return wish_velocity;

	vector heading = wish_velocity / speed;

	if (heading * self.crowd_wish_heading < 0.5)
		return wish_velocity;

	vector side = [-heading_y, heading_x, 0];
	return (heading * self.crowd_wish_factors_x + side * self.crowd_wish_factors_y) * speed;
}

vector(vector wish_velocity, optional float reuse) AI_CrowdVelocity =
{
	if (self.classname != "ai_zombie" || self.outside != false || self.fall || !(self.flags & FL_ONGROUND) || wish_velocity == '0 0 0')
		return wish_velocity;

	float speed = vlen(wish_velocity);
	vector path_direction = wish_velocity / speed;
	vector side = [-path_direction_y, path_direction_x, 0];
	vector result;

	if (reuse) {
		result = AI_CrowdCachedWishVelocity(wish_velocity, speed);
	} else {
		result = AI_CrowdWishVelocity(wish_velocity, speed);
		self.crowd_wish_factors = [result * path_direction / speed, result * side / speed, 0];
		self.crowd_wish_heading = path_direction;
		self.crowd_wish_origin = self.origin;
		self.crowd_wish_time = time;
		self.crowd_wish_enemy = self.enemy;
	}

	if (result == '0 0 0')
		return result;

	if (self.velocity_z < 0 && self.goalentity != world && self.goalentity.origin_z < self.origin_z - 20)
		return result;

	float flat_traced = false;

	if (result == wish_velocity || (fabs(result * side) < 0.1 && result * path_direction >= 0)) {
		vector start = self.origin + '0 0 0.03125';
		tracebox(start, '-16 -16 -32', '16 16 40', start + result * 0.1, true, self);
		flat_traced = true;

		if (!trace_startsolid && !trace_allsolid && trace_fraction == 1)
			return result;
	}

	if (AI_CrowdCanMove(result, flat_traced))
		return result;

	vector alternate = result - side * (result * side) * 2;

	if (alternate != result) {
		if (AI_CrowdCanMove(alternate)) {
			self.crowd_avoid_side = -self.crowd_avoid_side;
			self.crowd_wish_factors_y = -self.crowd_wish_factors_y;
			return alternate;
		}
	}

	vector forward_velocity = path_direction * clamp(result * path_direction, 0, speed);

	if (forward_velocity != result || alternate != result) {
		if (AI_CrowdCanMove(forward_velocity))
			return forward_velocity;
	}

	vector normal = trace_plane_normal;
	float into = forward_velocity * normal;

	if (fabs(normal_z) < 0.5 && normal * normal > 0.5 && into < 0) {
		vector slide = forward_velocity - normal * into;

		if (vlen(slide) > 1) {
			vector full_speed = normalize(slide) * vlen(forward_velocity);

			if (AI_CrowdCanMove(full_speed))
				return full_speed;

			if (AI_CrowdCanMove(slide))
				return slide;
		}
	}

	return '0 0 0';
}

vector(vector anchor, float speed, optional float reuse) AI_PathLookahead =
{
	if ((self.classname == "ai_zombie" || self.classname == "ai_dog") && self.goalentity == self.goaldummy && self.path_status >= 1) {
		if (reuse) {
			if (self.path_lookahead_time > 0 && anchor == self.path_lookahead_anchor && vlen(self.origin - self.path_lookahead_origin) <= 64)
				return self.path_lookahead_point;

			return anchor;
		}

		float update = time >= self.path_lookahead_time || anchor != self.path_lookahead_anchor;
		if (!update)
			update = vlen(self.origin - self.path_lookahead_origin) >= 24;

		if (update) {
			self.path_lookahead_point = nzp_pathfind_follow(self, anchor, clamp(speed * 0.6, 96, 192));
			self.path_lookahead_anchor = self.goaldummy.origin;
			self.path_lookahead_origin = self.origin;
			self.path_lookahead_time = time + 0.2;
		}

		return self.path_lookahead_point;
	}

	return anchor;
}

vector(vector wish_velocity, vector target) AI_PathVelocity =
{
	if ((self.classname != "ai_zombie" && self.classname != "ai_dog") || self.outside != false || self.fall || !(self.flags & FL_ONGROUND))
		return wish_velocity;

	float elapsed = time - self.path_move_time;
	if (elapsed <= 0 || elapsed >= 0.3 || self.path_move_direction == '0 0 0' || fabs(target_z - self.origin_z) >= 8)
		return wish_velocity;

	float speed = vlen(wish_velocity);
	if (speed == 0)
		return wish_velocity;

	if (vlen(self.origin - self.path_move_origin) > 64 || vlen(target - self.origin) <= speed * 0.2 + 32)
		return wish_velocity;

	vector heading = wish_velocity / speed;
	float bend = heading * self.path_move_direction;

	if (bend >= 0.99 || bend <= -0.5)
		return wish_velocity;

	float fraction = clamp(elapsed * 6, 0, 1);
	vector result = normalize(self.path_move_direction * (1 - fraction) + heading * fraction) * speed;

	if (tracemove(self.origin, '-16 -16 -32', '16 16 40', self.origin + result * 0.2, true, self))
		return result;

	return wish_velocity;
}

void(float dist, vector vec) do_walk_to_vec =
{
	if(dist == 0)
		return;

	vector new_velocity;
	float reuse = false;

	if ((self.classname == "ai_zombie" || self.classname == "ai_dog") && self.outside == false) {
		reuse = true;

		if (self.path_update_pending && ai_movement_updates < 1) {
			self.path_update_pending = false;
			ai_movement_updates++;
			reuse = false;
		}
	}

	vector target = self.outside == false ? AI_PathLookahead(vec, dist * 10, reuse) : vec;
	vector direction = target - self.origin;

	if (self.outside == false)
		direction_z = 0;
	if (direction != '0 0 0' && self.classname != "ai_dog") {
		self.ideal_yaw = vectoyaw(direction);
		ChangeYaw();
	}

	float len;
	len = vlen(direction);

	if(dist > len)//if we're moving past our goal position
	{
		dist = len;
	}
	//This movement method is moving directly towards the goal, regardless of where our yaw is facing (fixes several issues)
	vector heading = len > 0 ? direction / len : '0 0 0';
	new_velocity = heading * dist * 10;
	if (dist < 0)
		heading = -heading;

	if (self.outside == false) {
		if ((self.classname == "ai_zombie" || self.classname == "ai_dog") && time - self.path_move_time < 0.3 && vlen(self.origin - self.path_move_origin) <= 64 && self.path_move_direction != '0 0 0') {
			float bend = clamp(heading * self.path_move_direction, 0, 1);
			new_velocity *= 0.6 + bend * 0.4;
		}

		new_velocity = AI_PathVelocity(new_velocity, target);
		self.path_move_direction = normalize(new_velocity);
		self.path_move_time = time;
		self.path_move_origin = self.origin;
		new_velocity = self.classname == "ai_dog" ? Dog_SeparationVelocity(new_velocity, reuse) : AI_CrowdVelocity(new_velocity, reuse);

		if (self.classname == "ai_dog") {
			vector facing = new_velocity;
			if (facing == '0 0 0' && self.goalentity == self.enemy)
				facing = self.enemy.origin - self.origin;

			if (facing != '0 0 0') {
				self.ideal_yaw = vectoyaw(facing);
				ChangeYaw();
			}
		}
	}

	new_velocity_z = self.velocity_z;
	self.velocity = new_velocity;
};

void(float dist) do_walk =
{
	do_walk_to_vec(dist,self.goalentity.origin);
};

void(float dist) walk_to_window =
{
	do_walk_to_vec(dist,self.goalorigin);
};

// unused
void(vector org, float scale) interpolateToVector =
{
	self.origin_x += (org_x - self.origin_x) * scale;
	self.origin_y += (org_y - self.origin_y) * scale;
	setorigin(self,self.origin);
	self.zoom = 1;//value to let engine know to not check for collisions
}

float(vector where) nearby = 
{
	if(self.classname == "ai_zombie" || self.classname == "ai_dog")
	{
		float xdist;
		float ydist;
		float zdist;
		xdist = fabs(self.origin_x - where_x);
		ydist = fabs(self.origin_y - where_y);
		zdist = fabs(self.origin_z - where_z);
		
		if(xdist < 4 && ydist < 4)//horizontal distance is fairly close
		{
			if(zdist < 50)//vertical distance just has to be arbitrarily close
			{
				return 1;
			}
		}
		return 0;
	}
	return 0;
};

void(float dist) Window_Walk =
{
	if(self.reload_delay < time)
		Respawn();
	
	if(self.hop_step == 0)//following path corners
	{		
		if(self.goalentity == world)
		{
			if((!self.target) && (self.outside == TRUE))
			{
				bprint(PRINT_HIGH, "Error: Outside zombie spawn point has no target.\n");
				Respawn();
			}
			self.goalentity = find(world,targetname, self.target);
			if(!self.goalentity)
			{
				bprint(PRINT_HIGH, "Error: Outside zombie spawn point target does not exist.\n");
				Respawn();
			}
		}
		
		if(self.goalentity.classname == "path_corner" && nearby(self.goalentity.origin))
		{
			if (self.goalentity.spawnflags & 1) //this path corner sets zombie on inside.
			{
				AI_ResetPath();
				self.path_wait_ground = true;
				self.outside = FALSE;
				self.goalentity = world;
				self.enemy = find_new_enemy(self);
				self.th_walk();
				return;
			}
			self.reload_delay = time + 30;
			self.goalentity = find(world,targetname,self.goalentity.target);
			
			//Assumption is that when the zombie is outside, we can always walk from one path_corner to the next in a straight line, any devation should be corrected by the mapper
		}

		do_walk(dist);
		
		if(self.goalentity.classname == "window")
		{
			// cypress (17 dec 2023) -- fixed a nasty race condition here.
			// essentially, if a new zombie spawns in fast enough after
			// a zombie is currently/just finished hopping a spot, they will
			// end up always taking box1owner (the hoppable zombie)'s place,
			// regardless of whether or not there was someone else waiting.
			// apparently this is an issue i've created rather recently,
			// which does not make sense to me considering this is a pretty
			// glaring oversight that's been here since 2014. not my whoops?
			if(!self.goalentity.box1owner && !self.goalentity.box2owner && !self.goalentity.box3owner)
			{
				//self.used = WBOX1;
				self.goalentity.box1owner = self;
				self.goalorigin = self.goalentity.box1;
				self.hop_step = 3;
				self.reload_delay = time + 30;
			}
			else if(!self.goalentity.box2owner)
			{
				//self.used = WBOX2;
				self.goalentity.box2owner = self;
				self.goalorigin = self.goalentity.box2;
				self.hop_step = 3;
				self.reload_delay = time + 30;
			}
			else if(!self.goalentity.box3owner)
			{
				//self.used = WBOX3;
				self.goalentity.box3owner = self;
				self.goalorigin = self.goalentity.box3;
				self.hop_step = 3;
				self.reload_delay = time + 30;
			}
			else if(vlen(self.origin - self.goalentity.origin) < 150)
			{	
				//we don't claim the idlebox
				//self.used = WIDLEBOX;
				self.goalorigin = self.goalentity.idlebox;
				self.hop_step = 1;
				self.reload_delay = time + 30;
			}
			//else we continue walking to window until we either find one that's good, or we are close enough to chase idle_spot
		}
	}
	else if(self.hop_step == 1)//walking to the window's idle location
	{
		if(nearby(self.goalorigin))
		{
			self.hop_step = 2;
			self.reload_delay = time + 30;
			self.th_idle();
		}
		else
		{
			walk_to_window(dist);
		}
	}
	else if(self.hop_step == 2)//we're at idle box, waiting for a window attack box to be free...
	{
		if(self.goalentity.box1owner == world)
		{
			//self.used = WBOX1;
			self.goalentity.box1owner = self;
			self.goalorigin = self.goalentity.box1;
			self.hop_step = 3;
			self.reload_delay = time + 30;
			self.th_walk();
		}
		else if(self.goalentity.box2owner == world)
		{
			//self.used = WBOX2;
			self.goalentity.box2owner = self;
			self.goalorigin = self.goalentity.box2;
			self.hop_step = 3;
			self.reload_delay = time + 30;
			self.th_walk();
		}
		else if(self.goalentity.box3owner == world)
		{
			//self.used = WBOX3;
			self.goalentity.box3owner = self;
			self.goalorigin = self.goalentity.box3;
			self.hop_step = 3;
			self.reload_delay = time + 30;
			self.th_walk();
		}
	}
	else if(self.hop_step == 3)//walking to window attack box
	{
		// sometimes, we've assigned a zombie a waiting-position
		// while another zombie is actively hopping. this can cause
		// a bit of gameplay slowdown since the zombie has to walk
		// to that waiting position, then to the hop spot (approx 1sec),
		// so let's do continuous checks here to see if box1 is free,
		// and claim it if so, in order to smooth the path and claim
		// that time. only do this if there isn't anyone else in the queue,
		// though.
		if (!self.goalentity.box1owner) {
			// Claim it as ours mid-walk, if there isn't someone else waiting.
			if ((self.goalentity.box2owner == self && !self.goalentity.box3owner) ||
			(self.goalentity.box3owner == self && !self.goalentity.box2owner)) {
				self.goalentity.box1owner = self;
				self.goalorigin = self.goalentity.box1;

				// Free up the spot we were walking to before.
				if (self.goalentity.box2owner == self) self.goalentity.box2owner = world;
				if (self.goalentity.box3owner == self) self.goalentity.box3owner = world;
			}
		}

		if(nearby(self.goalorigin))
		{
			self.hop_step = 4;
			self.reload_delay = time + 30;
			self.th_idle();
		}
		else
		{
			walk_to_window(dist);
		}
	}
	else if(self.hop_step == 4)//attacking box
	{
		if(self.chase_time < time)
		{
			if(self.angles_z != self.goalentity.angles_z)
			{
				self.ideal_yaw = self.goalentity.angles_z;
				ChangeYaw();
				return;
			}
			if(self.goalentity.health > 0 && !self.goalentity.owner)
			{
				self.reload_delay = time + 30;
				self.th_melee();				
				if(rounds <= 5)
					self.chase_time = time + 1.5;
				else
					self.chase_time = time + 0.75;
				return;
			} else if (self.goalentity.owner) {
				self.chase_time = time + 0.05;
				return;
			}
		}
		if(self.goalentity.health <= 0 && !self.goalentity.owner)
		{
			self.outside = 2;
			self.chase_time = 0;
			self.hop_step = 0;
		}
		else return;
	}
};

void() AI_ResetPath =
{
	nzp_pathfind_clear(self);

	self.path_wait_ground = false;
	self.path_status = 0;
	self.path_goal_enemy = world;
	self.path_goal_origin = self.origin;
	self.path_progress_origin = self.origin;
	self.path_progress_time = time;
	self.path_retry_time = self.path_direct_retry_time = self.path_target_update_time = 0;
	self.path_lookahead_time = self.path_move_time = 0;
	self.path_move_direction = '0 0 0';
	self.path_move_origin = self.origin;
	self.crowd_update_time = self.crowd_progress_time = 0;
	self.crowd_wish_time = self.path_update_pending = 0;
	self.crowd_blocker = world;
	self.crowd_avoid_side = 0;

	for (int i = 0; i < 4; i++)
		self.crowd_neighbors[i] = world;
	self.chase_time = self.chase_enemy_time = 0;

	if (self.goaldummy != world)
		setorigin(self.goaldummy, self.origin);
}

void(float dist) Window_Hop =
{
	if(self.hop_step == 0) {
		if(self.goalentity.box1owner == self) {//we're at center box.
			self.hop_step = 4;
		} else {
			self.hop_step = 1;//wait for box1 to be free so we can claim it and walk to it.
			self.th_idle();
		}
	}

	if(self.hop_step == 1) {//waiting idly for box1 to be free, when free, we will claim it.
		if(!self.goalentity.box1owner || self.goalentity.box1owner == self) {
			self.goalentity.box1owner = self;

			if(self.goalentity.box2owner == self)
				self.goalentity.box2owner = world;

			if(self.goalentity.box3owner == self)
				self.goalentity.box3owner = world;

			//self.used = WBOX1;

			self.goalorigin = self.goalentity.box1;
			self.hop_step = 2;
			self.th_walk();
		}
	}

	if(self.hop_step == 2) {//we've claimed it, walk to box1
		if(nearby(self.goalorigin)) {
			self.hop_step = 4;
			self.angles = self.goalentity.angles;
		} else {
			walk_to_window(dist);
		}
	}

	if(self.hop_step == 4 && self.chase_time < time) {//we're at this step because we already own box1, so don't even check if window is busy...
		if(!self.goalentity.usedent) {
			self.hop_step = 5;
			self.angles = self.goalentity.angles;
			self.goalentity.box1owner = world;//free box1
			self.goalentity.usedent = self;//we own the window
			//don't need to set goalorigin here
			//self.used = WWINDOW;
			self.chase_time = 0;
			self.th_windowhop();
			return;
		} else {
			self.tries++;
			self.chase_time = time + 0.2;

			if(self.tries > 10) {
				if (!self.goalentity.owner)
					self.goalentity.usedent = world;//free up the window if we've been waiting to hop
			}
		}
	}

	if(self.hop_step == 6) {
		AI_ResetPath();
		self.path_wait_ground = true;
		self.hop_step = 0;
		self.outside = FALSE;
		self.goalentity.usedent = world;//free up the window, we're done hopping it
		self.goalentity = world;
		self.enemy = find_new_enemy(self);
		//self.th_die();
		self.th_walk();
		//LinkZombiesHitbox();
		//bprint (PRINT_HIGH, "Linked hitboxes");
	}
}

float() TryWalkToEnemy =
{
	if (time < self.path_direct_retry_time)
		return 0;

	float TraceResult = nzp_can_walk_to_enemy(self);

	if (TraceResult == 1) {
		self.goalentity = self.enemy;
		self.chase_time = time + 7;
		return 1;
	} else {
		self.path_direct_retry_time = time + 0.5;
		return 0;
	}
};

void(entity actor) AI_AdjustSpawnOrigin =
{
	while (pointcontents(actor.origin - '0 0 36') == CONTENT_SOLID) {
		actor.origin += '0 0 1';
		setorigin(actor, actor.origin);
	}
};

float(entity target, optional float keep_route) AI_PathfindTarget =
{
	if (target == world || target.downed || target.is_spectator)
		return 0;

	if (self.classname == "ai_dog" && target.classname == "player" && target.health <= 0)
		return 0;

	return Do_Pathfind_psp(self, target, keep_route);
}

float(string target_class, entity rejected) AI_FindReachableTarget =
{
	float previous_distance = -1;
	entity previous = world;

	while (true) {
		entity best = world;
		float best_distance = 1000000000;
		entity target = find(world, classname, target_class);

		while (target != world) {
			float distance = vlen(target.origin - self.origin);

			if (target != rejected && !target.downed && !target.is_spectator && (distance > previous_distance || (distance == previous_distance && (int)target > (int)previous)) && distance < best_distance) {
				best = target;
				best_distance = distance;
			}

			target = find(target, classname, target_class);
		}

		if (best == world)
			return 0;

		float result = AI_PathfindTarget(best);

		if (result != 0) {
			self.enemy = best;
			return result;
		}

		previous = best;
		previous_distance = best_distance;
	}
}

float(optional float keep_route) PathfindToEnemy =
{
	if (self.path_status < 1 || self.enemy != self.path_goal_enemy)
		keep_route = false;

	float path_result = AI_PathfindTarget(self.enemy, keep_route);

	if (path_result == 0 && self.classname == "ai_dog") {
		entity previous_enemy = self.enemy;
		path_result = AI_FindReachableTarget("player", previous_enemy);

		if (path_result != 0) {
			if (previous_enemy.classname == "player" && previous_enemy.hunt_count > 0)
				previous_enemy.hunt_count--;

			self.enemy.hunt_count++;
			self.ads_release = 0;
			self.dog_run_check_time = 0;
		}
	}

	if (path_result == 0 && self.classname == "ai_zombie") {
		entity rejected = self.enemy;
		float old_retry = self.path_direct_retry_time;
		self.path_direct_retry_time = 0;
		path_result = AI_FindReachableTarget("player", rejected);

		if (path_result == 0)
			path_result = AI_FindReachableTarget("zombie_horde_point", rejected);

		if (path_result == 0)
			path_result = AI_FindReachableTarget("info_player_1_spawn", rejected);

		if (path_result == 0)
			self.path_direct_retry_time = old_retry;
		else
			self.enemy_timeout = time + 5;
	}

	if (path_result >= 0 && time >= self.path_direct_retry_time)
		self.path_direct_retry_time = time + 0.5;

	float kept_route = path_result == 2;
	if (kept_route)
		path_result = 1;
	else
		self.path_lookahead_time = 0;

	self.path_status = path_result;
	self.path_goal_origin = nzp_pathfind_target_origin(self.enemy);
	self.path_goal_enemy = self.enemy;
	self.path_target_update_time = time + 0.5 + ((int)self & 3) * 0.05;

	if (path_result >= 1) {
		if (!kept_route) {
			self.goaldummy.origin = Get_First_Waypoint(self, self.origin, VEC_HULL_MIN, VEC_HULL_MAX);
			setorigin(self.goaldummy, self.goaldummy.origin);
			self.goalentity = self.goaldummy;
		}
		self.chase_time = time + 7;
	} else if (path_result == -1) {
		self.goalentity = self.enemy;
		self.chase_time = time + 6;
		self.chase_enemy_time = time + 0.5;
	} else {
		setorigin(self.goaldummy, self.origin);
		self.goalentity = self.goaldummy;
		self.chase_time = time + 1;
	}

	return path_result;
}

float() AI_PathTargetDistance =
{
	vector movement = self.enemy.origin - self.path_goal_origin;

	if (self.enemy.classname == "player" && !(self.enemy.flags & FL_ONGROUND))
		movement_z = 0;

	return vlen(movement);
}

void() NextPathfindToEnemy {
	if (self.path_status == 0 && self.chase_time > time)
		return;

	float update = self.path_status < 1;
	if (!update)
		update = AI_PathTargetDistance() >= 64;

	if (update) {
		PathfindToEnemy();
		return;
	}

	self.path_lookahead_time = 0;
	setorigin(self.goaldummy, Get_Next_Waypoint(self, self.origin, VEC_HULL_MIN, VEC_HULL_MAX));
	self.goalentity = self.goaldummy;
	self.chase_time = time + 7;
}

float() AI_PathNeedsUpdate =
{
	if (self.path_status < 1)
		return false;

	if (self.enemy != self.path_goal_enemy)
		return true;

	if (time < self.path_target_update_time)
		return false;

	return AI_PathTargetDistance() >= 64;
}

void(float dist) Inside_Walk = {
	if (self.path_wait_ground) {
		if (!(self.flags & FL_ONGROUND) && self.watertype != CONTENT_WATER)
			return;

		self.path_wait_ground = false;
	}

	if (self.classname == "ai_dog") {
		if ((self.enemy.classname != "player" || self.enemy.downed || self.enemy.is_spectator || self.enemy.health <= 0) && time >= self.enemy_timeout) {
			entity previous_enemy = self.enemy;
			self.enemy = Dog_FindEnemy(self);
			self.enemy_timeout = time + 0.2;

			if (self.enemy != previous_enemy) {
				self.path_direct_retry_time = 0;
				self.chase_enemy_time = 0;
				PathfindToEnemy();
			}
		}
	}
	// Normal Zombie time-out re-targeting
	else {
		if(self.enemy_timeout < time || self.enemy == world || self.enemy.downed == true) {
			self.enemy_timeout = time + 5;
			self.enemy = find_new_enemy(self);

			if (self.classname == "ai_zombie" && self.enemy.classname == "player" && self.enemy != self.path_goal_enemy) {
				self.path_direct_retry_time = 0;
				PathfindToEnemy();
			}
		}
	}

	if (self.classname == "ai_zombie" && self.enemy.classname == "player") {
		float update = self.enemy != self.path_goal_enemy;
		if (!update && time >= self.path_target_update_time)
			update = AI_PathTargetDistance() >= 32;

		if (update) {
			if (self.enemy != self.path_goal_enemy)
				self.path_direct_retry_time = 0;
			PathfindToEnemy(self.enemy == self.path_goal_enemy);
		}
	}
	//================Check for proximity to player ===========
	float enemy_distance = vlen(self.enemy.origin - self.origin);
	float attack_range = enemy_distance < 60;

	if (self.classname == "ai_dog") {
		attack_range = false;

		if ((self.flags & FL_ONGROUND) && enemy_distance < 100 && fabs(self.enemy.origin_z - self.origin_z) < 64 && angledif(vectoyaw(self.enemy.origin - self.origin), self.angles_y) <= 30) {
			traceline(self.origin + '0 0 8', self.enemy.origin, false, self);
			if (!trace_startsolid) {
				if (trace_fraction == 1)
					attack_range = true;
				else if (trace_ent == self.enemy)
					attack_range = true;
			}
		}
	}

	if (attack_range) {
		if(self.enemy.classname == "monkey_bomb" && self.classname != "ai_dog") {
			self.th_idle();
		}

		if(self.classname == "ai_zombie" || self.attack_delay < time) {
			if (self.classname != "ai_zombie")
				self.attack_delay = time + 1 + (1 * random());

			if (self.enemy.health)
				self.th_melee();

			if (self.enemy.downed == true) {
				if (self.classname == "ai_dog")
					self.enemy = Dog_FindEnemy(self);
				else
					self.enemy = find_new_enemy(self);
			}

			self.goalentity = self.enemy;
			self.chase_time = time + 5;
		}

		return;
	}

	if(self.goalentity == self.enemy || enemy_distance < 600) {
		if(self.goalentity == self.enemy && self.chase_enemy_time > time) {
			return;
		}

		if(TryWalkToEnemy())
		{
			self.chase_enemy_time = time + 0.5;
			return;
		}
	}

	if(self.goalentity == self.enemy) {
		self.path_direct_retry_time = time + 2;
		self.goalentity = self.goaldummy;
		self.chase_time = 0;
		PathfindToEnemy();
	}
	//============= No Target ====================
	if(self.goalentity == world) {//not sure when this would ever occur... but whatever.
		self.goalentity = self.goaldummy;
	}
	//============ GoalDummy is Target ============
	if(self.goalentity == self.goaldummy) {
		if (AI_PathNeedsUpdate())
			PathfindToEnemy(self.enemy == self.path_goal_enemy);

		if (vlen(self.origin - self.path_progress_origin) >= 4) {
			self.path_progress_origin = self.origin;
			self.path_progress_time = time;
		} else if (time - self.path_progress_time >= 1 && time >= self.path_retry_time) {
			self.path_retry_time = time + 1;
			PathfindToEnemy();
		}

		float advance = nearby(self.goaldummy.origin);

		if (advance) {
			NextPathfindToEnemy();
		}

		if(self.chase_time < time) {
			if(self.goaldummy.origin != world.origin && tracemove(self.origin,VEC_HULL_MIN,VEC_HULL_MAX,self.goalentity.origin,TRUE,self) == 1) {
				self.chase_time = time + 7;
			} else {
				PathfindToEnemy();
			}
		}
	}
}

.float droptime;
void(float dist) Zombie_Walk =  {
	// Super sprinting hack!!!
	if (self.classname == "ai_zombie" && self.walktype == 6 && !self.crawling)
		dist *= 21 / 13;
	dist = Gamemode_GetAIWalkSpeed(dist, self.classname);

	//Resetting velocity from last frame (except for vertical)
	self.velocity_x = 0;
	self.velocity_y = 0;
	//self.flags = self.flags | FL_PARTIALGROUND;

	if (!(self.flags & FL_ONGROUND) && self.watertype != CONTENT_WATER) {

		if (!self.droptime) {
			self.droptime = time + 1;
		} else if (self.droptime < time) {
			self.droptime = 0;
			//bprint(PRINT_HIGH, "not on ground\n");

			if (self.classname != "ai_dog")
				self.th_fall();
			return;
		}
	} else {
		self.droptime = 0;
	}

	if(self.outside == TRUE) {
		//handle special walk case for walking to org
		Window_Walk(dist);
		return;
	}

	if(self.outside == 2) {
		Window_Hop(dist);
		//handle special walk case for walking to org
		return;
	}

	if(self.outside == FALSE) {
		if(self.goalentity == self.enemy) {
			if(vlen(self.origin - self.enemy.origin) < 60) {
				if (self.classname == "ai_dog" && dist > 0)
					do_walk_to_vec(dist, self.origin);
				return;
			}
		}
	}

	do_walk(dist);
}

void() Zombie_AI = {
	//dist = 0;
	float dist = 0;
	self.flags = self.flags | FL_PARTIALGROUND;
	//check_onfire();

	//
	// Try to play some zombie sounds.
	//

	// Crawling
	if (self.crawling == true) {
		Zombie_PlaySoundType(ZOMBIE_SOUND_TYPE_CRAWL);
	} else {
		// Walking
		if (self.walktype < 4) {
			Zombie_PlaySoundType(ZOMBIE_SOUND_TYPE_WALK);
		}
		// Running
		else {
			Zombie_PlaySoundType(ZOMBIE_SOUND_TYPE_SPRINT);
		}
	}
	
	if(self.outside == FALSE) {
		Inside_Walk(dist);
	}
}

void() Hellhound_AI =
{
	if (self.is_attacking)
		return;

	Inside_Walk(0);
}

//
// Do_Zombie_AI()
//
void() Do_Zombie_AI = 
{
	entity z;
	entity old_self;
	
	z = find(lastzombie,aistatus,"1");
	if(z == world) {
		z = find(world,aistatus,"1");
		if(z == world) {
			return;//no zombies alive.
		}
	}

	old_self = self;
	self = z;

	if(z.classname == "ai_zombie") {
		if (z.outside == false)
			z.path_update_pending = true;
		Zombie_AI();
	}
	else if (z.classname == "ai_dog") {
		z.path_update_pending = true;
		Hellhound_AI();
	}

	self = old_self;
	lastzombie = z;
}