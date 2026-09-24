/*
	server/tests/test_json.qc

	Unit tests for JSON configuration

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

//
// Test_JSON_BasicFunctionality()
// Tests objects, arrays, values, and comments.
//
void() Test_JSON_BasicFunctionality =
{
	float root = json_parse("{/* block */\"name\":\"nzp\",\"enabled\":true,// line\n\"values\":[1,2]}");
	Test_Assert(root != 0, "JSON failed to parse!");
	Test_Assert(Json_Type(root) == JNODE_OBJECT, "JSON root was not an object!");
	Test_Assert(Json_GetStringPath(root, "name", "") == "nzp", "JSON string value was incorrect!");
	Test_Assert(Json_GetBoolPath(root, "enabled", false), "JSON boolean value was incorrect!");
	float values = Json_GetPath(root, "values");
	Test_Assert(Json_ArrayLen(values) == 2, "JSON array length was incorrect!");
	Test_Assert(Json_AsFloat(Json_ArrayAt(values, 1), 0) == 2, "JSON array value was incorrect!");
	json_free(root);
};

//
// Test_JSON_RejectsDuplicateKeys()
// Ensures ambiguous objects do not load.
//
void() Test_JSON_RejectsDuplicateKeys =
{
	float root = json_parse("{\"value\":1,\"value\":2}");
	Test_Assert(root == 0, "JSON accepted a duplicate key!");
	Test_Assert(json_get_error_code() != 0, "JSON did not report a parse error!");
	Test_Assert(json_get_error() == "Duplicate JSON key: value", "JSON reported the wrong duplicate key!");
	json_free(root);
};

//
// Test_JSON_OverlayKeepsEarlierValues()
// Ensures a sparse overlay only replaces values it supplies.
//
void() Test_JSON_OverlayKeepsEarlierValues =
{
	float old_health = game_modifiers.gameplay.player.start_health;
	float old_melee = game_modifiers.gameplay.player.can_use_melee;
	float old_round_delay = game_modifiers.gameplay.rounds.delay_between_rounds;
	float root = json_parse("{\"gameplay\":{\"player\":{\"start_health\":175}}}");

	Test_Assert(root != 0, "JSON overlay failed to parse!");
	if (root && Modifiers_Validate(root))
		Modifiers_ApplyValues(root, false);
	else
		Test_Assert(false, "JSON overlay failed validation!");

	Test_Assert(game_modifiers.gameplay.player.start_health == 175, "JSON overlay did not replace its value!");
	Test_Assert(game_modifiers.gameplay.player.can_use_melee == old_melee, "JSON overlay replaced an omitted player value!");
	Test_Assert(game_modifiers.gameplay.rounds.delay_between_rounds == old_round_delay, "JSON overlay replaced an omitted round value!");

	game_modifiers.gameplay.player.start_health = old_health;
	game_modifiers.gameplay.player.can_use_melee = old_melee;
	game_modifiers.gameplay.rounds.delay_between_rounds = old_round_delay;
	json_free(root);
};

//
// Test_JSON_InvalidOverlayDoesNotApply()
// Ensures invalid configuration is rejected before it changes gameplay.
//
void() Test_JSON_InvalidOverlayDoesNotApply =
{
	float old_health = game_modifiers.gameplay.player.start_health;
	string old_error = json_error_msg;
	float root = json_parse("{\"gameplay\":{\"player\":{\"start_health\":\"lots\"}}}");

	Test_Assert(root != 0, "Invalid JSON overlay failed to parse!");
	Test_Assert(!Modifiers_Validate(root), "Invalid JSON overlay passed validation!");
	Test_Assert(game_modifiers.gameplay.player.start_health == old_health, "Invalid JSON overlay changed gameplay!");
	json_error_msg = old_error;
	json_free(root);
};