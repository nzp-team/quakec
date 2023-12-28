/*
	server/weapons/weapon_core.qc

	weapon logic

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

void() W_PutOut;
float(entity who, float weapon) Zombie_HeadCanGib;
void(float side) W_Reload;
void() GrenadeExplode;
void() W_SprintStart;
#ifdef FTE
void() AI_SetAllEnemiesBBOX;
void() AI_RevertEnemySolidState
float() push_away_zombies;
#endif // FTE

//
// W_HideCrosshair(person)
// Toggles off the crosshair for provided client.
// This is considered "nasty" by use of stuffcmd,
// however non-FTE has no way of better controlling
// cvars for individual clients.
//
void(entity person) W_HideCrosshair =
{
	if (person == world)
		return;

	stuffcmd(person, "crosshair 0\n");
}

//
// W_ShowCrosshair(person)
// Toggles on the crosshair for provided client.
// This is considered "nasty" by use of stuffcmd,
// however non-FTE has no way of better controlling
// cvars for individual clients.
//
void(entity person) W_ShowCrosshair =
{
	if (person == world)
		return;

	// Grab the type of crosshair
	float crosshair_type;
	
	// Grenades have a special crosshair type that can pulse.
	if (person.grenade_delay) {
		crosshair_type = 4;
	} else
	 	crosshair_type = WepDef_GetWeaponCrosshairType(person.weapon);

	string crosshair_string = "crosshair ";
	crosshair_string = strzone(strcat(crosshair_string, ftos(crosshair_type)));
	stuffcmd(person, strcat(crosshair_string, "\n"));
	strunzone(crosshair_string);
}

void() ReturnWeaponModel =
{
	self.weaponmodel = GetWeaponModel(self.weapon, 0);

	if (IsDualWeapon(self.weapon)) {
		self.weapon2model = GetLeftWeaponModel(self.weapon);
	} else if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER) {
		self.weapon2model = "models/weapons/kar/v_karscope.mdl";
		UpdateV2model(self.weapon2model, 0);
	}

	UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
	UpdateV2model(self.weapon2model, GetWepSkin(self.weapon));

	// Always try to reload after any action.
	if (self.weapons[0].weapon_magazine == 0 && self.weapons[0].weapon_reserve != 0)
		W_Reload(S_RIGHT);
	if (IsDualWeapon(self.weapon) && self.weapons[0].weapon_magazine_left == 0 && self.weapons[0].weapon_reserve != 0)
		W_Reload(S_LEFT);

    // If the person is swapping, play the sprint anim if they're sprinting after swap. Otherwise it plays idle
    if (self.sprinting == TRUE)
        W_SprintStart();

	W_ShowCrosshair(self);
}

void() W_PlayTakeOut =
{
	W_HideCrosshair(self);
	Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, ReturnWeaponModel, 0);
}

.float scopetime;

void() W_AimIn =
{
	if (WepDef_DoesNotADS(self.weapon))
		return;

	if (IsDualWeapon(self.weapon) ||
		self.reload_delay > time ||
		self.knife_delay > time ||
		self.sprinting ||
		self.new_anim_stop ||
		self.semiknife == true) {		
		return;
	}

	float ads_frame = GetFrame(self.weapon, AIM_IN);
	if (ads_frame != 0 && self.fire_delay < time) {
		self.weaponframe_end = self.weaponframe = ads_frame;
	} else if (self.zoom) {
		return;
	}
	
	if (self.weapon == W_KAR_SCOPE || self.weapon == W_PTRS ||
	    self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
		SetUpdate(self, UT_ZOOM2, 0, 0, 0);
		self.zoom = 2;
		self.scopetime = time + 0.3;
	} else {
		self.zoom = 1;
	}
}

void() W_AimOut =
{
	if (!self.zoom ||
		self.new_anim_stop || 
		self.sprinting) {
		return;
	}

	if (self.weapon == W_KAR_SCOPE || self.weapon == W_PTRS ||
	    self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
		ReturnWeaponModel();
	}
		
#ifndef FTE

	self.zoom = 0;

#endif // FTE
}

void() W_SprintStop =
{
	if (self.sprinting)
	{
		self.sprint_stop_time = time;
		self.sprint_duration = self.sprint_timer;
	}

	if (self.isBuying || !self.sprinting)
		return;

	Weapon_PlayViewModelAnimation(ANIM_SPRINT_STOP, ReturnWeaponModel, 0);

	self.zoom = 0;
	self.tp_anim_time = 0;
	PAnim_Walk6(); // Run Walk for a few frames to simulate an ease in velocity
	self.sprinting = 0;
	self.into_sprint = 0;
	self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;
}


void W_SprintStart () {	
	if (self.speed_penalty_time > time || self.zoom != 0)
		return;
	
	self.sprint_start_time = time;
	
	if (self.sprint_rest_time > sprint_max_time)
		self.sprint_duration = 0.0;
	else
		self.sprint_duration -= self.sprint_rest_time;

	if (!self.sprintflag) {
		return;
	}
	
	if (self.fire_delay > time ||
		self.fire_delay2 > time ||
		self.new_anim_stop ||
		self.new_anim2_stop ||
		self.isBuying || 
		self.downed ||
		!(self.flags & FL_ONGROUND) || 
		self.sprint_delay > time) {
		return;
	}

	Weapon_PlayViewModelAnimation(ANIM_SPRINT_START, ContinueRun, 0);

	self.zoom = 3;
	self.sprint_delay = time + 1;
	self.sprinting = true;
	self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;
}

void() W_PutOutHack =
{
	Weapon_SwapWeapons(true);
}

void() W_PutOut =
{
	// We don't hold more than one weapon
	if (self.weapons[1].weapon_id == 0 || self.downed)
		return;

	float duration = getWeaponDelay(self.weapon, PUTOUT);
	
	W_AimOut();
	W_HideCrosshair(self);

	if (self.stance == 2)
		PAnim_Swap();
	
	if (self.weapon_count != 1 && !self.new_anim_stop)
		Weapon_PlayViewModelAnimation(ANIM_PUT_AWAY, W_PutOutHack, duration);
}

void() W_TakeOut =
{
	self.isBuying = false;

	float duration = getWeaponDelay(self.weapon, TAKEOUT);

	W_AimOut();
	W_HideCrosshair(self);
	Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, ReturnWeaponModel, duration);
}



//RELOAD

void(float side) W_Give_Ammo =
{
	float ammo_shot, max_mag, loadammo;
	
	max_mag = getWeaponMag(self.weapon);

	if (side == S_LEFT) {
		ammo_shot = max_mag - self.weapons[0].weapon_magazine_left;
	} else {
		ammo_shot = max_mag - self.weapons[0].weapon_magazine;
	}
	if (ammo_shot < self.weapons[0].weapon_reserve)
	{
    	self.weapons[0].weapon_reserve = self.weapons[0].weapon_reserve - ammo_shot;
      
		loadammo = max_mag;
	}
	else
	{
		loadammo = self.weapons[0].weapon_magazine + self.weapons[0].weapon_reserve;
		self.weapons[0].weapon_reserve = 0;
	}

	if (side == S_LEFT) {
		self.weapons[0].weapon_magazine_left = loadammo;
	} else {
		self.weapons[0].weapon_magazine = loadammo;
	}
};

void () W_LoadAmmo;
void() ContinueReload = //Special reloads
{
	if (self.new_anim_stop)
		return;
	
	if (self.weapon == W_GUT && self.weapons[0].weapon_magazine == 10)
    return;

	W_HideCrosshair(self);

	float delay = 0;
	string modelname = GetWeaponModel(self.weapon, 0);
	float startframe = 0;
	float endframe = 0;
	void(optional float t) endanimfunc = SUB_Null;
	
	if (self.weapons[0].weapon_magazine >= getWeaponMag(self.weapon) || !self.weapons[0].weapon_reserve || self.reloadinterupted) {
		if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER)
		{
			delay = 1; 
			startframe = 24;
			endframe = 28;
		} else if (self.weapon == W_TRENCH || self.weapon == W_GUT) {
			delay = 0.5; 
			startframe = 24;
			endframe = 26;
			endanimfunc = W_LoadAmmo;
		}
		self.reloadinterupted = FALSE;
	} else if (self.weapons[0].weapon_magazine < getWeaponMag(self.weapon)) {
		if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER) {
			self.weapons[0].weapon_magazine++;
        	self.weapons[0].weapon_reserve = self.weapons[0].weapon_reserve - 1;
			delay = 0.8; 
			startframe = 19;
			endframe = 24;
			endanimfunc = ContinueReload;
		} else if (self.weapon == W_TRENCH || self.weapon == W_GUT) {
			if (self.weapon == W_GUT && self.weapons[0].weapon_reserve >= 2 && self.weapons[0].weapon_magazine < 9) {
				self.weapons[0].weapon_magazine = self.weapons[0].weapon_magazine + 2;
				self.weapons[0].weapon_reserve = self.weapons[0].weapon_reserve - 2;
			} else {
				self.weapons[0].weapon_magazine++;
				self.weapons[0].weapon_reserve = self.weapons[0].weapon_reserve - 1;
			}
			delay = 0.5; 
			startframe = 18;
			endframe = 23;
			endanimfunc = ContinueReload;
		}
	}

	if (delay) {
		if (self.perks & P_SPEED) {
			delay *= 0.5;
		}
		self.reload_delay = time + delay;
		Set_W_Frame (startframe, endframe, delay, 0, RELOAD, endanimfunc, modelname, false, S_RIGHT);
	}
}

void(float side) W_AdvanceAnim =
{
	float startframe, endframe, delay, reloadcancelframe;
	string modelname;

	startframe = GetFrame(self.weapon, RELOAD_START);
	endframe = GetFrame(self.weapon, RELOAD_END);
	delay = getWeaponDelay(self.weapon, RELOAD);
	reloadcancelframe = GetFrame(self.weapon, RELOAD_CANCEL);
	
	if (self.perks & P_SPEED) delay *= 0.5;

	modelname = GetWeaponModel(self.weapon, 0);

	self.reload_delay = self.reload_delay2 = delay + time;

	Set_W_Frame (startframe, endframe, delay, reloadcancelframe, RELOAD, W_Give_Ammo, modelname, false, side);
}

void(float side) W_Reload =
{
	if (self.zoom == 2)
		return;

	if (GetFiretype(self.weapon) == FIRETYPE_FLAME)
		return;
	
	if (side == S_BOTH) {
		W_Reload(S_RIGHT);
		if (IsDualWeapon(self.weapon)) {
			W_Reload(S_LEFT);
		}
		return;
	}
	if (side == S_RIGHT &&
		(self.reload_delay > time ||
		self.new_anim_stop ||
		!self.weapons[0].weapon_reserve || 
		self.weapons[0].weapon_magazine >= getWeaponMag(self.weapon))){
		return;
	}
	if (side == S_LEFT &&
		(self.reload_delay2 > time ||
		self.new_anim2_stop || 
		!self.weapons[0].weapon_reserve ||
		self.weapons[0].weapon_magazine_left >= getWeaponMag(self.weapon))) {
		return;
	}

	self.zoom = false;

	W_AimOut();
	W_SprintStop();

	// If it's a dual wielded weapon, we don't want to hide the crosshair
	// unless both weapons are being reloaded.
	if (!IsDualWeapon(self.weapon) || (self.reload_delay > time || self.reload_delay2 > time))
		W_HideCrosshair(self);

	float endframe, startframe, reloadcancelframe, delay;
	string modelname = "";
	
	if (side == S_RIGHT) {
		modelname = GetWeaponModel(self.weapon, 0);
	} else {
		if (IsDualWeapon(self.weapon)) {
			modelname = GetLeftWeaponModel(self.weapon); 
		}
	}
	
	if (self.weapons[0].weapon_reserve)
	{
		switch(self.stance) {
			case 2: PAnim_Reload(); break;
			case 1: PAnim_CrReload(); break;
			case 0: if (!self.downed) PAnim_PrReload(); break;
		}
		
		startframe = GetFrame(self.weapon,RELOAD_START);
		endframe = GetFrame(self.weapon,RELOAD_END);
		reloadcancelframe = GetFrame(self.weapon,RELOAD_CANCEL);
		delay = getWeaponDelay(self.weapon,RELOAD);
		void(optional float t) endanimfunc = SUB_Null;

		if (self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER ){
			startframe = 14;
			endframe = 18;
			reloadcancelframe = 0;
			delay = 0.8;
			endanimfunc = ContinueReload;
		}
		// Check for special reload type
		else if (GetFrame(self.weapon, RELOAD_EMPTY_START) != 0) {
			if (self.weapons[0].weapon_magazine > 0) {
				startframe = GetFrame(self.weapon, RELOAD_PART_START);
				endframe = GetFrame(self.weapon, RELOAD_PART_END);
				delay = getWeaponDelay(self.weapon, RELOAD_PAR);
			} else {
				startframe = GetFrame(self.weapon, RELOAD_EMPTY_START);
				endframe = GetFrame(self.weapon, RELOAD_EMPTY_END);
				delay = getWeaponDelay(self.weapon, RELOAD_EMP);
			}
			endanimfunc = W_AdvanceAnim;
		}
		else if (self.weapon == W_TRENCH || self.weapon == W_GUT) {
			if (self.weapons[0].weapon_magazine == 0) {
				self.NeedLoad = true;
			}
			startframe = 14;
			endframe = 17;
			reloadcancelframe = 0;
			delay = 0.8;
			endanimfunc = ContinueReload;
		} else {
			endanimfunc = W_Give_Ammo;
		}

		if (self.perks & P_SPEED)
			delay = delay*0.5;
		
		if (side == S_RIGHT) {
			self.reload_delay = delay + time;
		} else {
			self.reload_delay2 = delay + time;
		}
		
		Set_W_Frame (startframe, endframe, delay, reloadcancelframe, RELOAD, endanimfunc, modelname, false, side);
	}
	
	if (self.weapon != W_TRENCH) {
		self.NeedLoad = false;
	}
};

void () W_LoadAmmoDone =
{
	self.NeedLoad = false;
}
void () W_LoadAmmo =
{
	if (!self.NeedLoad)
		return;
	if (!self.weapons[0].weapon_magazine)
	{
		W_Reload(S_BOTH);
		return;
	}

	string modelname;
	float endframe, startframe, reloadcancelframe, delay;

	modelname = GetWeaponModel(self.weapon, 0);
	startframe = GetFrame(self.weapon,RELOAD_START);
	endframe = GetFrame(self.weapon,RELOAD_END);
	reloadcancelframe = GetFrame(self.weapon,RELOAD_CANCEL);
	delay = getWeaponDelay(self.weapon,RELOAD);
	void(optional float t) endanimfunc = SUB_Null;

	if (self.weapon == W_TRENCH || self.weapon == W_GUT)
	{
		startframe = 4;
		endframe = 14;
		reloadcancelframe = 12;
		delay = 1;
		endanimfunc = W_LoadAmmoDone;
	}
	else if (self.weapon == W_KAR || self.weapon == W_ARMAGEDDON || self.weapon == W_KAR_SCOPE || self.weapon == W_HEADCRACKER || self.weapon == W_SPRING || self.weapon == W_PULVERIZER)
	{
		startframe = 4;
		endframe = 13;
		reloadcancelframe = 9;
		delay = 1.2;
		endanimfunc = W_LoadAmmoDone;
	}	

	if (delay) {

		if (self.perks & P_DOUBLE)
			delay *= 0.66;
			
		Set_W_Frame (startframe, endframe, delay, reloadcancelframe, FIRE, W_LoadAmmoDone, modelname, false, S_RIGHT);
		self.fire_delay = delay + time;
	}
}

void () CheckReload = 
{
	if (!self.weapons[0].weapon_magazine_left && IsDualWeapon(self.weapon)) {
		W_Reload(S_LEFT);
	}
	if (!self.weapons[0].weapon_magazine && self.weapons[0].weapon_reserve) {
		W_Reload(S_RIGHT);
	}
}

/*
================
SpawnBlood
================
*/
void(vector org, vector vel, float damage) SpawnBlood =
{
	local entity f;
  
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_BLOOD);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	msg_entity = self;
	multicast('0 0 0', MULTICAST_ONE);

