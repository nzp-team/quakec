/*
	server/player/last_stand.qc

	Logic for Last Stand and Player Reviving.

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

#define LASTSTAND_DEATH_TIMER       30

void() W_TakeOut;
void() Gamemode_LastStand;

//
// LastStand_SoloRevive()
// Gets the client out of last stand after solo revive
// timer has completed.
//
void() LastStand_SoloRevive =
{
    entity old_self = self;
    self = self.owner;
    GetUp();
    self = old_self;

    // Give the player their score back.
    Player_AddScore(self.owner, self.owner.requirespower, false);

	// Technically, this counts as a revive, I suppose.
	self.owner.revives++;

    // No need for us to exist anymore, goodbye!
    remove(self);
};

//
// LastStand_InitiateSoloRevive(client)
// Kicks off the timer set when a player enters Last
// Stand with Quick Revive in solo.
//
void(entity client) LastStand_InitiateSoloRevive =
{

#ifdef FTE

	// FTE-Specific: Broadcast to the player they're reviving themselves.
	FTE_BroadcastMessage(client, CSQC_BROADCAST_REVIVINGPLAYER, 3, client.playernum);

#endif // FTE

    // Create a new entity to "watch" and be the revivee.
    entity watcher = spawn();
    watcher.owner = client;
    watcher.think = LastStand_SoloRevive;
    watcher.nextthink = time + 10;
};

//
// LastStand_Penalize(client)
// Client entered Last Stand, remove their perks and
// other minor things.
//
void(entity client) LastStand_Penalize =
{
    // Reset bought Perk-A-Colas.
	client.perks = 0;

    // Set Max Health to that of without Jugger-Nog.
	switch(cvar("sv_difficulty")) {
		case 0: client.max_health = client.health = PLAYER_START_HEALTH_NORMAL; break;
		case 1: client.max_health = client.health = PLAYER_START_HEALTH_EASY; break;
		case 2: client.max_health = client.health = PLAYER_START_HEALTH_HARD; break;
		case 3: client.max_health = client.health = PLAYER_START_HEALTH_NIGHTMARE; break;
		default: break;
	}

    // Get rid of Mule Kick Weapon
	for(float i = 0; i < MAX_PLAYER_WEAPONS; i++) {
		if (client.weapons[i].is_mulekick_weapon == true) {
            entity old_self = self;
            self = client;
			Weapon_RemoveWeapon(i);
			Weapon_SetActiveInSlot(0, false);
            self = old_self;
		}
	}

	// Increment stat
	client.downs++;
};

//
// LastStand_AssignWeapon(client)
// Chooses what weapon to hand off to the player
// based on their loadout upon entering Last
// Stand.
//
void(entity client) LastStand_AssignWeapon =
{
    entity old_self = self;
    self = client;

    client.weaponbk = self.weapon;
	client.currentammobk = self.weapons[0].weapon_reserve;
	client.currentmagbk = self.weapons[0].weapon_magazine;
	client.currentmagbk2 = self.weapons[0].weapon_magazine_left;

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
		if (player_count == 1) {
			Weapon_AssignWeapon(0, W_BIATCH, 6, 12);
		} else {
			Weapon_AssignWeapon(0, W_COLT, 8, 16);
		}
	}

	// Play Switch Animation
	self.weaponmodel = GetWeaponModel(self.weapon, 0);
	
	float startframe = GetFrame(self.weapon,TAKE_OUT_START);
	float endframe = GetFrame(self.weapon,TAKE_OUT_END);
	Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, self.weaponmodel, false, S_BOTH, false);

    self = old_self;
};

//
// LastStand_KillPlayer(client)
// Player has bled out, force them into
// a spectator position.
//
void(entity client) LastStand_KillPlayer =
{
    entity old_self = self;
    self = client;

    DisableReviveIcon(self.playernum);

	// If we are in the middle of the Game Over
	// sequence, we should not allow a bleed
	// out to override it.
	if (in_endgame_sequence == false)
		startspectate();

    self = old_self;
};

//
// LastStand_ReviveTriggerFollow()
// Updates the position of the revive trigger
// to always track it's owner (downed client),
// also handles bleed-out checks.
//
void() LastStand_ReviveTriggerFollow =
{
    setorigin(self, self.owner.origin);
    self.nextthink = time + 1;

	// Iterate our death timer if we're not being revived.
	if (self.owner.beingrevived == false)
    	self.downed++;

    if (self.downed >= LASTSTAND_DEATH_TIMER) {
        // Kill our owner.
        LastStand_KillPlayer(self.owner);

        // Kill ourselves.
        remove(self);
    }
};

//
// LastStand_UnlinkRevivee(client)
// Reviving has stopped, revert the state of
// both clients where necessary.
//
void(entity client) LastStand_UnlinkRevivee =
{
	// We can move again.
	client.speed_penalty = client.speed_penalty_time = 0;

	// We're no longer being revived.
	client.beingrevived = false;

	// Remove our broadcast messages for visual feedback.
#ifdef FTE

	FTE_BroadcastMessage(client, CSQC_BROADCAST_NONE, 0, client.playernum);

	if (client.firer != world)
		FTE_BroadcastMessage(client.firer, CSQC_BROADCAST_NONE, 0, client.playernum);

#endif // FTE

	if (client.firer != world) {
		entity old_self = self;
		self = client.firer;

		// The previous revivee should deploy their active weapon.
		W_TakeOut();

		// We should also reset their progress bar state.
		Player_RemoveProgressBar(self);

		self = old_self;
	}

	// We no longer have an active revivee.
	client.firer.firer = world;
	client.firer = world;

	// Revert our revive indicator.
	ChangeReviveIconState(client.playernum, 1);
};

//
// LastStand_LinkRevivee(downed_client, revivee)
// Reviving has been initiated, link the two clients to
// one another for state tracking.
//
void(entity downed_client, entity revivee) LastStand_LinkRevivee =
{
	// We are, in fact, being revived.
    downed_client.beingrevived = true;

    // Link the downed team mate to the client who
    // initiated the revive.
    downed_client.firer = revivee;
	revivee.firer = downed_client;

	// Downed player should no longer be able to crawl
	downed_client.speed_penalty = 0.01;
 	downed_client.speed_penalty_time = time + 100;

	// Set our revive indicator to white.
	ChangeReviveIconState(downed_client.playernum, 2);

#ifdef FTE

	// FTE-Specific: Broadcast to the downed player they're being revived.
	FTE_BroadcastMessage(downed_client, CSQC_BROADCAST_BEINGREVIVED, 2, revivee.playernum);

	// FTE-Specific: Broadcast to revivee that they are reviving the downed player.
	FTE_BroadcastMessage(revivee, CSQC_BROADCAST_REVIVINGPLAYER, 2, downed_client.playernum);

#endif // FTE

	// Initiate an animation for morphine.
	entity old_self = self;
	self = revivee;
	Set_W_Frame (0, 21, 0, 0, SPRINT, SUB_Null, "models/weapons/morphine/v_morphine.mdl", false, S_RIGHT, true);
	self = old_self;
};

//
// LastStand_TouchReviveTrigger()
// Contact made with a downed player's revive trigger,
// handles reviving logic.
//
void() LastStand_TouchReviveTrigger =
{
	// Only trigger for free players, and not ourself.
    if (other.classname != "player" || other == self.owner)
        return;

	// If the team mate is actively being revived, and we are not the one
    // reviving them, break out.
    if (self.owner.beingrevived == true && self.owner.firer != other)
        return;

	// Is the client touching us down, or are they not facing us, or buying something?
	if (other.downed || !PlayerIsLooking(other, self.owner) || other.isBuying) {
		// Were they in the process of reviving us previously?
		if (self.owner.firer == other) {
			// Unlink us.
			LastStand_UnlinkRevivee(self.owner);
		}
		return;
	}

    // No one is actively reviving the downed team mate.
    if (self.owner.beingrevived == false) {
        // Hold F to revive...
        Player_UseprintWithWait(other, self, 13, 0, 0);

        // Kick-off the revive sequence.
        if (Player_UseButtonPressed(other, self)) {
			// Revive time should be significantly shorter with
			// Quick Revive.
			float revive_time = 4;
			if (other.perks & P_REVIVE)
				revive_time = 2;

			// Link us together!
			LastStand_LinkRevivee(self.owner, other);
			other.fire_delay = other.fire_delay2 = other.reload_delay = other.reload_delay2 = other.knife_delay = time + revive_time; // FIXME

			// Use ltime on the revive trigger to know when the revive is finished
			self.ltime = time + revive_time;

			// Display progress bar for the revivee.
			Player_InitiateProgressBar(other, revive_time);
        }
        return;
    }

	// Revivee has released the revive button.
    if (!self.owner.firer.button7) {
		LastStand_UnlinkRevivee(self.owner);
        return;
    }

	// Reviving has been executed for the full duration..
	if (self.ltime < time) {
		// Reward the revivee with the points the downed client lost,
		// and increment their revives stat.
		Player_AddScore(other, self.owner.requirespower, false);
		self.owner.revives++;

		entity old_self = self;
		self = self.owner;
		GetUp();
		self = old_self;

		// Unlink the revivee, no need to stay connected.
		LastStand_UnlinkRevivee(self.owner);

		// Remove the revive icon from above the previously downed client
		DisableReviveIcon(self.owner.playernum);

		// No reason for the trigger to exist anymore, goodbye!
		remove(self);
	}
};

//
// LastStand_SpawnReviveTrigger(client)
// Spawns a trigger to follow a client for reviving.
//
void(entity client) LastStand_SpawnReviveTrigger =
{
    entity revive_trigger = spawn();
    revive_trigger.owner = client;
    revive_trigger.classname = "revive_trigger";
    revive_trigger.think = LastStand_ReviveTriggerFollow;
    revive_trigger.nextthink = time + 1;
    revive_trigger.touch = LastStand_TouchReviveTrigger;
    revive_trigger.solid = SOLID_TRIGGER;
    
    setorigin(revive_trigger, client.origin);
    setsize(revive_trigger, '-52 -52 -16', '52 52 -4');
};

//
// LastStand_Begin(client)
// Player has gone down, oh noes! Kicks off their
// state changes and decides what the game should
// do next.
//
void(entity client) LastStand_Begin =
{
    entity old_self = self;
    self = client;

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

	// Calculate the loss in points, take away points from downed Player.
	float point_difference;
	point_difference = self.points;
	point_difference -= 10*rint((self.points*0.95)/10);
	Player_RemoveScore(self, point_difference);
	self.requirespower = point_difference;

	// Reset state
	self.velocity = self.zoom = 0;
	self.downed = true;
	self.dive_delay = 0;

    // End the game if no one else is alive.
	float players_still_alive = PollPlayersAlive();
	if ((player_count > 1&& !players_still_alive) || (player_count == 1 && !(self.perks & P_REVIVE))) {
		EndGameSetup();
		return;
	}

#ifdef FTE

	// FTE-Specific: Broadcast that the player has downed to everyone.
	FTE_BroadcastMessage(world, CSQC_BROADCAST_PLAYERDOWNED, 3, self.playernum);

#endif // FTE

    self.health = 19; 

	// Initiate Self-Revive on Solo
	if ((self.perks & P_REVIVE) && player_count == 1) {	
		if (cvar("sv_difficulty") == 3) {
			EndGameSetup();
			return;
		}
        LastStand_InitiateSoloRevive(self);
    }
    // Spawn the Revive Trigger
    else {
        LastStand_SpawnReviveTrigger(self);
    }

    // Reset the tracker for the achievement "No Perks? No Problem"
	self.ach_tracker_npnp = 0;

    // Take away Perks, Mule Kick weapon, etc.
    LastStand_Penalize(self);

    // Assign the Player a temporary weapon to use while in Last Stand.
    LastStand_AssignWeapon(self);

	// Spawn Revive Sprite in Co-Op
	if (player_count > 1) {
		EnableReviveIcon(self.playernum);
	}

	// Play Last Stand Animation
	PAnim_GetDown();

	Gamemode_LastStand();

    self = old_self;
};