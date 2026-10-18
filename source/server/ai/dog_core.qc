/*
	server/ai/dog_core.qc

	dog things

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

void() Dog_Think;
void() Dog_Death;
void() Dog_LungeMove;
void() Dog_Bite;
void() Dog_AttackFinish;

// DOG RUN
// 0-6
$frame dogrun1 dogrun2 dogrun3 dogrun4 dogrun5 dogrun6 dogrun7
void()	dog_runanim		=[	$dogrun1,	dog_runanim2	] {Dog_Think();Zombie_Walk(150 / 7);self.frame = 0;};
void()	dog_runanim2	=[	$dogrun2,	dog_runanim3	] {Dog_Think();Zombie_Walk(150 / 7);self.frame = 1;};
void()	dog_runanim3	=[	$dogrun3,	dog_runanim4	] {Dog_Think();Zombie_Walk(150 / 7);self.frame = 2;zombie_footstep();};
void()	dog_runanim4	=[	$dogrun4,	dog_runanim5	] {Dog_Think();Zombie_Walk(150 / 7);self.frame = 3;};
void()	dog_runanim5	=[	$dogrun5,	dog_runanim6	] {Dog_Think();Zombie_Walk(150 / 7);self.frame = 4;};
void()	dog_runanim6	=[	$dogrun6,	dog_runanim7	] {Dog_Think();Zombie_Walk(150 / 7);self.frame = 5;};
void()	dog_runanim7	=[	$dogrun7, 	Dog_Walk_Setup 	] {Dog_Think();Zombie_Walk(150 / 7);self.frame = 6;zombie_footstep();};

// DOG WALK
// 7-18
$frame dogwalk1 dogwalk2 dogwalk3 dogwalk4 dogwalk5 dogwalk6 dogwalk7 dogwalk8 dogwalk9 dogwalk10 dogwalk11 dogwalk12
void()	dog_walkanim	=[	$dogwalk1,		dog_walkanim2	] {Dog_Think();Zombie_Walk(10);self.frame = 7;};
void()	dog_walkanim2	=[	$dogwalk2,		dog_walkanim3	] {Dog_Think();Zombie_Walk(10);self.frame = 8;zombie_footstep();};
void()	dog_walkanim3	=[	$dogwalk3,		dog_walkanim4	] {Dog_Think();Zombie_Walk(10);self.frame = 9;};
void()	dog_walkanim4	=[	$dogwalk4,		dog_walkanim5	] {Dog_Think();Zombie_Walk(10);self.frame = 10;};
void()	dog_walkanim5	=[	$dogwalk5,		dog_walkanim6	] {Dog_Think();Zombie_Walk(10);self.frame = 11;};
void()	dog_walkanim6	=[	$dogwalk6,		dog_walkanim7	] {Dog_Think();Zombie_Walk(10);self.frame = 12;};
void()	dog_walkanim7	=[	$dogwalk7,		dog_walkanim8	] {Dog_Think();Zombie_Walk(10);self.frame = 13;zombie_footstep();};
void()	dog_walkanim8	=[	$dogwalk8,		dog_walkanim9	] {Dog_Think();Zombie_Walk(10);self.frame = 14;};
void()	dog_walkanim9	=[	$dogwalk9,		dog_walkanim10	] {Dog_Think();Zombie_Walk(10);self.frame = 15;};
void()	dog_walkanim10	=[	$dogwalk10,		dog_walkanim11	] {Dog_Think();Zombie_Walk(10);self.frame = 16;};
void()	dog_walkanim11 	=[	$dogwalk11,		dog_walkanim12	] {Dog_Think();Zombie_Walk(10);self.frame = 17;};
void()	dog_walkanim12	=[	$dogwalk12,		Dog_Walk_Setup	] {Dog_Think();Zombie_Walk(10);self.frame = 18;};

// DOG IDLE
// 19-24
$frame dogstand1 dogstand2 dogstand3 dogstand4 dogstand5 dogstand6
void()	dog_idleanim	=[	$dogstand1,	dog_idleanim2	] {Dog_Think();self.frame = 19;};
void()	dog_idleanim2	=[	$dogstand2,	dog_idleanim3	] {Dog_Think();self.frame = 20;};
void()	dog_idleanim3	=[	$dogstand3,	dog_idleanim4	] {Dog_Think();self.frame = 21;};
void()	dog_idleanim4	=[	$dogstand4,	dog_idleanim5	] {Dog_Think();self.frame = 22;};
void()	dog_idleanim5	=[	$dogstand5,	dog_idleanim6	] {Dog_Think();self.frame = 23;};
void()	dog_idleanim6	=[	$dogstand6,	dog_idleanim	] {Dog_Think();self.frame = 24;};

// DOG MELEE
// 25-34
$frame dogmelee1 dogmelee2 dogmelee3 dogmelee4 dogmelee5 dogmelee6 dogmelee7 dogmelee8 dogmelee9 dogmelee10
void()	dog_meleeanim	=[	$dogmelee1, 	dog_meleeanim2	] {Dog_Think();Dog_LungeMove(); self.frame = 26;};
void()	dog_meleeanim2	=[	$dogmelee2, 	dog_meleeanim3	] {Dog_Think();Dog_LungeMove();self.frame = 28; Sound_PlaySound(self, "sounds/hound/a0.wav", SOUND_TYPE_ZOMBIE_LOUD, SOUND_PRIORITY_PLAYALWAYS);};
void()	dog_meleeanim3	=[	$dogmelee3, 	dog_meleeanim4	] {Dog_Think();Dog_Bite();self.frame = 30;};
void()	dog_meleeanim4	=[	$dogmelee4, 	dog_meleeanim5	] {Dog_Think();Zombie_Walk(0);self.frame = 32;};
void()	dog_meleeanim5	=[	$dogmelee5, 	Dog_AttackFinish	] {Dog_Think();Zombie_Walk(0);self.frame = 34;};

// DOG DEATH
// 35 - 36
$frame dogdeath1 dogdeath2
void()	dog_deathanim		=[	$dogdeath1,		dog_deathanim2	] 	{self.frame = 35;};
void()	dog_deathanim2		=[	$dogdeath2,		SUB_Null 		] 	{self.nextthink = time + 3; self.think = removeZombie;  self.frame = 36;};


// DOG LIGHTNING SPAWN
// 1-13
$frame dls1 dls2 dls3 dls4 dls5 dls6 dls7 dls8 dls9 dls10 dls11 dls12 dls13
void() 	dog_lightninganim     =[  $dls1, 			dog_lightninganim2 	] {self.frame = 1;};
void() 	dog_lightninganim2    =[  $dls2, 			dog_lightninganim3 	] {self.frame = 2;};
void() 	dog_lightninganim3    =[  $dls3, 			dog_lightninganim4 	] {self.frame = 3;};
void() 	dog_lightninganim4    =[  $dls4, 			dog_lightninganim5 	] {self.frame = 4;};
void() 	dog_lightninganim5    =[  $dls5, 			dog_lightninganim6 	] {self.frame = 5;};
void() 	dog_lightninganim6    =[  $dls6, 			dog_lightninganim7 	] {self.frame = 6;};
void() 	dog_lightninganim7    =[  $dls7, 			dog_lightninganim8 	] {self.frame = 7;};
void() 	dog_lightninganim8    =[  $dls8, 			dog_lightninganim9 	] {self.frame = 8;};
void() 	dog_lightninganim9    =[  $dls9, 			dog_lightninganim10 ] {self.frame = 9;};
void() 	dog_lightninganim10   =[  $dls10, 			dog_lightninganim11 ] {self.frame = 10;};
void() 	dog_lightninganim11   =[  $dls11, 			dog_lightninganim12 ] {self.frame = 11;};
void() 	dog_lightninganim12   =[  $dls12, 			dog_lightninganim13 ] {self.frame = 12;};
void() 	dog_lightninganim13   =[  $dls13, 			SUB_Null		 	] {self.frame = 13; remove(self);};

// DOG EXPLODE SPRITE
// 1-5
$frame des1 des2 des3 des4 des5 des6
void() dog_explodeanim 		=[ 	$des1, 				dog_explodeanim2	] {self.frame = 1;};
void() dog_explodeanim2 	=[ 	$des2, 				dog_explodeanim3	] {self.frame = 2;};
void() dog_explodeanim3 	=[ 	$des3, 				dog_explodeanim4	] {self.frame = 3;};
void() dog_explodeanim4 	=[ 	$des4, 				dog_explodeanim5	] {self.frame = 4;};
void() dog_explodeanim5 	=[ 	$des5, 				dog_explodeanim6 	] {self.frame = 5;};
void() dog_explodeanim6 	=[ 	$des5, 				SUB_Null 		 	] {removeZombie();};

void() Dog_Walk_Setup = 
{	
	if (self.walktype == 1)
		dog_walkanim();
	else
		dog_runanim();
};

//
// Dog_Taunt()
// Plays some random Taunt sounds
//
void() Dog_Taunt =
{
	if (self.sound_time > time)
		return;

	self.sound_time = time + 3 * random();

	if (random() > 0.5) {
		Sound_PlaySound(self, "sounds/hound/t0.wav", SOUND_TYPE_ZOMBIE_LOUD, SOUND_PRIORITY_PLAYALWAYS);
	} else {
		Sound_PlaySound(self, "sounds/hound/t1.wav", SOUND_TYPE_ZOMBIE_LOUD, SOUND_PRIORITY_PLAYALWAYS);
	}
}

void() Dog_Think =
{
	Dog_Taunt();

	if (!self.ads_release && time >= self.dog_run_check_time) {
		self.dog_run_check_time = time + 0.2;

		if (self.enemy.classname == "player" && !self.enemy.downed && !self.enemy.is_spectator && self.enemy.health > 0) {
			if (self.health < self.max_health) {
				self.ads_release = true;
			} else {
				vector target = nzp_pathfind_target_origin(self.enemy);
				vector direction = target - self.origin;
				float distance = vlen(direction);
				float yaw = angledif(vectoyaw(direction), self.angles_y);

				if (distance <= 500 && fabs(direction_z) <= 64 && fabs(direction_z) <= distance * 0.5 && yaw <= 20) {
					traceline(self.origin + '0 0 8', self.enemy.origin, true, self);
					self.ads_release = trace_fraction == 1;
				}
			}
		}
	}

	// Stalk...
	if (self.ads_release == 0)
		self.walktype = 1;
	// Charge...
	else
		self.walktype = 2;

	// Play particles if we're on fire
	if (self.onfire) {
		Effect_Fire(self.origin);
	}
}

vector(vector wish_velocity, optional float reuse) Dog_SeparationVelocity =
{
	if (self.outside || !(self.flags & FL_ONGROUND) || self.is_attacking)
		return wish_velocity;

	if (!reuse && time >= self.crowd_update_time)
		AI_UpdateCrowd();

	float idle = wish_velocity == '0 0 0';
	float speed = idle ? 80 : vlen(wish_velocity);
	vector heading = idle ? normalize(self.enemy.origin - self.origin) : wish_velocity / speed;
	heading_z = 0;
	heading = heading == '0 0 0' ? '1 0 0' : normalize(heading);
	vector side = [-heading_y, heading_x, 0];
	float orientation = (heading_x < 0 || (heading_x == 0 && heading_y < 0)) ? -1 : 1;
	vector separation = '0 0 0';
	float limit = idle ? 0 : speed;

	for (int i = 0; i < 4; i++) {
		entity actor = self.crowd_neighbors[i];

		if (actor == world || actor.classname != "ai_dog" || actor.aistatus != "1" || actor.health <= 0 || actor.outside || fabs(actor.origin_z - self.origin_z) >= 24)
			continue;

		vector delta = actor.origin - self.origin;
		delta_z = 0;
		float distance = vlen(delta);

		if (distance >= 64)
			continue;

		float ahead = delta * heading;
		float lateral = delta * side;

		if (ahead > 0 && fabs(lateral) < 32) {
			float spacing = sqrt(3600 * (1 - lateral * lateral / 1024));
			float following = clamp(actor.velocity * heading + (ahead - spacing) * 4, 0, speed);
			if (following < limit)
				limit = following;

			float pass_side = fabs(lateral) >= 4 ? (lateral > 0 ? -1 : 1) : ((int)self < (int)actor ? -1 : 1) * orientation;
			separation += side * pass_side * clamp((64 - ahead) / 32, 0, 1);
		}

		if (distance < 1) {
			separation += side * ((int)self < (int)actor ? -1 : 1) * orientation;
		} else {
			float personal_space = 36 + 24 * fabs(ahead / distance);
			separation -= delta / distance * clamp((personal_space - distance) / 24, 0, 1);
		}
	}

	if (separation == '0 0 0' && (idle || limit == speed))
		return wish_velocity;

	float pressure = vlen(separation);
	if (pressure > 1)
		separation /= pressure;

	vector result = heading * limit + separation * speed * 0.75;
	float along = result * heading;
	if (idle || along < 0)
		result -= heading * along;
	if (vlen(result) > speed)
		result = normalize(result) * speed;

	vector start = self.origin + '0 0 0.03125';
	tracebox(start, '-16 -16 -32', '16 16 40', start + result * 0.1, true, self);
	if (!trace_startsolid && !trace_allsolid && trace_fraction == 1)
		return result;

	return heading * limit;
};

void() Dog_LungeMove =
{
	vector start = self.origin + '0 0 0.03125';
	vector end = start + [self.velocity_x, self.velocity_y, 0] * 0.1;
	tracebox(start, '-16 -16 -32', '16 16 40', end, false, self);

	float fraction = trace_fraction;
	if (trace_startsolid || trace_allsolid)
		fraction = 0;
	self.velocity_x *= fraction;
	self.velocity_y *= fraction;
};

void() Dog_Attack =
{
	if (self.is_attacking || !(self.flags & FL_ONGROUND) || self.enemy.classname != "player" || self.enemy.downed || self.enemy.is_spectator || self.enemy.health <= 0)
		return;

	vector direction = self.enemy.origin - self.origin;
	direction_z = 0;
	self.ideal_yaw = vectoyaw(direction);
	ChangeYaw();
	self.is_attacking = true;
	self.movetype = MOVETYPE_TOSS;
	self.ads_release = true;
	self.velocity = normalize(direction) * 400;
	self.velocity_z = 160;
	self.flags &= ~FL_ONGROUND;
	dog_meleeanim();
};

void() Dog_Bite =
{
	self.velocity_x = self.velocity_y = 0;

	if (self.enemy.classname != "player" || self.enemy.downed || self.enemy.is_spectator || self.enemy.health <= 0)
		return;

	traceline(self.origin + '0 0 8', self.enemy.origin, false, self);
	if (trace_startsolid)
		return;
	if (trace_fraction < 1) {
		if (trace_ent != self.enemy)
			return;
	}
	zombie_attack2();
};

void() Dog_AttackFinish =
{
	self.is_attacking = false;
	self.movetype = MOVETYPE_WALK;
	Dog_Walk_Setup();
};

float dogCount;

void(entity ent) Dog_Death_Cleanup = {
	// Already dead
	if(ent.aistatus == "0") {
		return;
	}
	if (ent.enemy.classname == "player" && ent.enemy.hunt_count > 0)
		ent.enemy.hunt_count--;

	ent.enemy = world;
	ent.is_attacking = false;
	ent.velocity = '0 0 0';
	ent.ads_release = 0;
	ent.dog_run_check_time = 0;
	ent.aistatus = "0";
	ent.solid = SOLID_NOT;
	ent.movetype = MOVETYPE_NONE;
	ent.takedamage = DAMAGE_NO;
	
	sound(ent, CHAN_WEAPON, "sounds/null.wav", 1, ATTN_NORM);
	
	ent.usedent = world;
	ent.health = 0;
	Remaining_Zombies = Remaining_Zombies - 1;
	dogCount -= 1;
}


void() Dog_Death = {
	Dog_Death_Cleanup(self);
	
	if(rounds == dogRound && Remaining_Zombies == 0) {
		Spawn_Powerup(self.origin, PU_MAXAMMO);
	}

	if (self.onfire || self.electro_targeted) {
		self.frame = 0;
		setmodel(self, "models/sprites/explosion.spr");
		Sound_PlaySound(self, "sounds/weapons/grenade/explode.wav", SOUND_TYPE_WEAPON_EXPLODE, SOUND_PRIORITY_PLAYALWAYS);
		dog_explodeanim();
	} else {
		dog_deathanim();
	}

	Sound_PlaySound(self, "sounds/hound/d0.wav", SOUND_TYPE_ZOMBIE_LOUD, SOUND_PRIORITY_PLAYALWAYS);

	self.onfire = 0;
	self.ads_release = 0;
	spawn_time = time + zombie_spawn_delay;
};


// DOG WAFFE DEATH
// 37-46
void() dog_die_wunder1 	=[ 37, 	dog_die_wunder2 	] {tesla_arc();};
void() dog_die_wunder2 	=[ 38, 	dog_die_wunder3 	] {tesla_arc();};
void() dog_die_wunder3 	=[ 39, 	dog_die_wunder4 	] {tesla_arc();};
void() dog_die_wunder4 	=[ 40, 	dog_die_wunder5 	] {tesla_arc();};
void() dog_die_wunder5 	=[ 41, 	dog_die_wunder6 	] {tesla_arc();};
void() dog_die_wunder6 	=[ 42, 	dog_die_wunder7 	] {tesla_arc();};
void() dog_die_wunder7 	=[ 43, 	dog_die_wunder8 	] {tesla_arc();};
void() dog_die_wunder8 	=[ 44, 	dog_die_wunder9 	] {tesla_arc();};
void() dog_die_wunder9 	=[ 45, 	dog_die_wunder10 	] {tesla_arc();};
void() dog_die_wunder10 =[ 46, 	SUB_Null 	] {tesla_arc(); self.iszomb=0; self.nextthink=time+3; self.think=removeZombie;};


void() Dog_Death_Tesla = {
	Dog_Death_Cleanup(self);
	// TODO - place tesla spark correctly
	tesla_spark(self.origin);

	if(rounds == dogRound && Remaining_Zombies == 0 && cvar("sv_magic") != 0) {
		Spawn_Powerup(self.origin, PU_MAXAMMO);
	}

	dog_die_wunder1();
};

//
// Dog_FindEnemy()
// Hellhounds are assigned an enemy at start,
// based on how many Hounds are stalking each
// player already.
//
entity(entity dog) Dog_FindEnemy =
{
	entity least_targeted_player = world;

	// Assume that if this is being called again, stop hunting
	// currently selected client
	if (dog.enemy.classname == "player" && dog.enemy.hunt_count > 0)
		dog.enemy.hunt_count--;

	dog.ads_release = 0;
	dog.dog_run_check_time = 0;

	// Grab every player in the World
	entity players = find(world, classname, "player");
	while(players != world) {
		// Don't target players in Last Stand
		if (!players.downed && !players.is_spectator && players.health > 0) {
			// Init least_targeted_player
			if (least_targeted_player == world)
				least_targeted_player = players;

			// This player has less dogs following them than the last,
			// make this our new golden goose.
			if (players.hunt_count < least_targeted_player.hunt_count)
				least_targeted_player = players;
		}

		players = find(players, classname, "player");
	}

	// Return the player we found
	if (least_targeted_player != world) {
		least_targeted_player.hunt_count++;
		return least_targeted_player;
	}

	// Couldn't find a player, go lurk at a spawn point
	return find(world, classname, "info_player_1_spawn");
}

//
// Dog_GetHealth()
// Returns the amount of health Hellhounds
// should have.
//
float() Dog_GetHealth =
{
	switch(dog_round_count) {
		case 1: return 400;
		case 2: return 900;
		case 3: return 1300;
		default: return 1600;
	}

	return 1600;
}

void(entity where) spawn_a_dogB =
{
	local entity sdog;//USED FOR WHAT TO SPAWN
	
	sdog = getFreeZombieEnt();
	if(sdog == world)
	{
		return;
	}

	sdog.origin = where.origin;
	sdog.frame = 0;
	
	sdog.target = where.target;	
	
	sdog.solid = SOLID_CORPSE;
	sdog.movetype = MOVETYPE_WALK;
	setmodel(sdog, "models/ai/dog.mdl");
	sdog.hop_step = 0;
	sdog.gravity = 1.0;
	
	sdog.scale = 1.125;
	sdog.mins = '-16 -16 -32';
	sdog.maxs = '16 16 18';
	setsize (sdog, sdog.mins, sdog.maxs);
		
	if(pointcontents(sdog.origin - '0 0 36') == -2)
	{
		while(pointcontents (sdog.origin - '0 0 36') == -2)
		{
			sdog.origin = sdog.origin + '0 0 1';
			setorigin(sdog,sdog.origin );
		}
	}

	sdog.classname = "ai_dog";
	sdog.aistatus = "1";
	setorigin (sdog.goaldummy, '0 0 0');
	sdog.origin_z = sdog.origin_z + 1;
	sdog.takedamage = DAMAGE_YES;
	setorigin(sdog, sdog.origin);
	sdog.flags = sdog.flags | FL_PARTIALGROUND | FL_MONSTER;

	sdog.spawnflags = where.spawnflags;
	sdog.spawnflags = sdog.spawnflags | 1;
	
	sdog.ideal_yaw = sdog.angles_y;
	sdog.yaw_speed = 20;
	sdog.health = sdog.max_health = Dog_GetHealth();
	sdog.th_die = Dog_Death;
	sdog.th_walk = Dog_Walk_Setup;
	sdog.outside = FALSE;
	sdog.iszomb = 1;
	sdog.onfire = (random() > 0.5);
	
	sdog.th_melee = Dog_Attack;
	sdog.th_idle = dog_idleanim;
	sdog.th_diewunder = Dog_Death_Tesla;
	sdog.enemy = Dog_FindEnemy(sdog);
	sdog.enemy_timeout = 0;
	sdog.attack_delay = 0;

	sdog.electro_targeted = 0;
	sdog.skin = 0;

	SetZombieWalk(sdog);
	
	sdog.reload_delay = 30 + time;//save  floats, equals respawn time.
	local entity old_self;
	old_self = self;
	self = sdog;
	//droptofloor();
	self.th_walk();
	self = old_self;
};

void() dogsprite_think =
{
	self.frame++;

	if (self.frame >= 3)
		self.frame = 0;
	
	// suicide timer!
	if(self.ltime < time) {
		spawn_a_dogB(self.owner);
		remove(self);
	}

	self.nextthink = time + 0.05;
}

void(entity where) spawn_dog_lightning =
{
	local entity tempe;
	local entity doglight;
	local entity dogsprite;

	// lightning model
	doglight = spawn();
	setmodel(doglight, "models/ai/dog_lightning.mdl");
	setorigin(doglight, where.origin - '0 0 20');
	tempe = self;
	self = doglight;
	dog_lightninganim();
	self = tempe;

	// lightning sprite
	dogsprite = spawn();
	setmodel(dogsprite, "models/sprites/lightning.spr");
	setorigin(dogsprite, where.origin);
	dogsprite.effects = EF_FULLBRIGHT;
	dogsprite.owner = where;
	dogsprite.think = dogsprite_think;
	dogsprite.nextthink = time + 0.05;
	dogsprite.ltime = time + 1.3; // we use ltime here to be out remove timer,
								  // since using frames interrupts think()

	Sound_PlaySound(world, "sounds/misc/electric_bolt.wav", SOUND_TYPE_ENV_VOICE, SOUND_PRIORITY_PLAYALWAYS);
}

float() spawn_a_dogA =
{
	local float pcount;
	local entity thing, szombie;
	local float FAIL;
	
	FAIL = false;
	pcount = 0;
	szombie = getFreeZombieEnt();
	if(szombie == world || dogCount >= (2 * (player_count)))
	{
		return 0;
	}
	lastspawn = find(lastspawn, classname, "spawn_dog");
	while (random() < 0.4)
	{
		lastspawn = find(lastspawn, classname, "spawn_dog");
	}
	
	while(lastspawn)
	{
		thing = findradius(lastspawn.origin, 60);
		while (thing)
		{
			pcount = 0;
			if (thing.classname == "ai_dog")
			{
				pcount = 1;
				break;
			}
			thing = thing.chain;
		}
		if (!pcount && random() < 0.6)
		{
			//spawn_a_dogB(lastspawn);
			spawn_dog_lightning(lastspawn);
			dogCount++;
			spawn_time = time + zombie_spawn_delay;
			return true;
		}
		lastspawn = find(lastspawn, classname, "spawn_dog");
	}
	return 0; //no free locations fround
};

void() spawn_dog =
{
	precache_model("models/ai/dog.mdl");
	precache_model("models/ai/dog_lightning.mdl");
	precache_model("models/sprites/lightning.spr");
	precache_model("models/sprites/explosion.spr");

	precache_sound("sounds/rounds/droundend.wav");
	precache_sound("sounds/rounds/droundstart.wav");
	
	precache_sound("sounds/misc/electric_bolt.wav");
	precache_sound("sounds/hound/d0.wav");
	precache_sound("sounds/hound/a0.wav");
	precache_sound("sounds/hound/t0.wav");
	precache_sound("sounds/hound/t1.wav");

	setsize(self, '0 0 0', '0 0 0');
	if (self.spawnflags & INACTIVE)
	{
		if (cvar("developer"))
			setmodel(self, "models/player.mdl");
		self.classname = "spawn_dog_in";
	}
	else
	{
		if (cvar("developer"))
			setmodel(self, "models/ai/dog.mdl");
		self.classname = "spawn_dog";
	}
	
	self.solid = SOLID_NOT;
};