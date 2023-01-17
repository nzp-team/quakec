/*
	server/main.qc

	mostly functions that will be called from the engine and are
	expected to exist

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

void() LS_Setup;
void() PU_Init;
void() SUB_Remove = {remove(self);}

//called when starting server/loading the map
void() main =
{
	localcmd("echo Server starting...\n");
}

float ai_delay_time;

//called for each frame that QC runs
float zombie_cleaned_w;
void() StartFrame =
{
	framecount = framecount + 1;

	if (waypoint_mode) {
		if (!zombie_cleaned_w) {
			entity zent;
			zent = find (world, classname, "ai_zombie");
			while (zent)
			{
				/*
				if (zent.head)
					remove (zent.head);
				if (zent.larm)
					remove (zent.larm);
				if (zent.rarm)
					remove (zent.rarm);
				*/
				remove (zent);
				zent = find (zent, classname, "ai_zombie");
			}
			zombie_cleaned_w = true;

			zent = find (world, classname, "waypoint");
			while (zent)
			{
				if (zent.targetname)
					setmodel(zent, "models/way/normal_way_door.spr");
				else
					setmodel(zent, "models/way/normal_way.spr");
				zent = find (zent, classname, "waypoint");
			}
			zent = find (world, classname, "door_nzp_cost");
			while (zent)
			{
				zent.solid = SOLID_NOT;
				zent.touch = SUB_Null;
				zent = find (zent, classname, "door_nzp_cost");
			}
			zent = find (world, classname, "door_nzp");
			while (zent)
			{
				zent.solid = SOLID_NOT;
				zent.touch = SUB_Null;
				zent.solid = SOLID_NOT;
				zent = find (zent, classname, "door_nzp");
			}
			zent = find (world, classname, "window");
			while (zent)
			{
				zent.solid = SOLID_NOT;
				zent.touch = SUB_Null;
				zent = find (zent, classname, "window");
			}
		}
		return;
	}


	if (roundinit) {
		Round_Core();

		if (ai_delay_time < time) {
			Do_Zombie_AI ();
			ai_delay_time = time + 0.05;
		}
	} else {
		entity SpawnedIn;
		SpawnedIn = find(world, classname, "player");

		if (SpawnedIn) {
			entity getdog = find(world, classname, "spawn_dog");
			if (getdog)
				gotdog = 1;
			else
				gotdog = 0;

			updateDogRound();
			InitRounds();
		}
	}
}
string(string s) precache_model         = #20;

