/*
	server/utilities/game_restart.qc

	A utility for re-starting the game without going through the
    server unload procedure.

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

void() PutClientInServer;
void() InitRounds;
void() func_door_nzp;

//
// GameRestart_CleanPowerUps()
// Cleans Power-Ups thrown about on the map,
// as well as a sanity check for their state.
//
void() GameRestart_CleanPowerUps =
{
    entity tempe;

    // Delete lingering PU entities
    tempe = find(world, classname, "item_powerup");
    while(tempe != world) {
        // Kill their sounds
        sound(tempe.owner, CHAN_VOICE, "sounds/null.wav", 1, ATTN_NORM);
	    sound(tempe, CHAN_AUTO, "sounds/null.wav", 1, ATTN_NONE);

        // Delete em
        remove(tempe.owner); // Sparkle
        remove(tempe);

        // Iterate to the next
        tempe = find(tempe, classname, "item_powerup");
    }

    // Turn off HUD icons
    tempe = find(world, classname, "player");
    while (tempe != world) {
        tempe.insta_icon = false;
        tempe.x2_icon = false;
        tempe = find(tempe, classname, "player");
    }

    // They're finished, stop doing the effects.
    instakill_finished = time;
    x2_finished = time;
}

//
// GameRestart_CleanWallSummons()
// Removes World models summoned from
// weapon_wall.
//
void() GameRestart_CleanWallSummons =
{
    entity tempe;

    tempe = find(world, classname, "weapon_wall");
    while (tempe != world) {
        // Check if it's model has been set, if it is undo the damage.
        if (tempe.enemy.model != "") {
			setmodel(tempe.enemy, "");
			tempe.enemy.boxstatus = 0;
			makevectors(tempe.angles);
			setorigin(tempe.enemy, tempe.origin + v_right*-4);
		}
            
        tempe = find(tempe, classname, "weapon_wall");
    }
}

//
// GameRestart_RepairBarricades()
// Resets the barricade health state.
//
void() GameRestart_RepairBarricades =
{
 	entity tempe;
	
	tempe = find(world, classname, "window");
    while (tempe != world) {
        if (tempe.health != -10) {
            tempe.health = 6;
            tempe.frame = 0;
        }

        tempe = find(tempe, classname, "window");
    }
}

//moto -- put this here because it keeps soft_restart somewhat clean..
void(entity door) reclose_door = {
	entity  oldself;
	oldself = self;

	self = door;
	setmodel(self, self.oldmodel);
	self.solid = SOLID_BSP;
	setorigin(self, self.oldorigin);
	self.isopen = 0;
	func_door_nzp();

	//Close_Waypoint(self.wayTarget);

	self = oldself;
}

void() Soft_Restart = {
	entity who, oldself, doors, box, revive, endgame;
	self = find(world,classname,"player");
	oldself = self;
	
	//remove all zombies
	who = find(world,classname,"ai_zombie");
	while(who != world)
	{
		if(who.health)
		{
			self = who;
			self.th_die();

			// hide bodies
			setmodel(self, "");
			if (self.head)
				setmodel(self.head, "");
			if (self.larm)
				setmodel(self.larm, "");
			if (self.rarm)
				setmodel(self.rarm, "");

			self = oldself;
		}
		
		who = find(who,classname,"ai_zombie");
	}

    GameRestart_CleanPowerUps();		// Get rid of any Power-Ups that were spawned and left.
    GameRestart_CleanWallSummons();		// Delete residual wall weapon spawns from our last game.
	GameRestart_RepairBarricades();		// Make sure all barricades are fully repaired.

	//close doors
	doors = findfloat(world, isopen, 1);
	while (doors) {
		if (doors.isopen)
			reclose_door(doors);
		doors = findfloat(world, isopen, 1);
	}

	//revert mystery box
	box = find(world, classname, "mystery");
	if (box) {
		box.boxstatus = 0;
		box.frame = 0;
		box.goaldummy.frame = 0;
		boxCount = 0;
		box.origin = boxOrigin;
		//self = box;

		if (box.boxweapon)
			remove(box.boxweapon);

		//mystery_box();
		//self = oldself;
	}

	//reset quick revive
	revive = find(world, classname, "perk_revive");
	if (revive) {
		setmodel(revive, revive.model);
		oldself.revivesoda = 0;
	}

	//reset buyable ending
	endgame = find(world, classname, "func_ending");
	if (endgame) {
		endgame.activated = false;
	}

	//reset teleporters
	local entity tp;
	tp = find(world, classname, "func_teleporter_entrance");

	if (tp) {
		tp.activated = false;
		tp.isLinked = false;
		tp.cooldown = false;
		tp.waitLink = false;
		tp.think = SUB_Null;
	}

	local entity power;
	power = find(world, classname, "power_switch");
	if(power) {
		isPowerOn = false;
		power.frame = 0;
	}

	self = oldself;
	self.downed = 0;
	self.progress_bar = 0;
	self.progress_bar_time = 0;
	self.progress_bar_percent = 0;
	game_over = false;
	rounds = 0;
	self.score = 0;
	self.points = 0;
	self.secondaryweapon = 0;

	// naievil -- clear betty
	self.secondary_grenades = 0;
	self.grenades = 1;
	self.pri_grenade_state = 0;

	InitRounds();
	self.isspec = false;
	PutClientInServer();
}