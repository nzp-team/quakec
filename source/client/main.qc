/*
	client/main.qc

	main csqc code

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

void() ToggleMenu =
{
	if(serverkey("constate") != "disconnected")
	{
		if (player_count == 0)
			localcmd("cmd pause\n");
		if(in_menu == MENU_NONE)
		{
			in_menu = MENU_PAUSE;
			time_in_menu = 0;
			local float i;
			for(i = 0; i < BUTTONS_COUNT; i++)
			{
				buttons[i].active = 1;
			}
			setcursormode(TRUE, cvar_string("cl_cursor"), __NULL__, cvar("cl_cursor_scale"));
		}
		else
		{
			in_menu = MENU_NONE;
			setcursormode(FALSE);
		}
	}
	else
	{
		in_menu = MENU_MAIN;
		time_in_menu = 0;
		setcursormode(TRUE, cvar_string("cl_cursor"), __NULL__, cvar("cl_cursor_scale"));
	}
}

noref void(float apiver, string enginename, float enginever) CSQC_Init =
{
	setwindowcaption("Nazi Zombies: Portable");
	
	precache_sound("sounds/menu/enter.wav");
	precache_sound("sounds/menu/navigate.wav");
	precache_model("models/player.mdl");

	registercommand("togglemenu");
	registercommand("startwalk");
	registercommand("stopwalk");
	registercommand("promptjoin");
	registercommand("showscores");

	cvar_set("sv_cheats", ftos(1));
	cvar_set("r_fb_models", ftos(0));
	autocvar(r_viewmodel_default_fov, 70);

	// Runtime check if we're running this in WebASM/WebGL.
	if (cvar_string("sys_platform") == "Web")
		platform_is_web = true;
	else
		platform_is_web = false;

	if (platform_is_web) {
		cvar_set("com_protocolname", "NZP-REBOOT-WEB");
	}
		
	//print("CSQC Started\n");
	dummy = spawn();
	if(serverkey("constate") == "disconnected")
		ToggleMenu();
	//bgpos = 0;

	// default button binds

	buttonBind[0] = "+forward";
	buttonBind[1] = "+back";
	buttonBind[2] = "+moveleft";
	buttonBind[3] = "+moveright";
	buttonBind[4] = "impulse 10";
	buttonBind[5] = "+sprint";
	buttonBind[6] = "impulse 30";
	buttonBind[7] = "impulse 110";
	buttonBind[8] = "impulse 111";
	buttonBind[9] = "+button7";
	buttonBind[10] = "+button5";
	buttonBind[11] = "+button6";
	buttonBind[12] = "+button3";
	buttonBind[13] = "impulse 33";

	// default/current width and height
	active_swidth = cvar("vid_width");
	active_sheight = cvar("vid_height");
	fullscreenval = cvar("vid_fullscreen");

	// cvars for custom settings
	autocvar(cl_adsmode, 0);
	autocvar(cl_cinematic, 0);
	autocvar(nzp_particles, 1);
	autocvar(nzp_decals, 1);
	autocvar(vid_ultrawide_limiter, 0);

	// per-channel volume
	autocvar(snd_channel1volume, 1);
	autocvar(snd_channel2volume, 1);
	autocvar(snd_channel3volume, 1);
	autocvar(snd_channel4volume, 1);
	autocvar(snd_channel5volume, 1);
	autocvar(snd_channel6volume, 1);

	// force nearest filtering for hud elements to avoid blur
	cvar_set("gl_texturemode2d", "gl_nearest");
	cvar_set("r_font_linear", "0");

	// force build date text in menu
	cvar_set("cl_showbuildtime", "1");

	// in-game stopwatch
	autocvar(scr_serverstopwatch, 0);
	stopwatch_sec = stopwatch_min = stopwatch_hr = 0;
	stopwatch_round_sec = stopwatch_round_min = stopwatch_round_hr = 0;
	stopwatch_round_starttime = time;

	// retrieve custom maps
	Customs_Get();

	//
	// get the build date
	//
	float file = fopen("version.txt", FILE_READ);

	if (file != -1) {
		build_datetime = fgets(file);
		fclose(file);
	}
};

//
// Init_Particles()
// Spawns a dummy particle for each effect
// so it loads. (FIXME - is there a better
// way?)
//
void() Init_Particles =
{
	for(int i = 0; i < 3; i++) {
		pointparticles(particleeffectnum(strcat("muzzle.muzzle_pap_part", itos(i))), '0 0 0', '0 0 0', 0);
		pointparticles(particleeffectnum(strcat("muzzle.muzzle_part", itos(i))), '0 0 0', '0 0 0', 0);
	}					
	pointparticles(particleeffectnum("weapons.impact"), '0 0 0', '0 0 0', 0);
	pointparticles(particleeffectnum("weapons.impact_decal"), '0 0 0', '0 0 0', 0);
	pointparticles(particleeffectnum("weapons.explode"), '0 0 0', '0 0 0', 0);
	pointparticles(particleeffectnum("blood.blood_particle"), '0 0 0', '0 0 0', 0);
}

noref void() CSQC_WorldLoaded =
{
	//precache_model("models/weapons/mg/mzl.iqm");
	//precache_model("models/blood.iqm");
	
	if(!player)
		player = findfloat(world, entnum, player_localnum);
	if(!vmodel)
		vmodel = spawn();
	if(!v2model)
		v2model = spawn();
	if(!mzlflash)
		mzlflash = spawn();
		
	v2model.renderflags = vmodel.renderflags = RF_VIEWMODEL;
	v2model.origin = vmodel.origin = '24 -12 -18';
	v2model_targetpos = v2model_currentpos = v2model.origin = vmodel_targetpos = vmodel_currentpos = vmodel.origin;
	v2model_velocity = vmodel_velocity = '0 0 0';
	//v2model_muzzleoffset = vmodel_muzzleoffset = '48 -1 2';
	setmodel(vmodel,"");
	setmodel(v2model,"");
	mzlflash.renderflags = vmodel.renderflags;
	mzlflash.origin = vmodel.origin + vmodel_muzzleoffset;

	Achievement_Init();
	Init_Particles();
	nameprint_time = time + 12;

	huddir = "gfx/hud/";
};

// This is from COW lol!
#define ADS_THOMPSON    '-3 +5.80 +4.52'

/*vector adsOffset;
float adsAmount;
float adsDir;*/
vector weapon_bob_factor;
float weapon_bob_factor_z_coef;
vector dampening_factor;
float vaccel;
float vzaccel;
void() Update_Vmodel =
{
	local vector offset, adsoffset;
	local vector dir;
    local float ads;

	if (cvar("r_drawviewmodel") == FALSE || hide_viewmodel == true) {
		vmodel.origin = '-10000 -10000 -10000';
		return;
	}

//
// View Bobbing Factors.
//

	// PAUSED, NO BOB
	if (serverkey(SERVERKEY_PAUSESTATE) == "1") {
		weapon_bob_factor = '0 0 0';
		dampening_factor = weapon_bob_factor;
		weapon_bob_factor_z_coef = 0;
	}
	// ADS
	else if (getstatf(STAT_WEAPONZOOM) && getstatf(STAT_WEAPONZOOM) != 3) {
		weapon_bob_factor = '0 0 0';
		dampening_factor = weapon_bob_factor;
		weapon_bob_factor_z_coef = 0;
	} 
	// SPRINT
	else if (getstatf(STAT_WEAPONZOOM) == 3) {
		weapon_bob_factor_x = 2;
		weapon_bob_factor_y = 8;
		weapon_bob_factor_z = 12;
		weapon_bob_factor_z_coef = 1;
		
		dampening_factor_x = sin(cltime*weapon_bob_factor_x);
		dampening_factor_y = 9*cos(cltime*weapon_bob_factor_y);
		dampening_factor_z = 0.1*sin(cltime*weapon_bob_factor_z);
	}
	// WALK
	else if (K_FORWARDDOWN || K_BACKDOWN || K_LEFTDOWN || K_RIGHTDOWN && !getstatf(STAT_WEAPONZOOM)) {
		weapon_bob_factor_x = 8;
		weapon_bob_factor_y = 8;
		weapon_bob_factor_z = 13.4;
		weapon_bob_factor_z_coef = 0.2;
		
		dampening_factor_x = 0.2*sin(cltime*weapon_bob_factor_x);
		dampening_factor_y = 0.2*cos(cltime*weapon_bob_factor_y);
		dampening_factor_z = 0.2*sin(cltime*weapon_bob_factor_z);
	}
	// STILL
	else if (!getstatf(STAT_WEAPONZOOM)) {

		// HACK HACK
		if (weapon_bob_factor_z == 12) {
			weapon_bob_factor_x = 8;
			weapon_bob_factor_y = 8;
			weapon_bob_factor_z = 13.4;
			weapon_bob_factor_z_coef = 0.2;
			
			dampening_factor_x = 0.2*sin(cltime*weapon_bob_factor_x);
			dampening_factor_y = 0.2*cos(cltime*weapon_bob_factor_y);
			dampening_factor_z = 0.2*sin(cltime*weapon_bob_factor_z);
		}

		// Naievil -- stupid ass calcs...
		// Basically we have a dampening factor per offset and we have to decrease it back down to zero
		// Problem is that we may be going in postive OR negative direction? 
		// Better solution: use fabs() lol 
		if (dampening_factor_x > 0 && sin(time*weapon_bob_factor_x) > 0) {
			if ((dampening_factor_x - 0.00000068* sin(time*weapon_bob_factor_x)) < 0)
				dampening_factor_x -= (0.00000068 - dampening_factor_x*sin(time*weapon_bob_factor_x));
			else 
				dampening_factor_x -= 0.00000068* sin(time*weapon_bob_factor_x);
				
		} else if (dampening_factor_x < 0 && sin(time*weapon_bob_factor_x) < 0) {
			if ((dampening_factor_x + 0.00000068* sin(time*weapon_bob_factor_x)) > 0)
				dampening_factor_x += (0.00000068 - dampening_factor_x*sin(time*weapon_bob_factor_x));
			else 
				dampening_factor_x += 0.00000068* sin(time*weapon_bob_factor_x);
		} else {
			weapon_bob_factor_x = 1.2;
		}
					
		if (weapon_bob_factor_x - 0.00000068 < 1.2)
			weapon_bob_factor_x = 1.2;
		else 
			weapon_bob_factor_x -= 0.00000068;
	
		
		if (dampening_factor_y > 0 && cos(time*weapon_bob_factor_y) > 0) {
			if ((dampening_factor_y - 0.00000065* cos(time*weapon_bob_factor_y)) < 0)
				dampening_factor_y -= (0.00000065 - dampening_factor_y*cos(time*weapon_bob_factor_y));
			else 
				dampening_factor_y -= 0.00000065* cos(time*weapon_bob_factor_y);		
				
		} else if (dampening_factor_y < 0 && cos(time*weapon_bob_factor_y) < 0) {
			if ((dampening_factor_y + 0.00000065* cos(time*weapon_bob_factor_y)) > 0)
				dampening_factor_y += (0.00000065 - dampening_factor_y*cos(time*weapon_bob_factor_y));
			else 
				dampening_factor_y += 0.00000065* cos(time*weapon_bob_factor_y);		
		} else {
			weapon_bob_factor_y = 1.5;
		}
		
		
		if (weapon_bob_factor_y - 0.00000065 < 1.5)
			weapon_bob_factor_y = 1.5;
		else 
			weapon_bob_factor_y -= 0.00000065;	
		
		if (dampening_factor_z > 0 && sin(time*weapon_bob_factor_z) > 0) {
			if ((dampening_factor_z - 0.00000123* sin(time*weapon_bob_factor_z)) < 0)
				dampening_factor_z -= (0.00000123 - dampening_factor_z*sin(time*weapon_bob_factor_z));
			else 
				dampening_factor_z -= 0.00000123* sin(time*weapon_bob_factor_z);	
				
		} else if (dampening_factor_z <= 0 && sin(time*weapon_bob_factor_z) < 0) {
			if ((dampening_factor_z + 0.00000123* sin(time*weapon_bob_factor_z)) > 0)
				dampening_factor_z += (0.00000123 - dampening_factor_z*sin(time*weapon_bob_factor_z));
			else 
				dampening_factor_z += 0.00000123* sin(time*weapon_bob_factor_z);
		} else  {
			weapon_bob_factor_z = 1.1;
		}
		
		if (weapon_bob_factor_z - 0.00000123 < 1.1)
			weapon_bob_factor_z = 1.1;
		else 
			weapon_bob_factor_z -= 0.00000123;	
		
		if (weapon_bob_factor_z_coef <= 0.1)
			weapon_bob_factor_z_coef = 0.1;
		else 
			weapon_bob_factor_z_coef -= 0.0000001*sin(time*weapon_bob_factor_z);
	}
			
	offset_x = 0.2 * (sin(cltime * weapon_bob_factor_x) + dampening_factor_x);
	offset_y = 0.2 * (cos(cltime * weapon_bob_factor_y) + dampening_factor_y);
	offset_z = weapon_bob_factor_z_coef * (sin(weapon_bob_factor_z*cltime + 0.5) + dampening_factor_z);
	
	vector tempv; 
	tempv_x = 0.2 * (sin(cltime * weapon_bob_factor_x));
	tempv_y = 0.2 * (cos(cltime * weapon_bob_factor_y));
	tempv_z = weapon_bob_factor_z_coef * (sin(weapon_bob_factor_z*cltime + 0.5));
		
	dir = vmodel_targetpos - vmodel_currentpos;
	if(vlen(dir) < (0.15 * 128 * frametime))
		vmodel_currentpos = vmodel_targetpos;
	else
		vmodel_currentpos += (dir * 0.15 * 128) * frametime;
	

	if(vlen(vmodel.angles) < (0.1 * 128 * frametime))
		vmodel.angles = '0 0 0';
	else
		vmodel.angles += (-vmodel.angles * 0.2 * 128) * frametime;

	vmodel_currentpos += (vmodel_velocity * 128) * frametime;
	vmodel_velocity *= 1 - frametime * 30;
	
	vmodel.angles += (vmodel_avelocity * 128) * frametime;
	vmodel_avelocity *= 1 - frametime * 30;
	
	adsoffset = GetWeaponADSPos(weapon);

    ads = getstatf(STAT_WEAPONZOOM); //get the zoomtoggle value 
    if(ads == 1 || ads == 2 && serverkey(SERVERKEY_PAUSESTATE) == "0")
    {
        vmodel_currentpos += (adsoffset * 0.15 * 128) * frametime;
        vmodel.origin = vmodel_currentpos + adsoffset;
    }
    else
    {
        switch(getstatf(STAT_PLAYERSTANCE)) {
			case 2:
				break;
			case 1:
				vmodel_currentpos = '0 0.6 -0.3';
				break;
			case 0:
				vmodel_currentpos = '1.5 0.6 -0.3';
				break;
			default: break;
		}
		vmodel.origin = vmodel_currentpos + offset;

		vmodel.origin_y += vaccel;
		vmodel.origin_z += vzaccel;

		if (in_menu != MENU_NONE)
			return;

		if (K_LEFTDOWN) {
			vaccel -= 0.01;
			if (vaccel < -0.8) 
				vaccel = -0.8;
		} else if (K_RIGHTDOWN) {
			vaccel += 0.01;
			if (vaccel > 0.8)
				vaccel = 0.8;
		} else if (vaccel != 0) {
			if (vaccel > 0)
				vaccel -= 0.01;
			else
				vaccel += 0.01;
		}

		//black ops -0.01 till -0.6 (looks better)
		if (K_BACKDOWN || K_FORWARDDOWN) {
			if (ads == 3) {
				vzaccel -= 0.1;

				if (vzaccel < -1.2)
					vzaccel = -1.2;
			} else {
				vzaccel -= 0.01;

				if (vzaccel < -0.6)
					vzaccel = -0.6;
			}
			
		} else if (vzaccel != 0) {
			if (vzaccel > 0)
				vzaccel -= 0.02;
			else
				vzaccel += 0.02;
		}

    }


	if(weapon == 1)
	{
		if(mzlflash.scale < 1)
			mzlflash.scale += (10 * random()) * frametime;
	}
	else if(weapon == 2)
	{
		if(mzlflash.scale < 1.5)
			mzlflash.scale += (20 * random()) * frametime;
	}
	mzlflash.origin = vmodel.origin + vmodel_muzzleoffset;
	mzlflash.alpha -= (0.15 * 100) * frametime;
	if(mzlflash.alpha < 0.1)
		mzlflash.alpha = 0.01;
}

