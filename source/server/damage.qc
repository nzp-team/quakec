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
void(entity client) LastStand_Begin;
void() Gamemode_GetUp;
void(entity attacker, float death_style) Gamemode_DieHandler;

#define DMG_SCORE_HEADSHOT		100 	// Death by Headshot
#define DMG_SCORE_MELEE			130		// Death by Melee
#define DMG_SCORE_UPPERTORSO	60		// Death by gunshot, upper torso.
#define DMG_SCORE_LOWERTORSO	50 		// Death by gunshot, lower torso.
#define DMG_SCORE_GRENADE		50 		// Death by Grenade.
#define DMG_SCORE_EXPLOSIVE		60  	// Death by Explosive Weapon.
#define DMG_SCORE_TESLA			50  	// Death by Tesla.
#define DMG_SCORE_STDDAMAGE		10  	// Standard Damage reward.

void() Barrel_Hit;
void() teddy_react;

// Fade to black function, creates another think for restart
void() EndGame_FadePrompt =
{
	entity players = find(world, classname, "player");
	while(players != world) {
		nzp_screenflash(players, SCREENFLASH_COLOR_BLACK, 5, SCREENFLASH_FADE_IN);
		players = find(players, classname, "player");
	}

#ifdef FTE

	self.think = MapRotation_Decide;

#else

	self.think = Soft_Restart;

#endif // FTE

	self.nextthink = time + 5;
}

