/*
	client/view_model.qc

	View Model Drawing and Manipulation.

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

vector current_viewmodel_ads_position;
vector viewmodel_slack_distance;
vector last_viewangles;

#define VIEWMODEL_ADS_TIME_FACTOR       (16 * frametime) // We want this to be server dependent.
#define VIEWMODEL_ANGLE_SLACK_FACTOR    (3)

//MOVEME
float(float a, float b, float mix) lerp =
{
    if (mix <= 0) return a;
    if (mix >= 1) return b;
    return (b * mix + a * ( 1 - mix ) );
};

//MOVEME
float(float value, float minValue, float maxValue) clamp = {
    if (value < minValue) return minValue;
    else if (value > maxValue) return maxValue;

    return value;
};
	
//MOVEME
float(float source, float target, float smoothing, float dt) damp =
{
    return lerp(source, target, 1 - pow(smoothing, dt));
};

//
// ViewModel_CalcBob()
// Blubs' refactored V_CalcBob reimplemented in CSQC.
// Edited to also add idle bobbing if low speed.
//
float(float speed, float which) ViewModel_CalcBob = 
{
    float sprint = 1;
    float client_zoom = getstatf(STAT_WEAPONZOOM);
    float cl_bobup_value = cvar("cl_bobup");
    float cl_bobside_value = cvar("cl_bobside");

    // Bob idle-y, instead of presenting as if in-motion.
    if (speed < 0.1) {
        // If we're zoomed in, we only want idle bobbing to be very subtle..
        if (client_zoom == 1)
            speed = 0.05;
        else
            speed = 0.25;

        if (which == 0)
            return cl_bobup_value * 10 * speed * (sprint * sprint) * sin(cltime * 3.25 * sprint);
        else
            return cl_bobside_value * 50 * speed * (sprint * sprint * sprint) * sin((cltime * sprint) - (M_PI * 0.25));
    } 
    // Normal walk/sprint bob.
    else {
        if (client_zoom == 3)
        sprint = 1.8;

        if (which == 0)
            return cl_bobup_value * 36 * speed * (sprint * sprint) * sin(cltime * 12.5 * sprint);
        else
            return cl_bobside_value * 36 * speed * (sprint * sprint * sprint) * sin((cltime * 6.25 * sprint) - (M_PI * 0.25));
    }
};

//
// ViewModel_CalcViewAngleDifference()
// Returns the difference in client viewangles between this frame
// and last.
//
vector() ViewModel_CalcViewAngleDifference =
{
    if (last_viewangles == '0 0 0')
        last_viewangles = getviewprop(VF_ANGLES);

    vector cl_viewangles = getviewprop(VF_ANGLES);
    vector difference = last_viewangles - cl_viewangles;
    last_viewangles = cl_viewangles;

    // Invert the X (up/down) axis, so that viewmodel
    // accels downward when camera moves up, and vice versa.
    difference[0] = -difference[0];
    return difference;
};

//
// ViewModel_CalcSlack()
// Calculates "slack" -- how far behind the viewents
// should fall behind the camera. Appended to viewent's angles.
//
vector() ViewModel_CalcSlack =
{
    // Calculate the target slack distance based on the view angle difference
    vector target_slack_distance = ViewModel_CalcViewAngleDifference();
    target_slack_distance[0] *= VIEWMODEL_ANGLE_SLACK_FACTOR;
    target_slack_distance[1] *= VIEWMODEL_ANGLE_SLACK_FACTOR;
    target_slack_distance[2] *= VIEWMODEL_ANGLE_SLACK_FACTOR;

    for(float i = 0; i < 2; i++) {
        // Apply smoothing to the viewmodel_slack_distance
        viewmodel_slack_distance[i] = damp(viewmodel_slack_distance[i], target_slack_distance[i], 0.1, clframetime * 4);

        // Clamp the values to a maximum threshold
        // Sorta nasty hack.. or something.. if the client is under 60FPS clamp at a lower value
        if (clframetime > 0.016)
            viewmodel_slack_distance[i] = clamp(viewmodel_slack_distance[i], -0.2, 0.2);
        else
            viewmodel_slack_distance[i] = clamp(viewmodel_slack_distance[i], -0.5, 0.5);
    }

    return viewmodel_slack_distance;
};

//
// ViewModel_Animate(viewent)
// Interpolation and animation for specified view entity.
//
void(entity viewent) ViewModel_Animate =
{
    float new_frame, new_model, anim_duration = 0;

    if (viewent == cl_viewent) {
        new_frame = getstatf(STAT_WEAPONFRAME);
        new_model = getstatf(STAT_WEAPONMODELI);
        anim_duration = getstatf(STAT_WEAPONDURATION);
    } else { // Assumes cl_viewent2
        new_model = getstatf(STAT_WEAPON2MODELI);
        anim_duration = getstatf(STAT_WEAPON2DURATION);

        // If our current weapon is not dual-wielded, we want weapon2frame
        // to always match standard weapon frames.
        if (!IsDualWeapon(getstatf(STAT_ACTIVEWEAPON)))
            new_frame = getstatf(STAT_WEAPONFRAME);
        else
            new_frame = getstatf(STAT_WEAPON2FRAME);
    }

    if (!anim_duration) anim_duration = 0.1; // Default to 10fps.

    // Server requested a model change
    if (new_model != viewent.modelindex) {
        viewent.modelindex = new_model;

        // Don't lerp new models. Fixes perceieved stutter.
        viewent.frame = new_frame;

        // If we switched to a different weapon model, 
        // make sure to update the HUD.
        if (getmodelindex(GetWeaponModel(getstatf(STAT_ACTIVEWEAPON), false)) == viewent.modelindex)
            HUD_Change_time = time + 7;
    }

    // Update the skin.
    viewent.skin = getstatf(STAT_WEAPONSKIN);

    // Server requested a frame change
    if (new_frame != viewent.frame) {
        viewent.frame2 = viewent.frame;
        viewent.frame2time = viewent.frame1time;
        viewent.frame = new_frame;
        viewent.frame1time = 0;
        viewent.lerpfrac = 1;
    }
    else {
        viewent.frame = new_frame;
    }

    viewent.lerpfrac -= frametime * (1/anim_duration);
    viewent.frame1time += frametime;
};

//
// ViewModel_MotionBob(viewent)
// Bobs the specified view entity with ViewModel_CalcBob.
//
void(entity viewent) ViewModel_MotionBob =
{
    // If the server is paused, early-out..
    if (serverkey(SERVERKEY_PAUSESTATE) == "1")
        return;

    float client_speed;

    // Calculate a rough estimate of the client's speed
    client_speed = (0.2 + sqrt((playerVelocity[0] * playerVelocity[0]) + (playerVelocity[1] * playerVelocity[1])))/280;

    // Run the bob calculation
    float bob, bobside;
    bob = ViewModel_CalcBob(client_speed, 0);
    bobside = ViewModel_CalcBob(client_speed, 1);

    // Set as start of view entity's origin offset.
    viewent.origin[2] = bob*0.5;
    viewent.origin[1] = bobside * 0.4;
};

//
// ViewModel_GetADSPosition()
// Returns a vector representing current offset
// progress on Aiming Down the Sight.
//
vector() ViewModel_GetADSPosition =
{
    vector ads_offset = '0 0 0';
    float client_zoom = getstatf(STAT_WEAPONZOOM);
    if (client_zoom == 1 || client_zoom == 2) {
        // These are ordered differently in QuakeC because ??
        // right, up, forward
        vector temp_adsofs = GetWeaponADSOfs(getstatf(STAT_ACTIVEWEAPON));

        // Translate to proper order, and re-gain precision.
        ads_offset[0] = temp_adsofs[2]/1000;
        ads_offset[1] = -temp_adsofs[0]/1000; // Y needs to be negative here -- matches Blender output, discrepancy from glQuake.
        ads_offset[2] = temp_adsofs[1]/1000;
    }

    // Interpolate values in/out of ADS over time.
    current_viewmodel_ads_position[0] += (ads_offset[0] - current_viewmodel_ads_position[0]) * VIEWMODEL_ADS_TIME_FACTOR;
    current_viewmodel_ads_position[1] += (ads_offset[1] - current_viewmodel_ads_position[1]) * VIEWMODEL_ADS_TIME_FACTOR;
    current_viewmodel_ads_position[2] += (ads_offset[2] - current_viewmodel_ads_position[2]) * VIEWMODEL_ADS_TIME_FACTOR;
    
    // Limit the vector to avoid bouncing back and forth on low framerates.
    if (client_zoom == 1 || client_zoom == 2) {
        if (current_viewmodel_ads_position[0] > ads_offset[0])  current_viewmodel_ads_position[0] = ads_offset[0];
        if (current_viewmodel_ads_position[1] > ads_offset[1])  current_viewmodel_ads_position[1] = ads_offset[1];
        if (current_viewmodel_ads_position[2] > ads_offset[2])  current_viewmodel_ads_position[2] = ads_offset[2];
    } else {
        if (current_viewmodel_ads_position[0] < 0)  current_viewmodel_ads_position[0] = 0;
        if (current_viewmodel_ads_position[1] < 0)  current_viewmodel_ads_position[1] = 0;
        if (current_viewmodel_ads_position[2] < 0)  current_viewmodel_ads_position[2] = 0;
    }
    
    // Return progress on Zoom position.
    return current_viewmodel_ads_position;
};

//
// ViewModel_Draw()
// Performs drawing routine for cl_viewent and cl_viewent2
//
void() ViewModel_Draw =
{
    // Spawn the model entities if they do not already exist..
    if (!cl_viewent) {
        cl_viewent = spawn();
        cl_viewent2 = spawn();
        cl_viewent.renderflags = cl_viewent2.renderflags = RF_VIEWMODEL;
    }

    // If we're zoomed in with a Sniper scope or r_drawviewmodel is false, early-out.
    if (!cvar("r_drawviewmodel") || getstatf(STAT_WEAPONZOOM) == 2 || cvar("chase_active"))
        return;

    cl_viewent.origin = cl_viewent2.origin = '0 0 0';

    // Bob while in motion
    ViewModel_MotionBob(cl_viewent);
    ViewModel_MotionBob(cl_viewent2);

    // Adjust viewmodel position based on ADS value.
    vector viewent_ads_position = ViewModel_GetADSPosition();
    cl_viewent.origin += viewent_ads_position;
    cl_viewent2.origin += viewent_ads_position;

    // Animate and Interpolate
    ViewModel_Animate(cl_viewent);
    ViewModel_Animate(cl_viewent2);

    // Have the View Model "lag behind" the camera a bit.
    cl_viewent.angles = cl_viewent2.angles = ViewModel_CalcSlack();

    // Send the viewents to engine for drawing.
    addentity(cl_viewent);
    addentity(cl_viewent2);
};