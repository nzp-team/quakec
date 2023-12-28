/*
	client/hud.qc

	HUD Drawing Code

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


/*******************
*    HUD_Health   *
*******************/

void(float width, float height) HUD_Health = 
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
    
		drawpic([0,0,0], "gfx/hud/blood.tga", [width, height, 0], [10,0,0], alpha/2000); // naievil -- alpha factor division here makes it easy to use legacy code
	}
	
}

/*******************
*    HUD_Ammo      *
*******************/

void(float width, float height) HUD_Ammo =
{
	local float ammo, curmag, benis, benis2;
	string ammostring, ammostring_1, ammostring_2;
	vector color;
	
	curmag = getstatf(STAT_CURRENTMAG);		
	ammo = getstatf(STAT_AMMO);	
	
	benis = strlen(ftos(ammo));
	benis2 = strlen(ftos(curmag));
	benis = benis + benis2;
	
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
		float x2 = (g_width - GetUltraWideOffset()) - 62 - stringwidth(ammostring, 0, [12, 12]);
		drawstring([x2, g_height - 29], ammostring, [12, 12], [1,1,1], 1, 0);
	} else {
		ammostring_1 = ftos(curmag);
		ammostring_2 = strcat("/", ftos(ammo));
		string weapon_ammo_string = strcat(ftos(curmag), "/", ftos(ammo));
		float x = (g_width - GetUltraWideOffset())  - 62 - stringwidth(weapon_ammo_string, 0, [12, 12]);

		drawstring([x, g_height - 29], ammostring_1, [12, 12], color, 1, 0);
		drawstring([x + stringwidth(ammostring_1, 0, [12, 12]), g_height - 29], ammostring_2, [12, 12], color_2, 1, 0);
	}
}

//
// HUD_AmmoString()
// Draws the "LOW AMMO", "Reload", etc. text
//
float ammoopac, ammoloop;
void() HUD_AmmoString =
{
	vector 	textcolor = [1, 1, 1];
	string 	message = "";
	float	reserve_is_low;
	float	mag_is_low;

	// Is the Reserve low?
	if (W_IsLowAmmo(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_AMMO), false)) {
		reserve_is_low = true;
	} else {
		reserve_is_low = false;
	}

	// Is the Magazine low?
	if (W_IsLowAmmo(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_CURRENTMAG), true)) {
		mag_is_low = true;
	} else {
		mag_is_low = false;
	}

	// Nothing to do.
	if (mag_is_low == false && reserve_is_low == false) {
		ammoopac = 1;
		ammoloop = 0;
		return;
	} else {
		// Display Reload text if the mag is low but reserve is not.
		if (mag_is_low == true && reserve_is_low == false) {
			message = "Reload";
			textcolor = [1, 1, 1];
		}
		// Report NO AMMO if both are empty
		else if (getstatf(STAT_CURRENTMAG) <= 0 && getstatf(STAT_AMMO) <= 0)
		{
			message = "NO AMMO";
			textcolor = [215/255, 0, 0];
		}
		// Display LOW AMMO if mag is low and reserve is empty
		else if (mag_is_low == true && getstatf(STAT_AMMO) <= 0)
		{
			message = "LOW AMMO";
			textcolor = [219/255, 203/255, 19/255];	
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

	float x = (g_width/2) - (stringwidth(message, 0, [12, 12])/2);
	drawstring([x, g_height/2 + 40, 0], message, [12, 12, 0], textcolor, ammoopac, 0);
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
	point_elements[index].string_width = stringwidth(point_elements[index].text_string, 0, [12, 12]);

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
	point_elements[index].y_position = (g_height - 90) - (25*(playernum - 1));

	// start with an opacity of 1
	point_elements[index].opacity = 1;

	// the element is being used
	point_elements[index].occupied = true;

	// iterate
	last_point_element_index++;
	active_point_elements++;
}

void(float pwidth, float width, float height, float playernum) PointUpdate = 
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
			drawstring([pwidth - point_elements[i].string_width - point_elements[i].x_position, 
			point_elements[i].y_position], point_elements[i].text_string, [12, 12], 
			POINT_DIFF_COLOR, point_elements[i].opacity, 0);
		}

		point_elements[i].x_position -= point_elements[i].x_velocity * (frametime*375);
		point_elements[i].y_position += point_elements[i].y_velocity * (frametime*375);
		point_elements[i].opacity -= (frametime*4);
	}
}

