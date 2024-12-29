/*
	client/chasecam.qc

	A pretty direct port of Quake's chase cam to CSQC.

    Copyright (C) 1996-1997 Id Software, Inc.
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

vector chase_pos;
vector chase_angles;

vector chase_dest;
vector chase_dest_angles;

void() Chase_Init =
{
    autocvar(chase_back, 100);
    autocvar(chase_up, 16);
    autocvar(chase_right, 0);
    autocvar(chase_active, 0);
    autocvar(chase_roll, 0);
    autocvar(chase_yaw, 0);
    autocvar(chase_pitch, 0);
};

float chase_nodraw;

#define NUM_TESTS           64
#define CHASE_DEST_OFFSET   2.0

void() Chase_Update =
{
    int     i;
    float   dist;
    vector  cl_viewangles, cl_vieworigin;
    vector  dest, stop;
    int     best;
    int     viewcontents;

    cl_viewangles = getproperty(VF_ANGLES);
    cl_vieworigin = getproperty(VF_ORIGIN);

    // if can't see player, reset
    makevectors(cl_viewangles);

    // calc exact destination
    for (i = 0; i < 3; i++) {
        chase_dest[i] = cl_vieworigin[i] - v_forward[i] * autocvar_chase_back - v_right[i] * autocvar_chase_right;
    }

    chase_dest[2] = cl_vieworigin[2] + autocvar_chase_up;

    // take contents of the view leaf
    viewcontents = pointcontents(cl_vieworigin);

    float attempts = 0;
    for (best = 0; best < NUM_TESTS; best++) {
        vector chase_newdest;

        chase_newdest[0] = cl_vieworigin[0] + (chase_dest[0] - cl_vieworigin[0]) * best / NUM_TESTS;
        chase_newdest[1] = cl_vieworigin[1] + (chase_dest[1] - cl_vieworigin[1]) * best / NUM_TESTS;
        chase_newdest[2] = cl_vieworigin[2] + (chase_dest[2] - cl_vieworigin[2]) * best / NUM_TESTS;

        // check for a leaf hit with different contents
        if (pointcontents(chase_newdest) != viewcontents)
        {
            // go back to the previous best as this one is bad
            // unless the first one was also bad, (viewleaf contents != viewleaf contents!!!)
            if (best > 0 && attempts < 5) {
                best--;
                attempts++;
            } else { 
                best = NUM_TESTS;
                break;
            }
        }
    }

    // certain surfaces can be viewed at an oblique enough angle that they are partially clipped
    // by znear, so now we fix that too...
    for (; best >= 0; best--) {
        // number of matches
        int nummatches = 0;

        // adjust
        chase_dest[0] = cl_vieworigin[0] + (chase_dest[0] - cl_vieworigin[0]) * best / NUM_TESTS;
        chase_dest[1] = cl_vieworigin[1] + (chase_dest[1] - cl_vieworigin[1]) * best / NUM_TESTS;
        chase_dest[2] = cl_vieworigin[2] + (chase_dest[2] - cl_vieworigin[2]) * best / NUM_TESTS;

        // move x to neg
        chase_dest[0] -= CHASE_DEST_OFFSET;
        if (pointcontents(chase_dest) == viewcontents) nummatches++;
        chase_dest[0] += CHASE_DEST_OFFSET;

        // move x to pos
        chase_dest[0] += CHASE_DEST_OFFSET;
        if (pointcontents(chase_dest) == viewcontents) nummatches++;
        chase_dest[0] -= CHASE_DEST_OFFSET;

        // move y to neg
        chase_dest[1] -= CHASE_DEST_OFFSET;
        if (pointcontents(chase_dest) == viewcontents) nummatches++;
        chase_dest[1] += CHASE_DEST_OFFSET;

        // move y to pos
        chase_dest[1] += CHASE_DEST_OFFSET;
        if (pointcontents(chase_dest) == viewcontents) nummatches++;
        chase_dest[1] -= CHASE_DEST_OFFSET;

        // move z to neg
        chase_dest[2] -= CHASE_DEST_OFFSET;
        if (pointcontents(chase_dest) == viewcontents) nummatches++;
        chase_dest[2] += CHASE_DEST_OFFSET;

        // move z to pos
        chase_dest[2] += CHASE_DEST_OFFSET;
        if (pointcontents(chase_dest) == viewcontents) nummatches++;
        chase_dest[2] -= CHASE_DEST_OFFSET;

        // all tests passed so we're good!
        if (nummatches == 6) break;
    }


    // find the spot the player is looking at
    dest[0] = cl_vieworigin[0] + 4096 * v_forward[0];
    dest[1] = cl_vieworigin[1] + 4096 * v_forward[1];
    dest[2] = cl_vieworigin[2] + 4096 * v_forward[2];
    traceline(cl_vieworigin, dest, MOVE_NOMONSTERS, world);

    // calculate pitch to look at the same spot from camera
    stop[0] = cl_vieworigin[0] - trace_endpos[0];
    stop[1] = cl_vieworigin[1] - trace_endpos[1];
    stop[2] = cl_vieworigin[2] - trace_endpos[2];
    dist = dotproduct(stop, v_forward);
    if (dist < 1) dist = 1;

    cl_viewangles[0] = -atan(stop[2] / dist) / M_PI * 180;

    setviewprop(VF_ORIGIN, chase_dest);
    //setviewprop(VF_ANGLES, cl_viewangles);
};