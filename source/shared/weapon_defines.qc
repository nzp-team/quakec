/*
	shared/weapon_defines.qc

	all weapon stats are stored here

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

string(float wep) GetWeaponName =
{

	switch (wep)
	{
		case W_COLT:
			return "Colt M1911";
		case W_BIATCH:
      		return "Mustang & Sally";
		case W_KAR:
			return "Kar 98k";
    	case W_ARMAGEDDON:
			return "Armageddon";
		case W_THOMPSON:
			return "Thompson";
		case W_GIBS:
			return "Gibs-O-Matic";
		case W_357:
			return ".357 Magnum";
		case W_KILLU:
			return ".357 Plus 1 K1L-u";
		case W_BAR:
			return "BAR";
		case W_WIDOW:
			return "The Widow Maker";
		case W_BK:
			return "Ballistic Knife";
		case W_KRAUS:
			return "The Krauss Refibrillator";
		case W_BROWNING:
			return "Browning M1919";
		case W_ACCELERATOR:
			return "B115 Accelerator";
		case W_DB:
			return "Double-Barreled Shotgun";
		case W_BORE:
			return "24 Bore Long Range";
		case W_FG:
			return "FG42";
		case W_IMPELLER:
			return "420 Impeller";
		case W_GEWEHR:
			return "Gewehr 43";
		case W_COMPRESSOR:
			return "G115 Compressor";
		case W_KAR_SCOPE:
			return "Scoped Kar 98k";
		case W_HEADCRACKER:
			return "Headcracker";
		case W_M1:
			return "M1 Garand";
		case W_M1000:
			return "M1000";
		case W_M1A1:
			return "M1A1 Carbine";
		case W_WIDDER:
			return "Widdershins RC-1";
		case W_M2:
			return "M2 Flamethrower";
		case W_FIW:
			return "F1W Nitrogen Cooled";
		case W_MP40:
			return "MP40";
		case W_AFTERBURNER:
			return "The Afterburner";
		case W_MP5K:
			return "MP5K";
		case W_KOLLIDER:
			return "MP115 Kollider";
		case W_MG:
			return "MG42";
		case W_BARRACUDA:
			return "Barracuda FU-A11";
		case W_PANZER:
			return "Panzerschrek";
		case W_LONGINUS:
			return "Longinus";
		case W_PPSH:
			return "PPSh-41";
		case W_REAPER:
			return "The Reaper";
		case W_PTRS:
			return "PTRS-41";
		case W_PENETRATOR:
			return "The Penetrator";
		case W_RAY:
			return "Ray Gun";
		case W_PORTER:
			return "Porter's X2 Ray Gun";
		case W_SAWNOFF:
			return "Sawed-Off Shotgun";
		case W_SNUFF:
			return "The Snuff Box";
		case W_STG:
			return "STG-44";
		case W_SPATZ:
			return "Spatz-447 +";
		case W_TRENCH:
			return "M1897 Trench Gun";
		case W_GUT:
			return "Gut Shot";
		case W_TYPE:
			return "Type 100";
		case W_SAMURAI:
			return "1001 Samurais";
		case W_BOWIE:
			return "Bowie Knife";
		case W_GRENADE:
			return "Grenades";
		case W_BETTY:
			return "Bouncing Betty";
    	case W_TESLA:
      		return "Wunderwaffe DG-2";
		case W_DG3:
			return "Wunderwaffe DG-3 JZ";
		case W_SPRING:
			return "Springfield";
		case W_PULVERIZER:
			return "Pulverizer";
		default:
			return " ";
	}
}

string(float perk) GetPerkName =
{
	switch (perk)
	{
		case 1:
			return "Quick Revive";
		case 2:
			return "Juggernog";
		case 3:
			return "Speed Cola";
		case 4:
			return "Double Tap";
		case 5:
			return "Stamin-Up";
		case 6:
			return "PhD Flopper";
		case 7:
			return "Deadshot Daiquiri";
		case 8:
			return "Mule Kick";
		default:
			return "NULL";
	}
}

float(float wep) GetFiretype =
{

	switch (wep)
	{
		case W_COLT:
			return FIRETYPE_SEMIAUTO;
		case W_BIATCH:
			return FIRETYPE_GRENADE;
		case W_KAR:
			return FIRETYPE_SEMIAUTO;
    	case W_ARMAGEDDON:
			return FIRETYPE_SEMIAUTO;
		case W_SPRING:
			return FIRETYPE_SEMIAUTO;
    	case W_PULVERIZER:
			return FIRETYPE_SEMIAUTO;
		case W_THOMPSON:
		case W_GIBS:
			return FIRETYPE_FULLAUTO;
		case W_357:
		case W_KILLU:
			return FIRETYPE_SEMIAUTO;
		case W_BAR:
		case W_WIDOW:
			return FIRETYPE_FULLAUTO;
		case W_BROWNING:
		case W_ACCELERATOR:
			return FIRETYPE_FULLAUTO;
		case W_DB:
		case W_BORE:
			return FIRETYPE_SEMIAUTO;
		case W_FG:
		case W_IMPELLER:
			return FIRETYPE_FULLAUTO;
		case W_GEWEHR:
		case W_COMPRESSOR:
			return FIRETYPE_SEMIAUTO;
		case W_KAR_SCOPE:
			return FIRETYPE_SEMIAUTO;
		case W_HEADCRACKER:
			return FIRETYPE_FULLAUTO;
		case W_M1:
		case W_M1000:
			return FIRETYPE_SEMIAUTO;
		case W_M1A1:
			return FIRETYPE_SEMIAUTO;
		case W_WIDDER:
			return FIRETYPE_FULLAUTO;
		case W_M2:
		case W_FIW:
			return FIRETYPE_FLAME;
		case W_MP40:
		case W_AFTERBURNER:
			return FIRETYPE_FULLAUTO;
		case W_MP5K:
		case W_KOLLIDER:
			return FIRETYPE_FULLAUTO;
		case W_MG:
		case W_BARRACUDA:
			return FIRETYPE_FULLAUTO;
		case W_PANZER:
		case W_LONGINUS:
			return FIRETYPE_ROCKET;
		case W_PPSH:
		case W_REAPER:
			return FIRETYPE_FULLAUTO;
		case W_PTRS:
		case W_PENETRATOR:
			return FIRETYPE_FULLAUTO;
		case W_RAY:
		case W_PORTER:
			return FIRETYPE_RAYBEAM;
		case W_SAWNOFF:
		case W_SNUFF:
			return FIRETYPE_SEMIAUTO;
		case W_STG:
		case W_SPATZ:
			return FIRETYPE_FULLAUTO;
		case W_TRENCH:
		case W_GUT:
			return FIRETYPE_SEMIAUTO;
		case W_TYPE:
		case W_SAMURAI:
			return FIRETYPE_FULLAUTO;
		case W_TESLA:
		case W_DG3:
			return FIRETYPE_TESLA;
    }

    return 0;
}

#define	HEAD_X			0
#define	UPPER_TORSO_X	1
#define	LOWER_TORSO_X	2
#define	LIMBS_X			3

float(float wep, float type) getWeaponMultiplier =
{

	switch (wep)
	{
		case W_COLT:
			switch (type)
			{
				case HEAD_X: 		return 3;
				case UPPER_TORSO_X: return 1;
				case LOWER_TORSO_X: return 0.8;
				case LIMBS_X: 		return 0.8;
			}
			break;
		case W_KAR:
			switch (type)
			{
				case HEAD_X: 		return 3.5;
				case UPPER_TORSO_X:	return 1.8;
				case LOWER_TORSO_X:	return 1.7;
				case LIMBS_X: 		return 0.7;
			}
			break;
		case W_ARMAGEDDON:
			switch (type)
			{
				case HEAD_X: 		return 10;
				case UPPER_TORSO_X:	return 6;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_SPRING:
			switch (type)
			{
				case HEAD_X: 		return 2;
				case UPPER_TORSO_X:	return 1.2;
				case LOWER_TORSO_X:	return 0.9;
				case LIMBS_X: 		return 0.8;
			}
			break;
		case W_PULVERIZER:
			switch (type)
			{
				case HEAD_X: 		return 8;
				case UPPER_TORSO_X:	return 5;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_THOMPSON:
			switch (type)
			{
				case HEAD_X: 		return 4;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_GIBS:
			switch (type)
			{
				case HEAD_X: 		return 5;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_357:
			switch (type)
			{
				case HEAD_X: 		return 1.5;
				case UPPER_TORSO_X:	return 1.1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_KILLU:
			switch (type)
			{
				case HEAD_X: 		return 3;
				case UPPER_TORSO_X:	return 1.5;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_BAR:
		case W_WIDOW:
			switch (type)
			{
				case HEAD_X: 		return 2.7;
				case UPPER_TORSO_X:	return 1.8;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1.5;
			}
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			switch (type)
			{
				case HEAD_X: 		return 3;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_FG:
		case W_IMPELLER:
			switch (type)
			{
				case HEAD_X: 		return 2.7;
				case UPPER_TORSO_X:	return 2;
				case LOWER_TORSO_X:	return 1.5;
				case LIMBS_X: 		return 1.5;
			}
			break;
		case W_GEWEHR:
			switch (type)
			{
				case HEAD_X: 		return 2.7;
				case UPPER_TORSO_X:	return 1.25;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_COMPRESSOR:
			switch (type)
			{
				case HEAD_X: 		return 6;
				case UPPER_TORSO_X:	return 2;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			switch (type)
			{
				case HEAD_X: 		return 10;
				case UPPER_TORSO_X:	return 1.5;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_M1:
			switch (type)
			{
				case HEAD_X: 		return 2.7;
				case UPPER_TORSO_X:	return 1.25;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 0.7;
			}
			break;
		case W_M1000:
			switch (type)
			{
				case HEAD_X: 		return 6;
				case UPPER_TORSO_X:	return 2;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_M1A1:
			switch (type)
			{
				case HEAD_X: 		return 2.7;
				case UPPER_TORSO_X:	return 1.25;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 0.7;
			}
			break;
		case W_WIDDER:
			switch (type)
			{
				case HEAD_X: 		return 6;
				case UPPER_TORSO_X:	return 2;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_MP40:
			switch (type)
			{
				case HEAD_X: 		return 4;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_AFTERBURNER:
			switch (type)
			{
				case HEAD_X: 		return 5;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_MP5K:
			switch (type)
			{
				case HEAD_X: 		return 4;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_KOLLIDER:
			switch (type)
			{
				case HEAD_X: 		return 5;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_MG:
		case W_BARRACUDA:
			switch (type)
			{
				case HEAD_X: 		return 3;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_PPSH:
		case W_REAPER:
			switch (type)
			{
				case HEAD_X: 		return 4;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_PTRS:
			switch (type)
			{
				case HEAD_X: 		return 3;
				case UPPER_TORSO_X:	return 2.25;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_PENETRATOR:
			switch (type)
			{
				case HEAD_X: 		return 3;
				case UPPER_TORSO_X:	return 3;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_STG:
			switch (type)
			{
				case HEAD_X: 		return 4;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 0.8;
			}
			break;
		case W_SPATZ:
			switch (type)
			{
				case HEAD_X: 		return 5;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 0.8;
			}
			break;
		case W_TYPE:
			switch (type)
			{
				case HEAD_X: 		return 4;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_SAMURAI:
			switch (type)
			{
				case HEAD_X: 		return 5.5;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
		case W_BK:
		case W_KRAUS:
			switch (type)
			{
				case HEAD_X:		return 2;
				case UPPER_TORSO_X:	return 1;
				case LOWER_TORSO_X:	return 1;
				case LIMBS_X: 		return 1;
			}
			break;
	}
	return 1;
}

float(float wep) getWeaponMag =
{

	switch (wep)
	{
		case W_COLT:
			return 8;
		case W_BIATCH:
			return 6;
		case W_KAR:
			return 5;
    	case W_ARMAGEDDON:
			return 8;
		case W_SPRING:
			return 5;
    	case W_PULVERIZER:
			return 8;
		case W_THOMPSON:
			return 20;
		case W_GIBS:
			return 40;
		case W_357:
		case W_KILLU:
			return 6;
		case W_BAR:
			return 20;
		case W_WIDOW:
			return 30;
		case W_BROWNING:
			return 125;
		case W_ACCELERATOR:
			return 125;
		case W_DB:
		case W_BORE:
		case W_SAWNOFF:
		case W_SNUFF:
			return 2;
		case W_FG:
			return 32;
		case W_IMPELLER:
			return 64;
		case W_GEWEHR:
			return 12;
		case W_COMPRESSOR:
			return 10;
		case W_KAR_SCOPE:
			return 5;
		case W_HEADCRACKER:
			return 10;
		case W_M1:
			return 8;
		case W_M1000:
			return 12;
		case W_M1A1:
			return 15;
		case W_WIDDER:
			return 15;
		case W_M2:
			return 200;
		case W_FIW:
			return 400;
		case W_MP40:
			return 32;
		case W_AFTERBURNER:
			return 64;
		case W_MP5K:
			return 30;
		case W_KOLLIDER:
			return 40;
		case W_MG:
			return 125;
		case W_BARRACUDA:
			return 125;
		case W_PANZER:
			return 1;
		case W_LONGINUS:
			return 3;
		case W_PPSH:
			return 71;
		case W_REAPER:
			return 115;
		case W_PTRS:
			return 5;
		case W_PENETRATOR:
			return 8;
		case W_RAY:
			return 20;
		case W_PORTER:
			return 40;
		case W_STG:
			return 30;
		case W_SPATZ:
			return 60;
		case W_TRENCH:
			return 6;
		case W_GUT:
			return 10;
		case W_TYPE:
			return 30;
		case W_SAMURAI:
			return 60;
		case W_TESLA:
			return 3;
		case W_DG3:
			return 6;
		case W_BK:
		case W_KRAUS:
			return 1;
	}
	return 0;
}

float(float wep) getWeaponAmmo =
{

	switch (wep)
	{
		case W_COLT:
			return 80;
		case W_BIATCH:
			return 50;
		case W_KAR:
			return 50;
    	case W_ARMAGEDDON:
			return 60;
		case W_SPRING:
			return 50;
    	case W_PULVERIZER:
			return 60;
		case W_THOMPSON:
			return 200;
		case W_GIBS:
			return 250;
		case W_357:
		case W_KILLU:
			return 80;
		case W_BAR:
			return 140;
		case W_WIDOW:
			return 180;
		case W_BROWNING:
			return 500;
		case W_ACCELERATOR:
			return 750;
		case W_DB:
		case W_SAWNOFF:
		case W_BORE:
			return 60;
		case W_FG:
			return 192;
		case W_IMPELLER:
			return 400;
		case W_GEWEHR:
			return 120;
		case W_COMPRESSOR:
			return 170;
		case W_KAR_SCOPE:
			return 50;
		case W_HEADCRACKER:
			return 100;
		case W_M1:
			return 128;
		case W_M1000:
			return 150;
		case W_M1A1:
			return 120;
		case W_WIDDER:
			return 150;
		case W_M2:
		case W_FIW:
      		return 0;
		case W_MP40:
			return 192;
		case W_AFTERBURNER:
			return 192;
		case W_MP5K:
			return 120;
		case W_KOLLIDER:
			return 200;
		case W_MG:
			return 500;
		case W_BARRACUDA:
			return 750;
		case W_PANZER:
			return 20;
		case W_LONGINUS:
			return 30;
		case W_PPSH:
			return 355;
		case W_REAPER:
			return 700;
		case W_PTRS:
			return 60;
		case W_PENETRATOR:
			return 60;
		case W_RAY:
			return 160;
		case W_PORTER:
			return 200;
		case W_SNUFF:
			return 60;
		case W_STG:
			return 180;
		case W_SPATZ:
			return 300;
		case W_TRENCH:
			return 60;
		case W_GUT:
			return 60;
		case W_TYPE:
			return 160;
		case W_SAMURAI:
			return 220;
		case W_TESLA:
			return 15;
		case W_DG3:
			return 30;
		case W_BK:
			return 4;
		case W_KRAUS:
			return 9;
	}
	return 0;
}


float(float wep) getWeaponDamage =
{

	switch (wep)
	{
		case W_COLT:
			return 20;
		case W_BIATCH:
			return 1000;
		case W_KAR:
			return 100;
		case W_ARMAGEDDON:
			return 200;
		case W_SPRING:
			return 105;
		case W_PULVERIZER:
			return 210;
		case W_THOMPSON:
			return 120;
		case W_GIBS:
			return 200;
		case W_357:
		case W_KILLU:
			return 1000;
		case W_BAR:
			return 100;
		case W_WIDOW:
			return 200;
		case W_BROWNING:
		case W_ACCELERATOR:
			return 130;
		case W_DB:
		case W_SAWNOFF:
			return 200;
		case W_BORE:
			return 380;
		case W_FG:
			return 100;
		case W_IMPELLER:
			return 110;
		case W_GEWEHR:
			return 90;
		case W_COMPRESSOR:
			return 200;
		case W_KAR_SCOPE:
			return 800;
		case W_HEADCRACKER:
			return 1000;
		case W_M1:
			return 105;
		case W_M1000:
			return 200;
		case W_M1A1:
			return 120;
		case W_WIDDER:
			return 200;
		case W_MP40:
			return 100;
		case W_AFTERBURNER:
			return 200;
		case W_MP5K:
			return 100;
		case W_KOLLIDER:
			return 140;
		case W_MG:
		case W_BARRACUDA:
			return 130;
		case W_PANZER:
			return 600;
		case W_LONGINUS:
			return 1000;
		case W_PPSH:
			return 100;
		case W_REAPER:
			return 150;
		case W_PTRS:
		case W_PENETRATOR:
			return 1000;
		case W_RAY:
			return 1000;
		case W_PORTER:
			return 1000;
		case W_SNUFF:
			return 240;
		case W_STG:
			return 100;
		case W_SPATZ:
			return 150;
		case W_TRENCH:
			return 160;
		case W_GUT:
			return 240;
		case W_TYPE:
			return 100;
		case W_SAMURAI:
			return 200;
		case W_BK:
			return 500;
		case W_KRAUS:
			return 1000;
    }

    return 0;
}

float(float wep) GetWeaponShotcount =
{

	switch(wep)
	{
		case W_DB:
			return 8;
		case W_BORE:
			return 10;
		case W_SAWNOFF:
		case W_SNUFF:
			return 8;
		case W_TRENCH:
			return 8;
		case W_GUT:
			return 10;
	}

    return 1;
}

float(float wep, float penetration_times) getWeaponPenetration =
{
	if (!penetration_times)
		return 2;

	switch (wep)
	{
		case W_COLT:
		case W_BIATCH:
			if (penetration_times >= 2)
				return 0;
			return 0.75;
		case W_KAR:
		case W_ARMAGEDDON:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_SPRING:
		case W_PULVERIZER:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_THOMPSON:
		case W_GIBS:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		case W_357:
		case W_KILLU:
			if (penetration_times >= 3)
				return 0;
		case W_BAR:
		case W_WIDOW:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_BROWNING:
		case W_ACCELERATOR:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_DB:
		case W_BORE:
		case W_SAWNOFF:
		case W_SNUFF:
			if (penetration_times >= 3)
				return 0;
			return 0.5;
		case W_FG:
		case W_IMPELLER:
			if (penetration_times >= 2)
				return 0;
			return 0.9;
		case W_GEWEHR:
		case W_COMPRESSOR:
			if (penetration_times >= 2)
				return 0;
			return 0.9;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_M1:
		case W_M1000:
			if (penetration_times >= 2)
				return 0;
			return 0.9;
		case W_M1A1:
		case W_WIDDER:
			if (penetration_times >= 2)
				return 0;
			return 0.9;
		case W_MP40:
		case W_AFTERBURNER:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		case W_MP5K:
		case W_KOLLIDER:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		case W_MG:
		case W_BARRACUDA:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_PPSH:
		case W_REAPER:
			if (penetration_times >= 2)
				return 0;
			return 0.75;
		case W_PTRS:
			if (penetration_times >= 3)
				return 0;
			return 1;
		case W_PENETRATOR:
			if (penetration_times >= 5)
				return 0;
			return 1;
		case W_STG:
		case W_SPATZ:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		case W_TRENCH:
		case W_GUT:
			if (penetration_times >= 3)
				return 0;
			return 0.7;
		case W_TYPE:
		case W_SAMURAI:
			if (penetration_times >= 2)
				return 0;
			return 0.8;
		default:
			return 0;
    }
}

float(float wep, float delaytype) getWeaponDelay =
{

	switch (wep)
	{
		case W_COLT:
			if (delaytype == RELOAD)
				return 1.9;
			else if (delaytype == FIRE)
				return 0.100;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_BIATCH:
			if (delaytype == RELOAD)
				return 1.66;
			else if (delaytype == FIRE)
				return 0.225;
			else if (delaytype == PUTOUT)
				return 0.15;
			else if (delaytype == TAKEOUT)
				return 0.60;
    	case W_ARMAGEDDON:
		case W_KAR:
			if (delaytype == RELOAD)
				return 2.5;
			else if (delaytype == FIRE)
				return 0.3;
			else if (delaytype == PUTOUT)
				return 0.25;
			else if (delaytype == TAKEOUT)
				return 0.5;
    	case W_PULVERIZER:
		case W_SPRING:
			if (delaytype == RELOAD)
				return 2.25;
			else if (delaytype == FIRE)
				return 0.33;
			else if (delaytype == PUTOUT)
				return 0.45;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_THOMPSON:
		case W_GIBS:
			if (delaytype == RELOAD)
				return 2.1;
			else if (delaytype == FIRE) {
				if (wep == W_THOMPSON)
					return 0.085;
				return 0.07;
			}
			else if (delaytype == PUTOUT)
				return 0.5;
			else if (delaytype == TAKEOUT)
				return 0.35;
		case W_357:
		case W_KILLU:
			if (delaytype == RELOAD)
				return 3;
			else if (delaytype == FIRE)
				return 0.4;
			else if (delaytype == PUTOUT)
				return 0.6;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_BAR:
			if (delaytype == RELOAD)
				return 2.75;
			else if (delaytype == FIRE)
				return 0.17;
			else if (delaytype == PUTOUT)
				return 0.55;
			else if (delaytype == TAKEOUT)
				return 0.65;
		case W_WIDOW:
			if (delaytype == RELOAD)
				return 2.75;
			else if (delaytype == FIRE)
				return 0.11;
			else if (delaytype == PUTOUT)
				return 0.55;
			else if (delaytype == TAKEOUT)
				return 0.65;
		case W_BROWNING:
			if (delaytype == RELOAD_EMP)
				return 2;
			else if (delaytype == RELOAD_PAR)
				return 3;
			else if (delaytype == RELOAD)
				return 4.0;
			else if (delaytype == FIRE)
				return 0.104;
			else if (delaytype == PUTOUT)
				return 0.75;
			else if (delaytype == TAKEOUT)
				return 0.75;
		case W_ACCELERATOR:
			if (delaytype == RELOAD_EMP)
				return 2;
			if (delaytype == RELOAD_PAR)
				return 3;
			if (delaytype == RELOAD)
				return 4;
			else if (delaytype == FIRE)
				return 0.088;
			else if (delaytype == PUTOUT)
				return 0.75;
			else if (delaytype == TAKEOUT)
				return 0.75;
		case W_DB:
			if (delaytype == RELOAD)
				return 3;
			else if (delaytype == FIRE)
				return 0.5;
			else if (delaytype == PUTOUT)
				return 0.5;
			else if (delaytype == TAKEOUT)
				return 0.65;
		case W_BORE:
			if (delaytype == RELOAD)
				return 2.5;
			else if (delaytype == FIRE)
				return 0.5;
			else if (delaytype == PUTOUT)
				return 0.5;
			else if (delaytype == TAKEOUT)
				return 0.65;
		case W_FG:
			if (delaytype == RELOAD)
			  	return 2.75;
			else if (delaytype == FIRE)
				return 0.075;
			else if (delaytype == PUTOUT)
				return 0.45;
			else if (delaytype == TAKEOUT)
				return 0.6;
		case W_IMPELLER:
			if (delaytype == RELOAD)
			  	return 2.75;
			else if (delaytype == FIRE)
				return 0.068;
			else if (delaytype == PUTOUT)
				return 0.45;
			else if (delaytype == TAKEOUT)
				return 0.6;
		case W_GEWEHR:
		case W_COMPRESSOR:
			if (delaytype == RELOAD)
				return 3;
			else if (delaytype == FIRE)
				return 0.200;
			else if (delaytype == PUTOUT)
				return 0.9;
			else if (delaytype == TAKEOUT)
				return 0.65;
		case W_M1:
		case W_M1000:
			if (delaytype == RELOAD_EMP)
				return 0.4;
			if (delaytype == RELOAD_PAR)
				return 1.4;
			if (delaytype == RELOAD)
				return 1.4;
			else if (delaytype == FIRE)
				return 0.275;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.35;
		case W_M1A1:
			if (delaytype == RELOAD)
				return 2.9;
			else if (delaytype == FIRE)
				return 0.220;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.5;
		case W_WIDDER:
			if (delaytype == RELOAD)
				return 2.9;
			else if (delaytype == FIRE)
				return 0.150;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.5;
		case W_M2:
		case W_FIW:
			if (delaytype == RELOAD)
				return 2.7;
			else if (delaytype == FIRE)
				return 0.02;
			else if (delaytype == PUTOUT)
				return 0.3;
			else if (delaytype == TAKEOUT)
				return 0.5;
		case W_MP40:
			if (delaytype == RELOAD)
				return 2.3;
			else if (delaytype == FIRE)
				return 0.120;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_AFTERBURNER:
			if (delaytype == RELOAD)
				return 2.3;
			else if (delaytype == FIRE)
				return 0.110;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_MP5K:
			if (delaytype == RELOAD)
				return 3.2;
			else if (delaytype == FIRE)
				return 0.085;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_KOLLIDER:
			if (delaytype == RELOAD)
				return 3.2;
			else if (delaytype == FIRE)
				return 0.085;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_MG:
			if (delaytype == RELOAD)
				return 4.5;
			else if (delaytype == FIRE)
				return 0.065;
			else if (delaytype == PUTOUT)
				return 0.9;
			else if (delaytype == TAKEOUT)
				return 0.6;
		case W_BARRACUDA:
			if (delaytype == RELOAD)
				return 4.5;
			else if (delaytype == FIRE)
				return 0.045;
			else if (delaytype == PUTOUT)
				return 0.9;
			else if (delaytype == TAKEOUT)
				return 0.6;
		case W_PANZER:
		case W_LONGINUS:
			if (delaytype == RELOAD)
				return 2.85;
			else if (delaytype == FIRE)
				return 0.331;
			else if (delaytype == PUTOUT)
				return 0.45;
			else if (delaytype == TAKEOUT)
				return 0.4;
		case W_PPSH:
			if (delaytype == RELOAD)
				return 2.1;
			else if (delaytype == FIRE)
				return 0.05;
			else if (delaytype == PUTOUT)
				return 0.35;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_REAPER:
			if (delaytype == RELOAD)
				return 2.1;
			else if (delaytype == FIRE)
				return 0.04;
			else if (delaytype == PUTOUT)
				return 0.35;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_PTRS:
		case W_PENETRATOR:
			if (delaytype == RELOAD)
				return 4.5;
			else if (delaytype == FIRE)
				return 0.8;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.7;
		case W_RAY:
		case W_PORTER:
			if (delaytype == RELOAD)
				return 2.75;
			else if (delaytype == FIRE)
				return 0.35;
			else if (delaytype == PUTOUT)
				return 1.0;
			else if (delaytype == TAKEOUT)
				return 0.3;
		case W_SAWNOFF:
			if (delaytype == RELOAD)
				return 2.65;
			else if (delaytype == FIRE)
				return 0.283;
			else if (delaytype == PUTOUT)
				return 0.5;
			else if (delaytype == TAKEOUT)
				return 0.65;
		case W_SNUFF:
			if (delaytype == RELOAD)
				return 2;
			else if (delaytype == FIRE)
				return 0.283;
			else if (delaytype == PUTOUT)
				return 0.5;
			else if (delaytype == TAKEOUT)
				return 0.65;
		case W_STG:
			if (delaytype == RELOAD)
				return 2.15;
			else if (delaytype == FIRE)
				return 0.110;
			else if (delaytype == PUTOUT)
				return 0.55;
			else if (delaytype == TAKEOUT)
				return 0.5;
		case W_SPATZ:
			if (delaytype == RELOAD)
				return 2.15;
			else if (delaytype == FIRE)
				return 0.08;
			else if (delaytype == PUTOUT)
				return 0.55;
			else if (delaytype == TAKEOUT)
				return 0.5;
		case W_TRENCH:
		case W_GUT:
			if (delaytype == RELOAD)
				return 0.6;
			else if (delaytype == FIRE)
				return 0.283;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.6;
		case W_TYPE:
			if (delaytype == RELOAD)
				return 2.25;
			else if (delaytype == FIRE)
				return 0.09;
			else if (delaytype == PUTOUT)
				return 0.35;
			else if (delaytype == TAKEOUT)
				return 0.35;
		case W_SAMURAI:
			if (delaytype == RELOAD)
				return 2.25;
			else if (delaytype == FIRE)
				return 0.07;
			else if (delaytype == PUTOUT)
				return 0.35;
			else if (delaytype == TAKEOUT)
				return 0.35;
		case W_TESLA:
			if (delaytype == RELOAD)
				return 4;
			else if (delaytype == FIRE)
				return 1;
			else if (delaytype == PUTOUT)
				return 0.7;
			else if (delaytype == TAKEOUT)
				return 0.9;
			break;
		case W_DG3:
			if (delaytype == RELOAD)
				return 3.3;
			else if (delaytype == FIRE)
				return 1;
			else if (delaytype == PUTOUT)
				return 0.7;
			else if (delaytype == TAKEOUT)
				return 0.9;
			break;
		case W_BK:
		case W_KRAUS:
			if (delaytype == RELOAD)
				return 0.75;
			else if (delaytype == FIRE)
				return 0.8;
			else if (delaytype == PUTOUT)
				return 0.4;
			else if (delaytype == TAKEOUT)
				return 0.4;
			else if (delaytype == MELEE_NORMAL)
				return 0.4;
			else if (delaytype == MELEE_LUNGED)
				return 1.4;
			break;
    }

    return 0;
}

#define SPEED_MULTIPLIER_STANDARD 		1
#define SPEED_MULTIPLIER_RIFLE 			0.88
#define SPEED_MULTIPLIER_HEAVY 			0.75
#define SPEED_MULTIPLIER_ULTRAHEAVY		0.66

float GetWeaponWalkSpeed(float perks, float weapon)
{
	float speed_multiplier = 1;

	switch (weapon) {
		case W_COLT:
		case W_BIATCH:
		case W_MP40:
		case W_AFTERBURNER:
		case W_PPSH:
		case W_REAPER:
		case W_STG:
		case W_SPATZ:
		case W_THOMPSON:
		case W_GIBS:
		case W_TYPE:
		case W_SAMURAI:
		case W_DB:
		case W_BORE:
		case W_SAWNOFF:
		case W_SNUFF:
		case W_TRENCH:
		case W_GUT:
		case W_BAR:
		case W_WIDOW:
		case W_FG:
		case W_IMPELLER:
		case W_RAY:
		case W_PORTER:
		case W_TESLA:
		case W_DG3:
		case W_MP5K:
		case W_KOLLIDER:
		case W_BK:
		case W_KRAUS:
			speed_multiplier = SPEED_MULTIPLIER_STANDARD;
			break;
		case W_357:
		case W_KILLU:
		case W_KAR:
		case W_ARMAGEDDON:
		case W_SPRING:
		case W_PULVERIZER:
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
		case W_GEWEHR:
		case W_COMPRESSOR:
		case W_M1A1:
		case W_WIDDER:
		case W_M1:
		case W_M1000:
			speed_multiplier = SPEED_MULTIPLIER_RIFLE;
			break;
		case W_PTRS:
		case W_PENETRATOR:
		case W_BROWNING:
		case W_ACCELERATOR:
		case W_MG:
		case W_BARRACUDA:
		case W_PANZER:
		case W_LONGINUS:
			speed_multiplier = SPEED_MULTIPLIER_HEAVY;
			break;
		case W_M2:
		case W_FIW:
			speed_multiplier = SPEED_MULTIPLIER_ULTRAHEAVY;
			break;
		default:
			break;
	}

	if (perks & P_STAMIN)
		speed_multiplier *= 1.07;

	return speed_multiplier;
}

/*
===========================
Weapon PSP ADS Declarations
===========================
*/
// x: left/right
// y: up/down
// z: forward/back
vector GetWeaponADSOfs(float wep) = 
{
		
	switch(wep)
	{
		case W_COLT:
		case W_BIATCH:
			return [-5479.2, 1850, -4000];
		case W_KAR:
		case W_ARMAGEDDON:
			return [-5495.9, 3006.9, -6000];
		case W_SPRING:
		case W_PULVERIZER:
			return [-5295.9, 3206.9, -5000];
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			return [-5286, 706.1, 0];
		case W_THOMPSON:
		case W_GIBS:
			return [-6200.3, 3407.6, -800]; 
		case W_TRENCH:
		case W_GUT:
			return [-5527.1, 2580.3, -250];
		case W_M2:
		case W_FIW:
			return [-9006.5, 2779.2, 9900];
		case W_357:
		case W_KILLU:
			return [-8306.5, 1079.2, -6750];
		case W_MG:
		case W_BARRACUDA:
			return [-6843.7, 3509.2, -6000];
		case W_DB:
		case W_BORE:
		case W_SAWNOFF:
			return [-5801.7, 2612.1, 1250];
		case W_M1A1:
		case W_WIDDER:
			return [-5387.8, 3250.9, -4500];
		case W_BAR:
		case W_WIDOW:
			return [-3903.3, 2564.5, 0];
		case W_FG:
		case W_IMPELLER:
			return [-11798, 1800, -12000];
		case W_RAY:
		case W_PORTER:
			return [-12700, 2086.9, -1000];
		case W_GEWEHR:
		case W_COMPRESSOR:
			return [-5150, 5200, -2990];
		case W_PPSH:
		case W_REAPER:
			return [-7500, 3000, -500];
		case W_MP40:
		case W_AFTERBURNER:
			return [-11400, 6500, -1000];
		case W_MP5K:
		case W_KOLLIDER:
			return [-10400, 5500, -8000];
		case W_TYPE:
		case W_SAMURAI:
			return [-400, -200, 0];
		case W_STG:
		case W_SPATZ:
			return [-9834, 2920, -17000];
		case W_M1:
		case W_M1000:
			return [-7700, 2200, -4500];
		case W_BROWNING:
		case W_ACCELERATOR:
			return [-8000, 3020, -6500];
		case W_PTRS:
		case W_PENETRATOR:
			return [-7200, 906.9, 0];
		case W_PANZER:
		case W_LONGINUS:
			return [-7679.2, 2900, -20000];
		default: 
			//Large values > 20ish cause weapon to flicker, scale model down if we encounter!
			//Scale better be 4.3, or else viewbobbing is going to be inaccurate.
			return [-5.4792, 1.6500, 0];
	}
};