float Player_PreDraw() =
{
	self.lerpfrac -= frametime*10;
	while(self.lerpfrac < 0) {
		self.frame2 = self.frame;
		self.lerpfrac += 1;
	}

    if (self.entnum == player_localentnum) {
        self.movetype = MOVETYPE_WALK;
		// Prepare rollback
		vector vOldOrigin = self.origin;
		vector vOldVelocity = self.velocity;
		float fOldPMoveFlags = self.pmove_flags;

		// Apply physics for every single input-frame that has not yet been
		// acknowledged by the server (servercommandframe = last acknowledged frame)
		for (int i = servercommandframe + 1; i <= clientcommandframe; i++) {
		float flSuccess = getinputstate(i);

			if (flSuccess == FALSE) {
				continue;
			}

			// Partial frames are the worst
			if (input_timelength == 0) {
				break;
			}
			runstandardplayerphysics(self);
		}
				
		// Smooth stair stepping, this has to be done manually!
		playerOriginOld = playerOrigin;
				
		if ((self.flags & FL_ONGROUND) && (self.origin_z - playerOriginOld_z > 0)) {
			playerOriginOld_z += frametime * 150;
					
			if (playerOriginOld_z > self.origin_z) {
				playerOriginOld_z = self.origin_z;
			}
			if (self.origin_z - playerOriginOld_z > 18) {
				playerOriginOld_z = self.origin_z - 18;
			}
			playerOrigin_z += playerOriginOld_z - self.origin_z;
		} else {
			playerOriginOld_z = self.origin_z;
		}
			
		playerOrigin = [self.origin_x, self.origin_y, playerOriginOld_z];
		playerVelocity = self.velocity;
		addentity(self);

		// Time to roll back
		self.origin = vOldOrigin;
		setorigin(self, self.origin);
		self.velocity = vOldVelocity;
		self.pmove_flags = fOldPMoveFlags;
		self.movetype = MOVETYPE_NONE;

		// Set renderflag for mirrors!
		self.renderflags = RF_EXTERNALMODEL;
    } else {
        addentity(self);
    }
    return PREDRAW_NEXT;
}

