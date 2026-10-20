/*
	server/tests/test_func_button.qc

	Unit tests for func_button explosion damage and weapon restrictions

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

void(string projectile, float button_health, float weapon_mask, float should_fire, optional float attacker_weapon) Test_ButtonExplosion =
{
    entity old_self = self;
    entity button = spawn();
    self = button;
    self.health = button_health;
    self.weapon = weapon_mask;
    setorigin(button, '100000 0 0');
    func_button();
    setsize(button, '-8 -8 -8', '8 8 8');

    entity shooter = spawn();
    shooter.weapons[0].weapon_id = attacker_weapon ? attacker_weapon : W_COLT;

    entity grenade = spawn();
    grenade.classname = projectile;
    setorigin(grenade, button.origin);
    self = grenade;
    DamgageExplode(grenade, shooter, 100, 10, 64);

    Test_Assert(button.health == button_health, "Explosion did not preserve/reset button health!");
    Test_Assert(button.state == (should_fire ? STATE_UP : STATE_BOTTOM), "Explosion did not honor button damage eligibility!");
    if (button_health == 0)
        Test_Assert(button.touch == button_touch, "Explosion changed a touch button's callback!");
    else
        Test_Assert(button.takedamage == (should_fire ? DAMAGE_NO : DAMAGE_YES), "Explosion did not preserve/reset button damage state!");
    Test_Assert(self == grenade, "Explosion did not restore self!");

    self = old_self;
    remove(grenade);
    remove(shooter);
    remove(button);
};

//
// Test_func_button_ExplosionWithoutHealth()
// Verifies Explosions near buttons without health do not
// try to call a bad th_die callback.
//
void() Test_func_button_ExplosionWithoutHealth =
{
    Test_ButtonExplosion("grenade", 0, 0, false);
    Test_ButtonExplosion("rocket", 0, 0, false);
    Test_ButtonExplosion("projectile_grenade", 0, 0, false);
    Test_ButtonExplosion("projectile_raybeam", 0, 0, false);
};

//
// Test_func_button_ExplosionWithHealth()
// Every supported explosive projectile should activate an unrestricted
// shootable button and reset its health through button_killed().
//
void() Test_func_button_ExplosionWithHealth =
{
    Test_ButtonExplosion("grenade", 10, 0, true);
    Test_ButtonExplosion("rocket", 10, 0, true);
    Test_ButtonExplosion("projectile_grenade", 10, 0, true);
    Test_ButtonExplosion("projectile_raybeam", 10, 0, true);
};

//
// Test_func_button_ExplosionWeaponRestrictions()
// Bullet, fire, electric, and melee restrictions must reject both ordinary
// explosions and raygun splash damage.
//
void() Test_func_button_ExplosionWeaponRestrictions =
{
    float masks[] = { FUNC_ALLOW_BULLET, FUNC_ALLOW_FIRE, FUNC_ALLOW_ELECTRIC, FUNC_ALLOW_MELEE };
    for (int i = 0; i < masks.length; i++) {
        Test_ButtonExplosion("grenade", 10, masks[i], false);
        Test_ButtonExplosion("rocket", 10, masks[i], false);
        Test_ButtonExplosion("projectile_grenade", 10, masks[i], false);
        Test_ButtonExplosion("projectile_raybeam", 10, masks[i], false);
    }
};

//
// Test_func_button_ExplosionExplosiveRestriction()
// Explosive-only buttons accept grenades and rockets while rejecting raygun
// splash damage, which has its own damage permission.
//
void() Test_func_button_ExplosionExplosiveRestriction =
{
    Test_ButtonExplosion("grenade", 10, FUNC_ALLOW_EXPLOSIVE, true);
    Test_ButtonExplosion("rocket", 10, FUNC_ALLOW_EXPLOSIVE, true);
    Test_ButtonExplosion("projectile_grenade", 10, FUNC_ALLOW_EXPLOSIVE, true);
    Test_ButtonExplosion("projectile_raybeam", 10, FUNC_ALLOW_EXPLOSIVE, false);
};

//
// Test_func_button_ExplosionRayRestriction()
// Ray-only buttons accept raygun splash damage while rejecting grenades,
// rockets, and grenade-launcher projectiles.
//
void() Test_func_button_ExplosionRayRestriction =
{
    Test_ButtonExplosion("grenade", 10, FUNC_ALLOW_RAY, false);
    Test_ButtonExplosion("rocket", 10, FUNC_ALLOW_RAY, false);
    Test_ButtonExplosion("projectile_grenade", 10, FUNC_ALLOW_RAY, false);
    Test_ButtonExplosion("projectile_raybeam", 10, FUNC_ALLOW_RAY, true);
};

//
// Test_func_button_ExplosionCombinedRestrictions()
// Combining explosive and ray permissions permits both categories of splash
// damage, including when an unrelated permission is present in the mask.
//
void() Test_func_button_ExplosionCombinedRestrictions =
{
    float mask = FUNC_ALLOW_EXPLOSIVE | FUNC_ALLOW_RAY | FUNC_ALLOW_MELEE;
    Test_ButtonExplosion("grenade", 10, mask, true);
    Test_ButtonExplosion("rocket", 10, mask, true);
    Test_ButtonExplosion("projectile_grenade", 10, mask, true);
    Test_ButtonExplosion("projectile_raybeam", 10, mask, true);
};

//
// Test_func_button_ExplosionUpgradeRestriction()
// Upgrade-only buttons accept splash damage only from upgraded weapons.
// Combining upgrade with a damage permission must require both conditions.
//
void() Test_func_button_ExplosionUpgradeRestriction =
{
    Test_ButtonExplosion("grenade", 10, FUNC_ALLOW_UPGRADE, false, W_COLT);
    Test_ButtonExplosion("grenade", 10, FUNC_ALLOW_UPGRADE, true, W_BIATCH);
    Test_ButtonExplosion("projectile_raybeam", 10, FUNC_ALLOW_UPGRADE, false, W_RAY);
    Test_ButtonExplosion("projectile_raybeam", 10, FUNC_ALLOW_UPGRADE, true, W_PORTER);

    float mask = FUNC_ALLOW_UPGRADE | FUNC_ALLOW_EXPLOSIVE;
    Test_ButtonExplosion("grenade", 10, mask, false, W_COLT);
    Test_ButtonExplosion("grenade", 10, mask, true, W_BIATCH);
    Test_ButtonExplosion("projectile_raybeam", 10, mask, false, W_PORTER);

    mask = FUNC_ALLOW_UPGRADE | FUNC_ALLOW_RAY;
    Test_ButtonExplosion("projectile_raybeam", 10, mask, false, W_RAY);
    Test_ButtonExplosion("projectile_raybeam", 10, mask, true, W_PORTER);
    Test_ButtonExplosion("grenade", 10, mask, false, W_BIATCH);
};

//
// Test_func_button_WeaponPermissionTypes()
// Each damage-type permission accepts its matching attack and rejects every
// other category, covering the non-explosive permissions directly as well.
//
void() Test_func_button_WeaponPermissionTypes =
{
    entity button = spawn();
    entity shooter = spawn();
    shooter.weapons[0].weapon_id = W_COLT;
    float masks[] = { FUNC_ALLOW_BULLET, FUNC_ALLOW_EXPLOSIVE, FUNC_ALLOW_FIRE, FUNC_ALLOW_RAY, FUNC_ALLOW_ELECTRIC, FUNC_ALLOW_MELEE };

    for (int i = 0; i < masks.length; i++) {
        button.weapon = masks[i];
        for (int j = 0; j < masks.length; j++)
            Test_Assert(Damage_ElligibleWeaponForBrushDamage(masks[j], button, shooter) == (i == j),
                sprintf("Weapon permission %d incorrectly handled damage type %d!", masks[i], masks[j]));
    }

    remove(shooter);
    remove(button);
};