float(float wep, float frametype, optional float z) GetFrame =
{
	switch (wep)
	{
		case W_COLT:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 26;
				case SPRINT_IN_START:
					return 33;
				case SPRINT_IN_END:
					return 34;
				case SPRINT_START:
					return 35;
				case SPRINT_END:
					return 40;
				case SPRINT_OUT_START:
					return 41;
				case SPRINT_OUT_END:
					return 42;
				case TAKE_OUT_START:
					return 29;
				case TAKE_OUT_END:
					return 32;
				case PUT_OUT_START:
					return 26;
				case PUT_OUT_END:
					return 29;
				case RELOAD_CANCEL:
					return 13;
			}
			break;
		case W_BIATCH:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 20;
				case RELOAD_END:
					return 49;
				case SPRINT_IN_START:
					return 9;
				case SPRINT_IN_END:
					return 11;
				case SPRINT_START:
					return 12;
				case SPRINT_END:
					return 16;
				case SPRINT_OUT_START:
					return 17;
				case SPRINT_OUT_END:
					return 18;
				case TAKE_OUT_START:
					return 5;
				case TAKE_OUT_END:
					return 8;
				case PUT_OUT_START:
					return 3;
				case PUT_OUT_END:
					return 5;
				case RELOAD_CANCEL:
					return 30;
			}
			break;
		case W_KAR:
		case W_ARMAGEDDON:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 14;
				case RELOAD_END:
					return 28;
				case SPRINT_IN_START:
					return 29;
				case SPRINT_IN_END:
					return 30;
				case SPRINT_OUT_START:
					return 30;
				case SPRINT_OUT_END:
					return 29;
				case TAKE_OUT_START:
					return 33;
				case TAKE_OUT_END:
					return 35;
				case PUT_OUT_START:
					return 32;
				case PUT_OUT_END:
					return 33;
				case RELOAD_CANCEL:
					return 21;
			}	
			break;
		case W_SPRING:
		case W_PULVERIZER:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 14;
				case RELOAD_END:
					return 28;
				case SPRINT_IN_START:
					return 29;
				case SPRINT_IN_END:
					return 30;
				case SPRINT_OUT_START:
					return 30;
				case SPRINT_OUT_END:
					return 29;
				case TAKE_OUT_START:
					return 33;
				case TAKE_OUT_END:
					return 35;
				case PUT_OUT_START:
					return 32;
				case PUT_OUT_END:
					return 33;
				case RELOAD_CANCEL:
					return 21;
			}	
			break;
		case W_THOMPSON:
		case W_GIBS:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 25;
				case SPRINT_IN_START:
					return 26;
				case SPRINT_IN_END:
					return 27;
				case SPRINT_OUT_START:
					return 28;
				case SPRINT_OUT_END:
					return 29;
				case TAKE_OUT_START:
					return 32;
				case TAKE_OUT_END:
					return 35;
				case PUT_OUT_START:
					return 29;
				case PUT_OUT_END:
					return 32;
				case RELOAD_CANCEL:
					return 15;
			}
			break;
		case W_357:
		case W_KILLU:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 4;
				case RELOAD_END:
					return 25;
				case SPRINT_IN_START:
					return 32;
				case SPRINT_IN_END:
					return 33;
				case SPRINT_START:
					return 35;
				case SPRINT_END:
					return 40;
				case SPRINT_OUT_START:
					return 41;
				case SPRINT_OUT_END:
					return 42;
				case TAKE_OUT_START:
					return 29;
				case TAKE_OUT_END:
					return 31;
				case PUT_OUT_START:
					return 26;
				case PUT_OUT_END:
					return 28;
				case RELOAD_CANCEL:
					return 14;
			}
			break;
		case W_BAR:
		case W_WIDOW:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 36;
				case SPRINT_IN_START:
					return 37;
				case SPRINT_IN_END:
					return 38;
				case SPRINT_OUT_START:
					return 38;
				case SPRINT_OUT_END:
					return 37;
				case TAKE_OUT_START:
					return 41;
				case TAKE_OUT_END:
					return 39;
				case PUT_OUT_START:
					return 39;
				case PUT_OUT_END:
					return 41;
				case RELOAD_CANCEL:
					return 21;
			}
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_PART_START:
					return 4;
				case RELOAD_PART_END:
					return 24;
				case RELOAD_EMPTY_START:
					return 57;
				case RELOAD_EMPTY_END:
					return 72;
				case RELOAD_START:
					return 25;
				case RELOAD_END:
					return 54;
				case SPRINT_IN_START:
					return 75;
				case SPRINT_IN_END:
					return 76;
				case SPRINT_OUT_START:
					return 76;
				case SPRINT_OUT_END:
					return 77;
				case TAKE_OUT_START:
					return 79;
				case TAKE_OUT_END:
					return 81;
				case PUT_OUT_START:
					return 77;
				case PUT_OUT_END:
					return 79;
				case RELOAD_CANCEL:
					return 37;
			}
			break;
		case W_SAWNOFF:
		case W_DB:
		case W_BORE:
				switch (frametype)
				{
					case FIRE_START:
						return 1;
					case FIRE_END:
						return 4;
					case RELOAD_START:
						return 5;
					case RELOAD_END:
						return 31;
					case SPRINT_IN_START:
						return 32;
					case SPRINT_IN_END:
						return 33;
					case SPRINT_OUT_START:
						return 33;
					case SPRINT_OUT_END:
						return 31;
					case TAKE_OUT_START:
						return 38;
					case TAKE_OUT_END:
						return 41;
					case PUT_OUT_START:
						return 35;
					case PUT_OUT_END:
						return 37;
					case RELOAD_CANCEL:
						return 22;
				}
				break;
		case W_SNUFF:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 4;
				case RELOAD_START:
					return 5;
				case RELOAD_END:
					return 45;
				case SPRINT_IN_START:
					return 53;
				case SPRINT_IN_END:
					return 58;
				case SPRINT_OUT_START:
					return 33;
				case SPRINT_OUT_END:
					return 31;
				case TAKE_OUT_START:
					return 46;
				case TAKE_OUT_END:
					return 49;
				case PUT_OUT_START:
					return 59;
				case PUT_OUT_END:
					return 52;
				case RELOAD_CANCEL:
					return 34;
			}
			break;
		case W_FG:
		case W_IMPELLER:
			switch (frametype)
			{
				case FIRE_START:
					return 0;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 29;
				case SPRINT_IN_START:
					return 35;
				case SPRINT_IN_END:
					return 36;
				case SPRINT_OUT_START:
					return 36;
				case SPRINT_OUT_END:
					return 37;
				case TAKE_OUT_START:
					return 32;
				case TAKE_OUT_END:
					return 34;
				case PUT_OUT_START:
					return 30;
				case PUT_OUT_END:
					return 32;
				case RELOAD_CANCEL:
					return 15;
			}
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			switch (frametype)
			{
				case FIRE_START:
					return 2;
				case FIRE_END:
					return 4;
				case RELOAD_START:
					return 11;
				case RELOAD_END:
					return 52;
				case SPRINT_IN_START:
					return 55;
				case SPRINT_IN_END:
					return 57;
				case SPRINT_OUT_START:
					return 59;
				case SPRINT_OUT_END:
					return 61;
				case TAKE_OUT_START:
					return 75;
				case TAKE_OUT_END:
					return 83;
				case PUT_OUT_START:
					return 64;
				case PUT_OUT_END:
					return 71;
				case RELOAD_CANCEL:
					return 36;
			}
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
				switch (frametype)
				{
					case FIRE_START:
						return 1;
					case FIRE_END:
						return 3;
					case SPRINT_IN_START:
						return 36;
					case SPRINT_IN_END:
						return 37;
					case SPRINT_OUT_START:
						return 37;
					case SPRINT_OUT_END:
						return 36;
					case TAKE_OUT_START:
						return 33;
					case TAKE_OUT_END:
						return 35;
					case PUT_OUT_START:
						return 32;
					case PUT_OUT_END:
						return 33;
					case RELOAD_CANCEL:
						return 21;
				}
				break;
		case W_M1:
		case W_M1000:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_EMPTY_START:
					return 4;
				case RELOAD_EMPTY_END:
					return 10;
				case RELOAD_PART_START:
					return 21;
				case RELOAD_PART_END:
					return 30;
				case RELOAD_START:
					return 10;
				case RELOAD_END:
					return 20;
				case SPRINT_IN_START:
					return 32;
				case SPRINT_IN_END:
					return 33;
				case SPRINT_OUT_START:
					return 34;
				case SPRINT_OUT_END:
					return 35;
				case TAKE_OUT_START:
					return 40;
				case TAKE_OUT_END:
					return 43;
				case PUT_OUT_START:
					return 36;
				case PUT_OUT_END:
					return 39;
				case RELOAD_CANCEL:
					return 14;
			}
			break;
		case W_M1A1:
		case W_WIDDER:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 29;
				case SPRINT_IN_START:
					return 37;
				case SPRINT_IN_END:
					return 38;
				case SPRINT_OUT_START:
					return 38;
				case SPRINT_OUT_END:
					return 37;
				case TAKE_OUT_START:
					return 33;
				case TAKE_OUT_END:
					return 36;
				case PUT_OUT_START:
					return 30;
				case PUT_OUT_END:
					return 33;
				case RELOAD_CANCEL:
					return 17;
			}
			break;
		case W_FIW:
		case W_M2:
			switch (frametype)
			{
				case FIRE_HOLD:
					return 3;
				case SPRINT_IN_START:
					return 17;
				case SPRINT_IN_END:
					return 18;
				case SPRINT_OUT_START:
					return 18;
				case SPRINT_OUT_END:
					return 19;
				case FIRST_TAKE_START:
					return 6;
				case FIRST_TAKE_END:
					return 17;
				case TAKE_OUT_START:
					return 22;
				case TAKE_OUT_END:
					return 24;
				case PUT_OUT_START:
					return 20;
				case PUT_OUT_END:
					return 22;
				case RELOAD_CANCEL:
					return 0;
			}
			break;
		case W_MP40:
		case W_AFTERBURNER:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 4;
				case RELOAD_END:
					return 31;
				case SPRINT_IN_START:
					return 39;
				case SPRINT_IN_END:
					return 41;
				case SPRINT_OUT_START:
					return 42;
				case SPRINT_OUT_END:
					return 46;
				case TAKE_OUT_START:
					return 35;
				case TAKE_OUT_END:
					return 37;
				case PUT_OUT_START:
					return 32;
				case PUT_OUT_END:
					return 34;
				case RELOAD_CANCEL:
					return 18;
			}
			break;
		case W_MP5K:
		case W_KOLLIDER:
			switch (frametype)
			{
				case FIRE_START:
					return 2;
				case FIRE_END:
					return 4;
				case RELOAD_START:
					return 7;
				case RELOAD_END:
					return 50;
				case SPRINT_IN_START:
					return 62;
				case SPRINT_IN_END:
					return 64;
				case SPRINT_OUT_START:
					return 65;
				case SPRINT_OUT_END:
					return 67;
				case TAKE_OUT_START:
					return 56;
				case TAKE_OUT_END:
					return 59;
				case PUT_OUT_START:
					return 52;
				case PUT_OUT_END:
					return 55;
				case RELOAD_CANCEL:
					return 33;
			}
			break;
		case W_MG:
		case W_BARRACUDA:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 2;
				case RELOAD_START:
					return 3;
				case RELOAD_END:
					return 38;
				case SPRINT_IN_START:
					return 39;
				case SPRINT_IN_END:
					return 40;
				case SPRINT_OUT_START:
					return 40;
				case SPRINT_OUT_END:
					return 38;
				case TAKE_OUT_START:
					return 43;
				case TAKE_OUT_END:
					return 47;
				case PUT_OUT_START:
					return 42;
				case PUT_OUT_END:
					return 43;
				case RELOAD_CANCEL:
					return 21;
			}
			break;
		case W_PANZER:
		case W_LONGINUS:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 5;
				case RELOAD_START:
					return 6;
				case RELOAD_END:
					return 29;
				case SPRINT_IN_START:
					return 0;
				case SPRINT_IN_END:
					return 0;
				case SPRINT_OUT_START:
					return 0;
				case SPRINT_OUT_END:
					return 0;
				case TAKE_OUT_START:
					return 33;
				case TAKE_OUT_END:
					return 35;
				case PUT_OUT_START:
					return 31;
				case PUT_OUT_END:
					return 33;
				case RELOAD_CANCEL:
					return 18;
				case AIM_IN:
					return 2;
				case AIM_FIRE_START:
					return 3;
				case AIM_FIRE_END:
					return 5;
			}
			break;
		case W_PPSH:
		case W_REAPER:
			switch (frametype)
			{
				case FIRE_START:
					return 0;
				case FIRE_END:
					return 1;
				case RELOAD_START:
					return 5;
				case RELOAD_END:
					return 38;
				case SPRINT_IN_START:
					return 40;
				case SPRINT_IN_END:
					return 42;
				case SPRINT_OUT_START:
					return 43;
				case SPRINT_OUT_END:
					return 45;
				case TAKE_OUT_START:
					return 49;
				case TAKE_OUT_END:
					return 52;
				case PUT_OUT_START:
					return 46;
				case PUT_OUT_END:
					return 48;
				case RELOAD_CANCEL:
					return 22;
			}
			break;
		case W_PTRS:
		case W_PENETRATOR:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 4;
				case RELOAD_END:
					return 35;
				case SPRINT_IN_START:
					return 36;
				case SPRINT_IN_END:
					return 37;
				case SPRINT_OUT_START:
					return 37;
				case SPRINT_OUT_END:
					return 38;
				case TAKE_OUT_START:
					return 40;
				case TAKE_OUT_END:
					return 42;
				case PUT_OUT_START:
					return 38;
				case PUT_OUT_END:
					return 40;
				case RELOAD_CANCEL:
					return 21;
			}
			break;
    	case W_RAY:
    	case W_PORTER:
			switch (frametype)
			{
				case FIRE_START:
					return 2;
				case FIRE_END:
					return 5;
				case RELOAD_START:
					return 7;
				case RELOAD_END:
					return 49;
				case SPRINT_IN_START:
					return 56;
				case SPRINT_IN_END:
					return 59;
				case SPRINT_START:
					return 59;
				case SPRINT_END:
					return 66;
				case SPRINT_OUT_START:
					return 66;
				case SPRINT_OUT_END:
					return 69;
				case TAKE_OUT_START:
					return 53;
				case TAKE_OUT_END:
					return 55;
				case PUT_OUT_START:
					return 50;
				case PUT_OUT_END:
					return 53;
				case RELOAD_CANCEL:
					return 48;
			}
			break;
		case W_STG:
   	 	case W_SPATZ:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case RELOAD_START:
					return 6;
				case RELOAD_END:
					return 49;
				case SPRINT_IN_START:
					return 63;
				case SPRINT_IN_END:
					return 67;
				case SPRINT_OUT_START:
					return 68;
				case SPRINT_OUT_END:
					return 73;
				case TAKE_OUT_START:
					return 54;
				case TAKE_OUT_END:
					return 61;
				case PUT_OUT_START:
					return 50;
				case PUT_OUT_END:
					return 53;
				case RELOAD_CANCEL:
					return 30;
			}
			break;
		case W_TRENCH:
   	 	case W_GUT:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 3;
				case SPRINT_IN_START:
					return 27;
				case SPRINT_IN_END:
					return 28;
				case SPRINT_OUT_START:
					return 27;
				case SPRINT_OUT_END:
					return 26;
				case TAKE_OUT_START:
					return 32;
				case TAKE_OUT_END:
					return 36;
				case PUT_OUT_START:
					return 30;
				case PUT_OUT_END:
					return 32;
				case RELOAD_CANCEL:
					return 20;
			}
			break;
		case W_TYPE:
   	 	case W_SAMURAI:
			switch (frametype)
			{
				case FIRE_START:
					return 0;
				case FIRE_END:
					return 1;
				case RELOAD_START:
					return 2;
				case RELOAD_END:
					return 24;
				case SPRINT_IN_START:
					return 35;
				case SPRINT_IN_END:
					return 37;
				case SPRINT_OUT_START:
					return 38;
				case SPRINT_OUT_END:
					return 40;
				case TAKE_OUT_START:
					return 38;
				case TAKE_OUT_END:
					return 41;
				case PUT_OUT_START:
					return 35;
				case PUT_OUT_END:
					return 38;
				case RELOAD_CANCEL:
					return 16;
				case AIM_IN:
					return 28;
				case AIM_FIRE_START:
					return 27;
				case AIM_FIRE_END:
					return 29;
			}
			break;
		case W_TESLA:
		case W_DG3:
			switch (frametype)
			{
				case FIRE_START:
					return 1;
				case FIRE_END:
					return 4;
				case RELOAD_START:
					return 9;
				case RELOAD_END:
					return 58;
				case SPRINT_IN_START:
					return 60;
				case SPRINT_IN_END:
					return 63;
				case SPRINT_OUT_START:
					return 63;
				case SPRINT_OUT_END:
					return 66;
				case TAKE_OUT_START:
					return 72;
				case TAKE_OUT_END:
					return 76;
				case PUT_OUT_START:
					return 66;
				case PUT_OUT_END:
					return 71;
				case RELOAD_CANCEL:
					return 39;
			}
			break;
		case W_BK:
		case W_KRAUS:
			switch (frametype)
			{
				case FIRE_START:
					return 28;
				case FIRE_END:
					return 32;
				case RELOAD_START:
					return 33;
				case RELOAD_END:
					return 46;
				case SPRINT_IN_START:
					return 51;
				case SPRINT_IN_END:
					return 53;
				case SPRINT_START:
					return 54;
				case SPRINT_END:
					return 61;
				case SPRINT_OUT_START:
					return 62;
				case SPRINT_OUT_END:
					return 64;
				case TAKE_OUT_START:
					return 4;
				case TAKE_OUT_END:
					return 6;
				case PUT_OUT_START:
					return 47;
				case PUT_OUT_END:
					return 50;
				case RELOAD_CANCEL:
					return 41;
				case MELEE_NORMAL_START:
					return 8;
				case MELEE_NORMAL_END:
					return 13;
				case MELEE_LUNGED_START:
					return 14;
				case MELEE_LUNGED_END:
					return 24;
			}
			break;
	}

    return 0;
}

