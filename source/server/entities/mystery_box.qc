/*
	server/entities/mystery_box.qc

	Mystery Box Entity Logic

	Copyright (C) 2021-2023 NZ:P Team

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

void(vector where, float time_alive) SpawnSpark;

#define MBOX_SPAWNFLAG_NOTHERE 		1
#define MBOX_SPAWNFLAG_NOLIGHT 		2


//
// MBOX_FreeEnt(ent)
// Marks an MBOX entity as able to be used.
//
void(entity ent) MBOX_FreeEnt =
{
	setmodel(ent, "");
	ent.classname = "freeMboxEntity";
	ent.touch = SUB_Null;
	ent.think = SUB_Null;
    ent.effects = 0;

#ifdef FTE

	ent.alpha = 1;

#endif // FTE

};

//
// MBOX_GetFreeEnt()
// Returns an MBOX entity to use.
//
entity() MBOX_GetFreeEnt =
{
	entity ent;
	ent = find(world, classname, "freeMboxEntity");

	if (ent == world)
		error("MBOX_GetFreeEnt: No free MBOX Entity. (Hacks?)\n");
	
	return ent;
};

void() updateBoxGlow
{
	if(self.goaldummy)
	{
		self.goaldummy.frame = self.frame;
	}
};


void()	box_open1		=[	1,	box_open2	] { self.frame = 1;updateBoxGlow(); Light_Yellow(self);};
void()	box_open2		=[	2,	box_open3	] { self.frame = 2;updateBoxGlow();};
void()	box_open3		=[	3,	box_open4	] { self.frame = 3;updateBoxGlow();};
void()	box_open4		=[	4,	box_open5	] { self.frame = 4;updateBoxGlow();};
void()	box_open5		=[	5,	box_open6	] { self.frame = 5;updateBoxGlow();};
void()	box_open6		=[	6,	box_open7	] { self.frame = 6;updateBoxGlow();};
void()	box_open7		=[	7,	box_open8	] { self.frame = 7;updateBoxGlow();};
void()	box_open8		=[	8,	SUB_Null	] { self.frame = 8;updateBoxGlow();};

void() resetbox = 
{
	self.frame = 0;
	self.boxstatus = 0;
};


void()	box_close1	=[	9,	box_close2	] { self.frame = 9;updateBoxGlow();sound (self, CHAN_ITEM, "sounds/machines/mbox_close.wav", 1, ATTN_NORM); Light_None(self);};
void()	box_close2	=[	10,	box_close3	] { self.frame = 10;updateBoxGlow();};
void()	box_close3	=[	11,	box_close4	] { self.frame = 11;updateBoxGlow();};
void()	box_close4	=[	12,	resetbox	] { self.frame = 12;updateBoxGlow();};

//
// Getweaponid()
// Returns weapon ID from Mbox ID, as they are slightly different
// because.. reasons..
//
float(float r) Getweaponid =
{	
	switch(r) {
		case 0:
			return W_COLT;
		case 1:
			return W_KAR;
		case 2:
			return W_DB;
		case 3:
			return W_MG;
		case 4:
			return W_RAY;
		case 5:
			return W_THOMPSON;
		case 6:
			return W_M2;
		case 7:
			return W_PPSH;
		case 8:
			return W_SAWNOFF;
		case 9:
			return W_TESLA;
		case 10:
			return W_M1A1;
		case 11:
			return W_GEWEHR;
		case 12:
			return W_FG;
		case 13:
			return W_BROWNING;
		case 14:
			return W_KAR_SCOPE;
		case 15:
			return W_357;
		case 16:
			return W_STG;
		case 17:
			return W_PANZER;
		case 18:
			return W_BK;
		case 19:
			return W_PTRS;
		case 20:
			return W_MP40;
		case 21:
			return W_TRENCH;
		case 22:
			return W_BAR;
		case 23:
			return W_M1;
		case 24:
			return W_TYPE;
		case 25:
			return W_MP5K;
		case 26:
			return W_SPRING;
	}

	return r;
}

//
// randomweapon()
// Returns a Weapon if permitted by the map's MBOX data file.
//
float() randomweapon =
{
	float r;
	r = rint((random() * 26));

	// If this weapon is in our Box Array, we can return it.
	if (BoxWeapons[r] == 1) {
		return r;
	} else { // It's not in the Array, try again until we find one.
		return randomweapon();
	}
};

//
// CheckWeapon(w, user)
// Checks all 3 weapon slots to see if the Player is holding specified
// Weapon, ensures we do not give Duplicates.
//
float CheckWeapon (float w, entity user) =
{
	// Non-PaP Weapons
	if (user.weapon == w || user.secondaryweapon == w || user.thirdweapon == w)
		return 0;
	
	// PaP Weapons
	if (EqualNonPapWeapon(user.weapon) == w || EqualNonPapWeapon(user.secondaryweapon) == w || EqualNonPapWeapon(user.thirdweapon) == w)
		return 0;
	
	// We passed both, this weapon is okay
	return 1;
};

//
// Reset_MBox()
// Resets the Mystery Box to it's inital State.
//
void() Reset_MBox =
{
	entity tempe;
	self.velocity = '0 0 0';
	tempe = self;
	self = self.owner;
	box_close1();
	self = tempe;
	self.owner.owner = world;
	self.owner.boxstatus = 0;
	MBOX_FreeEnt(self);
}

//
// Float_Decreate()
// Make the Gun in the Box slowly descend, eventually
// resetting the Box.
//
void() Float_Decrease =
{
	makevectors(self.angles);
	self.velocity = v_up*-5;
	self.nextthink = time + 7;
	self.think = Reset_MBox;
}

//
// findboxspot()
// Locate a new MBox spot and turn this spot into
// a tp_spot.
//
void() findboxspot =
{	
	local entity newspot;
	local float box = rint(random(mystery_box_count));
	newspot = mystery_boxes[box];

	// Ensure the spot we choose is valid.
	while(newspot == world || newspot == self.owner) {
		box = rint(random(mystery_box_count));
		newspot = mystery_boxes[box];
	}

	// Make our current spot a tp_spot
	self.owner.model = "models/props/teddy.mdl";
	self.owner.frame = 2;
	setmodel(self.owner, self.owner.model);
	self.owner.classname = "mystery_box_tp_spot";
	self.owner.touch = SUB_Null;
	self.owner.angles_y -= 90;
	Light_None(self.owner);
	
	newspot.angles_y += 90;

	// Spawn the Box Glow if permitted
	if (!(self.owner.spawnflags & MBOX_SPAWNFLAG_NOLIGHT))
	{
		entity g;
		g = MBOX_GetFreeEnt();
		g.classname = "mystery_glow";
		newspot.goaldummy = g;
		setmodel(g,"models/machines/mglow$.mdl");
		setorigin(g,newspot.origin);
		g.angles = newspot.angles;

#ifdef FTE

		g.alpha = 0.5;

#endif // FTE

	}
	
	// Remove teddy
	MBOX_FreeEnt(self);
	
	// Set some values and change the found Spot to an MBox
	newspot.spins = 0;
	newspot.boxstatus = 0;
	newspot.touch = mystery_touch;
	newspot.solid=SOLID_TRIGGER;
	newspot.classname = "mystery";
	newspot.spawnflags = self.owner.spawnflags;
	setorigin(newspot, newspot.origin);
	setmodel (newspot, "models/machines/mystery.mdl");
	newspot.frame = 0;
	setsize (newspot, VEC_HULL2_MIN, VEC_HULL2_MAX);
}

//
// MBOX_MakeActive()
// Sets the Mystery Box touch to mystery_touch (delay)
//
void() MBOX_MakeActive =
{
	self.touch = mystery_touch;
}

//
// MBOX_FindNewSpot()
// Locate a new location for the Mystery Box.
//
void() MBOX_FindNewSpot =
{
	entity new_box = world;

	// Find a new Mystery Box location
	while(new_box == world || new_box == self) {
		float box_index = rint(random(mystery_box_count));
		new_box = mystery_boxes[box_index];
	}

	// Stupid Teddy Bear being rotated!!
	new_box.angles_y += 90;

	// Convert the spawn to a Mystery Box
	new_box.spawnflags = self.spawnflags;
	new_box.spins = new_box.boxstatus = 0;
	new_box.think = MBOX_MakeActive;
	new_box.nextthink = time + 2;
	new_box.solid = SOLID_TRIGGER;
	new_box.classname = "mystery";
	new_box.frame = 0;
	setmodel(new_box, "models/machines/mystery.mdl");
	setsize(new_box, VEC_HULL2_MIN, VEC_HULL2_MAX);

	// Spawn the Box Glow if permitted
	if (!(new_box.spawnflags & MBOX_SPAWNFLAG_NOLIGHT))
	{
		entity light;
		light = MBOX_GetFreeEnt();
		light.classname = "mystery_glow";
		new_box.goaldummy = light;
		setmodel(light,"models/machines/mglow$.mdl");
		setorigin(light, new_box.origin);
		light.angles = new_box.angles;
		light.effects = EF_FULLBRIGHT;

#ifdef FTE

		light.alpha = 0.5;

#endif // FTE

	}

	// Spawn some sparkles so it doesn't just "appear"
	SpawnSpark(new_box.origin, 0.75);
	// "Woosh" Effect
	sound(new_box, CHAN_AUTO, "sounds/pu/drop.wav", 1, ATTN_NORM);
}

//
// MBOX_StopFlying()
// We've done our dance, go away and
// delay respawning.
//
void() MBOX_StopFlying = 
{
	// Spark Effect
	SpawnSpark(self.origin, 0.75);
	// "Woosh" Effect
	sound(self, CHAN_AUTO, "sounds/pu/drop.wav", 1, ATTN_NORM);
	// Disappear!
	self.model = "models/props/teddy.mdl";
	setmodel(self, self.model);
	self.frame = 2;
	// Clean up
	self.origin = self.oldvelocity;
	self.angles = self.movement;
	self.velocity = 0;
	self.angles_y -= 90;
	self.classname = "mystery_box_tp_spot";
	self.touch = SUB_Null;
	// 12 Second delay to finding a new spot
	self.think = MBOX_FindNewSpot;
	self.nextthink = time + 12;
}

//
// MBOX_AnimateFly()
// Rotate the Mystery Box as it flies away.
//
void() MBOX_AnimateFly =
{
	if (self.score == 0)
		self.angles_x += 6;
	else
		self.angles_x -= 6;

	if (self.angles_x - self.movement_x >= 20)
		self.score = 1;
	else if (self.angles_x - self.movement_x <= -20)
		self.score = 0;

	if(self.ltime < time) {
		MBOX_StopFlying();
	} else {
		self.nextthink = time + 0.05;
	}
}

//
// MBOX_FlyAway()
// The actual leave animation.
//
void() MBOX_FlyAway =
{
	// Begin rising
	makevectors(self.angles);
	self.movetype = MOVETYPE_NOCLIP;
	self.velocity = v_up * 7;
	// Animation lasts 4 seconds
	self.ltime = time + 4;
	// Animation Update
	self.think = MBOX_AnimateFly;
	self.nextthink = time + 0.05;
}

//
// MBOX_Leave()
// Starts Mystery Box Leave animation.
//
void() MBOX_Leave =
{
	// Broadcast the laughter
	sound(self, CHAN_ITEM, "sounds/pu/byebye.wav", 1, ATTN_NONE);
	// "Woosh" Effect
	sound(self, CHAN_AUTO, "sounds/pu/drop.wav", 1, ATTN_NORM);
	// Spark Effect
	SpawnSpark(self.origin, 0.75);
	// Turn off Light & Glow
	Light_None(self);
	if (!(self.spawnflags & MBOX_SPAWNFLAG_NOLIGHT)) 
		if (self.goaldummy != world)
			MBOX_FreeEnt(self.goaldummy);
	// Save old position and angle
	self.oldvelocity = self.origin;
	self.movement = self.angles;
	// Start flying
	self.think = MBOX_FlyAway;
	self.nextthink = time + 0.05;
}

//
// MBOX_TeddyDespawn()
// Frees the Teddy Bear entity.
//
void() MBOX_TeddyDespawn =
{
	self.velocity = 0;
	MBOX_FreeEnt(self);
}

//
// MBOX_TeddyLeave()
// Make the Teddy Bear float away and start the
// timer for the Mystery Box to follow.
//
void() MBOX_TeddyLeave =
{
	// Fly slowly
	self.velocity = v_up*75;
	self.think = MBOX_TeddyDespawn;
	self.nextthink = time + 5;
	// Linger for 3 seconds, and then the Box follows.
	self.owner.think = MBOX_Leave;
	self.owner.nextthink = time + 3;
}

//
// MBOX_PresentTeddy()
// Lets the Teddy Bear idle for a few seconds,
// return player points, kick-off leave.
//
void() MBOX_PresentTeddy =
{
	// Return the Player's points.
	addmoney(self.owner.owner, 950, 0);
	// Broadcast the bad luck.
	sound(self, CHAN_ITEM, "sounds/misc/buy.wav", 1, ATTN_NONE);
	sound(self, 2, "sounds/misc/giggle.wav", 1, ATTN_NONE);
	// Linger for 2 seconds, and then fly away.
	self.think = MBOX_TeddyLeave;
	self.nextthink = time + 2;
}

void() Float_Change =
{
	entity tpspot;
	float r, tempf, teddygen;
	string temps;

	tempf = randomweapon();
	r = Getweaponid(tempf);
	while (!CheckWeapon (r, self.owner.owner))
	{
		tempf = randomweapon();
		r = Getweaponid(tempf);
	}
	temps = GetWeaponModel(r, 1);
	setmodel (self, temps);

	self.boxstatus = self.boxstatus + 0.01;
	if (self.wait <= time)
	{
		tpspot = find(world, classname, "mystery_box_tp_spot");
		if (tpspot != world && self.owner.spins > 3) {
				teddygen = random();
				//bprint(PRINT_HIGH, "found tp spot\n");
		} else {
			teddygen = 0;
			//bprint(PRINT_HIGH, "no tp spot or spins < 3\n");
		}
				
		self.velocity = '0 0 0';
		
		if (!teddygen || teddygen < 0.7) {		//teddy gen threshold, high means less chance
			self.owner.boxstatus = 2;
			self.weapon = r;
			self.nextthink = time + 5;
			self.think = Float_Decrease;
			//bprint(PRINT_HIGH, "spot not found, or teddygun is > 0.7\n");
			return;
		}
		else {
			addmoney(self.owner.owner, 950, 0);
			self.model = "models/props/teddy.mdl";
			setmodel(self, self.model);
			self.angles_y = self.angles_y - 90;
			self.nextthink = time + 1;
			self.think = MBOX_PresentTeddy;
			ach_tracker_luck++;

			if (ach_tracker_luck >= 10)
				GiveAchievement(11);
			return;
		}
	}
	if (self.ltime <= time)
	{
		self.velocity_z = self.velocity_z*0.5;
		self.ltime = 0.5;
	}
	self.nextthink = time + self.boxstatus;
	self.think = Float_Change;
}

void() finish_mbox_setup =
{
	// Temporary hack for random box spawns until rewrite - Mikey (27/03/2023, DD/MM/YYYY)
    if(self.spawnflags & MBOX_SPAWNFLAG_NOTHERE) {
        entity temp = MBOX_GetFreeEnt();
		temp.classname = "mystery_helper";

        temp.owner = self;
        temp.think = findboxspot;
        temp.nextthink = time + 0.1;
    } else if(!(self.spawnflags & MBOX_SPAWNFLAG_NOLIGHT)) {
        entity g = MBOX_GetFreeEnt();
		g.classname = "mystery_glow";

		self.goaldummy = g;
		setmodel(g,"models/machines/mglow$.mdl");
		setorigin(g,self.origin);
		g.angles = self.angles;

#ifdef FTE

		g.alpha = 0.5;

#endif // FTE

    }
}

void() allocate_floating_weapons =
{
	self.think = SUB_Null;

	// Spawn all of our floating weapon entities
	// Multiply by 2 to account for the glow.
	for (float i = 0; i < mystery_box_count * 3; i++) {
		entity tempe = spawn();
		tempe.classname = "freeMboxEntity";
	}

	finish_mbox_setup();
}

void() Create_Floating_Weapon =
{
	entity gun;
	float r, tempf;
	string temps;

	tempf = randomweapon();
	r = Getweaponid(tempf);
	while (!CheckWeapon (r, self.owner.owner))
	{
		tempf = randomweapon();
		r = Getweaponid(tempf);
	}
	temps = GetWeaponModel(r, 1);
		
	gun = MBOX_GetFreeEnt();
	gun.classname = "mystery_weapon";
	
	setorigin (gun, self.origin);
	setmodel (gun, temps);
	setsize (gun, '0 0 0', '0 0 0');
	gun.angles = self.angles;
	gun.effects = EF_FULLBRIGHT;
	
	gun.movetype = MOVETYPE_NOCLIP;
	gun.solid = SOLID_NOT;
	makevectors(self.angles);
	gun.velocity = v_up*15;
	
	gun.owner = self;
	self.boxweapon = gun;
	
	gun.ltime = time+2;
	gun.boxstatus = 0.01;
	gun.wait = time + 5;
	gun.nextthink = time + 0.01;
	gun.think = Float_Change;
}

void() mystery_box_tp_spot = 
{
	precache_model ("models/props/teddy.mdl"); 
	precache_sound ("sounds/pu/byebye.wav");
	precache_sound ("sounds/misc/giggle.wav");
	
	self.solid=SOLID_TRIGGER;
	self.classname = "mystery_box_tp_spot";
	setorigin(self, self.origin);
	setmodel (self, "models/props/teddy.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);
	
	if (self.model == "models/props/teddy.mdl") {
		self.frame = 2;
		self.angles_y -= 90;
	}
	
	mystery_boxes[mystery_box_count] = self;
	mystery_box_count++;
};

void() mystery_touch =
{
	entity tempe;
	
	if (other.classname != "player" || other.downed)
		return;
		
	if (!self.boxstatus) {
		useprint (other, 6, 950, 0);
	}
	if (self.boxstatus == 2 && self.owner == other) {
		useprint (other, 7, 0, 0);
	}
	
	if (other.button7 && !other.semiuse)
	{
		other.semiuse = true;
		if (!self.boxstatus)
		{
			if (other.points >= 950)
			{					
				sound (self, CHAN_ITEM, "sounds/machines/mbox_open.wav", 1, ATTN_NORM);
				addmoney(other, -950, FALSE);
				self.boxstatus = 1;
				self.owner = other;
				box_open1 ();
				Create_Floating_Weapon();
				self.spins++;
			}
			else {
        		centerprint (other, STR_NOTENOUGHPOINTS);
				sound(other, 0, "sounds/misc/denybuy.wav", 1, 1);
			}
		}
		if (self.boxstatus == 2)
		{
			if (self.owner == other)
			{
				other.reload_delay = 0;
				self.boxstatus = 0;
				self.owner = world;
				if (other.weapon != self.boxweapon.weapon && other.secondaryweapon != self.boxweapon.weapon && other.secondaryweapon && other.thirdweapon != self.boxweapon.weapon)
				{	
					if ((other.perks & P_MULE) && !other.thirdweapon) {
						// store secondary weapon
						local float tempf = other.secondaryweapon;
						local float tempf1 = other.secondarymag;
						local float tempf2 = other.secondaryammo;
						local float tempf3 = other.secondarymag2;
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

					// give boxweapon
					other.weapon = self.boxweapon.weapon;
          			other.currentammo = getWeaponAmmo(self.boxweapon.weapon);
					other.currentmag = getWeaponMag(self.boxweapon.weapon);
					other.weaponskin = 0;

					if (other.weapon != W_KAR_SCOPE && other.weapon != W_HEADCRACKER && !IsDualWeapon(other.weapon)) {
						other.weapon2model = "";
					}
					
#ifndef FTE

					other.Flash_Offset = GetWeaponFlash_Offset(self.boxweapon.weapon);
					other.Flash_Size = GetWeaponFlash_Size(self.boxweapon.weapon);
					other.Weapon_Name = GetWeaponName(self.boxweapon.weapon);

#endif // FTE

				}
				else if (other.weapon == self.boxweapon.weapon)
				{
					other.currentammo = getWeaponAmmo(self.boxweapon.weapon);
					other.currentmag = getWeaponMag(self.boxweapon.weapon);
				}
				else if (other.secondaryweapon == self.boxweapon.weapon)
				{
					other.secondaryammo = getWeaponAmmo(self.boxweapon.weapon);
					other.secondarymag = getWeaponMag(self.boxweapon.weapon);
				}
				else if (other.thirdweapon == self.boxweapon.weapon)
				{
					other.thirdammo = getWeaponAmmo(self.boxweapon.weapon);
					other.thirdmag = getWeaponMag(self.boxweapon.weapon);
				}
				else if (!other.secondaryweapon)
				{
					WeaponSwitch(other);
					other.weapon = self.boxweapon.weapon;
					other.currentammo = getWeaponAmmo(self.boxweapon.weapon);
					other.currentmag = getWeaponMag(self.boxweapon.weapon);
					other.weaponskin = GetWepSkin(self.boxweapon.weapon);

#ifndef FTE

					other.Flash_Offset = GetWeaponFlash_Offset(self.boxweapon.weapon);
					other.Flash_Size = GetWeaponFlash_Size(self.boxweapon.weapon);
					other.Weapon_Name = GetWeaponName(self.boxweapon.weapon);

#endif // FTE

				}
				else if (!other.thirdweapon && (other.perks & P_MULE))
				{
					
				}
				sound(self, 0,"sounds/misc/ching.wav", 1, 1);
				tempe = self;
				self = other;

				if (GetFrame(self.weapon, FIRST_TAKE_START) != 0)
					Weapon_PlayViewModelAnimation(ANIM_FIRST_TAKE, SUB_Null, 0);
				else
					Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, SUB_Null, 0);

				SwitchWeapon(self.weapon);
				self = tempe;
				MBOX_FreeEnt(self.boxweapon);
				box_close1();
			}
		}
	}
}


//
// Load_Mbox_Data()
// Opens the map's MBOX Data File and adds parsed data
// into the Box's weapon Array.
// ----------
// TODO: Possibly investigate making this a little better and more modular
// so adding MBOX Weapons can be easier?
//
void() Load_Mbox_Data =
{
	float file;
	string h;
	int weapons_all_disabled = 1;

	// Attempt to Open the File
	h = strcat(mapname, ".mbox");
	h = strcat("maps/",  h);
	file = fopen (h, FILE_READ);

	// There was no MBOX Data, enable all Weapons!
	// R.I.P. PSP Memory 90% of the time in this case..
	if (file == -1) {
		for (float i = 0; i < 27; i++) {
			BoxWeapons[i] = 1;
		}
    fclose(file);
	} else {
		// Parse each Line and write the Data into our Array.
		for (float i = 0; i < 27; i++) {
			h = strtrim((fgets(file)));
			BoxWeapons[i] = stof(h);
			
			if (stof(h) == 1)
				weapons_all_disabled = 0;	
		}
	}
	
	if (weapons_all_disabled) {
		for (float i = 0; i < 27; i++) {
			BoxWeapons[i] = 1;
		}
	}

	for(float i = 0; i < 27; i++) {
		// Precache Weapon Data if enabled
		if (BoxWeapons[i]) {
			precache_model(GetWeaponModel(Getweaponid(i), 0));
			precache_model(GetWeaponModel(Getweaponid(i), 1));
			precache_extra(Getweaponid(i));
		}
	}

	fclose(file);
}

void() mystery_box =
{
	Load_Mbox_Data();

	precache_model ("models/machines/mystery.mdl");
	precache_sound ("sounds/machines/mbox_open.wav"); 
	precache_sound ("sounds/machines/mbox_close.wav"); 

	if (!(self.spawnflags & MBOX_SPAWNFLAG_NOLIGHT))
		precache_model ("models/machines/mglow$.mdl");
	
	self.solid = SOLID_TRIGGER;
	self.classname = "mystery";
	setorigin(self, self.origin);
	setmodel (self, "models/machines/mystery.mdl");
	setsize (self, VEC_HULL2_MIN, VEC_HULL2_MAX);

	self.touch = mystery_touch;
	boxOrigin = self.origin;

	mystery_boxes[mystery_box_count] = self;
	mystery_box_count++;

	self.think = allocate_floating_weapons;
	self.nextthink = time + 0.2;
}