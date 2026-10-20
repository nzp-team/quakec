/*
	server/tests/test_player_controls.qc

	Tests for per-player map controls and contact dispatch

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

float(float condition, string message) Test_Assert;

void() EachPlayer_TestTarget =
{
	activator.count++;
};

entity() Test_MapControlPlayer =
{
	entity client = spawn();
	client.classname = "player";
	client.health = 100;
	client.movetype = MOVETYPE_WALK;
	return client;
};

void() Test_EachPlayer_IndependentContacts =
{
	entity old_self = self;
	entity old_other = other;
	entity old_activator = activator;
	entity first = Test_MapControlPlayer();
	entity second = Test_MapControlPlayer();
	entity receiver = spawn();
	receiver.targetname = "test_eachplayer_contacts";
	receiver.use = EachPlayer_TestTarget;
	self = spawn();
	self.classname = "trigger_eachplayer";
	self.target = receiver.targetname;
	trigger_eachplayer();
	other = first;
	eachplayer_touch();
	eachplayer_touch();
	other = second;
	eachplayer_touch();
	Test_Assert((first.count == 1 && second.count == 1), "One player's cooldown blocked another player or allowed a repeat!");
	Test_Assert((activator == old_activator), "Contact dispatch leaked the activator!");

	// A second brush must not share the first brush's player cooldowns.
	entity first_trigger = self;
	self = spawn();
	self.classname = "trigger_eachplayer";
	self.target = receiver.targetname;
	trigger_eachplayer();
	other = first;
	eachplayer_touch();
	Test_Assert((first.count == 2), "Overlapping brushes shared a player cooldown!");
	self.eachplayer_contacts.ltime = time;
	eachplayer_touch();
	Test_Assert((first.count == 3), "Expired per-player cooldown did not fire again!");
	EachPlayer_ClearContacts(self, world);
	remove(self);
	EachPlayer_ClearContacts(first_trigger, world);
	remove(first_trigger);
	remove(receiver);
	remove(first);
	remove(second);
	self = old_self;
	other = old_other;
	activator = old_activator;
};

void() Test_EachPlayer_StateAndOnce =
{
	entity old_self = self;
	entity old_other = other;
	float old_state = global_triggerstate;
	float old_retouch = force_retouch;
	entity client = Test_MapControlPlayer();
	entity receiver = spawn();
	receiver.targetname = "test_eachplayer_once";
	receiver.use = EachPlayer_TestTarget;
	self = spawn();
	self.classname = "trigger_eachplayer";
	self.target = receiver.targetname;
	self.spawnflags = SPAWNFLAG_EACHPLAYER_STARTOFF;
	self.wait = -1;
	trigger_eachplayer();
	other = client;
	eachplayer_touch();
	Test_Assert((self.touch == SUB_Null && !self.eachplayer_contacts), "Start disabled brush accepted a contact!");
	global_triggerstate = TRIGGERSTATE_ON;
	eachplayer_use();
	Test_Assert((self.touch == eachplayer_touch && force_retouch == 2), "Enable failed to retouch existing occupants!");
	eachplayer_touch();
	entity contact = self.eachplayer_contacts;
	global_triggerstate = TRIGGERSTATE_ON;
	eachplayer_use();
	eachplayer_touch();
	Test_Assert((self.eachplayer_contacts == contact && contact.enemy == world), "Repeated On reset once-per-player state!");
	Test_Assert((client.count == 1), "Once-per-player fired more than once!");
	global_triggerstate = TRIGGERSTATE_OFF;
	eachplayer_use();
	Test_Assert((!self.eachplayer_contacts && self.touch == SUB_Null), "Disable left contacts active!");
	global_triggerstate = TRIGGERSTATE_TOGGLE;
	eachplayer_use();
	eachplayer_touch();
	Test_Assert((self.eachplayer_contacts.owner == client), "Re-enable did not accept the existing player!");
	Test_Assert((client.count == 2), "Re-enable did not rearm once-per-player targets!");
	eachplayer_use();
	Test_Assert((self.touch == SUB_Null && !self.eachplayer_contacts), "Toggle did not disable and clear contacts!");
	remove(client);
	remove(receiver);
	remove(self);
	self = old_self;
	other = old_other;
	global_triggerstate = old_state;
	force_retouch = old_retouch;
};

void() Test_PlayerControls_ActivatorAndStates =
{
	entity old_self = self;
	entity old_activator = activator;
	float old_state = global_triggerstate;
	entity first = Test_MapControlPlayer();
	entity second = Test_MapControlPlayer();
	self = spawn();
	game_freezeplayer();
	activator = first;
	global_triggerstate = TRIGGERSTATE_ON;
	self.use();
	Test_Assert(((first.map_control_flags & PLAYER_CONTROL_FROZEN) && !(first.map_control_flags & PLAYER_CONTROL_LOCKLOOK) && !(second.map_control_flags & PLAYER_CONTROL_FROZEN)), "Freeze was not isolated to the activator!");
	self.spawnflags = SPAWNFLAG_FREEZEPLAYER_LOCKLOOK;
	first.v_angle = '10 90 0';
	self.use();
	Test_Assert(((first.map_control_flags & PLAYER_CONTROL_LOCKLOOK) && first.map_lockangles == first.v_angle), "Lock-look did not capture the player's view!");
	first.v_angle = '30 180 0';
	self.use();
	Test_Assert((first.map_lockangles == '10 90 0'), "Repeated On changed the locked view!");
	global_triggerstate = TRIGGERSTATE_OFF;
	self.use();
	Test_Assert((!(first.map_control_flags & PLAYER_CONTROL_FROZEN) && !(first.map_control_flags & PLAYER_CONTROL_LOCKLOOK)), "Unfreeze left a movement or view lock!");
	global_triggerstate = TRIGGERSTATE_TOGGLE;
	self.use();
	Test_Assert((first.map_control_flags & PLAYER_CONTROL_FROZEN), "Toggle did not freeze!");
	self.use();
	Test_Assert((!(first.map_control_flags & PLAYER_CONTROL_FROZEN)), "Toggle did not unfreeze!");

	game_togglehud();
	global_triggerstate = TRIGGERSTATE_ON;
	self.use();
	self.use();
	Test_Assert(((first.map_control_flags & PLAYER_CONTROL_HIDEHUD) && !(second.map_control_flags & PLAYER_CONTROL_HIDEHUD)), "HUD On toggled or affected another player!");
	game_freezeplayer();
	self.use();
	global_triggerstate = TRIGGERSTATE_OFF;
	self.use();
	Test_Assert((first.map_control_flags == PLAYER_CONTROL_HIDEHUD), "Unfreezing changed the HUD state!");
	game_togglehud();
	self.use();
	Test_Assert((!(first.map_control_flags & PLAYER_CONTROL_HIDEHUD)), "HUD Off did not restore the HUD!");
	global_triggerstate = TRIGGERSTATE_TOGGLE;
	self.use();
	self.use();
	Test_Assert((!(first.map_control_flags & PLAYER_CONTROL_HIDEHUD)), "HUD toggle did not restore the HUD!");
	activator = second;
	second.downed = true;
	self.use();
	Test_Assert((!(second.map_control_flags & PLAYER_CONTROL_HIDEHUD)), "Downed player accepted cinematic control!");
	activator = world;
	self.use();
	Test_Assert((!(world.map_control_flags & PLAYER_CONTROL_HIDEHUD)), "Non-player activation changed the world!");
	remove(self);
	remove(second);
	remove(first);
	self = old_self;
	activator = old_activator;
	global_triggerstate = old_state;
};

void() Test_PlayerControls_PhysicsAndCleanup =
{
	entity old_self = self;
	entity old_other = other;
	entity client = Test_MapControlPlayer();
	client.map_control_flags = PLAYER_CONTROL_FROZEN | PLAYER_CONTROL_LOCKLOOK | PLAYER_CONTROL_HIDEHUD;
	client.map_lockangles = '10 90 0';
	client.v_angle = '30 180 0';
	client.velocity = '80 -40 120';
	self = client;
	Player_ApplyMapControls();
	Test_Assert((client.velocity == '80 -40 120' && client.movetype == MOVETYPE_WALK), "Freeze discarded external velocity or disabled physics!");
	Test_Assert((client.v_angle == '10 90 0' && client.fixangle), "Look lock did not enforce the captured view!");
	Test_Assert((client.maxspeed == 0), "Freeze retained player movement speed!");
	client.flags = FL_ONGROUND | FL_JUMPRELEASED;
	client.button2 = true;
	PlayerJump();
	Test_Assert((client.velocity_z == 120), "Frozen player could jump!");
	Player_MapControlsEndFrame();
	Test_Assert((client.map_saved_movetype && client.movetype == MOVETYPE_NONE), "User command processing was not gated!");
	Player_MapControlsStartFrame();
	Test_Assert((!client.map_saved_movetype && client.movetype == MOVETYPE_WALK), "Movement was not restored before physics!");
	self = spawn();
	self.classname = "trigger_eachplayer";
	trigger_eachplayer();
	other = client;
	eachplayer_touch();
	Test_Assert((self.eachplayer_contacts.owner == client), "Cleanup fixture has no player contact!");
	client.angles = '0 180 0';
	client.fixangle = true;
	Player_MapControlsEndFrame();
	Test_Assert((client.map_lockangles == '0 180 0'), "Look lock lost a scripted teleport direction!");
	Player_ClearMapControls(client);
	Test_Assert((!client.map_control_flags && !client.map_saved_movetype), "Lifecycle cleanup left map-owned controls!");
	Test_Assert((!self.eachplayer_contacts), "Lifecycle cleanup left a reused player slot on cooldown!");
	Test_Assert((client.velocity == '80 -40 120' && client.movetype == MOVETYPE_WALK), "Cleanup discarded external movement!");
	remove(self);
	remove(client);
	self = old_self;
	other = old_other;
};
