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
			for(i = 0; i < buttons.length; i++)
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
	buttonBind[7] = "+button4";
	buttonBind[8] = "+button4";
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
	Achievement_Init();
	Particles_Init();
	nameprint_time = time + 8;

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
		self.is_in_menu = readbyte();

		RegisterPointChange(self.points - old_points, self.playernum);

		if (self.movetype == MOVETYPE_BOUNCE)
			self.solid = SOLID_NOT;
		else
			self.solid = SOLID_SLIDEBOX;
			
		setmodelindex(self, self.modelindex);

		if (map_compatibility_mode != MAP_COMPAT_BETA) {
			if (self.stance == 2)
				setsize(self, PLAYER_MINS_STANDING, PLAYER_MAXS_STANDING);
			else
				setsize(self, PLAYER_MINS_CROUCHING, PLAYER_MAXS_CROUCHING);
		} else {
			setsize(self, PLAYER_MINS_QUAKE, PLAYER_MAXS_QUAKE);
		}
	} 
	// Power-Up
	else if (ent_type == 2) {
		if (isnew == TRUE) {
			self.classname = "item_powerup";
			self.solid = SOLID_NOT;
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

//MOVEME
float(float a) angledelta =
{
	a = anglemod(a);
	if (a > 180)
		a -= 360;
	return a;
}

//MOVEME
float delta_pitch, delta_yaw;
vector sniper_sway;
// Sways the camera while scoped in.
void() Camera_SniperSway =
{
	if (getstatf(STAT_WEAPONZOOM) != 2 || (getstatf(STAT_PERKS) & P_DEAD)) {
		sniper_sway = '0 0 0';
		return;
	}

	delta_pitch = (cos(cltime/0.7) + cos(cltime) + sin(cltime/1.1)) * 0.5;
	delta_yaw = (sin(cltime/0.4) + cos(cltime/0.56) + sin(cltime)) * 0.5;

	sniper_sway[0] = angledelta(delta_pitch);
	sniper_sway[1] = angledelta(delta_yaw);
};

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

	//does what you think it does
	renderscene();

	if (in_loadscreen)
	{
		in_loadscreen = false;
		localcmd(strcat("map ", loadscreen_mapname, "\n"));
	}
	if(in_menu)
	{
		// sorta-nasty hack: flashes should still draw if we're
		// drawing the menu.
		if (screenflash_duration > time)
			HUD_Screenflash();

		Draw_Menu();
		setlocaluserinfo(0, "in_menu", "1");
	}
	else
	{
		HUD_Draw(g_width, g_height);
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

	tokenize(findkeysforcommandex(btn));
	oldkey = argv(0);

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
			HUD_Change_time = time + 6;
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
			localsound_enhanced(strcat("tracks/", track_name, ".ogg"), CHAN_MUSIC, 1);
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
			screenflash_duration = time + readbyte();
			screenflash_type = readbyte();
			screenflash_worktime = 0;
			screenflash_starttime = time;
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
			game_over = true;
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
				case 5:
					crosshair_spread_time = time + 70/getWeaponRecoilReturn(getstatf(STAT_ACTIVEWEAPON));
					break;
				default: 
					break;
			}
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
		case EVENT_MAPTYPE:
			map_compatibility_mode = readbyte();
			break;
		case EVENT_WORLDDATA:
			chaptertitle = readstring();
			location = readstring();
			date = readstring();
			person = readstring();

			if (chaptertitle == "")
				chaptertitle = "'Nazi Zombies'";
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
