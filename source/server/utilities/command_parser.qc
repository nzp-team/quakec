/*
	server/utilities/command_parser.qc

	Contains SV_ParseClientCommand(), helper functions for server
    commands, and a table storing command information. Modeled after
    pr_cmds.

	Copyright (C) 2021-2022 NZ:P Team

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

// Needed to iterate through all of the command table.
#define NUMBER_OF_COMMANDS  2

// Success/Failure return codes
#define COMMAND_SUCCESS     0
#define COMMAND_FAILURE     1

//
// Command_give(params)
// Usage: give <weapon_number>
//
float(string params) Command_give =
{
	float wep = stof(argv(1));

	if (wep) {
		if (!self.secondaryweapon) {
			WeaponSwitch(self);
		}

	    float startframe, endframe;
		string modelname;

		self.weapon = wep;
		self.currentammo = getWeaponAmmo(wep);
		self.currentmag = getWeaponMag(wep);
		if (IsDualWeapon(wep)) {
			self.currentmag2 = self.currentmag;
		}

		self.weaponskin = GetWepSkin(self.weapon);

		startframe = GetFrame(self.weapon,TAKE_OUT_START);
		endframe = GetFrame(self.weapon,TAKE_OUT_END);
		modelname = GetWeaponModel(wep, 0);

		SwitchWeapon(wep);

		Set_W_Frame (startframe, endframe, 0, 0, 0, SUB_Null, modelname, false, S_BOTH);

		self.reload_delay2 = self.fire_delay2 = self.reload_delay = self.fire_delay = 0;

		#ifndef PC
		self.Weapon_Name = GetWeaponName(self.weapon);
	    #endif

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
    {"give", Command_give, true, "Usage: give <weapon number>\n  Gives `weapon` of index.\n"}
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
	float client_parse_override = false;

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
    for (float i = 0; i < NUMBER_OF_COMMANDS; i++) {
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
#ifdef PC
	if (client_parse_override == false)
		clientcommand(self, command_string);
#endif // PC
};