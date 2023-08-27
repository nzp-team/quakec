/*
	client/main.qc

	main csqc code

	Copyright (C) 2021 NZ:P Team

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

	registercommand("togglemenu");
	registercommand("startwalk");
	registercommand("stopwalk");
	registercommand("promptjoin");
	registercommand("showscores");

	cvar_set("sv_cheats", ftos(1));
	autocvar(r_viewmodel_default_fov, 70);

	// Runtime check if we're running this in WebASM/WebGL.
	if (cvar_string("sys_platform") == "Web")
		platform_is_web = true;
	else
		platform_is_web = false;
		
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
	buttonBind[13] = "impulse 25";

	// intialize screen resolutions

	// default/current width and height
	active_swidth = cvar("vid_width");
	active_sheight = cvar("vid_height");
	fullscreenval = cvar("vid_fullscreen");

	// 5:4
	screen_width_54[0] = 1280;
	screen_height_54[0] = 1024;
	//4:3
	screen_width_43[0] = 640;
	screen_height_43[0] = 480;
	screen_width_43[1] = 800;
	screen_height_43[1] = 600;
	screen_width_43[2] = 1024;
	screen_height_43[2] = 768;
	//16:10
	screen_width_1610[0] = 1280;
	screen_height_1610[0] = 800;
	screen_width_1610[1] = 1440;
	screen_height_1610[1] = 900;
	screen_width_1610[2] = 1680;
	screen_height_1610[2] = 1050;
	screen_width_1610[3] = 1920;
	screen_height_1610[3] = 1200;
	screen_width_1610[4] = 2560;
	screen_height_1610[4] = 1600;
	//16:9
	screen_width_169[0] = 640;
	screen_height_169[0] = 360;
	screen_width_169[1] = 1280;
	screen_height_169[1] = 720;
	screen_width_169[2] = 1360;
	screen_height_169[2] = 768;
	screen_width_169[3] = 1366;
	screen_height_169[3] = 768;
	screen_width_169[4] = 1536;
	screen_height_169[4] = 864;
	screen_width_169[5] = 1600;
	screen_height_169[5] = 900;
	screen_width_169[6] = 1920;
	screen_height_169[6] = 1080;
	screen_width_169[7] = 2048;
	screen_height_169[7] = 1152;
	screen_width_169[8] = 2560;
	screen_height_169[8] = 1440;
	screen_width_169[9] = 3840;
	screen_height_169[9] = 2160;
	//21:9
	screen_width_219[0] = 2560;
	screen_height_219[0] = 1080;
	screen_width_219[1] = 3440;
	screen_height_219[1] = 1440;

	// cvars for custom settings
	cvar_set("cl_adsmode", "0");
	cvar_set("cl_cinematic", "0");
	cvar_set("nzp_particles", "1");
	cvar_set("nzp_decals", "1");

	// per-channel volume
	cvar_set("snd_channel1volume", "1");
	cvar_set("snd_channel2volume", "1");
	cvar_set("snd_channel3volume", "1");
	cvar_set("snd_channel4volume", "1");
	cvar_set("snd_channel5volume", "1");
	cvar_set("snd_channel6volume", "1");

	// force nearest filtering for hud elements to avoid blur
	cvar_set("gl_texturemode2d", "gl_nearest");
	cvar_set("r_font_linear", "0");

	// force build date text in menu
	cvar_set("cl_showbuildtime", "1");

	// in-game stopwatch
	registercvar("scr_serverstopwatch", "0");
	stopwatch_sec = stopwatch_min = stopwatch_hr = 0;

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

noref void() CSQC_WorldLoaded =
{
	//precache_model("models/weapons/mg/mzl.iqm");
	//precache_model("models/blood.iqm");
	
	if(!player)
		player = edict_num(player_localnum);
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
	
	playerpoints[1] = -1;
	playerpoints[2] = -1;
	playerpoints[3] = -1;

	Achievement_Init();
	
	// Dummy so that our other point particles work!
	pointparticles(particleeffectnum("weapons.impact_decal"), '0 0 0', '0 0 0', 1);
	pointparticles(particleeffectnum("muzzle.muzzle_part0"), '0 0 0', '0 0 0', 1);

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

noref void(float isnew) CSQC_Ent_Update =
{
	if(isnew)
		addentity(self);
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

	//autoadd entities received from servers for drawing	
	addentities(MASK_ENGINE);

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

	if(in_menu)
	{
		//in menu.qc
		Draw_Menu();
	}
	else
	{
		HUD_Draw(g_width, g_height);
	}
	if(serverkey("constate") != "active" && serverkey("disconnected"))
	{
		drawfill('0 0 0',  [width, height, 0], '0.2 0.4 0.7', 1, 0);
		drawstring([width/2 - 60, height/2, 0], "Loading...", [16,16,0],[1,1,1],1,0);
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
	if(walk)
	{
		input_movevalues *= 0.5;
	}

	input_angles = getproperty(VF_ANGLES);
}

float() tracerthink =
{
	//makevectors(self.angles);
	local vector cross1 = normalize(crossproduct( getviewprop(VF_ORIGIN) - self.targetpos, self.targetpos - self.origin));
	local vector cross2 = normalize(crossproduct( getviewprop(VF_ORIGIN) - self.origin, self.targetpos - self.origin));
	R_BeginPolygon("tracers/mg");
	
	R_PolygonVertex(self.origin + cross2, '0 1 0', '1 1 1', self.alpha - 0.6);
	R_PolygonVertex(self.origin - cross2, '0 0 0', '1 1 1', self.alpha - 0.6);
	R_PolygonVertex(self.targetpos - cross1, '1 0 0', '1 1 1', self.alpha);

	R_PolygonVertex(self.targetpos + cross1, '1 1 0', '1 1 1', self.alpha);
	R_PolygonVertex(self.origin + cross2, '0 1 0', '1 1 1', self.alpha - 0.6);
	R_PolygonVertex(self.targetpos - cross1, '1 0 0', '1 1 1', self.alpha);

	/*R_PolygonVertex(self.origin + v_right, '0 1 0', '1 1 1', self.alpha - 0.4);
	R_PolygonVertex(self.origin - v_right, '0 0 0', '1 1 1', self.alpha - 0.4);
	R_PolygonVertex(self.targetpos - v_right, '1 0 0', '1 1 1', self.alpha);

	R_PolygonVertex(self.targetpos + v_right, '1 1 0', '1 1 1', self.alpha);
	R_PolygonVertex(self.origin + v_right, '0 1 0', '1 1 1', self.alpha - 0.4);
	R_PolygonVertex(self.targetpos - v_right, '1 0 0', '1 1 1', self.alpha);*/


	R_EndPolygon();

	self.alpha -= (frametime * self.rate);
	if(self.alpha <= 0)
		remove(self);

	return 0;
}