noref void(float isnew) CSQC_Ent_Update =
{
	float ent_type = readbyte();

	if (ent_type == 1) {
		if (isnew == TRUE) {
			self.classname = "player";
			self.solid = SOLID_SLIDEBOX;
			self.predraw = Player_PreDraw;
			self.drawmask = MASK_ENGINE;
			setmodel(self, "models/player.mdl");
		}

		float old_points = self.points;
			
		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
		self.angles_x = readangle();
		self.angles_y = readangle();
		self.angles_z = readangle();
		self.velocity_x = readshort();
		self.velocity_y = readshort();
		self.velocity_z = readshort();
		self.playernum = readbyte();
		self.modelindex = readshort();
		self.frame = readbyte();
		self.movetype = readshort();
		self.flags = readshort();
		self.stance = readbyte();
		self.points = readfloat();	// FIXME: this should be made a short, but I know we use price of 1 for some test maps, so I can't do /10 *10 shenanigans.
		self.kills = readshort();

		RegisterPointChange(self.points - old_points, self.playernum);

		if (self.movetype == MOVETYPE_BOUNCE)
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_SLIDEBOX;
			
		setmodelindex(self, self.modelindex);
		if (self.stance == 2)
			setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
		else
			setsize(self, PLAYER_MINS_CROUCHING, PLAYER_MAXS_CROUCHING);

	} else {
		if(isnew)
			addentity(self);
	}
}

