/*
	server/entities/sub_functions.qc

	entity/server utility subroutines

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

/*
==============================
SUB_UseTargets

the global "activator" should be set to the entity that initiated the firing.

If self.delay is set, a DelayedUse entity will be created that will actually
do the SUB_UseTargets after that many seconds have passed.

Centerprints any self.message to the activator.

Removes all entities with a targetname that match self.killtarget,
and removes them, so some events can remove other triggers.

Search for (string)targetname in all entities that
match (string)self.target and call their .use function

==============================
*/
void() SUB_UseTargets;
void(vector tdest, float tspeed, void() func) SUB_CalcMove;
void()  SUB_CalcMoveDone;
void() DelayThink =
{
	activator = self.enemy;
	SUB_UseTargets ();
	remove(self);
};

float global_triggerstate;

void() SUB_UseTargets =
{
	local entity t, stemp, otemp, act;
	float tempcount, temptotal, breakthis;
	string tempstring;

	tempstring = "";
	temptotal = 0;
	tempcount = 0;
	breakthis = false;

	if (self.target != "")
		tempcount = tempcount + 1;
	if (self.target2 != "")
		tempcount = tempcount + 1;
	if (self.target3 != "")
		tempcount = tempcount + 1;
	if (self.target4 != "")
		tempcount = tempcount + 1;
	if (self.target5 != "")
		tempcount = tempcount + 1;
	if (self.target6 != "")
		tempcount = tempcount + 1;
	if (self.target7 != "")
		tempcount = tempcount + 1;
	if (self.target8 != "")
		tempcount = tempcount + 1;

	//
	// print the message
	//
	if (self.message != "")
	{
		// cypress -- NZ:P specific change, we should be firing the centerprint from
		// activation onto all clients to not leave anyone out of the loop.
		entity clients = find(world, classname, "player");

		while (clients != world) {
			centerprint(clients, self.message);
			clients = find(clients, classname, "player");
		}
	}

	//
	// kill the killtagets
	//
	if (self.killtarget && self.killtarget != self.target)
	{
		t = world;
		do
		{
			t = find (t, targetname, self.killtarget);
			if (t == world || !t) {
				breakthis = true;
				continue;
			}
			Ent_FakeRemove(t);
		} while (!breakthis);
	}

	while(tempcount > temptotal)
	{
		temptotal = temptotal + 1;
		if (temptotal == 1)
			tempstring = self.target;
		if (temptotal == 2)
			tempstring = self.target2;
		if (temptotal == 3)
			tempstring = self.target3;
		if (temptotal == 4)
			tempstring = self.target4;
		if (temptotal == 5)
			tempstring = self.target5;
		if (temptotal == 6)
			tempstring = self.target6;
		if (temptotal == 7)
			tempstring = self.target7;
		if (temptotal == 8)
			tempstring = self.target8;
	//
	// check for a delay
	//
		if (self.delay)
		{
			// create a temp object to fire at a later time
			t = spawn();
			t.classname = "DelayedUse";
			t.nextthink = time + self.delay;
			t.think = DelayThink;
			t.enemy = activator;
			t.message = self.message;
			t.killtarget = self.killtarget;
			t.triggerstate = self.triggerstate;
			t.target = self.target;
			t.target2 = self.target2;
			t.target3 = self.target3;
			t.target4 = self.target4;
			t.target5 = self.target5;
			t.target6 = self.target6;
			t.target7 = self.target7;
			t.target8 = self.target8;
			return;
		}
		
	//
	// fire targets
	//
		if (tempstring != "")
		{
			act = activator;
			t = find (world, targetname, tempstring);
			breakthis = 0;
			while (!breakthis)
			{
				if (!t)
				{
					breakthis = true;
				}
				stemp = self;
				otemp = other;
				self = t;
				other = stemp;
				if (t.classname == "spawn_zombie_in")
				{
					t.classname = "spawn_zombie";
					t.spawn_id = zombie_spawn_points;
					zombie_spawn_points++;
				}
				if (t.classname == "waypoint_s")
				{
					t.classname = "waypoint_s";
				}
				if (t.classname == "spawn_dog_in")
					t.classname = "spawn_dog";
				if (self.use != SUB_Null)
				{
					global_triggerstate = self.triggerstate;

					if (self.use)
						self.use();
					
					global_triggerstate = -1;
				}
				self = stemp;
				other = otemp;
				activator = act;
				t = find (t, targetname, tempstring);
			}
		}
	}
	

};

