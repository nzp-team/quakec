/*
	server/player/last_stand.qc

	Functionality pertaining to Player's Last Stand mode and the act
    of getting out of it.

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
float() PollPlayersAlive;
void() EndGameSetup;
void() SpectatorSpawn;

#define LAST_STAND_DURATION_SEC     100 // Seconds in Last Stand.

// when dead and other players exist and are alive, throw user into spectate mode
void(entity deceased) Player_BecomeSpectator =
{
	if (!deceased.downed)
		return;
		
	/*if (self.beingrevived)
	{
		self.think = startspectate;
		self.nextthink = time + 0.1;
		return;
	}*/
	
	deceased.downedloop = 0;
	deceased.beingrevived = false;
	deceased.model = "";
	setmodel(deceased, deceased.model);
	deceased.health = 100;
	deceased.weaponmodel = "";
	deceased.weapon2model = "";
    deceased.weapon = 0;
	deceased.downed = 0;
	deceased.frame = 0;

	UpdateVmodel(deceased.weaponmodel, GetWepSkin(deceased.weapon));
	UpdateV2model(deceased.weapon2model, GetWepSkin(deceased.weapon));
	
    entity tempe;
    tempe = self;
    self = deceased;
    SwitchWeapon(self.weapon);
	SpectatorSpawn();
    self = tempe;
}

void() ReviveTracker_Update =
{
    // Add to the die timer..
    self.ltime += 0.1;

    // Bleed Out Timer
    if (self.ltime >= LAST_STAND_DURATION_SEC) {
        // Get rid of the Revive Icon from HUDs and make them a spectator.
        DisableReviveIcon(self.owner.electro_targeted);
		Player_BecomeSpectator(self.owner);

        // Prevent any leakage
        remove(self);
    } else {
        self.nextthink = time + 0.1;
    }
}

void(entity deceased) SpawnReviveTracker = 
{
    entity revive_tracker = spawn();
    revive_tracker.owner = deceased;

    revive_tracker.think = ReviveTracker_Update;
    revive_tracker.nextthink = time + 0.1;
}

void() Player_ReviveTrigger =
{
    if (other.classname != "player" || (self.beingrevived == true && self.firer != other))
        return;

    // perform a trace to make sure they're always facing the revivee
	vector source;
	makevectors(self.angles);
	source = other.origin - '0 0 12';
	traceline(source, source + v_forward*50, 0, other);
	other.active_door = trace_ent;

    centerprint(other, other.active_door.classname);

    if (self.beingrevived == false && other.active_door == self)
		useprint(other, 13, 0, 0);
}

void() Player_EnterLastStand =
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

    // Different hitbox for Last Stand
    setsize(self, '-16 -16 -32', '16 16 40');

	// Reset state
	self.velocity = self.zoom = 0;
	self.downed = true;
	self.dive_delay = 0;
	self.movetype = MOVETYPE_WALK;

    // Determine if we should End the Game.
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

	if(Util_PlayerHasWeapon(self, W_BIATCH, false) || 
	Util_PlayerHasWeapon(self, W_RAY, true) ||
	Util_PlayerHasWeapon(self, W_357, true)) {
		float weapon_slot;
		float total_ammo;
		total_ammo = 0;

		weapon_slot = Util_PlayerHasWeapon(self, W_RAY, true);
		if (weapon_slot == 0) weapon_slot = Util_PlayerHasWeapon(self, W_BIATCH, false);
		if (weapon_slot == 0) weapon_slot = Util_PlayerHasWeapon(self, W_357, true);

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

	// Spawn Revive Sprite and Revive Tracker in Co-Op
	if (coop) {
		EnableReviveIcon(revive_index, self.origin + VEC_VIEW_OFS);
        SpawnReviveTracker(self);
        self.touch = Player_ReviveTrigger;
		self.electro_targeted = revive_index;
		revive_index++;
	}

	//self.think = rec_downed;
	//self.nextthink = time + 0.1;
}

void() Player_LeaveLastStand =
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

    // Revert Hitbox
    setsize(self, '-16 -16 -32', '16 16 40');

	// Take away the ammo that was fired while in last stand.
	if (self.weapon != W_COLT) {
		if (self.weapon == self.weaponbk) {
			self.currentammobk -= self.teslacount;

			// Take from the mag if the reserve is empty now
			if (self.currentammobk < 0)
				self.currentmagbk += self.currentammobk;
			self.currentammobk = 0;
		} else if (self.weapon == self.secondaryweapon) {
			self.secondaryammo -= self.teslacount;

			// Take from the mag if the reserve is empty now
			if (self.secondaryammo < 0)
				self.secondarymag += self.secondaryammo;
			self.secondaryammo = 0;
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