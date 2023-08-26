/*
	server/clientfuncs.qc

	used for any sort of down, hit, etc that the player or entity 
	experiences

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
void (float achievement_id, optional entity who) GiveAchievement;

void() Barrel_Hit;
void() teddy_react;

void() EndGame_Restart = 
{
	localcmd("restart");
}

// Fade to black function, creates another think for restart
void() EndGame_FadePrompt =
{
	PromptLevelChange(time + 6, 2, self);

#ifdef FTE

	self.think = EndGame_Restart;

#else

	self.think = Soft_Restart;

#endif // FTE

	self.nextthink = time + 5;
}

//Actual endgame function, all zombies die, music plays
void() EndGame =
{
	local entity oldself;
	local entity who;

	self.health = 0;
	self.origin = '0 0 0';
	setorigin (self, self.origin);
	self.velocity = '0 0 0';
	sound (self, CHAN_AUTO, "sounds/music/end.wav", 1, ATTN_NORM);

	oldself = self;
	
	who = find(world,classname,"ai_zombie");
	while(who != world)
	{
		if(who.health)
		{
			self = who;
			self.th_die();
			self = oldself;
		}
		
		who = find(who,classname,"ai_zombie");
	}
	
	self.think = EndGame_FadePrompt;
	self.nextthink = time + 33;
}

// when dead and other players exist and are alive, throw user into spectate mode
void() startspectate =
{
	if (!self.downed)
		return;
		
	if (self.beingrevived)
	{
		self.think = startspectate;
		self.nextthink = time + 0.1;
		return;
	}
	
	self.downedloop = 0;
	self.beingrevived = false;
	self.model = "";
	setmodel(self, self.model);
	self.health = 100;
	self.weaponmodel = "";
	self.weapon2model = "";
	self.downed = 0;
	self.frame = 0;

	UpdateVmodel(self.weaponmodel, GetWepSkin(self.weapon));
	UpdateV2model(self.weapon2model, GetWepSkin(self.weapon));
	
	SpectatorSpawn();
}

// searches for players that are alive given which clients have which playernumbers
//      Returns 1 if there IS someone in the world that's not downed
float() PollPlayersAlive = 
{
	float i, gotalive;
	entity playerent;
	
	gotalive = 0;
	
	for (i = 1; i <= 4; i++)
	{
		playerent = findfloat(world, playernum, i);
		
		if (playerent) {
			if (!playerent.downed && !playerent.isspec) {
				gotalive = 1;
				break;
			}
		}
	}
	
	return gotalive;
}

// Endgamesetup -- think function for setting up the death of everyone
void() EndGameSetup =
{
	game_over = true;
	self.health = 10;
	self.think = EndGame;
	self.nextthink = time + 5;
	self.weapon = 0;
	self.currentammo = 0;
	self.currentmag = 0;
	self.weaponmodel = "";
	self.weapon2model = "";
	self.animend = SUB_Null;
	self.perks = 0;
	self.isspec = true;
	SetPerk(self, self.perks);
	SwitchWeapon(0);	
	addmoney(self, -self.points, 0);
	addmoney(self, self.score, 0);	
    return;
}

// rec_downed is used as a recursive loop where we consistently check to see if ALL players are downed
//    if they aren't dead, we keep looping until our OWN death (45 seconds, so 300 loops)
void() rec_downed = 
{
	self.downedloop++;
	if (self.downedloop >= 300) {
		DisableReviveIcon(self.electro_targeted);
		startspectate();
		return;
	}
	
	float gotalive = PollPlayersAlive();
	
	if (!gotalive && !self.progress_bar) {
		EndGameSetup();
		return;
	}
	
	self.think = rec_downed;
	self.nextthink = time + 0.1;
}

void() GetDown =
{
	// 'Pro Gamer Move' achievement.
	if (rounds <= 1 && self.currentmag == 0 && 
	self.currentmag2 == 0 && self.currentammo == 0 && 
	self.secondarymag == 0 && self.secondarymag2 == 0 && 
	self.secondaryammo == 0) {
		GiveAchievement(9, self);
	}

	// Play Last Stand Animation
	PAnim_GetDown1();

	// Force the player to prone.
	if (self.stance == 2) self.new_ofs_z = self.view_ofs_z - 42;
	if (self.stance == 1) self.new_ofs_z = self.view_ofs_z - 24;
	self.stance = 0;

	// Get Rid of Mule Kick Weapon (FIXME -- this just obliterates the third slot)
	self.thirdweapon = 0;

	// Calculate the loss in points, take away points from downed Player.
	float point_difference;
	point_difference = self.points;
	point_difference -= 10*rint((self.points*0.95)/10);
	addmoney(self, point_difference * -1, false);
	self.requirespower = point_difference;

	// Broadcast that the player has downed.
	BroadcastMessage(time + 3, 2, self.netname);

	// Reset state
	self.velocity = self.zoom = 0;
	self.downed = true;
	self.dive_delay = 0;
	self.movetype = MOVETYPE_NONE;

	float players_still_alive = PollPlayersAlive();

	if ((coop && !players_still_alive) || (!coop && !(self.perks & P_REVIVE))) {
		EndGameSetup();
		return;
	} else {
		self.health = 19; 
	}

	// Initiate Self-Revive on Solo
	if ((self.perks & P_REVIVE) && !coop) {	
		self.progress_bar = 10 + time;     
		self.progress_bar_time = 10;
		self.progress_bar_percent = 1;
	}

	// Take away weapons and Perks
	self.perks = 0;
	SetPerk(self, self.perks);
	self.weaponbk = self.weapon;
	self.currentammobk = self.currentammo;
	self.currentmagbk = self.currentmag;
	self.currentmagbk2 = self.currentmag2;

	// Reset Juggernog health
	self.max_health = self.health = PLAYER_START_HEALTH;

	if(Weapon_PlayerHasWeapon(self, W_BIATCH, false) || 
	Weapon_PlayerHasWeapon(self, W_RAY, true) ||
	Weapon_PlayerHasWeapon(self, W_357, true)) {
		float weapon_slot;
		float total_ammo;
		total_ammo = 0;

		weapon_slot = Weapon_PlayerHasWeapon(self, W_RAY, true);
		if (weapon_slot == 0) weapon_slot = Weapon_PlayerHasWeapon(self, W_BIATCH, false);
		if (weapon_slot == 0) weapon_slot = Weapon_PlayerHasWeapon(self, W_357, true);

		switch(weapon_slot) {
			case 1:
				total_ammo = self.currentmag + self.currentmag2 + self.currentammo;
				break;
			case 2:
				total_ammo = self.secondarymag + self.secondarymag2 + self.secondaryammo;
				self.weapon = self.secondaryweapon;
				break;
		}

		// If it's greater than the mag size, we can fill the magazine.
		if (total_ammo > getWeaponMag(self.weapon)) {
			self.currentmag = getWeaponMag(self.weapon);

			// subtract it from the total ammo
			total_ammo -= self.currentmag;
		} else {
			self.currentmag = total_ammo;
			total_ammo = 0;
		}

		// Check for dual wield mag too
		if (IsDualWeapon(self.weapon)) {
			if (total_ammo > getWeaponMag(self.weapon)) {
				self.currentmag2 = getWeaponMag(self.weapon);

				// subtract it from the total ammo
				total_ammo -= self.currentmag2;
			} else {
				self.currentmag2 = total_ammo;
				total_ammo = 0;
			}
		}

		// Ray Gun has a special case where we DON'T fill its reserve
		if (self.weapon != W_RAY && self.weapon != W_PORTER) {
			// Now see if the reserve ammo is more than max downed capacity
			if (total_ammo > getWeaponMag(self.weapon)*2) {
				self.currentammo = getWeaponMag(self.weapon)*2;
			} else {
				// It's not so just fill it
				self.currentammo = total_ammo;
			}
		} else {
			self.currentammo = 0;
		}
	} else {
		if (!coop) {
			self.weapon = W_BIATCH;
			self.currentammo = 12;
			self.currentmag = self.currentmag2 = 6;
		} else {
			self.weapon = W_COLT;
			self.currentmag = 8;
			self.currentammo = 16;
		}
	}

	// Play Switch Animation
	self.weaponmodel = GetWeaponModel(self.weapon, 0);
	SwitchWeapon(self.weapon);
	
	float startframe = GetFrame(self.weapon,TAKE_OUT_START);
	float endframe = GetFrame(self.weapon,TAKE_OUT_END);
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, self.weaponmodel, false, S_BOTH);

	// Spawn Revive Sprite in Co-Op
	if (coop) {
		EnableReviveIcon(revive_index, self.origin + VEC_VIEW_OFS);
		self.electro_targeted = revive_index;
		revive_index++;
	}

	self.think = rec_downed;
	self.nextthink = time + 0.1;
}

void () GetUp =
{
	local string modelname;
	float startframe;
	float endframe;
	
	playgetup();				// animation
	
	self.new_ofs_z = self.view_ofs_z + 42;
	self.stance = 2;
	self.health = 100;
	self.downedloop = 0;		// used for death timing vs endgame
	self.downed = 0;
	self.classname = "player";

	// Take away the ammo that was fired while in last stand.
	if (self.weapon != W_COLT) {
		if (self.weapon == self.weaponbk) {
			self.currentammobk -= self.teslacount;

			// Take from the mag if the reserve is empty now
			if (self.currentammobk < 0) {
				self.currentmagbk += self.currentammobk;
				self.currentammobk = 0;
			}	
		} else if (self.weapon == self.secondaryweapon) {
			self.secondaryammo -= self.teslacount;

			// Take from the mag if the reserve is empty now
			if (self.secondaryammo < 0) {
				self.secondarymag += self.secondaryammo;
				self.secondaryammo = 0;
			}
		}
	}
	
	self.teslacount = 0;

	if (!coop) {
		addmoney(self, self.requirespower, false);
	}

	if (self.weaponbk)
	{
		self.weapon = self.weaponbk;
		self.currentammo = self.currentammobk;
		self.currentmag = self.currentmagbk;
		self.currentmag2 = self.currentmagbk2;
	}	
	modelname = GetWeaponModel(self.weapon, 0);
	self.weaponmodel = modelname;
	SwitchWeapon(self.weapon);
	self.weapon2model = GetWeapon2Model(self.weapon);
	self.movetype = MOVETYPE_WALK;
  
  	startframe = GetFrame(self.weapon,TAKE_OUT_START);
	endframe = GetFrame(self.weapon,TAKE_OUT_END);
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);
	
};

// poll checking whether to see if our revive invoke is active
void(entity ent) CheckRevive =
{
	if (self.invoke_revive) {
		GetUp();
		DisableReviveIcon(self.electro_targeted);
		revive_index--;
		self.invoke_revive = 0;
		self.firer = world;
	}
}

void(entity attacker, float d_style) DieHandler =
{
    float t;

    t = random();

    if (self.classname == "ai_zombie" || self.classname == "ai_dog") {
        self.th_die();
    }

    if (attacker.classname == "player") {
		attacker.kills++;
		if (d_style == S_HEADSHOT) {
			addmoney(attacker, 100, true);
			attacker.headshots++;
		} else if (d_style == S_NORMAL) {
            addmoney(attacker, 60, true);
        }
		else if (d_style == S_KNIFE){
			addmoney(attacker, 130, true);
		} else if (d_style == S_TESLA) {
			addmoney(attacker, 50, true);
		}
    }
}

void(entity victim,entity attacker, float damage, float d_style) DamageHandler = {
	// don't do any attacking during nuke delay
	if (d_style == S_ZOMBIE && nuke_powerup_active > time)
		return;

	entity old_self;
	if (victim.classname == "ai_zombie" || victim.classname == "ai_dog") {

		if (attacker.classname == "player" && (victim.health - damage)> 0) {
			addmoney(attacker, 10, 1);
        }

		victim.health = victim.health - damage;

		if (d_style == S_EXPLOSIVE) {
			if (victim.health < z_health*0.5)
			{
				if (victim.crawling != TRUE && !(victim.health <= 0) && crawler_num < 5 && victim.classname != "ai_dog")
				{
					makeCrawler(victim);
					GiveAchievement(3, attacker);
				}
				else
				{
					if (attacker.classname == "player" && (victim.health - damage) > 0)
						addmoney(attacker, 10, 1);
				}
			}
			// MOTO - explosives seem to work fine without, but with will cause counter and QC errors..
			//else
			//	victim.th_die();	
				
			if (victim.health <= 0)
				addmoney(attacker, 60, 1);
		}

		if (victim.health <= 0 || instakill_finished) {
			old_self = self;
			self = victim;
			DieHandler(attacker, d_style);
			self = old_self;
		}
	} else if (victim.classname == "player" && !victim.downed) {

		if (victim.flags & FL_GODMODE) {
			return;
		}

		// Abstinence Program
		victim.ach_tracker_abst = 1;
		
		victim.health -= damage;

		// Determine how long to wait before regenerating based on our Health ratio
		float ratio = victim.health / victim.max_health;

		// Badly hurt = longer delay.
		if (ratio <= 0.2) {
			victim.health_delay = time + 5;

			// We're really low, so let's regen REALLY slow.
			victim.health_was_very_low = true;
		} else {
			victim.health_delay = time + 2.4;
		}

		// shake the camera on impact
		vector distance;
		distance = attacker.angles - victim.angles;

		// just to prevent radical punchangles
		while(distance_x > 10 || distance_x < -10) {
			distance_x /= 2;
		}
		while(distance_y > 10 || distance_y < -10) {
			distance_y /= 2;
		}

		// apply
		victim.punchangle_x = distance_x;
		victim.punchangle_y = distance_y;

		// Play pain noise if this isn't done by an electric barrier.
		if (d_style != S_ZAPPER)
			sound (self, CHAN_AUTO, "sounds/player/pain4.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_AUTO, "sounds/machines/elec_shock.wav", 1, ATTN_NORM);

		if (victim.sprinting) {
			old_self = self;
			self = victim;
			W_SprintStop();
			self = old_self;
		}

		victim.sprint_delay = time + 0.75;

		// Was 20 for.. some reason.
		if (victim.health <= 1)
		{
			old_self = self;
			self = victim;
			GetDown();
			self = old_self;
		}
	}
}

/*
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
*/
float(entity targ, entity inflictor) CanDamage =
{
	if (targ.flags == FL_GODMODE)
    return FALSE;
// bmodels need special checking because their origin is 0,0,0
	if (targ.movetype == MOVETYPE_PUSH)
	{
		traceline(inflictor.origin, 0.5 * (targ.absmin + targ.absmax), TRUE, self);
		if (trace_fraction == 1)
			return TRUE;
		if (trace_ent == targ)
			return TRUE;
		return FALSE;
	}
    
	traceline(inflictor.origin, targ.origin, TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '15 15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 -15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '-15 15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;
	traceline(inflictor.origin, targ.origin + '15 -15 0', TRUE, self);
	if (trace_fraction == 1)
		return TRUE;

	return FALSE;
};

void(entity inflictor, entity attacker, float damage2, float mindamage, float radius) DamgageExplode =
{
	float 	final_damage;
	entity	ent;

	float 	multi, r;
	ent = findradius(inflictor.origin, radius);
	
	while (ent != world)
	{
		if(ent.classname == "player" && ent == attacker) // we don't want OUR explosives to harm other players..
		{
			if (ent.perks & P_FLOP)
				final_damage = 0;
			else
			{
				final_damage = (radius - vlen(inflictor.origin - ent.origin))*1.5;

				if(final_damage < 0) 
				{
					ent = ent.chain;
					continue;
				}
			
				if (final_damage > radius * 0.75)
					final_damage = 100;
			
				if (final_damage < other.health)
				{
					addmoney(self, 10, 0);
				}
				else if (final_damage > other.health)
				{
					addmoney(self, 60, 0);
				}
				else
				{
					final_damage /= radius;
					final_damage *= 60;
				}
				DamageHandler (ent, ent, final_damage, S_EXPLOSIVE);

				// shake the camera on impact
				vector distance;
				distance = inflictor.angles - ent.angles;

				// just to prevent radical punchangles
				while(distance_x > 10 || distance_x < -10) {
					distance_x /= 2;
				}
				while(distance_y > 10 || distance_y < -10) {
					distance_y /= 2;
				}

				// apply
				ent.punchangle_x = distance_x;
				ent.punchangle_y = distance_y;
			}
		}
		else if (ent.classname == "explosive_barrel")
		{
			final_damage = radius - vlen(inflictor.origin - ent.origin);
			final_damage *= 4;

			if (final_damage < 0) 
			{
				ent = ent.chain;
				continue;
			}

			ent.health -= final_damage;

			entity oldself;
			oldself  = self;
			self = ent;
			Barrel_Hit();
			self = oldself;
		}
		else if (ent.classname == "teddy_spawn")
		{
			entity oldself2;
			oldself2 = self;
			self = ent;
			teddy_react();
			self = oldself2;
		}
		else if (ent.takedamage && ent.classname != "ai_zombie_head" && ent.classname != "ai_zombie_larm" && ent.classname != "ai_zombie_rarm")
		{			
			// verify we aren't doin anything with a bmodel
			if (ent.solid == SOLID_BSP || ent.movetype == MOVETYPE_PUSH)
				return;

			if (mapname == "ndu" && ent.classname == "ai_zombie" && inflictor.classname == "explosive_barrel") {
				ach_tracker_barr++;

				if (ach_tracker_barr >= 15) 
				{
					GiveAchievement(13);
				}
			}

			r = rounds;
			multi = 1.07;
			while(r > 0)
			{
				multi *= 1.05;
				r --;
			}
			
			if (mindamage == 75) 
			{
				final_damage = (200 * multi) + 185;
			}
			else 
			{
				final_damage = (mindamage + damage2)/2;
			}
			
			if (final_damage > 0)
			{
				/* ndaekill = true; */
				if (CanDamage (ent, inflictor))
					DamageHandler (ent, attacker, final_damage, S_EXPLOSIVE);
				/* kill = false; */
			}
		}
		ent = ent.chain;
	}
};