/*
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating 

The calling function should make sure self.think is valid
===============
*/
void SUB_CalcAngleMove (vector destangle, float tspeed, void() func);
void(entity ent, vector destangle, float tspeed, void() func) SUB_CalcAngleMoveEnt =
{
local entity		stemp;
	stemp = self;
	self = ent;
	SUB_CalcAngleMove (destangle, tspeed, func);
	self = stemp;
};

void SUB_CalcAngleMoveDone (void)
{
	// After rotating, set angle to exact final angle
	self.angles = self.finalangle;
	self.avelocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1 ();
}

void SUB_CalcAngleMove (vector destangle, float tspeed, void() func)
{
	vector	delta;
	float	traveltime;

	if (!tspeed)
		objerror ("No speed is defined!");

	delta = destangle - self.angles;
	traveltime = vlen (delta) / tspeed;

	self.avelocity = delta * (1 / traveltime);

	self.think1 = func;
	self.finalangle = destangle;

	self.think = SUB_CalcAngleMoveDone;
	self.nextthink = self.ltime + traveltime;
}

/*
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
*/
void(entity ent, vector tdest, float tspeed, void() func) SUB_CalcMoveEnt =
{
local entity	stemp;
	stemp = self;
	self = ent;

	SUB_CalcMove (tdest, tspeed, func);
	self = stemp;
};

void(vector tdest, float tspeed, void() func) SUB_CalcMove =
{
local vector	vdestdelta;
local float		len, traveltime;

	if (!tspeed)
		objerror("No speed is defined!");

	self.think1 = func;
	self.finaldest = tdest;
	self.think = SUB_CalcMoveDone;

	if (tdest == self.origin)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}
		
// set destdelta to the vector needed to move
	vdestdelta = tdest - self.origin;
	
// calculate length of vector
	len = vlen (vdestdelta);
	
// divide by speed to get time to reach dest
	traveltime = len / tspeed;

	if (traveltime < 0.1)
	{
		self.velocity = '0 0 0';
		self.nextthink = self.ltime + 0.1;
		return;
	}
	
// set nextthink to trigger a think when dest is reached
	self.nextthink = self.ltime + traveltime;

// scale the destdelta vector by the time spent traveling to get velocity
	self.velocity = vdestdelta * (1/traveltime);	// qcc won't take vec/float	
};

/*
============
After moving, set origin to exact final destination
============
*/
void()  SUB_CalcMoveDone =
{
	setorigin(self, self.finaldest);
	self.velocity = '0 0 0';
	self.nextthink = -1;
	if (self.think1)
		self.think1();
};


#ifdef FTE

//
// HalfLife_DoRender()
// Adds some support for HL rendermodes to FTE, made by 
// autonomous1 for 'quakelife'
//

// Do *some* of the half-life render stuff.
void () HalfLife_DoRender =
{
    local vector osize, omins, omaxs, oabsmin, oabsmax;

    if (self.rendercolor != '0 0 0') {}    // ADDME
    
    if (self.rendermode > 0)
        if (self.renderamt > 0) {
            self.alpha = self.renderamt/255;
            if (self.alpha == 0)
                self.alpha = .01;
        }
        else {
            self.rendermode = 2;
        }
        
        if (self.rendermode == 2) {
            self.alpha = self.renderamt/255;
            if (self.alpha == 0) {
                //self.alpha = 0.01;
                osize = self.size;
                omins = self.mins;
                omaxs = self.maxs;
                oabsmin = self.absmin;
                oabsmax = self.absmax;
                
                if (self.solid == SOLID_BSP) {

                        self.solid = SOLID_BBOX;
                }
                    
                //setmodel(self, string_null);
                self.size = osize;
                self.mins = omins;
                self.maxs = omaxs;
                self.absmin = oabsmin;
                self.absmax = oabsmax;
                //setorigin(self, self.origin);
            }
        }
};

#endif // FTE