float(__inout vector v) VectorNormalize =
{
	float length = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);

	if (length)
	{
		float ilength = 1 / length;
		v[0] *= ilength;
		v[1] *= ilength;
		v[2] *= ilength;
	}
		
	return length;
}

void() DropRecoilKick =
{
	float	len;

	if (crosshair_spread_time > time)
		return;

	len = VectorNormalize(gun_kick);

	len = len - frametime*5;
	if (len < 0)
		len = 0;

	gun_kick[0] *= len;
	gun_kick[1] *= len;
	gun_kick[2] *= len;
}

string() LoadScreen_GiveTip =
{
	float index = rint((random() * (80 - 1))) + 1;

	switch(index)
    {
        case 1:
			return  "Released in 1996, Quake is over 25 years old!";
        case 2:
            return  "Use the Kar98k to be the hero we need!";
        case 3:
            return  "Lots of modern engines are based on Quake!";
        case 4:
            return  "NZ:P began development on September 27 2009!";
        case 5:
            return  "NZ:P was first released on December 25, 2010!";
        case 6:
            return  "NZ:P Beta 1.1 has over 300,000 downloads!";
        case 7:
            return  "NZ:P has been downloaded over 500,000 times!";
        case 8:
            return  "A lot of people have worked on NZ:P!";
        case 9:
            return  "Blubswillrule, or \"blubs\", is from the US.";
        case 10:
            return  "Jukki is from Finland.";
        case 11:
            return  "Ju[s]tice, or \"tom\" is from Lithuania.";
        case 12:
            return  "This game has given us bad sleeping habits!";
        case 13:
            return  "We had a lot of fun making this game!";
        case 14:
            return  "Pro Tip: you can make your own custom map!";
        case 15:
            return  "Try Retro Mode, it's in the Graphics Settings!";
        case 16:
			return  "Tired of our maps? Go make your own!";
        case 17:
            return  "Slay zombies & be grateful.";
        case 18:
            return  "Custom maps, CUSTOM MAPS!";
        case 19:
            return  "Go outside & build a snowman!";
        case 20:
            return  "Please surround yourself with zombies!";
        case 21:
            return  "Don't play for too long.. zombies may eat you.";
        case 22:
            return  "That was epic... EPIC FOR THE WIIIN!"; //why
        case 23:
            return  "FTEQW is an awesome Quake Engine!";
        case 24:
            return  "You dead yet?";
        case 25:
            return  "Now 21% cooler!";
        case 26:
            return  "your lg is nothink on the lan!"; //what
        case 27:
            return  "I'm not your chaotic on dm6!"; 
        case 28:
            return  "Shoot or knife zombies to kill them, up to you!";
        case 29:
            return 	"How many people forgot to Compile today?";
        case 30:
            return  "ggnore";
        case 31:
			return  "NZ:P is also on PC, Switch, Vita, and PSP!";
        case 32:
            return  "Submerge your device in water for godmode!";
        case 33:
            return  "10/10/10 was a good day.";
        case 34:
            return  "Also check out \"FreeCS\" by eukara!";
        case 35:
            return 	"CypressImplex, or \"Ivy\", is from the USA.";
        case 36:
            return  "Zombies don't like bullets.";
        case 37:
            return  "Thanks for being an awesome fan!";
		case 38:
			return 	"Removed Herobrine";
		case 39:
			return 	"Pack-a-Punch the Kar98k to get to round 100000.";
		case 40:
			return 	"I feel like I'm being gaslit.";
		case 41:
			return 	"Heads up! You will die if you are killed!";
		case 42:
			return 	"Zombies legally can't kill you if you say no!";
		case 43:
			return 	"Please help me find the meaning of   . Thanks.";
		case 44:
			return  "Discord is ONLY for Thomas the Tank Engine RP!";
		case 45:
			return 	"\"Get rid of the 21% tip, it's an MLP reference.\"";
		case 46:
			return 	"You're playing on FTE!";
		case 47:
			return 	"Don't leak the beta!";
		case 48:
			return  "Jugger-Nog increases your health!";
		case 49:
			return  "greg was here";
		case 50:
			return  "Where the hell is the Mystery Box?!";
		case 51:
			return  "Zombies like getting shot.. I think.";
		case 52:
			return  "pro tip: aiming helps";
		case 53:
			return  "\"my mom gave me plunger money\"";
		case 54:
			return "dolphin dive on top of your friend for god mode";
		case 55:
			return "no free rides. ass, grass, or cash!";
		case 56:
			return "https://nzp.gay/";
		case 57:
			return "im an mlg gamer girl so its pretty guaranteed";
		case 58:
			return "this is a w because you cant have enough fnaf";
		case 59:
			return "i hope santa drops bombs on the uk";
		case 60:
			return "Hoyl shit, bro! You fucking ported fortnite!";
		case 61:
			return "icarly feet futtishist.";
		case 62:
			return "Well, it's impossible to play, I'm disgusted.";
		case 63:
			return "I like my women to not be cartoons";
		case 64:
			return "Plot twist: NZP was always broken";
		case 65:
			return "testing some think.";
		case 66:
			return "fnaf is older than gay marriage in the us";
		case 67:
			return "i want that twink Obliterated";
		case 68:
			return "i think he started the femboy transition process";
		case 69:
			return "nice";
		case 70:
			return "He's FUCKING annoying";
		case 71:
			return "yeah pog female bikers";
		case 72:
			return "Its either a stroke of genius or just a stroke";
		case 73:
			return  "Play some Custom Maps!";
		case 74:
			return  "Real OGs play on Win9X Machines!";
		case 75:
			return  "Adding this tip improved framerate by 39%!";
		case 76:
			return  "The NZ in NZP stands for New Zealand!";
		case 77:
			return  "The P in NZP stands for Professional!";
		case 78:
			return  "Remember to stay hydrated!";
		case 79:
			return  "cofe";
    }
    return "wut wut";
};

