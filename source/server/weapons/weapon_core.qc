/*
	server/weapons/weapon_core.qc

	weapon logic

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
	}

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

	if ((self.stance == PLAYER_STANCE_PRONE) && self.velocity)
		return;

	if (IsDualWeapon(self.weapon) ||
		self.reload_delay > time ||
		self.knife_delay > time ||
		self.new_anim_stop) {		
		return;
	}

	if (self.sprinting) {
		W_SprintStop();

		// FIXME: When we eventually allow custom delay values
		// for every weapon animation, this hardcoded frame
		// timer can be removed.
		float sprint_fire_delay = fabs(GetFrame(self.weapon, SPRINT_OUT_END) - GetFrame(self.weapon, SPRINT_OUT_START))/10;
		self.fire_delay = self.fire_delay2 = time + sprint_fire_delay;
	}

	float ads_frame = GetFrame(self.weapon, AIM_IN);
	if (ads_frame != 0 && self.fire_delay < time) {
		self.weaponframe_end = self.weaponframe = ads_frame;
	} else if (self.zoom) {
		return;
	}

	if (WepDef_HasSniperScore(self.weapon))
		self.scopetime = time + 0.3;
	
	// Even if the weapon is scoped, we should still initialize
	// the Zoom factor of one so it begins moving into position.
	self.zoom = 1;
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

	self.zoom = 0;

	// Update sniper zoom-out time instantly
	self.scopetime = 0;

	// Always set ads_release to false, to avoid complicating
	// actions where the player is forced to Aim Out with
	// Toggled ADS.
	self.ads_release = false;
}

void() W_SprintStop =
{
	if (self.isBuying || !self.sprinting)
		return;

	Weapon_PlayViewModelAnimation(ANIM_SPRINT_STOP, ReturnWeaponModel, 0);

	// Run Walk for a few frames to simulate an ease in velocity
	PAnim_Walk6();

	self.zoom = 0;
	self.tp_anim_time = 0;
	self.sprinting = 0;
	self.into_sprint = 0;
	self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;
	self.sprint_stop_time = time;
	self.sprint_duration = self.sprint_timer;
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
	if (self.weapons[1].weapon_id == 0 || self.downed ||
	self.switch_delay > time)
		return;

	float duration = getWeaponDelay(self.weapon, PUTOUT);
	self.switch_delay = duration + time;
	self.semi_actions |= SEMIACTION_WEAPONSWAP;
	
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
	self.switch_delay = duration + time;

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
			// cypress -- world at war depicts the trench gun as needing to 
			// pump after reload regardless of context, so i removed a reference
			// that would only do it if the mag was empty. tradeoff: now we're
			// pumping 2 shells away instead of 1 if not empty. oh well.
			self.NeedLoad = true;
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
		delay = 0.9;
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

//
// WeaponCore_CheckForReload()
// Determines if weapon should automatically
// reload after firing, or if weapon is empty
// and needs swapped out.
//
void() WeaponCore_CheckForReload =
{
	// Save some array lookup time -- copy into temporary structs.
	float wep_cur_mag = self.weapons[0].weapon_magazine;
	float wep_cur_mag2 = self.weapons[0].weapon_magazine_left;
	float wep_cur_res = self.weapons[0].weapon_reserve;
	float wep_nex_mag = self.weapons[1].weapon_magazine;
	float wep_nex_mag2 = self.weapons[1].weapon_magazine_left;
	float wep_nex_res = self.weapons[1].weapon_reserve;

	// Check if left weapon needs reloaded
	if (!wep_cur_mag2 && IsDualWeapon(self.weapon)) {
		W_Reload(S_LEFT);
	}

	// Check if right weapon needs reloaded
	if (!wep_cur_mag && wep_cur_res) {
		W_Reload(S_RIGHT);
	}

	// Check if a weapon swap is necessary
	if (!wep_cur_mag && !wep_cur_res && !wep_cur_mag2 &&
	(wep_nex_mag || wep_nex_mag2 || wep_nex_res)) {
		W_PutOut();
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

	FTE_RunParticleEffect(world, CSQC_PART_BLOODIMPACT, org, 0, world);

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

	FTE_RunParticleEffect(world, CSQC_PART_ZOMBIEGIB, where, 0, world);

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
 					vector where = body_ent.origin + (body_ent.head.view_ofs_x * v_right) + (body_ent.head.view_ofs_y * v_forward) + (body_ent.head.view_ofs_z * v_up);
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

			if (instakill_finished > time) {
				if(body_ent.head.deadflag) {
					makevectors(body_ent.head.owner.angles);
 					where = body_ent.origin + (body_ent.head.view_ofs_x * v_right) + (body_ent.head.view_ofs_y * v_forward) + (body_ent.head.view_ofs_z * v_up);
 					spawn_gibs(where);

					body_ent.head.deadflag = false;
					body_ent.head.solid = SOLID_NOT;
					setmodel(body_ent.head,"");
					body_ent.head.frame = 0;

#ifndef FTE

					updateLimb (body_ent.head.owner, 0, world);

#endif // FTE

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

void(float damage, vector dir, vector org, vector plane, entity hit_ent, float side) TraceAttack =
{
	vector  vel;
	float f_damage = 0;
  
	vel = normalize(dir);
	vel = vel + 2*plane;
	vel = vel * 200;

	if (hit_ent.takedamage) {
		if (trace_fraction >= 1) {
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
		} else if (hit_ent.solid == SOLID_BSP) {
			oldself = self;
			self = hit_ent;
			self.health -= damage;
			self.enemy = oldself;

			if (self.health < 0)
				self.th_die();
			self = oldself;
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

	FTE_RunParticleEffect(self, CSQC_PART_MUZZLEFLASH, org, side, hit_ent);

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
	
	CL_SendWeaponFire(self, self.weapon);

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

	if (self.switch_delay > time || self.dive)
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

	spread = WepDef_WeaponSpread(self.weapon, self.stance);

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
			if (self.semi_actions & SEMIACTION_FIRE_RIGHT) return;
			self.semi_actions |= SEMIACTION_FIRE_RIGHT;
		} else if (side == S_LEFT) {
			if (self.semi_actions & SEMIACTION_FIRE_LEFT) return;
			self.semi_actions |= SEMIACTION_FIRE_LEFT;
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

	// Cypress -- sources suggest Double Tap decreases fire rate
	// by 33% (meaning 66%), but testing has concluded it is instead
	// a rate of 23%, or 77% of it's original rate. There could be
	// quite a few reasons for this discrepancy, framerate-tied
	// weapon firing being one of them (the same reason why in
	// World at War, the PPSh-41 is completely unaffected by
	// Double Tap), but technically this IS the correct-and
	// -reproducible factor due to whatever went wrong there.
	if (self.perks & P_DOUBLE) {
		delay *= 0.77;
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
		Set_W_Frame (startframe, endframe, delay, 0, FIRE, WeaponCore_CheckForReload, modelname, FALSE, side);
	}


	sound (self, CHAN_WEAPON, soundname, 1, ATTN_NORM);

	if (side == S_RIGHT) {
		self.weapons[0].weapon_magazine = self.weapons[0].weapon_magazine - 1;
		self.fire_delay = delay + time;
	} else {
		self.weapons[0].weapon_magazine_left = self.weapons[0].weapon_magazine_left - 1;
		self.fire_delay2 = delay + time;
	}

	if (IsPapWeapon(self.weapon) && !WepDef_DoesNotPlayUpgradedSound(self.weapon)) {
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

#endif // FTE

}

//
// WeaponCore_Melee()
// Performs the melee action, intelligent
// against type of weaponry and lunge velocity
// applied.
//

#define WEAPONCORE_MELEE_LUNGEMIN	40	// Minimum amount of units away before lunge should be triggered.

void() WeaponCore_Melee =
{
	// Do not trigger if we're Aiming down the Sight, or
	// already melee-ing, or doing some other action.
	if (self.knife_delay > time || self.new_anim_stop ||
	self.new_anim2_stop || self.zoom)
		return;

	// Perform the third person animation if standing
	if (self.stance == PLAYER_STANCE_STAND)
		PAnim_Melee();

	// Hide crosshair -- irrelevant during melee
	W_HideCrosshair(self);

	// Stop sprinting if we are
	W_SprintStop();

	vector applied_velocity = '0 0 0'; // The lunge velocity we intend to apply to the player.
	float melee_range = WepDef_GetWeaponMeleeRange(self.weapon); // Returns the range of the traceline to perform for hit detection.
	float did_lunge = false;

	// Perform the traceline
	makevectors(self.v_angle);
	vector trace_source = self.origin + self.view_ofs;
	traceline(trace_source, trace_source + v_forward * melee_range, 0, self);

	if (trace_endpos_z - trace_source_z <= 15) {
		// Check if this is a Zombie limb, set to the body if so
		if (trace_ent.owner.head == trace_ent || trace_ent.owner.larm == trace_ent || trace_ent.owner.rarm == trace_ent)
			trace_ent = trace_ent.owner;

		// Target does not take damage -- no need to go any further
		if (!trace_ent.takedamage && !(trace_ent.flags & FL_CLIENT)) {
			// Hit a solid surface, so play hard melee sound.
			if (trace_fraction < 1.0)
				sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife_hit.wav", 1, ATTN_NORM);
			// Dead air, swing!
			else
				sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife.wav", 1, ATTN_NORM);
		} else {
			// AI has a more involved routine than other entities
			if (trace_ent.aistatus == "1") {
				// Play a flesh-y impact sound, spawn blood.
				sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife_hitbod.wav", 1, ATTN_NORM);
	 			SpawnBlood(trace_source + (v_forward * 20), trace_source + (v_forward * 20), 50);

				// Calculate distance to use for the Lunge velocity
				float lunge_factor = vlen(trace_source - (trace_endpos - v_forward*4));

				// Perform lunge, exclusive to AI.
				if (lunge_factor > WEAPONCORE_MELEE_LUNGEMIN) {
					did_lunge = true;
					applied_velocity = v_forward * melee_range * 6;
					applied_velocity_z = 0;
				}
			} 
			// Some other ent (player, button, etc.)
			else {
				// Never lunge in this circumstance.
				did_lunge = false;

				// Is this a player? Play the body hit sound and spawn blood, otherwise, solid swing.
				if (trace_ent.flags & FL_CLIENT) {
					sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife_hitbod.wav", 1, ATTN_NORM);
					SpawnBlood(trace_source + (v_forward * 20), trace_source + (v_forward * 20), 50);
				} else {
					sound (self, CHAN_WEAPON, "sounds/weapons/knife/knife_hit.wav", 1, ATTN_NORM);
				}
			}

			// Apply damage to the entity.
			if (trace_ent.takedamage) {
				float melee_damage = WepDef_CalculateMeleeDamage(self.weapon, self.bowie);
				DamageHandler (trace_ent, self, melee_damage, S_KNIFE);
			}
		}
	}

	// Grab animation stats for our melee weapon.
	float start_frame = WepDef_GetMeleeFirstFrame(self.weapon, did_lunge, self.bowie);
	float end_frame = WepDef_GetMeleeLastFrame(self.weapon, did_lunge, self.bowie);
	float anim_duration = WepDef_GetMeleeAnimDuration(self.weapon, did_lunge, self.bowie);
	string model_path = WepDef_GetMeleeModel(self.weapon, self.bowie);

	// Ensure we play the Take Out animation if the melee model is not our active weapon
	void() end_func;
	if (!WepDef_IsMeleeWeapon(self.weapon)) {
		end_func = W_PlayTakeOut;
	} else {
		end_func = __NULL__;
	}

	// Apply camera punch, and begin playback.
	self.punchangle_x = -5;
	self.punchangle_y = -10;
	Set_W_Frame (start_frame, end_frame, anim_duration, 0, KNIFE, end_func, model_path, false, S_RIGHT);
	self.knife_delay = anim_duration + time;

	// Now apply the lunge velocity, but only if we're Standing.
	if (self.stance == PLAYER_STANCE_STAND && did_lunge)
		self.velocity = applied_velocity;
}

/******************************
* W_Grenade                   *
******************************/