#else

	particle (org, vel*0.1, 73, damage*2);

#endif // FTE

	f = find (world, classname, "player");
	f.hitcount = f.hitcount + 1;
};

void(vector where) spawn_gibs = {

#ifndef FTE

	particle(where, where*0.1, 225, 1);

#else

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_LIMBGIB);
	WriteCoord(MSG_MULTICAST, where_x);
	WriteCoord(MSG_MULTICAST, where_y);
	WriteCoord(MSG_MULTICAST, where_z);
	multicast('0 0 0', MULTICAST_ALL);

#endif // FTE

}

void Parse_Damage () = // DO NOT TOUCH
{
	entity ent;
	float total_dmg;

	entity body_ent;
	float head_hit;

	//warn
	head_hit = 0;

	ent = findfloat (world, washit, 1);

	while (ent) {
		if (ent.classname != "radio" && ent.classname != "explosive_barrel") {

			if (ent.classname == "wunder" || ent.classname == "wunder_limb")
				return;

			if (ent.classname == "ai_zombie_head")
				head_hit = 1;
			
			if (ent.classname != "ai_zombie" && ent.classname != "ai_dog") //limb
				body_ent = ent.owner;
			else
				body_ent = ent;

			total_dmg = body_ent.hitamount;

			if (body_ent.head.washit) {					
				total_dmg += body_ent.head.hitamount;
				body_ent.head.health -= body_ent.head.hitamount;
				head_hit = 1;

				// Check if we should Gib the head, before this would
				// be a really weird check to "ressurect" a zombie if
				// it was out of health. I *think* this is more accurate
				// now. -- cypress (5 nov 2023)
				if (Zombie_HeadCanGib(body_ent, self.weapon)) {
					makevectors(body_ent.head.owner.angles);
 					vector where = body_ent.head.owner.origin + (body_ent.head.view_ofs_x * v_right) + (body_ent.head.view_ofs_y * v_forward) + (body_ent.head.view_ofs_z * v_up);
 					spawn_gibs(where);

					body_ent.head.deadflag = false;
					body_ent.head.solid = SOLID_NOT;
					setmodel(body_ent.head, "");
					body_ent.head.frame = 0;
					
					body_ent.usedent = self;
					body_ent.bleedingtime = time + 1;

#ifndef FTE

					updateLimb (body_ent.head.owner, 0, world);

#endif // FTE

				}
				
				body_ent.head.washit = 0;
				body_ent.head.hitamount = 0;
			}
			if (body_ent.larm.washit) {
				total_dmg += body_ent.larm.hitamount;
				body_ent.larm.health -= body_ent.larm.hitamount;

				if (WepDef_WeaponCanGibEnemy(self.weapon) && body_ent.larm.owner.rarm.deadflag && body_ent.larm.deadflag)
				{
					makevectors(body_ent.larm.owner.angles);
					where = body_ent.larm.owner.origin + (body_ent.larm.view_ofs_x * v_right) + (body_ent.larm.view_ofs_y * v_forward) + (body_ent.larm.view_ofs_z * v_up);
					spawn_gibs(where);
					
					body_ent.larm.deadflag = false;
					body_ent.larm.solid = SOLID_NOT;
					setmodel(body_ent.larm,"");
					body_ent.larm.frame = 0;

#ifndef FTE

					updateLimb (body_ent.larm.owner, 1, world);

#endif // FTE

				}

				body_ent.larm.washit = 0;
				body_ent.larm.hitamount = 0;
			}
			if (body_ent.rarm.washit) {
				total_dmg += body_ent.rarm.hitamount;
				body_ent.rarm.health -= body_ent.rarm.hitamount;

				if (WepDef_WeaponCanGibEnemy(self.weapon) && body_ent.rarm.owner.larm.deadflag && body_ent.rarm.deadflag) {
					
					makevectors(body_ent.rarm.owner.angles);
					where = body_ent.rarm.owner.origin + (body_ent.rarm.view_ofs_x * v_right) + (body_ent.rarm.view_ofs_y * v_forward) + (body_ent.rarm.view_ofs_z * v_up);
					spawn_gibs(where);
					
					body_ent.rarm.deadflag = false;
					body_ent.rarm.solid = SOLID_NOT;
					setmodel(body_ent.rarm,"");
					body_ent.rarm.frame = 0;

#ifndef FTE

					updateLimb (body_ent.rarm.owner, 2, world);

#endif // FTE

				}

				body_ent.rarm.washit = 0;
				body_ent.rarm.hitamount = 0;
			}

			if (instakill_finished) {
				if(body_ent.head.deadflag) {
					body_ent.head.deadflag = false;
					body_ent.head.solid = SOLID_NOT;
					setmodel(body_ent.head,"");
					body_ent.head.frame = 0;
				}
			}
			
			if (head_hit)
				DamageHandler(body_ent,self, total_dmg, S_HEADSHOT);
			else
				DamageHandler(body_ent,self, total_dmg, S_NORMAL);
			
			if (body_ent != world) {
				body_ent.washit = 0;
				body_ent.hitamount = 0;
			}
		}
		ent = findfloat (ent, washit, 1);
	}
}