void() precaches =
{
	precache_model ("models/player.mdl");

#ifdef PC

	if (world.song != "")
		precache_sound (world.song);

#endif // PC

	//
	// Models
	//

	// sprites
	precache_model ("models/sprites/revive.spr");
	precache_model ("models/sprites/revive_white.spr");
	precache_model ("models/sprites/sprkle.spr");
	precache_model ("models/sprites/lightning.spr");
	precache_model ("models/sprites/null.spr");
	precache_model ("models/way/current_way.spr");
	precache_model ("models/way/current_way_door.spr");
	precache_model ("models/way/last_way.spr");
	precache_model ("models/way/last_way_door.spr");
	precache_model ("models/way/normal_way.spr");
	precache_model ("models/way/normal_way_door.spr");
	precache_model ("models/way/way_jump.spr");
	precache_model ("models/way/way_land.spr");

	// zombie
	precache_model ("models/ai/zfull.mdl");
	precache_model ("models/ai/zal(.mdl");
	precache_model ("models/ai/zar(.mdl");
	precache_model ("models/ai/zb%.mdl");
	precache_model ("models/ai/zh^.mdl");

	// zombie crawler
	precache_model ("models/ai/zcfull.mdl");
	precache_model ("models/ai/zbc%.mdl");
	precache_model ("models/ai/zalc(.mdl");
	precache_model ("models/ai/zarc(.mdl");
	precache_model ("models/ai/zhc^.mdl");

	// powerups
	precache_model ("models/sprites/explosion.spr");
	precache_model ("models/pu/perkbottle!.mdl");

	// start weapons
	precache_model ("models/weapons/m1911/v_colt.mdl");
	precache_model ("models/weapons/m1911/g_colt.mdl");
	precache_model ("models/weapons/knife/v_knife.mdl");
	precache_model ("models/weapons/grenade/v_grenade.mdl");
	precache_model ("models/weapons/grenade/g_grenade.mdl");
	precache_model ("models/weapons/grenade/g_betty.mdl");
	precache_model ("models/weapons/grenade/v_betty.mdl");
	precache_model ("models/weapons/morphine/v_morphine.mdl");

	//
	// Sounds
	//

	// player-made
#ifdef PC
	precache_sound("sounds/player/footstep1.wav");
	precache_sound("sounds/player/footstep2.wav");
	precache_sound("sounds/player/footstep3.wav");
	precache_sound("sounds/player/footstep4.wav");
	precache_sound("sounds/player/footstep5.wav");
	#endif // PC
	precache_sound("sounds/player/jump.wav");
	precache_sound("sounds/player/land.wav");
	precache_sound("sounds/player/pain4.wav");

	// weapons
	precache_sound("sounds/weapons/colt/magin.wav");
	precache_sound("sounds/weapons/colt/magout.wav");
	precache_sound("sounds/weapons/colt/shoot.wav");
	precache_sound("sounds/weapons/colt/slide.wav");
	precache_sound("sounds/weapons/papfire.wav");

	// grenade
	precache_sound("sounds/weapons/grenade/prime.wav");
	precache_sound("sounds/weapons/grenade/throw.wav");
	precache_sound("sounds/weapons/grenade/explode.wav");

	// melee
	precache_sound("sounds/weapons/knife/knife_hitbod.wav");
	precache_sound("sounds/weapons/knife/knife.wav");
	precache_sound("sounds/weapons/knife/knife_hit.wav");

	// tunes
	precache_sound("sounds/rounds/eround.wav");
	precache_sound("sounds/rounds/nround.wav");
	precache_sound("sounds/rounds/splash.wav");
	precache_sound("sounds/music/end.wav");

	// misc
	precache_sound("sounds/misc/buy.wav");
	precache_sound("sounds/misc/wood_door.wav");
	precache_sound("sounds/misc/debris.wav");
	precache_sound("sounds/misc/denybuy.wav");

	// power-ups
	precache_sound ("sounds/pu/pickup.wav");
	precache_sound ("sounds/pu/byebye.wav");
	precache_sound ("sounds/pu/powerup.wav");
	precache_sound ("sounds/pu/drop.wav");

	// zombie walk
	precache_sound ("sounds/zombie/w0.wav");
	precache_sound ("sounds/zombie/w1.wav");
	precache_sound ("sounds/zombie/w2.wav");
	precache_sound ("sounds/zombie/w3.wav");
	precache_sound ("sounds/zombie/w4.wav");
	precache_sound ("sounds/zombie/w5.wav");
	precache_sound ("sounds/zombie/w6.wav");
	precache_sound ("sounds/zombie/w7.wav");
	precache_sound ("sounds/zombie/w8.wav");
	precache_sound ("sounds/zombie/w9.wav");

	// zombie run
	precache_sound ("sounds/zombie/r0.wav");
	precache_sound ("sounds/zombie/r1.wav");
	precache_sound ("sounds/zombie/r2.wav");
	precache_sound ("sounds/zombie/r3.wav");
	precache_sound ("sounds/zombie/r4.wav");
	precache_sound ("sounds/zombie/r5.wav");
	precache_sound ("sounds/zombie/r6.wav");
	precache_sound ("sounds/zombie/r7.wav");
	precache_sound ("sounds/zombie/r8.wav");
	precache_sound ("sounds/zombie/r9.wav");

	// zombie swipe
	precache_sound ("sounds/zombie/a0.wav");
	precache_sound ("sounds/zombie/a1.wav");
	precache_sound ("sounds/zombie/a2.wav");
	precache_sound ("sounds/zombie/a3.wav");
	precache_sound ("sounds/zombie/a4.wav");
	precache_sound ("sounds/zombie/a5.wav");
	precache_sound ("sounds/zombie/a6.wav");
	precache_sound ("sounds/zombie/a7.wav");

	// zombie death
	precache_sound ("sounds/zombie/d0.wav");
	precache_sound ("sounds/zombie/d1.wav");
	precache_sound ("sounds/zombie/d2.wav");
	precache_sound ("sounds/zombie/d3.wav");
	precache_sound ("sounds/zombie/d4.wav");
	precache_sound ("sounds/zombie/d5.wav");
	precache_sound ("sounds/zombie/d6.wav");
	precache_sound ("sounds/zombie/d7.wav");

	// zombie taunt
	precache_sound ("sounds/zombie/t0.wav");
	precache_sound ("sounds/zombie/t1.wav");
	precache_sound ("sounds/zombie/t2.wav");
	precache_sound ("sounds/zombie/t3.wav");
	precache_sound ("sounds/zombie/t4.wav");

	// zombie footsteps
	precache_sound ("sounds/zombie/s0.wav");
	precache_sound ("sounds/zombie/s1.wav");
	precache_sound ("sounds/zombie/sc0.wav");
	precache_sound ("sounds/zombie/sc1.wav");

	// null
	precache_sound("sounds/null.wav");

	#ifdef PC
	// Moto -- FIXME: compile FTE to remove this engine sound request
	precache_sound ("demon/dland2.wav");
	#endif
}