void() switch_nade = 
{ 
	if (self.downed || self.isBuying || !(self.grenades & 2) || self.grenade_delay > time)
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
	// Do one (1) damage on monster contact, to kill when Insta-Kill is active.
	if (other.flags & FL_MONSTER)
		DamageHandler(other, self.owner, 1, S_NORMAL);

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
	W_SprintStop();

	W_HideCrosshair(self);
	Set_W_Frame (0, 2, 0.6, 0, GRENADE, checkHold, "models/weapons/grenade/v_grenade.mdl", true, S_RIGHT);
	sound (self, CHAN_WEAPON, "sounds/weapons/grenade/prime.wav", 1, ATTN_NORM);	
	self.primary_grenades -= 1;
	self.reload_delay2 = self.fire_delay2 = self.throw_delay = self.reload_delay = self.fire_delay = time + 6;
	self.grenade_delay = time + 5;
} 

void(float wepnum) CheckButton = {
	W_PutOut();
}

void() Change_Stance = {

	if (self.downed || !(self.flags & FL_ONGROUND) || self.changestance == true || self.new_ofs_z != self.view_ofs_z)
		return;

	switch(self.stance) {
		case PLAYER_STANCE_STAND: 
			Player_SetStance(self, PLAYER_STANCE_CROUCH, true);
			break;
		case 1:
			// Prohibit Proning if Drinking a Perk-A-Cola, just stand.
			if (self.isBuying) {
				Player_SetStance(self, PLAYER_STANCE_STAND, true);
			} 
			// Stance flag isn't set, so go Prone.
			else if (!self.stancereset) {
				Player_SetStance(self, PLAYER_STANCE_PRONE, true);
			} 
			// Stance flag IS set, so stand if applicable.
			else if (Player_CanStandHere(self)) {
				Player_SetStance(self, PLAYER_STANCE_STAND, true);
				self.stancereset = false;
			} 
			// There's no room to stand, just prone again.
			else {
				Player_SetStance(self, PLAYER_STANCE_PRONE, true);
			}
			break;
		case 0:
			Player_SetStance(self, PLAYER_STANCE_CROUCH, true);
			self.stancereset = true;
			break;
		default: break;
	}

}