noref void(float width, float height, float notmenu) CSQC_UpdateViewLoading =
{
	if (loadscreen_mapname != "") {
		drawpic([0, 0], strcat("gfx/lscreen/", loadscreen_mapname), [width, height], [1, 1, 1], 1);
	}

	drawfill ([0, 0], [width, 32, 1], [0, 0, 0], 0.68, 0);
	drawfill ([0, height - 32], [width, 32, 1], [0, 0, 0], 0.68, 0);

	drawstring([width/2 - (stringwidth(loadscreen_tip, 0, [12, 12])/2), height - 16, 0], loadscreen_tip, [12, 12], [1, 1, 1], 1, 0);
	drawstring([6, 6], loadscreen_maptitle, [24, 24], TEXT_ORANGE, 1, 0);

	drawfill ([width/2 - 160, height - 42], [320, 18, 1], [0.27, 0.27, 0.27], 1, 0);
	drawfill ([width/2 - 164, height - 46], [328, 26, 1], [0, 0, 0], 0.77, 0);
	drawstring([width/2 - (stringwidth("Loading...", 0, [14, 14])/2), height - 40, 0], "Loading...", [14, 14], [1, 1, 1], 1, 0);
};

#define SCALE_CONSTANT 		8

// CALLED EVERY CLIENT RENDER FRAME
float pap_flash_alternate;
noref void(float width, float height, float menushown) CSQC_UpdateView =
{
	//clear and update our global screen resolution vars
	clearscene();
	g_width = width;
	g_height = height;
	
	// camang is controlled by our punchangles
	camang = getproperty(VF_ANGLES);
	
	//disable quake status bar and quake crosshair
	setviewprop(VF_DRAWENGINESBAR, 0);	
	setviewprop(VF_DRAWCROSSHAIR, 0);

	setsensitivityscaler((1 + SCALE_CONSTANT * getstatf(STAT_VIEWZOOM)) / (1 + SCALE_CONSTANT));
	setviewprop(VF_AFOV, autocvar(fov,90)*getstatf(STAT_VIEWZOOM));

	cvar_set("r_viewmodel_fov", ftos(cvar("r_viewmodel_default_fov")*getstatf(STAT_VIEWZOOM)));

	// Increment the stopwatch
	// FIXME: I don't really liket his being in UpdateView.. this has nothing to do with rendering.
	stopwatch_sec = time - (stopwatch_min * 60 + (stopwatch_hr * 3600));

	if (stopwatch_sec >= 60) {
		stopwatch_min += stopwatch_sec/60;
	}

	if (stopwatch_min >= 60) {
		stopwatch_hr += stopwatch_min/60;
		stopwatch_min = 0;
	}

	if (stopwatch_round_isactive) {
		stopwatch_round_sec = (time - stopwatch_round_starttime) - (stopwatch_round_min * 60 + (stopwatch_round_hr * 3600));

		if (stopwatch_round_sec >= 60) {
			stopwatch_round_min += stopwatch_round_sec/60;
		}

		if (stopwatch_round_min >= 60) {
			stopwatch_round_hr += stopwatch_round_min/60;
			stopwatch_round_min = 0;
		}
	} else {
		stopwatch_round_starttime = time;
	}

	//autoadd entities received from servers for drawing	
	addentities(MASK_ENGINE);

	setproperty(VF_ORIGIN, playerOrigin + [ 0, 0, getstatf(STAT_VIEWHEIGHT)]);
	//setproperty(VF_ANGLES, view_angles);

	//do viewmodel manipulation, purely cosmetic stuff
	if(vmodel)
	{
		Update_Vmodel();
		local vector vorg;
		local vector vang;
		vorg = getviewprop(VF_ORIGIN);
		vang = getviewprop(VF_ANGLES);
		//vmodel.origin += vorg;
		//vmodel.angles += vang;
		addentity(vmodel);
		addentity(v2model);
		//vmodel.origin -= vorg;
		//vmodel.angles -= vang;
		//addentity(vmodel);
		float weaponframe, weapon2frame;
		weaponframe = getstatf(STAT_WEAPONFRAME);

		float duration = getstatf(STAT_WEAPONDURATION);

		if (!duration) {
			duration = 0.1;
		}
		
		if (curweaponframe != weaponframe) {
			interpolating = TRUE;
			vmodel.lerpfrac = 0;
			oldweaponframe = curweaponframe;
			curweaponframe = weaponframe;
		}
		
		if (interpolating == TRUE) {
			vmodel.lerpfrac += frametime * (1/duration);

			if (vmodel.lerpfrac >= 1.0) {
				oldweaponframe = curweaponframe;
				vmodel.lerpfrac = 0;
				interpolating = FALSE;	
			}
			
		}
		vmodel.frame = oldweaponframe;
		vmodel.frame2 = curweaponframe;

		if (IsDualWeapon(getstatf(STAT_ACTIVEWEAPON))) {
			float duration2 = getstatf(STAT_WEAPON2DURATION);
			if (!duration2) {
				duration2 = 0.1;
			}
			weapon2frame = getstatf(STAT_WEAPON2FRAME);
			if (curweapon2frame != weapon2frame) {
				interpolating2 = TRUE;
				v2model.lerpfrac = 0;
				oldweapon2frame = curweapon2frame;
				curweapon2frame = weapon2frame;
			}
			
			if (interpolating2 == TRUE) {
				v2model.lerpfrac += frametime * (1/duration2);

				if (v2model.lerpfrac >= 1.0) {
					oldweapon2frame = curweapon2frame;
					v2model.lerpfrac = 0;
					interpolating2 = FALSE;	
				}
				
			}

			v2model.frame = oldweapon2frame;
			v2model.frame2 = curweapon2frame;

		} else {
			//v2model.frame = getstatf(STAT_WEAPON2FRAME);
			v2model.lerpfrac = vmodel.lerpfrac;
			v2model.frame = oldweaponframe;
			v2model.frame2 = curweaponframe;
		}
		v2model.angles = vmodel.angles;
		v2model.origin = vmodel.origin;
		if(mzlflash.alpha > 0.09)
		{
			makevectors(view_angles);
			local vector offset = vmodel.origin + vmodel_muzzleoffset;
			local vector muzzlepos;
			muzzlepos = getviewprop(VF_ORIGIN);
			muzzlepos += v_forward * offset_x;
			muzzlepos -= v_right * offset_y;
			muzzlepos += v_up * (offset_z + 6);

			if (cvar("r_drawviewmodel")) {
				if (IsPapWeapon(getstatf(STAT_ACTIVEWEAPON))) {
					if (pap_flash_alternate)
						dynamiclight_add(muzzlepos, 128 * mzlflash.alpha, '0.7 0 0' * mzlflash.alpha);
					else
						dynamiclight_add(muzzlepos, 128 * mzlflash.alpha, '0 0 0.7' * mzlflash.alpha);

					pap_flash_alternate = !pap_flash_alternate;
				}	
				else
					dynamiclight_add(muzzlepos, 128 * mzlflash.alpha, '1.2 0.7 0.2' * mzlflash.alpha);

				addentity(mzlflash);
			}
		}
	}
	
	//deltalisten makes engine call the "add_outline" func for each entity with the set model every frame
	/*deltalisten("models/mg_ammo.iqm", add_outline, 0);
	deltalisten("models/weapons/mg/mg.iqm", add_outline, 0);
	deltalisten("models/weapons/pistol/pistol.iqm", add_outline, 0);*/
	//deltalisten("models/humanoid_simplerig.iqm", add_outline, 0);
	
	DropRecoilKick();

	camang[0] += gun_kick[0];
	camang[1] += gun_kick[1];
	camang[2] += gun_kick[2];

	setviewprop(VF_ANGLES, camang);

	//does what you think it does
	renderscene();

	if (in_loadscreen)
	{
		in_loadscreen = false;
		localcmd(strcat("map ", loadscreen_mapname, "\n"));
	}
	if(in_menu)
	{
		//in menu.qc
		Draw_Menu();
	}
	else
	{
		HUD_Draw(g_width, g_height);
		Chat_Draw();
	}
};