string(float wep, float gorvmodel) GetWeaponModel =
{

	switch (wep)
	{
		case W_COLT:
			if (gorvmodel)
				return ("models/weapons/m1911/g_colt.mdl");
			else
				return ("models/weapons/m1911/v_colt.mdl");
		case W_BIATCH:
			if (gorvmodel)
				return ("models/weapons/m1911/g_colt.mdl");
			else
				return ("models/weapons/m1911/v_biatch_right.mdl");
		case W_KAR:
		case W_ARMAGEDDON:
			if (gorvmodel)
				return ("models/weapons/kar/g_kar.mdl");
			else
				return ("models/weapons/kar/v_kar.mdl");
		case W_SPRING:
		case W_PULVERIZER:
			if (gorvmodel)
				return ("models/weapons/spring/g_spring.mdl");
			else
				return ("models/weapons/spring/v_spring.mdl");
		case W_THOMPSON:
		case W_GIBS:
			if (gorvmodel)
				return ("models/weapons/thomp/g_thomp.mdl");
			else
				return ("models/weapons/thomp/v_thomp.mdl");
		case W_357:
		case W_KILLU:
			if (gorvmodel)
				return ("models/weapons/357/g_357.mdl");
			else
				return ("models/weapons/357/v_357.mdl");
		case W_BAR:
		case W_WIDOW:
			if (gorvmodel)
				return ("models/weapons/bar/g_bar.mdl");
			else
				return ("models/weapons/bar/v_bar.mdl");
		case W_BROWNING:
    	case W_ACCELERATOR:
			if (gorvmodel)
				return ("models/weapons/browning/g_browning.mdl");
			else
				return ("models/weapons/browning/v_browning.mdl");
		case W_DB:
    	case W_BORE:
			if (gorvmodel)
				return ("models/weapons/db/g_db.mdl");
			else
				return ("models/weapons/db/v_db.mdl");
		case W_FG:
    	case W_IMPELLER:
			if (gorvmodel)
				return ("models/weapons/fg42/g_fg.mdl");
			else
				return ("models/weapons/fg42/v_fg.mdl");
		case W_GEWEHR:
    	case W_COMPRESSOR:
			if (gorvmodel)
				return ("models/weapons/gewehr/g_gewehr.mdl");
			else
				return ("models/weapons/gewehr/v_gewehr.mdl");
		case W_KAR_SCOPE:
    	case W_HEADCRACKER:
			if (gorvmodel)
				return ("models/weapons/kar/g_kars.mdl");
			else
				return ("models/weapons/kar/v_kar.mdl");
		case W_M1:
    	case W_M1000:
			if (gorvmodel)
				return ("models/weapons/garand/g_m1.mdl");
			else
				return ("models/weapons/garand/v_m1.mdl");
		case W_M1A1:
    	case W_WIDDER:
			if (gorvmodel)
				return ("models/weapons/m1carbine/g_m1a1.mdl");
			else
				return ("models/weapons/m1carbine/v_m1a1.mdl");
		case W_M2:
		case W_FIW:
			if (gorvmodel)
				return ("models/weapons/m2flame/g_m2flame.mdl");
			else
				return ("models/weapons/m2flame/v_m2flame.mdl");
		case W_MP40:
    	case W_AFTERBURNER:
			if (gorvmodel)
				return ("models/weapons/mp40/g_mp40.mdl");
			else
				return ("models/weapons/mp40/v_mp40.mdl");
		case W_MP5K:
    	case W_KOLLIDER:
			if (gorvmodel)
				return ("models/weapons/mp5k/g_mp5k.mdl");
			else
				return ("models/weapons/mp5k/v_mp5k.mdl");
		case W_MG:
    	case W_BARRACUDA:
			if (gorvmodel)
				return ("models/weapons/mg/g_mg.mdl");
			else
				return ("models/weapons/mg/v_mg.mdl");
		case W_PANZER:
    	case W_LONGINUS:
			if (gorvmodel)
				return ("models/weapons/panzer/g_panzer.mdl");
			else
				return ("models/weapons/panzer/v_panzer.mdl");
		case W_PPSH:
    	case W_REAPER:
			if (gorvmodel)
				return ("models/weapons/ppsh/g_ppsh.mdl");
			else
				return ("models/weapons/ppsh/v_ppsh.mdl");
		case W_PTRS:
    	case W_PENETRATOR:
			if (gorvmodel)
				return ("models/weapons/ptrs/g_ptrs.mdl");
			else
				return ("models/weapons/ptrs/v_ptrs.mdl");
		case W_RAY:
    	case W_PORTER:
			if (gorvmodel)
				return ("models/weapons/ray/g_ray.mdl");
			else
				return ("models/weapons/ray/v_ray.mdl");
		case W_SAWNOFF:
			if (gorvmodel)
				return ("models/weapons/sawnoff/g_sawnoff.mdl");
			else
				return ("models/weapons/sawnoff/v_sawnoff.mdl");
    	case W_SNUFF:
			if (gorvmodel)
				return ("models/weapons/sawnoff/g_sawnoff.mdl");
			else
				return ("models/weapons/sawnoff/v_snuff_right.mdl");
		case W_STG:
    	case W_SPATZ:
			if (gorvmodel)
				return ("models/weapons/stg/g_stg.mdl");
			else
				return ("models/weapons/stg/v_stg.mdl");
		case W_TRENCH:
    	case W_GUT:
			if (gorvmodel)
				return ("models/weapons/trench/g_trench.mdl");
			else
				return ("models/weapons/trench/v_trench.mdl");
		case W_TYPE:
    	case W_SAMURAI:
			if (gorvmodel)
				return ("models/weapons/type/g_type.mdl");
			else
				return ("models/weapons/type/v_type.mdl");
		case W_GRENADE:
			if (gorvmodel)
				return ("models/weapons/grenade/g_grenade.mdl");
			else
				return ("models/weapons/grenade/v_grenade.mdl");
		case W_BETTY:
			if (gorvmodel)
				return ("models/weapons/grenade/g_betty.mdl");
			else
				return ("models/weapons/grenade/v_betty.mdl");
		case W_BOWIE:
			if (gorvmodel)
				return ("models/weapons/knife/g_bowie.mdl");
			else
				return ("models/weapons/knife/v_bowie.mdl");
		case W_DG3:
		case W_TESLA:
			if (gorvmodel)
				return ("models/weapons/tesla/g_tesla.mdl");
			else
				return ("models/weapons/tesla/v_tesla.mdl");
		case W_BK:
		case W_KRAUS:
			if (gorvmodel)
				return ("models/weapons/bk/g_bk.mdl");
			else
				return ("models/weapons/bk/v_bk.mdl");
    }

    return ("");
}

