/*
	server/map_rotation.qc

	Global useprint definition registry.

	Copyright (C) 2021-2026 NZ:P Team

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

string useprint_strings[256];
vector useprint_colors[256];
float useprint_count;
float useprint_registration_locked;

float(string value, vector color) Useprint_Register =
{
	if (value == "")
		return 0;

	if (color == '0 0 0')
		color = '1 1 1';

	for (float i = 1; i < useprint_count; i++) {
		if (useprint_strings[i] == value && useprint_colors[i] == color)
			return i;
	}

	if (useprint_registration_locked)
		error("Useprint_Register called after useprint registration was locked\n");

	if (useprint_count > USEPRINT_MAX) {
		dprint("WARNING: too many useprint strings\n");
		return 0;
	}

	float index = useprint_count;
	useprint_strings[index] = strzone(value);
	useprint_colors[index] = color;
	useprint_count++;
	return index;
};