//called when map loaded
void() worldspawn =
{
	precaches();

	// Define all of our Light Styles
	LS_Setup();

	// Init Power-Ups
	PU_Init();

	#ifdef PC
	clientstat(STAT_CURRENTMAG, EV_FLOAT, currentmag);
	clientstat(STAT_CURRENTMAG2, EV_FLOAT, currentmag2);
	clientstat(STAT_POINTS, EV_FLOAT, points);
	clientstat(STAT_WEAPON2FRAME, EV_FLOAT, weapon2frame);
	clientstat(STAT_WEAPON2MODEL, EV_STRING, weapon2model);
	clientstat(STAT_GRENADES, EV_FLOAT, primary_grenades);
	clientstat(STAT_SECGRENADES, EV_FLOAT, secondary_grenades);
	clientstat(STAT_PROGRESSBAR, EV_FLOAT, progress_bar_percent);
	clientstat(STAT_WEAPONDURATION, EV_FLOAT, weapon_animduration);
	clientstat(STAT_WEAPON2DURATION, EV_FLOAT, weapon2_animduration);
	clientstat(STAT_WEAPONZOOM, EV_FLOAT, zoom);
	clientstat(STAT_INSTA, EV_FLOAT, insta_icon);
	clientstat(STAT_X2, EV_FLOAT, x2_icon);
	clientstat(STAT_SPECTATING, EV_FLOAT, isspec);
	clientstat(STAT_PLAYERNUM, EV_FLOAT, playernum);		// literally useless but will be kept in case
	clientstat(STAT_PLAYERSTANCE, EV_FLOAT, stance);
	clientstat(STAT_FACINGENEMY, EV_FLOAT, facingenemy);
	clientstat(STAT_VIEWZOOM, EV_FLOAT, viewzoom);
	#endif

	mappath = strcat("maps/", mapname);
	mappath = strzone(mappath);

	LoadWaypointData();

	//set game elements
	G_STARTPOINTS = 500;
	G_STARTROUND = 1;
	G_PRONEPOINTS = 0;
	G_STARTWEAPON[0] = W_COLT;
	G_STARTWEAPON[1] = 8;
	G_STARTWEAPON[2] = 32;
	G_WORLDTEXT = 1;
	G_PERKS = 0;
	G_PERKPOWER = 0;
	load_nzd();

}

void() SpectatorConnect =
{
	bprint(PRINT_HIGH, self.netname);
	bprint(PRINT_HIGH, " has joined the spectators.\n");
}