string(float wep) GetWeapon2Model =
{

	switch (wep)
	{
		case W_BIATCH:
			return ("models/weapons/m1911/v_biatch_left.mdl");		
		case W_KAR_SCOPE:
    	case W_HEADCRACKER:
			return ("models/weapons/kar/v_karscope.mdl");
    	case W_SNUFF:
			return ("models/weapons/sawnoff/v_snuff_left.mdl");
		default:
			return "";
    }

    return ("");
}

string(float wep) GetWeaponSound =
{

	switch (wep)
	{
		case W_BIATCH:
		case W_COLT:
			return "sounds/weapons/colt/shoot.wav";
		case W_KAR:
		case W_ARMAGEDDON:
		case W_SPRING:
		case W_PULVERIZER:
			return "sounds/weapons/boltaction/shoot.wav";
		case W_THOMPSON:
		case W_GIBS:
			return "sounds/weapons/thomp/shoot.wav";
		case W_357:
		case W_KILLU:
			return "sounds/weapons/357/shoot.wav";
		case W_BAR:
    	case W_WIDOW:
			return "sounds/weapons/bar/shoot.wav";
		case W_BROWNING:
    	case W_ACCELERATOR:
			return "sounds/weapons/browning/shoot.wav";
		case W_DB:
    	case W_BORE:
			return "sounds/weapons/shotgun/shoot.wav";
		case W_FG:
    	case W_IMPELLER:
			return "sounds/weapons/fg42/shoot.wav";
		case W_GEWEHR:
    	case W_COMPRESSOR:
			return "sounds/weapons/gewehr/shoot.wav";
		case W_KAR_SCOPE:
    	case W_HEADCRACKER:
			return "sounds/weapons/boltaction/shoot.wav";
		case W_M1:
    	case W_M1000:
			return "sounds/weapons/garand/shoot.wav";
		case W_M1A1:
    	case W_WIDDER:
			return "sounds/weapons/m1carbine/shoot.wav";
		case W_M2:
			return "sounds/weapons/m2flame/flamethrower.wav";
		case W_MP40:
    	case W_AFTERBURNER:
			return "sounds/weapons/mp40/shoot.wav";
		case W_MP5K:
    	case W_KOLLIDER:
			return "sounds/weapons/mp5k/shoot.wav";
		case W_MG:
    	case W_BARRACUDA:
			return "sounds/weapons/mg42/shoot.wav";
		case W_PANZER:
   		case W_LONGINUS:
			return "sounds/weapons/panzer/shoot.wav";
		case W_PPSH:
    	case W_REAPER:
			return "sounds/weapons/ppsh/shoot.wav";
		case W_PTRS:
    	case W_PENETRATOR:
			return "sounds/weapons/ptrs/shoot.wav";
		case W_RAY:
    	case W_PORTER:
			return "sounds/weapons/raygun/shoot.wav";
		case W_SAWNOFF:
    	case W_SNUFF:
			return "sounds/weapons/shotgun/shoot.wav";
		case W_STG:
    	case W_SPATZ:
			return "sounds/weapons/stg/shoot.wav";
		case W_TRENCH:
    	case W_GUT:
			return "sounds/weapons/shotgun/shoot.wav";
		case W_TYPE:
    	case W_SAMURAI:
			return "sounds/weapons/type100/shoot.wav";
		case W_TESLA:
		case W_DG3:
      		return "sounds/weapons/tesla/shoot.wav";
		case W_BK:
		case W_KRAUS:
			return "sounds/weapons/ballknife/shoot.wav";
    }

    return "";
}

