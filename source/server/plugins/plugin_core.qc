/*
	server/plugins/plugin_core.qc

	In-game chat plugin core.

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
#ifdef FTE

//
// Plugin command table
// command_name         : Command string entered into developer console.
// command_function     : QuakeC function called when command is executed.
//                        Returns 0 for success, 1 for failure.
//
var struct {
    string                  command_name;
    float(string params)    command_function;
    float                   requires_arguments;
    string                  command_description;
} plugin_commands[] = {
    {"mapvote", ChatPlugin_MapVote, true, "Usage: mapvote <bsp_name>\nAttempts to initiate a Map Vote. Fails if one is already in progress.\n"},
    {"mapvote_y", ChatPlugin_MapVoteYes, false, "Usage: mapvote_y\n"},
    {"mapvote_n", ChatPlugin_MapVoteNo, false, "Usage: mapvote_n\n"},

};

#endif // FTE