void() RelinkZombies =
{
	entity ent,ent2;
	local float i;
	local vector min, max;


	//warn
	ent = ent2 = world;

	while ((ent = find (ent, classname, "ai_zombie")))
	{
		if(ent.currentHitBoxSetup == 0)//empty bbox, we don't care to update
			continue;

		makevectors (ent.angles);

		for(i = 0; i < 3; i++)
		{
			if(i == 0)
				ent2 = ent.head;
			if(i == 1)
				ent2 = ent.larm;
			if(i == 2)
				ent2 = ent.rarm;


			if (ent2)
			{
				//setorigin (ent.head, ent.origin + v_right * ent.head.view_ofs_x + v_forward * ent.head.view_ofs_y + v_up * ent.head.view_ofs_z);
				setorigin (ent2, ent.origin);
				//fixme, move angles set and frame set to below the continue, we only want to update origin (maybe angles too?)
				ent2.angles = ent.angles;

				if(ent2.deadflag)
					ent2.frame = ent.frame;

				//if(OnlyOrigin)
				//	continue;
				
				
				min = ent2.bbmins + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);
				max = ent2.bbmaxs + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);

				if(min_x > max_x) { min_x += max_x; max_x = min_x - max_x; min_x -= max_x; }
				if(min_y > max_y) { min_y += max_y; max_y = min_y - max_y; min_y -= max_y; }
				if(min_z > max_z) { min_z += max_z; max_z = min_z - max_z; min_z -= max_z; }

				setsize(ent2,min,max);
				
			}

		}
	}
}

void() LinkZombiesHitbox =
{
	entity ent,ent2;
	local float i;
	local vector min, max;


	//warn
	ent = ent2 = world;

	while ((ent = find (ent, classname, "ai_zombie")))
	{
		if(ent.currentHitBoxSetup == 0)//empty bbox, we don't care to update
			continue;

		makevectors (ent.angles);

		for(i = 0; i < 3; i++)
		{
			if(i == 0)
				ent2 = ent.head;
			if(i == 1)
				ent2 = ent.larm;
			if(i == 2)
				ent2 = ent.rarm;


			if (ent2)
			{
				ent2.angles = ent.angles;

				if(ent2.deadflag)
					ent2.frame = ent.frame;

				//if(OnlyOrigin)
				//	continue;
				
				
				min = ent2.bbmins + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);
				max = ent2.bbmaxs + (v_right * ent2.view_ofs_x) + (v_forward * ent2.view_ofs_y) + (v_up * ent2.view_ofs_z);

				if(min_x > max_x) { min_x += max_x; max_x = min_x - max_x; min_x -= max_x; }
				if(min_y > max_y) { min_y += max_y; max_y = min_y - max_y; min_y -= max_y; }
				if(min_z > max_z) { min_z += max_z; max_z = min_z - max_z; min_z -= max_z; }

				setsize(ent2,min,max);
				
			}

		}
	}
}

void() EndFrame =
{
	RelinkZombies();
};