//Actual endgame function, all zombies die, music plays
void() EndGame =
{
	entity old_self;
	entity who = find(world,classname,"ai_zombie");
	while(who != world)
	{
		if(who.health)
		{
			old_self = self;
			self = who;
			self.th_die();
			self = old_self;
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
	
	if (player_count > 1)
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
	entity gameover_watcher = spawn();
	gameover_watcher.think = EndGame;
	gameover_watcher.nextthink = time + 4;
	gameover_watcher.classname = "gameover_watcher";

	entity players = find(world, classname, "player");
	while(players != world) {
		players.health = 0;
		players.weapon = 0;
		players.currentammo = 0;
		players.currentmag = 0;
		players.weaponmodel = "";
		players.weapon2model = "";
		players.animend = SUB_Null;
		players.perks = 0;
		players.movetype = MOVETYPE_TOSS;
		players.velocity = '0 0 0';

		Player_RemoveScore(players, players.points);
		Player_AddScore(players, players.score, false);

		players = find(players, classname, "player");
	}

	if (in_endgame_sequence == false) {
		Rounds_PlayTransition("sounds/music/end.wav");
		NotifyGameEnd();
	}

	in_endgame_sequence = true;
	Player_RemoveScore(self, self.points);
	Player_AddScore(self, self.score, false);
	for (float i = 0; i < MAX_PLAYER_WEAPONS; ++i)
	{
		Weapon_RemoveWeapon(0);
	}
  return;
}

float() push_away_zombies;

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

	Weapon_AssignWeapon(0, self.weaponbk, self.currentmagbk, self.currentammobk);
	Gamemode_GetUp();
};

// poll checking whether to see if our revive invoke is active
void(entity ent) CheckRevive =
{
	if (self.invoke_revive) {
		GetUp();
		DisableReviveIcon(self.playernum);
		self.invoke_revive = 0;
		self.firer = world;
	}
}

void(entity attacker, float d_style) DieHandler =
{
	if (cvar("sv_headshotonly") == 1 && d_style != DMG_TYPE_HEADSHOT && self.classname == "ai_zombie")
		return;

    float t;

    t = random();

    if (self.classname == "ai_zombie" || self.classname == "ai_dog") {
        self.th_die();
    }

    if (attacker.classname == "player") {
		attacker.kills++;
		nzp_hitmarker(attacker, true);

		float points_earned = 0;
		switch(d_style) {
			case DMG_TYPE_HEADSHOT:
				points_earned = DMG_SCORE_HEADSHOT;
				attacker.headshots++;
				break;
			case DMG_TYPE_MELEE:
				points_earned = DMG_SCORE_MELEE;
				break;
			case DMG_TYPE_TESLA:
				points_earned = DMG_SCORE_GRENADE;
				break;
			case DMG_TYPE_FLAMETHROWER:
				points_earned = DMG_SCORE_GRENADE;

				// override their death sound (FIXME: make a new sound..)
				Sound_PlaySound(self, "sounds/pu/drop.wav", SOUND_TYPE_ZOMBIE_LOUD, SOUND_PRIORITY_PLAYALWAYS);
				break;
			case DMG_TYPE_GRENADE:
				points_earned = DMG_SCORE_GRENADE;
				break;
			case DMG_TYPE_EXPLOSIVE:
				points_earned = DMG_SCORE_EXPLOSIVE;
				break;
			case DMG_TYPE_LOWERTORSO:
				points_earned = DMG_SCORE_LOWERTORSO;
				break;
			case DMG_TYPE_UPPERTORSO:
				points_earned = DMG_SCORE_UPPERTORSO;
				break;
			default:
				if (cvar("developer"))
					bprint(PRINT_HIGH, "DieHandler: Received invalid style\n");
				break;
		}

		if (cvar("sv_difficulty") == 3)
			points_earned = floor((points_earned/10) * 0.75) * 10;

		Player_AddScore(attacker, points_earned, true);

		Gamemode_DieHandler(attacker, d_style);
    }
}

void(entity victim, entity attacker, float damage, float d_style) DamageHandler = {
	if (cvar("sv_headshotonly") == 1 && d_style != DMG_TYPE_HEADSHOT && victim.classname == "ai_zombie")
		return;

	// don't do any attacking during nuke delay
	if (d_style == DMG_TYPE_ZOMBIESWIPE && nuke_powerup_active > time)
		return;

	entity old_self;
	if (victim.classname == "ai_zombie" || victim.classname == "ai_dog") {

		if (attacker.classname == "player" && (victim.health - damage) > 0 && d_style != DMG_TYPE_OTHER) {
			Player_AddScore(attacker, DMG_SCORE_STDDAMAGE, true);
			nzp_hitmarker(attacker, false);
        }

		victim.health = victim.health - damage;

		if (d_style == DMG_TYPE_EXPLOSIVE && damage != 0) {
			if (victim.health > 0 && victim.crawling == 2) {
				makeCrawler(victim);
				GiveAchievement(3, attacker);
			}
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
		if (d_style != DMG_TYPE_ELECTRICTRAP) {
			Sound_PlaySound(victim, "sounds/player/pain4.wav", SOUND_TYPE_PLAYER_VOICE, SOUND_PRIORITY_PLAYALWAYS);
		} else {
			Sound_PlaySound(victim, "sounds/machines/elec_shock.wav", SOUND_TYPE_PLAYER_VOICE, SOUND_PRIORITY_PLAYALWAYS);
		}

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
			LastStand_Begin(victim);
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
	float 	damage_style = 0;
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
					Player_AddScore(self, DMG_SCORE_STDDAMAGE, false);
				}
				else if (final_damage > other.health)
				{
					Player_AddScore(self, DMG_SCORE_STDDAMAGE, false);
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

			// Give a heavy rumble for feedback of being in explosion vicinity.
			nzp_rumble(ent, 1400, 2000, 200);
			
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
				damage_style = DMG_TYPE_GRENADE;
			} else if (inflictor.classname == "projectile_grenade") {
				// projectile-based grenades (mustang & sally) seem to do
				// more damage than standard grenades.
				// (rounds + (rand 1200-5000))
				final_damage = rounds + rint(random() * 3800) + 1200;
				damage_style = DMG_TYPE_EXPLOSIVE;
			} else if (inflictor.classname == "rocket") {
				// rockets were kinda tricky to figure out, this is as close
				// as i can get and i'm not super confident..
				// (rounds * (rand 0-100) * weapon_damage/500).
				final_damage = (rounds * rint(random() * 100)) * damage2/500;
				damage_style = DMG_TYPE_EXPLOSIVE;
			} else if (inflictor.classname == "projectile_raybeam") {
				//final_damage = calculate_proximity_value(mindamage, damage2, inflictor.origin, ent.origin, radius);
				//bprint(PRINT_HIGH, strcat("damage: ", ftos(final_damage), "\n"));
				final_damage = damage2;
				damage_style = DMG_TYPE_GRENADE;
			} else if (inflictor.classname == "player") {
				// phd flopper.
				final_damage = calculate_proximity_value(mindamage, damage2, inflictor.origin, ent.origin, radius);
				damage_style = DMG_TYPE_GRENADE;
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
				DamageHandler (ent, attacker, final_damage, damage_style);
		}
		ent = ent.chain;
	}
};