float(float wep) IsDualWeapon = {

	switch(wep) {
		case W_BIATCH:
			return 1;
		case W_SNUFF:
			return 1;
		default:
			return 0;
	}
}

string(float wep) GetLeftWeaponModel = {

	switch(wep) {
		case W_BIATCH:
			return "models/weapons/m1911/v_biatch_left.mdl";
		case W_SNUFF:
			return "models/weapons/sawnoff/v_snuff_left.mdl";
		default:
			return "";
	}
}

float(float wep) IsPapWeapon = {

	switch(wep) {
		case W_BIATCH:
		case W_ARMAGEDDON:
		case W_GIBS:
		case W_KILLU:
		case W_WIDOW:
		case W_ACCELERATOR:
		case W_BORE:
		case W_IMPELLER:
		case W_COMPRESSOR:
		case W_HEADCRACKER:
		case W_M1000:
		case W_WIDDER:
		case W_AFTERBURNER:
		case W_KOLLIDER:
		case W_BARRACUDA:
		case W_LONGINUS:
		case W_REAPER:
		case W_PENETRATOR:
		case W_PORTER:
		case W_SNUFF:
		case W_SPATZ:
		case W_GUT:
		case W_SAMURAI:
		case W_DG3:
		case W_PULVERIZER:
		case W_FIW:
		case W_KRAUS:
			return 1;
		default:
			return 0;
	}
}

float(float wep) GetWepSkin = {

	switch(wep) {
		case W_BIATCH:
			return 0;
		case W_SNUFF:
			return 0;
		default:
			if (IsPapWeapon(wep)) {
				return 1;
			} else {
				return 0;
			}
	}
}


float(float wep)  EqualNonPapWeapon =
{

	switch (wep) {
		case W_BIATCH:
			return W_COLT;
		case W_ARMAGEDDON:
			return W_KAR;
		case W_PULVERIZER:
			return W_SPRING;
		case W_GIBS:
			return W_THOMPSON;
		case W_KILLU:
			return W_357;
		case W_WIDOW:
			return W_BAR;
		case W_ACCELERATOR:
			return W_BROWNING;
		case W_BORE:
			return W_DB;
		case W_IMPELLER:
			return W_FG;
		case W_COMPRESSOR:
			return W_GEWEHR;
		case W_HEADCRACKER:
			return W_KAR_SCOPE;
		case W_M1000:
			return W_M1;
		case W_WIDDER:
			return W_M1A1;
		case W_AFTERBURNER:
			return W_MP40;
		case W_KOLLIDER:
			return W_MP5K;
		case W_BARRACUDA:
			return W_MG;
		case W_LONGINUS:
			return W_PANZER;
		case W_REAPER:
			return W_PPSH;
		case W_PENETRATOR:
			return W_PTRS;
		case W_PORTER:
			return W_RAY;
		case W_SNUFF:
			return W_SAWNOFF;
		case W_SPATZ:
			return W_STG;
		case W_GUT:
			return W_TRENCH;
		case W_SAMURAI:
			return W_TYPE;
		case W_M14:
			return W_M14;
		case W_CUSTOM2:
			return W_CUSTOM1;
		case W_CUSTOM4:
			return W_CUSTOM3;
		case W_DG3:
			return W_TESLA;
		case W_FIW:
			return W_M2;
		case W_KRAUS:
			return W_BK;
		default:
			return wep;
	}
}
float(float wep)  EqualPapWeapon = 
{

	switch (wep) {
		case W_COLT:
			return W_BIATCH;
		case W_KAR:
      		return W_ARMAGEDDON;
		case W_SPRING:
			return W_PULVERIZER;
		case W_THOMPSON:
			return W_GIBS;
		case W_357:
			return W_KILLU;
		case W_BAR:
			return W_WIDOW;
		case W_BROWNING:
			return W_ACCELERATOR;
		case W_DB:
			return W_BORE;
		case W_FG:
			return W_IMPELLER;
		case W_GEWEHR:
			return W_COMPRESSOR;
		case W_KAR_SCOPE:
			return W_HEADCRACKER;
		case W_M1:
			return W_M1000;
		case W_M1A1:
			return W_WIDDER;
		case W_MP40:
			return W_AFTERBURNER;
		case W_MP5K:
			return W_KOLLIDER;
		case W_MG:
			return W_BARRACUDA;
		case W_PANZER:
			return W_LONGINUS;
		case W_PPSH:
			return W_REAPER;
		case W_PTRS:
			return W_PENETRATOR;
		case W_RAY:
			return W_PORTER;
		case W_SAWNOFF:
			return W_SNUFF;
		case W_STG:
			return W_SPATZ;
		case W_TRENCH:
			return W_GUT;
		case W_TYPE:
			return W_SAMURAI;
		case W_TESLA:
			return W_DG3;
		case W_M14:
			return W_M14;
		case W_M2:
			return W_FIW;
		case W_BK:
			return W_KRAUS;
		default:
			return wep;
	}
}