//
// a large switch statement to convert asset paths made for
// older versions of nzp to the new standard
// TODO: add strlower or similar to all platforms.
//
string(string asset) convert_old_asset_path =
{
	switch(asset) {
		case "models/machines/quick_revive.mdl":
			return "models/machines/quake_scale/quick_revive.mdl";
		case "models/machines/juggernog.mdl":
			return "models/machines/quake_scale/juggernog.mdl";
		case "models/machines/speed_cola.mdl":
			return "models/machines/quake_scale/speed_cola.mdl";
		case "models/machines/double_tap.mdl":
			return "models/machines/quake_scale/double_tap.mdl";
		case "models/machines/flopper.mdl":
			return "models/machines/quake_scale/flopper.mdl";
		case "models/machines/staminup.mdl":
			return "models/machines/quake_scale/staminup.mdl";
		case "models/machines/deadshot.mdl":
			return "models/machines/quake_scale/deadshot.mdl";
		case "models/machines/mulekick.mdl":
			return "models/machines/quake_scale/mulekick.mdl";
		case "models/machines/pap.mdl":
			return "models/machines/quake_scale/pap.mdl";
		case "progs/Sprites/lamp_glow.spr":
			return "models/sprites/lamp_glow.spr";
		case "progs/Sprites/lamp_glow2.spr":
			return "models/sprites/lamp_glow2.spr";
		case "progs/Sprites/lamp_glow3.spr":
			return "models/sprites/lamp_glow.spr";
		case "progs/Props/Kino_boxes2.mdl":
		case "progs/props/kino_boxes2.mdl":
			return "models/props/Kino_boxes2.mdl";
		case "progs/props/kino_boxes3.mdl":
			return "models/props/Kino_boxes3.mdl";
		case "progs/Props/Kino_boxes4.mdl":
		case "progs/props/kino_boxes4.mdl":
			return "models/props/Kino_boxes4.mdl";
		case "progs/props/Kino_box.mdl":
		case "progs/props/kino_box.mdl":
		case "progs/Props/Kino_box.mdl":
			return "models/props/Kino_box.mdl";
		case "progs/Props/table_dinner.mdl":
			return "models/props/table_dinner.mdl";
		case "progs/Props/table_sq.mdl":
			return "models/props/table_sq.mdl";
		case "progs/Props/Kino_table.mdl":
		case "progs/props/kino_table.mdl":
			return "models/props/Kino_table.mdl";
		case "progs/props/kino_couch.mdl":
			return "models/props/kino_couch.mdl";
		case "progs/Props/metal_chair.mdl":
			return "models/props/metal_chair.mdl";
		case "progs/Props/sandbags.mdl":
		case "progs/props/sandbags.mdl":
			return "models/props/sandbags.mdl";
		case "progs/Props/shelf.mdl":
		case "progs/props/shelf.mdl":
			return "models/props/shelf.mdl";
		case "progs/Props/dummy.mdl":
		case "progs/props/dummy.mdl":
			return "models/props/dummy.mdl";
		case "progs/props/stand.mdl":
			return "models/props/stand.mdl";
		case "progs/Props/radio.mdl":
			return "models/props/radio.mdl";
		case "progs/Props/radiator.mdl":
			return "models/props/radiator.mdl";
		case "progs/Props/lamp_ndu.mdl":
		case "progs/props/lamp_ndu.mdl":
			return "models/props/lamp_ndu.mdl";
		case "progs/Props/piano.mdl":
			return "models/props/piano.mdl";
		case "progs/props/teleporter.mdl":
			return "models/props/teleporter.mdl";
		case "progs/props/chandelier.mdl":
			return "models/props/chandelier.mdl";
		case "progs/props/vanity_table.mdl":
			return "models/props/vanity_table.mdl";
		case "progs/props/trash_con.mdl":
			return "models/props/trash_con.mdl";
		case "progs/props/kino_chairset.mdl":
			return "models/props/kino_chairset.mdl";
		case "progs/props/Kino_lounge.mdl":
			return "models/props/Kino_lounge.mdl";
		case "progs/props/kino_stageprop.mdl":
			return "models/props/kino_stageprop.mdl";
		case "progs/props/mainframe_pad.mdl":
			return "models/props/mainframe_pad.mdl";
		case "progs/Gmodels/g_mp40.mdl":
		case "progs/gmodels/g_mp40.mdl":
			return "models/weapons/mp40/g_mp40.mdl";
		case "progs/gmodels/g_thomp.mdl":
			return "models/weapons/thomp/g_thomp.mdl";
		case "progs/Gmodels/g_betty.mdl":
		case "progs/gmodels/g_betty.mdl":
			return "models/weapons/grenade/g_betty.mdl";
		case "progs/GModels/g_fg.mdl":
			return "models/weapons/fg42/g_fg.mdl";
		case "progs/gmodels/g_m1.mdl":
			return "models/weapons/garand/g_m1.mdl";
		case "progs/gmodels/g_trench.mdl":
			return "models/weapons/trench/g_trench.mdl";
		case "progs/gmodels/g_bar.mdl":
			return "models/weapons/bar/g_bar.mdl";
		case "progs/gmodels/g_grenade.mdl":
			return "models/weapons/grenade/g_grenade.mdl";
		case "progs/gmodels/g_gewehr.mdl":
			return "models/weapons/gewehr/g_gewehr.mdl";
		case "progs/gmodels/g_bowie.mdl":
			return "models/weapons/knife/g_bowie.mdl";
		case "progs/gmodels/g_type.mdl":
			return "models/weapons/type/g_type.mdl";
		case "progs/gmodels/g_stg.mdl":
			return "models/weapons/stg/g_stg.mdl";
		case "models/misc/lightning.spr":
			return "models/sprites/lightning.spr";
		default: return asset;
	}

	return asset;
};
