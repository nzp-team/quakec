/*
	client/hud.qc

	HUD Drawing Code

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

float(string bind) Key_IsControllerGlyph;
void(vector position, string bind, vector scale) Key_DrawControllerGlyph;

// vid_ultrawide_limiter
#define ULTRAWIDE_OFFSET 		250


float() GetUltraWideOffset =
{
	if (cvar("vid_ultrawide_limiter"))
		return ULTRAWIDE_OFFSET;
	
	return 0;
}

//return hud images, makes drawpic slightly cleaner..
string(string img) getImage = {
	return strcat(huddir, img);
}

//
// HUD_ResolveTextColorForPlayer(index)
// Returns the color as a vector to use for a
// player of the given index.
//
vector(float index) HUD_ResolveTextColorForPlayer =
{
	switch(index) {
		case 0:
			// White.
			return '1 1 1';
		case 1:
			// Light Blue.
			if (cvar("cl_colorblind")) {
				return '0.39 0.76 0.93';
			} else {
				return '0 0.46 0.70';
			}
		case 2:
			// Orange.
			if (cvar("cl_colorblind")) {
				return '0.93 0.42 0';
			} else {
				return '0.92 0.74 0';
			}
		case 3:
			// Green.
			if (cvar("cl_colorblind")) {
				return '0 0.69 0.52';
			} else {
				return '0 0.90 0.13';
			}
		case 4:
			// Salmon Pink.
			if (cvar("cl_colorblind")) {
				return '1 0.46 0.54';
			} else {
				return '1 0.57 0.64';
			}
		case 5:
			// Magenta.
			if (cvar("cl_colorblind")) {
				return '0.73 0.29 0.54';
			} else {
				return '0.80 0.20 0.55';
			}
		case 6:
			// Cyan.
			if (cvar("cl_colorblind")) {
				return '0.36 0.84 0.96';
			} else {
				return '0.42 0.82 0.82';
			}
		case 7:
			// Yellow. 
			if (cvar("cl_colorblind")) {
				return '0.86 0.78 0.25';
			} else {
				return '1 0.87 0.13';
			}
		default:
			// White.
			return '1 1 1';
	}
};

//
// HUD_GetAlphaForWeaponObjects()
// Used for objects on the ammo-corner, where
// they linger for X seconds and then fade after.
//
float() HUD_GetAlphaForWeaponObjects =
{
	if (HUD_Change_time <= time)
		return 0;
	else if (HUD_Change_time - time > 1)
		return 1;
	else
		return (HUD_Change_time - time);
};

//
// HUD_DrawStringWithBackdrop(position, text, size, rgb, alpha, drawflag)
// Wrapper for Draw_String that also drawfills with cl_textopacity.
//
void(vector position, string text, vector size, vector rgb, float alpha, float drawflag) HUD_DrawStringWithBackdrop =
{
	drawfill([position_x - 4, position_y - 4], [getTextWidth(text, size_x) + 6, size_y + 6], [0, 0, 0], cvar("cl_textopacity") * alpha, 0);
	Draw_String(position, text, size, rgb, alpha, drawflag);
}

/*******************
*    HUD_Health   *
*******************/

void() HUD_Health = 
{
	float health;
	float max_health;	
	float alpha;
	
	health = getstatf(STAT_HEALTH); 
	max_health = getstatf(STAT_MAXHEALTH);

	if (health < max_health)
	{
		alpha = 255 - ((health/max_health))*255;

		if (alpha <= 0.0)
			return;
		float modifier = (sin(time * 10) * 20) - 20;//always negative
		if(modifier < -35.0)
		modifier = -35.0;
    
		alpha += modifier;
    
		if(alpha < 0.0)
			return;
		float color = 255.0 + modifier;
    
		drawpic([0,0,0], "gfx/hud/blood.tga", [g_width, g_height, 0], [10,0,0], alpha/2000); // naievil -- alpha factor division here makes it easy to use legacy code
	}
	
}

/*******************
*    HUD_Ammo      *
*******************/

void() HUD_Ammo =
{
	if (cl_viewent.modelindex == 0)
	 	return;

	float alpha = HUD_GetAlphaForWeaponObjects();

	float ammo, curmag;
	string ammostring, ammostring_1, ammostring_2;
	vector color;
	
	curmag = getstatf(STAT_CURRENTMAG);		
	ammo = getstatf(STAT_AMMO);	
	
	if (W_IsLowAmmo(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_CURRENTMAG), true))
		color = [215/255, 0, 0];
	else
		color = [1, 1, 1];
	
	if (W_IsLowAmmo(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_AMMO), false))
		vector color_2 = [215/255, 0, 0];
	else
		color_2 = [1, 1, 1];

	if (IsDualWeapon(getstatf(STAT_ACTIVEWEAPON))) {
		float curmag2 = getstatf(STAT_CURRENTMAG2);
		
		ammostring = strcat(ftos(curmag2), " ", ftos(curmag), "/", ftos(ammo));
		float x2 = (g_width - GetUltraWideOffset()) - 62 - getTextWidth(ammostring, 12);
		HUD_DrawStringWithBackdrop([x2, g_height - 29], ammostring, [12, 12], [1,1,1], alpha, 0);
	} else {
		ammostring_1 = ftos(curmag);
		ammostring_2 = strcat("/", ftos(ammo));
		string weapon_ammo_string = strcat(ftos(curmag), "/", ftos(ammo));
		float x = (g_width - GetUltraWideOffset())  - 62 - getTextWidth(weapon_ammo_string, 12);
		HUD_DrawStringWithBackdrop([x, g_height - 29], ammostring_1, [12, 12], color, alpha, 0);
		HUD_DrawStringWithBackdrop([x + getTextWidth(ammostring_1, 12), g_height - 29], ammostring_2, [12, 12], color_2, alpha, 0);
	}
}

//
// HUD_AmmoString()
// Draws the "LOW AMMO", "Reload", etc. text
//
float ammoopac, ammoloop;
void() HUD_AmmoString =
{
	if (cl_viewent.modelindex == 0)
		return;

	vector 	textcolor = [1, 1, 1];
	string 	message = "";
	float	reserve_is_empty;
	float	mag_is_low;

	// Is the Reserve low?
	reserve_is_empty = getstatf(STAT_AMMO) <= 0;

	// Is the Magazine low?
	mag_is_low = W_IsLowAmmo(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_CURRENTMAG), true);

	// When the mag isn't low, there's nothing to do here.
	if (mag_is_low == false) {
		ammoopac = 1;
		ammoloop = 0;
		return;
	} else {
		// Report NO AMMO if both current mag and reserve are empty
		if (getstatf(STAT_CURRENTMAG) <= 0 && reserve_is_empty == true)
		{
			message = "NO AMMO";
			textcolor = [215/255, 0, 0];
		}
		// Display LOW AMMO if mag is low and reserve is empty
		else if (reserve_is_empty == true)
		{
			message = "LOW AMMO";
			textcolor = [219/255, 203/255, 19/255];
		}
		// Otherwise, just display reload text
		else
		{
            message = "Reload";
            textcolor = [1, 1, 1];
		}
	}

	// Blink the text and draw it.
	if (ammoloop == 0) {
			ammoopac -= frametime;
			if (ammoopac < 0.5) {
				ammoopac = 0.5;
				ammoloop = 1;
			}
	} else {
		ammoopac += frametime;
		if (ammoopac >= 1) {
			ammoopac = 1;
			ammoloop = 0;
		}
	}

	float x = (g_width/2) - (getTextWidth(message, 12)/2);
	HUD_DrawStringWithBackdrop([x, g_height/2 + 40, 0], message, [12, 12, 0], textcolor, ammoopac, 0);
}

/*******************
*    HUD_Points    *
*******************/

#define MAX_POINT_ELEMENTS 		64 		// the maximum amount of point differential elements that can be spawned before
								   		// we iterate back from 0

float active_point_elements;

var struct
{
	float 	difference; 				// the difference of points
	float 	x_position; 				// current x position
	float 	y_position; 				// current y position
	float 	x_velocity; 				// how fast the element moves on the x axis
	float 	y_velocity; 				// how fast the element moves on the y axis
	float 	opacity; 					// the opacity of the text_string as it progresses
	float 	string_width; 				// the width of text_string
	float 	occupied;					// is this array being used/occupied?
	float 	playerid; 					// who does this element belong to?
	string 	text_string; 				// either '+(difference)' or '-(difference)'
} point_elements[MAX_POINT_ELEMENTS];

float last_point_element_index;

void(float amount, float playernum) RegisterPointChange =
{
	if (last_point_element_index >= MAX_POINT_ELEMENTS)
		last_point_element_index = 0;

	float index = last_point_element_index;

	// set the difference amount
	point_elements[index].difference = amount;

	// assign it to the player
	point_elements[index].playerid = playernum;

	// fill our text string
	if (point_elements[index].difference > 0) {
		point_elements[index].text_string = strcat("+", ftos(point_elements[index].difference));
	} else {
		point_elements[index].text_string = ftos(point_elements[index].difference);
	}

	// determine the width of the text string
	point_elements[index].string_width = getTextWidth(point_elements[index].text_string, 12);

	// generate a velocity
	point_elements[index].y_velocity = random()/4;
	while (point_elements[index].x_velocity < 0.33) {
		point_elements[index].x_velocity = random();
	}

	if (point_elements[index].x_velocity > 0.70)
		point_elements[index].x_velocity -= 0.2;

	// should the vertical velocity be positive or negative?
	float rng = random();

	// negative
	if (rng < 0.5) {
		point_elements[index].y_velocity = -point_elements[index].y_velocity;
	}

	// set our x and y positions
	point_elements[index].x_position = 0;
	point_elements[index].y_position = (g_height - 90) - (25 * (playernum - 1));

	// start with an opacity of 1
	point_elements[index].opacity = 1;

	// the element is being used
	point_elements[index].occupied = true;

	// iterate
	last_point_element_index++;
	active_point_elements++;
}

