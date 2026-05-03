/*
	server/tests/test_score.qc

	Unit tests for score system

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
// Test_AddScore_NonClient()
// Attempts to give points to a non-client.
// (https://github.com/nzp-team/nzportable/issues/783)
//
void() Test_AddScore_NonClient =
{
    entity some_ent = spawn();
    Player_AddScore(some_ent, 10, false);
    remove(some_ent);
};

//
// Test_AddScore_DamageTypes()
// Asserts we are giving correct amount
// of score for every AI damage type.
// (https://github.com/nzp-team/nzportable/issues/776)
//
void() Test_AddScore_DamageTypes =
{
    float styles[] = {    
        DMG_TYPE_HEADSHOT, 
        DMG_TYPE_MELEE, 
        DMG_TYPE_TESLA, 
        DMG_TYPE_FLAMETHROWER, 
        DMG_TYPE_GRENADE, 
        DMG_TYPE_EXPLOSIVE,
        DMG_TYPE_LOWERTORSO,
        DMG_TYPE_UPPERTORSO,
        DMG_TYPE_FLOPPER
    };

    float scores[] = {
        DMG_SCORE_HEADSHOT,
        DMG_SCORE_MELEE,
        DMG_SCORE_GRENADE,
        DMG_SCORE_GRENADE,
        DMG_SCORE_GRENADE,
        DMG_SCORE_EXPLOSIVE,
        DMG_SCORE_LOWERTORSO,
        DMG_SCORE_UPPERTORSO,
        DMG_SCORE_FLOPPER
    };

    for (float i = 0; i < styles.length; i++) {
        float score_pre = self.points;

        DieHandler(self, styles[i]);

        float score_post = self.points;
        float score_delta = score_post - score_pre;

        Test_Assert((score_delta == scores[i]), sprintf("Unexpected score earned, expected [%d] but got [%d]!", scores[i], score_delta));
    }
};

//
// Test_AddScore_MysteryBoxLeave()
// Asserts we get exact amount of points
// back when the Mystery Box attempts
// to leave.
// (https://github.com/nzp-team/nzportable/issues/775)
//
void() Test_AddScore_MysteryBoxLeave =
{
    precache_sound("sounds/misc/giggle.wav");
    
    float score_pre = self.points;

    entity mystery_box_ent = spawn();
    entity owner_ent = spawn();
    entity old_self = self;

    self = mystery_box_ent;
    mystery_box();
    self.owner = owner_ent;
    self.owner.owner = old_self;
    MBOX_PresentTeddy();
    self = old_self;

    float score_post = self.points;
    Test_Assert((score_post - score_pre == mystery_box_cost), "Unexpected points earned!");

    remove(mystery_box_ent);
    remove(owner_ent);
};


//
// Test_AddScore_PhD_GunGame()
// Asserts we are giving correct amount
// of score for PhD Flopper in gun game
// Should return 0
// (https://github.com/nzp-team/nzportable/issues/1363)
//
void() Test_AddScore_PhD_GunGame =
{
    float score_pre = self.points;

    Gamemode_GunGame_DieHandler(self, DMG_TYPE_FLOPPER);

    float score_post = self.points;
    float score_delta = score_post - score_pre;

    

    Test_Assert((score_delta == 0), sprintf("Unexpected score earned, expected 0 but got [%d]!", score_delta));
};

//
// Test_AddScore_PhD_Festive()
// Asserts we are giving correct amount
// of score for PhD Flopper in Festive
// Should return 90
// (https://github.com/nzp-team/nzportable/issues/1363)
//
void() Test_AddScore_PhD_Festive =
{
    float pointsEarned = Gamemode_Festive_ScoreForDamage(DMG_SCORE_FLOPPER, DMG_TYPE_FLOPPER);

    Test_Assert((pointsEarned == 90), sprintf("Unexpected score earned, expected 90 but got [%d]!", pointsEarned));
};