void() LungeKnifeHit =
{		
	vector	source,org;
	float	f_damage;
	entity	hit_ent;

	makevectors (self.v_angle);
	source = self.origin + self.view_ofs;

	if (self.weapon == W_BK || self.weapon == W_KRAUS)
		traceline (source, source + v_forward*80*1.2, 0, self); // naievil -- added some extra length
	else
		traceline (source, source + v_forward*74*1.2, 0, self); // naievil -- ^^
	
	org = trace_endpos - v_forward*3; // naievil -- changed to factor of 3 from 4
	

	if (trace_ent.takedamage)
	{
		if(trace_ent.classname == "item_radio" || trace_ent.classname == "teddy_spawn")
		{
			entity oldself;
			oldself  = self;
			self = trace_ent;
			self.th_die();
			self = oldself;
			return;
		}
		sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife_hitbod.wav", 1, ATTN_NORM);
		
		// Calculate melee damage
		f_damage = WepDef_CalculateMeleeDamage(self.weapon, self.bowie);
					
		if (trace_ent.classname == "ai_zombie_head")
		{
			hit_ent = trace_ent.owner;
		}
		else if (trace_ent.classname == "ai_zombie_larm")
		{
			hit_ent = trace_ent.owner;
		}
		else if (trace_ent.classname == "ai_zombie_rarm")
		{
			hit_ent = trace_ent.owner;
		}
		else
		{
			hit_ent = trace_ent;
		}
		
		if (hit_ent.takedamage)
		{
			org = source + (v_forward * 20);
			SpawnBlood (org, org, 50);
			//hit = 1;
		}
		
		DamageHandler (hit_ent, self, f_damage, S_KNIFE);
	}
}

void(float damage, vector dir, vector org, vector plane, entity hit_ent, float side) TraceAttack =
{
	vector  vel;
	float f_damage = 0;
  
	vel = normalize(dir);
	vel = vel + 2*plane;
	vel = vel * 200;

	if (hit_ent.takedamage) {
		if (trace_fraction >= 1 || hit_ent.classname == "wunder") {
			return;
		}
		if(hit_ent.classname == "item_radio" || hit_ent.classname == "teddy_spawn")
		{
			entity oldself;
			oldself  = self;
			self = hit_ent;
			self.th_die();
			self = oldself;
			return;
		} else if (hit_ent.classname == "explosive_barrel") {
			hit_ent.enemy = self;
			oldself  = self;
			self = hit_ent;
			self.health = self.health - damage;
			
			Barrel_Hit();
			
			self = oldself;
			return;
		} else if (hit_ent.classname == "door" || hit_ent.classname == "door_nzp") {
			local entity old;
			old = self;
			self = hit_ent;
			self.health -= damage;

			if (self.health < 0)
				door_use();
			self = old;
			return;
		}
		
		SpawnBlood (org, vel, damage*10);

		switch(hit_ent.classname) {
			case "ai_zombie_head":
				f_damage = damage*getWeaponMultiplier(self.weapon, HEAD_X);
				break;
			case "ai_zombie_larm":
			case "ai_zombie_rarm":
				f_damage = damage*getWeaponMultiplier(self.weapon, LIMBS_X);
				break;
			case "ai_zombie":
				if (trace_endpos_z < hit_ent.origin_z)
					f_damage = damage*getWeaponMultiplier(self.weapon, LOWER_TORSO_X);
				else
					f_damage = damage*getWeaponMultiplier(self.weapon, UPPER_TORSO_X);
				break;
			default:
				f_damage = damage;
				break;
		}

		hit_ent.washit = 1;
		hit_ent.hitamount = hit_ent.hitamount + f_damage;
		
		SetUpdate(self, UT_HM, 0, 0, 0);
		
#ifndef FTE

		msg_entity = self;
		WriteByte(MSG_ONE, SVC_HITMARK);
		
#endif // FTE

	} else {

#ifndef FTE

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_GUNSHOT);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);

