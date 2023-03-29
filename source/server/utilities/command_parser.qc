/*
	server/utilities/command_parser.qc

	Contains SV_ParseClientCommand(), helper functions for server
    commands, and a table storing command information. Modeled after
    pr_cmds.

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

// Whether the command prohibits client-sending.
float client_parse_override;

// Success/Failure return codes
#define COMMAND_SUCCESS     0
#define COMMAND_FAILURE     1

//
// Command_give(params)
// Usage: give <weapon_number>
//
float(string params) Command_give =
{
	// Anti-Cheat in Co-Op.
	if (coop && cheats_have_been_activated == false) {
		bprint(PRINT_HIGH, "Someone tried to issue Give in a Co-Op match. Nice try!\n");
		return COMMAND_FAILURE;
	}

	float wep = stof(argv(1));

	if (wep) {
		self.weapon = wep;
		self.currentammo = getWeaponAmmo(wep);
		self.currentmag = getWeaponMag(wep);
		if (IsDualWeapon(wep)) {
			self.currentmag2 = self.currentmag;
		}

		if (GetFrame(self.weapon, FIRST_TAKE_START) != 0)
			Weapon_PlayViewModelAnimation(ANIM_FIRST_TAKE, SUB_Null, 0);
		else
			Weapon_PlayViewModelAnimation(ANIM_TAKE_OUT, SUB_Null, 0);

		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;

#ifndef FTE

		self.Weapon_Name = GetWeaponName(self.weapon);

#endif // FTE

		SwitchWeapon(self.weapon);

        return COMMAND_SUCCESS;
    }

    return COMMAND_FAILURE;
}

//
// Command_addmoney(params)
// Usage: addmoney <point_value>
// Gives <point_value> amount of points to the client
// who requested it.
//
float(string params) Command_addmoney =
{
	// Anti-Cheat in Co-Op.
	if (coop && cheats_have_been_activated == false) {
		bprint(PRINT_HIGH, "Someone tried to issue Add Money in a Co-Op match. Nice try!\n");
		return COMMAND_FAILURE;
	}

    // Grab parameters.
    tokenize(params);
    float point_value = stof(argv(0));

    // Safety checks
    if (point_value == 0) {
        sprint(self, 1, "Command_addmoney: <point_value> is either zero or blank string. Failing.\n");
        return COMMAND_FAILURE;
    }

    // Assign points to the player.
    addmoney(self, point_value, 0);

    return COMMAND_SUCCESS;
}

//
// Command_softrestart()
// Executes the Soft_Restart QuakeC function.
// Useful for debugging its functionality.
//
float(string params) Command_softrestart =
{
	Soft_Restart();

	return COMMAND_SUCCESS;
}

//
// Command_godmode()
// Toggles God Mode.
//
float(string params) Command_godmode =
{
	// Anti-Cheat in Co-Op.
	if (coop && cheats_have_been_activated == false) {
		bprint(PRINT_HIGH, "Someone tried to issue God Mode in a Co-Op match. Nice try!\n");
		return COMMAND_FAILURE;
	}

	client_parse_override = false;
	return COMMAND_SUCCESS;
} 

//
// Command_noclip()
// Toggles No Clip.
//
float(string params) Command_noclip =
{
	// Anti-Cheat in Co-Op.
	if (coop && cheats_have_been_activated == false) {
		bprint(PRINT_HIGH, "Someone tried to issue No-Clip in a Co-Op match. Nice try!\n");
		return COMMAND_FAILURE;
	}

	client_parse_override = false;
	return COMMAND_SUCCESS;
} 

//
// Command_tracedmgmultiplier()
// Multiplies damage output with weapons that fire Traces.
//
float(string params) Command_tracedmgmultiplier =
{
	// Anti-Cheat in Co-Op.
	if (coop && cheats_have_been_activated == false) {
		bprint(PRINT_HIGH, "Someone tried to issue sv_tracedmgmultiplier in a Co-Op match. Nice try!\n");
		return COMMAND_FAILURE;
	}

	// Grab parameters.
    tokenize(params);
	float value = stof(argv(0));

	if (value <= 0) {
		bprint(PRINT_HIGH, "Command_tracedmgmultiplier: 0 or less than 0 multiplier not allowed. Failing.\n");
		return COMMAND_FAILURE;
	}

	global_trace_damage_multiplier = value;
	return COMMAND_SUCCESS;
}

//
// Server command table
// command_name         : Command string entered into developer console.
// command_function     : QuakeC function called when command is executed.
//                        Returns 0 for success, 1 for failure.
// requires_arguments   : Whether or not to expect arguments to be passed 
//                        with the command.
// command_description  : Called when no params (when applicable) are given.
//
var struct {
    string                  command_name;
    float(string params)    command_function;
    float                   requires_arguments;
    string                  command_description;
} server_commands[] = {
    {"addmoney", Command_addmoney, true, "Usage: addmoney <point_value>\n  Gives `point_value` amount of points to the client who requested it.\n"},
    {"give", Command_give, true, "Usage: give <weapon number>\n  Gives `weapon` of index.\n"},
	{"qc_soft_restart", Command_softrestart, false, "Executes the Soft_Restart QuakeC function. Useful for debugging its functionality.\n"},
	{"god", Command_godmode, false, "Toggles God Mode.\n"},
	{"noclip", Command_noclip, false, "Toggles No Clip.\n"},
	{"sv_tracedmgmultiplier", Command_tracedmgmultiplier, true, "Multiplies damage output with weapons that fire Traces.\n"}
};

//
// SV_ParseClientCommand(command_string)
// Server-Side client command parser to add special
// gameplay commands that interact with QuakeC.
//

void(string command_string) SV_ParseClientCommand =
{
	// If true, we will avoid sending the command info
	// to the client.
	client_parse_override = false;

	// Get the string ready for arg parsing
	tokenize(command_string);

	// Grab the command string
	string command = argv(0);

	// Check for 'say' prefix (`cl_chatmode 2` will append it
	// to everything unregistered by the client). Re-tokenize
	// if found.
	if (command == "say") {
		string fixed_command_string = argv(1);
		tokenize(fixed_command_string);
		command = argv(0);
	}

    // Now iterate over our commands
    for (float i = 0; i < server_commands.length; i++) {
        // Command names match
        if (command == server_commands[i].command_name) {
            // Override Client Commands
            client_parse_override = true;

            // Return description if no params are given
            if (argv(1) == "" && server_commands[i].requires_arguments == true) {
                sprint(self, 1, server_commands[i].command_description);
            } else {
                if (server_commands[i].command_function(argv(1)) == COMMAND_FAILURE) {
                    sprint(self, 1, "Command executed but failed to complete.\n");
                }
            }
        }
    }

	// Client override was disabled, so let the engine
	// deal with whatever was sent.
#ifdef FTE

	if (client_parse_override == false)
		clientcommand(self, command_string);

#endif // FTE
};