noref float(string cmd) CSQC_ConsoleCommand =
{
	//self = theplayer;
	//if (!self)
	//	return FALSE;

	tokenize(cmd);
	switch(argv(0))
	{
		case "togglemenu":
			ToggleMenu();
			return TRUE;
		case "map":
			return FALSE;
		case "startwalk":
			walk = TRUE;
			return FALSE;
		case "stopwalk":
			walk = FALSE;
			return FALSE;
		case "promptjoin":
			menu_join();
			return TRUE;
		case "showscores":
			if (score_show)
				score_show = FALSE;
			else
				score_show = TRUE;
			return TRUE;
		default:
			return FALSE;
	}
	return FALSE;
};
//**********************************************************************//
// Input_Movecheck                                                      //
//                                                                      //
// Called at InputEvent and allows to set var if key is at that state   //
// NOTE: ALL movekeys are called in order to prevent unsetting keys     //
//**********************************************************************//

void(float scanx, float setval) Input_Movecheck = 
{
	tokenize(findkeysforcommand("+moveleft"));
	if (scanx == stof(argv(0)))
		K_LEFTDOWN = setval;
	
	tokenize(findkeysforcommand("+moveright"));
	if (scanx == stof(argv(0)))
		K_RIGHTDOWN = setval;
		
	tokenize(findkeysforcommand("+forward"));
	if (scanx == stof(argv(0)))
		K_FORWARDDOWN = setval;
		
	tokenize(findkeysforcommand("+back"));
	if (scanx == stof(argv(0)))
		K_BACKDOWN = setval;
}

void(float button, string key) setToBind =
{
	local string fullbind, unbind, oldkey;
	local string btn;
	editBind[button] = FALSE;

	btn = buttonBind[button];

	tokenize(findkeysforcommand(btn));
	oldkey = keynumtostring(stof(argv(0)));

	unbind = strcat("bind ", oldkey, " null\n");
	fullbind = strcat("bind ", key, " \"", btn, "\"\n");
			
	localcmd(unbind);
	localcmd(fullbind);
}

noref float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	switch(evtype)
	{
		case IE_KEYDOWN:
			if(in_menu != MENU_NONE)
			{
				if(scanx == K_MOUSE1) {
					Menu_Click(0);

					if (in_menu == MENU_CUSTOMS)
						Menu_Click_Custom();
					return TRUE;
				} else if (scanx == K_MOUSE2) {
					Menu_Click(1);
					return TRUE;
				}

				if (in_menu == MENU_CSETTINGS) {
					for (int i = 0; i < MAX_BINDS; i += 1) {
						if (editBind[i] == TRUE)
							setToBind(i, keynumtostring(scanx));
					}
				}

				if (in_menu == MENU_MULTI) {
					// GO AWAY!
					if (scanx == K_ENTER || scanx == K_ESCAPE) {
						editing_player_name = editing_server_id = editing_password = editing_hostname = false;
						return FALSE;
					}

					if (editing_player_name == true) {
						// Update the temp string.
						temp_player_name = GetUserInput(temp_player_name, scanx, chary, 18);

						// Always append.
						cvar_set("name", temp_player_name);

						// No, I don't want to read binds. Thanks.
						return TRUE;
					}
				} else if (in_menu == MENU_CREATE || in_menu == MENU_JOIN) {
					// GO AWAY!
					if (scanx == K_ENTER || scanx == K_ESCAPE) {
						editing_player_name = editing_server_id = editing_password = false;
						return FALSE;
					}

					// Server IP
					if (editing_server_id == true) {
						// Update the temp string.
						temp_server_name = GetUserInput(temp_server_name, scanx, chary, 18);

						// No, I don't want to read binds. Thanks.
						return TRUE;
					}

					// Password
					if (editing_password == true) {
						// Update the temp string.
						temp_password = GetUserInput(temp_password, scanx, chary, 18);

						// Always append.
						cvar_set("password", temp_password);

						// No, I don't want to read binds. Thanks.
						return TRUE;
					}

					// Hostname
					if (editing_hostname == true) {
						// Update the temp string.
						temp_hostname = GetUserInput(temp_hostname, scanx, chary, 18);

						// Always append.
						cvar_set("hostname", temp_hostname);

						// No, I don't want to read binds. Thanks.
						return TRUE;
					}
				}

				// Controller Menu Navigation
				if (scanx == K_JOY2) {
					GPActive[0] = TRUE;
				}

				if (scanx == K_JOY4) {
					GPActive[1] = TRUE;
				}

				if (scanx == K_JOY1) {
					GPActive[2] = TRUE;
				}

			}
		
			Input_Movecheck(scanx, 1);

			return FALSE;
		case IE_KEYUP:

			// Controller Menu Navigation
			if(in_menu != MENU_NONE) {
				if (scanx == K_JOY2) {
					GPActive[0] = FALSE;
				} 

				if (scanx == K_JOY4) {
					GPActive[1] = FALSE;
				} 

				if (scanx == K_JOY1) {
					GPActive[2] = FALSE;
				}
			}
			

			Input_Movecheck(scanx, 0);
	
			return FALSE;
		case IE_MOUSEDELTA:
			return FALSE;
		case IE_MOUSEABS:
			//if(devid != 0 && devid != 1)
			//	return FALSE;
			cursor_pos_x = scanx;
			cursor_pos_y = chary;
			return FALSE;
	}
	return FALSE;
};