#endif // FTE

	}
	
#ifdef FTE

	WriteByte(MSG_MULTICAST, SVC_CGAMEPACKET);
	WriteByte(MSG_MULTICAST, EVENT_PISTOLFIRE);
	WriteEntity(MSG_MULTICAST, self);
    WriteFloat(MSG_MULTICAST, side);
	WriteCoord(MSG_MULTICAST, org_x);
	WriteCoord(MSG_MULTICAST, org_y);
	WriteCoord(MSG_MULTICAST, org_z);
	WriteCoord(MSG_MULTICAST, plane_x);
	WriteCoord(MSG_MULTICAST, plane_y);
	WriteCoord(MSG_MULTICAST, plane_z);
	WriteEntity(MSG_MULTICAST, hit_ent);
	multicast(trace_endpos, MULTICAST_PHS);

#endif // FTE
	
};

void (float shotcount, float sprd, float Damage, float side) FireTrace =
{
	float count, r, ru, penetration_times, do_break;
	vector dir, src, trace_start_org;
	entity hitent;
	
	count = 0;
	
	makevectors(self.v_angle);
	
	src = self.origin + self.view_ofs;
	
#ifndef FTE

	CL_SendWeaponFire();

#endif // FTE

	while (count < shotcount)
	{
		dir = aim (self,0);
		r = random() * sprd*10;
		if (random() < 0.5)
			r = r*-1;
		ru = random() * sprd*10;
		if (random() < 0.5)
			ru = ru*-1;

		dir = dir*2048;
		dir = dir + v_right*r + v_up*ru;
		trace_start_org = src;
		trace_ent = self;
		do_break = 0;
		penetration_times = 0;
		hitent = world;
		while (!do_break && random() < getWeaponPenetration(self.weapon, penetration_times))
		{

#ifdef FTE

			AI_SetAllEnemiesBBOX();

#endif // FTE

			traceline (trace_start_org, trace_start_org + dir, MOVE_HITMODEL, trace_ent);

#ifdef FTE

			AI_RevertEnemySolidState();

#endif // FTE

			if (trace_fraction != 1.0)
				TraceAttack (Damage, dir, trace_endpos, trace_plane_normal, trace_ent, side);
			trace_start_org = trace_endpos;
			penetration_times++;
			if (!trace_ent.takedamage)
				do_break = 1;
			
			if (trace_ent.classname == "ai_zombie_head" || trace_ent.classname == "ai_zombie_larm" || trace_ent.classname == "ai_zombie_rarm")
				hitent = trace_ent.owner;
			else
				hitent = trace_ent;

		}
		hitent = world;

		count++;
	}
	if (self.weapon != W_TESLA)
		Parse_Damage();

}


void(float side) W_Fire =
{
	if (GetFiretype(self.weapon) == FIRETYPE_FLAME && self.cooldown)
		return;

	if (self.semiswitch == true || self.dive)
		return;

	//First check that we can actualy fire
	if (side == S_RIGHT &&
		(time < self.fire_delay ||
		self.new_anim_stop ||
		self.reload_delay > time || !self.weapons[0].weapon_magazine)) {
		return;
	}

	if (side == S_LEFT &&
		(time < self.fire_delay2 ||
		self.new_anim2_stop ||
		self.reload_delay2 > time)) {
		return;
	}

	if (self.sprinting) {
		W_SprintStop();
		return;
	}

	float startframe = 0;
	float endframe = 0;
	float firetype;
	float damage;
	float shotcount;
	string modelname = "";
	string soundname;
	float spread;
	float is_moving;
	float delay;

	//Update the basic vectors
	makevectors(self.v_angle);

	//make sure magazine is loading
	if (!self.weapons[0].weapon_magazine && side == S_RIGHT)
	{
		W_Reload(S_RIGHT);
		return;
	} else if (!self.weapons[0].weapon_magazine_left && side == S_LEFT)
	{
		W_Reload(S_LEFT);
		return;
	}

	//Dont fire if the gun has to cycle
	if (self.NeedLoad && (self.weapon == W_TRENCH || self.weapon == W_GUT || self.weapon == W_KAR_SCOPE || self.weapon == W_KAR || self.weapon == W_ARMAGEDDON || self.weapon == W_HEADCRACKER || self.weapon == W_SPRING || self.weapon == W_PULVERIZER))
	{
		W_LoadAmmo();
		return;
	}

	if (self.downed)
		PAnim_LastFire();
	else {
		switch(self.stance) {
			case 2: PAnim_Fire(); break;
			case 1: PAnim_CrouchFire(); break;
			case 0: break;
		}
	}
	
	//get some basic info
	damage = getWeaponDamage(self.weapon);

	if (global_trace_damage_multiplier != 0)
		damage *= global_trace_damage_multiplier;

	firetype = GetFiretype (self.weapon);
	if (side == S_RIGHT) {
		modelname = GetWeaponModel(self.weapon, 0);
	} else {
		if (IsDualWeapon(self.weapon)) {
			modelname = GetLeftWeaponModel(self.weapon); 
		}
	}
	shotcount = GetWeaponShotcount(self.weapon);
    soundname = GetWeaponSound(self.weapon);
	delay = getWeaponDelay(self.weapon, FIRE);

	// Double Tap 2.0
	if (self.perks & P_DOUBLE && self.has_doubletap_damage_buff)
		shotcount *= 2;

	if (self.velocity)
		is_moving = true;
	else
		is_moving = false;

	spread = GetWeaponSpread(self.weapon, is_moving, self.stance);

	if (self.perks & P_DEAD) {
		spread *= 0.65;
	}

	if (self.zoom == 1 && W_SpreadAffectedByADS(self.weapon)) {
		spread *= 0.02;
	} else if (self.zoom == 2) {
		if (W_HighPrecisionWhenADS(self.weapon))
			spread = 0;
		else
			spread *= 0.15;
	}

	// Check if weapon is semi-automatic and if it is, if it's ready to be fired.
	if (Weapon_IsSemiAutomatic(self.weapon)) {
		if (side == S_RIGHT) {
			if (self.semi) return;
			self.semi = true;
		} else if (side == S_LEFT) {
			if (self.semi2) return;
			self.semi2 = true;
		}
	}

	// Weapon Projectile/Trace Logic.
	if (Weapon_FiresTraceshot(self.weapon)) {

#ifdef FTE

		self.dimension_hit = HITBOX_DIM_LIMBS | HITBOX_DIM_ZOMBIES;

#endif // FTE

		FireTrace(shotcount, spread, damage, side);

#ifdef FTE

		self.dimension_hit = HITBOX_DIM_ZOMBIES;

#endif // FTE

	}

	switch(firetype) {
		case FIRETYPE_ROCKET:
			W_FireRocket();
			break;
		case FIRETYPE_GRENADE:
			W_FireGrenade(side);
			break;
		case FIRETYPE_RAYBEAM:
			W_FireRay();
			break;
		case FIRETYPE_TESLA:
			W_FireTesla();
			break;
		case FIRETYPE_FLAME:
			W_FireFlame();
			break;
		default: break;
	}

	// Play weapon animation and sound
	if (GetFrame(self.weapon, FIRE_HOLD) == 0) {
		if (self.zoom && GetFrame(self.weapon, AIM_FIRE_START) != 0) {
			startframe = GetFrame(self.weapon, AIM_FIRE_START);
			endframe = GetFrame(self.weapon, AIM_FIRE_END);
		} else {
			startframe = GetFrame(self.weapon, FIRE_START);
			endframe = GetFrame(self.weapon, FIRE_END);
		}
	} else {
		startframe = endframe = GetFrame(self.weapon, FIRE_HOLD);
	}

	// Increment the amount of shots fired while downed
	if (self.downed == true)
		self.teslacount++;

	if (self.perks & P_DOUBLE) {
		delay *= 0.66;
	}

	// Players shouldn't be allowed to move while firing and prone.
	if (self.stance == 0) {
		self.speed_penalty = 0.01;
		self.speed_penalty_time = time + delay;
	}

	if (self.weapon == W_GUT || self.weapon == W_KAR_SCOPE || self.weapon == W_TRENCH || self.weapon == W_KAR || self.weapon == W_ARMAGEDDON || self.weapon == W_HEADCRACKER || self.weapon == W_SPRING || self.weapon == W_PULVERIZER)
	{
		Set_W_Frame (startframe, endframe, delay, 0, FIRE, W_LoadAmmo, modelname, FALSE, side);
		self.NeedLoad = true;
	} else {
		Set_W_Frame (startframe, endframe, delay, 0, FIRE, CheckReload, modelname, FALSE, side);
	}


	sound (self, CHAN_WEAPON, soundname, 1, ATTN_NORM);

	if (side == S_RIGHT) {
		self.weapons[0].weapon_magazine = self.weapons[0].weapon_magazine - 1;
		self.fire_delay = getWeaponDelay(self.weapon, FIRE) + time;
	} else {
		self.weapons[0].weapon_magazine_left = self.weapons[0].weapon_magazine_left - 1;
		self.fire_delay2 = getWeaponDelay(self.weapon, FIRE) + time;
	}

	if (IsPapWeapon(self.weapon)) {
		sound (self, 0, "sounds/weapons/papfire.wav", 1, ATTN_NORM);
	}
	
	SetUpdate(self, UT_HUD, 6, 0, 0);
	SetUpdate(self, UT_CROSSHAIR, 5, 0, 0);
	

	// REFORMAT THIS 
#ifndef FTE

	if (side == S_LEFT)
		self.Flash_Offset = WepDef_GetLeftFlashOffset(self.weapon);
	else
		self.Flash_Offset = GetWeaponFlash_Offset(self.weapon);

	self.effects = self.effects | EF_MUZZLEFLASH;

#else 

	SendWeaponRecoil(self, self.weapon);

#endif // FTE

}


