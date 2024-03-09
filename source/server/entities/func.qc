/*
	server/entities/func.qc

	Source file for func_* map entities.

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

// =================================
// func_illusionary
// =================================

void() func_illusionary =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel (self, self.model);

#ifdef FTE

	HalfLife_DoRender();
	
#endif // FTE

};

// =================================
// func_detail
// =================================

void() func_detail =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	setmodel (self, self.model);

#ifdef FTE

	HalfLife_DoRender();
	
#endif // FTE

};

void() func_wall = { func_detail(); }

// =================================
// func_rotating
// =================================

.vector spawnorigin;

void () hl_rotating =
{
	float mvspd, realmvspd;
	
	mvspd = 180;

	if (!self.speed)
		realmvspd = 300;
	else
		realmvspd = self.speed;
	
	if (self.spawnflags & 2)
		mvspd *= -1;
	
	if (self.spawnflags & 4)
		self.pos1_z += mvspd;
	else if (self.spawnflags & 8)
		self.pos1_x += mvspd;
	else {
		self.pos1_y += mvspd;
	}
	
	SUB_CalcAngleMove (self.pos1, realmvspd, hl_rotating);
};


void () func_rotating_use =
{
	if (self.electro_targeted == 0) {
		hl_rotating();
		self.electro_targeted = 1;
	} else {
		self.avelocity = '0 0 0';
		self.think = SUB_Null;
		self.electro_targeted = 0;
	}
};

void() rot_crush =
{
    DamageHandler(self, other, 1, S_ZOMBIE);
}
	
void () func_rotating =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;

#ifdef FTE

	HalfLife_DoRender();

#endif // FTE
	
	self.blocked = rot_crush;

	if (self.spawnflags & 64)
		self.solid = 0;
	else
		self.solid = 4;
	
	setmodel(self, self.model);

	if (self.spawnflags & 1) {	// start on
		func_rotating_use();
	}

	self.use = func_rotating_use;


	if (self.spawnorigin != '0 0 0')
		setorigin(self, self.spawnorigin);
};

// =================================
// func_train
// =================================

void() train_next;
void() func_train_find;

void() train_blocked =
{
	if (time < self.death_timer)
		return;

	self.death_timer = time + 0.5;

    DamageHandler(self, other, self.dmg, S_ZOMBIE);
};

void() train_use =
{
	if (self.think != func_train_find)
		return;		// already activated

	train_next();
};

void() train_wait =
{
	if (self.wait) {
		self.nextthink = self.ltime + self.wait;
		sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	} else {
        self.nextthink = self.ltime + 0.1;
    }
	
	self.think = train_next;
};

void() train_next =
{
	entity targ;

    // motolegacy -- looks like id liked reusing ent fields too!
	if (self.electro_targeted == 1) {
		train_wait();
		return;
	}
	
	targ = find (world, targetname, self.target);
	self.target = targ.target;

	if (!self.target) {
		objerror ("train_next: no next target");
	}

	if (targ.wait)
		self.wait = targ.wait;
	else
		self.wait = 0;

	sound (self, CHAN_VOICE, self.noise1, 1, ATTN_NORM);
	SUB_CalcMove (targ.origin - self.mins, self.speed, train_wait);
};

void() func_train_find =
{
	entity targ;

	targ = find (world, targetname, self.target);
	self.target = targ.target;

	setorigin (self, targ.origin - self.mins);
	if (!self.targetname) {	
        // not triggered, so start immediately
		self.nextthink = self.ltime + 0.1;
		self.think = train_next;
	}
};

void() func_train =
{	
	if (!self.speed)
		self.speed = 100;

	if (!self.target) {
		objerror ("func_train without a target");
	}

	if (!self.dmg)
		self.dmg = 2;

	if (self.sounds == 0) {
		self.noise = ("sounds/null.wav");
		precache_sound ("sounds/null.wav");
		self.noise1 = ("sounds/null.wav");
		precache_sound ("sounds/null.wav");
	}

	if (self.sounds == 1) {
		self.noise = ("sounds/misc/debris.wav");
		precache_sound ("sounds/misc/debris.wav");
		self.noise1 = ("sounds/misc/debris.wav");
		precache_sound ("sounds/misc/debris.wav");
	}

	self.cnt = 1;
	self.solid = SOLID_BSP;
	self.movetype = MOVETYPE_PUSH;
	self.blocked = train_blocked;
	self.use = train_use;
	self.classname = "train";

	setmodel (self, self.model);
	setsize (self, self.mins , self.maxs);
	setorigin (self, self.origin);

#ifdef FTE

	HalfLife_DoRender();

#endif // FTE
	
// start trains on the second frame, to make sure their targets have had
// a chance to spawn
	self.nextthink = self.ltime + 0.1;
	self.think = func_train_find;
};

// =================================
// func_button
// =================================

void() button_wait;
void() button_return;

void() button_wait =
{
	self.state = STATE_TOP;
	self.nextthink = self.ltime + self.wait;
	self.think = button_return;
	activator = self.enemy;
	SUB_UseTargets();
	self.frame = 1;			// use alternate textures
};

void() button_done =
{
	self.state = STATE_BOTTOM;
};

void() button_return =
{
	self.state = STATE_DOWN;
	SUB_CalcMove (self.pos1, self.speed, button_done);
	self.frame = 0;			// use normal textures

	if (self.health)
		self.takedamage = DAMAGE_YES;	// can be shot again
};


void() button_blocked =
{	// do nothing, just don't ome all the way back out
};


void() button_fire =
{
	if (self.state == STATE_UP || self.state == STATE_TOP)
		return;

	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);

	self.state = STATE_UP;
	SUB_CalcMove (self.pos2, self.speed, button_wait);
};


void() button_use =
{
	self.enemy = activator;
	button_fire ();
};

void() button_touch =
{
	if (other.classname != "player")
		return;
	
	if(self.cost) {
		if(self.state == STATE_BOTTOM||self.state == STATE_DOWN) {
			centerprint(other,"Press use to buy [cost:");
			centerprint(other,ftos(self.cost));
			centerprint(other,"]\n");

			if (other.button7 && !(other.semi_actions & SEMIACTION_USE)) {
				other.semi_actions |= SEMIACTION_USE;
				if(other.points >= self.cost) {
					self.enemy = other;
					addmoney(other, 0 - self.cost, FALSE);
					button_fire();

					return;
				} else {
					centerprint(other, STR_NOTENOUGHPOINTS);
					sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
				}
			}
		}
	} else {
        self.enemy = other;
        button_fire ();
	}
};

void() button_killed =
{
	self.health = self.max_health;
	self.takedamage = DAMAGE_NO;	// wil be reset upon return
	button_fire ();
};

void() func_button =
{
	SetMovedir ();
	
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	setmodel (self, self.model);

	self.blocked = button_blocked;
	self.use = button_use;
	
	if (self.health) {
		self.max_health = self.health;
		self.th_die = button_killed;
		self.takedamage = DAMAGE_YES;
	} else {
		self.touch = button_touch;
    }

	if (!self.speed)
		self.speed = 40;
	if (!self.wait)
		self.wait = 1;
	if (!self.lip)
		self.lip = 4;

	self.state = STATE_BOTTOM;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);

#ifdef FTE

	HalfLife_DoRender();
	
#endif // FTE

};

// =================================
// func_ending
// =================================

void() touch_ending =
{
	if (other.classname != "player" || self.activated)
		return;
	
	useprint(other, 20, self.cost, 0);

	if (other.button7) {

		if (other.points < self.cost)
			return;

		addmoney(other, -self.cost, 0);

		entity tempe;
		entity players = find(world, classname, "player");
		while(players != world) {
			tempe = self;
			self = players;
			self.downed = true;
			EndGameSetup();
			self = tempe;
			players = find(players, classname, "player");
		}

		self.activated = true;
	}
}

void() func_ending =
{  
	precache_model (self.model);
	
	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid = SOLID_TRIGGER;
	self.classname = "func_ending";
  	setmodel(self, self.model);
  	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
    self.touch = touch_ending;
};