void(float pwidth, float playernum) PointUpdate = 
{
	if (active_point_elements == 0)
		return;

	vector POINT_DIFF_COLOR;

	for (float i = 0; i < MAX_POINT_ELEMENTS; i++) {
		if (point_elements[i].playerid != playernum)
			continue;

		if (point_elements[i].opacity <= 0 && point_elements[i].occupied == true) {
			point_elements[i].occupied = false;
			active_point_elements--;
			continue;
		}

		// should the text be red or orange?
		if (point_elements[i].difference > 0) {
			POINT_DIFF_COLOR = TEXT_ORANGE;
		} else {
			POINT_DIFF_COLOR = TEXT_RED;
		}

		if (point_elements[i].difference != 0 && point_elements[i].opacity > 0) {
			Draw_String([pwidth - point_elements[i].string_width - point_elements[i].x_position, 
			point_elements[i].y_position], point_elements[i].text_string, [12, 12], 
			POINT_DIFF_COLOR, point_elements[i].opacity, 0);
		}

		point_elements[i].x_position -= point_elements[i].x_velocity * (frametime*375);
		point_elements[i].y_position += point_elements[i].y_velocity * (frametime*375);
		point_elements[i].opacity -= (frametime*4);
	}
}

void() HUD_Points =
{
	float pointlength = 0, increm = 10, pointwidth = 0, x = 0;
	float backwidth = 0.8*g_width;
	vector TEXTCOLOR = '0 0 0';

	for (int i = 7; i >= 0; i = i - 1)
	{
		float player_number = getplayerkeyfloat(i, "client_index");
		entity client = findfloat(world, playernum, player_number);

		if ((client == world || !client.classname) && !client.is_spectator)
			continue;

		TEXTCOLOR = HUD_ResolveTextColorForPlayer(i);

		pointwidth = getTextWidth(ftos(client.points), 12);
		x = (99 - pointwidth)/2 + GetUltraWideOffset();

		if (player_number == getstatf(STAT_PLAYERNUM)) {
			drawpic([3 + GetUltraWideOffset(), g_height - 97 - (i * 25)], "gfx/hud/moneyback.tga", [96, 24], [1,1,1], 1);
			HUD_DrawStringWithBackdrop([x, g_height - 92 - (i * 25)], ftos(client.points), [12, 12], TEXTCOLOR, 1, 0);
		} else {
			drawpic([-7 + GetUltraWideOffset(), g_height - 97 - (i * 25)], "gfx/hud/moneyback_condensed.tga", [96, 24], [1,1,1], 1);
			HUD_DrawStringWithBackdrop([x - 9, g_height - 92 - (i * 25)], ftos(client.points), [12, 12], TEXTCOLOR, 1, 0);
		}

		PointUpdate(x + 70, player_number);
	}
}

/************************
*    HUD_CharacterName  *
************************/

void() HUD_CharacterName =
{
	if (nameprint_time <= time)
		return;

	float x = 100 + GetUltraWideOffset();
	float alpha = 1;

	if (nameprint_time - 1 < time) {
		alpha = (nameprint_time - time);
	}
	HUD_DrawStringWithBackdrop([x, g_height - 92 - ((getstatf(STAT_PLAYERNUM) - 1) * 25)], character_name, [12, 12], [1, 1, 1], alpha, 0);
}

/*******************
*    HUD_Grenades  *
*******************/

void() HUD_Grenades =
{
	float grenades;
	float betties;
	float alpha = HUD_GetAlphaForWeaponObjects();

	vector grenade_text_color;
	vector betties_text_color;

	grenades = getstatf(STAT_GRENADES);
	betties = getstatf(STAT_SECGRENADES);

	if (grenades == 0)
		grenade_text_color = [1, 0, 0];
	else
		grenade_text_color = [1, 1, 1];

	if (betties == 0)
		betties_text_color = [1, 0, 0];
	else
		betties_text_color = [1, 1, 1];

	drawpic([g_width - 3 - 56 - GetUltraWideOffset(), g_height - 50], "gfx/hud/frag.tga", [32, 32], [1, 1, 1], alpha);
	HUD_DrawStringWithBackdrop([g_width - 3 - 38 - GetUltraWideOffset(), g_height - 29], ftos(grenades), [12, 12], grenade_text_color, alpha, 0);

	if (betties != -1) {
		drawpic([g_width - 3 - 28 - GetUltraWideOffset(), g_height - 50], "gfx/hud/betty.tga", [32, 32], [1, 1, 1], alpha);
		HUD_DrawStringWithBackdrop([g_width - 3 - 10 - GetUltraWideOffset(), g_height - 29], ftos(betties), [12, 12], betties_text_color, alpha, 0);
	}
}

/*******************
*    HUD_Rounds    *
*******************/

// This is 107 on Vril Engine, but since our RGB mode is different
// in FTE we tone it down considerably to still look blood-red.
#define ROUND_RED_SHIFT		20

float 	color_shift[3];
float 	color_shift_end[3];
float 	color_shift_steps[3];
int		color_shift_init;
int 	blinking;
string sb_round[5];
string sb_round_num[10];
int alphabling;
float endroundchange;
float round_center_x;
float round_center_y;
//motolegacy -- 'round' text
float pwidth;
float rcolor, rinit, ralpha, localpha;