/******************************
* W_Knife                     *
******************************/

void () W_Knife =
{
	if (time < self.knife_delay || self.new_anim_stop ||
	  self.zoom || self.health == 10 || 
	  (!(self.flags & FL_ONGROUND)))
		return;

	vector	source;
	entity	hit_ent = world;
	//entity	oldself;
	float	r, backupSkin;
	vector	org;
	float hit = false;
		
	if (self.sprinting) {
		W_SprintStop();
	}

	W_HideCrosshair(self);

	if (self.stance == 2)
		PAnim_Melee();
	
	backupSkin = self.weaponskin;
	self.weaponskin = 0;
	sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife.wav", 1, ATTN_NORM);
	makevectors (self.v_angle);
	source = self.origin + self.view_ofs;
	if (self.weapon == W_BK || self.weapon == W_KRAUS)
		traceline (source, source + v_forward*80*1.2, 0, self);
	else
		traceline (source, source + v_forward*74*1.2, 0, self);
	
	org = trace_endpos - v_forward*4;

	r = fabs(vlen(source - org));

	if (trace_ent.takedamage)
	{
		if (trace_ent.classname == "ai_zombie_head")
			hit_ent = trace_ent.owner;
		else if (trace_ent.classname == "ai_zombie_larm")
			hit_ent = trace_ent.owner;
		else if (trace_ent.classname == "ai_zombie_rarm")
			hit_ent = trace_ent.owner;
		else
			hit_ent = trace_ent;
		if (hit_ent.classname == "ai_zombie")
			hit = true;

		// if zombie has a head and it's instakill, gib for  a e s t h e t i c
		if (hit_ent.head && instakill_finished >= time) {
			spawn_gibs(hit_ent.head.origin);
			setmodel(hit_ent.head, "");
		}
	}
	else if (trace_fraction < 1.0)
	{	// hit wall
		sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife_hit.wav", 1, ATTN_NORM);			
	}

	if (r > 40 && hit)//lunge
	{
		if (self.weapon == W_BK || self.weapon == W_KRAUS)
		{
			Set_W_Frame (14, 24, 1.4, 0, KNIFE, SUB_Null, "models/weapons/bk/v_bk.mdl", false, S_RIGHT);
			self.fire_delay = time + 1.5;
			self.knife_delay = time + 1.75;
		}
		else if (self.bowie)
		{
			Set_W_Frame (4, 10, 1.0, 0, KNIFE, W_PlayTakeOut, "models/weapons/knife/v_bowie.mdl", false, S_RIGHT);
			self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.8;
			self.knife_delay = time + 1.3;
		}
		else
		{
			self.punchangle_x = -5;
			self.punchangle_y = -10;
			Set_W_Frame (4, 12, 0.74, 0, KNIFE, W_PlayTakeOut, "models/weapons/knife/v_knife.mdl", false, S_RIGHT);
			self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.8;
			self.knife_delay = time + 1.1;
		}
		self.velocity = v_forward * r * 6;
		
	}
	else
	{
		if (self.weapon == W_BK || self.weapon == W_KRAUS)//slash
		{
			Set_W_Frame (8, 13, 0, 0.4, KNIFE, SUB_Null, "models/weapons/bk/v_bk.mdl", false, S_RIGHT);
			self.fire_delay = time + 0.5;
			self.knife_delay = time + 0.8;
		}
		else if (self.bowie)
		{
			Set_W_Frame (0, 3, 0.65, 0, KNIFE, W_PlayTakeOut, "models/weapons/knife/v_bowie.mdl", false, S_RIGHT);
			self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
			self.knife_delay = time + 0.9;
		}
		else
		{
			self.punchangle_x = -5;
			self.punchangle_y = -10;
			//self.punchangle_z = 5;
			Set_W_Frame (0, 3, 0.45, 0, KNIFE, W_PlayTakeOut, "models/weapons/knife/v_knife.mdl", false, S_RIGHT);
			self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
			self.knife_delay = time + 0.8;
		}
	}
	self.reload_delay2 = self.reload_delay = 0;
	self.weaponskin = backupSkin;
	
	LungeKnifeHit();

};




/******************************
* W_Grenade                   *
******************************/

void() switch_nade = 
{ 
	if (self.downed || self.isBuying || !(self.grenades & 2) || self.seminade)
      return;

	if (self.pri_grenade_state == 0)
	{
		centerprint (self, "Bouncing Betties Selected");
		self.bk_nade = 1;
    }
    if (self.pri_grenade_state == 1)
    {
		centerprint (self, "Frag Grenades Selected");
		self.bk_nade = 0;
    }  	
	
	self.pri_grenade_state = self.bk_nade;

};

void() GrenadeExplode =
{
	sound (self, CHAN_WEAPON, "sounds/weapons/grenade/explode.wav", 1, ATTN_NORM);	

	if (self.classname == "grenade")
		DamgageExplode (self, self.owner, 200, 50, 200);
	else if (self.classname == "betty")
		DamgageExplode (self, self.owner, 12000, 11000, 128);
	else
		DamgageExplode (self, self.owner, 1200, 1000, 75);

#ifdef FTE

    te_customflash(self.origin, 200, 300, '1 1 1');

#endif // FTE

	// Really stupid hack: For betties, let's dramatically increase
	// the explosion effect.
	if (self.classname == "betty") {
		CallExplosion(self.origin);	
		CallExplosion(self.origin);	
		CallExplosion(self.origin);	
		CallExplosion(self.origin);	
	} else {
    	CallExplosion(self.origin);		
	}
	
	SUB_Remove ();
};

void() NadeStraighten =
{
	self.angles_x = (self.angles_x > 0) ? 90 : -90;	
	
	if (self.pri_grenade_state == 1)
    return;
};
void() Velocity_reduce =
{
	if (!other.solid || other.solid == SOLID_TRIGGER)
		if (other != world)
			return;

	self.velocity = self.velocity*0.5;
	
	NadeStraighten();
};

