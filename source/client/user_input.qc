/*
	client/user_input.qc

	User Input scheme for menus.

	Copyright (C) 2021-2023 NZ:P Team

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

string(string source, float spec_key, float key, float max_length) GetUserInput =
{
    // Welcome to the world's worst user input implementation.
    // Seriously, though -- it's kind of hacked together.
    // I think at least. Upon further looking it seems,, decent?

    // Backspace -- just return the string minus 1.
    if (spec_key == K_BACKSPACE) {
        return substring(source, 0, strlen(source) - 1);
    }

    // If we've hit our max length, do nothing.
    if (strlen(source) >= max_length)
        return source;

    // Key is out of range (thanks Nuclide)
    if ((key < 32 || key > 125))
        return source;

    // Append and send that shit out!
    return sprintf("%s%s", source, chr2str(key));
}