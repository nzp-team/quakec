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

// DOG RUN
// 0-6
$frame dogrun1 dogrun2 dogrun3 dogrun4 dogrun5 dogrun6 dogrun7
void()	dog_runanim		=[	$dogrun1,	dog_runanim2	] {Dog_Think();Zombie_Walk(30);self.frame = 0;};
void()	dog_runanim2	=[	$dogrun2,	dog_runanim3	] {Dog_Think();Zombie_Walk(20);self.frame = 1;};
void()	dog_runanim3	=[	$dogrun3,	dog_runanim4	] {Dog_Think();Zombie_Walk(20);self.frame = 2;zombie_footstep();};
void()	dog_runanim4	=[	$dogrun4,	dog_runanim5	] {Dog_Think();Zombie_Walk(20);self.frame = 3;};
void()	dog_runanim5	=[	$dogrun5,	dog_runanim6	] {Dog_Think();Zombie_Walk(20);self.frame = 4;};
void()	dog_runanim6	=[	$dogrun6,	dog_runanim7	] {Dog_Think();Zombie_Walk(20);self.frame = 5;};
void()	dog_runanim7	=[	$dogrun7, 	Dog_Walk_Setup 	] {Dog_Think();Zombie_Walk(20);self.frame = 6;zombie_footstep();};

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
void()	dog_meleeanim	=[	$dogmelee1, 	dog_meleeanim2	] {Dog_Think(); makevectors(self.angles); self.velocity += v_forward * 50; self.frame = 26;};
void()	dog_meleeanim2	=[	$dogmelee2, 	dog_meleeanim3	] {Dog_Think();Zombie_Walk(0);self.frame = 28;sound(self, CHAN_VOICE, "sounds/hound/a0.wav", 1, ATTN_NORM);};
void()	dog_meleeanim3	=[	$dogmelee3, 	dog_meleeanim4	] {Dog_Think();Zombie_Walk(0);zombie_attack2();self.frame = 30;};
void()	dog_meleeanim4	=[	$dogmelee4, 	dog_meleeanim5	] {Dog_Think();Zombie_Walk(0);self.frame = 32;};
void()	dog_meleeanim5	=[	$dogmelee5, 	dog_runanim		] {Dog_Think();Zombie_Walk(0);self.frame = 34;};

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

	if (random() > 0.5)
		sound(self, CHAN_VOICE, "sounds/hound/t0.wav", 1, ATTN_NORM);
	else
		sound(self, CHAN_VOICE, "sounds/hound/t1.wav", 1, ATTN_NORM);
}

void() Dog_Think =
{
	Dog_Taunt();

	// Hellhounds begin to run whenever their target is in their line of sight.
	// So perform a tracemove and see if it hits it
	if (self.ads_release == 0) {
#ifdef FTE
		float result = tracemove(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, self.enemy.origin, TRUE, self);
#else
		float result = tracemove_fake(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, self.enemy.origin, TRUE, self);
#endif // FTE
		self.ads_release = result;
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

float dogCount;

void(entity ent) Dog_Death_Cleanup = {
	// Already dead
	if(ent.aistatus == "0") {
		return;
	}
	ent.aistatus = "0";
	ent.solid = SOLID_NOT;
	ent.movetype = MOVETYPE_NONE;
	ent.takedamage = DAMAGE_NO;
	
	sound(ent, 5, "sounds/null.wav", 1, ATTN_NORM);
	
	ent.usedent = world;
	ent.health = 0;
	Remaining_Zombies = Remaining_Zombies - 1;
	dogCount -= 1;
}


void() Dog_Death = {
	Dog_Death_Cleanup(self);
	play_sound_z(3);
	//Gotta' make sure we set it back down instead of glitching it up, yo'
	if(self.s_time > 0 && sounds_playing > 0) {
		sounds_playing --;
		self.s_time = 0;
	}
	
	if(rounds == dogRound && Remaining_Zombies == 0) {
		Spawn_Powerup(self.origin, PU_MAXAMMO);
	}

	if (self.onfire || self.electro_targeted) {
		self.frame = 0;
		setmodel(self, "models/sprites/explosion.spr");
		sound (self, CHAN_WEAPON, "sounds/weapons/grenade/explode.wav", 1, ATTN_NORM);
		dog_explodeanim();
	} else {
		dog_deathanim();
	}

	sound(self, CHAN_BODY, "sounds/hound/d0.wav", 1, ATTN_NORM);

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

	if(rounds == dogRound && Remaining_Zombies == 0) {
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
entity() Dog_FindEnemy = 
{
	entity least_targeted_player = world;

	// Assume that if this is being called again, stop hunting
	// currently selected client
	if (self.enemy != world) {
		self.enemy.hunt_count--;
		self.ads_release = 0;
	}

	// Grab every player in the World
	entity players = find(world, classname, "player");
	while(players != world) {
		// Don't target players in Last Stand
		if (!players.downed) {
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
	
	sdog.mins = '-16 -16 -32';
	sdog.maxs = '16 16 4';
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
	sdog.health = Dog_GetHealth();
	sdog.th_die = Dog_Death;
	sdog.th_walk = Dog_Walk_Setup;
	sdog.outside = FALSE;
	sdog.iszomb = 1;
	sdog.onfire = (random() > 0.5);
	
	sdog.th_melee = dog_meleeanim;
	sdog.th_idle = dog_idleanim;
	sdog.th_diewunder = Dog_Death_Tesla;
	sdog.enemy = Dog_FindEnemy();

	sdog.electro_targeted = 0;

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
	dogsprite.owner = where;
	dogsprite.think = dogsprite_think;
	dogsprite.nextthink = time + 0.05;
	dogsprite.ltime = time + 1.3; // we use ltime here to be out remove timer,
								  // since using frames interrupts think()

	sound(self, CHAN_AUTO, "sounds/misc/electric_bolt.wav", 1, ATTN_NONE);
}

float() spawn_a_dogA =
{
	local float pcount;
	local entity thing, szombie;
	local float FAIL;
	
	FAIL = false;
	pcount = 0;
	szombie = getFreeZombieEnt();
	if(szombie == world || dogCount >= (2 * (player_count + 1)))
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