noref void() CSQC_Input_Frame =
{
	input_angles += gun_kick;
}

#define DEG2RAD(x)	(x * M_PI / 180.f)

noref void() CSQC_Parse_Event =
{
	local float first = readbyte();

	switch (first) {
		case EVENT_PISTOLFIRE:			
			local float entnum, traceent, side;
			local vector pos, norm;
			entnum = readentitynum();
			side = readfloat();
			pos_x = readcoord();
			pos_y = readcoord();
			pos_z = readcoord();
			norm_x = readcoord();
			norm_y = readcoord();
			norm_z = readcoord();
			
			traceent = readentitynum();

			if(entnum == player_localentnum)
			{
				// originally was view_angles, but thats only what is reported
				// to the server, weapon kick is NOT reported, so offset continued
				// to grow.
				getinputstate(servercommandframe);
				makevectors(input_angles);
				local vector offset = vmodel.origin + vmodel_muzzleoffset;
				local vector muzzlepos, muzzle_offset;
				muzzlepos = getviewprop(VF_ORIGIN);
				
				muzzle_offset = GetWeaponFlash_Offset(getstatf(STAT_ACTIVEWEAPON))/1000;

				// Firing from the left? Use the other position instead
                if (side == 0 && IsDualWeapon(getstatf(STAT_ACTIVEWEAPON)))
					muzzle_offset = WepDef_GetLeftFlashOffset(getstatf(STAT_ACTIVEWEAPON))/1000;

				// ADS offset
				if(getstatf(STAT_WEAPONZOOM) == 1) {  
					muzzle_offset += GetWeaponADSOfs_PSP(weapon)/1000;
				}
				
				muzzlepos += v_forward * muzzle_offset_z;
				muzzlepos += v_right * muzzle_offset_x;
				muzzlepos += v_up * muzzle_offset_y;			
				mzlflash.alpha = 1;

				// Scale the muzzleflash to meet viewmodel FOV
				// FTE doesnt support vector scaling :(
				// float afov = cvar("fov");
				// float vfov = cvar("r_viewmodel_default_fov");
				// float ascale = 1.0 / tan(DEG2RAD(afov/2.0)) * vfov / 90.0;
				// mzlflash.scale = ascale;

				if (cvar("nzp_particles") && cvar("r_drawviewmodel")) {
					float index = rint(random() * 2);
					if (IsPapWeapon(getstatf(STAT_ACTIVEWEAPON)))				
						pointparticles(particleeffectnum(strcat("muzzle.muzzle_pap_part", ftos(index))), muzzlepos, norm*24, 1);
					else
						pointparticles(particleeffectnum(strcat("muzzle.muzzle_part", ftos(index))), muzzlepos, norm*24, 1);
				}
			}

			if (GetFiretype(getstatf(STAT_ACTIVEWEAPON)) == FIRETYPE_GRENADE)
				return;
			
			if(traceent == 0)
			{
				if (cvar("nzp_particles"))
					pointparticles(particleeffectnum("weapons.impact"), pos, norm*24, 1);

				if (cvar("nzp_decals"))
					pointparticles(particleeffectnum("weapons.impact_decal"), pos, '0 0 0', 1);
			}
			break;
		case EVENT_WEAPONRECOIL:
			local vector rec;
            rec_x = readcoord()/5;
            rec_y = readcoord()/5;
            rec_z = readcoord()/5;

			gun_kick += rec;
			break;
		case EVENT_EXPLOSION:
            local vector org;
            org_x = readcoord();
            org_y = readcoord();
            org_z = readcoord();

			if (cvar("nzp_decals"))
            	pointparticles(particleeffectnum("weapons.explode"), org, '0 0 0', 1);
            break;
		case EVENT_BLOOD:
			vector loc;

			loc_x = readcoord();
            loc_y = readcoord();
            loc_z = readcoord();
			
			if (cvar("nzp_particles"))
				pointparticles(particleeffectnum("blood.blood_particle"), loc, '0 0 0', 1);
			break;
		case EVENT_FLAME:
			vector floc;

			floc_x = readcoord();
            floc_y = readcoord();
            floc_z = readcoord();
			
			if (cvar("nzp_particles")) {
				pointparticles(particleeffectnum("flames.flame_particle"), floc, '0 0 0', 1);
			}
			break;
		case EVENT_LIMBGIB:
			vector gloc;

			gloc_x = readcoord();
            gloc_y = readcoord();
            gloc_z = readcoord();
			
			if (cvar("nzp_particles")) {
				pointparticles(particleeffectnum("blood.blood_particle"), gloc, '0 0 0', 1);
				pointparticles(particleeffectnum("blood.gibs"), gloc, '0 0 0', 1);
			}
			break;
		case EVENT_CHATMESSAGE:
			int sender = readbyte();
			int player_id = readbyte();
			string message = readstring();
			Chat_Register(sender, player_id, message);
			break;
		case EVENT_WEAPONCHANGE:
			local float to;
			to = readbyte();
			setmodel(vmodel,GetWeaponModel(to, FALSE));

			if (to == W_KAR_SCOPE && vmodel.model == "models/weapons/kar/v_kar.mdl") {
				setmodel(v2model,"models/weapons/kar/v_karscope.mdl");
			} else {
				setmodel(v2model,"");
			}

			v2model.origin = vmodel.origin = '0 0 0';
			v2model.angles = vmodel.angles = '-60 0 0';
			v2model_currentpos = vmodel_currentpos = vmodel.origin + '0 0 -24';
			v2model_targetpos = vmodel_targetpos = vmodel.origin;
			v2model_muzzleoffset = vmodel_muzzleoffset = '12 0 1';
			weapon = to;
			
			HUD_Change_time = time + 6;
			break;
		case EVENT_UPDATEVMODEL:
			local string new;
			local float skin2;
			new = readstring();
			setmodel(vmodel,new);
			vmodel.skin = readbyte();
			break;
		case EVENT_UPDATEV2MODEL:
			local string new2;
			new2 = readstring();
			setmodel(v2model,new2);
			v2model.skin = readbyte();
			break;
		case EVENT_USEPRINT:
			useprint_type = readbyte();
			useprint_cost = readshort();
			useprint_weapon = readbyte();

			useprint_time = time + 0.1;
			break;
		case EVENT_ENDGAME:
			game_over = true;
			break;
		case EVENT_NEWROUND:
			rounds = readbyte();
			HUD_Change_time = time + 6;
			break;
		case EVENT_SETROUND:
			rounds = readbyte();
			break;
		case EVENT_PERK:
			float newperks;
			
			newperks = readlong();

			UpdatePerks(newperks);
			break;
		case EVENT_DOUBLETAPUPDATE:
			double_tap_version = readbyte();
			break;
		case EVENT_UPDATE:
			float updatetype = readbyte();
			float var_1 = readbyte();
			float var_2 = readbyte();
			float var_3 = readbyte();
			
			switch (updatetype)
			{
				case 1: 
					HUD_Change_time = time + var_1; 
					break;
				case 2:
					rounds_change = var_1;
					break;
				case 3:
					if (Hitmark_time < time)
						Hitmark_time = time + 0.2;
					break;
				case 4:
					zoom_2_time = time + 0.05;
					break;
				case 5:
					crosshair_spread_time = time + 70/getWeaponRecoilReturn(getstatf(STAT_ACTIVEWEAPON));
					break;
				default: 
					break;
			}
			break;
		case EVENT_BROADCAST:
			broadcast_time = readbyte();
			broadcast_type = readbyte();
			broadcast_string = readstring();
			break;
		case EVENT_REVIVECHANGE:
			float revivechange_id = readbyte();
			float state = readbyte();
			revive_icons[revivechange_id].state = state;
			break;
		case EVENT_REVIVEON:
			float reviveon_id = readbyte();
			revive_icons[reviveon_id].org[0] = readcoord();
			revive_icons[reviveon_id].org[1] = readcoord();
			revive_icons[reviveon_id].org[2] = readcoord();
			revive_icons[reviveon_id].state = 1;
			revive_icons[reviveon_id].draw = true;
			active_revive_icons++;
			break;
		case EVENT_REVIVEOFF:
			float reviveoff_id = readbyte();
			revive_icons[reviveoff_id].org[0] = 0;
			revive_icons[reviveoff_id].org[1] = 0;
			revive_icons[reviveoff_id].org[2] = 0;
			revive_icons[reviveoff_id].state = 0;
			revive_icons[reviveoff_id].timer = 0;
			revive_icons[reviveoff_id].draw = false;
			active_revive_icons--;
			break;
		// case EVENT_POINTUPDATE:
		// 	float playernum = readbyte();
		// 	float temppoints = readlong();
		// 	RegisterPointChange(readlong(), playernum);
		// 	float tempkills = readlong();
		// 	string tempname = readstring();
			
		// 	switch(playernum) {
		// 		case 1: playerpoints[0] = temppoints; playerkills[0] = tempkills; playernames[0] = tempname; break;
		// 		case 2: playerpoints[1] = temppoints; playerkills[1] = tempkills; playernames[1] = tempname;  break;
		// 		case 3: playerpoints[2] = temppoints; playerkills[2] = tempkills; playernames[2] = tempname; break;
		// 		case 4: playerpoints[3] = temppoints; playerkills[3] = tempkills; playernames[3] = tempname; break;		
		// 	}
		// 	break;
		case EVENT_BLACKOUT:
			fade_time = readbyte();
			fade_type = readbyte();
			break;
		case EVENT_PUNCHANGLE:			
			vector changetest;
			changetest_x = readcoord();
			changetest_y = readcoord();
			changetest_z = readcoord();
			break;
		case EVENT_SCROLLTEXT:
			scrolltext = readstring();
			stext = TRUE;
			break;
		case EVENT_WORLDDATA:
			chaptertitle = readstring();
			location = readstring();
			date = readstring();
			person = readstring();

			if (chaptertitle == "")
				chaptertitle = "'Nazi Zombies'";
			break;
		case EVENT_SONGPLAY:
			string track_name = readstring();
			localsound_enhanced(strcat("tracks/", track_name, ".ogg"), CHAN_MUSIC, 1);
			break;
		case EVENT_ACHIEVEMENT:
			float ach = readbyte();

			if (achievements[ach].unlocked == true)
				return;
			Achievement_Unlock(ach);
			break;
		case EVENT_ACHIEVEMENTPROGRESS:
			float id = readbyte();
			float pg = readfloat();

			if (achievements[id].unlocked == true)
				return;
			
			Achievement_UpdateProgress(id, pg);
			break;
		case EVENT_PLAYERUPDATE:
			player_count = readbyte();
			break;
		case EVENT_GRENADEPULSE:
			crosshair_pulse_grenade = true;
			break;
		case EVENT_BETTYPROMPT:
			bettyprompt_time = time + 4;
			break;
		case EVENT_WEAPONUPDATE:
			float wepnum = readbyte();
			string wepname = readstring();
			string wvmodel = readstring();
			float mag = readbyte();
			float reserve = readbyte();
			vector cads = stov(readstring());
			float cmin = readbyte();
			float cmax = readbyte();
			vector flash = stov(readstring());
			float flashsize = readbyte();
			string v2 = readstring();
			float isd = readbyte();
			/*W_CUSTOMNAME[wepnum] = wepname;
			W_CVMODEL[wepnum] = wvmodel;
			W_CMAG[wepnum] = mag;
			W_CRESERVE[wepnum] = reserve;
			W_CCROSSMIN[wepnum] = cmin;
			W_CCROSSMAX[wepnum] = cmax;
			W_CADS[wepnum] = cads;
			W_CFLASHSIZE[wepnum] = flashsize;
			W_CVMODEL2[wepnum] = v2;
			W_CDUAL[wepnum] = isd;*/
			break;
		case EVENT_HUDUPDATE:
			/*string temps;
			float tempf;
			G_HUD = readstring();
			G_HUDHOR = readbyte();

			if (G_HUD != "")
				huddir = strcat("gfx/hud/", G_HUD, "/");*/
			break;
	}
}