void (float wep, float anim_style, float dualwep, float curweaponframe)	PlayWeaponSound =
{
	if (anim_style == KNIFE) {
		if (curweaponframe == 6) {
			self.punchangle_x = -2;
			self.punchangle_y = -5;	
		} else if (curweaponframe == 7) {
			self.punchangle_x = 5;
			self.punchangle_y = 10;
		}
	}

	if (anim_style == FIRE)
	{
		if (wep == W_KAR || wep == W_ARMAGEDDON || wep == W_KAR_SCOPE || wep == W_HEADCRACKER || wep == W_SPRING || wep == W_PULVERIZER)
		{
			if (curweaponframe == 6)
				sound (self ,5, "sounds/weapons/boltaction/boltup.wav", 1, ATTN_NORM);
			else if (curweaponframe == 7)
				sound (self ,5, "sounds/weapons/boltaction/boltback.wav", 1, ATTN_NORM);
			else if (curweaponframe == 9)
				sound (self ,5, "sounds/weapons/boltaction/boltforward.wav", 1, ATTN_NORM);
			else if (curweaponframe == 10)
				sound (self ,5, "sounds/weapons/boltaction/boltdown.wav", 1, ATTN_NORM);
		}
		else if (wep == W_TRENCH || wep == W_GUT)
		{
			if (curweaponframe == 7)
				sound (self ,5, "sounds/weapons/shotgun/pump.wav", 1, ATTN_NORM);
		}
	} else if (anim_style != RELOAD) {
		return;
	}


	switch (wep) {
		case W_COLT:
			if (curweaponframe == 5) {
				sound (self ,5, "sounds/weapons/colt/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 12) {
				sound (self ,5, "sounds/weapons/colt/magin.wav", 1, ATTN_NORM);
			} else if(curweaponframe == 18) {
				sound (self ,5, "sounds/weapons/colt/slide.wav", 1, ATTN_NORM);
			}
			break;
		case W_KAR:
		case W_ARMAGEDDON:
		case W_SPRING:
		case W_PULVERIZER:
			if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/boltaction/boltup.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/boltaction/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/boltaction/clipin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 25) {
				sound (self ,5, "sounds/weapons/boltaction/boltforward.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 26) {
				sound (self ,5, "sounds/weapons/boltaction/clipoff.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 27) {
				sound (self ,5, "sounds/weapons/boltaction/boltdown.wav", 1, ATTN_NORM);
			}
			break;
		case W_THOMPSON:
		case W_GIBS:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/thomp/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 12) {
				sound (self ,5, "sounds/weapons/thomp/magin.wav", 1, ATTN_NORM);}
			else if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/thomp/boltback.wav", 1, ATTN_NORM);
			}
			break;
		case W_357:
		case W_KILLU:
			if (curweaponframe == 5) {
				sound (self ,5, "sounds/weapons/357/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 9) {
				sound (self ,5, "sounds/weapons/357/out.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/357/in.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/357/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_BAR:
    	case W_WIDOW:
			if (curweaponframe == 6  || curweaponframe == 31) {
				sound (self ,5, "sounds/weapons/bar/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 19 || curweaponframe == 29) {
				sound (self ,5, "sounds/weapons/bar/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 23) {
				sound (self ,5, "sounds/weapons/bar/maghit.wav", 1, ATTN_NORM);
			}
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			if (curweaponframe == 6 || curweaponframe == 60) {
				sound (self ,5, "sounds/weapons/browning/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 16 || curweaponframe == 69)  {
				sound (self ,5, "sounds/weapons/browning/topopen.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 21) {
				sound (self ,5, "sounds/weapons/browning/chainoff.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 27) {
				sound (self ,5, "sounds/weapons/browning/chainon.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 30) {
				sound (self ,5, "sounds/weapons/browning/chainplace.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 36) {
				sound (self ,5, "sounds/weapons/browning/topclose.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 41) {
				sound (self ,5, "sounds/weapons/browning/tophit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 48) {
				sound (self ,5, "sounds/weapons/browning/boltforward.wav", 1, ATTN_NORM);
			}
			break;
		case W_DB:
		case W_SAWNOFF:
		case W_BORE:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/shotgun/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 12) {
				sound (self ,5, "sounds/weapons/shotgun/out.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/shotgun/in.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 26) {
				sound (self ,5, "sounds/weapons/shotgun/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_SNUFF:
			if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/shotgun/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 23) {
				sound (self ,5, "sounds/weapons/shotgun/out.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 33) {
				sound (self ,5, "sounds/weapons/shotgun/in.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 40) {
				sound (self ,5, "sounds/weapons/shotgun/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_FG:
		case W_IMPELLER:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/fg42/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 14) {
				sound (self ,5, "sounds/weapons/fg42/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 23) {
				sound (self ,5, "sounds/weapons/fg42/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 26) {
				sound (self ,5, "sounds/weapons/fg42/boltforward.wav", 1, ATTN_NORM);
			}
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			if (curweaponframe == 21) {
				sound (self ,5, "sounds/weapons/gewehr/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 32) {
				sound (self ,5, "sounds/weapons/gewehr/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 36) {
				sound (self ,5, "sounds/weapons/gewehr/maghit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 45) {
				sound (self ,5, "sounds/weapons/gewehr/boltrelease.wav", 1, ATTN_NORM);
			}
			break;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
		case W_SPRING:
		case W_PULVERIZER:
			if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/boltaction/boltup.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/boltaction/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/boltaction/insert.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 25) {
				sound (self ,5, "sounds/weapons/boltaction/boltforward.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 27) {
				sound (self ,5, "sounds/weapons/boltaction/boltdown.wav", 1, ATTN_NORM);
			}
			break;
		case W_M1:
		case W_M1000:
			if (curweaponframe == 5 || curweaponframe == 25) {
				sound (self ,5, "sounds/weapons/garand/clipout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 13) {
				sound (self ,5, "sounds/weapons/garand/clipin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/garand/boltrelease.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 24) {
				sound (self ,5, "sounds/weapons/garand/clippush.wav", 1, ATTN_NORM);
			}
			break;
		case W_M1A1:
		case W_WIDDER:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/m1carbine/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 14) {
				sound (self ,5, "sounds/weapons/m1carbine/magin.wav", 1, ATTN_NORM);
			} else if(curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/m1carbine/maghit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 24) {
				sound (self ,5, "sounds/weapons/m1carbine/bolt.wav", 1, ATTN_NORM);
			}
			break;
		case W_MP40:
		case W_AFTERBURNER:
			if (curweaponframe == 7) {
				sound (self ,5, "sounds/weapons/mp40/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 17) {
				sound (self ,5, "sounds/weapons/mp40/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 25) {
				sound (self ,5, "sounds/weapons/mp40/boltback.wav", 1, ATTN_NORM);
			}
			break;
		case W_MP5K:
		case W_KOLLIDER:
			if (curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/mp5k/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 31) {
				sound (self ,5, "sounds/weapons/mp5k/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 39) {
				sound (self ,5, "sounds/weapons/mp5k/slap.wav", 1, ATTN_NORM);
			}
			break;
		case W_PANZER:
		case W_LONGINUS:
			if (curweaponframe == 12) {
				sound (self ,5, "sounds/weapons/panzer/move.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 16) {
				sound (self ,5, "sounds/weapons/panzer/insert.wav", 1, ATTN_NORM);
			}
			break;
		case W_MG:
		case W_BARRACUDA:
			if (curweaponframe == 8) {
				sound (self ,5, "sounds/weapons/mg42/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/mg42/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 29) {
				sound (self ,5, "sounds/weapons/mg42/charge.wav", 1, ATTN_NORM);
			}
			break;
		case W_PPSH:
    	case W_REAPER:
				if (curweaponframe == 8) {
				sound (self ,5, "sounds/weapons/ppsh/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/ppsh/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 22) {
				sound (self ,5, "sounds/weapons/ppsh/maghit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 30) {
				sound (self ,5, "sounds/weapons/ppsh/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 33) {
				sound (self ,5, "sounds/weapons/ppsh/boltrelease.wav", 1, ATTN_NORM);
			}
			break;
		case W_PTRS:
		case W_PENETRATOR:
			if (curweaponframe == 7) {
				sound (self ,5, "sounds/weapons/ptrs/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 13 || curweaponframe == 31) {
				sound (self ,5, "sounds/weapons/ptrs/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 21) {
				sound (self ,5, "sounds/weapons/ptrs/maghit.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 23) {
				sound (self ,5, "sounds/weapons/ptrs/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_RAY:
		case W_PORTER:
			if (curweaponframe == 10) {
				sound (self ,5, "sounds/weapons/raygun/open.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/raygun/out.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 33) {
				sound (self ,5, "sounds/weapons/raygun/in.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 41) {
				sound (self ,5, "sounds/weapons/raygun/close.wav", 1, ATTN_NORM);
			}
			break;
		case W_STG:
		case W_SPATZ:
			if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/stg/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 28) {
				sound (self ,5, "sounds/weapons/stg/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 37) {
				sound (self ,5, "sounds/weapons/stg/boltback.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 41) {
				sound (self ,5, "sounds/weapons/stg/boltrelease.wav", 1, ATTN_NORM);
			}
			break;
		case W_TRENCH:
		case W_GUT:
			if (curweaponframe == 19) {
				sound (self ,5, "sounds/weapons/shotgun/insert.wav", 1, ATTN_NORM);
			}
			break;
		case W_TYPE:
		case W_SAMURAI:
			if (curweaponframe == 6) {
				sound (self ,5, "sounds/weapons/type100/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 15) {
				sound (self ,5, "sounds/weapons/type100/magin.wav", 1, ATTN_NORM);
			} else if (curweaponframe == 20) {
				sound (self ,5, "sounds/weapons/type100/boltpull.wav", 1, ATTN_NORM);
			}
			break;
		case W_BIATCH:
			if (curweaponframe == 23) {
				sound (self ,5, "sounds/weapons/colt/magout.wav", 1, ATTN_NORM);
			} else if (curweaponframe ==30) {
				sound (self ,5, "sounds/weapons/colt/magin.wav", 1, ATTN_NORM);
			} else if(curweaponframe == 36) {
				sound (self ,5, "sounds/weapons/biatch/slideback.wav", 1, ATTN_NORM);
			} else if(curweaponframe == 42) {
				sound (self ,5, "sounds/weapons/biatch/sliderelease.wav", 1, ATTN_NORM);
			}
			break;
		case W_TESLA:
		case W_DG3:
			if (curweaponframe == 20)
				sound (self ,5, "sounds/weapons/tesla/switchoff.wav", 1, ATTN_NORM);
			else if (curweaponframe == 25)
				sound (self ,5, "sounds/weapons/tesla/pulllever.wav", 1, ATTN_NORM);
			else if (curweaponframe == 31)
				sound (self ,5, "sounds/weapons/tesla/glassbreak.wav", 1, ATTN_NORM);
			else if (curweaponframe == 38)
				sound (self ,5, "sounds/weapons/tesla/clipin.wav", 1, ATTN_NORM);
			else if (curweaponframe == 43)
				sound (self ,5, "sounds/weapons/tesla/clipoff.wav", 1, ATTN_NORM);
			else if (curweaponframe == 51)
				sound (self ,5, "sounds/weapons/tesla/switchon.wav", 1, ATTN_NORM);
			break;
		case W_BK:
		case W_KRAUS:
			if (curweaponframe == 41)
				sound(self, 5, "sounds/weapons/ballknife/insert.wav", 1, ATTN_NORM);
			break;
	}
}


void(float weptype) precache_extra =
{

	switch (weptype) {
		case W_COLT:
		case W_BIATCH:
			precache_sound("sounds/weapons/colt/shoot.wav");
			precache_sound("sounds/weapons/biatch/slideback.wav");
			precache_sound("sounds/weapons/biatch/sliderelease.wav");
			precache_sound("sounds/weapons/colt/magout.wav");
			precache_sound("sounds/weapons/colt/magin.wav");
			precache_sound("sounds/weapons/colt/slide.wav");
			precache_model ("models/weapons/m1911/v_biatch_right.mdl");
			precache_model ("models/weapons/m1911/v_biatch_left.mdl");
			break;
		case W_KAR_SCOPE:
		case W_KAR:
		case W_ARMAGEDDON:
		case W_SPRING:
		case W_PULVERIZER:
			precache_sound ("sounds/weapons/boltaction/boltup.wav");
			precache_sound ("sounds/weapons/boltaction/boltback.wav");
			precache_sound ("sounds/weapons/boltaction/boltforward.wav");
			precache_sound ("sounds/weapons/boltaction/boltdown.wav");
			precache_sound ("sounds/weapons/boltaction/clipin.wav");
			precache_sound ("sounds/weapons/boltaction/clipoff.wav");
			precache_sound ("sounds/weapons/boltaction/shoot.wav");
			precache_sound ("sounds/weapons/boltaction/insert.wav");
			precache_model ("models/weapons/kar/v_karscope.mdl");
			break;
		case W_THOMPSON:
		case W_GIBS:
			precache_sound("sounds/weapons/thomp/magout.wav");
			precache_sound("sounds/weapons/thomp/magin.wav");
			precache_sound("sounds/weapons/thomp/boltback.wav");
			precache_sound("sounds/weapons/thomp/shoot.wav");
			break;
		case W_357:
		case W_KILLU:
			precache_sound("sounds/weapons/357/open.wav");
			precache_sound("sounds/weapons/357/out.wav");
			precache_sound("sounds/weapons/357/in.wav");
			precache_sound("sounds/weapons/357/close.wav");
			precache_sound("sounds/weapons/357/shoot.wav");
			break;
		case W_BAR:
		case W_WIDOW:
			precache_sound("sounds/weapons/bar/shoot.wav");
			precache_sound("sounds/weapons/bar/magout.wav");
			precache_sound("sounds/weapons/bar/magin.wav");
			precache_sound("sounds/weapons/bar/maghit.wav");
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
			precache_sound ("sounds/weapons/browning/boltback.wav");
			precache_sound ("sounds/weapons/browning/topopen.wav");
			precache_sound ("sounds/weapons/browning/chainoff.wav");
			precache_sound ("sounds/weapons/browning/boltback.wav");
			precache_sound ("sounds/weapons/browning/topopen.wav");
			precache_sound ("sounds/weapons/browning/chainon.wav");
			precache_sound ("sounds/weapons/browning/chainplace.wav");
			precache_sound ("sounds/weapons/browning/topclose.wav");
			precache_sound ("sounds/weapons/browning/tophit.wav");
			precache_sound ("sounds/weapons/browning/boltforward.wav");
			precache_sound ("sounds/weapons/browning/shoot.wav");
			break;
		case W_SAWNOFF:
		case W_SNUFF:
		case W_DB:
		case W_BORE:
			precache_sound("sounds/weapons/shotgun/open.wav");
			precache_sound("sounds/weapons/shotgun/out.wav");
			precache_sound("sounds/weapons/shotgun/in.wav");
			precache_sound("sounds/weapons/shotgun/close.wav");
			precache_sound("sounds/weapons/shotgun/shoot.wav");

			//lotta stuff here, so let's make sure we don't add unless ABSOLUTELY necessary..
			if (weptype == W_SNUFF) {
				precache_model("models/weapons/sawnoff/v_snuff_right.mdl");
				precache_model("models/weapons/sawnoff/v_snuff_left.mdl");
			}
			break;
		case W_FG:
		case W_IMPELLER:
			precache_sound("sounds/weapons/fg42/magout.wav");
			precache_sound("sounds/weapons/fg42/magin.wav");
			precache_sound("sounds/weapons/fg42/boltback.wav");
			precache_sound("sounds/weapons/fg42/boltforward.wav");
			precache_sound("sounds/weapons/fg42/shoot.wav");
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
			precache_sound("sounds/weapons/gewehr/magout.wav");
			precache_sound("sounds/weapons/gewehr/magin.wav");
			precache_sound("sounds/weapons/gewehr/maghit.wav");
			precache_sound("sounds/weapons/gewehr/boltrelease.wav");
			precache_sound("sounds/weapons/gewehr/shoot.wav");
			break;
		case W_M1:
		case W_M1000:
			precache_sound ("sounds/weapons/garand/clipout.wav");
			precache_sound ("sounds/weapons/garand/clipin.wav");
			precache_sound ("sounds/weapons/garand/clippush.wav");
			precache_sound ("sounds/weapons/garand/boltrelease.wav");
			precache_sound ("sounds/weapons/garand/shoot.wav");
			break;
		case W_M1A1:
		case W_WIDDER:
			precache_sound("sounds/weapons/m1carbine/shoot.wav");
			precache_sound("sounds/weapons/m1carbine/magout.wav");
			precache_sound("sounds/weapons/m1carbine/magin.wav");
			precache_sound("sounds/weapons/m1carbine/maghit.wav");
			precache_sound("sounds/weapons/m1carbine/bolt.wav");
			break;
		case W_M2:
			precache_sound("sounds/weapons/m2flame/flamethrower.wav");
			precache_model("models/sprites/flamer.spr");
			break;
		case W_MP40:
		case W_AFTERBURNER:
			precache_sound ("sounds/weapons/mp40/shoot.wav");
			precache_sound ("sounds/weapons/mp40/magout.wav");
			precache_sound ("sounds/weapons/mp40/magin.wav");
			precache_sound ("sounds/weapons/mp40/boltback.wav");
			break;
		case W_MP5K:
		case W_KOLLIDER:
			precache_sound ("sounds/weapons/mp5k/shoot.wav");
			precache_sound ("sounds/weapons/mp5k/magout.wav");
			precache_sound ("sounds/weapons/mp5k/magin.wav");
			precache_sound ("sounds/weapons/mp5k/slap.wav");
			break;
		case W_MG:
		case W_BARRACUDA:
			precache_sound("sounds/weapons/mg42/magout.wav");
			precache_sound("sounds/weapons/mg42/magin.wav");
			precache_sound("sounds/weapons/mg42/charge.wav");
			precache_sound("sounds/weapons/mg42/shoot.wav");
			break;
		case W_PANZER:
		case W_LONGINUS:
			precache_sound ("sounds/weapons/panzer/move.wav");
			precache_sound ("sounds/weapons/panzer/insert.wav");
			precache_sound ("sounds/weapons/panzer/shoot.wav");
			precache_model ("models/misc/shark.mdl");
			break;
		case W_PPSH:
		case W_REAPER:
			precache_sound("sounds/weapons/ppsh/magout.wav");
			precache_sound("sounds/weapons/ppsh/magin.wav");
			precache_sound("sounds/weapons/ppsh/maghit.wav");
			precache_sound("sounds/weapons/ppsh/boltback.wav");
			precache_sound("sounds/weapons/ppsh/boltrelease.wav");
			precache_sound("sounds/weapons/ppsh/shoot.wav");
			break;
		case W_PTRS:
		case W_PENETRATOR:
			precache_sound ("sounds/weapons/ptrs/open.wav");
			precache_sound ("sounds/weapons/ptrs/maghit.wav");
			precache_sound ("sounds/weapons/ptrs/magin.wav");
			precache_sound ("sounds/weapons/ptrs/close.wav");
			precache_sound ("sounds/weapons/ptrs/shoot.wav");
			break;
		case W_RAY:
		case W_PORTER:
			precache_sound("sounds/weapons/raygun/open.wav");
			precache_sound("sounds/weapons/raygun/out.wav");
			precache_sound("sounds/weapons/raygun/in.wav");
			precache_sound("sounds/weapons/raygun/close.wav");
			precache_sound("sounds/weapons/raygun/shoot.wav");
			precache_model("models/misc/raybeam.mdl");
			break;
		case W_STG:
		case W_SPATZ:
			precache_sound ("sounds/weapons/stg/magout.wav");
			precache_sound ("sounds/weapons/stg/magin.wav");
			precache_sound ("sounds/weapons/stg/shoot.wav");
			precache_sound ("sounds/weapons/stg/boltback.wav");
			precache_sound ("sounds/weapons/stg/boltrelease.wav");
			break;
		case W_TRENCH:
		case W_GUT:
			precache_sound ("sounds/weapons/shotgun/pump.wav");
			precache_sound ("sounds/weapons/shotgun/insert.wav");
			precache_sound ("sounds/weapons/shotgun/shoot.wav");
			break;
		case W_TYPE:
		case W_SAMURAI:
			precache_sound("sounds/weapons/type100/magout.wav");
			precache_sound("sounds/weapons/type100/magin.wav");
			precache_sound("sounds/weapons/type100/boltpull.wav");
			precache_sound("sounds/weapons/type100/shoot.wav");
			break;
		case W_TESLA:
		case W_DG3:
			precache_model("models/sprites/lightning.spr");
			precache_sound("sounds/weapons/tesla/switchoff.wav");
			precache_sound("sounds/weapons/tesla/pulllever.wav");
			precache_sound("sounds/weapons/tesla/glassbreak.wav");
			precache_sound("sounds/weapons/tesla/clipin.wav");
			precache_sound("sounds/weapons/tesla/clipoff.wav");
			precache_sound("sounds/weapons/tesla/switchon.wav");
			precache_sound("sounds/weapons/tesla/shoot.wav");
			precache_sound("sounds/machines/elec_shock.wav");
			break;
		case W_BK:
		case W_KRAUS:
			precache_sound("sounds/weapons/ballknife/shoot.wav");
			precache_sound("sounds/weapons/ballknife/insert.wav");
			break;
		case W_GRENADE:
			precache_model("models/props/grenade_bag.mdl");
			break;
		case W_BETTY:
			precache_model("models/weapons/grenade/g_betty.mdl");
			break;
	}
}

float(float wep) getWeaponRecoilReturn =
{

	switch (wep)
	{
		case W_COLT:
			return 750;
		case W_BIATCH:
			return 750;
		case W_KAR:
		case W_SPRING:
			return 750;
		case W_ARMAGEDDON:
		case W_PULVERIZER:
			return 750;
		case W_THOMPSON:
			return 950;
		case W_GIBS:
			return 950;
		case W_357:
			return 1500;
		case W_KILLU:
			return 1500;
		case W_BAR:
			return 460;
		case W_WIDOW:
			return 460;
		case W_BROWNING:
			return 950;
		case W_ACCELERATOR:
			return 950;
		case W_DB:
			return 1000;
		case W_BORE:
			return 1000;
		case W_FG:
			return 1129;
		case W_IMPELLER:
			return 1129;
		case W_GEWEHR:
			return 1500;
		case W_COMPRESSOR:
			return 1500;
		case W_KAR_SCOPE:
			return 750;
		case W_HEADCRACKER:
			return 750;
		case W_M1:
			return 1500;
		case W_M1000:
			return 1500;
		case W_M1A1:
			return 1500;
		case W_WIDDER:
			return 1500;
		case W_MP40:
			return 2538;
		case W_AFTERBURNER:
			return 2538;
		case W_MP5K:
			return 1255;
		case W_KOLLIDER:
			return 1255;
		case W_MG:
			return 1778;
		case W_BARRACUDA:
			return 1778;
		case W_PANZER:
			return 0;
		case W_LONGINUS:
			return 0;
		case W_PPSH:
			return 1255;
		case W_REAPER:
			return 1255;
		case W_PTRS:
			return 1500;
		case W_PENETRATOR:
			return 1500;
		case W_RAY:
			return 0;
		case W_PORTER:
			return 0;
		case W_SAWNOFF:
			return 1000;
		case W_SNUFF:
			return 1000;
		case W_STG:
			return 2400;
		case W_SPATZ:
			return 2400;
		case W_TRENCH:
			return 500;
		case W_GUT:
			return 500;
		case W_TYPE:
			return 1813;
		case W_SAMURAI:
			return 1813;
		case W_TESLA:
		case W_DG3:
			return 1813;
		case W_BK:
		case W_KRAUS:
			return 460;
	}
	return 0;
}

float(float weapon, float stance) CrossHairWeapon =
{
	float crosshair_spread = 0;

	switch(weapon)
	{
		case W_COLT:
		case W_BIATCH:
		case W_357:
		case W_KILLU:
		case W_BK:
		case W_KRAUS:
			crosshair_spread = 22;
			break;
		case W_PTRS:
		case W_PENETRATOR:
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
		case W_KAR:
		case W_ARMAGEDDON:
		case W_SPRING:
		case W_PULVERIZER:
			crosshair_spread = 65;
			break;
		case W_MP40:
		case W_AFTERBURNER:
		case W_STG:
		case W_SPATZ:
		case W_THOMPSON:
		case W_GIBS:
		case W_BAR:
		case W_WIDOW:
		case W_PPSH:
		case W_REAPER:
		case W_TYPE:
		case W_SAMURAI:
		case W_FG:
		case W_IMPELLER:
		case W_MP5K:
		case W_KOLLIDER:
			crosshair_spread = 10;
			break;
		case W_BROWNING:
		case W_ACCELERATOR:
		case W_MG:
		case W_BARRACUDA:
			crosshair_spread = 30;
			break;
		case W_SAWNOFF:
		case W_SNUFF:
			crosshair_spread = 50;
			break;
		case W_TRENCH:
		case W_GUT:
		case W_DB:
		case W_BORE:
			crosshair_spread = 35;
			break;
		case W_GEWEHR:
		case W_COMPRESSOR:
		case W_M1:
		case W_M1000:
		case W_M1A1:
		case W_WIDDER:
		case W_RAY:
		case W_PORTER:
			crosshair_spread = 5;
			break;
		case W_PANZER:
		case W_LONGINUS:
		case W_TESLA:
			crosshair_spread = 0;
			break;
		default:
			crosshair_spread = 0;
			break;
	}

	// early out
	if (crosshair_spread == 0)
		return crosshair_spread;

	// pretty sure CoD doesn't compute this, but we're cooler than CoD
	switch(stance) {
			case 2:
				return crosshair_spread;
			case 1:
				return crosshair_spread * 0.90;
			case 0:
				return crosshair_spread * 0.85;
			default: return 0;
	}

	return crosshair_spread;
}

float(float weapon, float stance) CrossHairMaxSpread =
{
	float crosshair_spread = 0;

	switch(weapon)
	{
		case W_COLT:
		case W_BIATCH:
		case W_STG:
		case W_SPATZ:
		case W_MP40:
		case W_AFTERBURNER:
		case W_THOMPSON:
		case W_GIBS:
		case W_BAR:
		case W_WIDOW:
		case W_357:
		case W_KILLU:
		case W_BROWNING:
		case W_ACCELERATOR:
		case W_FG:
		case W_IMPELLER:
		case W_MP5K:
		case W_KOLLIDER:
		case W_MG:
		case W_BARRACUDA:
		case W_PPSH:
		case W_REAPER:
		case W_TYPE:
		case W_SAMURAI:
		case W_BK:
		case W_KRAUS:
			crosshair_spread = 48;
			break;
		case W_PTRS:
		case W_PENETRATOR:
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
		case W_KAR:
		case W_ARMAGEDDON:
		case W_SPRING:
		case W_PULVERIZER:
			crosshair_spread = 75;
			break;
		case W_SAWNOFF:
		case W_SNUFF:
			crosshair_spread = 50;
			break;
		case W_DB:
		case W_BORE:
		case W_TRENCH:
		case W_GUT:
		case W_GEWEHR:
		case W_COMPRESSOR:
		case W_M1:
		case W_M1000:
		case W_M1A1:
		case W_WIDDER:
		case W_RAY:
		case W_PORTER:
			crosshair_spread = 35;
			break;
		case W_PANZER:
		case W_LONGINUS:
		case W_TESLA:
			crosshair_spread = 0;
			break;
		default:
			crosshair_spread = 0;
			break;
	}

	// early out
	if (crosshair_spread == 0)
		return crosshair_spread;

	// pretty sure CoD doesn't compute this, but we're cooler than CoD
	switch(stance) {
			case 2:
				return crosshair_spread;
			case 1:
				return crosshair_spread * 0.90;
			case 0:
				return crosshair_spread * 0.85;
			default: return 0;
	}

	return crosshair_spread;
}

float(float wep) W_HighPrecisionWhenADS =
{
	switch (wep) {
		case W_KAR:
		case W_ARMAGEDDON:
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
		case W_PTRS:
		case W_PENETRATOR:
		case W_SPRING:
		case W_PULVERIZER:
			return true;
		default:
			return false;
	}
}

float(float wep) W_SpreadAffectedByADS =
{
	switch (wep) {
		case W_SAWNOFF:
		case W_SNUFF:
		case W_DB:
		case W_BORE:
		case W_TRENCH:
		case W_GUT:
			return false;
		default:
			return true;
	}
}

//
// W_IsLowAmmo(weapon, value, mag_not_reserve)
// Determine if the weapon is low on ammo on the Magazine
// or in its Reserve.
//
float(float weapon, float value, float mag_not_reserve) W_IsLowAmmo =
{
	// Check the Reserve
	if (mag_not_reserve == false) {
		// If there's 20% or less of maximum capacity
		if (value / getWeaponAmmo(weapon) <= 0.2)
			return true;
		return false;
	}
	// Check the Magazine
	else {
		// Initial check: always return true if there's only one
		// round left and that's not the maximum clip size.
		if (value == 1 && value != getWeaponMag(weapon))
			return true;

		// If there's less than 33%
		if (value / getWeaponMag(weapon) < 0.33)
			return true;
		return false;
	}
}

vector(float wep) GetWeaponRecoil =
{
	vector guaranteed = '0 0 0';
	vector kick_change = '0 0 0';
	vector final_kick = '0 0 0';
	float change_1, change_2, change_3,total_recoil, r, temp1, temp2;
	switch (wep)
	{
		case W_COLT:
			guaranteed = '0 35 0';
			kick_change = '25 15 25';
			break;
		case W_BIATCH:
			guaranteed = '0 35 0';
			kick_change = '25 15 25';
			break;
		case W_357:
			guaranteed = '0 80 50';
			kick_change = '0 60 40';
			break;
		case W_KILLU:
			guaranteed = '0 80 50';
			kick_change = '0 60 40';
			break;
		case W_THOMPSON:
			kick_change = '74 74 85';
			break;
		case W_GIBS:
			kick_change = '74 74 85';
			break;
		case W_MP40:
			kick_change = '44 44 44';
			break;
		case W_AFTERBURNER:
			kick_change = '44 44 44';
			break;
		case W_MP5K:
			kick_change = '44 44 44';
			break;
		case W_KOLLIDER:
			kick_change = '44 44 44';
			break;
		case W_TYPE:
			kick_change = '44 44 44';
			break;
		case W_SAMURAI:
			kick_change = '24 74 24';
			break;
		case W_PPSH:
			kick_change = '4 22 4';
			break;
		case W_REAPER:
			kick_change = '4 22 4';
			break;
		case W_GEWEHR:
			kick_change = '50 60 50';
			break;
		case W_COMPRESSOR:
			kick_change = '50 60 50';
			break;
		case W_M1:
			guaranteed = '0 35 0';
			kick_change = '30 30 30';
			break;
		case W_M1000:
			guaranteed = '0 35 0';
			kick_change = '30 30 30';
			break;
		case W_STG:
			kick_change = '15 44 15';
			break;
		case W_SPATZ:
			kick_change = '15 44 15';
			break;
		case W_M1A1:
			kick_change = '50 60 50';
			break;
		case W_WIDDER:
			kick_change = '50 60 50';
			break;
		case W_KAR:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_ARMAGEDDON:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_SPRING:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_PULVERIZER:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_KAR_SCOPE:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_HEADCRACKER:
			guaranteed = '0 50 0';
			kick_change = '25 30 25';
			break;
		case W_PTRS:
			guaranteed = '0 100 85';
			kick_change = '0 95 75';
			break;
		case W_PENETRATOR:
			guaranteed = '0 100 85';
			kick_change = '0 95 75';
			break;
		case W_TRENCH:
			guaranteed = '0 100 85';
			kick_change = '0 95 75';
			break;
		case W_GUT:
			guaranteed = '0 100 85';
			kick_change = '0 95 75';
			break;
		case W_DB:
			guaranteed = '0 95 0';
			kick_change = '45 85 45';
			break;
		case W_BORE:
			guaranteed = '0 95 0';
			kick_change = '45 85 45';
			break;
		case W_SAWNOFF:
			guaranteed = '0 95 0';
			kick_change = '45 85 45';
			break;
		case W_SNUFF:
			guaranteed = '0 95 0';
			kick_change = '45 85 45';
			break;
		case W_BAR:
			kick_change = '0 50 0';
			break;
		case W_WIDOW:
			kick_change = '0 50 0';
			break;
		case W_MG:
			kick_change = '40 30 40';
			break;
		case W_BARRACUDA:
			kick_change = '40 30 40';
			break;
		case W_FG:
			kick_change = '30 45 0';
			break;
		case W_IMPELLER:
			kick_change = '30 45 0';
			break;
		case W_BROWNING:
			kick_change = '50 66 50';
			break;
		case W_ACCELERATOR:
			kick_change = '50 66 50';
			break;
		case W_TESLA:
		case W_DG3:
			kick_change = '74 74 85';
			break;
		case W_BK:
		case W_KRAUS:
			kick_change = '3 3 3';
			break;
	}
	total_recoil = kick_change_x + kick_change_y + kick_change_z;

	change_1 = (kick_change_x)/total_recoil;
	change_2 = (kick_change_y)/total_recoil;
	change_3 = (kick_change_z)/total_recoil;

	r = random();
	temp1 = change_1 + change_2;
	temp2 = change_1 + change_2 + change_3;

	if (r < change_1)
		final_kick_y = kick_change_x*0.4;
	else if (r < temp1)
		final_kick_x = kick_change_y*-0.4;
	else if (r < temp2)
		final_kick_y = kick_change_z*-0.4;

	final_kick_y = final_kick_y + guaranteed_x;
	final_kick_x = final_kick_x - guaranteed_y;
	final_kick_y = final_kick_y - guaranteed_z;

	final_kick_x = final_kick_x / 10;
	final_kick_y = final_kick_y / 10;
	final_kick_z = final_kick_z / 10;
	//bprint	(vtos(final_kick));
	//bprint	("\n");
	return final_kick;
}

// Flash offset is multiplied because vectors have limited precision within qc
// Y, Z, X for .. reasons!
// Y will always be flipped IE, if its negative in blender, it will be positive
// in QC.
vector (float wep) GetWeaponFlash_Offset = 
{
		switch(wep) {
			case W_COLT:
				return [5488, -2742, 35300];
			case W_BIATCH:
				return [6355, -2984, 36625];
			case W_KAR:
			case W_KAR_SCOPE:
			case W_HEADCRACKER:
			case W_ARMAGEDDON:
			case W_SPRING:
			case W_PULVERIZER:
				return [5560, -4582, 75833];
			case W_THOMPSON:
			case W_GIBS:
				return [6203, -5740, 57670];
			case W_TRENCH:
			case W_GUT:
				return [5550, -4118, 62364];
			case W_357:
			case W_KILLU:
				return [8193, -2353, 50527];
			case W_MG:
			case W_BARRACUDA:
				return [6806, -9375, 81713];
			case W_DB: 
			case W_BORE:
				return [5801, -4300, 83174];
			case W_SAWNOFF:
				return [5801, -4414, 44820];
			case W_M1A1:
			case W_WIDDER:
				return [5317, -5331, 70583];
			case W_BAR:
			case W_WIDOW:
				return [3899, -5021, 78199];
			case W_FG:
			case W_IMPELLER:
				return [11847, -6792, 77246];
			case W_GEWEHR:
			case W_COMPRESSOR:
				return [5261, -8070, 78777];
			case W_PPSH:
			case W_REAPER:
				return [7325, -5742, 60803];
			case W_MP40:
			case W_AFTERBURNER:
				return [11621, -9366, 79787];
			case W_MP5K:
			case W_KOLLIDER:
				return [10327, -9776, 45327];
			case W_STG:
			case W_SPATZ:
				return [10300, -10230, 100000];
			case W_M1:
			case W_M1000:
				return [7223, -4235, 94189];
			case W_BROWNING:
			case W_ACCELERATOR:
				return [7374, -8656, 84620];
			case W_PTRS:
			case W_PENETRATOR:
				return [5768, -7709, 160570];
			case W_TYPE:
			case W_SAMURAI:
				return [488, -2300, 25300];
			case W_TESLA:
			case W_DG3:
				return [12347, -9557, 108920];
			case W_RAY:
			case W_PORTER:
				return [12566, -6463, 49165];
			default:
				return [5488, -2742, 35300];
		}
		return [0, 0, 0];
}

float (float wep) GetWeaponFlash_Size = {

	switch(wep) {
		case W_COLT:
            return 5;
		case W_BIATCH:
			return 5;
		case W_KAR:
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
		case W_ARMAGEDDON:
		case W_SPRING:
		case W_PULVERIZER:
			return 15;
		case W_THOMPSON:
		case W_GIBS:
			return 8;
		case W_TRENCH:
		case W_GUT:
			return 19;
		case W_357:
		case W_KILLU:
			return 7;
		case W_MG:
		case W_BARRACUDA:
			return 16;
		case W_DB: 
		case W_BORE:
			return 18;
		case W_SAWNOFF:
			return 20;
		case W_M1A1:
		case W_WIDDER:
			return 14;
		case W_BAR:
		case W_WIDOW:
			return 16;
		case W_FG:
		case W_IMPELLER:
			return 16;
		case W_GEWEHR:
		case W_COMPRESSOR:
			return 12;
		case W_PPSH:
		case W_REAPER:
			return 12;
		case W_MP40:
		case W_AFTERBURNER:
			return 10;
		case W_MP5K:
		case W_KOLLIDER:
			return 10;
		case W_STG:
		case W_SPATZ:
			return 16;
		case W_M1:
		case W_M1000:
			return 14;
		case W_BROWNING:
		case W_ACCELERATOR:
			return 16;
		case W_PTRS:
		case W_PENETRATOR:
			return 30;
		case W_TYPE:
		case W_SAMURAI:
			return 5;
		case W_TESLA:
		case W_DG3:
			return 20;
		case W_RAY:
		case W_PORTER:
			return 10;
		default:
			return 5;
	}
}

// Returns the amount needed to zoom in a weapon. In near-fov "units".
float(float wep) GetWeaponZoomAmount =
{
	switch(wep) {
		case W_COLT:
            return 10;
		case W_KAR:
		case W_ARMAGEDDON:
		case W_SPRING:
		case W_PULVERIZER:
			return 25;
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
			return 47;
		case W_THOMPSON:
		case W_GIBS:
			return 10;
		case W_TRENCH:
		case W_GUT:
			return 10;
		case W_357:
		case W_KILLU:
			return 5;
		case W_MG:
		case W_BARRACUDA:
			return 15;
		case W_DB:
		case W_BORE:
		case W_SAWNOFF:
			return 10;
		case W_M1A1:
		case W_WIDDER:
			return 20;
		case W_BAR:
		case W_WIDOW:
			return 30;
		case W_FG:
		case W_IMPELLER:
			return 30;
		case W_GEWEHR:
		case W_COMPRESSOR:
			return 25;
		case W_PPSH:
		case W_REAPER:
			return 10;
		case W_MP40:
		case W_AFTERBURNER:
			return 10;
		case W_MP5K:
		case W_KOLLIDER:
			return 10;
		case W_STG:
		case W_SPATZ:
			return 20;
		case W_M1:
		case W_M1000:
			return 25;
		case W_BROWNING:
		case W_ACCELERATOR:
			return 15;
		case W_PTRS:
		case W_PENETRATOR:
			return 50;
		case W_TYPE:
		case W_SAMURAI:
			return 10;
		case W_RAY:
		case W_PORTER:
			return 5;
		default: return 0;
	}

	return 0;
}

//
// WepDef_HasSniperScore(weapon)
// Returns true if the weapon should display the Scope
// HUD element when Aiming down the Sights.
//
float(float weapon) WepDef_HasSniperScore =
{
	switch(weapon) {
		case W_KAR_SCOPE:
		case W_HEADCRACKER:
		case W_PTRS:
		case W_PENETRATOR:
			return true;
		default:
			return false;
	}

	return false;
}

//
// WepDef_WeaponMaxSpread(weapon, stance)
// Returns the maximum amount of Spread a Weapon
// can output. This is based on data manipulation of
// crosshair values.
//
float(float weapon, float stance) WepDef_WeaponMaxSpread =
{
	return CrossHairMaxSpread(weapon, stance)/2.5;
}

#ifndef CSQC

//
// WepDef_WeaponSpread(weapon, stance)
// Returns the general amount of Spread a Weapon
// can output. This is based on data manipulation of
// crosshair values.
//

float(float weapon, float stance) WepDef_WeaponSpread =
{
	// Early out.
	if (self.recoil_delay > time)
		return WepDef_WeaponMaxSpread(weapon, stance);

	// Increase spread over time.
	return (CrossHairWeapon(weapon, stance)/2) + self.cur_spread;
}

#endif // CSQC

//
// WepDef_CalculateMeleeDamage(weapon, has_bowie)
// Returns the amount of melee damage the Player can
// do given their weapon and Bowie Knife status.
//
float(float weapon, float has_bowie) WepDef_CalculateMeleeDamage =
{
	switch(weapon) {
		case W_BK:
			if (has_bowie)
				return 1000;
			return 500;
			break;
		case W_KRAUS:
			if (has_bowie)
				return 1500;
			return 1000;
			break;
		default:
			break;
	}

	if (has_bowie)
		return 1000;

	return 150;
}

//
// WepDef_DoesNotADS(weapon)
// Returns true if the weapon should not be allowed
// to aim down the sight.
//
float(float weapon) WepDef_DoesNotADS =
{
	switch(weapon) {
		case W_TESLA:
		case W_DG3:
		case W_BK:
		case W_KRAUS:
			return true;
		default:
			return false;
	}

	return false;
}

//
// WepDef_GetWeaponMeleeRange(weapon)
// Returns the range to be used when performing a trace
// to dictate how far away an object has to be for
// a Melee to perform successfully.
//
float(float weapon) WepDef_GetWeaponMeleeRange =
{
	switch(weapon) {
		case W_BK:
		case W_KRAUS:
			return 96;
		default:
			return 88;
	}

	return 88;
};

// FIXME -- data-drive these.
#define MELEE_BOWIE_FIRST_FRAME_NORMAL 	0
#define MELEE_BOWIE_LAST_FRAME_NORMAL	3
#define MELEE_BOWIE_FIRST_FRAME_LUNGED	4
#define MELEE_BOWIE_LAST_FRAME_LUNGED	10
#define MELEE_BOWIE_DURATION_NORMAL		0.65
#define MELEE_BOWIE_DURATION_LUNGED		1.0
#define MELEE_BOWIE_VIEWMODEL_PATH 		"models/weapons/knife/v_bowie.mdl"
#define MELEE_KNIFE_FIRST_FRAME_NORMAL 	0
#define MELEE_KNIFE_LAST_FRAME_NORMAL	3
#define MELEE_KNIFE_FIRST_FRAME_LUNGED	4
#define MELEE_KNIFE_LAST_FRAME_LUNGED	12
#define MELEE_KNIFE_DURATION_NORMAL		0.45
#define MELEE_KNIFE_DURATION_LUNGED		0.74
#define MELEE_KNIFE_VIEWMODEL_PATH 		"models/weapons/knife/v_knife.mdl"

//
// WepDef_IsMeleeWeapon(weapon)
// Returns true if the weapon provided has a melee-action
//
float(float weapon) WepDef_IsMeleeWeapon =
{
	switch(weapon) {
		case W_BK:
		case W_KRAUS:
			return true;
		default:
			return false;
	}

	return false;
}

//
// WepDef_GetMeleeModel(weapon, has_bowie)
// Returns the viewmodel to play for Melee animations.
//
string(float weapon, float has_bowie) WepDef_GetMeleeModel =
{
	if (WepDef_IsMeleeWeapon(weapon)) {
		return GetWeaponModel(weapon, false);
	} else {
		if (has_bowie)
			return MELEE_BOWIE_VIEWMODEL_PATH;
		else
			return MELEE_KNIFE_VIEWMODEL_PATH;
	}
};

//
// WepDef_GetMeleeFirstFrame(weapon, did_lunge, has_bowie)
// Returns the first frame of animation for Melee
// relative to currently held weapon, if the attack
// lunged or not, and if the Bowie Knife is in-hand.
//
float(float weapon, float did_lunge, float has_bowie) WepDef_GetMeleeFirstFrame =
{
	float return_value;
	
	if (did_lunge)
		return_value = GetFrame(weapon, MELEE_LUNGED_START);
	else
		return_value = GetFrame(weapon, MELEE_NORMAL_START);

	// We have a specific melee weapon.
	if (return_value)
		return return_value;

	if (has_bowie) {
		if (did_lunge)
			return MELEE_BOWIE_FIRST_FRAME_LUNGED;
		else
			return MELEE_BOWIE_FIRST_FRAME_NORMAL;
	} else {
		if (did_lunge)
			return MELEE_KNIFE_FIRST_FRAME_LUNGED;
		else
			return MELEE_KNIFE_FIRST_FRAME_NORMAL;
	}

	return 0;
};

//
// WepDef_GetMeleeLastFrame(weapon, did_lunge, has_bowie)
// Returns the final frame of animation for Melee
// relative to currently held weapon, if the attack
// lunged or not, and if the Bowie Knife is in-hand.
//
float(float weapon, float did_lunge, float has_bowie) WepDef_GetMeleeLastFrame =
{
	float return_value;
	
	if (did_lunge)
		return_value = GetFrame(weapon, MELEE_LUNGED_END);
	else
		return_value = GetFrame(weapon, MELEE_NORMAL_END);

	// We have a specific melee weapon.
	if (return_value)
		return return_value;

	if (has_bowie) {
		if (did_lunge)
			return MELEE_BOWIE_LAST_FRAME_LUNGED;
		else
			return MELEE_BOWIE_LAST_FRAME_NORMAL;
	} else {
		if (did_lunge)
			return MELEE_KNIFE_LAST_FRAME_LUNGED;
		else
			return MELEE_KNIFE_LAST_FRAME_NORMAL;
	}

	return 0;
};

//
// WepDef_GetMeleeAnimDuration(weapon, did_lunge, has_bowie)
// Returns the amount of time it should take for animation
// playback of a Melee animation, given factors.
//
float(float weapon, float did_lunge, float has_bowie) WepDef_GetMeleeAnimDuration =
{
	float return_value;
	
	if (did_lunge)
		return_value = getWeaponDelay(weapon, MELEE_LUNGED);
	else
		return_value = getWeaponDelay(weapon, MELEE_NORMAL);

	// We have a specific melee weapon.
	if (return_value)
		return return_value;

	if (has_bowie) {
		if (did_lunge)
			return MELEE_BOWIE_DURATION_LUNGED;
		else
			return MELEE_BOWIE_DURATION_NORMAL;
	} else {
		if (did_lunge)
			return MELEE_KNIFE_DURATION_LUNGED;
		else
			return MELEE_KNIFE_DURATION_NORMAL;
	}

	return 0;
};

//
// WepDef_DoesNotPlayUpgradedSound(weapon)
// Returns true if the weapon should not play
// the special Pack-A-Punch fire sound over
// it's standard weapon fire.
//
float(float weapon) WepDef_DoesNotPlayUpgradedSound =
{
	switch(weapon) {
		case W_DG3:
		case W_PORTER:
    case W_FIW:
			return true;
		default:
			return false;
	}

	return false;
}

//
// WepDef_OnlyOneAllowed(weapon)
// Returns true if server is only allowed to distribute
// this weapon to one player at a time (e.g., from Box).
//
float(float weapon) WepDef_OnlyOneAllowed =
{
	switch(weapon) {
		case W_TESLA:
		case W_DG3:
			return true;
		default:
			return false;
	}

	return false;
}

//
// WepDef_GetWeaponIDFromName(weapon)
// Takes a string input and returns the weapon ID
// from the associated string. Will be deprecated
// when weapons are data-driven.
//
float(string weapon) WepDef_GetWeaponIDFromName =
{
	switch(weapon) {
		case "m1911": return W_COLT;
		case "kar98k": return W_KAR;
		case "thompson": return W_THOMPSON;
		case "357_magnum": return W_357;
		case "bar": return W_BAR;
		case "ballistic_knife": return W_BK;
		case "browning": return W_BROWNING;
		case "double_barreled_shotgun": return W_DB;
		case "fg42": return W_FG;
		case "gewehr": return W_GEWEHR;
		case "kar98k_scoped": return W_KAR_SCOPE;
		case "m1_garand": return W_M1;
		case "m1a1_carbine": return W_M1A1;
		case "m2_flamethrower": return W_M2;
		case "mp40": return W_MP40;
		case "mg42": return W_MG;
		case "panzerschreck": return W_PANZER;
		case "ppsh-41": return W_PPSH;
		case "ptrs-41": return W_PTRS;
		case "ray_gun": return W_RAY;
		case "sawed_off_shotgun": return W_SAWNOFF;
		case "stg-44": return W_STG;
		case "trenchgun": return W_TRENCH;
		case "type_100": return W_TYPE;
		case "wunderwaffe": return W_TESLA;
		case "mp5k": return W_MP5K;
		case "springfield": return W_SPRING;
		default: return W_NOWEP;
	}
	return W_COLT;
}

//
// WepDef_WeaponCanGibEnemy(weapon)
// Returns true if the weapon is capable of
// gibbing/blowing limbs off.
//
float WepDef_WeaponCanGibEnemy(float weapon)
{
	switch(weapon) {
		case W_COLT: return 0;
		case W_357: return 0;
		case W_KILLU: return 0;
		default: return 1;
	}

	return 1;
}

//
// WepDef_GetWeaponCrosshairType(weapon)
// Returns the type of crosshair used by active
// weapon.
// 0. No crosshair
// 1. Standard crosshair (+)
// 2. Area of Effect (o)
// 3. Dot crosshair (.) (unused).
// 4 is reserved for the grenade, do not use.
//
float WepDef_GetWeaponCrosshairType(float weapon)
{
	switch(weapon) {
		case W_M2:
		case W_FIW:
		case W_TESLA:
		case W_DG3:
			return 2;
		case W_PANZER:
		case W_LONGINUS:
			return 0;
		default:
			return 1;
	}
}

//
// WepDef_GetLeftFlashOffset(weapon)
// Returns the offset from client view origin
// for a left-handed weapon's muzzleflash.
// See GetWeaponFlash_Offset() for data structure.
//
vector(float weapon) WepDef_GetLeftFlashOffset =
{
    switch(weapon) {
        case W_BIATCH:
            return [-8639, -3621, 39337];
        default:
            return [0, 0, 0];
    }
    return [0, 0, 0];
}