void() W_ThrowGrenade =
{
	string modelname;
	float startframe;
	float endframe;
	local	entity nade;

	W_HideCrosshair(self);

	if (self.pri_grenade_state == 0) {
		nade = spawn ();
		nade.owner = self;
		nade.grenade_delay = nade.owner.grenade_delay;
		nade.owner.grenade_delay = 0;
		nade.movetype = MOVETYPE_BOUNCE;
		nade.solid = SOLID_BBOX;
		nade.classname = "grenade";

		// set nade speed	

		makevectors (self.v_angle);

		nade.velocity = v_forward*1400;
		
		nade.avelocity = '400 -400 400';

		//nade.angles = vectoangles(nade.velocity);
		//nade.angles_z += (nade.angles_z + 180 < 360)? 180 : -180;
		nade.angles = vectoangles(v_forward);
		nade.angles_z -= 15;
		// set nade duration
		nade.nextthink = nade.grenade_delay;
		nade.think = GrenadeExplode;

		nade.touch = Velocity_reduce;
		setmodel (nade, "models/weapons/grenade/g_grenade.mdl");
		setsize (nade, '0 0 0', '0 0 0');
		nade.origin = self.origin + self.view_ofs;
		nade.origin += v_forward * 12;
		setorigin (nade, nade.origin);

		self.animend = ReturnWeaponModel;
		self.callfuncat = 0;
		self.isBuying = false;
	} else if (self.pri_grenade_state == 1) {
		Betty_Drop();
	} else  {
		centerprint (other, "No grenadetype defined...\n");
	}

	startframe = GetFrame(self.weapon,TAKE_OUT_START);
	endframe = GetFrame(self.weapon,TAKE_OUT_END);
	modelname = GetWeaponModel(self.weapon, 0);
	Set_W_Frame (startframe, endframe, 0, 0, 0, ReturnWeaponModel, modelname, false, S_BOTH);

	SetUpdate(self, UT_HUD, 6, 0, 0);
}

void() checkHold =
{
	if (self.pri_grenade_state == 1) {
		Betty_CheckForRelease();
		return;
	}

	if (!self.button3 || self.grenade_delay < time)
	{
		if(self.grenade_delay < time)
			self.grenade_delay = time + 0.05;
			
		self.isBuying = true;  
		Set_W_Frame (3, 6, 0, 5, GRENADE, W_ThrowGrenade, "models/weapons/grenade/v_grenade.mdl", true, S_RIGHT);
		sound (self, CHAN_WEAPON, "sounds/weapons/grenade/throw.wav", 1, ATTN_NORM);
		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = time + 0.4;
		self.throw_delay = time + 0.9;
	}
	else
	{
		if (self.isBuying == false) {
			W_ShowCrosshair(self);
			self.isBuying = true;
		}

		// Pulse the grenade crosshair every 1 second
		float difference = rint(self.grenade_delay - time);
		if (difference != self.beingrevived) {
			self.beingrevived = difference;
			grenade_pulse(self);
		}

		Set_W_Frame (2, 2, 0, 0, GRENADE, checkHold, "models/weapons/grenade/v_grenade.mdl", true, S_RIGHT);
	}
}

void() W_Grenade =
{
	if (self.throw_delay > time || self.zoom || self.downed || self.primary_grenades < 1 || self.isBuying)
		return;

	// Prevent the Player from Sprinting and also avoid issues with
	// the equipment being completely cancelled..
	if (self.sprinting)
		W_SprintStop();

	W_HideCrosshair(self);
	Set_W_Frame (0, 2, 0.6, 0, GRENADE, checkHold, "models/weapons/grenade/v_grenade.mdl", true, S_RIGHT);
	sound (self, CHAN_WEAPON, "sounds/weapons/grenade/prime.wav", 1, ATTN_NORM);	
	self.primary_grenades -= 1;
	self.reload_delay2 = self.fire_delay2 = self.throw_delay = self.reload_delay = self.fire_delay = time + 6;
	self.grenade_delay = time + 5;
    self.seminade = true;
} 

void(float wepnum) CheckButton = {
	W_PutOut();
}

void() Change_Stance = {

	if (self.downed || !(self.flags & FL_ONGROUND) || self.changestance == true || self.new_ofs_z != self.view_ofs_z)
		return;

	switch(self.stance) {
		case 2: 
			self.new_ofs_z = self.view_ofs_z - PLAYER_CROUCH_HEIGHT;
			self.stance = 1;
			PAnim_Crouch();
			setsize(self, PLAYER_MINS_CROUCHING, PLAYER_MAXS_CROUCHING);
			break;
		case 1:
			// Prohibit Proning if Drinking a Perk-A-Cola
			if (self.isBuying && Player_CanStandHere(self)) {
				self.stance = 2;
				self.new_ofs_z = self.view_ofs_z + PLAYER_CROUCH_HEIGHT;
				PAnim_Stand();
				setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
			} 
			// Stance flag isn't set, so go Prone.
			else if (!self.stancereset) {
				self.new_ofs_z = self.view_ofs_z - PLAYER_PRONE_HEIGHT;
				self.stance = 0;
				PAnim_Prone();
			} 
			// Stance flag IS set, so stand if applicable.
			else if (Player_CanStandHere(self)) {
				self.new_ofs_z = self.view_ofs_z + PLAYER_CROUCH_HEIGHT;
				self.stance = 2;
				self.stancereset = 0;
				PAnim_Stand();
				setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
			} 
			// There's no room to stand, just prone again.
			else {
				self.new_ofs_z = self.view_ofs_z - PLAYER_PRONE_HEIGHT;
				self.stance = 0;
				PAnim_Prone();
			}
			break;
		case 0:
			self.new_ofs_z = self.view_ofs_z + PLAYER_PRONE_HEIGHT;
			self.stance = self.stancereset = 1;
			setsize(self, PLAYER_MINS_CROUCHING, PLAYER_MAXS_CROUCHING);
			PAnim_UpCrouch();
			break;
		default: break;
	}

}

void() dolphin_dive =		//naievil
{    
	if (self.stance != 2 || self.view_ofs_z != 32)
		return;
 	if (self.flags & FL_WATERJUMP)
		return;

	if (self.waterlevel >= 2)
	{
		if (self.watertype == CONTENT_WATER)
			self.velocity_z = 100;
		else if (self.watertype == CONTENT_SLIME)
			self.velocity_z = 80;
		else
			self.velocity_z = 50;
	}

	if (!(self.flags & FL_ONGROUND))
		return;
		
	if ( !(self.flags & FL_JUMPRELEASED) )
		return;		// don't pogo stick
		
  
	self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
	self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
	makevectors (self.v_angle);
    self.velocity = self.velocity * 1.1;		
	self.velocity_z = self.velocity_z + 270;

	if (self.button2)
		self.button2 = 0;

	self.dive = 1;
	W_SprintStop();
	PAnim_EnterDive();

	sound(self, CHAN_VOICE, "sounds/player/jump.wav", 1, 1);

	self.oldz = self.origin_z;
	self.new_ofs_z = self.view_ofs_z - (PLAYER_CROUCH_HEIGHT + PLAYER_PRONE_HEIGHT);
	self.stance = 0;
	setsize(self, PLAYER_MINS_CROUCHING, PLAYER_MAXS_CROUCHING);
}