void() HUD_Rounds =
{	
	float roundheight = 65;
	float roundwidth = 15;
	
	float roundwidth_4 = 81;
	float roundheight_4 = 65;
	
	float roundheight_num = 65;
	float roundwidth_num = 43; // naievil -- was 32, but more square makes it look better

	int i, x_offset, icon_num, savex;
	int num[3];
	x_offset = 0;
	savex = 0;

	for (float j = 0; j < 10; j++) {
		if (j < 5) {
			sb_round[j] = getImage(strcat("r", ftos(j+1), ".tga"));
		}

		sb_round_num[j] = getImage(strcat("r_num", ftos(j), ".tga"));
	}

	if (rounds_change == 1 || rounds_change == 2) {
		if (!rinit) {
			rcolor = rinit = 1;
			ralpha = 1;
		}

		pwidth = getTextWidth("Round", 24)/2;
		Draw_String([(g_width/2) - pwidth, g_height/2 - 70], "Round", [24, 24], [1, rcolor, rcolor], ralpha, 0);

		rcolor -= frametime/2.5;
		if (rcolor < 0) {
			rcolor = 0;
			ralpha -= frametime/2.5;
			if (ralpha > 0) {
				localpha += frametime*0.4;
				if (localpha > 1)
					localpha = 1;
			}
			if (ralpha < 0) {
				ralpha = 0;
				localpha -= frametime*0.4;
				if (localpha < 0)
					localpha = 0;
			}
		}

		Draw_String([g_width - 3 - GetUltraWideOffset() - getTextWidth(chaptertitle, 12), g_height/2 + 48], chaptertitle, [12, 12], [1, 1, 1], localpha, 0);
		Draw_String([g_width - 3 - GetUltraWideOffset() - getTextWidth(location, 12), g_height/2 + 60], location, [12, 12], [1, 1, 1], localpha, 0);
		Draw_String([g_width - 3 - GetUltraWideOffset() - getTextWidth(date, 12), g_height/2 + 72], date, [12, 12], [1, 1, 1], localpha, 0);
		Draw_String([g_width - 3 - GetUltraWideOffset() - getTextWidth(person, 12), g_height/2 + 84], person, [12, 12], [1, 1, 1], localpha, 0);
	}

	if (rounds_change == 1)//this is the rounds icon at the middle of the screen
	{
		alphabling = alphabling + (frametime*500);

		if (alphabling < 0)
			alphabling = 0;
		else if (alphabling > 255)
			alphabling = 255;
			
		round_center_x = g_width/2 - 6;
		round_center_y = g_height/2 - 36;
		
		drawpic([round_center_x,round_center_y,0], sb_round[0], [roundwidth, roundheight], [ROUND_RED_SHIFT/255,1/255], alphabling/255);
	}
	else if (rounds_change == 2)//this is the rounds icon moving from middle
	{
		stopwatch_round_isactive = true;
		float round_center_y_offset = 0;
		float round_center_x_offset = 0;
				
		drawpic([round_center_x + round_center_x_offset,round_center_y + round_center_y_offset,0], sb_round[0], [roundwidth,roundheight, 1], [ROUND_RED_SHIFT/255,(1/255),0], 1);
		
		round_center_x = round_center_x - (((229/108)*2 - 0.2)*((g_width - GetUltraWideOffset())/480)/8) * (frametime*250);
		round_center_y = round_center_y + ((2*(g_height/272))/8) * (frametime*250);

		if (round_center_x <= 3 + GetUltraWideOffset())
			round_center_x = 3 + GetUltraWideOffset();
		if (round_center_y >= g_height - 1 - roundheight)
			round_center_y = g_height - 1 - roundheight;
	}
	else if (rounds_change == 3)//shift to white
	{
		stopwatch_round_isactive = false;
		if (!color_shift_init)
		{
			color_shift[0] = ROUND_RED_SHIFT;
			color_shift[1] = 1;
			color_shift[2] = 0;
			for (i = 0; i < 3; i = i + 1)
			{
				color_shift_end[i] = 255;
				color_shift_steps[i] = (color_shift_end[i] - color_shift[i])/60;
			}
			color_shift_init = 1;
		}
		for (i = 0; i < 3; i = i + 1)
		{
			if (color_shift[i] < color_shift_end[i])
				color_shift[i] = color_shift[i] + color_shift_steps[i]*(frametime*100);

			if (color_shift[i] >= color_shift_end[i])
				color_shift[i] = color_shift_end[i];
		}
		if (rounds > 0 && rounds < 11)
		{

			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5 + GetUltraWideOffset(), g_height - roundheight, 0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
					
					savex = x_offset + (10*g_width/480);
					x_offset = x_offset + (10*g_width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth + (3*g_width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[2]], [roundwidth_num, roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
								
				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

			x_offset = x_offset +  roundwidth_num - (8*g_width/480);
		}
	}
	else if (rounds_change == 4)//blink white
	{
	
		if (endroundchange > time)
		{
			blinking = ((int)(time*475)&510) - 255;
			blinking = fabs(blinking);
		}
		else
		{
			if (blinking)
				blinking = blinking - 1;
			else
				blinking = 0;
		}
			
	
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5 + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					savex = x_offset + (10*g_width/480);
					x_offset = x_offset + (10*g_width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

					drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*g_width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
					
				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
				
				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
			
			x_offset = x_offset +  roundwidth_num - (8*g_width/480);
		}
		
		if (endroundchange == 0) {
			endroundchange = time + 7.5;
			blinking = 0;
		}
	}
	else if (rounds_change == 5)//blink white
	{
		if (blinking > 0)
			blinking = blinking - (frametime*5000);
		if (blinking < 0)
			blinking = 0;
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5 + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					savex = x_offset + (10*g_width/480);
					x_offset = x_offset + (10*g_width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);
					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*g_width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

			x_offset = x_offset +  roundwidth_num - (8*g_width/480);
		}
	}
	else if (rounds_change == 6)//blink white while fading back
	{
		endroundchange = 0;
		
		color_shift_init = 0;
		blinking += frametime*500;
		if (blinking > 255) blinking = 255;
			
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5 + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);
								
					savex = x_offset + (10*g_width/480);
					x_offset = x_offset + (10*g_width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*g_width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
				
				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

			x_offset = x_offset +  roundwidth_num - (8*g_width/480);
		}
	}
	else if (rounds_change == 7)//blink white while fading back
	{
		stopwatch_round_isactive = true;
		stopwatch_round_hr = stopwatch_round_min = stopwatch_round_sec = 0;
		if (!color_shift_init)
		{
			color_shift_end[0] = ROUND_RED_SHIFT;
			color_shift_end[1] = 1;
			color_shift_end[2] = 0;
			for (i = 0; i < 3; i = i + 1)
			{
				color_shift[i] = 255;
				color_shift_steps[i] = (color_shift[i] - color_shift_end[i])*(frametime*1.5);
			}
			color_shift_init = 1;
		}
		for (i = 0; i < 3; i = i + 1)
		{
			if (color_shift[i] > color_shift_end[i])
				color_shift[i] = color_shift[i] - color_shift_steps[i];

			if (color_shift[i] < color_shift_end[i])
				color_shift[i] = color_shift_end[i];
		}
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5 + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

					savex = x_offset + (10*g_width/480);
					x_offset = x_offset + (10*g_width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth + (3*g_width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2+x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2+x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2+x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

			x_offset = x_offset +  roundwidth_num - (8*g_width/480);
		}
	}
	else
	{
		color_shift[0] = ROUND_RED_SHIFT;
		color_shift[1] = 1;
		color_shift[2] = 0;
		color_shift_init = 0;
		alphabling = 0;
		if (rounds > 0 && rounds < 11)
		{
			for (i = 0; i < rounds; i = i + 1)
			{
				if (i == 4)
				{
					drawpic([5 + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [ROUND_RED_SHIFT/255,1/255,0], 1);

					savex = x_offset + (10*g_width/480);
					x_offset = x_offset + (10*g_width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [ROUND_RED_SHIFT/255,1/255,0], 1);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [ROUND_RED_SHIFT/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth + (3*g_width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [ROUND_RED_SHIFT/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [ROUND_RED_SHIFT/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth_num - (8*g_width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			
			if(rounds == 0)
				return;
			
			drawpic([2 + x_offset + GetUltraWideOffset(), g_height - roundheight - (4*g_height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [ROUND_RED_SHIFT/255,1/255,0], 1);

			x_offset = x_offset +  roundwidth_num - (8*g_width/480);
		}
	}
}

/*******************
*    HUD_Useprint  *
*******************/

void() HUD_Useprint =
{
	if (useprint_time <= time) 
		return;

	string usestring, usespace;
	string usecost;
	float print_width, x, button_width;
	
	usestring = "";
	usespace = "";
	usecost = "";

	string usebutton = "";
    float argc = tokenize(findkeysforcommandex("+button7"));

    for (int i = 0; i < argc; i++) {
		string temp_button = strtoupper(argv(i));
        float bind_is_gamepad = Key_IsControllerGlyph(temp_button);

		// Always display the last button in the last.
        if (bind_is_gamepad && last_input_was_gamepad)
            usebutton = temp_button;
        else if (!bind_is_gamepad && !last_input_was_gamepad)
            usebutton = temp_button;
    }

    if (usebutton == "")
        usebutton = "UNBOUND";

	// If this is a gamepad button, the space we want to reserve
	// in the usestring should be a fixed width.
	if (Key_IsControllerGlyph(usebutton)) {
		usespace = " ";
	} 
	// Scale the space in the usestring for the bind according to
	// the bind's name.
	else {
		for(float i = 0; i < strlen(usebutton); i++) {
			usespace = strcat(usespace, " ");
		}
	}

	switch (useprint_type) {
		case 0://clear
			usestring = "";
			break;
		case 1://door
			usestring = strcat("Hold  ",usespace, " to open Door");
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 2://debris
			usestring = strcat("Hold  ",usespace, " to remove Debris");
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 3://ammo
			usestring = strcat("Hold  ",usespace, " to buy Ammo for ", GetWeaponName(useprint_weapon));
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 4://weapon
			usestring = strcat("Hold  ",usespace, " to buy ", GetWeaponName(useprint_weapon));
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 5://window
			usestring = strcat("Hold  ",usespace, " to Rebuild Barrier");
			break;
		case 6://box
			usestring = strcat("Hold  ",usespace, " for Mystery Box");
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 7://box take
			usestring = strcat("Hold  ",usespace, " for ", GetWeaponName(useprint_weapon));
			break;
		case 8://power
			usestring = "The Power must be Activated first";
			break;
		case 9://perk
			usestring = strcat("Hold  ",usespace, " to buy ", GetItemName(useprint_weapon));
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 10://turn on power
			usestring = strcat("Hold  ",usespace, " to Turn On the Power");
			break;
		case 11://turn on trap
			usestring = strcat("Hold  ",usespace, " to Activate the Trap");
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 12://packapunch
			usestring = strcat("Hold  ",usespace, " to Pack-a-Punch");
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 13://revive
			usestring = strcat("Hold  ",usespace, " to Revive Player");
			break;
		case 14://use teleporter (free)
			usestring = strcat("Hold  ", usespace, " to use Teleporter");
			break;
		case 15://use teleporter (cost)
			usestring = strcat("Hold  ", usespace, " to use Teleporter");
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 16://tp cooldown
			usestring = "Teleporter is cooling down";
			break;
		case 17://link
			usestring = strcat("Hold  ", usespace, " to initate link to pad");
			break;
		case 18://no link
			usestring = "Link not active";
			break;
		case 19://finish link
			usestring = strcat("Hold  ", usespace, " to link pad with core");
			break;
		case 20://buyable ending
			usestring = strcat("Hold  ", usespace, " to End the Game");
			usecost = strcat("[Cost: ", ftos(useprint_cost), "]");
			break;
		case 21: // Magic disabled
			usestring = "...";
			break;
		case 22: // Jugger-Nog (NIGHTMARE)
			usestring = "It doesn't seem to be working..";
			break;
		case 23: // Tactical Nuke (Gun Game)
			usestring = strcat("Hold ", usespace, " to Drop the Nuke");
			break;
		default:
			usestring = "This should not happen you dum fuck"; //yikes
			break;
	}

	print_width = getTextWidth(usestring, 12);
	x = (g_width - print_width)/2;

	if (useprint_type == 22)
		HUD_DrawStringWithBackdrop([x, g_height/2 + 65, 0], usestring, [12, 12, 0], [1, 0, 0], 1, 0);
	else
		HUD_DrawStringWithBackdrop([x, g_height/2 + 65, 0], usestring, [12, 12, 0], [1, 1, 1], 1, 0);

	// Draw "Cost" text.
	if (usecost != "") {
		float cost_width = getTextWidth(usecost, 12);
		float x3 = (g_width - cost_width)/2;
		HUD_DrawStringWithBackdrop([x3, g_height/2 + 84, 0], usecost, [12, 12, 0], [1, 1, 1], 1, 0);
	}

	// Draw highlighted usebutton
	if (substring(usestring, 0, 4) == "Hold") {
		button_width = x + getTextWidth("Hold ", 12);

		if (Key_IsControllerGlyph(usebutton))
			Key_DrawControllerGlyph([button_width - 5, g_height/2 + 62], usebutton, [18, 18]);
		else
			Draw_String([button_width, g_height/2 + 65, 0], usebutton, [12, 12, 0], [1, 1, 0], 1, 0);
	}
}

/*******************
*    HUD_Perks     *
*******************/

int perk_order[9];
int current_perk_order;

void() UpdatePerks = 
{
	float new_perks = getstatf(STAT_PERKS);

	if (perks == new_perks)
		return;

	float s;

	// avoids out of bounds err - moto
	if (new_perks == 0)
		current_perk_order = 0;

	for(float i = 1; i < 129; i *= 2) {
		if (new_perks & i && !(perks & i)) {
			perk_order[current_perk_order] = i;
			current_perk_order += 1;
		}
	}

	for(float i = 1; i < 129; i *= 2) {
		if (perks & i && !(new_perks & i)) 
		{
			for(s = 0; s < 8; s++) 
			{
				if (perk_order[s] == i) 
				{
					perk_order[s] = 0;
					while (perk_order[s+1]) 
					{
						perk_order[s] = perk_order[s+1];
						perk_order[s+1] = 0;
					}
					break;
				}
			}
		}
	}
	
	perks = new_perks;
}

	
void() HUD_Perks =
{
	float scale;
	float x, y;

	// Update Perk Order.
	UpdatePerks();
	
	scale = 32;

	x = 20;
	y = 6;

	if (cvar("vid_ultrawide_limiter"))
		x += ULTRAWIDE_OFFSET;

	// Double-Tap can have 2 icons depending on
	// machine-specified version.
	string double_tap_icon;
	if (double_tap_version == 1) // damage buffed
		double_tap_icon = "gfx/hud/double2.tga";
	else // just rof
		double_tap_icon = "gfx/hud/double.tga";

	// Draw second column first -- these need to be
	// overlayed below the first column.
	for (float i = 4; i < 8; i++) {
		if (perk_order[i]) {
			if (perk_order[i] == P_JUG) {drawpic([x, y], "gfx/hud/jug.tga", [scale, scale], [1,1,1], 1);}
			if (perk_order[i] == P_DOUBLE) {drawpic([x, y], double_tap_icon, [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_SPEED) {drawpic([x, y], "gfx/hud/speed.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_REVIVE) {drawpic([x, y], "gfx/hud/revive.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_FLOP) {drawpic([x, y], "gfx/hud/flopper.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_STAMIN) {drawpic([x, y], "gfx/hud/stamin.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_DEAD) {drawpic([x, y], "gfx/hud/dead.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_MULE) {drawpic([x, y], "gfx/hud/mule.tga", [scale, scale, 1], [1,1,1], 1);}
		}
		y += scale;
	}

	x = 3;
	y = 6;

	if (cvar("vid_ultrawide_limiter"))
		x += ULTRAWIDE_OFFSET;

	// Now the first column.
	for (float i = 0; i < 4; i++) {
		if (perk_order[i]) {
			if (perk_order[i] == P_JUG) {drawpic([x, y], "gfx/hud/jug.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_DOUBLE) {drawpic([x, y], double_tap_icon, [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_SPEED) {drawpic([x, y], "gfx/hud/speed.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_REVIVE) {drawpic([x, y], "gfx/hud/revive.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_FLOP) {drawpic([x, y], "gfx/hud/flopper.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_STAMIN) {drawpic([x, y], "gfx/hud/stamin.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_DEAD) {drawpic([x, y], "gfx/hud/dead.tga", [scale, scale, 1], [1,1,1], 1);}
			if (perk_order[i] == P_MULE) {drawpic([x, y], "gfx/hud/mule.tga", [scale, scale, 1], [1,1,1], 1);}
		}
		y += scale;
	}
}

/*******************
*    HUD Weapons   *
*******************/

float weapon_name_time;
string weapon_name_last;

void() HUD_WeaponString =
{
	if (cl_viewent.modelindex == 0)
		return;

	string weapon_name = GetWeaponName(getstatf(STAT_ACTIVEWEAPON));

	// If the string matches our last store, bail out.
	if (weapon_name == weapon_name_last && weapon_name_time <= time) {
		return;
	} else if (weapon_name != weapon_name_last) {
		// three seconds: one for display, two for fade out.
		weapon_name_time = time + 3;

		// Update last string storage.
		weapon_name_last = weapon_name;
	}

	float weapon_name_alpha;

	if (weapon_name_time - time > 2) {
		weapon_name_alpha = 1;
	} else {
		weapon_name_alpha = (weapon_name_time - time)/2;	
	}

	float x = g_width - 62 - getTextWidth(weapon_name, 12);

	HUD_DrawStringWithBackdrop([x - GetUltraWideOffset(), g_height - 49], weapon_name, [12, 12], [1, 1, 1], weapon_name_alpha, 0);
}

/*********************
* HUD Bouncing Betty *
*********************/

void() HUD_BouncingBetty =
{
	if (bettyprompt_time <= time)
		return;

	float top_x, bot_x, but_x;
	string betty_key = "";
	string betty_space = "";
	string activate_string, activate_string2;

	float argc = tokenize(findkeysforcommandex("impulse 33"));

	for (int i = 0; i < argc; i++) {
		string temp_button = strtoupper(argv(i));
        float bind_is_gamepad = Key_IsControllerGlyph(temp_button);

		// Always display the last button in the last.
        if (bind_is_gamepad && last_input_was_gamepad)
            betty_key = temp_button;
        else if (!bind_is_gamepad && !last_input_was_gamepad)
            betty_key = temp_button;
    }

	// If this is a gamepad button, the space we want to reserve
	// in the betty string should be a fixed width.
	if (Key_IsControllerGlyph(betty_key)) {
		betty_space = "  ";
	} 
	// Scale the space in the betty string for the bind according to
	// the bind's name.
	else {
		for(float i = 0; i < strlen(betty_key); i++) {
			betty_space = strcat(betty_space, " ");
		}
	}

	activate_string = strcat("Press ", betty_space, " to place a");
	activate_string2 = "Bouncing Betty";

	top_x = (g_width/2) - (getTextWidth(activate_string, 12)/2);
	bot_x = (g_width/2) - (getTextWidth(activate_string2, 12)/2);

	HUD_DrawStringWithBackdrop([top_x, g_height - 303], activate_string, [12, 12], [1, 1, 1], 1, 0); 
	HUD_DrawStringWithBackdrop([bot_x, g_height - 289], activate_string2, [12, 12], [1, 1, 1], 1, 0); 

	// Draw the highlighted button
	but_x = top_x + getTextWidth("Press ", 12);

	if (Key_IsControllerGlyph(betty_key))
		Key_DrawControllerGlyph([but_x - 5, g_height - 308], betty_key, [18, 18]);
	else
		Draw_String([but_x, g_height - 303], betty_key, [12, 12], [1, 1, 0], 1, 0); 
}

/*******************
* HUD Progress Bar *
*******************/

void() HUD_Progressbar =
{
	float percent = getstatf(STAT_PROGRESSBAR);

	if (!percent)
		return;

	string progress; 
	local float ws_offset;
	
	progress = ftos(percent);
	ws_offset = (strlen(progress) - 1);

	float bar_width = 200;
	float bar_height = 12;
	float bar_x = (g_width - bar_width)/2;
	float bar_y = g_height*0.75;

	drawfill ([bar_x - 1, bar_y - 1, 0], [bar_width+2, bar_height, 0], [0, 0, 0], 0.4, 0);
	drawfill ([bar_x, bar_y, 0], [bar_width * percent, bar_height-2, 0], [1, 1, 1], 0.4, 0);
	float x = (g_width/2) - (getTextWidth("Reviving...", 12)/2);

	HUD_DrawStringWithBackdrop([x, g_height - 105], "Reviving...", [12, 12], [1, 1, 1], 1, 0); 
}

/*******************
*    HUD Hitmark   *
*******************/

void() HUD_Hitmark =
{
	if (hitmark_time <= time || cvar("cl_hitmarkers") == 0)
		return;

	float hitmark_alpha = 1;
	vector hitmark_color = [1, 1, 1];
	
	if (hitmark_type == 1) {
		hitmark_alpha = (hitmark_time - time) * 5;
		hitmark_color = [0.75, 0, 0];
	} else {
		hitmark_alpha = (hitmark_time - time) * 3.3;
	}

	drawpic([g_width/2 - 10, g_height/2 - 10], "gfx/hud/hit_marker.tga", [20, 20], hitmark_color, hitmark_alpha);
}

/*******************
*   HUD Crosshair  *
*******************/

float croshhairmoving; // naievil --used t o see if we are moving or not
float cur_spread;
float crosshair_offset_step;
float crosshair_opacity;
vector crosshair_color;

void() HUD_Crosshair =
{
	if (cvar("cl_crosshair_debug")) {
		drawline(2, [g_width/2, g_height/2, 0], [0, g_height, 0], [1, 0, 0], 0.5);
		drawline(2, [g_width/2, g_height/2, 0], [g_width, 0, 0], [0, 1, 1], 0.5);
		drawline(2, [g_width, g_height, 0], [g_width/2, g_height/2, 0], [0, 1, 0], 0.5);
		drawline(2, [0, 0, 0], [g_width/2, g_height/2, 0], [0, 0, 1], 0.5);
	}

	hide_viewmodel = false;
	if (getstatf(STAT_WEAPONZOOM) == 2 && zoom_2_time < time)
    {
		hide_viewmodel = true;
		drawfill('0 0 0',  [g_width/2 - g_height/2, g_height, 0], '0 0 0', 1, 0);
		drawpic([(g_width/2 - g_height/2),0,0], "gfx/hud/scope_nb.tga", [g_height, g_height, 1], [1,1,1], 1);
		drawfill([(g_width/2 + g_height/2),0,0],  [g_width, g_height, 0], '0 0 0', 1, 0);

		// Draw "Hold Breath" text if we aren't already doing so and we don't have Deadshot Daiquiri.
		if (sniper_hold_breath != true && !(getstatf(STAT_PERKS) & P_DEAD)) {
			// Grab the bind for Sprint/Hold Breath
			string breath_button = "";
			string space_width = "";

			float argc = tokenize(findkeysforcommandex("impulse 23"));
			for (int i = 0; i < argc; i++) {
				string temp_button = strtoupper(argv(i));
				float bind_is_gamepad = Key_IsControllerGlyph(temp_button);

				// Always display the last button in the last.
				if (bind_is_gamepad && last_input_was_gamepad)
					breath_button = temp_button;
				else if (!bind_is_gamepad && !last_input_was_gamepad)
					breath_button = temp_button;
			}

			if (breath_button == "")
				breath_button = "UNBOUND";

			string breath_button_string = "  ";

			// If this is a gamepad button, the space we want to reserve
			// in the string should be a fixed width.
			if (!Key_IsControllerGlyph(breath_button)) {
				breath_button_string = breath_button;
			} 

			string breath_string = strcat("Hold ", breath_button_string, " to steady");
			float print_width = getTextWidth(breath_string, 12);
			float x = (g_width - print_width)/2;
			Draw_String([x, 65, 0], breath_string, [12, 12, 0], [1, 1, 1], 1, 0);

			// Draw highlighted button
			float button_width = x + getTextWidth("Hold ", 12);

			if (Key_IsControllerGlyph(breath_button))
				Key_DrawControllerGlyph([button_width - 5, 62], breath_button, [18, 18]);
			else
				Draw_String([button_width, 65, 0], breath_button, [12, 12, 0], [1, 1, 0], 1, 0);
		}

		return;
	}

	float crosshair_value = cvar("crosshair");
	if (!crosshair_value || getstatf(STAT_WEAPONZOOM) == 1)
		return;

	if (!crosshair_opacity)
		crosshair_opacity = 1;

	if ((K_BACKDOWN || K_FORWARDDOWN || K_LEFTDOWN || K_RIGHTDOWN || input_buttons == 2) && crosshair_value == 1) {
		croshhairmoving = 1;

		crosshair_opacity -= frametime;

		if (crosshair_opacity < 0.5)
			crosshair_opacity = 0.5;
		
		if (cur_spread >= CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE))) {
			cur_spread = CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE));
		} else {
			cur_spread += (frametime*160);

		}
	} else {
		croshhairmoving = 0;
		
		if (cur_spread > 0)
			cur_spread -= (frametime*160);
		else 
			cur_spread = 0;

		crosshair_opacity += frametime;

		if (crosshair_opacity > 1)
			crosshair_opacity = 1;
	}

	// Update values to be red if we're facing an enemy
	if (getstatf(STAT_FACINGENEMY))
		crosshair_color = TEXT_RED;
	else
		crosshair_color = [1, 1, 1];
	
	if (getstatf(STAT_HEALTH) < 1)
		return;

	// Standard crosshair (+)
	if (crosshair_value == 1) {
		int x_value, y_value;
		int crosshair_offset;
			
		crosshair_offset = CrossHairWeapon(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE)) + cur_spread;
			
		if (CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE)) < crosshair_offset)
			crosshair_offset = CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE));
			
		if (perks & P_DEAD)
			crosshair_offset *= 0.65;

		crosshair_offset_step += (crosshair_offset - crosshair_offset_step) * 0.5;

		// Creds to heartologic for some actually good crosshair position stuff.
		vector crossSize = [1, 5];
		vector screenSize = [g_width, g_height];

		drawfill(screenSize / 2 - [crossSize.x, +crossSize.y * 2 + crosshair_offset_step], crossSize, crosshair_color, crosshair_opacity, 0); // top
		drawfill(screenSize / 2 - [crossSize.x, -crossSize.y * 1 - crosshair_offset_step + 2], crossSize, crosshair_color, crosshair_opacity, 0); // bottom
		drawfill(screenSize / 2 - [+crossSize.y * 2 + crosshair_offset_step, crossSize.x], [crossSize.y, crossSize.x], crosshair_color, crosshair_opacity, 0); // right
		drawfill(screenSize / 2 - [-crossSize.y * 1 - crosshair_offset_step, crossSize.x], [crossSize.y, crossSize.x], crosshair_color, crosshair_opacity, 0); // left
	}
	// Area of Effect (o)
	else if (crosshair_value == 2) {
		float circle_offset = getTextWidth("O", 14)/2;
		Draw_String([g_width/2 - circle_offset, g_height/2 - circle_offset], "O", [14, 14], crosshair_color, 1, 0);
	}
	// Dot crosshair (.)
	else if (crosshair_value == 3) {
		vector screenSize2 = [g_width, g_height];
		drawfill(screenSize2 / 2 - [2, 2], [4, 4], crosshair_color, crosshair_opacity, 0); // dot
	}
	// Grenade crosshair
	else if (crosshair_value == 4) {
		if (crosshair_pulse_grenade) {
			crosshair_offset_step = 0;
			cur_spread = 12;
		}

		crosshair_pulse_grenade = false;

		int crosshair_offset2;	
		crosshair_offset2 = 3 + cur_spread;
		crosshair_offset_step += (crosshair_offset2 - crosshair_offset_step) * 0.05;

		// Creds to heartologic for some actually good crosshair position stuff.
		vector crossSize2 = [1, 5];
		vector screenSize3 = [g_width, g_height];

		drawfill(screenSize3 / 2 - [crossSize2.x, +crossSize2.y * 2 + crosshair_offset_step], crossSize2, crosshair_color, crosshair_opacity, 0); // top
		drawfill(screenSize3 / 2 - [crossSize2.x, -crossSize2.y * 1 - crosshair_offset_step + 2], crossSize2, crosshair_color, crosshair_opacity, 0); // bottom
		drawfill(screenSize3 / 2 - [+crossSize2.y * 2 + crosshair_offset_step, crossSize2.x], [crossSize2.y, crossSize2.x], crosshair_color, crosshair_opacity, 0); // right
		drawfill(screenSize3 / 2 - [-crossSize2.y * 1 - crosshair_offset_step, crossSize2.x], [crossSize2.y, crossSize2.x], crosshair_color, crosshair_opacity, 0); // left
	}
}

void() HUD_Powerups =
{
	float count = 0;

	// horrible way to offset check :)))))))))))))))))) :DDDDDDDD XOXO

	if (getstatf(STAT_X2))
		count++;

	if (getstatf(STAT_INSTA))
		count++;

	// both are avail draw fixed order
	if (count == 2) {
		drawpic([g_width/2 - (2 + 32), g_height - 38], "gfx/hud/2x.tga", [32, 32], [1, 1, 1], 1);
		drawpic([g_width/2 + 2, g_height - 38], "gfx/hud/in_kill.tga", [32, 32], [1, 1, 1], 1);
	} else {
		if (getstatf(STAT_X2))
			drawpic([g_width/2 - 16, g_height - 38], "gfx/hud/2x.tga", [32, 32], [1, 1, 1], 1);
		else if (getstatf(STAT_INSTA))
			drawpic([g_width/2 - 16, g_height - 38], "gfx/hud/in_kill.tga", [32, 32], [1, 1, 1], 1);
	}
}

void() HUD_Broadcast = 
{
	if (broadcast_time <= time)
		return;

	// broadcast_num refers to the playernum of the client. This
	// does NOT correspond to player key indexes, so we need to
	// grab the player with the matching playernum and use infokeys.
	entity player_target = findfloat(world, playernum, broadcast_num);
	string broadcast_name = infokey(player_target, INFOKEY_P_NAME);

	string broadcast_msg = "";

	switch(broadcast_type) {
		case CSQC_BROADCAST_PLAYERDOWNED:
			broadcast_msg = strcat(broadcast_name, " needs to be revived");
			break;
		case CSQC_BROADCAST_BEINGREVIVED:
			broadcast_msg = strcat(broadcast_name, " is reviving you");
			break;
		case CSQC_BROADCAST_REVIVINGPLAYER:
			broadcast_msg = strcat("Reviving ", broadcast_name);
			break;
		case CSQC_BROADCAST_GUNGAMEADVANCEMENT:
			broadcast_msg = strcat(broadcast_name, " reached a new tier!");
			break;
		case CSQC_BROADCAST_GUNGAMEWINNER:
			broadcast_msg = strcat(broadcast_name, " can Activate the Nuke!");
			break;
		case CSQC_BROADCAST_NONE:
			broadcast_msg = "";
			break;
		default:
			broadcast_msg = "Bad broadcast.";
			break;
	}

	float print_width = getTextWidth(broadcast_msg, 12);
	float x = (g_width - print_width)/2;

	if (broadcast_msg != "") {
		HUD_DrawStringWithBackdrop([x, g_height/2, 0], broadcast_msg, [12, 12], [1, 1, 1], 1, 0);
	}
};

void(float y_pos) HUD_DrawMoneyBackDisplay =
{
	int i;

	// Center moneyback
	drawpic([g_width/2 - 48, y_pos], "gfx/hud/moneyback.tga", [96, 24], [1,1,1], 1);
	// Left
	for(i = 0; i < 3; i++) {
		drawpic([(g_width/2 - 48) - (70 * (i + 1)), y_pos], "gfx/hud/moneyback.tga", [96, 24], [1,1,1], 1);
	}
	// Right
	for(i = 0; i < 3; i++) {
		drawpic([(g_width/2 - 48) + (70 * (i + 1)), y_pos], "gfx/hud/moneyback.tga", [96, 24], [1,1,1], 1);
	}
};

void() HUD_Scores =
{
	vector TEXTCOLOR = [1, 1, 1];

	float header_x_start = -75;
	float header_x_increment = 65;
	float scoreboard_text_size = 10;
	float header_x_pos = header_x_start;
	
	if(serverkey("constate") != "disconnected")
	{
		Draw_String([5, g_height - scoreboard_text_size - 5], sprintf("Nazi Zombies: Portable %s", build_datetime), [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0);

		// Scoreboard header
		drawfill([g_width/2 - 271, 177], [270 * 2 + 2, 1], [0.2, 0.2, 0.2], 1, 0);
		drawfill([g_width/2 - 271, 178 + scoreboard_text_size + 4], [270 * 2 + 2, 1], [0.2, 0.2, 0.2], 1, 0);
		drawfill([g_width/2 - 271, 178], [1, scoreboard_text_size + 4], [0.2, 0.2, 0.2], 1, 0);
		drawfill([g_width/2 + 270, 178], [1, scoreboard_text_size + 4], [0.2, 0.2, 0.2], 1, 0);
		drawfill([g_width/2 - 270, 178], [270 * 2, scoreboard_text_size + 4], [0, 0, 0], 0.80, 0);

		// Name
		string map_name = serverkey("mapname_pretty");
		Draw_String([g_width/2 - 265, 180], map_name, [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 

		Draw_String([g_width/2 + (header_x_pos - getTextWidth("Score", scoreboard_text_size)/2), 180], "Score", [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
		header_x_pos += header_x_increment;
		Draw_String([g_width/2 + (header_x_pos - getTextWidth("Kills", scoreboard_text_size)/2), 180], "Kills", [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
		header_x_pos += header_x_increment;
		Draw_String([g_width/2 + (header_x_pos - getTextWidth("Downs", scoreboard_text_size)/2), 180], "Downs", [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
		header_x_pos += header_x_increment;
		Draw_String([g_width/2 + (header_x_pos - getTextWidth("Revives", scoreboard_text_size)/2), 180], "Revives", [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
		header_x_pos += header_x_increment;
		Draw_String([g_width/2 + (header_x_pos - getTextWidth("Headshots", scoreboard_text_size)/2), 180], "Headshots", [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
		header_x_pos += header_x_increment;
	
		for (int i = 0; i < 4; i = i + 1)
		{
			float player_number = getplayerkeyfloat(i, "client_index");
			entity client = findfloat(world, playernum, player_number);

			if ((client == world || !client.classname) && !client.is_spectator)
				continue;
			
			TEXTCOLOR = HUD_ResolveTextColorForPlayer(i);

			float y_pos = (scoreboard_text_size + 5) * i;

			// Fill
			drawfill([g_width/2 - 270, 195 + y_pos], [270 * 2, scoreboard_text_size + 5], [0, 0, 0], 0.80, 0);
			drawfill([g_width/2 + (header_x_start - header_x_increment/2), 195 + y_pos], [header_x_increment, scoreboard_text_size + 5], [0.3, 0, 0], 0.15, 0);
			drawfill([g_width/2 + ((header_x_start + header_x_increment*2) - header_x_increment/2), 195 + y_pos], [header_x_increment, scoreboard_text_size + 5], [0.3, 0, 0], 0.15, 0);
			drawfill([g_width/2 + ((header_x_start + header_x_increment*4) - header_x_increment/2), 195 + y_pos], [header_x_increment, scoreboard_text_size + 5], [0.3, 0, 0], 0.15, 0);

			// Top
			if (i == 0)
				drawfill([g_width/2 - 271, 194 + y_pos], [270 * 2 + 2, 1], [0.2, 0.2, 0.2], 1, 0); 

			// Bottom
			if (player_count == i + 1)
				drawfill([g_width/2 - 271, 195 + y_pos + scoreboard_text_size + 4], [270 * 2 + 2, 1], [0.2, 0.2, 0.2], 1, 0);

			// Left
			drawfill([g_width/2 - 271, 194 + y_pos], [1, scoreboard_text_size + 6], [0.2, 0.2, 0.2], 1, 0);

			// Right			
			drawfill([g_width/2 + 270, 194 + y_pos], [1, scoreboard_text_size + 6], [0.2, 0.2, 0.2], 1, 0);

			header_x_pos = header_x_start;
			
			// Name
			string player_name = getplayerkeyvalue(i, "name");
			Draw_String([g_width/2 - 265, 197 + y_pos], player_name, [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 

			// Score
			string score_string = ftos(client.points);
			Draw_String([g_width/2 + (header_x_pos - getTextWidth(score_string, scoreboard_text_size)/2), 197 + y_pos], score_string, [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
			header_x_pos += header_x_increment;

			// Kills
			string kills_string = ftos(client.kills);
			Draw_String([g_width/2 + (header_x_pos - getTextWidth(kills_string, scoreboard_text_size)/2), 197 + y_pos], kills_string, [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
			header_x_pos += header_x_increment;

			// Downs
			string downs_string = ftos(client.downs);
			Draw_String([g_width/2 + (header_x_pos - getTextWidth(downs_string, scoreboard_text_size)/2), 197 + y_pos], downs_string, [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
			header_x_pos += header_x_increment;

			// Revives
			string revives_string = ftos(client.revives);
			Draw_String([g_width/2 + (header_x_pos - getTextWidth(revives_string, scoreboard_text_size)/2), 197 + y_pos], revives_string, [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
			header_x_pos += header_x_increment;

			// Headshots
			string headshots_string = ftos(client.headshots);
			Draw_String([g_width/2 + (header_x_pos - getTextWidth(headshots_string, scoreboard_text_size)/2), 197 + y_pos], headshots_string, [scoreboard_text_size, scoreboard_text_size], TEXTCOLOR, 1, 0); 
			
			// Ping
			float ping_num_bars;
			vector ping_bar_color = [0, 1, 0];

			if (client.ping < 100) {
				ping_num_bars = 4;
			} else if (client.ping < 200) {
				ping_num_bars = 3;
			} else if (client.ping < 300) {
				ping_num_bars = 2;
				ping_bar_color = [1, 0.5, 0];
			} else {
				ping_num_bars = 1;
				ping_bar_color = [1, 0, 0];
			}

			header_x_pos += 5 + header_x_increment/2;
			float ping_bar_width = 2;
			float ping_bar_height = 4;
			float ping_bar_height_increment = 2;

			string ping_string = sprintf("%dms", client.ping);
			Draw_String([g_width/2 + ((header_x_pos + 28) - getTextWidth(ping_string, scoreboard_text_size - 2)/2), 199 + y_pos], ping_string, [scoreboard_text_size - 2, scoreboard_text_size - 2], TEXTCOLOR, 1, 0); 

			for(float bars = ping_num_bars; bars > 0; bars--) {
				drawfill([g_width/2 + header_x_pos, 197 + y_pos + (11 - ping_bar_height)], [ping_bar_width, ping_bar_height], ping_bar_color, 1, 0);
				ping_bar_height += ping_bar_height_increment;
				header_x_pos += 3;
			}
		}
	}
}

void() HUD_Endgame = {
	string game_over = "GAME OVER";
	string survive;
	string round;

	if (rounds == 1)
		round = " Round";
	else
		round = " Rounds";

	survive = strcat("You Survived ", ftos(rounds), round);

	float game_over_width = getTextWidth(game_over, 24);
	HUD_DrawStringWithBackdrop([g_width/2 - game_over_width/2, 100], game_over, [24, 24], [1, 1, 1], 1, 0);

	float survive_width = getTextWidth(survive, 18);
	HUD_DrawStringWithBackdrop([g_width/2 - survive_width/2, 135], survive, [18, 18], [1, 1, 1], 1, 0);
}

//
// HUD_Screenflash()
// Screen fade in and out behaviors.
//
void() HUD_Screenflash = 
{  
	if (screenflash_duration <= time)
		return;

	vector color = '0 0 0';
	float flash_alpha = 0;

	// Obtain the flash color
	switch(screenflash_color) {
		case SCREENFLASH_COLOR_BLACK: color = '0 0 0'; break;
		case SCREENFLASH_COLOR_WHITE: color = '1 1 1'; break;
		default: color = '1 0 0'; break;
	}

	float percentage_complete = screenflash_worktime / (screenflash_duration - screenflash_starttime);

	// Fade Out
	if (screenflash_type == SCREENFLASH_FADE_OUT) {
		flash_alpha = invertfloat(percentage_complete);
	}
	// Fade In
	else if (screenflash_type == SCREENFLASH_FADE_IN) {
		flash_alpha = percentage_complete;
	}
	// Fade In + Fade Out
	else {
		// Fade In
		if (percentage_complete < 0.5) {
			flash_alpha = percentage_complete;
		} 
		// Fade Out
		else {
			flash_alpha = invertfloat(percentage_complete);
		}
	}

	screenflash_worktime += frametime;
	drawfill ([0, 0], [g_width, g_height, 0], color, flash_alpha, 0);
}

//
// HUD_MaxAmmo(width, height)
// Displays the "Max Ammo!" text on the HUD.
//
void() HUD_MaxAmmo =
{
	if (hud_maxammo_endtime <= time)
		return;

	string maxammo_string = "Max Ammo!";

	float start_y = 70;
	float end_y = 55;
	float diff_y = end_y - start_y;

	float text_alpha = 1;

	float string_width = getTextWidth(maxammo_string, 14);
	float pos_x = (g_width - string_width)/2;
	float pos_y;

	float start_time, end_time;

	// For the first 0.5s, stay still while we fade in
	if (hud_maxammo_endtime > time + 1.5) {
		start_time = hud_maxammo_starttime;
		end_time = hud_maxammo_starttime + 0.5;

		text_alpha = (time - start_time) / (end_time - start_time);
		pos_y = start_y;
	}
	// For the remaining 1.5s, fade out while we fly upwards.
	else {
		start_time = hud_maxammo_starttime + 0.5;
		end_time = hud_maxammo_endtime;

		float percent_time = (time - start_time) / (end_time - start_time);

		pos_y = start_y + diff_y * percent_time;
		text_alpha = 1 - percent_time;
	}

	HUD_DrawStringWithBackdrop([pos_x, pos_y, 0], maxammo_string, [14, 14], [1, 1, 1], text_alpha, 0);
};

float achievement_init;
float achievement_ypos;
float achievement_desc_ypos;
float achievement_img_ypos;
float achievement_time;
void() HUD_Achievements = {
	if (active_achievement == -1)
		return;

	if (!achievement_init) {
		achievement_time 		= 0;
		achievement_ypos 		= -0.16;
		achievement_desc_ypos	= -0.13;
		achievement_img_ypos 	= -0.164;
		achievement_init 		= true;
	}


	Draw_String([0.2*g_width, achievement_ypos*g_height, 0], "ACHIEVEMENT GET!", [0.015*g_width, 0.015*g_width, 0], [1, 1, 0], 1, 0);
	Draw_String([0.2*g_width, achievement_desc_ypos*g_height, 0], achievements[active_achievement].name, [0.015*g_width, 0.015*g_width, 0], [1, 1, 1], 1, 0);
	drawpic([0.005*g_width, achievement_img_ypos*g_height,0], achievements[active_achievement].img, [0.16*g_width, 0.08*g_width, 0], [1,1,1], 1);

	if (achievement_time <= 120) {
		achievement_ypos 		+= (frametime*0.15);
		achievement_desc_ypos 	+= (frametime*0.15);
		achievement_img_ypos	+= (frametime*0.15);
	} else {
		achievement_ypos 		-= (frametime*0.15);
		achievement_desc_ypos 	-= (frametime*0.15);
		achievement_img_ypos 	-= (frametime*0.15);
		if (achievement_desc_ypos <= -0.13) {
			achievement_init 	= 0;
			active_achievement 	= -1;
		}
	}

	if (achievement_desc_ypos > 0.045) {
		if (achievement_time <= 120) {
			achievement_ypos 		= 0.015;
			achievement_desc_ypos 	= 0.045;
			achievement_img_ypos 	= 0.01;
		}

		achievement_time += (frametime*25);
	}
}

void(float x_position, float y_position, string command, string action) HUD_DrawWaypointModeString =
{
	string bind_button = "";
	string bind_space = "";

	float argc = tokenize(findkeysforcommandex(command));

	for (int i = 0; i < argc; i++) {
		string temp_button = strtoupper(argv(i));
		float bind_is_gamepad = Key_IsControllerGlyph(temp_button);

		// Always display the last button in the last.
		if (bind_is_gamepad && last_input_was_gamepad)
			bind_button = temp_button;
		else if (!bind_is_gamepad && !last_input_was_gamepad)
			bind_button = temp_button;
	}

	if (bind_button == "")
		bind_button = "UNBOUND";

	// If this is a gamepad button, the space we want to reserve
	// in the usestring should be a fixed width.
	if (Key_IsControllerGlyph(bind_button)) {
		bind_space = " ";
	} 
	// Scale the space in the usestring for the bind according to
	// the bind's name.
	else {
		for(float i = 0; i < strlen(bind_button); i++) {
			bind_space = strcat(bind_space, "  ");
		}
	}

	string tooltip = sprintf("Press %s to %s", bind_space, action);
	float bind_x = x_position + getTextWidth("Press ", 12);

	Draw_String([x_position, y_position], tooltip, [12, 12], [1, 1, 1], 1, 0);

	if (Key_IsControllerGlyph(bind_button)) {
		Key_DrawControllerGlyph([bind_x - 5, y_position], bind_button, [15, 15]);
	} else {
		// FTE likes to use MOUSE1 and MOUSE2 for LMOUSE and RMOUSE respectively, which is obtuse.
		string bind_display = "";
		switch(bind_button) {
			case "MOUSE1": bind_display = "LMOUSE"; break;
			case "MOUSE2": bind_display = "RMOUSE"; break;
			default: bind_display = bind_button; break;
		}

		Draw_String([bind_x, y_position, 0], bind_display, [12, 12, 0], [1, 1, 0], 1, 0);
	}
};

void() HUD_Waypoint =
{
	drawfill([0, 4], [450, 190], [0, 0, 0], cvar("cl_textopacity"), 0);

	Draw_String([5, 8], "WAYPOINT MODE", [18, 18], [1, 1, 1], 1, 0);
	Draw_String([5, 30], "Create/Tweak Pathfind Nodes for Zombie AI", [12, 12], [1, 1, 0], 1, 0);
	Draw_String([5, 45], "(If you don't know what you're doing, you probably shouldn't be here!)", [10, 10], [1, 1, 1], 1, 0);

	drawfill([5, 60], [440, 3], [0.3, 0.3, 0.3], 1, 0);

	HUD_DrawWaypointModeString(5, 70, "+attack", "Create a Waypoint");
	HUD_DrawWaypointModeString(5, 85, "+button7", "Select a Waypoint");
	HUD_DrawWaypointModeString(5, 100, "+button8", "Link a Waypoint");
	HUD_DrawWaypointModeString(5, 115, "+button6", "Remove a Waypoint");
	HUD_DrawWaypointModeString(5, 130, "+button4", "Move selected Waypoint Here");
	HUD_DrawWaypointModeString(5, 145, "+button5", "Create a (Special) Waypoint");
	HUD_DrawWaypointModeString(5, 160, "impulse 22", "Load Map's Waypoints");
	HUD_DrawWaypointModeString(5, 175, "impulse 24", "Save current Waypoints");
}

void() HUD_Spectator =
{
	drawfill([0, 4], [250, 60], [0, 0, 0], cvar("cl_textopacity"), 0);
	Draw_String([5, 8], "SPECTATING", [18, 18], [1, 1, 1], 1, 0);
	Draw_String([5, 30], "You will spawn next Round", [12, 12], [1, 1, 0], 1, 0);
	Draw_String([5, 45], "(Fly around or go grab a snack!)", [10, 10], [1, 1, 1], 1, 0);
	drawfill([5, 60], [240, 3], [0.3, 0.3, 0.3], 1, 0);
}

void() HUD_GunGame =
{
	drawfill([g_width/2 - 318, 4], [636, 45], [0, 0, 0], cvar("cl_textopacity"), 0);

	string weapon_id = "";
	string point_info = "";

	if (getstatf(STAT_GUNGAME_IDX) >= 100) {
		weapon_id = "You've passed all weapons!";
		point_info = "The Winner can choose to End the Game";
	} else {
		weapon_id = sprintf("%s [%d/32]", GetWeaponName(getstatf(STAT_ACTIVEWEAPON)), getstatf(STAT_GUNGAME_IDX) + 1);
		point_info = sprintf("[%d] Score until next Weapon", getstatf(STAT_GUNGAME_SCOREGOAL) - getstatf(STAT_TOTALSCORE));
	}

	Draw_String([g_width/2 - getTextWidth(weapon_id, 18)/2, 8], weapon_id, [18, 18], [1, 1, 1], 1, 0);
	Draw_String([g_width/2 - getTextWidth(point_info, 12)/2, 30], point_info, [12, 12], [1, 1, 0], 1, 0);
}

void() HUD_PlayerNames =
{
	for (float i = 7; i >= 0; i = i - 1) {
		float player_number = getplayerkeyfloat(i, "client_index");

		if (player_number == getstatf(STAT_PLAYERNUM))
			continue;

		string text = getplayerkeyvalue(i, "name");
		entity client = findfloat(world, playernum, player_number);

		if (client == world || !client.classname || client.is_spectator)
			continue;

		// Append "[CHAT] " to the player name if the user is in message mode
		if (client.is_in_menu == 2)
			text = strcat("[CHAT] ", text);
		// Similarly, append "[PAUSED] " to the player name if the user is paused
		else if (client.is_in_menu == 1)
			text = strcat("[PAUSED] ", text);

		entity plr = findfloat(world, playernum, player_number);
		vector player_origin = plr.origin + '0 0 48';
		vector screen_position = project(player_origin);
		vector text_color = '1 1 1';

		if (player_origin == '0 0 48')
			continue;

		screen_position_x -= getTextWidth(text, 8)/2;
		text_color = HUD_ResolveTextColorForPlayer(i);

		if (screen_position_z > 0) {
			HUD_DrawStringWithBackdrop(screen_position, text, [8, 8], text_color, 1, 0);
		}
	}
}

void() HUD_ReviveIcons =
{
	for (float i = 3; i >= 0; i = i - 1) {
		float player_index = i;

		// Don't render our own Icon.
		if (player_index + 1 == getstatf(STAT_PLAYERNUM))
			continue;

		// Player is not in Last Stand.
		if (revive_icons[player_index].state <= 0)
			continue;

		// Player is not being actively revived, so the
		// Revive Icon should grow more and more red over time.
		if (revive_icons[player_index].state == 1)
			revive_icons[player_index].timer += frametime;
		
		float player_number = getplayerkeyfloat(i, "client_index");

		//string text = getplayerkeyvalue(i, "name");
		entity client = findfloat(world, playernum, player_number);

		// Client does not exist.
		if (client == world || !client.classname || client.is_spectator)
			continue;

		entity plr = findfloat(world, playernum, player_number);
		vector player_origin = plr.origin + '0 0 32';
		vector screen_position = project(player_origin);
		screen_position_x -= (32)/2;

		if (player_origin == '0 0 32')
			continue;

		if (screen_position_z > 0) {
			// Client is actively being revived, render white.
			if (revive_icons[i].state == 2) {
				drawpic(screen_position, "gfx/hud/revive_icon.tga", [32, 32, 1], [1,1,1], 1);
			} 
			// Draw with a yellow->red hue.
			else {
				drawpic(screen_position, "gfx/hud/revive_icon.tga", [32, 32, 1], [1,1 - (revive_icons[i].timer/30),0], 1);
			}
		}
	}
}

void() HUD_StopWatch =
{
	string sec, min, hr;
	string stopwatch;

	if (stopwatch_sec < 10) {
		sec = strcat("0", substring(ftos(stopwatch_sec), 0, 3));
	} else {
		sec = substring(ftos(stopwatch_sec), 0, 4);
	}

	if (stopwatch_min < 10) min = strcat("0", ftos(stopwatch_min)); else min = ftos(stopwatch_min);
	if (stopwatch_hr < 10) hr = strcat("0", ftos(stopwatch_hr)); else hr = ftos(stopwatch_hr);

	stopwatch = strcat(hr, ":", min, ":", sec);
	HUD_DrawStringWithBackdrop([g_width - (getTextWidth(stopwatch, 12)) - 2, 2], stopwatch, [12, 12], TEXT_ORANGE, 1, 0);
}

void() HUD_RoundStopWatch =
{
	string sec, min, hr;
	string stopwatch;

	if (stopwatch_round_sec < 10) {
		sec = strcat("0", substring(ftos(stopwatch_round_sec), 0, 3));
	} else {
		sec = substring(ftos(stopwatch_round_sec), 0, 4);
	}

	if (sec == "00") sec = "00.0";
	if (stopwatch_round_min < 10) min = strcat("0", ftos(stopwatch_round_min)); else min = ftos(stopwatch_round_min);
	if (stopwatch_round_hr < 10) hr = strcat("0", ftos(stopwatch_round_hr)); else hr = ftos(stopwatch_round_hr);

	stopwatch = strcat(hr, ":", min, ":", sec);
	HUD_DrawStringWithBackdrop([g_width - (getTextWidth(stopwatch, 12)) - 2, 16], stopwatch, [12, 12], [1, 1, 1], 1, 0);
}

/*******************
*  HUD Debug Info  *
*******************/

// set from CSQC_Ent_Update
vector player_velocity;

void() HUD_PlayerDebugInfo =
{
	static float lastupstime;
	static float lastups;

	if (!cvar("scr_playerdebuginfo"))
		return;

	if ((time - lastupstime) >= 1.0 / 20)
	{
		lastups = vlen(player_velocity);
		lastupstime = time;
	}

	vector pos = [cvar("scr_playerdebuginfo_x"), cvar("scr_playerdebuginfo_y")];
	pos.x += GetUltraWideOffset();

	drawfill(pos - [8, 8], [128, 192], [0, 0, 0], 0.75, 0);

	Draw_FancyFloat(pos, "Speed:", lastups, "qu/s");

	if (cvar("scr_playerdebuginfo") >= 2)
	{
		Draw_FancyVector(pos + [0, 36], "Angles:", getproperty(VF_ANGLES));
		Draw_FancyVector(pos + [0, 106], "Origin:", getproperty(VF_ORIGIN));
	}
};

//
// HUD_DrawElementsForEndGame()
// Heads-Up Display draw logic for when the server
// is in its "GAME OVER" state.
//
void() HUD_DrawElementsForEndGame =
{
	// Draws our "GAME OVER" text.
	HUD_Endgame();

	// Draws the scoreboard.
	HUD_Scores();
};

//
// HUD_DrawElementsForSpectator()
// Heads-Up Display draw logic for Spectators.
//
void() HUD_DrawElementsForSpectator =
{
	// If the scoreboard is open, only draw it and nothing else.
	if (score_show) {
		HUD_Scores();
		return;
	}

	// Networked names for all players.
	HUD_PlayerNames();

	// Draws the current round.
	HUD_Rounds();

	// Draws all player's points.
	HUD_Points();

	// Draws Power-Up status.
	HUD_Powerups();
	HUD_MaxAmmo();

	// "You are Spectating" message.
	HUD_Spectator();
};

//
// HUD_DrawElementsForWaypointMode()
// Heads-Up Display draw logic when in Waypoint Mode.
//
void() HUD_DrawElementsForWaypointMode =
{
	// Waypoint Mode tutorial.
	HUD_Waypoint();

	//
	// Everything below should be debug or cvar-related.
	//

	// Player origin, angles, etc. for debugging if cvar is enabled.
	HUD_PlayerDebugInfo();
};

//
// HUD_DrawElementsForHardcorePlayer()
// Heads-Up Display draw logic during Hardcore mode.
//
void() HUD_DrawElementsForHardcorePlayer =
{
	// We shouldn't draw anything during the game intro fade.
	if (screenflash_color == SCREENFLASH_COLOR_BLACK && screenflash_duration > time) {
		HUD_Screenflash();
		return;
	}

	// Blood filter on screen to indicate health.
	HUD_Health();

	// If the scoreboard is open, only draw it and nothing else.
	if (score_show) {
		HUD_Scores();
		return;
	}
	// Additionally, bail here if cl_cinematic is set.
	else if (cvar("cl_cinematic")) {
		return;
	}

	// Being scoped-in hides all low-priority elements.
	if (getstatf(STAT_WEAPONZOOM) != 2 || zoom_2_time >= time) {
		// Draws all player's points.
		HUD_Points();
	}

	// Visual hit Feedback. 
	HUD_Hitmark();

	// Black/White/etc. total screen flashes.
	HUD_Screenflash();

	//
	// Everything below should always have maximum priority.
	//

	// Revive indicator for Players in Last Stand.
	HUD_ReviveIcons();

	// "X" needs to be revived, or other important messages.
	HUD_Broadcast();
};

//
// HUD_DrawElementsForPlayer()
// Heads-Up Display draw logic during normal play.
//
void() HUD_DrawElementsForPlayer =
{
	// We shouldn't draw anything during the game intro fade.
	if (screenflash_color == SCREENFLASH_COLOR_BLACK && screenflash_duration > time) {
		HUD_Screenflash();
		return;
	}

	// Blood filter on screen to indicate health.
	HUD_Health();

	// Networked names for all players.
	HUD_PlayerNames();

	// If the scoreboard is open, only draw it and nothing else.
	if (score_show) {
		HUD_Scores();
		return;
	}
	// Additionally, bail here if cl_cinematic is set.
	else if (cvar("cl_cinematic")) {
		return;
	}

	// Crosshair for Player weapons.
	HUD_Crosshair();

	// Being scoped-in hides all low-priority elements.
	if (getstatf(STAT_WEAPONZOOM) != 2 || zoom_2_time >= time) {
		// "Low Ammo", "No Ammo", etc.
		HUD_AmmoString();

		// Draws all player's points.
		HUD_Points();

		// Draws the current player's character name.
		HUD_CharacterName();

		// Draws the current player's Perk-A-Cola loadout.
		HUD_Perks();

		// Draws Power-Up status.
		HUD_Powerups();
		HUD_MaxAmmo();

		// Draws the current round.
		HUD_Rounds();

		// Draw the player's Bouncing Betties and Grenades.
		HUD_Grenades();

		// Draws the player's magazine and reserve count.
		HUD_Ammo();

		// Draws the name of the player's active weapon.
		HUD_WeaponString();

		// "Hold F to use" triggered strings.
		HUD_Useprint();

		// Bouncing Betty tutorial.		
		HUD_BouncingBetty();

		switch(active_gamemode) {
			case GAMEMODE_GUNGAME: HUD_GunGame(); break;
			default: break;
		}

		// Revive status progress bar.
		HUD_Progressbar();
	}

	// Visual hit Feedback. 
	HUD_Hitmark();

	// Black/White/etc. total screen flashes.
	HUD_Screenflash();

	//
	// Everything below should always have maximum priority.
	//

	// Revive indicator for Players in Last Stand.
	HUD_ReviveIcons();

	// "X" needs to be revived, or other important messages.
	HUD_Broadcast();

	//
	// Everything below should be debug or cvar-related.
	//

	// Total gametime stopwatch for Speedruns.
	if (cvar("scr_serverstopwatch")) {
		HUD_StopWatch();
	}

	// Active round stopwatch for Speedruns.
	if (cvar("scr_serverstopwatch") >= 2) {
		HUD_RoundStopWatch();
	}

	// Player origin, angles, etc. for debugging if cvar is enabled.
	HUD_PlayerDebugInfo();
};

//
// HUD_DrawElements(width, height)
// Redirects to Heads-Up Display draw lists depending on
// client and game state.
//
void() HUD_DrawElements = 
{
	//
	// Game Over Sequence
	//
	if (in_endgame_sequence) {
		HUD_DrawElementsForEndGame();
		return;
	}

	//
	// Spectator Mode
	//
	if (getstatf(STAT_SPECTATING)) {
		HUD_DrawElementsForSpectator();
		return;
	}

	//
	// Waypoint Mode
	//
	if (cvar("waypoint_mode")) {
		HUD_DrawElementsForWaypointMode();
		return;
	}

	//
	// Hardcore Mode has a more limited HUD
	//
	if (active_gamemode == GAMEMODE_HARDCORE) {
		HUD_DrawElementsForHardcorePlayer();
		return;
	}

	//
	// Standard Play
	//
	HUD_DrawElementsForPlayer();
};