void() dolphin_dive =		//naievil
{    
	if (self.stance != 2)
		return;
	if ((map_compatibility_mode == MAP_COMPAT_BETA && self.view_ofs_z != VIEW_OFS_QK[2]) ||
	(!map_compatibility_mode && self.view_ofs_z != VIEW_OFS_HL[2]))
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
	Player_SetStance(self, PLAYER_STANCE_PRONE, false);
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
			if (cheats_have_been_activated) {
				Player_AddScore(self, 10000, true);
				rounds += 4;
			}
			break;
		case 23:

#ifdef FTE

			if (!checkMovement(forward))
				return;

#endif // FTE

			if (self.dive || self.downed || !Player_CanStandHere(self))
				return;

			Player_SetStance(self, PLAYER_STANCE_STAND, false);
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
		case 26:
			self.ads_release = !self.ads_release;
			self.has_ads_toggle = true;
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
		case 100:
			cvar_set("waypoint_mode", "1");
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

//
// WeaponCore_PowerUpBlink(blink_delay, powerup_endtime)
// Determines whether or not the Power-Up HUD icon should be
// visible.
// FIXME: This should be moved out of weapon_core, ideally.
//
float(__inout float blink_delay, float powerup_endtime) WeaponCore_PowerUpBlink =
{
	// If the Power-Up is still active
	if (powerup_endtime >= time) {
		float should_be_visible = false;

		// If there's less than five seconds remaining,
		// blink every 0.2s.
		if (powerup_endtime < time + 5) {
			if (blink_delay < time - 0.2)
				blink_delay = time + 0.2;
		}
		// If there's less than 10 seconds remaining,
		// blink every 0.4s.
		else if (powerup_endtime < time + 10) {
			if (blink_delay < time - 0.4)
				blink_delay = time + 0.4;
		}

		if (blink_delay < time)
			return true;
	}

	// End of the line, return false.
	return false;
};

void() CheckPlayer = 
{
	// Update Power-Up blinking
	self.insta_icon = WeaponCore_PowerUpBlink(insta_blink, instakill_finished);
	self.x2_icon = WeaponCore_PowerUpBlink(x2_blink, x2_finished);

	CheckRevive(self);

	if (self.sprinting) {
		makevectors(self.angles);

		// We should stop sprinting if we are falling, technically
		// CoD continues the animation but applies a move speed
		// penalty, however, that makes no sense! This also applies
		// as a better implementation to stop sprinting while jumping.
		if (fabs(self.velocity_z) >= 5)
			W_SprintStop();
		// Otherwise, also stop sprinting if we are moving at a base below
		// predicted for our slowest possible weapon. This removes the need
		// for an engine-side hack for toggle sprinting turning off when
		// you're applying less pressure to the analog stick.
		else if (vlen(self.velocity) <= 130 && self.sprint_delay <= time + 0.75)
			W_SprintStop();
		// Another sprinting caveat -- if we are moving a considerabe distance
		// horizontally, much more than reasonable, it is very obviously impossible
		// to actually sprint.
		else if (fabs(self.velocity * v_right) >= fabs(self.velocity * v_forward) * 0.75)
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


				#ifdef FTE

				// FTE-Specific: Broadcast to the player they're being revived.
				FTE_BroadcastMessage(ent, CSQC_BROADCAST_BEINGREVIVED, 2, self.playernum);

				// FTE-Specific: Broadcast to client that they are reviving the downed player.
				FTE_BroadcastMessage(self, CSQC_BROADCAST_REVIVINGPLAYER, 2, ent.playernum);

				#endif // FTE

				ent.speed_penalty = 0.01;
				ent.speed_penalty_time = time + 100;
				ent.beingrevived = true;
				ent.firer = self;
				
				if (!self.reviving) {
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
					Player_AddScore(self, ent.requirespower, false);


					#ifdef FTE

					// FTE-Specific: End Broadcast Messages on both ends
					FTE_BroadcastMessage(ent, CSQC_BROADCAST_NONE, 0, self.playernum);
					FTE_BroadcastMessage(self, CSQC_BROADCAST_NONE, 0, ent.playernum);

					#endif // FTE

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

				#ifdef FTE

				// FTE-Specific: End Broadcast Messages on both ends
				FTE_BroadcastMessage(ent, CSQC_BROADCAST_NONE, 0, self.playernum);
				FTE_BroadcastMessage(self, CSQC_BROADCAST_NONE, 0, ent.playernum);

				#endif // FTE

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

//
// WeaponCore_UpdateRecoilAndSpread()
// Somewhat-intelligent serverside Weapon Recoil
// update system that takes into account velocity
// and how long the weapon has been fired.
//
void() WeaponCore_UpdateRecoilAndSpread =
{
	// Moving? Our weapon spread should be the maximum.
	if (self.velocity)
		self.cur_spread = WepDef_WeaponMaxSpread(self.weapon, self.stance);

	// Slowly increase our spread based on how long the weapon
	// has been fired.
	else if (self.recoil_delay > time && self.recoil_delay)
    {
        self.cur_spread = self.cur_spread + 10;
		if (self.cur_spread >= WepDef_WeaponMaxSpread(self.weapon, self.stance))
			self.cur_spread = WepDef_WeaponMaxSpread(self.weapon, self.stance);
    }
	// Diminish spread over time as recoil decreases.
    else if (self.recoil_delay < time && self.recoil_delay)
    {
        self.cur_spread = self.cur_spread - 4;
		if (self.cur_spread <= 0)
		{
			self.cur_spread = 0;
			self.recoil_delay = 0;
		}
    }
}

//
// WeaponCore_UpdateViewModels()
// Updates animation playback for View models,
// if applicable.
//
void() WeaponCore_UpdateViewModels =
{
	// If the weapon has a "Hold Fire" frame (e.g., M2 Flamethrower)
	// And it's actively firing, we shouldn't force an update.
	float hold_fire_frame = GetFrame(self.weapon, FIRE_HOLD); // Avoid iterating through long switch twice.
	if (self.weaponmodel == GetWeaponModel(self.weapon, false) && 
	hold_fire_frame != 0 && self.weaponframe == hold_fire_frame)
		return;

	// Checks passed -- update view model animations.
	W_Frame_Update();
	W2_Frame_Update();
};

//
// WeaponCore_ResetHoldFireWeapons()
// Allows for a "Hold Fire" weapon to reach its base
// position again.
//
void() WeaponCore_ResetHoldFireWeapon =
{
	float hold_fire_frame = GetFrame(self.weapon, FIRE_HOLD); // Avoid iterating through long switch twice.
	if (hold_fire_frame != 0 && self.weaponframe == hold_fire_frame && 
	self.weaponmodel == GetWeaponModel(self.weapon, 0)) {
		self.weaponframe = 0;
	}
};

//
// WeaponCore_UpdateSniperScope
// If eligible, reports to the client via
// the .zoom stat to draw the Sniper Scope
// HUD graphic.
//
void() WeaponCore_UpdateSniperScope =
{
	if ((self.scopetime < time) && self.scopetime) {
		self.scopetime = 0;
		self.zoom = 2;
		self.weapon2model = "";
		self.weaponmodel = "";
	}
};

//
// WeaponCore_UpdateWeaponStats()
// Specific weapon fields are used to network weapon
// stats to the client, since arrays and structs
// can't be used for this task. This is where we store
// them for pass-off.
//
inline void() WeaponCore_UpdateWeaponStats =
{
	self.currentammo = self.weapons[0].weapon_reserve;			// Weapon Reserve Ammo
	self.currentmag = self.weapons[0].weapon_magazine;			// Weapon Magazine
	self.currentmag2 = self.weapons[0].weapon_magazine_left;	// Left-side Weapon Magazine

	// FTE-specific - update weapon2modelindex to simplify protocol
	// and data exchange.
#ifdef FTE

	self.weapon2modelindex = getmodelindex(self.weapon2model);

#endif // FTE
};

//
// WeaponCore_FireButtonPressed()
// Executed when WeaponCore_ClientLogic
// detects that button0 has been pressed.
//
void() WeaponCore_FireButtonPressed =
{
	// With keyboard/mouse input, we want akimbo weapons to actually correspond
	// to which click of the mouse you've provided, which is different behavior
	// to single-hand weapons, where left click fires its right-side. (Hooray
	// for ternaries!).
#ifdef FTE

	(IsDualWeapon(self.weapon)) ? W_Fire(S_LEFT) : W_Fire(S_RIGHT);

#else

	// Always fire right-side elsewhere.
	W_Fire(S_RIGHT);

#endif // FTE
};

//
// WeaponCore_FireButtonReleased()
// Executed when WeaponCore_ClientLogic
// detects that button0 has been released.
//
void() WeaponCore_FireButtonReleased =
{
	// Allow semi-automatic fire again -- see WeaponCore_FireButtonPressed() for platform discrepancy.
#ifdef FTE

	(IsDualWeapon(self.weapon)) ? self.semi_actions &= ~SEMIACTION_FIRE_LEFT : self.semi_actions &= ~SEMIACTION_FIRE_RIGHT;

#else

	// Always allow right-side elsewhere.
	self.semi_actions &= ~SEMIACTION_FIRE_RIGHT;

#endif // FTE

	// Make sure Hold-special weapons are allowed
	// back to base-frame.
	WeaponCore_ResetHoldFireWeapon();
};

//
// WeaponCore_AimButtonPressed()
// Executed when WeaponCore_ClientLogic
// detects that button8 has been pressed.
//
void() WeaponCore_AimButtonPressed =
{
	// If we're holding an akimbo weapon, we actually want to
	// fire our secondary as opposed to Aiming down the Sight.
	if (IsDualWeapon(self.weapon)) {
#ifdef FTE

		W_Fire(S_RIGHT);

#else

		W_Fire(S_LEFT);

#endif // FTE

	} 
	// Don't permit Aiming down the Sights if the client
	// is moving and Prone.
	else if (!self.ads_release) {
		W_AimIn();
		self.has_ads_toggle = false;
	}
};

//
// WeaponCore_AimButtonReleased()
// Executed when WeaponCore_ClientLogic
// detects that button8 has been released.
//
void() WeaponCore_AimButtonReleased =
{
	// Lower weapon if Aiming down the Sight.
	if (!self.ads_release)
		W_AimOut();

	// Allow akimbo semi-automatic weapons to fire again.
	if (IsDualWeapon(self.weapon)) {

#ifdef FTE

		self.semi_actions &= ~SEMIACTION_FIRE_RIGHT;

#else

		self.semi_actions &= ~SEMIACTION_FIRE_LEFT;

#endif // FTE
	}
};

//
// WeaponCore_GrenadeButtonPressed()
// Executed when WeaponCore_ClientLogic
// detects that button3 has been pressed.
//
void() WeaponCore_GrenadeButtonPressed =
{
	// Leave if there is already a Grenade action
	// being performed.
	if (self.grenade_delay > time || (self.semi_actions & SEMIACTION_GRENADE))
		return;

	if (self.pri_grenade_state == 0)
		W_Grenade();
    else
        W_PrimeBetty();

	self.semi_actions |= SEMIACTION_GRENADE;
};

//
// WeaponCore_MeleeButtonPressed()
// Executed when WeaponCore_ClientLogic
// detects that button6 has been pressed.
//
void() WeaponCore_MeleeButtonPressed =
{
	// On platforms with limited control schemes, 
	// performing a melee-action while sprinting
	// triggers Dive-to-Prone.
#ifndef FTE

	if (self.sprinting) {
		dolphin_dive();
		return;
	}

#endif // FTE

	if (self.semi_actions & SEMIACTION_MELEE)
		return;

#ifdef FTE

	// On FTE, we should resort to standard CoD
	// behavior where pressing melee should cancel
	// sprinting.
	W_SprintStop();

#endif // FTE

	WeaponCore_Melee();
	self.semi_actions |= SEMIACTION_MELEE;
};

//
// WeaponCore_ClientLogic()
// Executes every frame on clients, dictates
// weapon behaviors such as receiving inputs
// or updating animation playback.
//
void() WeaponCore_ClientLogic =
{
	// Make sure information about our weapon stats
	// are being networked to the client.
	WeaponCore_UpdateWeaponStats();

	// Viewmodel animation playback.
	WeaponCore_UpdateViewModels();

	// Dynamic Weapon Recoil and Spread adjustment.
	WeaponCore_UpdateRecoilAndSpread();

	// Register changes to client's .impulse
	Impulse_Functions();

	// Tells client to draw Sniper HUD element.
	WeaponCore_UpdateSniperScope();

	// Call to the client to do some update
	// checks specific to them.
	CheckPlayer();

#ifdef FTE

	// FTE-only: custom Punchangle Interpolation Implementation
	FTE_InterpolatePunchAngle(self);

	// FTE-only: update dynamic FOV
	FTE_UpdateDynamicFOV(self);

#endif // FTE

	// If the client is Aiming down the Sight while prone and
	// moving, force them to stop
	if (self.stance == PLAYER_STANCE_PRONE && self.velocity && self.zoom) {
		W_AimOut();
	}

	// Fire Button Pressed
	if (self.button0) {
		WeaponCore_FireButtonPressed();
	}
	// Fire Button Released
	else {
		WeaponCore_FireButtonReleased();
	}

	// If Client has ADS bound to impulse 26 (toggle),
	// check if the flag is set and W_AimIn()
	if (self.ads_release)
		W_AimIn();
	else if (self.has_ads_toggle)
		W_AimOut();

	// ADS Button Pressed
	if (self.button8) {
		WeaponCore_AimButtonPressed();
	}
	// ADS Button Released
	else {
		WeaponCore_AimButtonReleased();
	}

	// Use Button Released
	if (!self.button7) {
		// Allow use to be triggered again.
		self.semi_actions &= ~SEMIACTION_USE;
	}

	// Switch Button Pressed
	if (self.button4) {
		W_PutOut();
	} else {
		// Allow Switch to be pressed again.
		self.semi_actions &= ~SEMIACTION_WEAPONSWAP;
	}

	// Grenade Button Pressed
	if (self.button3) {
		WeaponCore_GrenadeButtonPressed();
	} else {
		// Allow Grenade to be pressed again.
		self.semi_actions &= ~SEMIACTION_GRENADE;
	}

	// Reload Button Pressed
	if (self.button5) {
		W_Reload(S_BOTH);
	}

	// Melee Button Pressed
	if (self.button6) {
		WeaponCore_MeleeButtonPressed();
	} 
	// Melee Button Released
	else {
		// Allow Melee to be pressed again
		self.semi_actions &= ~SEMIACTION_MELEE;
	}
};