void () Impulse_Functions =
{
	if (!self.impulse)
		return;
		
	switch (self.impulse)
	{		
		case 10:

#ifdef FTE

			// FTE handles jumping, which we don't want.. so we use impulses to override.
			JumpCheck(1);

#endif // FTE
			break;
		case 22:
			addmoney(self, 10000, 0);
			rounds += 4;
			break;
		case 23:

#ifdef FTE

			if (!checkMovement(forward))
				return;

#endif // FTE

			if (self.dive || self.downed || !Player_CanStandHere(self))
				return;
			switch(self.stance) {
				case 0:
					self.new_ofs_z = self.view_ofs_z + PLAYER_CROUCH_HEIGHT + PLAYER_PRONE_HEIGHT;
					self.stance = 2;
					setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
					break;
				case 1:
					self.new_ofs_z = self.view_ofs_z + PLAYER_CROUCH_HEIGHT;
					self.stance = 2;
					setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
					break;
				default: break;
			}
			self.sprintflag = true;
			W_SprintStart();
			break;
		case 24:
			self.sprintflag = false;
			W_SprintStop();
			break;
		case 25:
			switch_nade();
			break;
		case 33:
			W_PrimeBetty();
			break;
		case 26:
		case 30:
			if (self.sprinting)
				dolphin_dive();
			else
				Change_Stance();
			break;
		case 31:
			self.sprintflag = 0;
			break;
		case 32:
			self.sprintflag = 1;
			break;
		case 110:
		case 111:
			W_PutOut();
			self.semiswitch = true;
			break;	
		case 100:
			cvar_set("waypoint_mode", "1");
			
			local entity d;
			d = find(world,classname,"door_nzp_cost");
			while(d != world)
			{
				d.classname = "door_nzp";
				d = find(d,classname,"door_nzp_cost");
			}
			d = find(world,classname,"door_open");
			while(d != world)
			{
				d.classname = "door_nzp";
				d = find(d,classname,"door_open");
			}
			
			waypoint_mode = 1;
			localcmd("restart\n");
			break;
		default:

#ifdef FTE

			bprint(PRINT_HIGH, "Unknown impulse: ", ftos(self.impulse));

#endif // FTE

			break;
	}
	
	self.impulse = 0;
};

void() CheckImpulses =
{
	self.impulse = 0;
}

void(entity ent) CheckPowerups =
{
	if (instakill_finished >= time)
	{
		if (instakill_finished < 4 + time)
		{
			if (insta_blink< time - 0.25)
				insta_blink = time + 0.25;
		}
		else if (instakill_finished < 7 + time)
		{
			if (insta_blink< time - 0.5)
				insta_blink = time + 0.5;
		}
		else if (instakill_finished < 10 + time)
		{
			if (insta_blink< time - 1)
				insta_blink = time + 1;
		}
		
		if (insta_blink < time)
			ent.insta_icon = true;
		else 
			ent.insta_icon = false;		
	}
	else if(instakill_finished)
	{
		instakill_finished = 0;
		
		ent.insta_icon = false;
	}
	
	if (x2_finished > time)
	{
		if (x2_finished < 4 + time)
		{
			if (x2_blink< time - 0.25)
				x2_blink = time + 0.25;
		}
		else if (x2_finished < 7 + time)
		{
			if (x2_blink< time - 0.5)
				x2_blink = time + 0.5;
		}
		else if (x2_finished < 10 + time)
		{
			if (x2_blink< time - 1)
				x2_blink = time + 1;
		}
		
		if (x2_blink < time)
			ent.x2_icon = true;
		else 
			ent.x2_icon = false;
	}
	else if(x2_finished)
	{
		x2_finished = 0;
		
		ent.x2_icon = false;
	}

}

void() CheckPlayer = 
{
	CheckPowerups(self);
	CheckRevive(self);

	if (!self.sprintflag && self.sprinting) {
		W_SprintStop();
	}

	// FIXME - can't do frame independent stance changing.. ofs starts spazzing..
	if (self.view_ofs_z > self.new_ofs_z) {
			self.changestance = true;
			self.view_ofs_z = self.view_ofs_z - 1;
	} else if (self.view_ofs_z < self.new_ofs_z) {
			self.changestance = true;
			self.view_ofs_z = self.view_ofs_z + 1;
	} else {
		self.changestance = false;
	}

	if (self.view_ofs_z > 32) {
		self.view_ofs_z = 32;
		self.changestance = false;
	}

	// Diving on top of other players :)
	if (self.dive && !(self.flags & FL_ONGROUND)) {
		makevectors(self.angles);
		traceline(self.origin, self.origin + (v_up * -40), 0, self);

		if (trace_ent.classname == "player") {
			DamageHandler(self, trace_ent, 100000, S_NORMAL);
			DamageHandler(trace_ent, self, 100000, S_NORMAL);
		}
	}
	
	if (!self.button2 && self.flags & FL_ONGROUND) {
		float dist = fabs(self.oldz - self.origin_z);

		if (self.dive) {
			if (self.perks & P_FLOP && dist >= 64) {
				sound (self, CHAN_WEAPON, "sounds/weapons/grenade/explode.wav", 1, ATTN_NORM);	
				DamgageExplode (self, self, 5000, 1000, 300);

#ifdef FTE

				te_customflash(self.origin, 300, 300, '1 0.6 0.1');

#endif // FTE

				CallExplosion(self.origin);
				CallExplosion(self.origin);
				CallExplosion(self.origin);
			}
			PAnim_Flop();
			self.dive = 0;
		}

		if (dist + 64 > 176 && !(self.perks & P_FLOP)) {
			float height = dist + 64;
			float damage = height*(0.68);

			if (damage > 98) damage = 98;
			
			DamageHandler (self, other, damage, S_ZOMBIE);	

			if (self.health <= 5)
				GiveAchievement(7, self);	
		}
		
		self.oldz = self.origin_z;		
	}

	//
	// Revive Sequence
	//
#ifdef FTE

	entity ent;
	ent = findradius(self.origin, 70);
		
	while(ent)
	{
		if(ent.classname == "player" && ent != self && ent.downed)
		{

			// perform a trace to make sure they're always facing the revivee
			vector source;
			makevectors(self.angles);
			source = self.origin - '0 0 12';
			traceline(source, source + v_forward*50, 0, self);
			self.active_door = trace_ent;

			if (ent.beingrevived == false && self.active_door == ent && !self.downed)
				useprint (self, 13, 0, 0);
			
			if (self.button7 && !ent.invoke_revive && self.active_door == ent && !self.downed) {
				if (ent.beingrevived == true && ent.firer != self)
					return;

				// Broadcast that they're being revived
				BroadcastMessageToClient(ent, time + 2, 3, self.netname);

				ent.speed_penalty = 0.01;
				ent.speed_penalty_time = time + 100;
				ent.beingrevived = true;
				ent.firer = self;
				
				if (!self.progress_bar_percent) {
					ChangeReviveIconState(ent.electro_targeted, 2);
					self.movetype = MOVETYPE_TOSS;
					Set_W_Frame (0, 21, 0, 0, SPRINT, SUB_Null, "models/weapons/morphine/v_morphine.mdl", false, S_RIGHT);
					
					if !(self.perks & P_REVIVE)
						self.progress_bar_time = 4;
					else
						self.progress_bar_time = 2;
					
					self.progress_bar = self.progress_bar_time + time;     
					self.progress_bar_percent = 1;
					self.reviving = true;
				}
				
				if (self.revived) {
					self.movetype = MOVETYPE_WALK;
					W_TakeOut();
					ent.invoke_revive = 1;
					ent.beingrevived = false;
					ent.speed_penalty_time = 0;
					self.reviving = 0;
					self.progress_bar = 0;
					self.progress_bar_time = 0;
					self.progress_bar_percent = 0;
					self.revived = 0;
					addmoney(self, ent.requirespower, false);
				}
			}
			else if (self.downed || (!self.button7 && self.reviving) || (self.reviving && self.active_door != ent) || ent.classname == "disconnected") {
				if (ent.classname != "disconnected")
					ChangeReviveIconState(ent.electro_targeted, 1);
				else
					DisableReviveIcon(ent.electro_targeted);
				self.movetype = MOVETYPE_WALK;
				ent.beingrevived = false;
				ent.speed_penalty_time = 0;
				ent.firer = world;
				W_TakeOut();
				self.progress_bar = 0;
				self.progress_bar_time = 0;
				self.progress_bar_percent = 0;
				self.revived = 0;
				self.reviving = 0;
			}
		}
		else if(ent.classname == "player" && ent != self && !ent.downed) // small player push 
		{
			vector push;
			push =  ent.origin - self.origin;
			push_z = 0;
			push = normalize(push) * 0.5;
			
			ent.velocity += push;
		}
		ent = ent.chain;
	}

#endif // FTE

}

