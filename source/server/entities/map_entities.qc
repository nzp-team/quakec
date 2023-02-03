/*
	server/entities/map_entities.qc

	misc map entity spawn and logic

	Copyright (C) 2021-2022 NZ:P Team

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

void() func_wall =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_PUSH;	// so it doesn't get pushed by anything
	self.solid = SOLID_BSP;
	setmodel (self, self.model);

	#ifdef PC
	HalfLife_DoRender();
	#endif
};

void() func_illusionary =
{
	self.angles = '0 0 0';
	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_NOT;
	setmodel (self, self.model);

	#ifdef PC
	HalfLife_DoRender();
	#endif
	// makestatic (self); // dr_mabuse1981: dont use makestatic, it doesnt show the HL rendermodes then.
};

// button and multiple button

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
	
	if(self.cost)
	{
		if(self.state == STATE_BOTTOM||self.state == STATE_DOWN)
		{
			centerprint(other,"Press use to buy [cost:");
			centerprint(other,ftos(self.cost));
			centerprint(other,"]\n");
			if (other.button7)
			{
				if(other.points >= self.cost)
				{
					self.enemy = other;
					addmoney(other, 0 - self.cost, FALSE);
					button_fire();
					return;
				}
				else
				{
					centerprint(other, STR_NOTENOUGHPOINTS);

				}
			}
		}
	}
	else
	{
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


/*QUAKED func_button (0 .5 .8) ?
When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.

"angle"		determines the opening direction
"target"	all entities with a matching targetname will be used
"speed"		override the default 40 speed
"wait"		override the default 1 second wait (-1 = never return)
"lip"		override the default 4 pixel lip remaining at end of move
"health"	if set, the button must be killed instead of touched
"sounds"
0) steam metal
1) wooden clunk
2) metallic click
3) in-out
*/

void() func_button =
{
	SetMovedir ();
	
	self.movetype = MOVETYPE_PUSH;
	self.solid = SOLID_BSP;
	setmodel (self, self.model);

	self.blocked = button_blocked;
	self.use = button_use;
	
	if (self.health)
	{
		self.max_health = self.health;
		self.th_die = button_killed;
		self.takedamage = DAMAGE_YES;
	}
	else
		self.touch = button_touch;

	if (!self.speed)
		self.speed = 40;
	if (!self.wait)
		self.wait = 1;
	if (!self.lip)
		self.lip = 4;

	self.state = STATE_BOTTOM;

	self.pos1 = self.origin;
	self.pos2 = self.pos1 + self.movedir*(fabs(self.movedir*self.size) - self.lip);

	#ifdef PC
	HalfLife_DoRender();
	#endif
};

void() flame_update = {	
	#ifndef PC	
	particle (self.origin, v_up, 111, 0);
	#else
	te_flamejet(self.origin, v_up, 10);
	#endif
	self.think = flame_update;
	self.nextthink = time + random()+0.1;
}
void() place_fire =
{
	#ifndef PC
	particle (self.origin, v_up*8, self.frame, 0);
	#else
	te_flamejet(self.origin, v_up*8, 10);
	#endif
	self.think = flame_update;
	self.nextthink = time + random()+0.1;
};

