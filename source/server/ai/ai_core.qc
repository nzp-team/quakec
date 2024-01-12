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

void(float what) play_sound_z;
void() LinkZombiesHitbox;
entity() Dog_FindEnemy;

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
			if (targets.downed == true || targets.isspec == true) {
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

float() avoid_zombies =
{
	local entity ent;
	ent = findradius(self.origin,23);//22.67
	makevectors(self.angles);
	float left_amount, right_amount;
	left_amount = right_amount = 0;
	while(ent)
	{
		if(ent.classname == "ai_zombie" && ent != self)
		{
			local vector vec_b;
			local float dot;
			//vec_b = normalize(self.origin - ent.origin);
			//dot = v_right * vec_b;
			//dot = self.angles_y - (dot > 0.5) ? 90 :  270;
			
			vec_b = (self.origin - ent.origin);
			dot = (v_right_x * vec_b_x) + (v_right_y * vec_b_y);//dot product
			if(dot > 0)// on right
				right_amount++;
			else// on left
				left_amount++;
		}
		ent = ent.chain;
	}
	if(left_amount + right_amount == 0)
		return 0;
	
	return (left_amount > right_amount) ? 15 : -15;
};

float() push_away_zombies =
{
	local entity ent;
	ent = findradius(self.origin,11);
	float return_value;
	return_value = 0;
	while(ent)
	{
		if(ent.aistatus == "1" && ent != self)
		{
			vector push;
			push = ent.origin - self.origin;
			push_z = 0;
			push = normalize(push) * 10;
			
			ent.velocity += push;
			return_value = 1;
		}
		ent = ent.chain;
	}
	return return_value;
}


void(float dist, vector vec) do_walk_to_vec =
{
	if(dist == 0)
		return;
	
	self.ideal_yaw = vectoyaw(vec - self.origin);
	if(self.outside == false)
	{
		// this is a performance net negative for like 0 gain in horde space.
		push_away_zombies();
	}
	ChangeYaw();
	vector new_velocity;
	
	float len;
	len = vlen(self.origin - vec);
	
	if(dist > len)//if we're moving past our goal position
	{
		dist = len;
	}
	//This movement method is moving directly towards the goal, regardless of where our yaw is facing (fixes several issues)
	new_velocity = normalize(vec - self.origin) * dist * 10;
	
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


//
// FTE's custom "tracemove" -- no way in hell I'm reimplementing SV_Move
// in QuakeC. So this is just a really bad traceline hack. We can't even
// use tracebox since that's limited by BSP hulls,
//
#ifdef FTE
inline float(vector start, vector min, vector max, vector end, float nomonsters, entity forent) tracemove =
#else
float(vector start, vector min, vector max, vector end, float nomonsters, entity forent) tracemove_fake =
#endif // FTE
{
	makevectors(forent.angles);

	// Top left of the box
	traceline(start + '0 0 32' + v_right * -18, end, nomonsters, forent);

	// Results Check
	if (trace_ent != forent && trace_endpos != end)
		return 0;

	// Top right of the box
	traceline(start + '0 0 32' + v_right * 18, end, nomonsters, forent);

	// Results Check
	if (trace_ent != forent && trace_endpos != end)
		return 0;

	// Bottom left of the box
	traceline(start - '0 0 24' + v_right * -18, end, nomonsters, forent);

	// Results Check
	if (trace_ent != forent && trace_endpos != end)
		return 0;

	// Bottom right of the box
	traceline(start - '0 0 24' + v_right * 18, end, nomonsters, forent);

	// Results Check
	if (trace_ent != forent && trace_endpos != end)
		return 0;

	return 1;		
}

float() TryWalkToEnemy =
{

	// Early out hack for FTE -- if there's tons of z-diff, GTFO!
	float z_axis_diff = fabs(self.origin_z - self.enemy.origin_z);
	if (z_axis_diff >= 30)
		return 0;

	// This has been a headache...
	// TryWalkToEnemy is a system that attempts to ignore waypoints from a
	// certain distance to simulate proper player-targeting. It does this
	// using the custom builtin tracemove, which calls SV_Move to determine
	// if it's possible for the enemy to walk directly to the target. This
	// is problematic, however -- in that FTE does not feature this builtin
	// since it's non-standard and was written by blubs. This means there
	// needs to be improvisation, and as a result there is disparity here.
	// See the custom tracemove() function for details on that.
	// -- cypress (28 Nov 2023)
#ifdef FTE
	float TraceResult = tracemove(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, self.enemy.origin, TRUE, self);
#else
	float TraceResult = tracemove_fake(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, self.enemy.origin, TRUE, self);
#endif // FTE

	if (TraceResult == 1) {
		self.goalentity = self.enemy;
		self.chase_time = time + 7;
		return 1;
	} else {
		return 0;
	}
};

void() PathfindToEnemy =
{
	float path_result;
	float path_failure;

	//just to stop any warns.
	path_failure = 0;

#ifndef FTE

	path_result = Do_Pathfind_psp(self, self.enemy);

#else

	path_result = Do_Pathfind(self, self.enemy);

#endif // FTE

	if (path_result >= 1) {

#ifndef FTE

		self.goaldummy.origin = Get_First_Waypoint(self, self.origin, VEC_HULL_MIN, VEC_HULL_MAX);
		setorigin(self.goaldummy, self.goaldummy.origin);
		path_failure = path_result;

#else

		self.goalway = path_result;
		setorigin(self.goaldummy,waypoints[self.goalway].org);
		path_failure = self.goalway;

#endif // FTE

		self.goalentity = self.goaldummy;
		self.chase_time = time + 7;
		
	} else if (path_failure == -1) {
		self.goalentity = self.enemy;
		self.chase_time = time + 6;
	} else {

#ifdef FTE

		//bprint(PRINT_HIGH, "FirstPathfind Failure\n");

#endif // FTE

	}
}

void() NextPathfindToEnemy {
	// same as PathfindToEnemy on non-FTE platforms

#ifndef FTE

	float path_success;
	path_success = Do_Pathfind_psp(self,self.enemy);
	if(path_success ==1) {
		self.goaldummy.origin = Get_Next_Waypoint(self,self.origin,VEC_HULL_MIN,VEC_HULL_MAX);
		setorigin(self.goaldummy,self.goaldummy.origin);
		self.goalentity = self.goaldummy;
		self.chase_time = time + 7;
	} else if(path_success == -1){
		self.goalentity = self.enemy;
		self.chase_time = time + 6;
	} else {
		bprint(PRINT_HIGH, "NextPathfind Failure\n");		// this lags like hell
	}

#else

	self.way_cur++;

	if (self.way_cur < 40 && self.way_path[self.way_cur] != -1) {
		self.goalway = self.way_path[self.way_cur];
		setorigin(self.goaldummy,waypoints[self.goalway-1].org);
	} else {
		self.way_cur = 0;
	}

#endif // FTE

}

void(float dist) Inside_Walk = {
	// Hellhounds should only change targets if current one is in Last Stand
	if (self.classname == "ai_dog" && self.enemy.downed == true) {
		self.enemy = Dog_FindEnemy();
	} 
	// Normal Zombie time-out re-targeting
	else if (self.classname != "ai_dog") {
		if(self.enemy_timeout < time || self.enemy == world || self.enemy.downed == true) {
			self.enemy_timeout = time + 5;
			local entity oldEnemy;
			oldEnemy = self.enemy;
			self.enemy = find_new_enemy(self);
		}
	}
	//================Check for proximity to player ===========
	if(vlen(self.enemy.origin - self.origin) < 60) {
		if(self.enemy.classname == "monkey_bomb" && self.classname != "ai_dog") {
			self.th_idle();
		}
		
		if(self.attack_delay < time) {
			self.attack_delay = time + 1 + (1 * random());

			if (self.enemy.health)
				self.th_melee(); 

			if (self.enemy.downed == true) {
				if (self.classname == "ai_dog")
					self.enemy = Dog_FindEnemy();
				else
					self.enemy = find_new_enemy(self);
			}
			self.goalentity = self.enemy;
			self.chase_time = time + 5;
		}
		return;
	}
	
	if(vlen(self.enemy.origin - self.origin) < 600) {//50 feet
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
		self.goalentity = self.goaldummy;
		self.chase_time = 0;
	}
	//============= No Target ====================
	if(self.goalentity == world) {//not sure when this would ever occur... but whatever.
		self.goalentity = self.goaldummy;
	}
	//============ GoalDummy is Target ============
	if(self.goalentity == self.goaldummy) {
		if(nearby(self.goaldummy.origin)) {

#ifndef FTE

			NextPathfindToEnemy();

#else

			PathfindToEnemy();

#endif // FTE

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
	}
	
	if(self.outside == TRUE) {
		//handle special walk case for walking to org
		Window_Walk(dist);
		return;
	}
	
	if(self.outside == 2) {
		//play_sound_z(2);
		Window_Hop(dist);
		//handle special walk case for walking to org
		return;
	}
	if(self.outside == FALSE) {
		if(self.goalentity == self.enemy) {
			if(vlen(self.origin - self.enemy.origin) < 60) {
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
	
	if(self.outside == TRUE) {
		play_sound_z(2);
		//self.calc_time = time + (0.3 * random());
		//Window_Walk(dist);
		return;
	} else if(self.outside == 2) {
		play_sound_z(2);
		//Window_Hop(0);
		return;
	} else if(self.outside == FALSE) {
		play_sound_z(2);
		//self.calc_time = time + (0.25 + (0.15 * random()));
		Inside_Walk(dist);
	}
}

void() Hellhound_AI =
{
	Inside_Walk(0);
}

//
// Do_Zombie_AI()
// Behaves differently based on platform -- in FTE,
// all AI can afford to be executed at once. However,
// on every other platform there is a timed delay in
// place and only one zombie AI can be updated at a time.
//
void() Do_Zombie_AI = 
{
	entity z;
	entity old_self;
	
#ifndef FTE

	z = find(lastzombie,aistatus,"1");
	if(z == world) {
		z = find(world,aistatus,"1");
		if(z == world) {
			return;//no zombies alive.
		}
	}

	old_self = self;
	self = z;

	if(z.classname == "ai_zombie")
		Zombie_AI();
	else if (z.classname == "ai_dog")
		Hellhound_AI();

	self = old_self;
	lastzombie = z;

#else

	z = find(world, aistatus, "1");

	while(z != world) {
		old_self = self;
		self = z;

		// Execute AI
		if (z.classname == "ai_zombie")
			Zombie_AI();
		else if (z.classname == "ai_dog")
			Hellhound_AI();

		self = old_self;
		z = find(z, aistatus, "1");
	}

#endif // FTE

}

#ifdef FTE

void() AI_SetAllEnemiesBBOX =
{
	entity zombies = find(world, classname, "ai_zombie");

	while(zombies != world) {
		if (zombies.aistatus == "1") {
			zombies.last_solid = zombies.solid;
			zombies.solid = SOLID_BBOX;

			if (zombies.head) {
				zombies.head.last_solid = zombies.head.solid;
				zombies.head.solid = SOLID_BBOX;
			}

			if (zombies.larm) {
				zombies.larm.last_solid = zombies.larm.solid;
				zombies.larm.solid = SOLID_BBOX;
			}

			if (zombies.rarm) {
				zombies.rarm.last_solid = zombies.rarm.solid;
				zombies.rarm.solid = SOLID_BBOX;
			}
		}
		
		zombies = find(zombies, classname, "ai_zombie");
	}
}

void() AI_RevertEnemySolidState =
{
	entity zombies = find(world, classname, "ai_zombie");

	while(zombies != world) {
		if (zombies.aistatus == "1") {
			zombies.solid = zombies.last_solid;

			if (zombies.head)
				zombies.head.solid = zombies.head.last_solid;
			if (zombies.larm)
				zombies.larm.solid = zombies.larm.last_solid;
			if (zombies.rarm)
				zombies.rarm.solid = zombies.rarm.last_solid;
		}

		zombies = find(zombies, classname, "ai_zombie");
	}
}

#endif // FTE