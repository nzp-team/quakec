/*
	server/plugins/plugin_core.qc

	Map Vote plugin for Dedicated Servers.

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

#define PLUGIN_MAPVOTE_VOTETIMER    60

.float plugin_mapvote_voted;
float plugin_mapvote_in_progress;
string plugin_mapvote_mapchoice;

//
// ChatPlugin_MapVoteChange()
// Changes map after successful vote.
//
void() ChatPlugin_MapVoteChange =
{
    localcmd(sprintf("changelevel %s\n", plugin_mapvote_mapchoice));
};

//
// ChatPlugin_MapVotePollResults
// Called at end of voting. Changes maps if vote
// passed.
//
void() ChatPlugin_MapVotePollResults =
{
    float total_yes_votes = serverkeyfloat("mapvotes_y");
    float total_no_votes = serverkeyfloat("mapvotes_n");

    if (total_yes_votes > total_no_votes) {
        CSQC_SendChatMessage(255, sprintf("[MapVote] Vote to switch map to '%s' has PASSED.", plugin_mapvote_mapchoice));
        CSQC_SendChatMessage(255, "[MapVote] Changing maps in 15 seconds.");
        self.think = ChatPlugin_MapVoteChange;
        self.nextthink = time + 15;
    } else {
        CSQC_SendChatMessage(255, sprintf("[MapVote] Vote to switch map to '%s' has FAILED.", plugin_mapvote_mapchoice));
        plugin_mapvote_in_progress = false;
        remove(self);
    }
};

//
// ChatPlugin_MapVoteClear()
// Clears any previous Map Vote infokeys.
//
void() ChatPlugin_MapVoteClear =
{
	forceinfokey(world, "mapvotes_y", "0");
	forceinfokey(world, "mapvotes_n", "0");

    entity players = find(world, classname, "player");
    while (players != world) {
        players.plugin_mapvote_voted = false;

        players = find(players, classname, "player");
    }

    entity spectators = find(world, classname, "spectator");
    while (spectators != world) {
        spectators.plugin_mapvote_voted = false;

        spectators = find(spectators, classname, "player");
    }
};

//
// ChatPlugin_MapVoteYes()
// "mapvote_y" command, votes Yes on Map Vote.
//
float(string params) ChatPlugin_MapVoteYes =
{
    // Fail if no map vote is active.
    if (plugin_mapvote_in_progress == false) {
        CSQC_SendChatMessageToPlayer(255, "[MapVote] Cannot vote because no Map Vote is active.", self);
        return 1;
    }

    // Fail if we have already voted.
    if (self.plugin_mapvote_voted == true) {
        CSQC_SendChatMessageToPlayer(255, "[MapVote] Cannot vote because you have already voted.", self);
        return 1;
    }

    forceinfokey(world, "mapvotes_y", ftos(serverkeyfloat("mapvotes_y") + 1));
    self.plugin_mapvote_voted = true;
    CSQC_SendChatMessage(255, sprintf("[MapVote] %s voted YES to change map to '%s'", self.netname, plugin_mapvote_mapchoice));

    return 0;
};

//
// ChatPlugin_MapVoteNo()
// "mapvote_n" command, votes No on Map Vote.
//
float(string params) ChatPlugin_MapVoteNo =
{
    // Fail if no map vote is active.
    if (plugin_mapvote_in_progress == false) {
        CSQC_SendChatMessageToPlayer(255, "[MapVote] Cannot vote because no Map Vote is active.", self);
        return 1;
    }

    // Fail if we have already voted.
    if (self.plugin_mapvote_voted == true) {
        CSQC_SendChatMessageToPlayer(255, "[MapVote] Cannot vote because you have already voted.", self);
        return 1;
    }

    forceinfokey(world, "mapvotes_n", ftos(serverkeyfloat("mapvotes_n") + 1));
    self.plugin_mapvote_voted = true;
    CSQC_SendChatMessage(255, sprintf("[MapVote] %s voted NO to change map to '%s'", self.netname, plugin_mapvote_mapchoice));

    return 0;
};

//
// ChatPlugin_MapVote(params)
// "mapvote" command, initiates Map Vote.
//
float(string params) ChatPlugin_MapVote =
{
    // Fail if a map vote is already in progress.
    if (plugin_mapvote_in_progress) {
        CSQC_SendChatMessageToPlayer(255, "[MapVote] Cannot initiate a Map Vote while one is already in progress.", self);
        return 1;
    }

    // Fail if the requested map is the one currently active.
    if (mapname == params) {
        CSQC_SendChatMessageToPlayer(255, "[MapVote] Cannot vote for a map that the server is already running.", self);
        return 1;
    }

    plugin_mapvote_mapchoice = params;

    // Fail if the requested map does not exist on disk.
    float bsp = fopen(sprintf("maps/%s.bsp", plugin_mapvote_mapchoice), FILE_READ);
    if (bsp == -1) {
        CSQC_SendChatMessageToPlayer(255, sprintf("[MapVote] Could not find map '%s' on server.", plugin_mapvote_mapchoice), self);
        return 1;
    }
    fclose(bsp);

    // Reset any old votes.
    ChatPlugin_MapVoteClear();

    plugin_mapvote_in_progress = true;

    CSQC_SendChatMessage(255, sprintf("[MapVote] Begining vote for map '%s'", plugin_mapvote_mapchoice));
    CSQC_SendChatMessage(255, "Vote with 'mapvote_y' or 'mapvote_n' to switch maps.");
    CSQC_SendChatMessage(255, sprintf("Voting will end in %d seconds.", PLUGIN_MAPVOTE_VOTETIMER));

    // Spawn a temporary entity to handle polling results.
    entity tempe = spawn();
    tempe.classname = "plugin_mapvote_poller";
    tempe.think = ChatPlugin_MapVotePollResults;
    tempe.nextthink = time + PLUGIN_MAPVOTE_VOTETIMER;

    return 0;
};

#endif // FTE