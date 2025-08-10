/*
	client/main.qc

	main csqc code

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
float need_vid_reload;

void() ToggleMenu =
{
	if (serverkey("constate") != "disconnected")
	{
		if (player_count == 1)
			localcmd("cmd pause\n");

		if(current_menu == MENU_NONE)
		{
			current_menu = MENU_PAUSE;
			setcursormode(TRUE, cvar_string("cl_cursor"), __NULL__, cvar("cl_cursor_scale"));
		}
		else
		{
			menu_paus_submenu = 0;
			current_menu = MENU_NONE;
			setcursormode(FALSE);
		}
	}
}

float(float isnew) SetZombieSkinning =
{
	self.drawmask = MASK_ENGINE;
	setcustomskin(self, __NULL__, sprintf("replace \"\" \"models/ai/zfull.mdl_%d.pcx\"\n", self.skin));
	return PREDRAW_NEXT;
};

//
// GenerateAlphaTransparencyQ3Shaders()
// What a mouth-full! Anyway, NZ:P supports
// alpha transparency via a pseudo-hack where
// if the last character of a model is "$"
// we render with special blend modes. To
// do the same on FTE, we need to generate
// Quake III "shader" files. Returns TRUE
// if we had shader modifications.
//
float() GenerateAlphaTransparencyQ3Shaders =
{
	searchhandle 	alias_models;
	float 			amod_count;
	float 			need_reload = false;

	alias_models = search_begin("*.mdl:*/*.mdl:*/*/*.mdl:*/*/*/*.mdl:*/*/*/*/*.mdl:*/*/*/*/*/*.mdl", SB_CASEINSENSITIVE | SB_MULTISEARCH, true); // gross.
	amod_count = search_getsize(alias_models);

	for (float i = 0; i < amod_count; i++) {
		string full_path = search_getfilename(alias_models, i);

		// Single out character before ".mdl" extension.
		string special_character = substring(full_path, strlen(full_path) - 5, 1);

		// Early out, not a special guy.
		if (special_character != "$")
			continue;

		// Isolate its basename.. manually :(
		string basename = "";
		for (float j = strlen(full_path); j > 0; j--) {
			if (str2chr(full_path, j) == str2chr("/", 0)) {
				// Strip path
				basename = substring(full_path, j + 1, strlen(full_path) - (j + 1));

				// Strip extension
				basename = substring(basename, 0, strlen(basename) - 4);
				break;
			}
		}

		if (basename == "") {
			print(sprintf("[ERROR]: Unable to calculate basename for [%s]!\n", full_path));
			continue;
		}

		float shader_file;
		string shader_path = sprintf("scripts/%s.shader", basename);

		// Check if the shader already exists.
		shader_file = fopen(shader_path, FILE_READ);
		if (shader_file != -1) {
			fclose(shader_file);
			continue;
		}

		// Begin to write.
		shader_file = fopen(shader_path, FILE_WRITE);
		if (shader_file == -1) {
			print(sprintf("[ERROR]: Unable to generate Q3 shader for [%s]!\n", full_path));
			continue;
		}

		// Body of our shader file we're writing.
		string shader_content = sprintf(
			"//\n"
			"// Quake III Shader generated automatically by Nazi Zombies: Portable. Do not modify.\n"
			"//\n"
			"\n"
			"%s_0.lmp\n" // full_path
			"{\n"
			"	program defaultskin\n"
			"	progblendfunc GL_SRC_ALPHA GL_ONE_MINUS_SRC_ALPHA\n"
			"	diffusemap %s_0.tga\n" // full_path
			"	alphafunc ge128\n"
			"}\n"
		, full_path, full_path);

		fputs(shader_file, shader_content);
		fclose(shader_file);

		need_reload = true;
	}

	search_end(alias_models);
	return need_reload;
};

noref void(float apiver, string enginename, float enginever) CSQC_Init =
{
	setwindowcaption("Nazi Zombies: Portable");
	
	precache_sound("sounds/menu/enter.wav");
	precache_sound("sounds/menu/navigate.wav");
	precache_model("models/player.mdl");

	registercommand("togglemenu");
	registercommand("promptjoin");
	registercommand("showscores");

	cvar_set("r_fb_models", ftos(0));
	autocvar(r_viewmodel_default_fov, 70);
	autocvar(cl_controllerglyphs, "xbox");
	autocvar(in_rumbleenabled, 1);
	autocvar(in_aimassist, 0);
	autocvar(cl_hitmarkers, 1);
	autocvar(cl_textopacity, 0.20);
	autocvar(cl_colorblind, 0);

	autocvar(scr_playerdebuginfo, 0);
	autocvar(scr_playerdebuginfo_x, 64);
	autocvar(scr_playerdebuginfo_y, 6);

	// Runtime check if we're running this in WebASM/WebGL.
	if (cvar_string("sys_platform") == "Web")
		platform_is_web = true;
	else
		platform_is_web = false;

	if (platform_is_web) {
		cvar_set("com_protocolname", "NZP-REBOOT-WEB");
	}

	// cvars for custom settings
	autocvar(cl_cinematic, 0);
	autocvar(nzp_particles, 1);
	autocvar(nzp_decals, 1);
	autocvar(vid_ultrawide_limiter, 0);
	autocvar(cl_bobside, 0.02);

	// per-channel volume
	autocvar(snd_channel1volume, 1);
	autocvar(snd_channel2volume, 1);
	autocvar(snd_channel3volume, 1);
	autocvar(snd_channel4volume, 1);
	autocvar(snd_channel5volume, 1);
	autocvar(snd_channel6volume, 1);

	// FTE is overriding cl_bobup values.. so be evil
	// and force it to 0.02.
	cvar_set("cl_bobup", "0.02");

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

	// FTE via emscripten (for the fault of the browser?) bugs out
	// when using mousewheel. So as a hack, just unbind the mouse
	// wheel. :/
	if (platform_is_web) {
		localcmd("unbind MWHEELUP; unbind MWHEELDOWN\n");
		localcmd("bind 1 +button4; bind 2 +button4\n");
	}

	//
	// get the build date
	//
	float file = fopen("version.txt", FILE_READ);

	if (file != -1) {
		build_datetime = fgets(file);
		fclose(file);
	}

	// Intercept every Zombie mesh to apply custom skinning
	for(float i = 0; i < zombie_skins.length; i++) {
		deltalisten(zombie_skins[i], SetZombieSkinning, 0);
	}

	InitKerningMap();

	// If we've made shader changes, we should perform
	// a vid_reload at a reasonable time.
	need_vid_reload = GenerateAlphaTransparencyQ3Shaders();
};

noref void() CSQC_WorldLoaded =
{
	if (need_vid_reload == true) {
		need_vid_reload = false;
		localcmd("vid_reload\n");
	}

	Achievement_Init();
	Particles_Init();
	nameprint_time = time + 8;

	huddir = "gfx/hud/";
};

vector weapon_bob_factor;
float weapon_bob_factor_z_coef;
vector dampening_factor;
float vaccel;
float vzaccel;

// FIXME: Move Power-Up CSQC drawing to separate file :)
float 	mdlflag_poweruprotate_duration;
float 	mdlflag_poweruprotate_starttime;

vector 	mdlflag_poweruprotate_startangles;
vector 	mdlflag_poweruprotate_differenceangles;
vector 	mdlflag_poweruprotate_currentangles;

float 	last_puframetime;

void() PU_UpdateAngles =
{
	// Don't update more than once per frame.
	if (last_puframetime != frametime) {
		// New cycle, dictate new rotation time and target angle. 
		if (mdlflag_poweruprotate_duration <= time) {
			mdlflag_poweruprotate_starttime = time;
			mdlflag_poweruprotate_duration = time + (random() * 25 + 25)/10; // Take between 2.5 and 5 seconds.

			mdlflag_poweruprotate_startangles[0] = mdlflag_poweruprotate_currentangles[0];
			mdlflag_poweruprotate_startangles[1] = mdlflag_poweruprotate_currentangles[1];
			mdlflag_poweruprotate_startangles[2] = mdlflag_poweruprotate_currentangles[2];

			float target_pitch = (random() * 120) - 60;
			float target_yaw = (random() * 240) + 60;
			float target_roll = (random() * 90) - 45;

			vector target_angles;
			target_angles[0] = target_pitch;
			target_angles[1] = target_yaw;
			target_angles[2] = target_roll;

			// Calculate the difference from our start to our target.
			for(float i = 0; i < 2; i++) {
				if (mdlflag_poweruprotate_currentangles[i] > target_angles[i])
					mdlflag_poweruprotate_differenceangles[i] = (mdlflag_poweruprotate_currentangles[i] - target_angles[i]) * -1;
				else
					mdlflag_poweruprotate_differenceangles[i] = fabs(mdlflag_poweruprotate_currentangles[i] - target_angles[i]);
			}
		}

		float percentage_complete = (time - mdlflag_poweruprotate_starttime) / (mdlflag_poweruprotate_duration - mdlflag_poweruprotate_starttime);

		for(float j = 0; j < 2; j++) {
			mdlflag_poweruprotate_currentangles[j] = mdlflag_poweruprotate_startangles[j] + (mdlflag_poweruprotate_differenceangles[j] * percentage_complete);
		}

		last_puframetime = frametime;
	}
};

float() PU_PreDraw =
{
	PU_UpdateAngles();
	self.angles = mdlflag_poweruprotate_currentangles;
	addentity(self);

	return PREDRAW_NEXT;
};

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

	// Player
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
		self.headshots = readshort();
		self.downs = readshort();
		self.revives = readshort();
		self.is_in_menu = readbyte();
		self.is_spectator = readbyte();
		self.ping = readshort();

		// set for HUD_PlayerDebugInfo
		player_velocity = self.velocity;

		setmodelindex(self, self.modelindex);

		if (self.is_spectator)
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_SLIDEBOX;

		RegisterPointChange(self.points - old_points, self.playernum);

		if (map_compatibility_mode != MAP_COMPAT_BETA) {
			if (self.stance == 2)
				setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
			else
				setsize(self, PLAYER_MINS_CROUCHING, PLAYER_MAXS_CROUCHING);
		} else {
			setsize(self, PLAYER_MINS_QUAKE, PLAYER_MAXS_QUAKE);
		}

		if (self.modelindex == getmodelindex("models/sprites/null.spr") && !self.playernum) {
			self.solid = SOLID_NOT;
			self.classname = "";
		} else {
			self.classname = "player";
		}
	} 
	// Power-Up
	else if (ent_type == 2) {
		if (isnew == TRUE) {
			self.classname = "item_powerup";
			self.solid = SOLID_NOT;
			self.effects = EF_FULLBRIGHT;
			self.predraw = PU_PreDraw;
			self.drawmask = MASK_ENGINE;
		}

		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
		self.modelindex = readshort();

		setmodelindex(self, self.modelindex);
	}
	else {
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

	if (recoil_kick_time > time)
		return;

	len = VectorNormalize(gun_kick);

	len = len - frametime*5;
	if (len < 0)
		len = 0;

	gun_kick[0] *= len;
	gun_kick[1] *= len;
	gun_kick[2] *= len;
}

//
// Key_IsControllerGlyph(bind)
// Returns TRUE if the string provided belongs to
// a gamepad/controller.
//
float(string bind) Key_IsControllerGlyph =
{
	switch(bind) {
		case "GP_A":
		case "GP_B":
		case "GP_X":
		case "GP_Y":
		case "GP_LSHOULDER":
		case "GP_RSHOULDER":
		case "GP_LTRIGGER":
		case "GP_RTRIGGER":
		case "GP_BACK":
		case "GP_START":
		case "GP_LTHUMB":
		case "GP_RTHUMB":
		case "GP_DPAD_UP":
		case "GP_DPAD_DOWN":
		case "GP_DPAD_LEFT":
		case "GP_DPAD_RIGHT":
			return true;
	}

	return false;
};

//
// Key_DrawControllerGlyph(position, bind, scale)
// Draws the associated glyph for the bind name from the
// Glyph tilemap at the provided position, with the
// provided scale.
//
void(vector position, string bind, vector scale) Key_DrawControllerGlyph =
{
	vector tilemap_position = [0, 0];

	// The coordinates in 0-1 range of each button in the glyph tilemap.
	switch(bind) {
		case "GP_A":
			tilemap_position = [0, 0];
			break;
		case "GP_B":
			tilemap_position = [0.125, 0];
			break;
		case "GP_X":
			tilemap_position = [0.250, 0];
			break;
		case "GP_Y":
			tilemap_position = [0.375, 0];
			break;
		case "GP_LSHOULDER":
			tilemap_position = [0.250, 0.125];
			break;
		case "GP_RSHOULDER":
			tilemap_position = [0.375, 0.125];
			break;
		case "GP_LTRIGGER":
			tilemap_position = [0.500, 0.125];
			break;
		case "GP_RTRIGGER":
			tilemap_position = [0.625, 0.125];
			break;
		case "GP_BACK":
			tilemap_position = [0.875, 0.125];
			break;
		case "GP_START":
			tilemap_position = [0.750, 0.125];
			break;
		case "GP_LTHUMB":
			tilemap_position = [0, 0.125];
			break;
		case "GP_RTHUMB":
			tilemap_position = [0.125, 0.125];
			break;
		case "GP_DPAD_UP":
			tilemap_position = [0.500, 0];
			break;
		case "GP_DPAD_DOWN":
			tilemap_position = [0.625, 0];
			break;
		case "GP_DPAD_LEFT":
			tilemap_position = [0.750, 0];
			break;
		case "GP_DPAD_RIGHT":
			tilemap_position = [0.875, 0];
			break;
	}

	drawsubpic([position_x, position_y], [scale_x, scale_y], sprintf("gfx/controller_glyphs/%s.tga", cvar_string("cl_controllerglyphs")), [tilemap_position_x, tilemap_position_y], [0.125, 0.125], [1, 1, 1], 1);
};

#define SCALE_CONSTANT 		8

//MOVEME
float(float a) angledelta =
{
	a = anglemod(a);
	if (a > 180)
		a -= 360;
	return a;
}

//MOVEME
vector current_sway;
float current_intensity;
float target_intensity;
vector sniper_sway;
float sniper_breath_starttime;
float sniper_breath_endtime;
float sniper_breath_counter;
float sniper_breath_exhaustion_starttime;
float sniper_breath_exhaustion_endtime;
float sniper_breath_delay;
float sniper_hold_breath;

#define SNIPER_SWAY_INTENSITY_FOCUSED		0.05
#define SNIPER_SWAY_INTENSITY_NORMAL		0.5
#define SNIPER_SWAY_INTENSITY_EXHAUSTION	2

void(float inhale) Sniper_HoldBreath =
{
	if (sniper_breath_delay > time)
		return;

	if (getstatf(STAT_WEAPONZOOM) != 2 || (getstatf(STAT_PERKS) & P_DEAD)) {
		return;
	}

	if (inhale) {
		if (sniper_hold_breath == true)
			return;
		sniper_breath_starttime = time;
		sniper_breath_endtime = time + 4;
		sniper_hold_breath = true;
		localsound("sounds/player/inhale.wav", 0, 1);
	} else {
		if (sniper_hold_breath == false)
			return;
		sniper_breath_endtime = sniper_breath_starttime = 0;
		sniper_hold_breath = false;
		sniper_breath_delay = time + 1;
		localsound("sounds/player/exhale.wav", 0, 1);
	}
};

void() Camera_SniperSway =
{
    // Determine target intensity based on state
    target_intensity = SNIPER_SWAY_INTENSITY_NORMAL;

    if (getstatf(STAT_WEAPONZOOM) != 2 || (getstatf(STAT_PERKS) & P_DEAD)) {
		current_intensity = 0;
		current_sway = '0 0 0';
        target_intensity = 0;
		sniper_breath_counter = 0;
    } else {
		// We are focused.
        if (sniper_breath_endtime > time) {
            target_intensity = SNIPER_SWAY_INTENSITY_FOCUSED;

			float breath_duration = floor(time - sniper_breath_starttime);

			// Play heartbeat sfx at every second interval.
			if (breath_duration != sniper_breath_counter) {
				sniper_breath_counter = breath_duration;
				localsound("sounds/player/heart.wav", 0, 5);
			}
        } 
		// Time has expired and we're out of breath, begin exhaustion.
		else if (sniper_breath_endtime < time && sniper_hold_breath == true) {
            Sniper_HoldBreath(false);
            sniper_breath_exhaustion_starttime = time;
            sniper_breath_exhaustion_endtime = time + 4;
            sniper_breath_delay = time + 4;
        }

		// Slowly decrease in intensity from fully exhausted to normal.
        if (sniper_breath_exhaustion_endtime > time) {
            float progress = (time - sniper_breath_exhaustion_starttime) / (sniper_breath_exhaustion_endtime - sniper_breath_exhaustion_starttime);
            target_intensity = SNIPER_SWAY_INTENSITY_EXHAUSTION + progress * (SNIPER_SWAY_INTENSITY_NORMAL - SNIPER_SWAY_INTENSITY_EXHAUSTION);
        }
    }

    // Smoothly interpolate intensity towards target
    current_intensity += (target_intensity - current_intensity) * (clframetime * 5); // Adjust 0.1 for smoother/faster transitions

    // Calculate sway deltas based on cltime and intensity
    float sway_pitch = (cos(cltime / 0.7) + cos(cltime) + sin(cltime / 1.1));
    float sway_yaw = (sin(cltime / 0.4) + cos(cltime / 0.56) + sin(cltime));

    // Update current sway using the smoothly interpolated intensity
    current_sway[0] = sway_pitch * current_intensity;
    current_sway[1] = sway_yaw * current_intensity;

    // Apply the smooth sway to sniper_sway
    sniper_sway[0] = angledelta(current_sway[0]);
    sniper_sway[1] = angledelta(current_sway[1]);
};

float gamepad_enabled;

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

	float sensitivity_factor;

	if (current_menu != MENU_NONE)
		sensitivity_factor = 0;
	else
		sensitivity_factor = (1 + SCALE_CONSTANT * getstatf(STAT_VIEWZOOM)) / (1 + SCALE_CONSTANT);

	if (gamepad_enabled && getstatf(STAT_FACINGENEMY) && cvar("in_aimassist") == 1)
		sensitivity_factor *= 0.5;

	setsensitivityscaler(sensitivity_factor);

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

	// Draw the client's viewmodels.
	ViewModel_Draw();
	
	DropRecoilKick();
	Camera_SniperSway();

	camang[0] += gun_kick[0];
	camang[1] += gun_kick[1];
	camang[2] += gun_kick[2];
	camang[0] += sniper_sway[0];
	camang[1] += sniper_sway[1];
	camang[2] += sniper_sway[2];

	setviewprop(VF_ANGLES, camang);

	if (cvar("chase_active")) {
		Chase_Update();
	}

	//does what you think it does
	renderscene();

	if (current_menu != MENU_NONE)
	{
		// sorta-nasty hack: flashes should still draw if we're
		// drawing the menu.
		HUD_Screenflash();

		setlocaluserinfo(0, "in_menu", "1");

		sui_begin(g_width, g_height);
		root_menu([g_width, g_height]);
		sui_end();
	}
	else
	{
		setcursormode(FALSE);
		HUD_DrawElements();
		Chat_Draw();
		setlocaluserinfo(0, "in_menu", "0");
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

	float argc = tokenize(findkeysforcommand("impulse 23"));
    for (int i = 0; i < argc; i++) {
		if (scanx == stof(argv(i))) {
			Sniper_HoldBreath(setval);
		}
    }
}

noref float(float evtype, float scanx, float chary, float devid) CSQC_InputEvent =
{
	if (evtype == IE_GYROSCOPE || evtype == IE_ACCELEROMETER)
		return FALSE;

	// Ignore subtle (drift-y) joystick axes
	if (evtype == IE_JOYAXIS && devid > 0)
	{
		if (scanx == 0)
		{
			K_LEFTDOWN = (chary < -0.1);
			K_RIGHTDOWN = (chary > 0.1);
			return FALSE;
		}

		if (scanx == 1)
		{
			K_FORWARDDOWN = (chary < -0.1);
			K_BACKDOWN = (chary > 0.1);
			return FALSE;
		}

		if (fabs(chary) < 0.1)
		{
			return FALSE;
		}
	}

	last_input_deviceid = devid;
	float last_input_storage = last_input_was_gamepad;

	if (last_input_deviceid > 0)
	{
		last_input_was_gamepad = TRUE;
		setlocaluserinfo(0, "using_gamepad", "1");
	}
	else
	{
		last_input_was_gamepad = FALSE;
		setlocaluserinfo(0, "using_gamepad", "0");
	}

	if (current_menu != MENU_NONE)
	{
		return sui_input_event(evtype, scanx, chary, devid);
	}

	if (evtype == IE_KEYDOWN) {
		switch (scanx) {
			case K_GP_A:
			case K_GP_B:
			case K_GP_X:
			case K_GP_Y:
			case K_GP_LSHOULDER:
			case K_GP_RSHOULDER:
			case K_GP_LTRIGGER:
			case K_GP_RTRIGGER:
			case K_GP_BACK:
			case K_GP_START:
			case K_GP_LTHUMB:
			case K_GP_RTHUMB:
			case K_GP_DPAD_UP:
			case K_GP_DPAD_DOWN:
			case K_GP_DPAD_LEFT:
			case K_GP_DPAD_RIGHT:
			case K_GP_LTHUMB_UP:
			case K_GP_LTHUMB_DOWN:
			case K_GP_LTHUMB_LEFT:
			case K_GP_LTHUMB_RIGHT:
			case K_GP_RTHUMB_UP:
			case K_GP_RTHUMB_DOWN:
			case K_GP_RTHUMB_LEFT:
			case K_GP_RTHUMB_RIGHT:
				if (!GPButtonHeldBeginTime[scanx-816])
					GPButtonHeldBeginTime[scanx-816] = cltime;
				break;

		}
	}

	if (evtype == IE_KEYUP) {
		switch (scanx) {
			case K_GP_A:
			case K_GP_B:
			case K_GP_X:
			case K_GP_Y:
			case K_GP_LSHOULDER:
			case K_GP_RSHOULDER:
			case K_GP_LTRIGGER:
			case K_GP_RTRIGGER:
			case K_GP_BACK:
			case K_GP_START:
			case K_GP_LTHUMB:
			case K_GP_RTHUMB:
			case K_GP_DPAD_UP:
			case K_GP_DPAD_DOWN:
			case K_GP_DPAD_LEFT:
			case K_GP_DPAD_RIGHT:
			case K_GP_LTHUMB_UP:
			case K_GP_LTHUMB_DOWN:
			case K_GP_LTHUMB_LEFT:
			case K_GP_LTHUMB_RIGHT:
			case K_GP_RTHUMB_UP:
			case K_GP_RTHUMB_DOWN:
			case K_GP_RTHUMB_LEFT:
			case K_GP_RTHUMB_RIGHT:
				//print(sprintf("Key: %f Duration: %f\n", scanx, cltime-GPButtonHeldBeginTime[scanx-816]));
				GPButtonHeldBeginTime[scanx-816] = 0;
				break;

		}
	}
	switch(evtype)
	{
		case IE_KEYDOWN:
			Input_Movecheck(scanx, 1);
			return FALSE;
		case IE_KEYUP:
			Input_Movecheck(scanx, 0);
			return FALSE;
		case IE_MOUSEDELTA:
			return FALSE;
		case IE_MOUSEABS:
			return FALSE;
	}

	return FALSE;
};

noref void() CSQC_Input_Frame =
{
	input_angles += gun_kick;
	input_angles += sniper_sway;
}

#define DEG2RAD(x)	(x * M_PI / 180.f)

noref void() CSQC_Parse_Event =
{
	float event_type = readbyte();

	switch (event_type) {
		case CSQC_EVENT_PARTICLE:
			float particle_type = readbyte();
			float part_pos_x = readcoord();
			float part_pos_y = readcoord();
			float part_pos_z = readcoord();
			float part_optional = readbyte();
			float part_entity = readentitynum();
			vector particle_pos = [part_pos_x, part_pos_y, part_pos_z];
			Particles_RunParticle(particle_type, particle_pos, part_optional, part_entity);
			break;
		case CSQC_EVENT_USEPRINT:
			useprint_type = readbyte();
			useprint_cost = readshort();
			useprint_weapon = readbyte();
			useprint_time = time + 0.1;
			break;
		case CSQC_EVENT_ROUNDCHANGE:
			rounds = readbyte();
			break;
		case CSQC_EVENT_BROADCASTMESSAGE:
			broadcast_type = readbyte();
			broadcast_time = time + readbyte();
			broadcast_num = readbyte();
			break;
		case CSQC_EVENT_MAXAMMOTEXT:
			hud_maxammo_endtime = time + 2;
			hud_maxammo_starttime = time;
			break;
		case CSQC_EVENT_MUSICSTREAM:
			string track_name = readstring();
			string track_extension;
			if (platform_is_web)
				track_extension = ".wav";
			else
				track_extension = ".ogg";

			localsound_enhanced(strcat("tracks/", track_name, track_extension), CHAN_MUSIC, 0.85);
			break;
		case CSQC_EVENT_GIVEACHIEVEMENT:
			float achievement_id = readbyte();

			// Don't unlock an existing achievement or any if on emscripten.
			if (achievements[achievement_id].unlocked || platform_is_web)
				return;

			Achievement_Unlock(achievement_id);
			break;
		case CSQC_EVENT_PLAYERNAME:
			character_name = readstring();
			break;
		case CSQC_EVENT_SCREENFLASH:
			screenflash_color = readbyte();
			if (screenflash_color == SCREENFLASH_COLOR_WHITE && cvar("scr_whiteflash") == 1) {
				screenflash_color = SCREENFLASH_COLOR_BLACK;
			}
			screenflash_duration = time + readbyte();
			screenflash_type = readbyte();
			screenflash_worktime = 0;
			screenflash_starttime = time;
			break;
		case CSQC_EVENT_RUMBLE:
			float low_frequency = readshort();
			float high_frequency = readshort();
			float duration = readshort();
			if (cvar("in_rumbleenabled"))
				gp_rumble(last_input_deviceid, low_frequency, high_frequency, duration);
			break;
		case CSQC_EVENT_SETGAMEMODE:
			active_gamemode = readbyte();
			break;
		case EVENT_WEAPONRECOIL:
			local vector rec;
            rec_x = readcoord()/5;
            rec_y = readcoord()/5;
            rec_z = readcoord()/5;

			gun_kick += rec;
			break;
		case EVENT_CHATMESSAGE:
			int sender = readbyte();
			int player_id = readbyte();
			string message = readstring();
			Chat_Register(sender, player_id, message);
			break;
		case EVENT_ENDGAME:
			in_endgame_sequence = true;
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
					if (hitmark_ignore_time > time)
						return;

					hitmark_type = var_1;

					// Red
					if (hitmark_type == 1) {
						hitmark_time = time + 0.2;
						hitmark_ignore_time = time + 0.2;
					} else {
						hitmark_time = time + 0.3;
					}
					break;
				case 5:
					recoil_kick_time = time + 70/getWeaponRecoilReturn(getstatf(STAT_ACTIVEWEAPON));
					cur_spread = CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE));
					break;
				default: 
					break;
			}
			break;
		case EVENT_REVIVECHANGE:
			float revivechange_player_index = readbyte() - 1; // playernum starts at one.
			float state = readbyte();
			revive_icons[revivechange_player_index].state = state;
			break;
		case EVENT_REVIVEON:
			float reviveon_player_index = readbyte() - 1; // playernum starts at one.
			if (reviveon_player_index < 0)
				return;

			revive_icons[reviveon_player_index].state = 1;
			revive_icons[reviveon_player_index].draw = true;
			break;
		case EVENT_REVIVEOFF:
			float reviveoff_player_index = readbyte() - 1; // playernum starts at one.
			if (reviveoff_player_index < 0)
				return;

			revive_icons[reviveoff_player_index].state = 0;
			revive_icons[reviveoff_player_index].timer = 0;
			revive_icons[reviveoff_player_index].draw = false;
			break;
		case EVENT_MAPTYPE:
			map_compatibility_mode = readbyte();
			break;
		case EVENT_WORLDDATA:
			chaptertitle = readstring();
			location = readstring();
			date = readstring();
			person = readstring();

			switch(active_gamemode) {
				case GAMEMODE_CLASSIC: 
					if (chaptertitle == "")
						chaptertitle = "'Nazi Zombies'";
					break;
				case GAMEMODE_GUNGAME:
					chaptertitle = "GUN GAME";
					location = "Cycle all Weapons to WIN!";
					date = "";
					person = "";
					break;
				case GAMEMODE_HARDCORE:
					chaptertitle = "HARDCORE";
					break;
				case GAMEMODE_STICKSNSTONES:
					chaptertitle = "STICKS & STONES";
					location = "Ballistic Knife FTW!";
					date = "";
					person = "";
					break;
				case GAMEMODE_WILDWEST:
					chaptertitle = "WILD WEST";
					location = "It's a stand-off!";
					date = "";
					person = "";
					break;
				default:
					break;
			}
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
	}
}
