/*
	client/user_input.qc

	User Input scheme for menus.

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

    // Seriously bad HACKS incoming...
    // The if statement is supposed to be checking "key" and not "spec_key"
    // but... checking key doesn't play nice with SDL for some reason.
    // This breaks any letter/symbol you need to press shift to type.
    // This includes capital letters.
    // TODO TODO TODO Fix this... or hope the new revamp fixes it.
    //if ((key < 32 || key > 125))
    //    return source
    if ((spec_key < 32 || spec_key > 125))
        return source;

    // Append and send that shit out!
    // This is supposed to be appending "key"... but it isn't
    // too bad!
    return sprintf("%s%s", source, chr2str(spec_key));
}
