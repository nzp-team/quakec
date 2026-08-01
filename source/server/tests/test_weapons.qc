/*
	server/tests/test_weapons.qc

	Weapon related unit tests.

	Copyright (C) 2021-2025 NZ:P Team

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
void(string message) Test_Skip;

//
//
// Weapon System
//
//

//
// Test_Weapons_Gewehr_MagazineSize()
// Asserts the Gewehr and it's Pack-A-Punched
// form have the correct magazine sizes.
// (https://github.com/nzp-team/nzportable/issues/1102)
//
void() Test_Weapons_Gewehr_MagazineSize =
{
    Test_Assert((getWeaponMag(W_GEWEHR) == 10), "Gewehr has incorrect magazine size!");
    Test_Assert((getWeaponMag(W_COMPRESSOR) == 12), "Upgraded Gewehr has incorrect magazine size!");
};

//
// Test_Weapons_DualWield_ReloadLowReserveRightLeft()
// Asserts if we are attempting to reload a Dual Wield
// weapon while the reserve is too small to fill both
// mags, that we do not give out more ammo than intended.
// This triggers the Right side first, then Left.
// (https://github.com/nzp-team/nzportable/issues/1096)
//
void() Test_Weapons_DualWield_ReloadLowReserveRightLeft =
{
    Weapon_RemoveWeapon(0);
    Weapon_GiveWeapon(W_BIATCH, 0, 0, 0);

    self.weapons[0].weapon_magazine = 3;
    self.weapons[0].weapon_magazine_left = 1;
    self.weapons[0].weapon_reserve = 7;

    W_Give_Ammo(S_RIGHT);
    W_Give_Ammo(S_LEFT);

    Test_Assert((self.weapons[0].weapon_magazine == 6), sprintf("Expected [6] for right magazine size, got [%d]!", self.weapons[0].weapon_magazine));
    Test_Assert((self.weapons[0].weapon_magazine_left == 5), sprintf("Expected [5] for left magazine size, got [%d]!", self.weapons[0].weapon_magazine_left));
    Test_Assert((self.weapons[0].weapon_reserve == 0), sprintf("Expected [0] for reserve size, got [%d]!", self.weapons[0].weapon_reserve));
};

//
// Test_Weapons_DualWield_ReloadLowReserveLeftRight()
// Asserts if we are attempting to reload a Dual Wield
// weapon while the reserve is too small to fill both
// mags, that we do not give out more ammo than intended.
// This triggers the Right side first, then Left.
// (https://github.com/nzp-team/nzportable/issues/1096)
//
void() Test_Weapons_DualWield_ReloadLowReserveLeftRight =
{
    Weapon_RemoveWeapon(0);
    Weapon_GiveWeapon(W_BIATCH, 0, 0, 0);

    self.weapons[0].weapon_magazine = 3;
    self.weapons[0].weapon_magazine_left = 1;
    self.weapons[0].weapon_reserve = 7;

    W_Give_Ammo(S_LEFT);
    W_Give_Ammo(S_RIGHT);

    Test_Assert((self.weapons[0].weapon_magazine == 5), sprintf("Expected [5] for right magazine size, got [%d]!", self.weapons[0].weapon_magazine));
    Test_Assert((self.weapons[0].weapon_magazine_left == 6), sprintf("Expected [6] for left magazine size, got [%d]!", self.weapons[0].weapon_magazine_left));
    Test_Assert((self.weapons[0].weapon_reserve == 0), sprintf("Expected [0] for reserve size, got [%d]!", self.weapons[0].weapon_reserve));
};

//
// Test_Weapons_BowieKnife_RemovedAfterRespawn()
// Asserts that upon respawning a client loses the
// Bowie Knife.
// (https://github.com/nzp-team/nzportable/issues/922)
//
void() Test_Weapons_BowieKnife_RemovedAfterRespawn =
{
    self.has_bowie_knife = true;
    PlayerSpawn();
    Test_Assert((self.has_bowie_knife == false), "Client still has Bowie Knife!");
};

//
// Test_Weapons_HoldTwoWeapons()
// Asserts we can hold more than just a single 
// weapon.
// (https://github.com/nzp-team/nzportable/issues/786)
//
void() Test_Weapons_HoldTwoWeapons =
{
    Weapon_GiveWeapon(W_COLT, 0, 0, 0);
    Weapon_GiveWeapon(W_GEWEHR, 0, 0, 0);

    Test_Assert((self.weapons[0].weapon_id != 0), "No weapon in slot zero!");
    Test_Assert((self.weapons[1].weapon_id != 0), "No weapon in slot one!");

    Weapon_RemoveWeapon(1);
};

//
// Test_Weapons_HoldThreeWeapons()
// Gives the client Mule Kick and asserts we can
// hold three weapons.
//
void() Test_Weapons_HoldThreeWeapons =
{
    GivePerk(P_MULE);

    Weapon_GiveWeapon(W_COLT, 0, 0, 0);
    Weapon_GiveWeapon(W_GEWEHR, 0, 0, 0);
    Weapon_GiveWeapon(W_KAR, 0, 0, 0);

    Test_Assert((self.weapons[0].weapon_id != 0), "No weapon in slot zero!");
    Test_Assert((self.weapons[1].weapon_id != 0), "No weapon in slot one!");
    Test_Assert((self.weapons[2].weapon_id != 0), "No weapon in slot two!");

    Weapon_RemoveWeapon(1);
    Weapon_RemoveWeapon(2);
    self.perks = 0;
};

//
// Test_Weapons_UpgradedSound()
// Validates certain weapons are set to not
// play an upgraded sound.
//
void() Test_Weapons_UpgradedSound =
{
    float weapon_list[] = { W_DG3, W_PORTER, W_FIW };

    for (float i = 0; i < weapon_list.length; i++) {
        Test_Assert((WepDef_DoesNotPlayUpgradedSound(weapon_list[i]) == true), sprintf("Weapon [%s] plays an upgraded sound!", GetWeaponName(weapon_list[i], -1)));
    }

	return false;
};

//
// Test_Weapons_RayGunClassification()
// Ensures every base and upgraded Ray Gun is in the same weapon family.
//
void() Test_Weapons_RayGunClassification =
{
	Test_Assert(WepDef_IsRayGun(W_RAY), "Ray Gun is not classified as a Ray Gun!");
	Test_Assert(WepDef_IsRayGun(W_PORTER), "Porter's X2 is not classified as a Ray Gun!");
	Test_Assert(WepDef_IsRayGun(W_RAYMK2), "Ray Gun Mark II is not classified as a Ray Gun!");
	Test_Assert(WepDef_IsRayGun(W_PORTERMK2), "Porter's Mark II is not classified as a Ray Gun!");
	Test_Assert(!WepDef_IsRayGun(W_COLT), "A non-Ray Gun is classified as a Ray Gun!");
};

//
// Test_Weapons_BurstCannotBeInterruptedBySwap()
// Ensures a weapon swap cannot replace the animation callback responsible for
// completing a burst and leave the player permanently action-locked.
// (https://github.com/nzp-team/nzportable/issues/1342)
//
void() Test_Weapons_BurstCannotBeInterruptedBySwap =
{
	float old_weapon1 = self.weapons[1].weapon_id;
	float old_burst_count = self.weapon_burst_count;
	float old_semi_actions = self.semi_actions;
	float old_switch_delay = self.switch_delay;
	float old_is_buying = self.isBuying;
	float old_downed = self.downed;

	self.weapons[1].weapon_id = W_COLT;
	self.weapon_burst_count = 2;
	self.semi_actions &= ~SEMIACTION_WEAPONSWAP;
	self.switch_delay = 0;
	self.isBuying = false;
	self.downed = false;

	W_PutOut();

	Test_Assert(!(self.semi_actions & SEMIACTION_WEAPONSWAP), "Weapon swap started during an active burst!");
	Test_Assert((self.weapon_burst_count == 2), "Weapon swap interrupted the active burst!");

	self.weapons[1].weapon_id = old_weapon1;
	self.weapon_burst_count = old_burst_count;
	self.semi_actions = old_semi_actions;
	self.switch_delay = old_switch_delay;
	self.isBuying = old_is_buying;
	self.downed = old_downed;
};

//
// Test_MysteryBox_RayGunsAreMutuallyExclusive()
// Ensures a player carrying either Ray Gun variant cannot receive another.
//
void() Test_MysteryBox_RayGunsAreMutuallyExclusive =
{
	float old_weapon0 = self.weapons[0].weapon_id;
	float old_weapon1 = self.weapons[1].weapon_id;
	float old_weapon2 = self.weapons[2].weapon_id;

	self.weapons[0].weapon_id = W_RAY;
	self.weapons[1].weapon_id = W_NOWEP;
	self.weapons[2].weapon_id = W_NOWEP;
	Test_Assert(!MBOX_CanPlayerReceiveWeapon(self, W_RAYMK2), "Player with Ray Gun could receive Mark II!");

	self.weapons[0].weapon_id = W_NOWEP;
	self.weapons[2].weapon_id = W_PORTERMK2;
	Test_Assert(!MBOX_CanPlayerReceiveWeapon(self, W_RAY), "Player with upgraded Mark II could receive Ray Gun!");
	Test_Assert(MBOX_CanPlayerReceiveWeapon(self, W_COLT), "Ray Gun incorrectly blocked an unrelated weapon!");

	self.weapons[0].weapon_id = old_weapon0;
	self.weapons[1].weapon_id = old_weapon1;
	self.weapons[2].weapon_id = old_weapon2;
};

//
// Test_MysteryBox_MarkTwoIsOptIn()
// Ensures an omitted Mark II remains disabled for both MB2 list modes.
// (https://github.com/nzp-team/nzportable/issues/1348)
//
void() Test_MysteryBox_MarkTwoIsOptIn =
{
	Test_Assert(!MBOX_WeaponAllowedByDefault(true, W_RAYMK2), "Allow mode enabled an omitted Mark II!");
	Test_Assert(!MBOX_WeaponAllowedByDefault(false, W_RAYMK2), "Deny mode enabled an omitted Mark II!");
	Test_Assert(MBOX_WeaponAllowedByDefault(false, W_COLT), "Deny mode failed to enable an omitted normal weapon!");
};

//
// Test_Weapons_ShotgunPenetration()
// Validates shotgun penetration is set
// correctly.
// (https://github.com/nzp-team/nzportable/issues/652)
//
void() Test_Weapons_ShotgunPenetration =
{
    float weapon_list[] = { W_DB, W_BORE, W_SAWNOFF, W_SNUFF, W_TRENCH, W_GUT };

    for (float i = 0; i < weapon_list.length; i++) {
        Test_Assert((getWeaponPenetration(weapon_list[i], 2) != 0), sprintf("Weapon [%s] not correctly penetrating!", GetWeaponName(weapon_list[i], -1)));
    }
};

//
// Test_Weapons_WunderWaffe_UpgradedReserve()
// Validates correct reserve ammo count for DG-3.
// (https://github.com/nzp-team/nzportable/issues/651)
//
void() Test_Weapons_WunderWaffe_UpgradedReserve =
{
    Test_Assert(getWeaponAmmo(W_DG3) == 30, "Incorrect reserve ammo!");
};

//
// Test_Weapons_WunderWaffe_FireAtBarrel()
// Simulates firing the DG-2 at an explosive barrel
// and validates it does not count as a kill and
// does not award points.
// (https://github.com/nzp-team/nzportable/issues/584)
//
void() Test_Weapons_WunderWaffe_FireAtBarrel =
{
    Test_Skip("Skipped while facing odd traceline behavior");
#if 0
    float kills_pre = self.kills;
    float score_pre = self.points;

    makevectors(self.angles);

    entity barrel = spawn();
    entity old_self = self;
    self = barrel;
    setorigin(self, old_self.origin + (v_forward * 50) + '0 0 16');
    explosive_barrel();
    self = old_self;

    Weapon_GiveWeapon(W_TESLA, 0, 0, 0);
    W_FireTesla();

    float kills_post = self.kills;
    float score_post = self.points;

    Test_Assert((kills_pre == kills_post), "Explosive barrel counted as kill!");
    Test_Assert((score_pre == score_post), "Explosive barrel earned score!");
#endif
};

//
//
// Wall Weapons
//
//

//
// Test_WallWeapons_Message()
// Asserts a written message field gets removed
// from a buy_weapon()
//
void() Test_WallWeapons_Message =
{
    entity weapon = spawn();
    entity old_self = self;
    self = weapon;

    self.message = "test";

    buy_weapon();

    Test_Assert((self.message == ""), "Message field was not removed!");

    self = old_self;
    remove(weapon);
};

//
// Test_WallWeapons_ActivatesAllTargets()
// Validates that when a buy_weapon entity
// uses its targets, all 8 are activated.
// (https://github.com/nzp-team/nzportable/issues/961)
//
void() Test_WallWeapons_ActivatesAllTargets =
{
    float i;

    entity weapon = spawn();
    entity old_self = self;
    entity targets[8];

    for (i = 0; i < 8; i++) {
        targets[i] = spawn();
        targets[i].health = 2;
        targets[i].targetname = sprintf("test_target_%d", i);

        self = targets[i];
        game_counter();
    }

    self = weapon;
    self.target  = "test_target_0";
    self.target2 = "test_target_1";
    self.target3 = "test_target_2";
    self.target4 = "test_target_3";
    self.target5 = "test_target_4";
    self.target6 = "test_target_5";
    self.target7 = "test_target_6";
    self.target8 = "test_target_7";
    buy_weapon();
    SUB_UseTargets();

    for(i = 0; i < 8; i++) {
        Test_Assert((targets[i].frags == 1), sprintf("Target #%d did not increment!", i));
        remove(targets[i]);
    }

    self = old_self;
    remove(weapon);
};
