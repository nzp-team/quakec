/*
	client/particles.qc

	CSQC-Driven Particle Runner.

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

// Stored outside of struct for stack efficency.
float   particle_optional_field;
float   particle_optional_entity;
vector  particle_position;

//
// Particles_MuzzleflashCallback()
// Executes Muzzleflash Particle effect.
// Optional: Which weapon was fired (left/right, for akimbo).
//
void() Particles_MuzzleflashCallback =
{
    // Do not display Muzzleflashes if we're using a Sniper Scope or not drawing the viewmodel.
    if (getstatf(STAT_WEAPONZOOM) == 2 || !cvar("r_drawviewmodel") || cvar("chase_active"))
        return;

    // Organized storage of optional_field and optional_entity.
    float weapon_side = particle_optional_field;
    float hit_entity = particle_optional_entity;

    // Obtain our input view angles.
    getinputstate(servercommandframe);
    makevectors(input_angles);

    vector muzzleflash_offset;
	vector muzzleflash_position = getviewprop(VF_ORIGIN);

	// If firing the left side of a dual-wield weapon, use the left side muzzleflash offset.
    if (weapon_side == 0 && IsDualWeapon(getstatf(STAT_ACTIVEWEAPON)))
		muzzleflash_offset = WepDef_GetLeftFlashOffset(getstatf(STAT_ACTIVEWEAPON))/1000;
	// Otherwise, use the standard offset.
	else
		muzzleflash_offset = GetWeaponFlash_Offset(getstatf(STAT_ACTIVEWEAPON))/1000;

	// Move to match ADS position if Zoomed in.
	if(getstatf(STAT_WEAPONZOOM) == 1) {  
		muzzleflash_offset += GetWeaponADSOfs(getstatf(STAT_ACTIVEWEAPON))/1000;
	}
				
	muzzleflash_position += v_forward * muzzleflash_offset_z;
	muzzleflash_position += v_right * muzzleflash_offset_x;
	muzzleflash_position += v_up * muzzleflash_offset_y;

	float muzzleflash_type = rint(random() * 2); // Choose one of three Muzzleflash variances.

	// Display Muzzleflash Particle and Dynamic Light
	if (IsPapWeapon(getstatf(STAT_ACTIVEWEAPON))) {			
		pointparticles(particleeffectnum(strcat("muzzle.muzzle_pap_part", ftos(muzzleflash_type))), muzzleflash_position, '0 0 0', 1);

		// Pack-A-Punched Weapons can display either a Blue or Red light
		if (random() > 0.5)
			dynamiclight_add(muzzleflash_position, 256, '0.7 0 0');
		else
			dynamiclight_add(muzzleflash_position, 256, '0 0 0.7');
	} else {
		pointparticles(particleeffectnum(strcat("muzzle.muzzle_part", ftos(muzzleflash_type))), muzzleflash_position, '0 0 0', 1);
		dynamiclight_add(muzzleflash_position, 256, '1.2 0.7 0.2');
	}

    // Grenade-Lunching weapons should not show decals.
    if (GetFiretype(getstatf(STAT_ACTIVEWEAPON)) == FIRETYPE_GRENADE)
		return;
			
	if(hit_entity == 0) {
		pointparticles(particleeffectnum("weapons.impact"), particle_position, '0 0 0', 1);
		pointparticles(particleeffectnum("weapons.impact_decal"), particle_position, '0 0 0', 1);
	}

};

// This struct must be ordered linearly for fast array lookups. Do NOT skip indexes.
var struct
{
    float   particle_type;      // ID of Particle.
    string  particle_string;    // String that refers to the Particle name/gamedir path. May be blank if callbacks utilized.
    void()  particle_func;      // Callback that also gets executed on Particle_RunParticle, typically __NULL__. optional_field used here.
} csqc_particles[] =
{
    {CSQC_PART_MUZZLEFLASH, "", Particles_MuzzleflashCallback},     // View Entity Muzzleflashes.
    {CSQC_PART_EXPLOSION, "weapons.explode", __NULL__},             // Explosion effect.
    {CSQC_PART_BLOODIMPACT, "blood.blood_particle", __NULL__},      // Blood Impact effect.
    {CSQC_PART_ZOMBIEGIB, "blood.gibs", __NULL__},                  // Zombie Gib effect.
    {CSQC_PART_FIRE, "flames.flame_particle", __NULL__}             // Fire/flame effect.
};

//
// Particles_RunParticle(particle_type, position, optional_field, optional_entity)
// Runs specific particle given it's type, location,
// and optional fields to pass to an optional callback.
//
void(float particle_type, vector position, float optional_field, float optional_entity) Particles_RunParticle =
{
    // If the requested particle index does not have a callback function,
    // run it outright.
    if (csqc_particles[particle_type].particle_func == __NULL__)
        pointparticles(particleeffectnum(csqc_particles[particle_type].particle_string), position, '0 0 0', 1);
    // It has a callback -- so execute it instead.
    else {
        particle_optional_field = optional_field;
        particle_optional_entity = optional_entity;
        particle_position = position;
        csqc_particles[particle_type].particle_func();
        particle_optional_field = particle_optional_entity = 0;
        particle_position = '0 0 0';
    }
};

//
// Particles_Init()
// Particles never draw on their first run, so "allocate"
// them here. Particles only called via callbacks need
// invidiually referenced.
//
void() Particles_Init =
{
    int i;
    //
    // Callback Particles
    //

    // Muzzleflashes.
	for(i = 0; i < 3; i++) {
		pointparticles(particleeffectnum(strcat("muzzle.muzzle_pap_part", itos(i))), '0 0 0', '0 0 0', 0);
		pointparticles(particleeffectnum(strcat("muzzle.muzzle_part", itos(i))), '0 0 0', '0 0 0', 0);
	}	

    //
    // Normal References
    //	
    for(i = 0; i < csqc_particles.length; i++) {
        pointparticles(particleeffectnum(csqc_particles[i].particle_string), '0 0 0', '0 0 0', 0);
    }			
};