float() alphafade =
{
	
	self.alpha -= (frametime * 3);
	self.scale += (frametime * 9);
	if(self.alpha <= 0.05)
		remove(self);
	
	local vector cross1 = 10 * self.scale * normalize(crossproduct( getviewprop(VF_ORIGIN) - self.origin + self.targetpos * self.scale, self.targetpos * self.scale));
	local vector cross2 = 10 * self.scale * normalize(crossproduct( getviewprop(VF_ORIGIN) - self.origin, self.targetpos * self.scale));
	R_BeginPolygon("bloodsplat2");
	
	R_PolygonVertex(self.origin + cross2, '0 1 0', '1 1 1', self.alpha);
	R_PolygonVertex(self.origin - cross2, '0 0 0', '1 1 1', self.alpha);
	R_PolygonVertex(self.origin + (self.targetpos*self.scale*18) - cross1, '1 0 0', '1 1 1', self.alpha);

	R_PolygonVertex(self.origin + (self.targetpos*self.scale*18) + cross1, '1 1 0', '1 1 1', self.alpha);
	R_PolygonVertex(self.origin + cross2, '0 1 0', '1 1 1', self.alpha);
	R_PolygonVertex(self.origin + (self.targetpos*self.scale*18) - cross1, '1 0 0', '1 1 1', self.alpha);
	
	R_EndPolygon();
	
	return 0;
}

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
				makevectors(view_angles);
				local vector offset = vmodel.origin + vmodel_muzzleoffset;
				local vector muzzlepos;
				muzzlepos = getviewprop(VF_ORIGIN);
				
				local vector muzzle_offset = GetWeaponFlash_Offset(getstatf(STAT_ACTIVEWEAPON))/1000;

				// ADS offset
				if(getstatf(STAT_WEAPONZOOM) == 1)
				{  
					muzzle_offset += GetWeaponADSPos(weapon);
					muzzle_offset[0] -= 2;
				}
                
                // Firing from the left? Flip x-axis for muzzleflash
                if (side == 0 && IsDualWeapon(getstatf(STAT_ACTIVEWEAPON)))
                    muzzle_offset[0] = -muzzle_offset[0];
				
				muzzlepos += v_forward * muzzle_offset_z;
				muzzlepos += v_right * muzzle_offset_x;
				muzzlepos += v_up * muzzle_offset_y;			
				mzlflash.alpha = 1;

				if (cvar("nzp_particles") && cvar("r_drawviewmodel")) {
					float index = rint(random() * 2);
					if (IsPapWeapon(getstatf(STAT_ACTIVEWEAPON)))				
						pointparticles(particleeffectnum(strcat("muzzle.muzzle_pap_part", ftos(index))), muzzlepos, norm*24, 1);
					else
						pointparticles(particleeffectnum(strcat("muzzle.muzzle_part", ftos(index))), muzzlepos, norm*24, 1);
				}
			}
			
			if(traceent == 0 && GetFiretype(getstatf(STAT_ACTIVEWEAPON)) != 3)
			{
				if (cvar("nzp_particles"))
					pointparticles(particleeffectnum("weapons.impact"), pos, norm*24, 1);

				if (cvar("nzp_decals"))
					pointparticles(particleeffectnum("weapons.impact_decal"), pos, '0 0 0', 1);
			}
			else
			{
				local vector entorg;
				entorg = getentity(traceent, GE_ORIGIN);
				norm = (norm * 0.25) + (normalize(pos - (entorg + '0 0 12')) * 0.75);
				local entity splat = spawn();
				splat.drawmask = 1;
				splat.alpha = 1;
				splat.scale = 0.05;
				splat.angles = [random()*360, random()*360, random()*360];
				splat.targetpos = norm * 1.5;
				splat.predraw = alphafade;
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
			local vector loc;

			loc_x = readcoord();
            loc_y = readcoord();
            loc_z = readcoord();
			
			if (cvar("nzp_particles"))
				pointparticles(particleeffectnum("blood.blood_particle"), loc, '0 0 0', 1);
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
		case EVENT_POINTUPDATE:
			float playernum = readbyte();
			float temppoints = readlong();
			RegisterPointChange(readlong(), playernum);
			float tempkills = readlong();
			string tempname = readstring();
			
			switch(playernum) {
				case 1: playerpoints[0] = temppoints; playerkills[0] = tempkills; playernames[0] = tempname; break;
				case 2: playerpoints[1] = temppoints; playerkills[1] = tempkills; playernames[1] = tempname;  break;
				case 3: playerpoints[2] = temppoints; playerkills[2] = tempkills; playernames[2] = tempname; break;
				case 4: playerpoints[3] = temppoints; playerkills[3] = tempkills; playernames[3] = tempname; break;		
			}
			break;
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