void(float width, float height) HUD_Points =
{
	float pointlength = 0, increm = 10, pointwidth = 0, x = 0;
	float backwidth = 0.8*width;
	vector TEXTCOLOR = '0 0 0';

	for (int i = 3; i >= 0; i = i - 1)
	{
		float player_number = getplayerkeyfloat(i, "viewentity");
		entity client = findfloat(world, playernum, player_number);

		if (client == world || client.movetype == MOVETYPE_BOUNCE)
			continue;

		switch(i) {
			case 1: TEXTCOLOR = TEXT_LIGHTBLUE; break;
			case 2: TEXTCOLOR = TEXT_ORANGE; break;
			case 3: TEXTCOLOR = TEXT_GREEN; break;
			default: TEXTCOLOR = [1, 1, 1]; break;
		}

		pointwidth = stringwidth(ftos(client.points), 0, [12, 12]);
		x = (99 - pointwidth)/2 + GetUltraWideOffset();

		if ((i + 1) == getstatf(STAT_PLAYERNUM)) {
			drawpic([3 + GetUltraWideOffset(), g_height - 97 - (i * 25)], "gfx/hud/moneyback.tga", [96, 24], [1,1,1], 1);
			drawstring([x, g_height - 92 - (i * 25)], ftos(client.points), [12, 12], TEXTCOLOR, 1, 0);
		} else {
			drawpic([-7 + GetUltraWideOffset(), g_height - 97 - (i * 25)], "gfx/hud/moneyback_condensed.tga", [96, 24], [1,1,1], 1);
			drawstring([x - 9, g_height - 92 - (i * 25)], ftos(client.points), [12, 12], TEXTCOLOR, 1, 0);
		}

		PointUpdate(x + 70, width, height, i + 1);
	}
}

/************************
*    HUD_CharacterName  *
************************/

void(float width, float height) HUD_CharacterName =
{
	float x = 100 + GetUltraWideOffset();
	float alpha = 1;

	if (nameprint_time - 1 < time) {
		alpha = (nameprint_time - time);
	}

	drawstring([x, height - 92 - ((getstatf(STAT_PLAYERNUM) - 1) * 25)], getstats(STAT_PLAYERNAME), [12, 12], [1, 1, 1], alpha, 0);
}

/*******************
*    HUD_Grenades  *
*******************/

void(float width, float height) HUD_Grenades =
{
	float grenades;
	float betties;

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

	drawpic([g_width - 3 - 56 - GetUltraWideOffset(), g_height - 50], "gfx/hud/frag.tga", [32, 32], [1, 1, 1], 1);
	drawstring([g_width - 3 - 38 - GetUltraWideOffset(), g_height - 29], ftos(grenades), [12, 12], grenade_text_color, 1, 0);

	if (betties != -1) {
		drawpic([g_width - 3 - 28 - GetUltraWideOffset(), g_height - 50], "gfx/hud/betty.tga", [32, 32], [1, 1, 1], 1);
		drawstring([g_width - 3 - 10 - GetUltraWideOffset(), g_height - 29], ftos(betties), [12, 12], betties_text_color, 1, 0);
	}
}

/*******************
*    HUD_Rounds    *
*******************/

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