void () Weapon_Logic =
{
	// HACK HACK: Don't let the frame updater take control of hold fire.
	if (self.weaponframe == GetFrame(self.weapon, FIRE_HOLD) && GetFrame(self.weapon, FIRE_HOLD) != 0 && self.weaponmodel == GetWeaponModel(self.weapon, 0)) {

	} else {
		W_Frame_Update();
		W2_Frame_Update();
	}
	
		
	Impulse_Functions();

#ifndef FTE

	// For non-FTE only to tell our engine to display the scope
	if ((self.scopetime < time) && self.scopetime) {
		self.scopetime = 0;
		self.zoom = 2;
		self.weapon2model = "";
		self.weaponmodel = "";
	}

#else

	UpdatePunchangle(self);

#endif // FTE

	// If the player is aiming down the sight while prone and moving,
	// force them to stop
	if (self.stance == 0 && self.velocity && self.zoom) {
		W_AimOut();
		self.zoom = 0;

#ifdef FTE

		self.viewzoom = 1;
		UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
		UpdateV2model(self.weapon2model, 0);

#endif // FTE

	}

	//
	// Force-ADS if toggled
	//
	if (cvar("cl_adsmode")) {
		// Toggle ADS back and forth
		if (self.ads_toggle == false) {
			W_AimOut();
			self.zoom = 0;

#ifdef FTE

			self.viewzoom = 1;
			UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
			UpdateV2model(self.weapon2model, 0);

#endif // FTE
		} else if (self.reload_delay < time && self.reload_delay2 < time &&
		self.knife_delay < time && self.grenade_delay < time) {
			if (self.stance == 0 && self.velocity)
				return;

			W_AimIn();

#ifdef FTE

			if (self.weapon == W_KAR_SCOPE   || self.weapon == W_PTRS ||
					self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
						if (self.scopetime >= time) {
							self.viewzoom = 1 - (0.018*GetWeaponZoomAmount(self.weapon));
							self.zoom = 2;
						}
			} else {
				self.viewzoom = 1 - (0.018*GetWeaponZoomAmount(self.weapon));
			}

#endif // FTE

			if (!self.zoom) {
				if (self.weapon == W_KAR_SCOPE   || self.weapon == W_PTRS ||
					self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
					SetUpdate(self, UT_ZOOM2, 0, 0, 0);
					self.zoom = 2;
					self.scopetime = time + 0.3;
				} else {
					self.zoom = 1;
				}
			}
		}
	}

	//
	// Fire Button Logic
	// NOTE: Since the right weapon is the "normal" side there's some
	// flip flop logic on FTE so that LMB will fire the left side instead.
	//

	// Right Trigger/LMB/etc.
	if (self.button0) {

#ifdef FTE

		if (IsDualWeapon(self.weapon)) { W_Fire(S_LEFT); } else { W_Fire(S_RIGHT); }

#else

		W_Fire(S_RIGHT);

#endif // FTE

	} else {
		// Check for release for semi automatic weapons.

#ifdef FTE

		if (IsDualWeapon(self.weapon)) { self.semi2 = false; } else { self.semi = false; }

		// Hold fire weapons should get set back to base frame.
		if (GetFrame(self.weapon, FIRE_HOLD) != 0 && self.weaponframe == GetFrame(self.weapon, FIRE_HOLD) &&
		self.weaponmodel == GetWeaponModel(self.weapon, 0)) {
			self.weaponframe = 0;
		}

#else

		self.semi = false;

#endif // FTE

	}

	// Left Trigger/RMB/etc.
	if (self.button8) {
		if (IsDualWeapon(self.weapon)) {

#ifdef FTE

			W_Fire(S_RIGHT);

#else

			W_Fire(S_LEFT);

#endif // FTE

		} else {
			if (cvar("cl_adsmode")) {
				if (self.ads_release == false)
					return;

				self.ads_toggle = !self.ads_toggle;
				self.ads_release = false;
			} else {
				if (self.stance == 0 && self.velocity)
					return;

				W_AimIn();

#ifdef FTE

				if (self.zoom) {
					if (self.weapon == W_KAR_SCOPE   || self.weapon == W_PTRS ||
					self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
						if (self.scopetime >= time)
							self.viewzoom = 1 - (0.018*GetWeaponZoomAmount(self.weapon));
					} else {
						float zoom_factor = 1 - (0.018*GetWeaponZoomAmount(self.weapon));
						float sigmoid_input = (self.viewzoom - zoom_factor) * 10; // multiply by 10 to adjust the steepness of the sigmoid
						float sigmoid_output = 1 / (1 + exp(-sigmoid_input)); // apply the sigmoid function
						float zoom_speed = 0.06 * (sigmoid_output + 0.5) * (frametime*40); // adjust the zoom speed based on the sigmoid output

						if (self.viewzoom > zoom_factor) {
							self.viewzoom -= zoom_speed;
							if (self.viewzoom < zoom_factor)
								self.viewzoom = zoom_factor;
						} else {
							self.viewzoom = zoom_factor;
						}
					}
				}

#endif // FTE

			}
		}
	}
	// AIM button is released
	else if (!self.button8 && self.zoom) {
		// So ADS toggle knows not to spam updates.
		self.ads_release = true;

		if (cvar("cl_adsmode") && self.ads_toggle == true)
			return;

#ifdef FTE

		if (self.weapon == W_KAR_SCOPE   || self.weapon == W_PTRS ||
			self.weapon == W_HEADCRACKER || self.weapon == W_PENETRATOR) {
			ReturnWeaponModel();
			UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
			UpdateV2model(self.weapon2model, 0);
			self.viewzoom = 1;
			self.zoom = 0;
			if (self.weapons[0].weapon_magazine == 0)
				W_Reload(S_BOTH);
		} else {
			if (self.viewzoom == 0.75) {
				W_AimOut();
			} else {
				float zoom_factor2 = 1 + (0.018 * GetWeaponZoomAmount(self.weapon)); // increase zoom factor
				float sigmoid_input2 = (zoom_factor2 - self.viewzoom) * 10; // adjust sigmoid input
				float sigmoid_output2 = 1 / (1 + exp(-sigmoid_input2)); // apply the sigmoid function
				float zoom_speed2 = 0.06 * (sigmoid_output2 + 0.5) * (frametime * 80); // adjust the zoom speed based on the sigmoid output

				if (self.viewzoom < zoom_factor2) {
					self.viewzoom += zoom_speed2;
					if (self.viewzoom > zoom_factor2)
						self.viewzoom = zoom_factor2;
				} else {
					self.viewzoom = zoom_factor2;
				}
			}
		}
		
		// Don't stop aiming until the camera is restored
		if (self.viewzoom >= 1) {
			self.viewzoom = 1;

			if (self.zoom != 3)
				self.zoom = 0;
		}

#else

		W_AimOut();

#endif // FTE

	} else {
		
		// So ADS toggle knows not to spam updates.
		self.ads_release = true;

		// Check for release for semi automatic weapons.
		if (IsDualWeapon(self.weapon)) {

#ifdef FTE

			self.semi = false;

#else

			self.semi2 = false;

#endif // FTE

		}
	}
	
	if (!self.button7) {
		self.semiuse = false;
	}
	
	if (self.button4 && !self.semiswitch && self.weapon_count != 1 && !self.zoom)
	{
		W_PutOut();
		self.semiswitch = true;
	} else if (!self.button4 && self.semiswitch && self.impulse != 110 && self.impulse != 111) {
		self.semiswitch = false;
	}
	
	if (self.button3 && self.isBuying != true && self.seminade != true)
	{
        if (self.pri_grenade_state == 0)
		    W_Grenade();
        else
            W_PrimeBetty();
		self.seminade = true;
	} else if (!self.button3 && self.seminade) {
		self.seminade = false;
	}

	if (self.button5 && !self.semireload)
	{
		W_Reload(S_BOTH);
		self.semireload = TRUE;
	}
	else if (!self.button5) {
		self.semireload = FALSE;
	}
	
	if (self.button6 && !self.semiknife)
	{ 

		// Don't do this at all on FTE.
#ifndef FTE

		if (self.sprinting) {
			dolphin_dive();
			return;
		}

#endif // FTE

		W_Knife();
		self.semiknife = true;
	}
	else if (!self.button6)
		self.semiknife = false;
	
	CheckImpulses();
	CheckPlayer();	

	// These are sent to clients in engine for stat
	// reference.
	self.currentammo = self.weapons[0].weapon_reserve;
	self.currentmag = self.weapons[0].weapon_magazine;
	self.currentmag2 = self.weapons[0].weapon_magazine_left;
}
