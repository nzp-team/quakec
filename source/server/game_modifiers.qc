/*
	server/game_modifiers.qc

	Gameplay configuration loading and overrides.

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

float modifier_weapon_upgrade_overridden;

//
// Modifiers_CheckValue(root, path, type, minimum, maximum)
// Validate a layer before changing any gameplay values. Missing keys
// inherit the earlier layer; null and wrong types are configuration errors.
//
float(float root, string path, float type, float minimum, float maximum) Modifiers_CheckValue =
{
    float node = Json_GetPath(root, path);
    if (!node) return true;
    if (!Json_IsType(node, type)) {
        Json_Fail(strcat("Wrong type for ", path));
        return false;
    }
    if (type == JNODE_STRING && strstrofs(path, ".toast", 0) < 0 && strlen(Json_AsString(node, "")) > 63) {
        Json_Fail(strcat("Asset path or setting exceeds 63 bytes: ", path));
        return false;
    }
    float number = Json_AsFloat(node, 0);
    if (type == JNODE_NUMBER && (!(number >= minimum) || !(number <= maximum))) {
        Json_Fail(strcat("Value out of range for ", path));
        return false;
    }
    return true;
};

float(float root, string path, float capacity) Modifiers_CheckArray =
{
    float node = Json_GetPath(root, path);
    if (!node) return true;
    if (Json_Type(node) != JNODE_ARRAY || Json_ArrayLen(node) > capacity) {
        Json_Fail(strcat("Invalid array size or type for ", path));
        return false;
    }
    for (float i = 0; i < Json_ArrayLen(node); i++) {
        float child = Json_ArrayAt(node, i);
        string value = Json_AsString(child, "");
        if (Json_Type(child) != JNODE_STRING || (value == "" && strstrofs(path, "interface.", 0) != 0) || strlen(value) > 63) {
            Json_Fail(strcat("Invalid string entry in ", path));
            return false;
        }
    }
    return true;
};

float(float root, string path) Modifiers_CheckColor =
{
    float node = Json_GetPath(root, path);
    if (!node) return true;
    if (Json_Type(node) != JNODE_ARRAY || Json_ArrayLen(node) != 3) {
        Json_Fail(strcat("Invalid RGB color for ", path));
        return false;
    }
    for (float i = 0; i < Json_ArrayLen(node); i++) {
        float child = Json_ArrayAt(node, i);
        float value = Json_AsFloat(child, -1);
        if (Json_Type(child) != JNODE_NUMBER || value < 0 || value > 255) {
            Json_Fail(strcat("Invalid RGB color for ", path));
            return false;
        }
    }
    return true;
};

vector(float root, string path, vector fallback) Modifiers_ReadColor =
{
    float node = Json_GetPath(root, path);
    if (!node) return fallback;
    return [
        Json_AsFloat(Json_ArrayAt(node, 0), fallback[0]),
        Json_AsFloat(Json_ArrayAt(node, 1), fallback[1]),
        Json_AsFloat(Json_ArrayAt(node, 2), fallback[2])
    ];
};

//
// Modifiers_ReadString(root, path, current, initialize, fallback)
// Parser strings are released after each file. Gameplay keeps its own copy.
//
string(float root, string path, string current, float initialize, string fallback) Modifiers_ReadString =
{
    float node = Json_GetPath(root, path);
    string value, owned;
    if (!initialize && !node) return current;
    value = Json_AsString(node, fallback);
    owned = "";
    if (value != "") owned = strzone(value);
    if (current != "") strunzone(current);
    return owned;
};

float(float root, string path, float capacity) Modifiers_CheckSoundArray =
{
    float node = Json_GetPath(root, path);
    if (!node) return true;
    if (Json_Type(node) == JNODE_STRING)
        return Modifiers_CheckValue(root, path, JNODE_STRING, 0, 0);
    return Modifiers_CheckArray(root, path, capacity);
};

string(float node, float index) Modifiers_ArrayString =
{
    if (node && Json_Type(node) == JNODE_STRING) {
        if (index == 0) return Json_AsString(node, "");
        return "";
    }
    return Json_ArrayStringAt(node, index, "");
};

float(float root) Modifiers_Validate =
{
    if (Json_Type(root) != JNODE_OBJECT) {
        Json_Fail("Configuration root must be an object");
        return false;
    }

    // Reject malformed sections as well as malformed leaves.
    if (!Modifiers_CheckValue(root, "gameplay.rounds", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.rounds.sounds", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.equipment", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.equipment.graphics", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.powerups", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.powerups.graphics", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.rounds", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.rounds.graphics", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.score", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.score.graphics", JNODE_OBJECT, 0, 0)) return false;

    if (!Modifiers_CheckValue(root, "gameplay", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.ai", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.ai.zombie", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.ai.zombie.sounds", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.ai.zombie.walk_styles", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.global", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.packapunch", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.perksacola", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.player", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.player.health_regeneration", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade", JNODE_OBJECT, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.powerups.sounds", JNODE_OBJECT, 0, 0)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.global.all_items_cost_multiplier", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_purchase_limit", JNODE_NUMBER, 0, 8)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_quickrevive_health_regeneration_multiplier", JNODE_NUMBER, 0.001, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_juggernog_player_health", JNODE_NUMBER, 0.001, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_speedcola_accelerates_barricade_repair", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_speedcola_reload_speed_multiplier", JNODE_NUMBER, 0.001, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_doubletap_rate_of_fire_multiplier", JNODE_NUMBER, 0.001, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_doubletap_rechamber_speed_multiplier", JNODE_NUMBER, 0.001, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_staminup_movement_speed_multiplier", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_staminup_stamina_recharge_multiplier", JNODE_NUMBER, 0.001, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_deadshot_headshot_damage_multiplier", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.perksacola.perk_deadshot_weapon_spread_reduction_multiplier", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.packapunch.packapunch_supports_upgrade_tiers", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.packapunch.packapunch_upgrades_instantly", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.max_powerups_per_round", JNODE_NUMBER, 0, 64)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_spawn_frequency_multiplier", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.sounds.pick_up", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.sounds.idle", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.sounds.drop", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo.enabled", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo.chance_to_allow_in_rotation", JNODE_NUMBER, 0, 1)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo.disabled_before_round", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo.fills_magazine", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo.toast", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo.show_toast", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo.model", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_max_ammo.voiceover", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill.enabled", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill.chance_to_allow_in_rotation", JNODE_NUMBER, 0, 1)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill.disabled_before_round", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill.duration", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill.toast", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill.show_toast", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill.model", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_instakill.voiceover", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.enabled", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.chance_to_allow_in_rotation", JNODE_NUMBER, 0, 1)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.disabled_before_round", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.duration", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.score_multiplier", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.toast", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.show_toast", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.model", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_double_points.voiceover", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.enabled", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.chance_to_allow_in_rotation", JNODE_NUMBER, 0, 1)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.disabled_before_round", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.destroyed_barricade_requirement", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.score_awarded", JNODE_NUMBER, -1000000, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.toast", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.show_toast", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.model", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_carpenter.voiceover", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.enabled", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.chance_to_allow_in_rotation", JNODE_NUMBER, 0, 1)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.disabled_before_round", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.score_awarded", JNODE_NUMBER, -1000000, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.toast", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.show_toast", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.model", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.voiceover", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_nuke.explosion_sfx", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk.enabled", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk.chance_to_allow_in_rotation", JNODE_NUMBER, 0, 1)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk.disabled_before_round", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk.awarded_score_if_no_perk_obtained", JNODE_NUMBER, -1000000, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk.toast", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk.show_toast", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk.model", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_free_perk.voiceover", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points.enabled", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points.chance_to_allow_in_rotation", JNODE_NUMBER, 0, 1)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points.disabled_before_round", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points.score_awarded", JNODE_NUMBER, -1000000, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points.toast", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points.show_toast", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points.model", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_bonus_points.voiceover", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade.enabled", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade.chance_to_allow_in_rotation", JNODE_NUMBER, 0, 1)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade.disabled_before_round", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade.awarded_score_if_no_upgrade_received", JNODE_NUMBER, -1000000, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade.toast", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade.show_toast", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade.model", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.powerups.powerup_weapon_upgrade.voiceover", JNODE_STRING, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.ai.zombie.walk_styles.can_walk", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.ai.zombie.walk_styles.can_jog", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.ai.zombie.walk_styles.can_sprint", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.ai.zombie.walk_styles.can_super_sprint", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckArray(root, "gameplay.powerups.powerup_free_perk.allowed_perksacola", 8)) return false;
	if (!Modifiers_CheckArray(root, "gameplay.ai.zombie.sounds.attack", 12)) return false;
	if (!Modifiers_CheckArray(root, "gameplay.ai.zombie.sounds.death", 12)) return false;
	if (!Modifiers_CheckArray(root, "gameplay.ai.zombie.sounds.shout", 12)) return false;
	if (!Modifiers_CheckArray(root, "gameplay.ai.zombie.sounds.taunt", 12)) return false;
	if (!Modifiers_CheckArray(root, "gameplay.ai.zombie.sounds.groan", 12)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.ai.score_system", JNODE_STRING, 0, 0)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.ai.round_health_cap", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.player.start_health", JNODE_NUMBER, 0.001, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.player.can_earn_points_in_last_stand", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.player.can_use_melee", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.player.can_use_equipment", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.player.can_earn_score_from_sources_other_than_ai", JNODE_BOOL, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.player.health_regeneration.regeneration_multiplier", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.player.health_regeneration.regeneration_delay_light_damage", JNODE_NUMBER, 0, 1000000)) return false;
	if (!Modifiers_CheckValue(root, "gameplay.player.health_regeneration.regeneration_delay_heavy_damage", JNODE_NUMBER, 0, 1000000)) return false;
	string score_system = Json_GetStringPath(root, "gameplay.ai.score_system", "default");
	if (score_system != "default" && score_system != "cw" && score_system != "bo4") {
		Json_Fail("AI score_system must be default, cw, or bo4");
		return false;
	}
    if (!Modifiers_CheckValue(root, "gameplay.rounds.delay_between_rounds", JNODE_NUMBER, 0, 1000000)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.rounds.ai_spawn_delay_reduction_multiplier", JNODE_NUMBER, 0, 1000000)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.rounds.sounds.game_start", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckSoundArray(root, "gameplay.rounds.sounds.new_round", 4)) return false;
    if (!Modifiers_CheckSoundArray(root, "gameplay.rounds.sounds.end_round", 4)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.rounds.sounds.new_hound_round", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.rounds.sounds.end_hound_round", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckSoundArray(root, "gameplay.rounds.sounds.hound_round_taunts", 4)) return false;
    if (!Modifiers_CheckValue(root, "gameplay.rounds.sounds.game_over", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.position_style", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.quickrevive", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.juggernog", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.speedcola", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.doubletap", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.doubletap_2", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.staminup", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.flopper", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.deadshot", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.graphics.mulekick", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.powerups.graphics.insta_kill", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.powerups.graphics.double_points", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.rounds.position_style", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.rounds.skip_intro", JNODE_BOOL, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.rounds.use_tally_marks_until_round", JNODE_NUMBER, 0, 1000000)) return false;
    if (!Modifiers_CheckColor(root, "interface.rounds.color")) return false;
    if (!Modifiers_CheckArray(root, "interface.rounds.graphics.tally_marks", 5)) return false;
    if (!Modifiers_CheckArray(root, "interface.rounds.graphics.numeric", 10)) return false;
    if (!Modifiers_CheckValue(root, "interface.equipment.graphics.grenade", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.equipment.graphics.bouncing_betty", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.score.graphics.score_background_full", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.score.graphics.score_background_condensed", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.perksacola.position_style", JNODE_STRING, 0, 0)) return false;
    if (!Modifiers_CheckValue(root, "interface.score.position_style", JNODE_STRING, 0, 0)) return false;
    string round_style = Json_GetStringPath(root, "interface.rounds.position_style", "bottom_left");
    if (round_style != "bottom_left" && round_style != "top_right") {
        Json_Fail("Round position_style must be bottom_left or top_right");
        return false;
    }
    if (!Json_GetBoolPath(root, "gameplay.ai.zombie.walk_styles.can_walk", game_modifiers.gameplay.ai.zombie.walk_styles.can_walk) &&
        !Json_GetBoolPath(root, "gameplay.ai.zombie.walk_styles.can_jog", game_modifiers.gameplay.ai.zombie.walk_styles.can_jog) &&
        !Json_GetBoolPath(root, "gameplay.ai.zombie.walk_styles.can_sprint", game_modifiers.gameplay.ai.zombie.walk_styles.can_sprint) &&
        !Json_GetBoolPath(root, "gameplay.ai.zombie.walk_styles.can_super_sprint", game_modifiers.gameplay.ai.zombie.walk_styles.can_super_sprint)) {
        Json_Fail("At least one zombie walk style must be enabled");
        return false;
    }
    return true;
};

//
// Modifiers_ApplyValues(config_root, initialize)
// Only initialize uses compiled fallbacks. Later layers retain the current
// value for omitted keys, including values set by the game mode.
// Supplied arrays replace the whole list, so shorter lists clear the old tail.
//
void(float config_root, float initialize) Modifiers_ApplyValues =
{
    float array_root;
    // MARK: Global
    game_modifiers.gameplay.global.all_items_cost_multiplier = Json_GetFloatPath(config_root, "gameplay.global.all_items_cost_multiplier", initialize ? 1 : game_modifiers.gameplay.global.all_items_cost_multiplier);

    // MARK: Perk-A-Cola
    game_modifiers.gameplay.perksacola.perk_purchase_limit = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_purchase_limit", initialize ? 8 : game_modifiers.gameplay.perksacola.perk_purchase_limit);
    game_modifiers.gameplay.perksacola.perk_quickrevive_health_regeneration_multiplier = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_quickrevive_health_regeneration_multiplier", initialize ? 1 : game_modifiers.gameplay.perksacola.perk_quickrevive_health_regeneration_multiplier);
    game_modifiers.gameplay.perksacola.perk_juggernog_player_health = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_juggernog_player_health", initialize ? 160 : game_modifiers.gameplay.perksacola.perk_juggernog_player_health);
    game_modifiers.gameplay.perksacola.perk_speedcola_accelerates_barricade_repair = Json_GetBoolPath(config_root, "gameplay.perksacola.perk_speedcola_accelerates_barricade_repair", initialize ? true : game_modifiers.gameplay.perksacola.perk_speedcola_accelerates_barricade_repair);
    game_modifiers.gameplay.perksacola.perk_speedcola_reload_speed_multiplier = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_speedcola_reload_speed_multiplier", initialize ? 2 : game_modifiers.gameplay.perksacola.perk_speedcola_reload_speed_multiplier);
    game_modifiers.gameplay.perksacola.perk_doubletap_rate_of_fire_multiplier = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_doubletap_rate_of_fire_multiplier", initialize ? 1.298 : game_modifiers.gameplay.perksacola.perk_doubletap_rate_of_fire_multiplier);
    game_modifiers.gameplay.perksacola.perk_doubletap_rechamber_speed_multiplier = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_doubletap_rechamber_speed_multiplier", initialize ? 1.5 : game_modifiers.gameplay.perksacola.perk_doubletap_rechamber_speed_multiplier);
    game_modifiers.gameplay.perksacola.perk_staminup_movement_speed_multiplier = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_staminup_movement_speed_multiplier", initialize ? 1.07 : game_modifiers.gameplay.perksacola.perk_staminup_movement_speed_multiplier);
    game_modifiers.gameplay.perksacola.perk_staminup_stamina_recharge_multiplier = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_staminup_stamina_recharge_multiplier", initialize ? 2 : game_modifiers.gameplay.perksacola.perk_staminup_stamina_recharge_multiplier);
    game_modifiers.gameplay.perksacola.perk_deadshot_headshot_damage_multiplier = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_deadshot_headshot_damage_multiplier", initialize ? 1 : game_modifiers.gameplay.perksacola.perk_deadshot_headshot_damage_multiplier);
    game_modifiers.gameplay.perksacola.perk_deadshot_weapon_spread_reduction_multiplier = Json_GetFloatPath(config_root, "gameplay.perksacola.perk_deadshot_weapon_spread_reduction_multiplier", initialize ? 0.65 : game_modifiers.gameplay.perksacola.perk_deadshot_weapon_spread_reduction_multiplier);

    // MARK: Pack-A-Punch
    game_modifiers.gameplay.packapunch.packapunch_supports_upgrade_tiers = Json_GetBoolPath(config_root, "gameplay.packapunch.packapunch_supports_upgrade_tiers", initialize ? false : game_modifiers.gameplay.packapunch.packapunch_supports_upgrade_tiers);
    game_modifiers.gameplay.packapunch.packapunch_upgrades_instantly = Json_GetBoolPath(config_root, "gameplay.packapunch.packapunch_upgrades_instantly", initialize ? false : game_modifiers.gameplay.packapunch.packapunch_upgrades_instantly);

    // MARK: Power-Ups
    game_modifiers.gameplay.powerups.max_powerups_per_round = Json_GetFloatPath(config_root, "gameplay.powerups.max_powerups_per_round", initialize ? 4 : game_modifiers.gameplay.powerups.max_powerups_per_round);
    game_modifiers.gameplay.powerups.powerup_spawn_frequency_multiplier = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_spawn_frequency_multiplier", initialize ? 1 : game_modifiers.gameplay.powerups.powerup_spawn_frequency_multiplier);
    game_modifiers.gameplay.powerups.sounds.pick_up = Modifiers_ReadString(config_root, "gameplay.powerups.sounds.pick_up", game_modifiers.gameplay.powerups.sounds.pick_up, initialize, "sounds/pu/pickup.wav");
    game_modifiers.gameplay.powerups.sounds.idle = Modifiers_ReadString(config_root, "gameplay.powerups.sounds.idle", game_modifiers.gameplay.powerups.sounds.idle, initialize, "sounds/pu/powerup.wav");
    game_modifiers.gameplay.powerups.sounds.drop = Modifiers_ReadString(config_root, "gameplay.powerups.sounds.drop", game_modifiers.gameplay.powerups.sounds.drop, initialize, "sounds/pu/drop.wav");

    // MARK: Max Ammo Power-Up
    game_modifiers.gameplay.powerups.powerup_max_ammo.enabled = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_max_ammo.enabled", initialize ? true : game_modifiers.gameplay.powerups.powerup_max_ammo.enabled);
    game_modifiers.gameplay.powerups.powerup_max_ammo.chance_to_allow_in_rotation = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_max_ammo.chance_to_allow_in_rotation", initialize ? 1 : game_modifiers.gameplay.powerups.powerup_max_ammo.chance_to_allow_in_rotation);
    game_modifiers.gameplay.powerups.powerup_max_ammo.disabled_before_round = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_max_ammo.disabled_before_round", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_max_ammo.disabled_before_round);
    game_modifiers.gameplay.powerups.powerup_max_ammo.fills_magazine = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_max_ammo.fills_magazine", initialize ? false : game_modifiers.gameplay.powerups.powerup_max_ammo.fills_magazine);
    game_modifiers.gameplay.powerups.powerup_max_ammo.toast = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_max_ammo.toast", game_modifiers.gameplay.powerups.powerup_max_ammo.toast, initialize, "Max Ammo!");
    game_modifiers.gameplay.powerups.powerup_max_ammo.show_toast = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_max_ammo.show_toast", initialize ? true : game_modifiers.gameplay.powerups.powerup_max_ammo.show_toast);
    game_modifiers.gameplay.powerups.powerup_max_ammo.model = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_max_ammo.model", game_modifiers.gameplay.powerups.powerup_max_ammo.model, initialize, "models/pu/maxammo!.mdl");
    game_modifiers.gameplay.powerups.powerup_max_ammo.voiceover = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_max_ammo.voiceover", game_modifiers.gameplay.powerups.powerup_max_ammo.voiceover, initialize, "sounds/pu/maxammo.wav");

    // MARK: Insta-Kill Power-Up
    game_modifiers.gameplay.powerups.powerup_instakill.enabled = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_instakill.enabled", initialize ? true : game_modifiers.gameplay.powerups.powerup_instakill.enabled);
    game_modifiers.gameplay.powerups.powerup_instakill.chance_to_allow_in_rotation = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_instakill.chance_to_allow_in_rotation", initialize ? 1 : game_modifiers.gameplay.powerups.powerup_instakill.chance_to_allow_in_rotation);
    game_modifiers.gameplay.powerups.powerup_instakill.disabled_before_round = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_instakill.disabled_before_round", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_instakill.disabled_before_round);
    game_modifiers.gameplay.powerups.powerup_instakill.duration = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_instakill.duration", initialize ? 30 : game_modifiers.gameplay.powerups.powerup_instakill.duration);
    game_modifiers.gameplay.powerups.powerup_instakill.toast = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_instakill.toast", game_modifiers.gameplay.powerups.powerup_instakill.toast, initialize, "Insta-Kill!");
    game_modifiers.gameplay.powerups.powerup_instakill.show_toast = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_instakill.show_toast", initialize ? false : game_modifiers.gameplay.powerups.powerup_instakill.show_toast);
    game_modifiers.gameplay.powerups.powerup_instakill.model = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_instakill.model", game_modifiers.gameplay.powerups.powerup_instakill.model, initialize, "models/pu/instakill!.mdl");
    game_modifiers.gameplay.powerups.powerup_instakill.voiceover = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_instakill.voiceover", game_modifiers.gameplay.powerups.powerup_instakill.voiceover, initialize, "sounds/pu/insta_kill.wav");

    // MARK: Double Points Power-Up
    game_modifiers.gameplay.powerups.powerup_double_points.enabled = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_double_points.enabled", initialize ? true : game_modifiers.gameplay.powerups.powerup_double_points.enabled);
    game_modifiers.gameplay.powerups.powerup_double_points.chance_to_allow_in_rotation = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_double_points.chance_to_allow_in_rotation", initialize ? 1 : game_modifiers.gameplay.powerups.powerup_double_points.chance_to_allow_in_rotation);
    game_modifiers.gameplay.powerups.powerup_double_points.disabled_before_round = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_double_points.disabled_before_round", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_double_points.disabled_before_round);
    game_modifiers.gameplay.powerups.powerup_double_points.duration = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_double_points.duration", initialize ? 30 : game_modifiers.gameplay.powerups.powerup_double_points.duration);
    game_modifiers.gameplay.powerups.powerup_double_points.score_multiplier = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_double_points.score_multiplier", initialize ? 2 : game_modifiers.gameplay.powerups.powerup_double_points.score_multiplier);
    game_modifiers.gameplay.powerups.powerup_double_points.toast = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_double_points.toast", game_modifiers.gameplay.powerups.powerup_double_points.toast, initialize, "Double Points!");
    game_modifiers.gameplay.powerups.powerup_double_points.show_toast = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_double_points.show_toast", initialize ? false : game_modifiers.gameplay.powerups.powerup_double_points.show_toast);
    game_modifiers.gameplay.powerups.powerup_double_points.model = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_double_points.model", game_modifiers.gameplay.powerups.powerup_double_points.model, initialize, "models/pu/x2!.mdl");
    game_modifiers.gameplay.powerups.powerup_double_points.voiceover = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_double_points.voiceover", game_modifiers.gameplay.powerups.powerup_double_points.voiceover, initialize, "sounds/pu/double_points.wav");

    // MARK: Carpenter Power-Up
    game_modifiers.gameplay.powerups.powerup_carpenter.enabled = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_carpenter.enabled", initialize ? true : game_modifiers.gameplay.powerups.powerup_carpenter.enabled);
    game_modifiers.gameplay.powerups.powerup_carpenter.chance_to_allow_in_rotation = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_carpenter.chance_to_allow_in_rotation", initialize ? 1 : game_modifiers.gameplay.powerups.powerup_carpenter.chance_to_allow_in_rotation);
    game_modifiers.gameplay.powerups.powerup_carpenter.disabled_before_round = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_carpenter.disabled_before_round", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_carpenter.disabled_before_round);
    game_modifiers.gameplay.powerups.powerup_carpenter.destroyed_barricade_requirement = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_carpenter.destroyed_barricade_requirement", initialize ? 5 : game_modifiers.gameplay.powerups.powerup_carpenter.destroyed_barricade_requirement);
    game_modifiers.gameplay.powerups.powerup_carpenter.score_awarded = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_carpenter.score_awarded", initialize ? 200 : game_modifiers.gameplay.powerups.powerup_carpenter.score_awarded);
    game_modifiers.gameplay.powerups.powerup_carpenter.toast = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_carpenter.toast", game_modifiers.gameplay.powerups.powerup_carpenter.toast, initialize, "Carpenter!");
    game_modifiers.gameplay.powerups.powerup_carpenter.show_toast = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_carpenter.show_toast", initialize ? false : game_modifiers.gameplay.powerups.powerup_carpenter.show_toast);
    game_modifiers.gameplay.powerups.powerup_carpenter.model = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_carpenter.model", game_modifiers.gameplay.powerups.powerup_carpenter.model, initialize, "models/pu/carpenter!.mdl");
    game_modifiers.gameplay.powerups.powerup_carpenter.voiceover = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_carpenter.voiceover", game_modifiers.gameplay.powerups.powerup_carpenter.voiceover, initialize, "sounds/pu/carpenter.wav");

    // MARK: Nuke Power-Up
    game_modifiers.gameplay.powerups.powerup_nuke.enabled = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_nuke.enabled", initialize ? true : game_modifiers.gameplay.powerups.powerup_nuke.enabled);
    game_modifiers.gameplay.powerups.powerup_nuke.chance_to_allow_in_rotation = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_nuke.chance_to_allow_in_rotation", initialize ? 1 : game_modifiers.gameplay.powerups.powerup_nuke.chance_to_allow_in_rotation);
    game_modifiers.gameplay.powerups.powerup_nuke.disabled_before_round = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_nuke.disabled_before_round", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_nuke.disabled_before_round);
    game_modifiers.gameplay.powerups.powerup_nuke.score_awarded = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_nuke.score_awarded", initialize ? 400 : game_modifiers.gameplay.powerups.powerup_nuke.score_awarded);
    game_modifiers.gameplay.powerups.powerup_nuke.toast = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_nuke.toast", game_modifiers.gameplay.powerups.powerup_nuke.toast, initialize, "Ka-Boom!");
    game_modifiers.gameplay.powerups.powerup_nuke.show_toast = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_nuke.show_toast", initialize ? false : game_modifiers.gameplay.powerups.powerup_nuke.show_toast);
    game_modifiers.gameplay.powerups.powerup_nuke.model = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_nuke.model", game_modifiers.gameplay.powerups.powerup_nuke.model, initialize, "models/pu/nuke!.mdl");
    game_modifiers.gameplay.powerups.powerup_nuke.voiceover = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_nuke.voiceover", game_modifiers.gameplay.powerups.powerup_nuke.voiceover, initialize, "sounds/pu/kaboom.wav");
    game_modifiers.gameplay.powerups.powerup_nuke.explosion_sfx = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_nuke.explosion_sfx", game_modifiers.gameplay.powerups.powerup_nuke.explosion_sfx, initialize, "sounds/pu/nuke.wav");

    // MARK: Free Perk Power-Up
    game_modifiers.gameplay.powerups.powerup_free_perk.enabled = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_free_perk.enabled", initialize ? false : game_modifiers.gameplay.powerups.powerup_free_perk.enabled);
    game_modifiers.gameplay.powerups.powerup_free_perk.chance_to_allow_in_rotation = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_free_perk.chance_to_allow_in_rotation", initialize ? 0.25 : game_modifiers.gameplay.powerups.powerup_free_perk.chance_to_allow_in_rotation);
    game_modifiers.gameplay.powerups.powerup_free_perk.disabled_before_round = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_free_perk.disabled_before_round", initialize ? 15 : game_modifiers.gameplay.powerups.powerup_free_perk.disabled_before_round);
    game_modifiers.gameplay.powerups.powerup_free_perk.awarded_score_if_no_perk_obtained = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_free_perk.awarded_score_if_no_perk_obtained", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_free_perk.awarded_score_if_no_perk_obtained);
    array_root = Json_GetPath(config_root, "gameplay.powerups.powerup_free_perk.allowed_perksacola");
    if (initialize || array_root) {
        for (float i = 0; i < 8; i++) {
            if (game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[i] != "") strunzone(game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[i]);
            game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[i] = "";
            string value = Json_ArrayStringAt(array_root, i, "");
            if (value != "") game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[i] = strzone(value);
        }
    }
    if (initialize && !array_root) {
        game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[0] = strzone("quickrevive");
        game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[1] = strzone("juggernog");
        game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[2] = strzone("speedcola");
        game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[3] = strzone("doubletap");
        game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[4] = strzone("phdflopper");
        game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[5] = strzone("staminup");
        game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[6] = strzone("deadshot");
        game_modifiers.gameplay.powerups.powerup_free_perk.allowed_perksacola[7] = strzone("mulekick");
    }
    game_modifiers.gameplay.powerups.powerup_free_perk.toast = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_free_perk.toast", game_modifiers.gameplay.powerups.powerup_free_perk.toast, initialize, "Random Perk!");
    game_modifiers.gameplay.powerups.powerup_free_perk.show_toast = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_free_perk.show_toast", initialize ? false : game_modifiers.gameplay.powerups.powerup_free_perk.show_toast);
    game_modifiers.gameplay.powerups.powerup_free_perk.model = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_free_perk.model", game_modifiers.gameplay.powerups.powerup_free_perk.model, initialize, "models/pu/perkbottle!.mdl");
    game_modifiers.gameplay.powerups.powerup_free_perk.voiceover = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_free_perk.voiceover", game_modifiers.gameplay.powerups.powerup_free_perk.voiceover, initialize, "");

    // MARK: Bonus Points Power-Up
    game_modifiers.gameplay.powerups.powerup_bonus_points.enabled = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_bonus_points.enabled", initialize ? false : game_modifiers.gameplay.powerups.powerup_bonus_points.enabled);
    game_modifiers.gameplay.powerups.powerup_bonus_points.chance_to_allow_in_rotation = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_bonus_points.chance_to_allow_in_rotation", initialize ? 1 : game_modifiers.gameplay.powerups.powerup_bonus_points.chance_to_allow_in_rotation);
    game_modifiers.gameplay.powerups.powerup_bonus_points.disabled_before_round = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_bonus_points.disabled_before_round", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_bonus_points.disabled_before_round);
    game_modifiers.gameplay.powerups.powerup_bonus_points.score_awarded = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_bonus_points.score_awarded", initialize ? 500 : game_modifiers.gameplay.powerups.powerup_bonus_points.score_awarded);
    game_modifiers.gameplay.powerups.powerup_bonus_points.toast = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_bonus_points.toast", game_modifiers.gameplay.powerups.powerup_bonus_points.toast, initialize, "Bonus Points!");
    game_modifiers.gameplay.powerups.powerup_bonus_points.show_toast = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_bonus_points.show_toast", initialize ? false : game_modifiers.gameplay.powerups.powerup_bonus_points.show_toast);
    game_modifiers.gameplay.powerups.powerup_bonus_points.model = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_bonus_points.model", game_modifiers.gameplay.powerups.powerup_bonus_points.model, initialize, "models/pu/points!.mdl");
    game_modifiers.gameplay.powerups.powerup_bonus_points.voiceover = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_bonus_points.voiceover", game_modifiers.gameplay.powerups.powerup_bonus_points.voiceover, initialize, "");

    // MARK: Weapon Upgrade Power-Up
    game_modifiers.gameplay.powerups.powerup_weapon_upgrade.enabled = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_weapon_upgrade.enabled", initialize ? false : game_modifiers.gameplay.powerups.powerup_weapon_upgrade.enabled);
    game_modifiers.gameplay.powerups.powerup_weapon_upgrade.chance_to_allow_in_rotation = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_weapon_upgrade.chance_to_allow_in_rotation", initialize ? 1 : game_modifiers.gameplay.powerups.powerup_weapon_upgrade.chance_to_allow_in_rotation);
    game_modifiers.gameplay.powerups.powerup_weapon_upgrade.disabled_before_round = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_weapon_upgrade.disabled_before_round", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_weapon_upgrade.disabled_before_round);
    game_modifiers.gameplay.powerups.powerup_weapon_upgrade.awarded_score_if_no_upgrade_received = Json_GetFloatPath(config_root, "gameplay.powerups.powerup_weapon_upgrade.awarded_score_if_no_upgrade_received", initialize ? 0 : game_modifiers.gameplay.powerups.powerup_weapon_upgrade.awarded_score_if_no_upgrade_received);
    game_modifiers.gameplay.powerups.powerup_weapon_upgrade.toast = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_weapon_upgrade.toast", game_modifiers.gameplay.powerups.powerup_weapon_upgrade.toast, initialize, "Weapon Upgrade!");
    game_modifiers.gameplay.powerups.powerup_weapon_upgrade.show_toast = Json_GetBoolPath(config_root, "gameplay.powerups.powerup_weapon_upgrade.show_toast", initialize ? false : game_modifiers.gameplay.powerups.powerup_weapon_upgrade.show_toast);
    game_modifiers.gameplay.powerups.powerup_weapon_upgrade.model = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_weapon_upgrade.model", game_modifiers.gameplay.powerups.powerup_weapon_upgrade.model, initialize, "models/pu/pack!.mdl");
    game_modifiers.gameplay.powerups.powerup_weapon_upgrade.voiceover = Modifiers_ReadString(config_root, "gameplay.powerups.powerup_weapon_upgrade.voiceover", game_modifiers.gameplay.powerups.powerup_weapon_upgrade.voiceover, initialize, "");

    // MARK: AI scoring
    float score_system_node = Json_GetPath(config_root, "gameplay.ai.score_system");
    if (initialize || score_system_node) {
        string score_system = Json_AsString(score_system_node, "default");
        if (score_system == "cw")
            game_modifiers.gameplay.ai.score_system = SCORE_SYSTEM_CW;
        else if (score_system == "bo4")
            game_modifiers.gameplay.ai.score_system = SCORE_SYSTEM_BO4;
        else
            game_modifiers.gameplay.ai.score_system = SCORE_SYSTEM_DEFAULT;
    }

    game_modifiers.gameplay.ai.round_health_cap = Json_GetFloatPath(config_root, "gameplay.ai.round_health_cap", initialize ? 0 : game_modifiers.gameplay.ai.round_health_cap);

    // MARK: Zombie Walk Styles
    game_modifiers.gameplay.ai.zombie.walk_styles.can_walk = Json_GetBoolPath(config_root, "gameplay.ai.zombie.walk_styles.can_walk", initialize ? true : game_modifiers.gameplay.ai.zombie.walk_styles.can_walk);
    game_modifiers.gameplay.ai.zombie.walk_styles.can_jog = Json_GetBoolPath(config_root, "gameplay.ai.zombie.walk_styles.can_jog", initialize ? true : game_modifiers.gameplay.ai.zombie.walk_styles.can_jog);
    game_modifiers.gameplay.ai.zombie.walk_styles.can_sprint = Json_GetBoolPath(config_root, "gameplay.ai.zombie.walk_styles.can_sprint", initialize ? true : game_modifiers.gameplay.ai.zombie.walk_styles.can_sprint);
    game_modifiers.gameplay.ai.zombie.walk_styles.can_super_sprint = Json_GetBoolPath(config_root, "gameplay.ai.zombie.walk_styles.can_super_sprint", initialize ? false : game_modifiers.gameplay.ai.zombie.walk_styles.can_super_sprint);
    
    // MARK: Zombie Attack Sounds
    array_root = Json_GetPath(config_root, "gameplay.ai.zombie.sounds.attack");
    if (initialize || array_root) {
        for (float i = 0; i < 12; i++) {
            if (game_modifiers.gameplay.ai.zombie.sounds.attack[i] != "") strunzone(game_modifiers.gameplay.ai.zombie.sounds.attack[i]);
            game_modifiers.gameplay.ai.zombie.sounds.attack[i] = "";
            string value = Json_ArrayStringAt(array_root, i, "");
            if (value != "") game_modifiers.gameplay.ai.zombie.sounds.attack[i] = strzone(value);
        }
    }

    // MARK: Zombie Death Sounds
    array_root = Json_GetPath(config_root, "gameplay.ai.zombie.sounds.death");
    if (initialize || array_root) {
        for (float i = 0; i < 12; i++) {
            if (game_modifiers.gameplay.ai.zombie.sounds.death[i] != "") strunzone(game_modifiers.gameplay.ai.zombie.sounds.death[i]);
            game_modifiers.gameplay.ai.zombie.sounds.death[i] = "";
            string value = Json_ArrayStringAt(array_root, i, "");
            if (value != "") game_modifiers.gameplay.ai.zombie.sounds.death[i] = strzone(value);
        }
    }

    // MARK: Zombie Shout Sounds
    array_root = Json_GetPath(config_root, "gameplay.ai.zombie.sounds.shout");
    if (initialize || array_root) {
        for (float i = 0; i < 12; i++) {
            if (game_modifiers.gameplay.ai.zombie.sounds.shout[i] != "") strunzone(game_modifiers.gameplay.ai.zombie.sounds.shout[i]);
            game_modifiers.gameplay.ai.zombie.sounds.shout[i] = "";
            string value = Json_ArrayStringAt(array_root, i, "");
            if (value != "") game_modifiers.gameplay.ai.zombie.sounds.shout[i] = strzone(value);
        }
    }

    // MARK: Zombie Taunt Sounds
    array_root = Json_GetPath(config_root, "gameplay.ai.zombie.sounds.taunt");
    if (initialize || array_root) {
        for (float i = 0; i < 12; i++) {
            if (game_modifiers.gameplay.ai.zombie.sounds.taunt[i] != "") strunzone(game_modifiers.gameplay.ai.zombie.sounds.taunt[i]);
            game_modifiers.gameplay.ai.zombie.sounds.taunt[i] = "";
            string value = Json_ArrayStringAt(array_root, i, "");
            if (value != "") game_modifiers.gameplay.ai.zombie.sounds.taunt[i] = strzone(value);
        }
    }

    // MARK: Zombie Groan Sounds
    array_root = Json_GetPath(config_root, "gameplay.ai.zombie.sounds.groan");
    if (initialize || array_root) {
        for (float i = 0; i < 12; i++) {
            if (game_modifiers.gameplay.ai.zombie.sounds.groan[i] != "") strunzone(game_modifiers.gameplay.ai.zombie.sounds.groan[i]);
            game_modifiers.gameplay.ai.zombie.sounds.groan[i] = "";
            string value = Json_ArrayStringAt(array_root, i, "");
            if (value != "") game_modifiers.gameplay.ai.zombie.sounds.groan[i] = strzone(value);
        }
    }

    // MARK: Player
    game_modifiers.gameplay.player.start_health = Json_GetFloatPath(config_root, "gameplay.player.start_health", initialize ? 100 : game_modifiers.gameplay.player.start_health);
    game_modifiers.gameplay.player.can_earn_points_in_last_stand = Json_GetBoolPath(config_root, "gameplay.player.can_earn_points_in_last_stand", initialize ? false : game_modifiers.gameplay.player.can_earn_points_in_last_stand);
    game_modifiers.gameplay.player.can_use_melee = Json_GetBoolPath(config_root, "gameplay.player.can_use_melee", initialize ? true : game_modifiers.gameplay.player.can_use_melee);
    game_modifiers.gameplay.player.can_use_equipment = Json_GetBoolPath(config_root, "gameplay.player.can_use_equipment", initialize ? true : game_modifiers.gameplay.player.can_use_equipment);
    game_modifiers.gameplay.player.can_earn_score_from_sources_other_than_ai = Json_GetBoolPath(config_root, "gameplay.player.can_earn_score_from_sources_other_than_ai", initialize ? true : game_modifiers.gameplay.player.can_earn_score_from_sources_other_than_ai);
    game_modifiers.gameplay.player.health_regeneration.regeneration_multiplier = Json_GetFloatPath(config_root, "gameplay.player.health_regeneration.regeneration_multiplier", initialize ? 1 : game_modifiers.gameplay.player.health_regeneration.regeneration_multiplier);
    game_modifiers.gameplay.player.health_regeneration.regeneration_delay_light_damage = Json_GetFloatPath(config_root, "gameplay.player.health_regeneration.regeneration_delay_light_damage", initialize ? 2.4 : game_modifiers.gameplay.player.health_regeneration.regeneration_delay_light_damage);
    game_modifiers.gameplay.player.health_regeneration.regeneration_delay_heavy_damage = Json_GetFloatPath(config_root, "gameplay.player.health_regeneration.regeneration_delay_heavy_damage", initialize ? 5 : game_modifiers.gameplay.player.health_regeneration.regeneration_delay_heavy_damage);

    // MARK: Round and HUD configuration
    game_modifiers.gameplay.rounds.delay_between_rounds = Json_GetFloatPath(config_root, "gameplay.rounds.delay_between_rounds", initialize ? 10 : game_modifiers.gameplay.rounds.delay_between_rounds);
    game_modifiers.gameplay.rounds.ai_spawn_delay_reduction_multiplier = Json_GetFloatPath(config_root, "gameplay.rounds.ai_spawn_delay_reduction_multiplier", initialize ? 1 : game_modifiers.gameplay.rounds.ai_spawn_delay_reduction_multiplier);
    game_modifiers.gameplay.rounds.sounds.game_start = Modifiers_ReadString(config_root, "gameplay.rounds.sounds.game_start", game_modifiers.gameplay.rounds.sounds.game_start, initialize, "sounds/rounds/splash1.wav");
    array_root = Json_GetPath(config_root, "gameplay.rounds.sounds.new_round");
    if (initialize || array_root) {
        for (float i = 0; i < 4; i++) {
            if (game_modifiers.gameplay.rounds.sounds.new_round[i] != "") strunzone(game_modifiers.gameplay.rounds.sounds.new_round[i]);
            game_modifiers.gameplay.rounds.sounds.new_round[i] = "";
            string value = Modifiers_ArrayString(array_root, i);
            if (value != "") game_modifiers.gameplay.rounds.sounds.new_round[i] = strzone(value);
        }
    }
    if (initialize && !array_root) {
        game_modifiers.gameplay.rounds.sounds.new_round[0] = strzone("sounds/rounds/nround1.wav");
    }
    array_root = Json_GetPath(config_root, "gameplay.rounds.sounds.end_round");
    if (initialize || array_root) {
        for (float i = 0; i < 4; i++) {
            if (game_modifiers.gameplay.rounds.sounds.end_round[i] != "") strunzone(game_modifiers.gameplay.rounds.sounds.end_round[i]);
            game_modifiers.gameplay.rounds.sounds.end_round[i] = "";
            string value = Modifiers_ArrayString(array_root, i);
            if (value != "") game_modifiers.gameplay.rounds.sounds.end_round[i] = strzone(value);
        }
    }
    if (initialize && !array_root) {
        game_modifiers.gameplay.rounds.sounds.end_round[0] = strzone("sounds/rounds/eround1.wav");
    }
    game_modifiers.gameplay.rounds.sounds.new_hound_round = Modifiers_ReadString(config_root, "gameplay.rounds.sounds.new_hound_round", game_modifiers.gameplay.rounds.sounds.new_hound_round, initialize, "sounds/rounds/droundstart.wav");
    game_modifiers.gameplay.rounds.sounds.end_hound_round = Modifiers_ReadString(config_root, "gameplay.rounds.sounds.end_hound_round", game_modifiers.gameplay.rounds.sounds.end_hound_round, initialize, "sounds/rounds/droundend.wav");
    array_root = Json_GetPath(config_root, "gameplay.rounds.sounds.hound_round_taunts");
    if (initialize || array_root) {
        for (float i = 0; i < 4; i++) {
            if (game_modifiers.gameplay.rounds.sounds.hound_round_taunts[i] != "") strunzone(game_modifiers.gameplay.rounds.sounds.hound_round_taunts[i]);
            game_modifiers.gameplay.rounds.sounds.hound_round_taunts[i] = "";
            string value = Modifiers_ArrayString(array_root, i);
            if (value != "") game_modifiers.gameplay.rounds.sounds.hound_round_taunts[i] = strzone(value);
        }
    }
    if (initialize && !array_root) {
        game_modifiers.gameplay.rounds.sounds.hound_round_taunts[0] = strzone("sounds/rounds/fetch.wav");
    }
    game_modifiers.gameplay.rounds.sounds.game_over = Modifiers_ReadString(config_root, "gameplay.rounds.sounds.game_over", game_modifiers.gameplay.rounds.sounds.game_over, initialize, "sounds/music/end.wav");
    game_modifiers.interface.perksacola.position_style = Modifiers_ReadString(config_root, "interface.perksacola.position_style", game_modifiers.interface.perksacola.position_style, initialize, "nzp");
    game_modifiers.interface.perksacola.graphics.quickrevive = Modifiers_ReadString(config_root, "interface.perksacola.graphics.quickrevive", game_modifiers.interface.perksacola.graphics.quickrevive, initialize, "gfx/hud/revive");
    game_modifiers.interface.perksacola.graphics.juggernog = Modifiers_ReadString(config_root, "interface.perksacola.graphics.juggernog", game_modifiers.interface.perksacola.graphics.juggernog, initialize, "gfx/hud/jug");
    game_modifiers.interface.perksacola.graphics.speedcola = Modifiers_ReadString(config_root, "interface.perksacola.graphics.speedcola", game_modifiers.interface.perksacola.graphics.speedcola, initialize, "gfx/hud/speed");
    game_modifiers.interface.perksacola.graphics.doubletap = Modifiers_ReadString(config_root, "interface.perksacola.graphics.doubletap", game_modifiers.interface.perksacola.graphics.doubletap, initialize, "gfx/hud/double");
    game_modifiers.interface.perksacola.graphics.doubletap_2 = Modifiers_ReadString(config_root, "interface.perksacola.graphics.doubletap_2", game_modifiers.interface.perksacola.graphics.doubletap_2, initialize, "gfx/hud/double2");
    game_modifiers.interface.perksacola.graphics.staminup = Modifiers_ReadString(config_root, "interface.perksacola.graphics.staminup", game_modifiers.interface.perksacola.graphics.staminup, initialize, "gfx/hud/stamin");
    game_modifiers.interface.perksacola.graphics.flopper = Modifiers_ReadString(config_root, "interface.perksacola.graphics.flopper", game_modifiers.interface.perksacola.graphics.flopper, initialize, "gfx/hud/flopper");
    game_modifiers.interface.perksacola.graphics.deadshot = Modifiers_ReadString(config_root, "interface.perksacola.graphics.deadshot", game_modifiers.interface.perksacola.graphics.deadshot, initialize, "gfx/hud/dead");
    game_modifiers.interface.perksacola.graphics.mulekick = Modifiers_ReadString(config_root, "interface.perksacola.graphics.mulekick", game_modifiers.interface.perksacola.graphics.mulekick, initialize, "gfx/hud/mule");
    game_modifiers.interface.powerups.graphics.insta_kill = Modifiers_ReadString(config_root, "interface.powerups.graphics.insta_kill", game_modifiers.interface.powerups.graphics.insta_kill, initialize, "gfx/hud/in_kill");
    game_modifiers.interface.powerups.graphics.double_points = Modifiers_ReadString(config_root, "interface.powerups.graphics.double_points", game_modifiers.interface.powerups.graphics.double_points, initialize, "gfx/hud/2x");
    game_modifiers.interface.rounds.position_style = Modifiers_ReadString(config_root, "interface.rounds.position_style", game_modifiers.interface.rounds.position_style, initialize, "bottom_left");
    game_modifiers.interface.rounds.skip_intro = Json_GetBoolPath(config_root, "interface.rounds.skip_intro", initialize ? false : game_modifiers.interface.rounds.skip_intro);
    game_modifiers.interface.rounds.use_tally_marks_until_round = Json_GetFloatPath(config_root, "interface.rounds.use_tally_marks_until_round", initialize ? 11 : game_modifiers.interface.rounds.use_tally_marks_until_round);
    game_modifiers.interface.rounds.color = Modifiers_ReadColor(config_root, "interface.rounds.color", initialize ? '107 1 0' : game_modifiers.interface.rounds.color);
    array_root = Json_GetPath(config_root, "interface.rounds.graphics.tally_marks");
    if (initialize || array_root) {
        for (float i = 0; i < 5; i++) {
            if (game_modifiers.interface.rounds.graphics.tally_marks[i] != "") strunzone(game_modifiers.interface.rounds.graphics.tally_marks[i]);
            game_modifiers.interface.rounds.graphics.tally_marks[i] = "";
            string value = Modifiers_ArrayString(array_root, i);
            if (value != "") game_modifiers.interface.rounds.graphics.tally_marks[i] = strzone(value);
        }
    }
    if (initialize && !array_root) {
        game_modifiers.interface.rounds.graphics.tally_marks[0] = strzone("gfx/hud/r1");
        game_modifiers.interface.rounds.graphics.tally_marks[1] = strzone("gfx/hud/r2");
        game_modifiers.interface.rounds.graphics.tally_marks[2] = strzone("gfx/hud/r3");
        game_modifiers.interface.rounds.graphics.tally_marks[3] = strzone("gfx/hud/r4");
        game_modifiers.interface.rounds.graphics.tally_marks[4] = strzone("gfx/hud/r5");
    }
    array_root = Json_GetPath(config_root, "interface.rounds.graphics.numeric");
    if (initialize || array_root) {
        for (float i = 0; i < 10; i++) {
            if (game_modifiers.interface.rounds.graphics.numeric[i] != "") strunzone(game_modifiers.interface.rounds.graphics.numeric[i]);
            game_modifiers.interface.rounds.graphics.numeric[i] = "";
            string value = Modifiers_ArrayString(array_root, i);
            if (value != "") game_modifiers.interface.rounds.graphics.numeric[i] = strzone(value);
        }
    }
    if (initialize && !array_root) {
        game_modifiers.interface.rounds.graphics.numeric[0] = strzone("gfx/hud/r_num0");
        game_modifiers.interface.rounds.graphics.numeric[1] = strzone("gfx/hud/r_num1");
        game_modifiers.interface.rounds.graphics.numeric[2] = strzone("gfx/hud/r_num2");
        game_modifiers.interface.rounds.graphics.numeric[3] = strzone("gfx/hud/r_num3");
        game_modifiers.interface.rounds.graphics.numeric[4] = strzone("gfx/hud/r_num4");
        game_modifiers.interface.rounds.graphics.numeric[5] = strzone("gfx/hud/r_num5");
        game_modifiers.interface.rounds.graphics.numeric[6] = strzone("gfx/hud/r_num6");
        game_modifiers.interface.rounds.graphics.numeric[7] = strzone("gfx/hud/r_num7");
        game_modifiers.interface.rounds.graphics.numeric[8] = strzone("gfx/hud/r_num8");
        game_modifiers.interface.rounds.graphics.numeric[9] = strzone("gfx/hud/r_num9");
    }
    game_modifiers.interface.equipment.graphics.grenade = Modifiers_ReadString(config_root, "interface.equipment.graphics.grenade", game_modifiers.interface.equipment.graphics.grenade, initialize, "gfx/hud/frag");
    game_modifiers.interface.equipment.graphics.bouncing_betty = Modifiers_ReadString(config_root, "interface.equipment.graphics.bouncing_betty", game_modifiers.interface.equipment.graphics.bouncing_betty, initialize, "gfx/hud/betty");
    game_modifiers.interface.score.position_style = Modifiers_ReadString(config_root, "interface.score.position_style", game_modifiers.interface.score.position_style, initialize, "left");
    game_modifiers.interface.score.graphics.score_background_full = Modifiers_ReadString(config_root, "interface.score.graphics.score_background_full", game_modifiers.interface.score.graphics.score_background_full, initialize, "gfx/hud/moneyback");
    game_modifiers.interface.score.graphics.score_background_condensed = Modifiers_ReadString(config_root, "interface.score.graphics.score_background_condensed", game_modifiers.interface.score.graphics.score_background_condensed, initialize, "gfx/hud/moneyback_condensed");

};

//
// Modifiers_LoadFile(path, required, report_missing)
// A broken optional layer leaves the previous settings intact.
// The default file is required so a bad install doesn't silently change play.
//
void(string path, float required, float report_missing) Modifiers_LoadFile =
{
    float root = Json_ParseFile(path);
    if (json_file_missing && !required && !report_missing) return;
    float valid = root != 0;
    if (valid) valid = Modifiers_Validate(root);
    if (!valid) {
        print("Configuration error in ");
        print(path);
        print(": ");
        if (json_file_missing) print("file not found");
        else print(json_error_msg);
        print("\n");
        if (root) json_free(root);
        if (required) error("Could not load default gameplay configuration.\n");
        return;
    }
    if (!required && Json_GetPath(root, "gameplay.powerups.powerup_weapon_upgrade.enabled"))
        modifier_weapon_upgrade_overridden = true;
    Modifiers_ApplyValues(root, false);
    json_free(root);
};

float(string name) Modifiers_ValidName =
{
    string c;
    string allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-";
    if (name == "" || strlen(name) > 64) return false;
    for (float i = 0; i < strlen(name); i++) {
        c = substring(name, i, 1);
        float found = strstrofs(allowed, c, 0) >= 0;
        if (!found) return false;
    }
    return true;
};

void() Modifiers_LoadGameVariables =
{
    modifier_weapon_upgrade_overridden = false;
    Modifiers_ApplyValues(0, true);
    Modifiers_LoadFile("data/configuration/default.json", true, true);
};

//
// Modifiers_LoadOverrides()
// Called after game mode defaults, before any configurable assets precache.
// File precedence is default.json -> maps/<map>.json -> overlays/<name>.json.
//
void() Modifiers_LoadOverrides =
{
    string path;
    if (Modifiers_ValidName(mapname)) {
        path = strzone(strcat(strcat("data/configuration/maps/", mapname), ".json"));
        Modifiers_LoadFile(path, false, false);
        strunzone(path);
    }
    string overlay = strzone(cvar_string("sv_gameconfig"));
    if (overlay != "") {
        if (Modifiers_ValidName(overlay)) {
            path = strzone(strcat(strcat("data/configuration/overlays/", overlay), ".json"));
            Modifiers_LoadFile(path, false, true);
            strunzone(path);
        } else {
            print("sv_gameconfig must be a filename without a path or .json extension.\n");
        }
    }
    strunzone(overlay);
};

//
// Modifiers_ZombieSoundAt(group, index)
// Sound groups are attack, death, shout, taunt and groan, in that order.
//
string(float group, float index) Modifiers_ZombieSoundAt =
{
    switch (group) {
        case 0: return game_modifiers.gameplay.ai.zombie.sounds.attack[index];
        case 1: return game_modifiers.gameplay.ai.zombie.sounds.death[index];
        case 2: return game_modifiers.gameplay.ai.zombie.sounds.shout[index];
        case 3: return game_modifiers.gameplay.ai.zombie.sounds.taunt[index];
        case 4: return game_modifiers.gameplay.ai.zombie.sounds.groan[index];
    }
    return "";
};

float(float group) Modifiers_ZombieSoundCount =
{
    for (float i = 0; i < 12; i++) {
        if (Modifiers_ZombieSoundAt(group, i) == "") return i;
    }
    return 12;
};

string(float group) Modifiers_PickZombieSound =
{
    float count = Modifiers_ZombieSoundCount(group);
    if (!count) return "";
    return Modifiers_ZombieSoundAt(group, clamp(floor(random() * count), 0, count - 1));
};

string(float ending) Modifiers_PickRoundSound =
{
    float count;
    for (count = 0; count < 4; count++) {
        if (ending && game_modifiers.gameplay.rounds.sounds.end_round[count] == "") break;
        if (!ending && game_modifiers.gameplay.rounds.sounds.new_round[count] == "") break;
    }
    if (!count) return "";
    float index = clamp(floor(random() * count), 0, count - 1);
    if (ending) return game_modifiers.gameplay.rounds.sounds.end_round[index];
    return game_modifiers.gameplay.rounds.sounds.new_round[index];
};

string() Modifiers_PickHellhoundTaunt =
{
    float count;
    for (count = 0; count < 4; count++) {
        if (game_modifiers.gameplay.rounds.sounds.hound_round_taunts[count] == "") break;
    }
    if (!count) return "";
    return game_modifiers.gameplay.rounds.sounds.hound_round_taunts[clamp(floor(random() * count), 0, count - 1)];
};

void(string path) Modifiers_PrecacheSound =
{
    if (path != "") precache_sound(path);
};

void() Modifiers_PrecacheSounds =
{
    for (float group = 0; group < 5; group++) {
        for (float i = 0; i < 12; i++) Modifiers_PrecacheSound(Modifiers_ZombieSoundAt(group, i));
    }
    for (float i = 0; i < 4; i++) {
        Modifiers_PrecacheSound(game_modifiers.gameplay.rounds.sounds.new_round[i]);
        Modifiers_PrecacheSound(game_modifiers.gameplay.rounds.sounds.end_round[i]);
    }
    Modifiers_PrecacheSound(game_modifiers.gameplay.rounds.sounds.game_start);
    Modifiers_PrecacheSound(game_modifiers.gameplay.rounds.sounds.new_hound_round);
    Modifiers_PrecacheSound(game_modifiers.gameplay.rounds.sounds.end_hound_round);
    for (float i = 0; i < 4; i++) Modifiers_PrecacheSound(game_modifiers.gameplay.rounds.sounds.hound_round_taunts[i]);
    Modifiers_PrecacheSound(game_modifiers.gameplay.rounds.sounds.game_over);
};

// Vril keeps these for clients joining after worldspawn, too.
void() Modifiers_RegisterHUD =
{
	nzp_hudconfig(0, game_modifiers.interface.perksacola.position_style);
	nzp_hudconfig(1, ftos(game_modifiers.interface.rounds.use_tally_marks_until_round));
	nzp_hudconfig(2, game_modifiers.interface.perksacola.graphics.quickrevive);
	nzp_hudconfig(3, game_modifiers.interface.perksacola.graphics.juggernog);
	nzp_hudconfig(4, game_modifiers.interface.perksacola.graphics.speedcola);
	nzp_hudconfig(5, game_modifiers.interface.perksacola.graphics.doubletap);
	nzp_hudconfig(6, game_modifiers.interface.perksacola.graphics.doubletap_2);
	nzp_hudconfig(7, game_modifiers.interface.perksacola.graphics.staminup);
	nzp_hudconfig(8, game_modifiers.interface.perksacola.graphics.flopper);
	nzp_hudconfig(9, game_modifiers.interface.perksacola.graphics.deadshot);
	nzp_hudconfig(10, game_modifiers.interface.perksacola.graphics.mulekick);
	nzp_hudconfig(11, game_modifiers.interface.powerups.graphics.insta_kill);
	nzp_hudconfig(12, game_modifiers.interface.powerups.graphics.double_points);
	nzp_hudconfig(13, game_modifiers.interface.rounds.graphics.tally_marks[0]);
	nzp_hudconfig(14, game_modifiers.interface.rounds.graphics.tally_marks[1]);
	nzp_hudconfig(15, game_modifiers.interface.rounds.graphics.tally_marks[2]);
	nzp_hudconfig(16, game_modifiers.interface.rounds.graphics.tally_marks[3]);
	nzp_hudconfig(17, game_modifiers.interface.rounds.graphics.tally_marks[4]);
	nzp_hudconfig(18, game_modifiers.interface.rounds.graphics.numeric[0]);
	nzp_hudconfig(19, game_modifiers.interface.rounds.graphics.numeric[1]);
	nzp_hudconfig(20, game_modifiers.interface.rounds.graphics.numeric[2]);
	nzp_hudconfig(21, game_modifiers.interface.rounds.graphics.numeric[3]);
	nzp_hudconfig(22, game_modifiers.interface.rounds.graphics.numeric[4]);
	nzp_hudconfig(23, game_modifiers.interface.rounds.graphics.numeric[5]);
	nzp_hudconfig(24, game_modifiers.interface.rounds.graphics.numeric[6]);
	nzp_hudconfig(25, game_modifiers.interface.rounds.graphics.numeric[7]);
	nzp_hudconfig(26, game_modifiers.interface.rounds.graphics.numeric[8]);
	nzp_hudconfig(27, game_modifiers.interface.rounds.graphics.numeric[9]);
	nzp_hudconfig(28, game_modifiers.interface.equipment.graphics.grenade);
	nzp_hudconfig(29, game_modifiers.interface.equipment.graphics.bouncing_betty);
	nzp_hudconfig(30, game_modifiers.interface.score.graphics.score_background_full);
	nzp_hudconfig(31, game_modifiers.interface.score.graphics.score_background_condensed);
    nzp_hudconfig(32, game_modifiers.interface.score.position_style);
	nzp_hudconfig(33, game_modifiers.interface.rounds.position_style);
	nzp_hudconfig(34, ftos(game_modifiers.interface.rounds.skip_intro));
	nzp_setroundcolor(game_modifiers.interface.rounds.color);
};