void(float width, float height) HUD_Rounds =
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

		pwidth = stringwidth("Round", 0, [24, 24])/2;
		drawstring([(g_width/2) - pwidth, g_height/2 - 70], "Round", [24, 24], [1, rcolor, rcolor], ralpha, 0);

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

		drawstring([3 + GetUltraWideOffset(), g_height/2 + 24], chaptertitle, [12, 12], [1, 1, 1], localpha, 0);
		drawstring([3 + GetUltraWideOffset(), g_height/2 + 36], location, [12, 12], [1, 1, 1], localpha, 0);
		drawstring([3 + GetUltraWideOffset(), g_height/2 + 48], date, [12, 12], [1, 1, 1], localpha, 0);
		drawstring([3 + GetUltraWideOffset(), g_height/2 + 60], person, [12, 12], [1, 1, 1], localpha, 0);
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
		
		drawpic([round_center_x,round_center_y,0], sb_round[0], [roundwidth, roundheight], [107/255,1/255], alphabling/255);
	}
	else if (rounds_change == 2)//this is the rounds icon moving from middle
	{
		stopwatch_round_isactive = true;
		float round_center_y_offset = 0;
		float round_center_x_offset = 0;
				
		drawpic([round_center_x + round_center_x_offset,round_center_y + round_center_y_offset,0], sb_round[0], [roundwidth,roundheight, 1], [107/255,(1/255),0], 1);
		
		round_center_x = round_center_x - (((229/108)*2 - 0.2)*((width - GetUltraWideOffset())/480)/8) * (frametime*250);
		round_center_y = round_center_y + ((2*(height/272))/8) * (frametime*250);

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
			color_shift[0] = 107;
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
					drawpic([5 + GetUltraWideOffset(),height - roundheight, 0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
					
					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num, roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);
								
				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
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
					drawpic([5 + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

					drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
					
				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
				
				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
			
			x_offset = x_offset +  roundwidth_num - (8*width/480);
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
					drawpic([5 + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);
					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
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
					drawpic([5 + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);
								
					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [1,1,1], blinking/255);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);
				
				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [1,1,1], blinking/255);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
	}
	else if (rounds_change == 7)//blink white while fading back
	{
		stopwatch_round_isactive = true;
		if (!color_shift_init)
		{
			color_shift_end[0] = 107;
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
					drawpic([5 + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2+x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2+x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			drawpic([2+x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [color_shift[0]/255,color_shift[1]/255,color_shift[2]/255], 1);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
	}
	else
	{
		color_shift[0] = 107;
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
					drawpic([5 + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [107/255,1/255,0], 1);

					savex = x_offset + (10*width/480);
					x_offset = x_offset + (10*width/480);
					continue;
				}
				if (i == 9)
				{
					drawpic([5 + savex + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[4], [roundwidth_4,roundheight_4, 1], [107/255,1/255,0], 1);

					continue;
				}
				if (i > 4)
					icon_num = i - 5;
				else
					icon_num = i;

				drawpic([5 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round[icon_num], [roundwidth,roundheight, 1], [107/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth + (3*width/480);
			}
		}
		else
		{
			if (rounds >= 100)
			{
				num[2] = (int)(rounds/100);
				drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[2]], [roundwidth_num,roundheight_num, 1], [107/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[2] = 0;
			if (rounds >= 10)
			{
				num[1] = (int)((rounds - num[2]*100)/10);
				drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[1]], [roundwidth_num,roundheight_num, 1], [107/255,1/255,0], 1);

				x_offset = x_offset +  roundwidth_num - (8*width/480);
			}
			else
				num[1] = 0;

			num[0] = rounds - num[2]*100 - num[1]*10;
			
			if(rounds == 0)
				return;
			
			drawpic([2 + x_offset + GetUltraWideOffset(), height - roundheight - (4*height/272),0], sb_round_num[num[0]], [roundwidth_num,roundheight_num, 1], [107/255,1/255,0], 1);

			x_offset = x_offset +  roundwidth_num - (8*width/480);
		}
	}
}

/*******************
*    HUD_Useprint  *
*******************/

void(float width, float height) HUD_Useprint =
{
	string usestring, usebutton, usespace;
	string usecost;
	float print_width, x, button_width;
	
	usestring = "";
	usespace = "";
	usecost = "";
		
	tokenize(findkeysforcommand("+button7"));
	usebutton = strtoupper(keynumtostring(stof(argv(0))));

	for(float i = 0; i < strlen(usebutton); i++) {
		usespace = strcat(usespace, " ");
	}

	switch (useprint_type) {
		case 0://clear
			usestring = "";
			break;
		case 1://door
			usestring = strcat("Hold ",usespace, " to open Door");
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 2://debris
			usestring = strcat("Hold ",usespace, " to remove Debris");
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 3://ammo
			usestring = strcat("Hold ",usespace, " to buy Ammo for ", GetWeaponName(useprint_weapon));
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 4://weapon
			usestring = strcat("Hold ",usespace, " to buy ", GetWeaponName(useprint_weapon));
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 5://window
			usestring = strcat("Hold ",usespace, " to Rebuild Barrier");
			break;
		case 6://box
			usestring = strcat("Hold ",usespace, " for Mystery Box");
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 7://box take
			usestring = strcat("Hold ",usespace, " for ", GetWeaponName(useprint_weapon));
			break;
		case 8://power
			usestring = "The Power must be Activated first";
			break;
		case 9://perk
			usestring = strcat("Hold ",usespace, " to buy ", GetPerkName(useprint_weapon));
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 10://turn on power
			usestring = strcat("Hold ",usespace, " to Turn On the Power");
			break;
		case 11://turn on trap
			usestring = strcat("Hold ",usespace, " to Activate the Trap");
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 12://packapunch
			usestring = strcat("Hold ",usespace, " to Pack-a-Punch");
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 13://revive
			usestring = strcat("Hold ",usespace, " to Revive Player");
			break;
		case 14://use teleporter (free)
			usestring = strcat("Hold ", usespace, " to use Teleporter");
			break;
		case 15://use teleporter (cost)
			usestring = strcat("Hold ", usespace, " to use Teleporter");
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		case 16://tp cooldown
			usestring = "Teleporter is cooling down";
			break;
		case 17://link
			usestring = strcat("Hold ", usespace, " to initate link to pad");
			break;
		case 18://no link
			usestring = "Link not active";
			break;
		case 19://finish link
			usestring = strcat("Hold ", usespace, " to link pad with core");
			break;
		case 20://buyable ending
			usestring = strcat("Hold ", usespace, " to End the Game");
			usecost = strcat("[Cost:", ftos(useprint_cost), "]");
			break;
		default:
			usestring = "This should not happen you dum fuck"; //yikes
			break;
	}

	print_width = stringwidth (usestring, 0, [12, 12]);
	x = (width - print_width)/2;
	drawstring([x, g_height/2 + 65, 0], usestring, [12, 12, 0], [1, 1, 1], 1, 0);

	// Draw "Cost" text.
	if (usecost != "") {
		float cost_width = stringwidth(usecost, 0, [12, 12]);
		float x3 = (width - cost_width)/2;
		drawstring([x3, g_height/2 + 78, 0], usecost, [12, 12, 0], [1, 1, 1], 1, 0);
	}

	// Draw highlighted usebutton (or button icon in the future)
	if (substring(usestring, 0, 4) == "Hold") {
		button_width = x + stringwidth ("Hold ", 0, [12, 12, 0]);
		drawstring([button_width, g_height/2 + 65, 0], usebutton, [12, 12, 0], [1, 1, 0], 1, 0);
	}
}

/*******************
*    HUD_Perks     *
*******************/

int perk_order[9];
int current_perk_order;
	
void(float width, float height) HUD_Perks =
{
	float scale;
	float x, y;
	
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

void(float width, float height) HUD_Weaponstring =
{
	string weaponstring; 
	weaponstring = GetWeaponName(getstatf(STAT_ACTIVEWEAPON));
	float x = g_width - 62 - stringwidth(weaponstring, 0, [12, 12]);
	drawstring([x - GetUltraWideOffset(), g_height - 49], weaponstring, [12, 12], [1, 1, 1], 1, 0);
}

/*********************
* HUD Bouncing Betty *
*********************/

void(float width, float height) HUD_BouncingBetty =
{
	float top_x, bot_x, but_x;
	string betty_key;
	string betty_space;
	string activate_string, activate_string2;

	tokenize(findkeysforcommand("impulse 33"));
	betty_key = strtoupper(keynumtostring(stof(argv(0))));

	betty_space = "";
	for(float i = 0; i < strlen(betty_key); i++) {
		betty_space = strcat(betty_space, " ");
	}

	activate_string = strcat("Press ", betty_space, " to place a");
	activate_string2 = "Bouncing Betty";

	top_x = (g_width/2) - (stringwidth(activate_string, 0, [12, 12])/2);
	bot_x = (g_width/2) - (stringwidth(activate_string2, 0, [12, 12])/2);

	drawstring([top_x, g_height - 303], activate_string, [12, 12], [1, 1, 1], 1, 0); 
	drawstring([bot_x, g_height - 289], activate_string2, [12, 12], [1, 1, 1], 1, 0); 

	// Draw the highlighted button
	but_x = top_x + stringwidth("Press ", 0, [12, 12, 0]);
	drawstring([but_x, g_height - 303], betty_key, [12, 12], [1, 1, 0], 1, 0); 
}

/*******************
* HUD Progress Bar *
*******************/

void(float width, float height) HUD_Progressbar =
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
	float bar_x = (width - bar_width)/2;
	float bar_y = height*0.75;

	drawfill ([bar_x - 1, bar_y - 1, 0], [bar_width+2, bar_height, 0], [0, 0, 0], 0.4, 0);
	drawfill ([bar_x, bar_y, 0], [bar_width * percent, bar_height-2, 0], [1, 1, 1], 0.4, 0);
	
	float x = (g_width/2) - (stringwidth("Reviving...", 0, [12, 12])/2);
	drawstring([x, g_height - 105], "Reviving...", [12, 12], [1, 1, 1], 1, 0); 
}

/*******************
*    HUD Hitmark   *
*******************/

void() HUD_Hitmark =
{
	drawpic([g_width/2 - 12, g_height/2 - 12], "gfx/hud/hit_marker.tga", [24, 24], [1,1,1], 1);
}

/*******************
*   HUD Crosshair  *
*******************/

float croshhairmoving; // naievil --used t o see if we are moving or not
float cur_spread;
float crosshair_offset_step;
float crosshair_opacity;
vector crosshair_color;

void() Draw_Crosshair =
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

	if (crosshair_spread_time > time && crosshair_spread_time)
    {
        cur_spread = cur_spread + 10;
		if (cur_spread >= CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE)))
			cur_spread = CrossHairMaxSpread(getstatf(STAT_ACTIVEWEAPON), getstatf(STAT_PLAYERSTANCE));
		
		if (!croshhairmoving)
			cur_spread *= 1/2;
    }
    else if (crosshair_spread_time < time && crosshair_spread_time)
    {
        cur_spread = cur_spread - 0.25;
		if (cur_spread <= 0)
		{
			cur_spread = 0;
			crosshair_spread_time = 0;
		}
    }

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
		float circle_offset = stringwidth("O", 0, [14, 14])/2;
		drawstring([g_width/2 - circle_offset, g_height/2 - circle_offset], "O", [14, 14], crosshair_color, 1, 0);
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

void() HUD_Broadcast = {

	string broadcast_msg = "";
	float health = getstatf(STAT_HEALTH);
	
	switch(broadcast_type) {
		case 2: broadcast_msg = strcat(broadcast_string, " needs to be revived"); break;
		case 3: broadcast_msg = strcat(broadcast_string, " is reviving you"); break;
		default: break;
	}

	float print_width = stringwidth (broadcast_msg, 0, [0.015*g_width, 0.015*g_width, 0]);
	float x = (g_width - print_width)/2;

	if (broadcast_msg != "")
		drawstring([x, g_height/2, 0], broadcast_msg, [0.015*g_width, 0.015*g_width, 0], [1, 1, 1], 1, 0);
}

void() HUD_Scores =
{
	int j;
	vector TEXTCOLOR = [1, 1, 1];
	
	if(serverkey("constate") != "disconnected")
	{
		// Headers
		drawstring([g_width/2 + 15, 175], "Points", [12, 12], TEXTCOLOR, 1, 0); 
		drawstring([g_width/2 + 170, 175], "Kills", [12, 12], TEXTCOLOR, 1, 0); 
	
		for (int i = 0; i < 4; i = i + 1)
		{
			float player_number = getplayerkeyfloat(i, "viewentity");
			entity client = findfloat(world, playernum, player_number);

			if (client == world || client.movetype == MOVETYPE_BOUNCE)
				break;
			
			switch(i) {
				case 1: TEXTCOLOR = TEXT_LIGHTBLUE; break;
				case 2: TEXTCOLOR = TEXT_ORANGE; break;
				case 3: TEXTCOLOR = TEXT_GREEN; break;
				default: TEXTCOLOR = [1, 1, 1]; break;
			}

			//
			// Since positioning is center-aligned, we need to be careful how we do our X and Y
			// pos. to keep things looking nicely centered and even with different aspect ratios.
			//

			// Center moneyback
			drawpic([g_width/2 - 48,  195 + (30 * i)], "gfx/hud/moneyback.tga", [96, 24], [1,1,1], 1);
			// Left
			for(j = 0; j < 3; j++) {
				drawpic([(g_width/2 - 48) - (70 * (j+1)),  195 + (30 * i)], "gfx/hud/moneyback.tga", [96, 24], [1,1,1], 1);
			}
			// Right
			for(j = 0; j < 3; j++) {
				drawpic([(g_width/2 - 48) + (70 * (j+1)),  195 + (30 * i)], "gfx/hud/moneyback.tga", [96, 24], [1,1,1], 1);
			}
			
			// Name
			string player_name = getplayerkeyvalue(i, "name");
			drawstring([g_width/2 - 245, 200 + (30 * i)], player_name, [12, 12], TEXTCOLOR, 1, 0); 

			// Points
			float point_width = stringwidth(ftos(client.points), 0, [12, 12]);
			float point_x = ((g_width/2) - (point_width)/2) + 52;
			drawstring([point_x, 200 + (30 * i)], ftos(client.points), [12, 12], TEXTCOLOR, 1, 0); 

			// Kills
			float kill_width = stringwidth(ftos(client.points), 0, [12, 12]);
			float kill_x = ((g_width/2) - (kill_width)/2) + 210;
			drawstring([kill_x, 200 + (30 * i)], ftos(client.kills), [12, 12], TEXTCOLOR, 1, 0); 
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

	float game_over_width = stringwidth(game_over, 0, [24, 24]);
	drawstring([g_width/2 - game_over_width/2, 100], game_over, [24, 24], [1, 1, 1], 1, 0);

	float survive_width = stringwidth(survive, 0, [18, 18]);
	drawstring([g_width/2 - survive_width/2, 135], survive, [18, 18], [1, 1, 1], 1, 0);

	HUD_Scores();
}

float oldfade_alpha;
void() HUD_Fade = 
{  
	float alpha;
	
	if (fade_type == 1) {
		alpha = cos(fade_time - time);
			if (oldfade_alpha > 0.95)
			alpha = 1;
			
			alpha = invertfloat(alpha);
						
		drawfill ([0, 0, 0], [g_width, g_height, 0], [0, 0, 0], alpha, 0);	// background
		oldfade_alpha = alpha;
	}
	else if (fade_type == 2) {
		alpha = sin(((fade_time - time) * 2));
		if (oldfade_alpha > 0.95)
			alpha = 1;
				
		drawfill ([0, 0, 0], [g_width, g_height, 0], [0, 0, 0], alpha, 0);	// background
		oldfade_alpha = alpha;
	}
}

void(float width, float height) HUD_ScrollText = {
	float print_width = stringwidth (scrolltext, 0, [12, 12, 0]);
	float x = (width - print_width)/2;

	drawstring([x, scrollheight*height, 0], scrolltext, [12, 12, 0], [1, 1, 1], scrollopacity, 0); //low
	if (scrollheight > 0.70) {
		scrollheight -= frametime/10;
		if (scrollopacity > 0)
			scrollopacity -= frametime;
	} else {
		stext = 0;
	}
}

float achievement_init;
float achievement_ypos;
float achievement_desc_ypos;
float achievement_img_ypos;
float achievement_time;
void(float width, float height) HUD_Achievements = {
	if (active_achievement == -1)
		return;

	if (!achievement_init) {
		achievement_time 		= 0;
		achievement_ypos 		= -0.16;
		achievement_desc_ypos	= -0.13;
		achievement_img_ypos 	= -0.164;
		achievement_init 		= true;
	}


	drawstring([0.2*width, achievement_ypos*height, 0], "ACHIEVEMENT GET!", [0.015*width, 0.015*width, 0], [1, 1, 0], 1, 0);
	drawstring([0.2*width, achievement_desc_ypos*height, 0], achievements[active_achievement].name, [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawpic([0.005*width, achievement_img_ypos*height,0], achievements[active_achievement].img, [0.16*width, 0.08*width, 0], [1,1,1], 1);

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

string(float index) GetButtonString =
{
	// place holder
	if (index == 100)
		return "LMOUSE";
	else if (index == 101)
		return "RMOUSE";

	tokenize(findkeysforcommand(buttonBind[index]));
	string temps = strtoupper(keynumtostring(stof(argv(0))));

	return temps;
}

void(float width, float height) HUD_Waypoint =
{
	drawstring([0.015*width, 0.015*height, 0], "WAYPOINT MODE", [0.030*width, 0.030*width, 0], [1, 1, 1], 1, 0);
	drawfill([0.015*width, 0.035*height + height*0.035, 0], [strlen("WAYPOINT MODE")*0.030*width, 0.005*width, 0], [1, 1,1], 1, 0);
	drawstring([0.015*width, 0.095*height, 0], strcat("Press ", GetButtonString(100), " to Create a Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.125*height, 0], strcat("Press ", GetButtonString(9), " to Select a Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.155*height, 0], strcat("Press ", GetButtonString(101), " to Link a Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.185*height, 0], strcat("Press ", GetButtonString(11), " to Remove a Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.215*height, 0], strcat("Press ", GetButtonString(7), " to Move a Waypoint Here"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.245*height, 0], strcat("Press ", GetButtonString(10), " to Create a Special Waypoint"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.275*height, 0], strcat("Press ", "=", " to load map waypoints"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
	drawstring([0.015*width, 0.305*height, 0], strcat("Press ", "-", " to save current waypoints"), [0.015*width, 0.015*width, 0], [1, 1, 1], 1, 0);
}

void(float width, float height) HUD_PlayerNames =
{
	for (float i = 3; i >= 0; i = i - 1) {
		if ((i+1) == getstatf(STAT_PLAYERNUM))
			continue;
		
		float player_number = getplayerkeyfloat(i, "viewentity");

		string text = getplayerkeyvalue(i, "name");
		entity plr = findfloat(world, playernum, player_number);
		vector player_origin = plr.origin + '0 0 48';
		vector screen_position = project(player_origin);
		vector text_color = '1 1 1';

		if (player_origin == '0 0 48')
			continue;

		screen_position_x -= stringwidth(text, 0, [8, 8])/2;

		switch(i) {
			case 1: text_color = TEXT_LIGHTBLUE; break;
			case 2: text_color = TEXT_ORANGE; break;
			case 3: text_color = TEXT_GREEN; break;
			default: break;
		}

		if (screen_position_z > 0)
			drawstring(screen_position, text, [8, 8], text_color, 1, 0);
	}
}

void(float width, float height) HUD_ReviveIcons =
{
	for (float i = 0; i < active_revive_icons; i++) {
		if (revive_icons[i].draw == true) {
			revive_icons[i].timer += frametime;
			vector revive_origin;
			revive_origin_x = revive_icons[i].org[0];
			revive_origin_y = revive_icons[i].org[1];
			revive_origin_z = revive_icons[i].org[2];
			vector screen_position = project(revive_origin);
			screen_position_x -= (32)/2;

			if (screen_position_z > 0) {
				// being revived
				if (revive_icons[i].state == 2)
					drawpic(screen_position, "gfx/hud/revive_icon.tga", [32, 32, 1], [1,1,1], 1);
				else {
					drawpic(screen_position, "gfx/hud/revive_icon.tga", [32, 32, 1], [1,1 - (revive_icons[i].timer/30),0], 1);
				}
			}
		}
	}
}

void(float width, float height) HUD_StopWatch =
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

	drawstring([width - (strlen(stopwatch) * 12) - 2, 2], stopwatch, [12, 12], TEXT_ORANGE, 1, 0);
}

void(float width, float height) HUD_RoundStopWatch =
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

	drawstring([width - (strlen(stopwatch) * 12) - 2, 16], stopwatch, [12, 12], [1, 1, 1], 1, 0);
}

/*******************
*     HUD Draw     *
*******************/

void(float width, float height) HUD_Draw = 
{
	if (cvar("cl_cinematic"))
		return;

	HUD_Achievements(width, height);

	
	if (!getstatf(STAT_SPECTATING) && (getstatf(STAT_HEALTH) > 1) && !score_show)
	{
		Draw_Crosshair();

		if (!cvar("waypoint_mode")) {
			HUD_Health(width, height);
			HUD_Points(width, height);
			HUD_Rounds(width, height);
			HUD_Perks(width, height);
			HUD_Progressbar(width, height);
			HUD_Powerups();

            if (vmodel.model == GetWeaponModel(getstatf(STAT_ACTIVEWEAPON), FALSE) && vmodel.model != "")
			    HUD_AmmoString();

			if (nameprint_time > time)
				HUD_CharacterName(width, height);

			if (bettyprompt_time > time)
				HUD_BouncingBetty(width, height);
		
			if (HUD_Change_time > time)
			{
                HUD_Grenades(width, height);

                if (vmodel.model == GetWeaponModel(getstatf(STAT_ACTIVEWEAPON), FALSE) && vmodel.model != "") {
                    HUD_Ammo(width, height);
				    HUD_Weaponstring(width, height);
                }
			}
				
			if (useprint_time > time) 
				HUD_Useprint(width, height);
			
			if (Hitmark_time > time)
				HUD_Hitmark();

			if (stext) {
				HUD_ScrollText(width, height);
			} else {
				scrollopacity = 1;
				scrollheight = 0.80;
			}

			HUD_PlayerNames(width, height);
			HUD_ReviveIcons(width, height);

			if (cvar("scr_serverstopwatch")) {
				HUD_StopWatch(width, height);
			}
			if (cvar("scr_serverstopwatch") >= 2) {
				HUD_RoundStopWatch(width, height);
			}
		} else {
			HUD_Waypoint(width, height);
		}
	}
	
	// Only keep broadcast messages outside in case they are important
	if (broadcast_time > time)
		HUD_Broadcast();
	
	if (game_over)
		HUD_Endgame();
		
	if (score_show)
		HUD_Scores();
		
	if (fade_time > time)
		HUD_Fade();
}

void UpdatePerks(float newperks) {
	float s;

	// avoids out of bounds err - moto
	if (newperks == 0)
		current_perk_order = 0;

	for(float i = 1; i < 129; i *= 2) {
		if (newperks & i && !(perks & i)) {
			perk_order[current_perk_order] = i;
			current_perk_order += 1;
		}
	}

	for(float i = 1; i < 129; i *= 2) {
		if (perks & i && !(newperks & i)) 
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
	
	perks = newperks;
}
