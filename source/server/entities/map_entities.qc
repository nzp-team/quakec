/*
	server/entities/map_entities.qc

	misc map entity spawn and logic

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

string(float wep, float gorvmodel) GetWeaponModel;
void() ReturnWeaponModel;

void() flame_update = 
{	
	Effect_Fire(self.origin);

	self.think = flame_update;
	self.nextthink = time + random()+0.1;
}

void() place_fire =
{
	Effect_Fire(self.origin);

	self.think = flame_update;
	self.nextthink = time + random()+0.1;
};

.float radioState;
.float length;
.string tune;
#define SPAWNFLAG_RADIO_PLAYONCE 	1
void() radioPlay =
{
	self.health = 1;

	if (self.radioState == 1) {
		sound (self, CHAN_ITEM, self.tune, 1, ATTN_NORM);


		if (!(self.spawnflags & SPAWNFLAG_RADIO_PLAYONCE))
#ifndef FTE

			self.nextthink = time + GetSoundLen(self.tune);

#else

			self.nextthink = time + self.length;

#endif // FTE

		self.think = radioPlay;
	} else if (self.radioState == 0) {
		sound (self, CHAN_ITEM, "sounds/null.wav", 1, ATTN_NONE);
		self.nextthink = 0;
		self.think = SUB_Null;
	}
}

void() radio_hit =
{
	self.health = 1;

	sound (self, CHAN_ITEM, "sounds/misc/radio.wav", 1, ATTN_NORM);
	self.nextthink = time + 1;
	self.think = radioPlay;
	
	if (self.radioState == 0)
		self.radioState = 1;
	else if (self.radioState == 1)
		self.radioState = 0;

	if (self.spawnflags & SPAWNFLAG_RADIO_PLAYONCE)
		self.takedamage = DAMAGE_NO;
}

void() item_radio = 
{
	if (!self.model) self.model = "models/props/radio.mdl";
	if (!self.mins) self.mins = '-8 -8 -4';
	if (!self.maxs) self.maxs = '8 8 4';
	
	precache_model (self.model);
	precache_sound ("sounds/misc/radio.wav");

	// Backwards compatibility
	if (!self.tune) {
		self.tune = "sounds/music/tune1.wav";
		self.length = 10.1;
	}

	precache_sound (self.tune);
	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid=SOLID_BBOX;
	self.classname = "item_radio";
	setmodel (self, self.model);
	setsize (self, self.mins, self.maxs);

	self.takedamage = DAMAGE_YES;
	self.health = 1;
	self.radioState = 0;
	self.th_die = radio_hit;
};

/* ================
   Custom Teddy Code
   ================*/

void() teddy_spawn = 
{
	precache_model ("models/props/teddy.mdl");

	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid = SOLID_BBOX;
	self.classname = "teddy_spawn";
	self.noise = Compat_ConvertOldAssetPath(self.noise);
	setmodel (self, "models/props/teddy.mdl");
	setsize (self, '-8 -8 -4', '8 8 4');

	self.takedamage = DAMAGE_YES;
	self.health = 0;
	self.th_die = teddy_react;
	
	if (self.noise)
		precache_sound (self.noise);
};

/* ==================
    Custom Song Code
   ================== */
   
void() game_songtriggered =
{
	songegg(self.aistatus);
	music_override = time + self.cost;
}

void() game_songplay =
{
	self.use = game_songtriggered;
};

// Old gross ent..
void() trigger_song = { remove(self); }

//
// ============================================================
// misc_model()
// Entity for prop/other model placement, derived from
// progs_dump. Deprecates place_model.
// ============================================================
// Modifications from stock:
// - Added new spawnflag 64 for fullbright.
// - 'model' is now the preffered model field instead of 'mdl'.
//

// Spawnflags
#define MISC_MODEL_GRAVITY 			1
#define MISC_MODEL_SOLID 			2
#define MISC_MODEL_BACK_AND_FORTH	4
#define MISC_MODEL_ONLY_ONCE		8
#define MISC_MODEL_PLAY_COUNT		16
#define MISC_MODEL_STARTOFF			32
#define MISC_MODEL_FULLBRIGHT 		64

// States
#define STATE_ACTIVE 				0
#define STATE_INACTIVE				1
#define STATE_INVISIBLE				8

// Entity fields
.float 	first_frame; 				// The starting frame of the animation
.float	last_frame; 				// The ending frame of the animation
.string	mdl;
.vector	mdlsz;
.vector	centeroffset;
.float	count;						// for counting triggers
.float	cnt; 						// misc flag

void() misc_model_use = 
{
	// Make invisible
	if (self.state == STATE_ACTIVE) {
		if (self.spawnflags & MISC_MODEL_SOLID) self.solid = SOLID_NOT;
		self.oldmodel = self.model;
		self.model = "";

		self.state = STATE_INVISIBLE;
		setorigin(self, self.origin);
	}
	// Have it appear again
	else {
		if (self.spawnflags & MISC_MODEL_SOLID) self.solid = SOLID_BBOX;
		self.model = self.oldmodel;

		self.state = STATE_ACTIVE;
		setorigin(self, self.origin);
	}
};

