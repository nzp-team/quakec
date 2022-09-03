/*
	server/dummies/generic.qc

	generic (all platform) dummys

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

void LoadWaypointData() = {};

// Old Demo defs
.float fogdogs;
.float MaxRange;
float gotdog;

void(string chaptertitle, string location, string date, string person, entity who) WorldText = {};

void GiveAchievement(float achievement_id, optional entity who) = {};

