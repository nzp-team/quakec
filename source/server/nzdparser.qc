/*
	server/nzdparser.qc

	parses NZData files for map variety

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

//custom weapon search
void(string weaponFile) nzd_defineweapon = {
	float f, p, l, fnum, wepnum, framenum, fsnd;
	string line;
	
	fnum = 0;
	framenum = 0;
	fsnd = 0;

	line = strcat(strcat("data/maps/", weaponFile), ".cw");
	f = fopen(line, FILE_READ);

	if (f == -1) { //no custom weapons
		return;
	}
	wepnum = currentWeaponTracker - 1;
	p = 0;
	l = 1;

	while(l) {
		string li;
		li = fgets(f);

		if not (li) {
			l = 0;
			break;
		}

		line = strtrim(li);

		if (line == "")
			continue;

		switch(p) {
			case 0:
				wepnum += 1;
				currentWeaponTracker = wepnum;
				if (line == "weapon")
					p = 1;
				break;
			case 1:
				if (line == "{")
					p = 2;
				else
					bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(line, " expected {\n")));
				break;
			case 2:
				tokenize(line);

				string v, vari;
				vari = strtrim(argv(0));
				v = strtrim(argv(2));

				switch(vari) {
					case "name":
						CustomWeapons[wepnum].name = v;
						break;
					case "mag":
						CustomWeapons[wepnum].magSize = stof(v);
						break;
					case "reserve":
						CustomWeapons[wepnum].reserveSize = stof(v);
						break;
					case "vmodel":
						CustomWeapons[wepnum].vmodel = v;
						break;
					case "vmodel2":
						CustomWeapons[wepnum].vmodel2 = v;
						break;
					case "gmodel":
						CustomWeapons[wepnum].gmodel = v;
						break;
					case "ads":
						CustomWeapons[wepnum].adsofs = stov(v);
						break;
					case "firetype":
						CustomWeapons[wepnum].firetype = stof(v);
						break;
					case "ispap":
						CustomWeapons[wepnum].ispap = stof(v);
						break;
					case "nonpap":
						CustomWeapons[wepnum].nonpap = stof(v);
						break;
					case "pap":
						CustomWeapons[wepnum].papWpn = stof(v);
						break;
					case "dmg":
						CustomWeapons[wepnum].damage = stof(v);
						break;
					case "shotcount":
						CustomWeapons[wepnum].shotcount = stof(v);
						break;
					case "bodypen":
						CustomWeapons[wepnum].bodypen = stof(v);
						break;
					case "penetration":
						CustomWeapons[wepnum].penetration = stof(v);
						break;
					case "spread":
						CustomWeapons[wepnum].spread = stof(v);
						break;
					case "fdelay":
						CustomWeapons[wepnum].fdelay = stof(v);
						break;
					case "rdelay":
						CustomWeapons[wepnum].rdelay = stof(v);
						break;
					case "walkspeed":
						CustomWeapons[wepnum].walkspeed = stof(v);
						break;
					case "firesound":
						CustomWeapons[wepnum].firesound = v;
						break;
					case "skin":
						CustomWeapons[wepnum].skin = stof(v);
						break;
					case "recoil":
						CustomWeapons[wepnum].recoil = stof(v);
						break;
					case "crossmin":
						CustomWeapons[wepnum].crossmin = stof(v);
						break;
					case "crossmax":
						CustomWeapons[wepnum].crossmax = stof(v);
						break;
					case "lowmag":
						CustomWeapons[wepnum].lowmag = stof(v);
						break;
					case "lowreserve":
						CustomWeapons[wepnum].lowreserve = stof(v);
						break;
					case "flash":
						CustomWeapons[wepnum].flash = stov(v);
						break;
					case "flashsize":
						CustomWeapons[wepnum].flashsize = stof(v);
				}

				break;
			case 3:
                if (line == "[") {
                    p = 4;
                } else {
                    bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(line, " expected [\n")));
                }
                break;
            case 4:
                if (line == "]") {
                    p = 2;
                } else {
					switch(wepnum) {
						/*case 0: W_C1FRAMES[fnum] = stof(line); break;
						case 1: W_C2FRAMES[fnum] = stof(line); break;
						case 2: W_C3FRAMES[fnum] = stof(line); break;
						case 3: W_C4FRAMES[fnum] = stof(line); break;*/
					}
					fnum++;
                }
				break;
			case 5:
                if (line == "[") {
                    p = 6;
                } else {
                    bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(line, " expected [\n")));
                }
                break;
            case 6:
                if (line == "]") {
                    p = 2;
                } else {
					switch(wepnum) {
						/*case 0: W_C1XSNDFRAME[framenum] = stof(line); break;
						case 1: W_C2XSNDFRAME[framenum] = stof(line); break;
						case 2: W_C3XSNDFRAME[framenum] = stof(line); break;
						case 3: W_C4XSNDFRAME[framenum] = stof(line); break;*/
					}
					framenum++;
                }
				break;
			case 7:
                if (line == "[") {
                    p = 8;
                } else {
                    bprint(PRINT_HIGH, strcat("Error: unknown variable ", strcat(line, " expected [\n")));
                }
                break;
            case 8:
                if (line == "]") {
                    p = 2;
                } else {
					switch(wepnum) {
						/*case 0: W_C1XTRASND[fsnd] = line; break;
						case 1: W_C2XTRASND[fsnd] = line; break;
						case 2: W_C3XTRASND[fsnd] = line; break;
						case 3: W_C4XTRASND[fsnd] = line; break;*/
					}
					fsnd++;
                }
				break;
		}
	}
	fclose(f);
}


void() load_nzd = {

}