void() misc_model_think = 
{
    self.nextthink = time + fabs(self.speed);

    if (self.state != STATE_ACTIVE) 
		return;
    
    self.frame = self.frame + sign(self.speed);

    if (self.spawnflags & MISC_MODEL_BACK_AND_FORTH && self.frame < self.first_frame) {
  		self.speed = -1 * self.speed;
  		self.frame += 2;
  	} else if (self.spawnflags & MISC_MODEL_BACK_AND_FORTH && self.frame > self.last_frame) {
  		self.speed = -1 * self.speed;
  		self.frame-=2;
  	}
  	else
  		self.frame = wrap(self.frame, self.first_frame, self.last_frame);

  	if (self.spawnflags & MISC_MODEL_ONLY_ONCE && self.frame == self.last_frame && self.last_frame != self.first_frame)
		self.nextthink = -1;

    if (self.spawnflags & MISC_MODEL_PLAY_COUNT && self.frame == self.last_frame && self.last_frame != self.first_frame)
    {
		if (!self.count)
        	objerror ("Error: set count to the number of animation cycles!");

      	self.cnt = self.cnt +1;

      	dprint (ftos(self.cnt));
      	dprint ("\n");

      	if (self.cnt != self.count)
        	return FALSE;
      	else
    		self.nextthink = -1;
    }
};

void() misc_model = 
{
    if (!self.mdl || self.mdl == "") {
		// NZP: Check for .model instead
		if (!self.model || self.model == "")
        	objerror("Model not defined");
	} else {
		// Convert to .model instead of .mdl
		self.model = self.mdl;
	}

	//
	// Set default stats.
	//

	// Center offset.
	if(!self.centeroffset)
		self.centeroffset = '0 0 0';

	// Custom Bounding Box.
	if(!self.mdlsz)
		self.mdlsz = '32 32 32';

	// Generate Proper Bounding Box size.
	vector vmin, vmax;
	vmin_x = self.centeroffset_x - (self.mdlsz_x / 2);
	vmin_y = self.centeroffset_y - (self.mdlsz_y / 2);
	vmin_z = self.centeroffset_z - (self.mdlsz_z / 2);

	vmax_x = self.centeroffset_x + (self.mdlsz_x / 2);
	vmax_y = self.centeroffset_y + (self.mdlsz_y / 2);
	vmax_z = self.centeroffset_z + (self.mdlsz_z / 2);
	setsize (self, vmin, vmax);

	// Set our model
    precache_model(self.model);
    setmodel(self, self.model);
	
	// Model has collision box
	if (self.spawnflags & MISC_MODEL_SOLID)
		self.solid = SOLID_BBOX;
	else
		self.solid = SOLID_NOT;

	// Model has gravity
	if (self.spawnflags & MISC_MODEL_GRAVITY)
		self.movetype = MOVETYPE_TOSS;
	else
		self.movetype = MOVETYPE_NONE;

	// Model is fullbright
	if (self.spawnflags & MISC_MODEL_FULLBRIGHT)
		self.effects = self.effects | EF_FULLBRIGHT;

    self.use = misc_model_use;


    if (!self.frame)
        self.frame = self.first_frame;

    // Make static (not animate) if not given a frame range, and not affected by gravity
    // also remains active if it has a targetname (so it can be killtargeted/toggled)
    if (!self.last_frame && !(self.spawnflags & 1) && !(self.spawnflags & MISC_MODEL_SOLID) && !self.targetname && self.classname != "place_model")
		makestatic(self);

	// if it as a custom animation range
    if (self.last_frame) {
    	// Default animation speed to 10 fps
	    if (!self.speed) {
	        self.speed = 0.1;
	    }
        self.nextthink = time + self.speed;
        self.think = misc_model_think;
    }
    
	// Start hidden
	if (self.spawnflags & MISC_MODEL_STARTOFF)    
		self.state = STATE_ACTIVE;
	else    
		self.state = STATE_INVISIBLE;

	if (self.classname != "place_model")
		misc_model_use();
};

//
// place_model()
// Converts old place_model entities to use misc_model instead.
//
void() place_model =
{  
	self.classname = "place_model";
	
	// Grab an updated model path.
	self.model = Compat_ConvertOldAssetPath(self.model);
  
	// Convert the VEC_HULL bounds to match mdlsz.
	self.mdlsz = '64 64 88';

	// misc_model just uses frame plainly.
	self.frame = self.sequence;
	
	// Move fullbright spawnflag to the new param.
	if (self.spawnflags & 1)
		self.spawnflags = 64;
	else
		self.spawnflags = 0;

	// Now just execute the misc_model spawn function.
	misc_model();
};

//
// game_counter()
// Quick and dirty game_counter implementation, referenced
// from TWHL docs (https://twhl.info/index.php/wiki/page/game_counter)
//
#define SPAWNFLAG_COUNTER_REMOVEONFIRE 		1
#define SPAWNFLAG_COUNTER_RESETONFIRE 		2
void() game_counter_increment =
{
	self.frags++;

	if (self.frags == self.health) {
		SUB_UseTargets();

		if (self.spawnflags & SPAWNFLAG_COUNTER_REMOVEONFIRE) {
			remove(self);
		} else if (self.spawnflags & SPAWNFLAG_COUNTER_RESETONFIRE) {
			self.frags = self.cost;
		}
	}
}

void() game_counter =
{
	// TODO: master checking..

	// Store the initial value in case RESET ON FIRE is set.
	self.cost = self.frags;

	// Every time its triggered, increment.
	self.use = game_counter_increment;
}