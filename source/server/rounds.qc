/*
	server/rounds.qc

	wave logic

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
void() SUB_UseTargets;
float() spawn_a_dogA;
void() zapper_cooldown;

void() Spawn_Enemy =
{
	// temporarily prevent spawning
	if (nuke_powerup_spawndelay > time)
		return;

	if (roundtype == 1)
	{
		if (spawn_a_zombieA())
		{
			Current_Zombies = Current_Zombies + 1;
		}
	}
	else if (roundtype == 2)
	{
		if (spawn_a_dogA())
		{
			Current_Zombies = Current_Zombies + 1;
		}
	}
}

float(float a, float b) qc_max =
{
	if (a < b)
		return b;
	return a;
}

float() getZombieTotal = {
	if (roundtype == 1) {
		float count, multiplier, plrcnt;
		count = 24;
		plrcnt = player_count + 1;

		multiplier = qc_max(rounds/5, 1);

		if (rounds >= 10)
			multiplier *= rounds * 0.15;

		if (plrcnt == 1)
			count += rint((0.5 * 6) * multiplier);
		else
			count += rint(((plrcnt - 1) * 6) * multiplier);

		if (rounds < 2)
			count = floor(count * 0.25);
		else if (rounds < 3)
			count = floor(count * 0.30);
		else if (rounds < 4)
			count = floor(count * 0.50);
		else if (rounds < 5)
			count = floor(count * 0.70);
		else if (rounds < 6)
			count = floor(count * 0.90);

		return count;
	} else { //dogs
		// 2 waves
		if (rounds <= 14)
			return 6 * (player_count + 1);

		return 8 * (player_count + 1);
	}
	return 0;
}

//
// Rounds_PlayTransition(sound_path)
// A nice wrapper for sound() that checks if
// music is playing and proceeds if not.
//
void(string sound_path) Rounds_PlayTransition =
{
	// Don't play any round stuff while there's a song egg happening.
	if (music_override > time)
		return;

	// Pick a random player because it needs a source.
	entity some_player = find(world, classname, "player");
	sound(some_player, CHAN_AUTO, sound_path, 1, ATTN_NONE);
}

void() updateDogRound =
{
	float r = random();

	if (r < 0.33) {
		dogRound = rounds + 5;
	} else if (r < 0.66) {
		dogRound = rounds + 6;
	} else {
		dogRound = rounds + 7;
	}
}

void() PlayerSpawn;

void() EndRound =
{
	entity who = find(world,classname,"spectator");
	while(who != world)
	{
		if(who.isspec)
		{
			self = who;
			PlayerSpawn();
		}
		who = find(who, classname, "spectator");
	}

	rounds_change = 4;
	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
	if (gotdog && rounds == dogRound) {
		Rounds_PlayTransition("sounds/rounds/droundend.wav");
		dogWave = false;
	} else {
		Rounds_PlayTransition("sounds/rounds/eround.wav");
	}
	round_changetime = time + 10;

	// No Perks? No Problem & Abstinence Program
	if (rounds >= 10) {
		entity players;
		players = find(world, classname, "player");

		while(players != world) {
			if (players.ach_tracker_abst == 0) {
				GiveAchievement(8, players);
			}
			if (rounds >= 16) {
				if (players.ach_tracker_npnp == 0) {
					GiveAchievement(5, players);
				}
			}
			players = find(players, classname, "player");
		}
	}

	// Fire off all trigger_atroundent ents
	entity triggers = find(world, classname, "trigger_atroundend");
	while(triggers != world) {
		if (triggers.health == rounds) {
			entity oldself = self;
			self = triggers;
			SUB_UseTargets();
			self = oldself;
		}
		triggers = find(triggers, classname, "trigger_atroundend");
	}
}

void() NewRound =
{
	entity tempe;
	round_changetime = 0;
	spawn_time = time + 5;
	sounds_playing = 0;//just in case it ever somehow glitches
	if (delay_at_round > 0.08)
	{
		delay_at_round = delay_at_round*0.95;
		if (delay_at_round < 0.08)
			delay_at_round = 0.08;
	}
	if (rounds != 0)
	{
		if (gotdog && rounds == (dogRound - 1)) {
			Rounds_PlayTransition("sounds/rounds/droundstart.wav");
			dogWave = true;
			dog_round_count++;
		} else {
			Rounds_PlayTransition("sounds/rounds/nround.wav");
		}
		rounds_change = 6;
		SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
		blink_return = time + 2;
	}

	// if we just had a dog round, set the next
	if (gotdog && rounds == dogRound) {
		updateDogRound();
	}

	rounds = rounds + 1;

#ifdef FTE

	// FTE-Specific - alert CSQC of the round increment for HUD display
	FTE_IncrementRound(rounds);

#endif // FTE

	tempe = find(world, classname, "player");
	while (tempe)
	{
		if(tempe.grenades & 1)
		{
			tempe.primary_grenades = tempe.primary_grenades + 2;
			if (tempe.primary_grenades > 4)
				tempe.primary_grenades = 4;
		}

		if(tempe.grenades & 2)
		{
			tempe.secondary_grenades = tempe.secondary_grenades + 2;
			if (tempe.secondary_grenades > 2)
				tempe.secondary_grenades = 2;
		}

		// Set everyone to full health.
		tempe.health = tempe.max_health;

		tempe = find(tempe, classname, "player");
	}

	set_z_health();

	maxreward = 50 * rounds;
	if (maxreward > 500)
		maxreward = 500;

	totalreward = 0;
	Current_Zombies = 0;
	spawn_delay = 0;
	totalpowerups = 0;

	if (rounds == dogRound && gotdog) {
		roundtype = 2;
		localcmd("fog 200 525 54 55 60\n");
	} else {
		roundtype = 1;

		if (world.fog) {
			localcmd(strcat("fog ", world.fog));
		} else {
			localcmd("fog 0 0 0 0 0\n");
		}
	}

	Remaining_Zombies = Total_Zombies = getZombieTotal();

	switch(rounds) {
		case 5: 	GiveAchievement(0); break;
		case 10: 	GiveAchievement(1); break;
		case 15: 	GiveAchievement(2); break;
		default: 	break;
	}

	// Set up delay for zombie spawning
	local float spawndelay;

	spawndelay = zombie_spawn_delay;

	if (spawndelay > 0.08) {
		zombie_spawn_delay *= 0.95;
	} else {
		zombie_spawn_delay = 0.08;
	}

	// 2 seconds by default
	if (rounds == 1)
		zombie_spawn_delay = 2;

	// Actually start the timer
	zombie_spawn_timer = 2 + time;

	if (rounds >= 10 && ach_tracker_spin == 0) {
		GiveAchievement(10);
	}

	// Refresh Electric Traps
	entity zaps = find(world, classname, "zapper_switch");
	while(zaps != world) {
		if (zaps.mode == 1) {
			zaps.think = zapper_cooldown;
            zaps.nextthink = time + 0.1;
		}
		zaps = find(zaps, classname, "zapper_switch");
	}
}

void() Round_Core =
{
	if (game_over)
		return;

	if (round_changetime) {
		if (round_changetime <= (time + 2)) {
			if (!rounds)
				rounds_change = 2;
			else
				rounds_change = 5;
		}
	}
	if (blink_return && blink_return < time) {
		if (rounds_change == 6) {
			blink_return = time + 3;
			rounds_change = 7;
		} else {
			blink_return = 0;
			rounds_change = 0;
		}
	}

	if (round_changetime < time && round_changetime != 0) {
		roundtype = 1;
		NewRound();
		return;
	} else if (round_changetime != 0) return;

	if (Total_Zombies > Current_Zombies && spawn_time < time) {
		Spawn_Enemy();
	}

	if (Remaining_Zombies < 1 && !Delay_Time) {
		Delay_Time = time + 1;
		rounds_change = 3;
	} else if (Delay_Time && Delay_Time < time) {
		Delay_Time = 0;
		EndRound();
	}

	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
}

void() InitRounds =
{
	roundtype = 1;
	delay_at_round = 2/0.95;
	totalpowerups = 0;
	powerup_activate = 2000;
	powerup_score_threshold = ((player_count + 1) * G_STARTPOINTS) + powerup_activate;

	// cypress -- fix Soft_Restart spawning multiple 
	// pairs of zombie spawn points.
	if (!roundinit)
		spawnAllZombEnts();
	
	round_changetime = time + 3.5;
	rounds_change = 1;
	roundinit = 1;
	SetUpdate(self, UT_ROUNDS_CHANGE, rounds_change, 0, 0);
}
