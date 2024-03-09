/*
	server/ai/standard/waypoints_core.qc

	non-pc waypoint impulsing

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

float waypoint_action;

void () Waypoint_Functions =
{
	switch (self.impulse)
	{
		case 15:
			Make_Special_Waypoint();
			break;
		case 10:
			Move_Waypoint();
			break;
		case 18:
			Remove_Waypoint ();
			break;
		case 21:
			Link_Waypoints ();
			break;
		case 20: 
			Dual_Link_Waypoints();
			break;
		case 22: 
			Auto_Link_Waypoints();
			break;
		case 101:
			Save_Waypoints();
			break;
		case 102:
			Load_Waypoints();
			break;
	}
	
	if(self.button8 && !(self.semi_actions & SEMIACTION_WAYPOINT))
	{
		self.semi_actions |= SEMIACTION_WAYPOINT;
		Dual_Link_Waypoints();
		waypoint_action = waypoint_action + 1;
	}
	if (self.button0 && !(self.semi_actions & SEMIACTION_WAYPOINT))
	{
		self.semi_actions |= SEMIACTION_WAYPOINT;
		Create_New_Waypoint();
		waypoint_action = waypoint_action + 1;
	}
	
	if (self.button7 && !(self.semi_actions & SEMIACTION_WAYPOINT))
	{
		self.semi_actions |= SEMIACTION_WAYPOINT;
		Select_Waypoint();
		waypoint_action = waypoint_action + 1;
	}
	
	if(self.button4 && !(self.semi_actions & SEMIACTION_WAYPOINT))
	{
		self.semi_actions |= SEMIACTION_WAYPOINT;
		waypoint_action = waypoint_action + 1;
		Move_Waypoint();
	}
	if(self.button6 && !(self.semi_actions & SEMIACTION_WAYPOINT))
	{
		self.semi_actions |= SEMIACTION_WAYPOINT;
		Remove_Waypoint ();
		waypoint_action = waypoint_action + 1;
	}
	if(self.button5 && !(self.semi_actions & SEMIACTION_WAYPOINT))
	{
		self.semi_actions |= SEMIACTION_WAYPOINT;
		Make_Special_Waypoint();
		waypoint_action = waypoint_action + 1;
	}
	
	if(!self.button0 && !self.button7 && !self.button4 && !self.button5 && !self.button6 && !self.button8)
	{
		self.semi_actions &= ~SEMIACTION_WAYPOINT;
	}
	
	self.impulse = 0;
};

void () Waypoint_Logic =
{
	if (waypoint_action > 20) {
		if (cvar("autosave_waypoint"))
			Save_Waypoints();
		waypoint_action = 0;
	}
		
	Waypoint_Functions();
};