/*
	client/chat.qc

	Chat interception and custom drawing, based on Nuclide.

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

var float autocvar_cg_chatEnabled = true;

#define CHAT_LINES 10
#define CHAT_TIME 7

var int g_chatpos[2];
var float g_chattime;
var int g_chatlines = -1;
string g_chatbuffer[CHAT_LINES];
string g_chatbuffer_final;

/*
 * called every frame pretty much and prints whatever is in the chatbuffer.
 * removes lines after some time, one at a time.
 */
void Chat_Draw()
{
	int i;

	if (autocvar_cg_chatEnabled == false)
	 	return;

	g_chatpos[0] = GetUltraWideOffset() + 5;
	g_chatpos[1] = 170;

	if (g_chatlines < 0) {
		return;
	}

	/* remove messages after a g_chattime has passed */
	if (g_chattime < time) {
        g_chatbuffer_final = "";
		for (i = 0; i < g_chatlines; i++) {
			if (g_chatbuffer[i+1] != __NULL__) {
				g_chatbuffer[i] = g_chatbuffer[i+1];
			}
            if (i == 0)
			    g_chatbuffer_final = g_chatbuffer[i];
		    else
			    g_chatbuffer_final = sprintf("%s\n%s", g_chatbuffer_final, g_chatbuffer[i]);
		}
		g_chatbuffer[g_chatlines] = __NULL__;
		g_chatlines--;
		g_chattime = time + CHAT_TIME;
	}

    int barlines = 0;
    for(i = 0; i <= g_chatlines; i++) {
        if (g_chatbuffer[i] == __NULL__)
            continue;

        if (strlen(g_chatbuffer[i]) > 48) {
            barlines += strlen(g_chatbuffer[i])/48 + 2;
        } else {
            barlines++;
        }
    }

    drawfill ([g_chatpos[0] - 2, g_chatpos[1] - 2], [290, (barlines) * 8 + 4], [0, 0, 0], 0.65, 0);
    drawtextfield([g_chatpos[0], g_chatpos[1]], [290, 280], 1 | 2, g_chatbuffer_final);
}

//
// Chat_GetHexCodeForPlayer(player_id)
// Returns a hex string for the Player Name color
//
string Chat_GetHexCodeForPlayer(float player_id)
{
    switch(player_id) {
        case 1: return "^xFFF";
        case 2: return "^x07E";
        case 3: return "^xCA0";
        case 4: return "^x5D0";
		case 255: return "^xF76";
    }
    return "^xFFF";
}

//
// Chat_Register(sender, player_id, message)
// Adds the chat message to the chat struct to be
// drawn.
//
void Chat_Register(int sender, int player_id, string message)
{
    // Append name+color to the message
    string player_hex = Chat_GetHexCodeForPlayer(player_id);
    string player_name = getplayerkeyvalue(sender, "name");

	// Not a server message.
	if (player_id != 255) {
		message = strcat(player_hex, player_name, "^xCCC: ", message);
	} else {
		message = strcat(player_hex, message);
	}
    

	if (g_chatlines < (CHAT_LINES - 1)) {
		g_chatbuffer[g_chatlines + 1] = message;
		g_chatlines++;
	} else {
		for (int i = 0; i < (CHAT_LINES - 1); i++) {
			g_chatbuffer[i] = g_chatbuffer[i + 1];
		}
		g_chatbuffer[CHAT_LINES - 1] = message;
	}

	g_chattime = time + CHAT_TIME;

	/* we need to be silent */
	if (autocvar_cg_chatEnabled == false)
	 	return;

	localsound("sounds/misc/talk2.wav");

	g_chatbuffer_final = "";

	for (int i = 0; i < CHAT_LINES; i++) {
		if (i == 0)
			g_chatbuffer_final = g_chatbuffer[i];
		else
			g_chatbuffer_final = sprintf("%s\n%s", g_chatbuffer_final, g_chatbuffer[i]);
	}
}