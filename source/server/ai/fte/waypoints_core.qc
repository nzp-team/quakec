/*
	server/ai/fte/waypoints_core.qc

	FTE waypointing

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

void() creator_way_touch =
{
	if (cvar("waypoint_mode")) {
		if (other.classname != "player") {
			return;
		}
		
		current_way = self;
	}
}

void () Create_New_Waypoint =
{
	float way_count;
	float tempf;
	entity tempe;
	entity new_way;

	way_count = -1;
	tempe = find (world, classname, "waypoint");
	while (tempe) {
		tempf = stof(tempe.waynum);
		if (tempf > way_count) {
			way_count = tempf;
		}
		tempe = find (tempe, classname, "waypoint");
	}
	new_way = spawn();

	setorigin(new_way, self.origin);
	
	
	//new_way.flags = FL_ITEM;
	new_way.solid = SOLID_TRIGGER;

	
	setmodel(new_way, "models/way/normal_way.spr");
	new_way.classname = "waypoint";
	new_way.effects = EF_FULLBRIGHT;
	
	new_way.waynum = ftos(way_count + 1);
	new_way.targetname = strzone(new_way.targetname);
	bprint (PRINT_HIGH, "Created waypoint  ");
	bprint (PRINT_HIGH, new_way.waynum);
	bprint (PRINT_HIGH, "\n");

	new_way.touch = creator_way_touch;
}


void () Make_Special_Waypoint =
{
	if (self.classname != "player" || !active_way) {
		return;
	}
	if (active_way.targetname != "") {//Toggling it back off
		setmodel(active_way, "models/way/current_way.spr");
		active_way.targetname = "";
		bprint (PRINT_HIGH, "Waypoint ");
		bprint (PRINT_HIGH, active_way.waynum);
		bprint (PRINT_HIGH, " is no longer a special waypoint\n");
		return;
	}

	if (active_way) {
		if(self.active_door == world) {
			bprint (PRINT_HIGH, "Error: no door selected!\n");
			return;
		}

		if(self.active_door.wayTarget == "") {
			bprint (PRINT_HIGH, "Error: Door has no wayTarget value!\n");
			return;
		}
		setmodel(active_way, "models/way/current_way_door.spr");
		active_way.targetname = self.active_door.wayTarget;

		bprint (PRINT_HIGH, "special waypoint ");
		bprint (PRINT_HIGH, active_way.waynum);
		bprint (PRINT_HIGH, " named ");
		bprint (PRINT_HIGH, active_way.targetname);
		bprint (PRINT_HIGH, "\n");
	}
}


void () Move_Waypoint =
{
	if (!active_way)
		return;

	setorigin (active_way, self.origin);
	bprint (PRINT_HIGH, "Moved waypoint ");
	bprint (PRINT_HIGH, active_way.waynum);
	bprint (PRINT_HIGH, "\n");
	
}

void () Select_Waypoint =
{
	if (self.classname != "player")
		return;
	if (!current_way)
		return;

	entity tempe;

	if (current_way == active_way)
		active_way = world;
	else
		active_way = current_way;

	tempe = find (world, classname, "waypoint");
	while (tempe)
	{
		if (tempe.targetname != "")
			setmodel(tempe, "models/way/normal_way_door.spr");
		else
			setmodel(tempe, "models/way/normal_way.spr");
		tempe = find (tempe, classname, "waypoint");
	}
	if (active_way)
	{
		if (active_way.targetname != "")
			setmodel(active_way, "models/way/current_way_door.spr");
		else
			setmodel(active_way, "models/way/current_way.spr");
		
		bprint (PRINT_HIGH, "Selected waypoint ");
		bprint (PRINT_HIGH, active_way.waynum);
		if(active_way.targetname != "")
		{
			bprint (PRINT_HIGH, ", special tag ");
			bprint (PRINT_HIGH, active_way.targetname);
		}
		bprint (PRINT_HIGH, "\n");
		
		float i;
		for	(i = 0; i < MAX_WAY_TARGETS; i++) {
			tempe = find (world, waynum, active_way.targets[i]);
			if (tempe) {
				if (tempe.targetname != "")
					setmodel(tempe, "models/way/last_way_door.spr");
				else
					setmodel(tempe, "models/way/last_way.spr");
			} else {
				active_way.targets[i] = "";
			}
		}
	}
}


void() Remove_Waypoint =
{
	entity tempe;
	float i;
	if (!active_way)
		return;
		
	tempe = find (world, classname, "waypoint");
	while (tempe) {
	
		for	(i = 0; i < MAX_WAY_TARGETS; i++) {
			if (tempe.targets[i] == active_way.waynum) {
				tempe.targets[i] = "";
			}
		}

		tempe = find (tempe, classname, "waypoint");
	}
		
	bprint(PRINT_HIGH, "Removed waypoint ");
	bprint(PRINT_HIGH, active_way.waynum);
	bprint(PRINT_HIGH, "\n");
	remove (active_way);
}

float Waypoint_Linked_To(entity from, entity to) {
	float i;
	for	(i = 0; i < MAX_WAY_TARGETS; i++) {
		if (from.waynum == to.targets[i]) {
			bprint(PRINT_HIGH, "These waypoints are already linked!\n");
			return 1;
		}
	}

	return 0;
}

float Link (entity from, entity to) {
	float i;
	entity tempe;
	for	(i = 0; i < MAX_WAY_TARGETS; i++) {
		tempe = find(world, waynum, from.targets[i]);

		if (tempe == world || !from.targets[i]) {
			from.targets[i] = to.waynum;
			bprint(PRINT_HIGH, "Linked waypoint ");
			bprint(PRINT_HIGH, to.waynum);
			bprint(PRINT_HIGH, " to ");
			bprint(PRINT_HIGH, from.waynum);
			bprint(PRINT_HIGH, "\n");

			if (to.targetname != "") {
				setmodel(to, "models/way/last_way_door.spr");
			} else {
				setmodel(to, "models/way/last_way.spr");
			}
			
			return 1;
		}
	}

	return 0;
}

void () Link_Waypoints =
{
	if (self.classname != "player")
		return;
	if (!current_way)
		return;
	if (!active_way)
		return;
	if (current_way == active_way)
		return;
	
	if (Waypoint_Linked_To(current_way, active_way)) {
		bprint(PRINT_HIGH, "[INFO]: These waypoints are already linked!\n");
		return;
	}
	
	float i;
	entity tempe;
	for	(i = 0; i < MAX_WAY_TARGETS; i++) {
		// First pass - if the target field is blank no extra
		// validation is needed, just link.
		if (!active_way.targets[i]) {
			if (Link(active_way, current_way))
				return;

			bprint(PRINT_HIGH, "[INFO]: Got Linkable Waypoints but Linking failed!\n");
			return;
		}

		// Second pass - if the targets field is occupied
		// check if the waypoint still exists, link if it
		// does not.
		if (find(world, waynum, active_way.targets[i]) == world) {
			bprint(PRINT_HIGH, sprintf("[INFO]: Found Waypoint ID %s but not entity, overwriting link..\n", active_way.targets[i]));

			if (Link(active_way, current_way))
				return;

			bprint(PRINT_HIGH, "        ..Failed!\n");
			return;
		}
	}

	bprint(PRINT_HIGH, "[INFO]: All Waypoint links occupied for this Waypoint!\n");
}



void() Dual_Link_Waypoints =
{
	if (self.classname != "player" || !current_way || !active_way || current_way == active_way) {
		return;
	}
	
	float result1,result2;
	result1 = Waypoint_Linked_To(current_way,active_way);
	result2 = Waypoint_Linked_To(active_way,current_way);
	
	if(result1 && result2) {
		bprint(PRINT_HIGH, "Both waypoints already linked!\n");
		return;
	}
	
	if(!result1)
	{
		if (Link(current_way,active_way)) {
			bprint(PRINT_HIGH, strcat("Linked waypoint ", strcat(current_way.waynum, strcat(" to ",strcat(active_way.waynum, "\n")))));
		} else {
			bprint(PRINT_HIGH, strcat("ERROR: Could not link waypoint ", strcat(current_way.waynum, strcat(" to ", strcat(active_way.waynum, "\n")))));
		}
	}
	if(!result2)
	{
		if (Link(active_way,current_way)) {
			bprint(PRINT_HIGH, strcat("Linked waypoint ", strcat(active_way.waynum, strcat(" to ", strcat(current_way.waynum, "\n")))));
		} else {
			bprint(PRINT_HIGH, strcat("ERROR: Could not link waypoint ", strcat(active_way.waynum, strcat(" to ", strcat(current_way.waynum, "\n")))));
		}
	}
}



//alter auto_link_waypoints to iterate through the closest waypoints from closest to furthest
// on the innermost loop, we find the next closest waypoint that is further away from the last closest waypoint, and we use that!

void() Auto_Link_Waypoints =
{
	entity tempe1, tempe2;
	
	tempe1 = find(world,classname,"waypoint");
	while(tempe1 != world)
	{
		tempe2 = find(world,classname,"waypoint");
		while(tempe2 != world)
		{
			if(tempe1 == tempe2)
			{
				tempe2 = find(tempe2,classname,"waypoint");
				continue;
			}
			
			if(tracemove(tempe1.origin,VEC_HULL_MIN,VEC_HULL_MAX,tempe2.origin,TRUE,self))
			{
				Link(tempe1,tempe2);
			}
			
			tempe2 = find(tempe2,classname,"waypoint");
		}
		tempe1 = find(tempe1,classname,"waypoint");
	}
}
//alter auto_link_waypoints to iterate through the closest waypoints from closest to furthest
// on the innermost loop, we find the next closest waypoint that is further away from the last closest waypoint, and we use that!

void() Remove_Links =
{
	entity tempe;
	
	tempe = find(world,classname,"waypoint");
	while(tempe != world)
	{
		float i;
		for (i = 0; i < MAX_WAY_TARGETS; i = i + 1) {
			if (tempe.targetname != "")
				setmodel(tempe, "models/way/normal_way_door.spr");
			else
				setmodel(tempe, "models/way/normal_way.spr");
			tempe.targets[i] = "";
		}
		tempe = find(tempe,classname,"waypoint");
	}
}

string tempstest;
void() Save_Waypoints_Legacy =
{
	float file;
	string h;

	h = strcat(mappath, ".way");
	file = fopen (h, FILE_WRITE);
	
	entity dway;

	dway = find(world, classname, "waypoint");
	while (dway)
	{
		dprint ("Saving waypoints\n");
		fputs(file,"Waypoint\n");
		fputs(file,"{\norigin = ");

		// FTE users are just gonna have to deal with no float precision
		// for now. :s
		int x = ftoi(dway.origin_x);
		int y = ftoi(dway.origin_y);
		int z = ftoi(dway.origin_z);
		tempstest = strcat("'", itos(x), " ", itos(y), " ", itos(z), "'");
		tempstest = strzone(tempstest);
		fputs(file, tempstest);
		strunzone (tempstest);
		fputs(file,"\nid = ");
		fputs(file,dway.waynum);
		fputs(file,"\nspecial = ");
		fputs(file,dway.targetname);
		fputs(file,"\ntarget = ");
		fputs(file,dway.targets[0]);
		fputs(file,"\ntarget2 = ");
		fputs(file,dway.targets[1]);
		fputs(file,"\ntarget3 = ");
		fputs(file,dway.targets[2]);
		fputs(file,"\ntarget4 = ");
		fputs(file,dway.targets[3]);
		fputs(file,"\ntarget5 = ");
		fputs(file,dway.targets[4]);
		fputs(file,"\ntarget6 = ");
		fputs(file,dway.targets[5]);
		fputs(file,"\ntarget7 = ");
		fputs(file,dway.targets[6]);
		fputs(file,"\ntarget8 = ");
		fputs(file,dway.targets[7]);
		fputs(file,"\n");
		fputs(file,"}\n");
		
		
		dway = find(dway, classname, "waypoint");
		if (dway)
			fputs(file,"\n");
	}
	fclose(file);
}

void() Save_Waypoints
{
	float file;
	string h;
	float i;
	entity tempe;

	h = strcat(mappath, ".way");
	file = fopen (h, FILE_WRITE);
	
	dprint (strcat("Saving waypoints ", strcat(h, "\n")));
	
	local entity dway;
	//fputs(file, "begin\n");
	dway = find(world, classname, "waypoint");
	while (dway)
	{
		fputs(file,"waypoint\n");
		fputs(file,"{\n");
		fputs(file, strcat(" id: ", strcat(dway.waynum, "\n")));
		fputs(file, strcat(" origin: ", strcat(vtos(dway.origin), "\n")));
		if (dway.targetname != "") {
			fputs(file, strcat(" door: ", strcat(dway.targetname, "\n")));
		}

		fputs(file, " targets:\n");
		fputs(file, " [\n");
		for (i = 0; i < MAX_WAY_TARGETS; i++) {
			if (dway.targets[i] != "") {
				tempe = findfloat (world, waynum, dway.targets[i]);

				if (tempe != world) {
					fputs(file, strcat("  ", strcat(dway.targets[i], "\n")));
				} else {
					tempe = find (world, waynum, dway.targets[i]);
					if (tempe != world) {
						fputs(file, strcat("  ", strcat(dway.targets[i], "\n")));
					}
				}
			}
		}
		fputs(file, " ]\n");
		fputs(file,"}\n");
		
		
		dway = find(dway, classname, "waypoint");
		if (dway)
			fputs(file,"\n");
	}
	fclose(file);
}

void (vector here, float which, string special, string trg, string trg2, string trg3, string trg4, string trg5, string trg6, string trg7, string trg8) Create_Waypoint =
{
	entity new_way;
	new_way = spawn();

	setorigin(new_way, here);
	
	
	//new_way.flags = FL_ITEM;
	new_way.solid = SOLID_TRIGGER;

	if (cvar("waypoint_mode"))
		setmodel(new_way, "models/way/normal_way.spr");
	new_way.classname = "waypoint";
	new_way.effects = EF_FULLBRIGHT;
	new_way.waynum = ftos(which);
	dprint ("Created waypoint  ");
	dprint (new_way.waynum);
	dprint ("\n");
	
	if (special != "")
	{
		if (!cvar("waypoint_mode"))
			new_way.classname = "waypoint_s";
		if (cvar("waypoint_mode"))
			setmodel(new_way, "models/way/normal_way_door.spr");
		new_way.targetname = special;
		dprint ("Special waypoint  ");
		dprint (new_way.targetname);
		dprint ("\n");
		//current_special++;
	}

	new_way.targets[0] = trg;
	new_way.targets[1] = trg2;
	new_way.targets[2] = trg3;
	new_way.targets[3] = trg4;
	new_way.targets[4] = trg5;
	new_way.targets[5] = trg6;
	new_way.targets[6] = trg7;
	new_way.targets[7] = trg8;

	new_way.touch = creator_way_touch;
}

float waypoints_loaded;
void() Load_Waypoints
{
	float file, point;
	string h;
	float targetcount, loop;

	entity new_way;

	h = strcat(mappath, ".way");
	file = fopen (h, FILE_READ);

	if (file == -1)
	{

#ifdef FTE

		dprint("LoadWaypointData: No .way file found, trying Beta format..\n");
		Compat_TryLoadBetaWaypoints();

#endif // FTE

		return;
	}

	new_way = spawn();
	targetcount = 0;
	point = 0;
	loop = 1;
	while (loop)
	{
		string line;
		line = fgets(file);
		if (line == "") {
			bprint(PRINT_HIGH, "End of file\n");
			loop = 0;
			break;
		}
		h = strtrim(line);

		//bprint(PRINT_HIGH, strcat(h, "\n"));
		if (h == "") {
			continue;
		}

		switch (point) {
			case 0:
				if (h == "waypoint") {
					new_way = spawn();
					new_way.solid = SOLID_TRIGGER;
					new_way.effects = EF_FULLBRIGHT;
					new_way.model = "models/way/normal_way.spr";
					setmodel(new_way, "models/way/normal_way.spr");
					new_way.classname = "waypoint";

					new_way.touch = creator_way_touch;
					point = 1;
					targetcount = 0;
				} else if (h == "Waypoint") {
					//bprint(PRINT_HIGH, "Identified .way as legacy..\n");
					point = 99;
					Load_Waypoints_Legacy();
					loop = 0;
					break;
				} else {
					bprint(PRINT_HIGH, strcat("Error: unknown point ", strcat(h, "\n")));
				}
				break;
			case 1:
				if (h == "{") {
					point = 2;
				} else {
					bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, " expected {\n")));
				}
				break;
			case 2:
				tokenize(h);

				string value, variable;
				variable = strtrim(argv(0));
				value = strtrim(argv(2));

				//bprint(PRINT_HIGH, strcat(variable, "\n"));

				switch (variable) {
					case "origin":
						
						print(strcat(value, "\n"));
						new_way.origin = stov(value);
						setorigin(new_way, new_way.origin);
						break;
					case "id":
						new_way.waynum = value;
						break;
					case "door":
						new_way.targetname = value;
						
						setmodel(new_way, "models/way/normal_way_door.spr");
						break;
					case "targets":
						point = 3;
						break;
					case "}":
						point = 0;
						break;
					default:
						bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(variable, "\n")));
						break;
				}
				break;
			case 3:
				if (h == "[") {
					point = 4;
				} else {
					bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(h, " expected [\n")));
				}
				break;
			case 4:
				if (targetcount >= MAX_WAY_TARGETS) {
					bprint(PRINT_HIGH, "Error: Target count too high for waypoint\n");
				} else if (h == "]") {
					point = 2;
				} else  {
					bprint(PRINT_HIGH, strcat(strcat("WAYPOINT TARGET: ", strcat(strcat(ftos(targetcount), " "), h)), "\n"));
					new_way.targets[targetcount] = h;
					targetcount++;
				}
				break;
		}
	}

	fclose(file);
	waypoints_loaded = 1;
}

void() Load_Waypoints_Legacy
{
	float file, which;
	string h, special, trg, trg2, trg3, trg4, trg5, trg6, trg7, trg8;
	local vector where;

	h = strcat(mappath, ".way");
	file = fopen (h, FILE_READ);

	if (file == -1)
	{
		dprint("Error: file not found \n");
		return;
	}

	// Clear all waypoints
	for(float i = 0; i < MAX_WAYPOINTS; i++) {
		waypoints[i].id = -1;
	}

	while (1)
	{
		// the first line is just a comment, ignore it
		h = fgets(file);	
		if (h != "Waypoint")
		{
			fclose(file);
			return;
		}
		h = fgets(file);
		h = fgets(file);
		h = substring(h, 9, 50); // fix for high-precision vectors.
		where = stov(h);
		
		h = (fgets(file));
		h = substring(h, 5, 20);
		which = stof(h);
	
		h = (fgets(file));
		special = substring(h, 10, 20);
	
		h = (fgets(file));
		trg = substring(h, 9, 20);

		h = (fgets(file));
		trg2 = substring(h, 10, 20);

		h = (fgets(file));
		trg3 = substring(h, 10, 20);

		h = (fgets(file));
		trg4 = substring(h, 10, 20);

		h = (fgets(file));
		trg5 = substring(h, 10, 20);

		h = (fgets(file));
		trg6 = substring(h, 10, 20);

		h = (fgets(file));
		trg7 = substring(h, 10, 20);

		h = (fgets(file));
		trg8 = substring(h, 10, 20);
		
		waypoint_ai waypoint;
		waypoint = waypoints[which];

		waypoints[which].id = which;
		waypoints[which].org = where;
		waypoints[which].targetdoor = special;

		if (waypoint_mode) {
			entity new_way = spawn();
			new_way.solid = SOLID_TRIGGER;
			new_way.touch = creator_way_touch;
			new_way.effects = EF_FULLBRIGHT;
			new_way.classname = "waypoint";
			new_way.waynum = ftos(which);
			new_way.targets[0] = trg;
			new_way.targets[1] = trg2;
			new_way.targets[2] = trg3;
			new_way.targets[3] = trg4;
			new_way.targets[4] = trg5;
			new_way.targets[5] = trg6;
			new_way.targets[6] = trg7;
			new_way.targets[7] = trg8;
			new_way.targetname = special;
			setorigin(new_way, where);

			if (special != "" && special != " ") {
				setmodel(new_way, "models/way/normal_way_door.spr");
			} else {
				setmodel(new_way, "models/way/normal_way.spr");
			}
		}


		// Initialize neighbor slots to load
		waypoints[which].target_id[0] = -1;
		waypoints[which].target_id[1] = -1;
		waypoints[which].target_id[2] = -1;
		waypoints[which].target_id[3] = -1;
		waypoints[which].target_id[4] = -1;
		waypoints[which].target_id[5] = -1;
		waypoints[which].target_id[6] = -1;
		waypoints[which].target_id[7] = -1;
		// Initialize extra neighbor slots
		waypoints[which].target_id[8] = -1;
		waypoints[which].target_id[9] = -1;
		

		if(trg != "") {
			waypoints[which].target_id[0] = stof(trg);
		}
		if(trg2 != "") {
			waypoints[which].target_id[1] = stof(trg2);
		}
		if(trg3 != "") {
			waypoints[which].target_id[2] = stof(trg3);
		}
		if(trg4 != "") {
			waypoints[which].target_id[3] = stof(trg4);
		}
		if(trg5 != "") {
			waypoints[which].target_id[4] = stof(trg5);
		}
		if(trg6 != "") {
			waypoints[which].target_id[5] = stof(trg6);
		}
		if(trg7 != "") {
			waypoints[which].target_id[6] = stof(trg7);
		}
		if(trg8 != "") {
			waypoints[which].target_id[7] = stof(trg8);
		}

		h = (fgets(file));
		h = (fgets(file));
	}
}


void VisualizePathfind() {
	if (self.classname != "player")
		return;
	if (!current_way)
		return;
	if (!active_way)
		return;
	if (current_way == active_way)
		return;
	
	Pathfind(self, stof(active_way.waynum), stof(current_way.waynum));
}

.float waypoint_delay;

//Waypoint logic functions
float way_save_state;
void () Waypoint_Functions =
{

	switch (self.impulse) {
		case 24:
			if (way_save_state == 0) {
				bprint(PRINT_HIGH, "Are you sure you want to save? This will overwrite the old waypoints file, press Load to cancel!\n");
				way_save_state++;
			} else {
				bprint(PRINT_HIGH, "Saving Waypoints..\n");
				Save_Waypoints_Legacy();
				way_save_state = 0;
			}
			break;
		case 22:
			if (way_save_state == 1) {
				bprint(PRINT_HIGH, "Waypoint Save cancelled.\n");
				way_save_state = 0;
			} else {
				if (!waypoints_loaded)
					Load_Waypoints();
			}
			break;
	}
	
	self.impulse = 0;

	// Match what we display on the screen
	if (self.button0 && self.waypoint_delay < time) { 
		Create_New_Waypoint(); 
		self.waypoint_delay = time + 1;
	}

	if (self.button4 && self.waypoint_delay < time) {
		Move_Waypoint();
		self.waypoint_delay = time + 0.25;
	}

	if (self.button7 && self.waypoint_delay < time) {
		Select_Waypoint();
		self.waypoint_delay = time + 0.25;	
	}

	if (self.button8 && self.waypoint_delay < time) {
		Link_Waypoints ();
		self.waypoint_delay = time + 0.5;	
	}

	if (self.button6 && self.waypoint_delay < time) {
		Remove_Waypoint();
		self.waypoint_delay = time + 0.5;	
	}

	if (self.button5 && self.waypoint_delay < time) {
		Make_Special_Waypoint();
		self.waypoint_delay = time + 1;
	}

};

void () Waypoint_Logic =
{
	waypoint_mode = true;
	Waypoint_Functions();
};