/*
	server/clientfuncs.qc

	used for any sort of down, hit, etc that the player or entity 
	experiences

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
	nzp_screenflash(self, SCREENFLASH_COLOR_BLACK, 6, SCREENFLASH_FADE_IN);

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
	self.nextthink = time + 28;
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
	self.health = 100;
	self.weaponmodel = "";
	self.weapon2model = "";
	self.downed = 0;
	self.frame = 0;
	
	SpectatorSpawn();
}

// searches for players that are alive given which clients have which playernumbers
//      Returns 1 if there IS someone in the world that's not downed
float() PollPlayersAlive = 
{
	entity players = find(world, classname, "player");

	while(players != world) {
		if (!players.downed)
			return 1;

		players = find(players, classname, "player");
	}

	return 0;
}

// Endgamesetup -- think function for setting up the death of everyone
void() EndGameSetup =
{
	self.health = 10;
	self.think = EndGame;
	self.nextthink = time + 4;
	self.weapon = 0;
	self.currentammo = 0;
	self.currentmag = 0;
	self.weaponmodel = "";
	self.weapon2model = "";
	self.animend = SUB_Null;
	self.perks = 0;
	self.isspec = true;
	self.movetype = MOVETYPE_TOSS;

	if (!game_over) {
		sound(self, CHAN_AUTO, "sounds/music/end.wav", 1, ATTN_NONE);
		NotifyGameEnd();
	}
	game_over = true;
	Player_RemoveScore(self, self.points);
	Player_AddScore(self, self.score, false);
    return;
}

// rec_downed is used as a recursive loop where we consistently check to see if ALL players are downed
//    if they aren't dead, we keep looping until our OWN death (45 seconds, so 300 loops)
void() rec_downed = 
{
	if (!self.beingrevived)
		self.downedloop += 1;

	if (self.downedloop >= 30) {
		DisableReviveIcon(self.electro_targeted);
		revive_index--;
		startspectate();
		return;
	}
	
	float gotalive = PollPlayersAlive();
	
	if (!gotalive && !self.progress_bar) {
		EndGameSetup();
		return;
	}
	
	self.think = rec_downed;
	self.nextthink = time + 1;
}

float() push_away_zombies;
void() GetDown =
{
	// 'Pro Gamer Move' achievement.
	if (rounds <= 1 && self.weapons[0].weapon_magazine == 0 && 
	self.weapons[0].weapon_magazine_left == 0 && self.weapons[0].weapon_reserve == 0 && 
	self.weapons[1].weapon_magazine == 0 && self.weapons[1].weapon_magazine_left == 0 && 
	self.weapons[1].weapon_reserve == 0) {
		GiveAchievement(9, self);
	}

	// Aim out to reset zoom values
	W_AimOut();

#ifdef FTE

	self.viewzoom = 1;

#endif // FTE

	// Make any zombies inside of the player's bounding box leave
	push_away_zombies();

	// Force the player to prone.
	Player_SetStance(self, PLAYER_STANCE_PRONE, false);

	// Get rid of Mule Kick Weapon
	for(float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		if (self.weapons[i].is_mulekick_weapon == true) {
			Weapon_RemoveWeapon(i);
			Weapon_SetActiveInSlot(0, false);
		}
	}

	// Calculate the loss in points, take away points from downed Player.
	float point_difference;
	point_difference = self.points;
	point_difference -= 10*rint((self.points*0.95)/10);
	Player_RemoveScore(self, point_difference);

	self.requirespower = point_difference;

#ifdef FTE

	// FTE-Specific: Broadcast that the player has downed to everyone.
	FTE_BroadcastMessage(world, CSQC_BROADCAST_PLAYERDOWNED, 3, self.playernum);

#endif // FTE

	// Reset state
	self.velocity = self.zoom = 0;
	self.downed = true;
	self.dive_delay = 0;

	float players_still_alive = PollPlayersAlive();

	if ((player_count && !players_still_alive) || (!player_count && !(self.perks & P_REVIVE))) {
		EndGameSetup();
		return;
	} else {
		self.health = 19; 
	}

	// Initiate Self-Revive on Solo
	if ((self.perks & P_REVIVE) && !player_count) {	
		self.progress_bar = 10 + time;     
		self.progress_bar_time = 10;
		self.progress_bar_percent = 1;

#ifdef FTE

		// FTE-Specific: Broadcast to the player they're reviving themselves.
		FTE_BroadcastMessage(self, CSQC_BROADCAST_REVIVINGPLAYER, 3, self.playernum);

#endif // FTE


	}

	// Take away weapons and Perks
	self.perks = 0;

	self.weaponbk = self.weapon;
	self.currentammobk = self.weapons[0].weapon_reserve;
	self.currentmagbk = self.weapons[0].weapon_magazine;
	self.currentmagbk2 = self.weapons[0].weapon_magazine_left;

	//Reset the tracker for the achievement "No Perks? No Problem"
	self.ach_tracker_npnp = 0;

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
				total_ammo = self.weapons[0].weapon_magazine + self.weapons[0].weapon_magazine_left + self.weapons[0].weapon_reserve;
				break;
			case 2:
				total_ammo = self.weapons[1].weapon_magazine + self.weapons[1].weapon_magazine_left + self.weapons[1].weapon_reserve;
				Weapon_SwapWeapons(true);
				break;
		}

		self.weaponbk = self.weapon;
		self.currentammobk = self.weapons[0].weapon_reserve;
		self.currentmagbk = self.weapons[0].weapon_magazine;
		self.currentmagbk2 = self.weapons[0].weapon_magazine_left;

		// If it's greater than the mag size, we can fill the magazine.
		if (total_ammo > getWeaponMag(self.weapon) || total_ammo == 0) {
			self.weapons[0].weapon_magazine = getWeaponMag(self.weapon);

			// subtract it from the total ammo
			if (total_ammo != 0)
				total_ammo -= self.weapons[0].weapon_magazine;
		} else {
			self.weapons[0].weapon_magazine = total_ammo;
			total_ammo = 0;
		}

		// Check for dual wield mag too
		if (IsDualWeapon(self.weapon)) {
			if (total_ammo > getWeaponMag(self.weapon) || total_ammo == 0) {
				self.weapons[0].weapon_magazine_left = getWeaponMag(self.weapon);

				// subtract it from the total ammo
				if (total_ammo != 0)
					total_ammo -= self.weapons[0].weapon_magazine_left;
			} else {
				self.weapons[0].weapon_magazine_left = total_ammo;
				total_ammo = 0;
			}
		}

		// Ray Gun has a special case where we DON'T fill its reserve
		if (self.weapon != W_RAY && self.weapon != W_PORTER) {
			// Now see if the reserve ammo is more than max downed capacity
			if (total_ammo > getWeaponMag(self.weapon)*2) {
				self.weapons[0].weapon_reserve = getWeaponMag(self.weapon)*2;
			} else {
				// It's not so just fill it
				self.weapons[0].weapon_reserve = total_ammo;
			}
		} else {
			self.weapons[0].weapon_reserve = 0;
		}
	} else {
		if (!player_count) {
			Weapon_AssignWeapon(0, W_BIATCH, 6, 12);
		} else {
			Weapon_AssignWeapon(0, W_COLT, 8, 16);
		}
	}

	// Play Switch Animation
	self.weaponmodel = GetWeaponModel(self.weapon, 0);
	
	float startframe = GetFrame(self.weapon,TAKE_OUT_START);
	float endframe = GetFrame(self.weapon,TAKE_OUT_END);
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, self.weaponmodel, false, S_BOTH);

	// Spawn Revive Sprite in Co-Op
	if (player_count) {
		EnableReviveIcon(revive_index, self.origin + VIEW_OFS_HL);
		self.electro_targeted = revive_index;
		revive_index++;
	}

	// Play Last Stand Animation
	PAnim_GetDown();
}

void () GetUp =
{	
	// Play Getting Up Animation
	PAnim_GetUp();

	Player_SetStance(self, PLAYER_STANCE_STAND, false);

	// Bad hack: if we're crouching, just play some dummy crouchwalk frames.
	if (self.stance == PLAYER_STANCE_CROUCH)
		PAnim_CrouchWalk7();
	
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
		} else if (self.weapon == self.weapons[1].weapon_id) {
			self.weapons[1].weapon_reserve -= self.teslacount;

			// Take from the mag if the reserve is empty now
			if (self.weapons[1].weapon_reserve < 0) {
				self.weapons[0].weapon_magazine += self.weapons[1].weapon_reserve;
				self.weapons[1].weapon_reserve = 0;
			}
		}
	}
	
	self.teslacount = 0;

	if (!player_count) {
		Player_AddScore(self, self.requirespower, false);
	}

	Weapon_AssignWeapon(0, self.weaponbk, self.currentmagbk, self.currentammobk);
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

		float points_earned = 0;
		switch(d_style) {
			case S_HEADSHOT:
				points_earned = 100;
				attacker.headshots++;
				break;
			case S_KNIFE:
				points_earned = 130;
				break;
			case S_TESLA:
				points_earned = 50;
				break;
			case S_FLAME:
				points_earned = 50;

				// override their death sound (FIXME: make a new sound..)
				sound(self, CHAN_BODY, "sounds/pu/drop.wav", 1, ATTN_NORM);
				break;
			default:
				points_earned = 60;
				break;
		}

		Player_AddScore(attacker, points_earned, true);
    }
}

void(entity victim,entity attacker, float damage, float d_style) DamageHandler = {
	// don't do any attacking during nuke delay
	if (d_style == S_ZOMBIE && nuke_powerup_active > time)
		return;

	entity old_self;
	if (victim.classname == "ai_zombie" || victim.classname == "ai_dog") {

		if (attacker.classname == "player" && (victim.health - damage) > 0) {
			Player_AddScore(attacker, 10, true);
        }

		victim.health = victim.health - damage;

		if (d_style == S_EXPLOSIVE && damage != 0) {
			if (victim.health > 0 && victim.crawling == 2) {
				makeCrawler(victim);
				GiveAchievement(3, attacker);
			}
				
			if (victim.health <= 0)
				Player_AddScore(attacker, 60, true);
			else
				Player_AddScore(attacker, 10, true);
		}

		if (victim.health <= 0 || instakill_finished > time) {
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

float(float min, float max, vector org1, vector org2, float radius) calculate_proximity_value =
{
	float proximity_value;
	float distance = fabs(vlen(org1 - org2));

	if (distance <= radius) {
		float normalized_distance = distance / radius;
		proximity_value = min + (max - min) * (1 - normalized_distance);
	} else {
		proximity_value = min;
	}
	
	return proximity_value;
};

void(entity inflictor, entity attacker, float damage2, float mindamage, float radius) DamgageExplode =
{
	float 	final_damage = 0;
	entity	ent;

	float 	multi, r;
	ent = findradius(inflictor.origin, radius);
	
	while (ent != world)
	{
		if(ent.classname == "player")
		{
			if (ent.perks & P_FLOP)	// PhD Flopper makes us immune to any explosive damage
				final_damage = 0;
			else if (inflictor.classname == "betty") // Self-inflicted betties don't do damage either.
				final_damage = 0;
			else if (inflictor.owner != ent) // we don't want OUR explosives to harm other players..
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
					Player_AddScore(self, 10, false);
				}
				else if (final_damage > other.health)
				{
					Player_AddScore(self, 10, false);
				}
				else
				{
					final_damage /= radius;
					final_damage *= 60;
				}

				// inflicting damage from an explosive introduces a delay before
				// player can sprint again.
				ent.sprint_delay = time + 3;
			}
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

			// cypress -- accurate explosive damage
			// cod likes to override the damage to ai with
			// explosives (yay!).
			if (inflictor.classname == "grenade") {
				// grenades follow the logic of (rounds + (rand 150-500))
				// rounds is basically meaningless though.. wtf?
				final_damage = rounds + rint(random() * 350) + 150;
			} else if (inflictor.classname == "projectile_grenade") {
				// projectile-based grenades (mustang & sally) seem to do
				// more damage than standard grenades.
				// (rounds + (rand 1200-5000))
				final_damage = rounds + rint(random() * 3800) + 1200;
			} else if (inflictor.classname == "rocket") {
				// rockets were kinda tricky to figure out, this is as close
				// as i can get and i'm not super confident..
				// (rounds * (rand 0-100) * weapon_damage/500).
				final_damage = (rounds * rint(random() * 100)) * damage2/500;
			} else if (inflictor.classname == "projectile_raybeam") {
				//final_damage = calculate_proximity_value(mindamage, damage2, inflictor.origin, ent.origin, radius);
				//bprint(PRINT_HIGH, strcat("damage: ", ftos(final_damage), "\n"));
				final_damage = damage2;
			} else if (inflictor.classname == "player") {
				// phd flopper.
				final_damage = calculate_proximity_value(mindamage, damage2, inflictor.origin, ent.origin, radius);
			} else {
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
			}

			// to decide if this should make a crawler, check if we've done 10% or more damage
			if (final_damage / ent.health > 0.10 && ent.crawling != true && ent.classname != "ai_dog") {
				ent.crawling = 2;
			}	
		}

		if (final_damage > 0) {
			if (CanDamage (ent, inflictor))
				DamageHandler (ent, attacker, final_damage, S_EXPLOSIVE);
		}
		ent = ent.chain;
	}
};
