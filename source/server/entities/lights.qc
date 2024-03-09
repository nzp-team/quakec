/*
	server/entities/lights.qc

	Spawns and handles Quake's lights and torches

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

#define LIGHT_SPAWNFLAG_STARTOFF        1               // Light starts turned off but can be triggered
                                                        // On via Power Switch.

#define LIGHT_SPAWNFLAG_STARTON         2               // Opposite of STARTOFF, light turns Off when
                                                        // Power is On.

//
// LS_Setup()
// Defines all of the LightStyles in the Game.
//
void() LS_Setup =
{
    // Lightstyles take alphebetical strings of input, from a-z.
    // a = complete darkness.
    // z = maximum brightness.
    lightstyle(0, "m");                                                     // 0 : Normal
    lightstyle(1, "mmnmmommommnonmmonqnmmo");                               // 1 : Flicker
    lightstyle(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba");   // 2 : Slow Strong Pulse
    lightstyle(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg");                    // 3 : Candle
    lightstyle(4, "mamamamamama");                                          // 4 : Fast Strobe
    lightstyle(5, "jklmnopqrstuvwxyzyxwvutsrqponmlkj");                     // 5 : Gentle Pulse
    lightstyle(6, "nmonqnmomnmomomno");                                     // 6 : Flicker 2
    lightstyle(7, "mmmaaaabcdefgmmmmaaaammmaamm");                          // 7 : Candle 2
    lightstyle(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa");            // 8 : Candle 3
    lightstyle(9, "aaaaaaaazzzzzzzz");                                      // 9 : Slow Strobe
    lightstyle(10, "mmamammmmammamamaaamammma");                            // 10: Fluro
    lightstyle(11, "abcdefghijklmnopqrrqponmlkjihgfedcba");                 // 11: Slow Pulse (no black)                                                  // 64: Off.
}
//
// L_Use()
// Target function for lights
//
void() L_Use = 
{
	if (self.spawnflags & INACTIVE) {
		lightstyle(self.style, "m");
		self.spawnflags = self.spawnflags - INACTIVE;
	}
	else {
		lightstyle(self.style, "a");
		self.spawnflags = self.spawnflags + INACTIVE;
	}
}

//
// L_Setup()
// Initialization for Lights.
//
void() L_Setup =
{
    // If it's not vanilla ZHLT, cut it off.
    if (self.style > 12)
       return;
    // Set the Light to be Off if the spawnflag is set.
    /*if ((self.spawnflags & LIGHT_SPAWNFLAG_STARTOFF)) {
        // Store the other value for later.
        //self.score = self.style;
        lightstyle(self.style, "a");
    }*/
}

//
// --------------------
// Generic Light Entities
// --------------------
//

void()  light               =           // Basic Light
{   
	L_Setup();
	
	if (self.spawnflags & INACTIVE)
		lightstyle(self.style, "a");
	else
		lightstyle(self.style, "m");
		
	self.use = L_Use;
}
void()  light_fluoro        =           // Light with hum ambient
{   L_Setup();                                                              }
void()  light_environment   =           // Sun cast from Sky
{   makestatic(self);                                                       }
void()  light_fluorospark   =           // Light with buzz ambient
{   L_Setup();                                                              }
void()  light_globe         =           // Light with visible globe
{   L_Setup();  makestatic(self);                                           }
void()  light_torch_small_walltorch =   // Light with visible wall torch
{   L_Setup(); makestatic(self);                                            }
void()  light_flame_large_yellow =
{   L_Setup(); makestatic(self);                                            }
void()  light_torch_small_yellow =      // Light with small flame & fire sound
{   L_Setup();    makestatic(self);                                         }
void()  light_torch_large_yellow =      // Light with larger flame & fire sound
{   L_Setup();   self.frame = 1; makestatic(self);                          }
void()  light_flame_small_white =       // Light with small flame & fire sound
{   L_Setup();   makestatic(self);                                          }
void()  light_spot = 			// Spotlight
{   L_Setup();   				                                            }

//
// --------------------
// Spawnable Dynamic Lights
// --------------------
//

//
// Light_Red(e)
// RGB: 255, 56, 56
//
void(entity e, optional float fullbright) Light_Red =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_REDLIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 2;	
	    e.color_y = 0.25;	
	    e.color_z = 0.25;
    }

#endif // FTE

}

//
// Light_Green(e)
// RGB: 56, 255, 56
//
void(entity e, optional float fullbright) Light_Green =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_GREENLIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 0.25;	
	    e.color_y = 2;	
	    e.color_z = 0.25;
    }

#endif // FTE

}

//
// Light_Blue(e)
// RGB: 56, 56, 255
//
void(entity e, optional float fullbright) Light_Blue =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_BLUELIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 0.25;	
	    e.color_y = 0.25;	
	    e.color_z = 2;
    }

#endif // FTE

}

//
// Light_Orange(e)
// RGB: 255, 128, 0
//
void(entity e, optional float fullbright) Light_Orange =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_ORANGELIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 2;	
	    e.color_y = 1;	
	    e.color_z = 0;
    }

#endif // FTE

}

//
// Light_Purple(e)
// RGB: 255, 28, 255
//
void(entity e, optional float fullbright) Light_Purple =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_PURPLELIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 2;	
	    e.color_y = 0.25;	
	    e.color_z = 2;
    }

#endif // FTE

}

//
// Light_Cyan(e)
// RGB: 97, 178, 248
//
void(entity e, optional float fullbright) Light_Cyan =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_CYANLIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 0.765;	
	    e.color_y = 1.4;	
	    e.color_z = 1.95;
    }

#endif // FTE

}

//
// Light_Pink(e)
// RGB: 255, 180, 180
//
void(entity e, optional float fullbright) Light_Pink =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_PINKLIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 2.37;	
	    e.color_y = 1.35;	
	    e.color_z = 1.35;
    }

#endif // FTE

}

//
// Light_Lime(e)
// RGB: 128, 255, 128
//
void(entity e, optional float fullbright) Light_Lime =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_LIMELIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 1;	
	    e.color_y = 2;	
	    e.color_z = 1;
    }

#endif // FTE

}

//
// Light_Yellow(e)
// RGB: 255, 255, 128
//
void(entity e, optional float fullbright) Light_Yellow =
{
    if (fullbright)
        e.effects = EF_FULLBRIGHT;

#ifndef FTE

    e.effects = e.effects | EF_YELLOWLIGHT;

#else

    {
        e.pflags = PFLAGS_FULLDYNAMIC;
       	e.light_lev = 100;
	    e.color_x = 2;	
	    e.color_y = 2;	
	    e.color_z = 1;
    }

#endif // FTE

}

//
// Light_None(e)
// Resets all Perk Light Effects.
//
void(entity e) Light_None =
{
	e.effects = 0;

#ifdef FTE

	{
		e.pflags = 0;
		e.light_lev = 0;
		e.color_x = 0;
		e.color_y = 0;
		e.color_z = 0;
	}

#endif // FTE

}

#ifdef FTE

void(entity what, float fullbright, float light_level,
     float red, float green, float blue) Light_Custom =
{
    if (fullbright)
        what.effects = what.effects | EF_FULLBRIGHT;

    {
        what.pflags = PFLAGS_FULLDYNAMIC;
        what.light_lev = light_level;
        what.color_x = red;
        what.color_y = green;
        what.color_z = blue;
    }
}

#endif // FTE