void () buy_weapon_touch =
{
	entity oldent;
	float tempf, tempf1, tempf2, tempf3;
	float startframe,endframe;
	string modelname;

	float wcost;

	if (other.classname != "player" || other.downed || other.isBuying) {
		return;
	}

	if (self.weapon != 99) {
		#ifndef PC
		other.Weapon_Name_Touch = GetWeaponName(self.weapon);
		#endif

		float slot;

		// Player has this weapon in any of their slots, PaP'd or not.
		if ((slot = Util_PlayerHasWeapon(other, self.weapon, true)) != 0) {
			float is_pap = true;


			// But the utility function returns the same value if we are NOT PaP'd
			if (Util_PlayerHasWeapon(other, self.weapon, false) == slot)
				is_pap = false;

			// Set the cost and weapon value (for useprint).
			wcost = (is_pap) ? 4500 : self.cost2;
			float wep = (is_pap) ? EqualPapWeapon(self.weapon) : self.weapon;

			useprint(other, 3, wcost, wep);

			if (!other.button7 || other.semiuse || other.isBuying) {
				return;
			}

			// Store current Ammo value.
			float ammo = Util_GetPlayerAmmoInSlot(other, slot);

			// Max carrying capacity of the wall weapon
			float wall_ammo = (is_pap) ? getWeaponAmmo(EqualPapWeapon(self.weapon)) : getWeaponAmmo(self.weapon);

			// Weapon is already full. Abort.
			if (ammo >= wall_ammo)
				return;

			other.semiuse = true;

			// Player doesn't have enough points. Abort.
			if (other.points < wcost) {
				centerprint(other, STR_NOTENOUGHPOINTS);
				return;
			}

			other.ach_tracker_coll++;

			// Set the weapon's ammo to the max capacity.
			Util_SetPlayerAmmoInSlot(other, slot, wall_ammo);

			sound(other, 0, "sounds/misc/ching.wav", 1, 1);
			other.reload_delay = 0;

			// Subtract the cost from player points.
			addmoney(other, wcost*-1, 0);

			if (self.enemy) {
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
	} else 
	// Universal Ammo buy
	{
		#ifndef PC
		other.Weapon_Name_Touch = GetWeaponName(other.weapon);
		#endif

		if (other.currentammo < getWeaponAmmo(other.weapon)) {

			// Set the cost and weapon value (for useprint).
			wcost = (IsPapWeapon(other.weapon)) ? 4500 : self.cost2;

			useprint(other, 3, wcost, other.weapon);

			if (!other.button7 || other.semiuse || other.isBuying) {
				return;
			}

			// Player doesn't have enough points. Abort.
			if (other.points < wcost) {
				centerprint(other, STR_NOTENOUGHPOINTS);
				return;
			}

			other.currentammo = getWeaponAmmo(other.weapon);

			sound(other, 0, "sounds/misc/ching.wav", 1, 1);
			other.reload_delay = 0;

			// Subtract the cost from player points.
			addmoney(other, wcost*-1, 0);

			if (self.enemy) {
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
	}
	if (self.weapon == W_BETTY)
	{
		if (other.secondary_grenades < 2)
			useprint (other, 3, self.cost2, self.weapon);
		else
			return;
		if (!other.button7 || other.semiuse)
			return;
		if (other.points < self.cost2)
		{
			centerprint(other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			return;
		}
		else
		{
			other.ach_tracker_coll++;
			other.reload_delay = 0;
			sound(other, 0, "sounds/misc/ching.wav", 1, 1);
			//other.boughtweapon = true;
			addmoney(other, 0 - self.cost2, FALSE);
			other.grenades = other.grenades | 2;
			other.secondary_grenades = 2;
			if (self.enemy)
			{
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
		other.semiuse = true;
		return;
	}
	else if (self.weapon == W_GRENADE)
	{
		if (other.primary_grenades < 4)
			useprint (other, 3, self.cost2, self.weapon);
		else
			return;
		if (!other.button7 || other.semiuse)
			return;
		if (other.points < self.cost)
		{
			centerprint(other, STR_NOTENOUGHPOINTS);
			sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);

			return;
		}
		else
		{
			other.ach_tracker_coll++;
			other.reload_delay = 0;
			sound(other, 0, "sounds/misc/ching.wav", 1, 1);
			//other.boughtweapon = true;
			addmoney(other, 0 - self.cost, FALSE);
			other.primary_grenades = 4;
			if (self.enemy)
			{
				oldent = self;
				self = self.enemy;
				self.use();
				self = oldent;
			}
		}
		other.semiuse = true;
		return;
	}
	else if (self.weapon == W_BOWIE)
	{
		if (!other.bowie) {
			useprint(other, 3, self.cost2, self.weapon);
			if (other.button7)
			{
				if (other.points < self.cost2) {
					centerprint(other, STR_NOTENOUGHPOINTS);
					return;
				} else {
					addmoney(other, -self.cost2, FALSE);
					other.ach_tracker_coll++;
					entity tempz;
					tempz = self;
					self = other;
					Set_W_Frame(15, 30, 0, 0, 0, ReturnWeaponModel, "models/weapons/knife/v_bowie.mdl", false, S_BOTH);
					self.bowie = 1;
				}
			}
		}
	}
	else if (self.weapon != 99)
	{
		entity tempe;

		//centerprint(other, self.message);
      	useprint (other, 4, self.cost, self.weapon);

		if (!other.button7 || other.semiuse) {
			return;
		}

		other.semiuse = 1;
		if (other.points < self.cost) {
			centerprint (other, STR_NOTENOUGHPOINTS);
			return;
		}

		other.semiuse = true;
		other.ach_tracker_coll++;

		if (other.weapon && !other.secondaryweapon) {
			tempf = other.currentammo;
			other.currentammo = other.secondaryammo;
			other.secondaryammo = tempf;

			tempf1 = other.currentmag;
			other.currentmag = other.secondarymag;
			other.secondarymag = tempf1;

			tempf2 = other.weapon;
			other.weapon = other.secondaryweapon;
			other.secondaryweapon = tempf2;

			tempf3 = other.currentmag2;
			other.currentmag2 = other.secondarymag2;
			other.secondarymag2 = tempf3;
		} else if (other.weapon && other.secondaryweapon) {
			if ((other.perks & P_MULE) && !other.thirdweapon) {
				// store secondary weapon
				tempf = other.secondaryweapon;
				tempf1 = other.secondarymag;
				tempf2 = other.secondaryammo;
				tempf3 = other.secondarymag2;
				// move primary to secondary
				other.secondaryweapon = other.weapon;
				other.secondarymag = other.currentmag;
				other.secondarymag2 = other.currentmag2;
				other.secondaryammo = other.currentammo;
				// move secondary to tertiary
				other.thirdweapon = tempf;
				other.thirdmag = tempf1;
				other.thirdammo = tempf2;
				other.thirdmag2 = tempf3;
			}

			// free current slot
			other.currentammo = 0;
			other.currentmag = 0;
			other.weapon = 0;
		}

		sound(other, 0, "sounds/misc/ching.wav", 1, 1);
		other.reload_delay = 0;
		addmoney(other, -1*self.cost, 0);
		if (self.enemy) {
			oldent = self;
			self = self.enemy;
			self.use();
			self = oldent;
		}
		other.weapon = self.weapon;

		other.currentammo = getWeaponAmmo(self.weapon);
		other.currentmag = getWeaponMag(self.weapon);
		tempe = self;
		self = other;
		startframe = GetFrame(self.weapon,TAKE_OUT_START);
		endframe = GetFrame(self.weapon,TAKE_OUT_END);
		modelname = GetWeaponModel(self.weapon, 0);

		if (self.weapon != W_KAR_SCOPE && self.weapon != W_HEADCRACKER && !IsDualWeapon(self.weapon)) {
			self.weapon2model = "";
		}

		SwitchWeapon(self.weapon);
		Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);//FIXME

		#ifndef PC
		self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);
		self.Flash_Size = GetWeaponFlash_Size(self.weapon);
		self.Weapon_Name = GetWeaponName(self.weapon);
		#endif

		self = tempe;
	}

	if (other.ach_tracker_coll == ach_tracker_col2) {
		GiveAchievement(12, other);
	}
};

void() buy_weapon_link_target =
{
	entity ent;
	
	ent = find (world, targetname, self.target);
	
	if (ent.classname == "weapon_wall")
	    self.enemy = ent;
}

void() buy_weapon =
{
	string weaponname;
	InitTrigger ();

	weaponname = GetWeaponModel (self.weapon, 0);
	if (weaponname != "")
		precache_model (weaponname);

	// Use the grenade bag instead for nades
	if (self.weapon == W_GRENADE)
		weaponname = "models/props/grenade_bag.mdl";
	else
		weaponname = GetWeaponModel(self.weapon, 1);
	if (weaponname != "")
		precache_model (weaponname);
	
	precache_extra (self.weapon);
	self.touch = buy_weapon_touch;
	
	self.think = buy_weapon_link_target;
	self.nextthink = time + 0.2; 

	ach_tracker_col2++;
	
	precache_sound("sounds/misc/ching.wav");
};

.float radioState;
.float length;
.string tune;
void() radioPlay =
{
	self.health = 1;

	if (self.radioState == 1) {
		sound (self, CHAN_ITEM, self.tune, 1, ATTN_NORM);
		self.nextthink = time + self.length;
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
	self.nextthink = time + 1;//getSoundLen("sounds/music/tune1.wav");
	self.think = radioPlay;
	
	if (self.radioState == 0)
		self.radioState = 1;
	else if (self.radioState == 1)
		self.radioState = 0;
}

void() item_radio = 
{
	precache_model ("models/props/radio.mdl");
	precache_sound ("sounds/misc/radio.wav");

	if(self.tune) {
		precache_sound (self.tune);
	}

	self.movetype = MOVETYPE_NONE;	// so it doesn't get pushed by anything
	self.solid=SOLID_BBOX;
	self.classname = "item_radio";
	setmodel (self, "models/props/radio.mdl");
	setsize (self, '-8 -8 -4', '8 8 4');

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
	self.solid=SOLID_BBOX;
	self.classname = "teddy_spawn";
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

void() touch_songtrigger = {
	if (other.classname != "player" || self.activated)
		return;

	if (other.button7) {
		sound(self, CHAN_VOICE, self.tune, 1, ATTN_NORM);
		self.activated = true;
		sndActivCnt++;

		if (sndTriggerCnt == sndActivCnt)
			playSoundAtPlayers(world.song);
	}
	
}

void() trigger_song = {
	#ifndef PC
	remove(self);
	#endif

	precache_model(self.model);
	precache_sound(self.tune);

	self.movetype = MOVETYPE_NONE;
	self.solid = SOLID_TRIGGER;
	self.classname = "trigger_song";
	setmodel(self, self.model);
	setsize(self, VEC_HULL2_MIN, VEC_HULL2_MAX);

	self.touch = touch_songtrigger;

	sndTriggerCnt++;
}

/* ================
    Buyable Ending
   ================ */
void() touch_ending =
{
	if (other.classname != "player" || self.activated)
		return;
	
	useprint(other, 20, self.cost, 0);

	if (other.button7) {

		if (other.points < self.cost)
			return;

		addmoney(other, -self.cost, 0);

		local entity tempe;
		tempe = self;
		self = other;
		EndGameSetup();
		self = tempe;

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
    if (!self.last_frame && !(self.spawnflags & 1) && !(self.spawnflags & MISC_MODEL_SOLID) && !self.targetname)
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

	misc_model_use();
};

//
// place_model()
// Converts old place_model entities to use misc_model instead.
//
void() place_model =
{  
	// Grab an updated model path.
	self.model = convert_old_asset_path(self.model);
  
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