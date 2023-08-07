DEFINE_ANIM(zombie_idle, 1,2,3,4,5,6,7,8,9,10,11,12,13);                                                // Defines: get_anim_frame_zombie_idle,                  get_anim_length_zombie_idle
DEFINE_ANIM(zombie_rise, 14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37);      // Defines: get_anim_frame_zombie_rise,                  get_anim_length_zombie_rise
DEFINE_ANIM(zombie_walk1, 38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53);                             // Defines: get_anim_frame_zombie_walk1,                 get_anim_length_zombie_walk1
DEFINE_ANIM(zombie_walk2, 54,55,56,57,58,59,60,61,62,63,64,65,66,67);                                   // Defines: get_anim_frame_zombie_walk2,                 get_anim_length_zombie_walk2
DEFINE_ANIM(zombie_walk3, 68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83);                             // Defines: get_anim_frame_zombie_walk3,                 get_anim_length_zombie_walk3
DEFINE_ANIM(zombie_jog1, 84,85,86,87,88,89,90,91,92);                                                   // Defines: get_anim_frame_zombie_jog1,                  get_anim_length_zombie_jog1
DEFINE_ANIM(zombie_run1, 93,94,95,96,97,98,99,100,101,102);                                             // Defines: get_anim_frame_zombie_run1,                  get_anim_length_zombie_run1
DEFINE_ANIM(zombie_attack1, 103,104,105,106,107);                                                       // Defines: get_anim_frame_zombie_attack1,               get_anim_length_zombie_attack1
DEFINE_ANIM(zombie_attack2, 108,109,110,111,112,113);                                                   // Defines: get_anim_frame_zombie_attack2,               get_anim_length_zombie_attack2
DEFINE_ANIM(zombie_window_rip_board1, 182,183,184,185,186,187,188,189,190,191,192);                     // Defines: get_anim_frame_zombie_window_rip_board1,     get_anim_length_zombie_window_rip_board1
DEFINE_ANIM(zombie_window_rip_board2, 192,193,194,195,196,197,198,199,200,201,202);                     // Defines: get_anim_frame_zombie_window_rip_board2,     get_anim_length_zombie_window_rip_board2
DEFINE_ANIM(zombie_window_attack, 202,203,204,205,206,207,208,209,210,211);                             // Defines: get_anim_frame_zombie_window_attack,         get_anim_length_zombie_window_attack
DEFINE_ANIM(zombie_window_hop, 114,115,116,117,118,119,120,121,122,123);                                // Defines: get_anim_frame_zombie_window_hop,            get_anim_length_zombie_window_hop
DEFINE_ANIM(zombie_die1, 124,125,126,127,128,129,130,131,132,133,134);                                  // Defines: get_anim_frame_zombie_die1,                  get_anim_length_zombie_die1
DEFINE_ANIM(zombie_die2, 135,136,137,138,139);                                                          // Defines: get_anim_frame_zombie_die2,                  get_anim_length_zombie_die2
DEFINE_ANIM(zombie_die3, 140,141,142,143,144,145,146,147,148,149);                                      // Defines: get_anim_frame_zombie_die3,                  get_anim_length_zombie_die3
DEFINE_ANIM(zombie_die_wunder, 212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228);    // Defines: get_anim_frame_zombie_die_wunder,            get_anim_length_zombie_die_wunder
DEFINE_ANIM(zombie_fall, 150,151,152,153);                                                              // Defines: get_anim_frame_zombie_fall,                  get_anim_length_zombie_fall
DEFINE_ANIM(zombie_land, 154,155,156,157,158,159,159);                                                  // Defines: get_anim_frame_zombie_land,                  get_anim_length_zombie_land
DEFINE_ANIM(zombie_jump, 161,162,163,164,165,166,167);                                                  // Defines: get_anim_frame_zombie_jump,                  get_anim_length_zombie_jump
DEFINE_ANIM(zombie_climb, 168,169,170,171,172,173,174,175,176,177,178,179,180,181);                     // Defines: get_anim_frame_zombie_climb,                 get_anim_length_zombie_climb
DEFINE_ANIM(zombie_jump_low, 164,165,166);                                                  // Defines: get_anim_frame_zombie_jump_low,              get_anim_length_zombie_jump_low
DEFINE_ANIM(zombie_climb_low, 171,172,173,174,175,176,177,178,179,180,181);                             // Defines: get_anim_frame_zombie_climb_low,             get_anim_length_zombie_climb_low
DEFINE_ANIM(zombie_fall_loop, 151,152,153,152);                                                              // Defines: get_anim_frame_zombie_fall_loop,            get_anim_length_zombie_fall_loop




#define AI_STATE_PATHING 0
#define AI_STATE_TRAVERSING 1


// Constructor. Called when calling `spawn(AI_Chase);`
void() AI_Chase::AI_Chase = {
    this.path_target = world;
    this.path_pos = world.origin;
    this.cur_anim_frametime = 0.1;
    // this.think_delta_time = 0.1; // Call `this.think();` 10x per second
};


void() AI_Chase::think = {

    // ------------------------------------------------------------------------
    // Animation logic
    // ------------------------------------------------------------------------

    // Check if we're updating the current animation being played
    if(this.cur_anim_get_frame_func != SUB_Null) {
        float cur_anim_prev_frame_idx = floor(this.cur_anim_frame_idx);
        this.cur_anim_frame_idx += 1;
        // this.cur_anim_frame_idx = (time - this.cur_anim_start_time) / this.cur_anim_frametime;

        // If at the final frame, we're done
        if(this.cur_anim_frame_idx >= this.cur_anim_length) {
            if(this.cur_anim_stop_type == ANIM_STOP_TYPE_LOOP) {
                    this.cur_anim_frame_idx = this.cur_anim_frame_idx % this.cur_anim_length;
            }
            else if(this.cur_anim_stop_type == ANIM_STOP_TYPE_NEXT_ANIM) {
                this.play_anim(
                    this.next_anim_get_frame_func, 
                    this.next_anim_length,
                    this.next_anim_stop_type);
                this.cur_anim_frametime = this.next_anim_frametime;
                // We started a new animation, play the frame callback
                cur_anim_prev_frame_idx = -1;
            }
            // Otherwise, treat it as ANIM_STOP_TYPE_STOP
            else { 
                this.cur_anim_frame_idx = min(this.cur_anim_frame_idx, this.cur_anim_length - 1);
                this.cur_anim_get_frame_func = (float(float)) SUB_Null;
                this.cur_anim_length = 0;
            }
        }

        // If we still have an animation:
        if(this.cur_anim_get_frame_func != SUB_Null) {
            // NOTE - We can control frame interpolation using the fractional
            // NOTE   portion of `cur_anim_frame_idx`, in case we ever have
            // NOTE   better control over MDL frame interpolation.
            this.cur_anim_frame_idx = floor(this.cur_anim_frame_idx);
            this.frame = this.cur_anim_get_frame_func(this.cur_anim_frame_idx);

            // if(floor(this.cur_anim_frame_idx) != cur_anim_prev_frame_idx) {
            //     this.frame_callback();
            // }
        }
        // print("Frame_idx: ", ftos(this.cur_anim_frame_idx), " Actual frame: ", ftos(this.frame), "\n");
    }
    // ------------------------------------------------------------------------

    // this.nextthink = time + this.think_delta_time;
    this.nextthink = time + this.cur_anim_frametime;
    this.think_callback();
};









void (float move_speed) AI_Chase::do_walk_to_goal = {
    if(move_speed == 0) {
        return;
    }

    vector goal_pos = path_pos;
    if(this.path_target != world) {
        goal_pos = this.path_target.origin;
    }



// TODO - For PSP, call engine-side function that gets us next walk point
#ifdef PC
	navmesh_pathfind_result* res = &(sv_zombie_pathfind_result[this.pathfind_result_idx]);
	float start_poly = sv_navmesh_get_containing_poly(this.origin);
	float goal_poly = sv_navmesh_get_containing_poly(goal_pos);
    float pathfind_success = sv_navmesh_pathfind_start(start_poly, goal_poly, this.origin, goal_pos, res);
    this.pathfind_cur_point_idx = 0;

    if(pathfind_success) {
        goal_pos = res->point_path_points[this.pathfind_cur_point_idx];

        // TOOD - If close, continue to next one...
        // TODO - Also make sure we're "close enough" in Z...
        if(vlen_xy(this.origin - goal_pos) < 5) {
            // print("Distance from target: ", ftos(vlen_xy(this.origin - goal_pos)), ", Cur point: ", ftos(this.pathfind_cur_point_idx), "\n");
            // print("Current traversal: ", ftos(res->point_path_traversals[this.pathfind_cur_point_idx]),"\n");
            // If this point path is a traversal, teleport to traversal end spot

            if(res->point_path_traversals[this.pathfind_cur_point_idx] != -1) {
                this.state = AI_STATE_TRAVERSING;
                this.substate = 0;
                this.cur_traversal_idx = res->point_path_traversals[this.pathfind_cur_point_idx];
                // print("Setting state to traversing.\n");
                // vector traversal_end_pos = sv_navmesh_get_traversal_end_pos(res->point_path_traversals[this.pathfind_cur_point_idx]);
                // print("Setting origin to end position: ", vtos(traversal_end_pos), "\n");
                // this.origin = traversal_end_pos;
            }
            this.pathfind_cur_point_idx += 1;
            goal_pos = res->point_path_points[this.pathfind_cur_point_idx];
        }
    }
    else {
        move_speed = 0;
        // TODO - Idle animation?
    }
#endif // PC


    this.ideal_yaw = vectoyaw(goal_pos - this.origin);
    ChangeYaw();
    vector new_velocity;
    float walk_dist = move_speed * this.cur_anim_frametime;
    float dist_to_goal = vlen(goal_pos - this.origin);
    if(walk_dist > dist_to_goal) {
        move_speed = dist_to_goal / this.cur_anim_frametime;
    }
    new_velocity = normalize(goal_pos - this.origin) * move_speed;
    new_velocity_z = this.velocity_z;
    this.velocity = new_velocity;
};















float get_zombie_walk_is_footstep(float frame) {
    switch(floor(frame)) {
        // ------------ Zombie Walk 1 --------------
        case 39:        // Right foot
        case 44:        // Left foot
        case 47:        // Right foot
        case 51:     // Left foot
            return 1;
        // ------------ Zombie Walk 2 --------------
        // ------------ Zombie Walk 3 --------------
        // ------------ Zombie Jog 1 --------------
        // ------------ Zombie Run 1 --------------
        default:
            return 0;
    }
}

float get_zombie_walk_dist_for_frame(float frame) {
    switch(floor(frame)) {
        // ------------ Zombie Walk 1 --------------
        case 38:
            return 8;
        case 39:
        case 40:
        case 41:
        case 42:
        case 43:
            return 3.5;
        case 44:
            return 8.8;
        case 45:
            return 9;
        case 46:
        case 47:
            return 4;
        case 48:
            return 7.8;
        case 49:
            return 5.2;
        case 50:
            return 2.4;
        case 51:
            return 2.8;
        case 52:
            return 6.5;
        case 53:
            return 7.7;
        // ------------ Zombie Walk 2 --------------
        case 54: 
            return 4.2;
        case 55: 
            return 5.9;
        case 56: 
            return 3;
        case 57: 
            return 5.7;
        case 58: 
            return 4.2;
        case 59: 
            return 7.2;
        case 60: 
            return 4.5;
        case 61: 
            return 3.4;
        case 62: 
            return 1.2;
        case 63: 
            return 6.7;
        case 64: 
            return 8.4;
        case 65: 
            return 1.3;
        case 66: 
            return 6.3;
        case 67: 
            return 3.6;
        // ------------ Zombie Walk 3 --------------
        case 68: 
            return 3.4;
        case 69: 
            return 2;
        case 70: 
            return 5.4;
        case 71: 
            return 5.6;
        case 72: 
            return 3;
        case 73: 
            return 3.1;
        case 74: 
            return 3;
        case 75: 
            return 2.9;
        case 76: 
            return 3.3;
        case 77: 
            return 2.2;
        case 78: 
            return 3.7;
        case 79: 
            return 4.2;
        case 80: 
            return 5.3;
        case 81: 
            return 5.2;
        case 82: 
            return 2.2;
        case 83: 
            return 2.4;
        // ------------ Zombie Jog 1 --------------
        case 84: 
        case 85: 
        case 86: 
        case 87: 
        case 88: 
        case 89: 
        case 90: 
        case 91: 
        case 92: 
            return 6;
        // ------------ Zombie Run 1 --------------
        case 93: 
        case 94: 
        case 95: 
        case 96: 
        case 97: 
        case 98: 
        case 99: 
        case 100: 
        case 101: 
        case 102: 
            return 15;
        default:
            return 0.0;
    }
}




void zombie_traversal_logic() {
    AI_Zombie zombie_ent = (AI_Zombie) self;

    float traversal_idx = zombie_ent.cur_traversal_idx;
    vector start_pos = sv_navmesh_traversals[traversal_idx].start_pos;
    vector midpoint_pos;
    vector end_pos = sv_navmesh_get_traversal_end_pos(traversal_idx);


    string traversal_type;
    traversal_type = "jump_up";
    // traversal_type = "jump_down";
    // traversal_type = "jump_gap";
    // traversal_type = "hop_barricade";
    // traversal_type = "hop_fence";
    // traversal_type = "window";
    // traversal_type = "teleport";

    // Jump up logic
    if(traversal_type == "jump_up") {
        // zombie_ent.angles.y = sv_navmesh_traversals[traversal_idx].angle;
        float delta_angle = sv_navmesh_traversals[traversal_idx].angle - zombie_ent.angles.y;
        // Apply smallest delta angle
        delta_angle = ((delta_angle + 180) % 360) - 180;
            // zombie_ent.angles.y = sv_navmesh_traversals[traversal_idx].angle;
            float delta_angle = sv_navmesh_traversals[traversal_idx].angle - zombie_ent.angles.y;

            // FIXME - Replace this with mods....
            // delta_angle = (((delta_angle - 180) % 180) + 180) % 180;
            // ((delta_angle - 180) % 360) + 180
            while(delta_angle < -180) {
                delta_angle += 360;
            }
            while(delta_angle > 180) {
                delta_angle -= 360;
            }

            zombie_ent.angles.y += 0.5 * delta_angle;        zombie_ent.angles.y += 0.5 * delta_angle;

        // Jump up traversal consists of the following substates:
        //      0: Start traversal, play jump up anim
        //      1: Wait for jump up anim to complete
        //      2: Move zombie up to ledge
        //      3: Play zombie get up animation
        //
        // Check height of ledge we're climbing:
        float traversal_height = end_pos.z - start_pos.z;
        vector goal_pos;
        float traversal_time;
        float lerp_frac;
        float anim_time;

        // Fall down
        if(traversal_height < 0 ) {
            if(zombie_ent.substate == 0) {
                zombie_ent.movetype = MOVETYPE_STEP;
                zombie_ent.play_anim(get_anim_frame_zombie_fall, get_anim_length_zombie_fall(), ANIM_STOP_TYPE_STOP);
                zombie_ent.queue_anim(get_anim_frame_zombie_fall_loop, get_anim_length_zombie_fall_loop(), ANIM_STOP_TYPE_LOOP);
                traversal_time = min(-traversal_height * (0.35 / 100.0), 2.0);
                zombie_ent.cur_traversal_start_time = time;
                zombie_ent.cur_traversal_end_time = time + traversal_time;
                zombie_ent.substate = 1;
            }
            else if(zombie_ent.substate == 1) {
                lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
                zombie_ent.origin = lerpVector(start_pos, end_pos, lerp_frac * lerp_frac);
                if(lerp_frac >= 1.0) {
                    zombie_ent.play_anim(get_anim_frame_zombie_land, get_anim_length_zombie_land(), ANIM_STOP_TYPE_NEXT_ANIM);
                    zombie_ent.cur_anim_frametime = 0.05;
                    zombie_ent.queue_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
                    zombie_ent.state = AI_STATE_PATHING;
                    zombie_ent.movetype = MOVETYPE_WALK;
                }
            }
        }


        // Short ledge
        else if(traversal_height < 98) {
            if(zombie_ent.substate == 0) {
                zombie_ent.movetype = MOVETYPE_STEP;

                // If short jump up, play short jump / short climb anim
                zombie_ent.play_anim(get_anim_frame_zombie_jump_low, get_anim_length_zombie_jump_low(), ANIM_STOP_TYPE_STOP);
                // zombie_ent.cur_anim_frametime = 0.08;
                anim_time = (zombie_ent.cur_anim_length - 1) * zombie_ent.cur_anim_frametime;
                // zombie_ent.cur_traversal_end_time = time + anim_time - (2 * zombie_ent.cur_anim_frametime);
                zombie_ent.cur_traversal_end_time = 0;
                // Stash anim stop-time in this variable so we can tell when to proceed: (minus three frames)

                zombie_ent.cur_traversal_start_time = time;
                zombie_ent.cur_traversal_end_time = time + 0.3;
                zombie_ent.substate = 1;
            }
            if(zombie_ent.substate == 1) {
                lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
                makevectors([0, sv_navmesh_traversals[traversal_idx].angle, 0]);
                goal_pos = end_pos - '0 0 77' - v_forward * 21;
                zombie_ent.origin = lerpVector(start_pos, goal_pos, lerp_frac);

                if(lerp_frac >= 1) {
                    zombie_ent.substate = 2;
                    // If short jump up, play short climb anim
                    zombie_ent.play_anim(get_anim_frame_zombie_climb_low, get_anim_length_zombie_climb_low(), ANIM_STOP_TYPE_STOP);
                    anim_time = (zombie_ent.cur_anim_length - 1) * zombie_ent.cur_anim_frametime;
                    zombie_ent.cur_traversal_start_time = time;
                    zombie_ent.cur_traversal_end_time = time + anim_time;
                }
            }
            else if(zombie_ent.substate == 2) {
                lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
                start_pos = end_pos - '0 0 77' - v_forward * 21;
                zombie_ent.origin = lerpVector(start_pos, end_pos, lerp_frac);
                if(lerp_frac >= 1.0) {
                    zombie_ent.state = AI_STATE_PATHING;
                    zombie_ent.movetype = MOVETYPE_WALK;
                    // FIXME - Need a better way to revert to walking
                    zombie_ent.play_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
                }
            }
        }
        // Tall ledge
        else {
            if(zombie_ent.substate == 0) {
                zombie_ent.movetype = MOVETYPE_STEP;
                zombie_ent.play_anim(get_anim_frame_zombie_jump, get_anim_length_zombie_jump(), ANIM_STOP_TYPE_STOP);
                // zombie_ent.cur_anim_frametime = 0.08;
                anim_time = (zombie_ent.cur_anim_length - 1) * zombie_ent.cur_anim_frametime;
                zombie_ent.cur_traversal_end_time = time + anim_time - (1 * zombie_ent.cur_anim_frametime);
                // Stash anim stop-time in this variable so we can tell when to proceed: (minus three frames)
                zombie_ent.substate = 1;

                // zombie_ent.cur_anim_get_frame_func = (float(float)) SUB_Null;
                // Figure out how fast to move the zombie
                // float traversal_length = vlen(end_pos - start_pos);
                // zombie_ent.cur_traversal_start_time = time;
                // FIXME - Some traversals will have a different way of getting speed...
            }
            else if(zombie_ent.substate == 1) {
                if(zombie_ent.cur_traversal_end_time <= time) {
                    // Zombie jumping should be real fast, 
                    traversal_time = 0.2; // seconds
                    // TODO - Should we determine how fast the zombie moves based on traversal distance? 
                    // TODO   Otherwise zombie will always jump up in 0.5 seconds regardless of ledge height
                    zombie_ent.cur_traversal_start_time = time;
                    zombie_ent.cur_traversal_end_time = time + traversal_time;
                    zombie_ent.substate = 2;
                }
            }
            else if(zombie_ent.substate == 2) {
                lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
                makevectors([0, sv_navmesh_traversals[traversal_idx].angle, 0]);
                goal_pos = end_pos - '0 0 98' - v_forward * 28;
                zombie_ent.origin = lerpVector(start_pos, goal_pos, lerp_frac);


                if(lerp_frac >= 1) {
                    zombie_ent.substate = 3;
                    zombie_ent.play_anim(get_anim_frame_zombie_climb, get_anim_length_zombie_climb(), ANIM_STOP_TYPE_STOP);
                    anim_time = (zombie_ent.cur_anim_length - 1) * zombie_ent.cur_anim_frametime;
                    zombie_ent.cur_traversal_start_time = time;
                    zombie_ent.cur_traversal_end_time = time + anim_time;
                }
            }
            else if(zombie_ent.substate == 3) {
                lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
                start_pos = end_pos - '0 0 98' - v_forward * 28;
                zombie_ent.origin = lerpVector(start_pos, end_pos, lerp_frac);
                if(lerp_frac >= 1.0) {
                    zombie_ent.state = AI_STATE_PATHING;
                    zombie_ent.movetype = MOVETYPE_WALK;
                    // FIXME - Need a better way to revert to walking
                    zombie_ent.play_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
                }
            }
        }


        // FIXME - I need better alignment tools...


        return;
    }



    // // Starting traversal
    // if(zombie_ent.substate == 0) {
    //     zombie_ent.velocity = '0 0 0';
    //     // zombie_ent.cur_anim_get_frame_func = (float(float)) SUB_Null;
    //     // Start zombie animation:
    //     // zombie_ent.play_anim(get_anim_frame_zombie_window_hop, get_anim_length_zombie_window_hop(), ANIM_STOP_TYPE_STOP);
    //     // zombie_ent.play_anim(get_anim_frame_zombie_jump_climb, get_anim_length_zombie_jump_climb(), ANIM_STOP_TYPE_STOP);
    //     // zombie_ent.cur_anim_get_frame_func = (float(float)) SUB_Null;
    //     // Figure out how fast to move the zombie
    //     float traversal_length = vlen(end_pos - start_pos);
    //     float anim_time = (zombie_ent.cur_anim_length - 1) * zombie_ent.cur_anim_frametime;

    //     zombie_ent.cur_traversal_start_time = time;
    //     // FIXME - Some traversals will have a different way of getting speed...
    //     zombie_ent.cur_traversal_end_time = time + anim_time;
    //     zombie_ent.substate = 1;
    //     zombie_ent.movetype = MOVETYPE_STEP;
    //     zombie_ent.angles.y = sv_navmesh_traversals[traversal_idx].angle;
    // }
    // // Moving zombie across traversal
    // if(zombie_ent.substate == 1) {
    //     float lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);

    //     if(lerp_frac > 1.0) {
    //         zombie_ent.state = AI_STATE_PATHING;
    //         zombie_ent.movetype = MOVETYPE_WALK;

    //         // TODO - How to tell zombie to play walk anim again?
    //         // FIXME - This ain't right
    //         zombie_ent.play_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
    //     }

    //     // If the traversal uses the midpoint, lerp across midpoint
    //     if(sv_navmesh_traversals[zombie_ent.cur_traversal_idx].use_midpoint) {
    //         print("Current lerpfrac: ", ftos(lerp_frac), "\n");
    //         midpoint_pos = sv_navmesh_get_traversal_midpoint_pos(traversal_idx);
    //         // Lerp from start to midpoint
    //         if(lerp_frac < 0.5) {
    //             zombie_ent.origin = lerpVector(start_pos, midpoint_pos, lerp_frac * 2.0);
    //         }
    //         // Lerp from midpoint to end
    //         else {
    //             zombie_ent.origin = lerpVector(midpoint_pos, end_pos, (lerp_frac - 0.5) * 2.0);
    //         }
    //     }
    //     // Otherwise, lerp from start to end
    //     else {
    //         zombie_ent.origin = lerpVector(start_pos, end_pos, lerp_frac);
    //     }



    //     // TODO - Moving 
    //     // vector start_pos = sv_navmesh_traversals[traversal_idx].start_pos;
    //     // vector end_pos = sv_navmesh_get_traversal_end_pos(traversal_idx);
    // }
}





// Called once per ent.think invocation
void zombie_think_callback() {
    AI_Zombie zombie_ent = (AI_Zombie) self;

    if(zombie_ent.state == AI_STATE_PATHING) {
        // "::classname" denotes the global ".string classname" field.
        entity player_ent = find( world, classname, "player"); 
        if(player_ent != world) {
            zombie_ent.path_target = player_ent;
            zombie_ent.enemy = player_ent;
        }

        if(get_zombie_walk_is_footstep(zombie_ent.frame)) {
            if(random() < 0.5) {
                sound(self, 5, "sounds/zombie/s0.wav", 1, ATTN_NORM);
            }
            else {
                sound(self, 5, "sounds/zombie/s1.wav", 1, ATTN_NORM);
            }
        }
        // Ideal animation velocity:
        float dist_per_frame = get_zombie_walk_dist_for_frame(zombie_ent.frame);
        float speed = dist_per_frame / zombie_ent.cur_anim_frametime;
        zombie_ent.do_walk_to_goal(speed);
    }
    else if(zombie_ent.state == AI_STATE_TRAVERSING) {
        zombie_traversal_logic();
        // TODO - Need to figure out how to dispatch different traversals...



        // TODO - If we're traversing, then we should have stashed

        // res->point_path_traversals[this.pathfind_cur_point_idx]
    }

};

















void(vector org) AI_Zombie::init = {
    setmodel(this, "models/ai/zfull.mdl");
    // ---------------------------------
    // Usual zombie setup stuff
    // ---------------------------------
    this.solid = SOLID_CORPSE;
#ifdef PC
	this.dimension_solid = HITBOX_DIM_ZOMBIES;
#endif // PC

    // this.movetype = MOVETYPE_STEP;
    this.movetype = MOVETYPE_WALK;
    setsize (this, '-8 -8 -32', '8 8 30');
    this.origin = org;
    setorigin(this, this.origin);
    this.classname = "ai_zombie";
    this.gravity = 1.0;
    this.takedamage = DAMAGE_YES;
    this.flags = this.flags | FL_PARTIALGROUND | FL_MONSTER;
    this.health = 999999;
    // SetUpHitBoxes(self);
    // ---------------------------------
    this.yaw_speed = 20;
    this.cur_anim_frametime = 0.1;
    // ---------------------------------
    // this.think_delta_time = 0.1; // 10x per second
    // this.nextthink = time + this.think_delta_time;
    this.nextthink = time + this.cur_anim_frametime;
    // this.cur_fg_start_time = -1;
}


// void() AI_Zombie::think = {
//     print("we do be thinkin!\n");
//     // TODO - how to call superclass think?
// }




// void () AI_Zombie::traverse = {
//     this.traversal_idx; // Can't use pointers... but can use index!
//     this.traversal_state;
//     this.traversal_substate;

//     // TODO - Check traversal type, check if this class knows how to perform it.

//     float traversal_idx = 0;
//     // TODO - Once we know traversal type, the AI_Zombie class will know which think_callback to use
//     // TODO - Set up a test scene on the map, set up a test traversal, have dummy zombie play the test traversal
    

//     this.traversal_callback = zombie_traversal_hop_barricade_think;
//     void (entity ent) zombie_hop_barricade_traveral_think = {
//         AI_Zombie zombie_ent = (AI_Zombie) ent;
//         // TODO - need to initialize traversal state and traversal substate
//         // Initialize state
//         if(ent.traversal_state < 0) {
//             ent.traversal_state = 0;
//             ent.traversal_substate = 0;
//         }
        
//         // State 0 -- Start hopping, start playing anim, lerp towards
//         // TODO - How to adjust animation speed scale?
//         // TODO - How best to control animation from here?
//         if(ent.traversal_state == 0) {
//             // TODO - Somehow start playing animation?

//         }
//         // ...
//         // On final state, clear traversal
//         else {
//             ent.traversal_state = -1;
//             // TODO - Revert to zombie original behavior, fg_walk?
//             zombie_ent.fg_walk();
//         }
//     };


//     // TODO - Implement think logic for hop barricade traversal
//     // Each traversal has a different think function implementation...
//     // When I call zombie.traverse(), I need some way of telling the zombie which barricade to traverse
//     // Maybe traverse has a traversal_idx as its argument?
//     // zombie_ent.traverse(traversal_idx);
    
//     // That tells the zombie to perform this traversal
//     // And the traversal think function will be stored in the struct



// #define MYFUNC(DUMMY, FN, I) int FN(void) { return I; } 
// #define GENFUNCS(...)                                          \
// P99_FOR(, P99_NARG(__VA_ARGS__), P00_IGN, MYFUNC, __VA_ARGS__) \
// int (*function_table)(void)[] = { __VA_ARGS__ }

// GENFUNCS(toto, hui, gogo);


void() test_frame_callback = {
    // print("Frame Callback: ", self.classname, "\n");
    AI_Zombie ent = self;
    print("Frame Callback. Frame: ", ftos(ent.frame), " anim frame_idx: ", ftos(ent.cur_anim_frame_idx), "\n");
}

void() test_new_ent = {
	makevectors(self.v_angle);
	AI_Zombie zombie = spawn(AI_Zombie);
	zombie.init(self.origin + v_forward * 100);
    // TODO - If riser, Immediately set frmae to below ground frame
    zombie.frame = get_anim_frame_zombie_rise(0);
    zombie.play_anim(get_anim_frame_zombie_rise, get_anim_length_zombie_rise(), ANIM_STOP_TYPE_NEXT_ANIM);
    zombie.queue_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);

    zombie.think_callback = zombie_think_callback;
    zombie.state = AI_STATE_PATHING;
    // zombie.play_anim(get_anim_frame_zombie_rise, get_anim_length_zombie_rise(), ANIM_STOP_TYPE_LOOP);



    // if(random() < 0.33) {
    //     zombie.queue_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
    // }
    // else if(random() < 0.5) {
    //     zombie.queue_anim(get_anim_frame_zombie_walk2, get_anim_length_zombie_walk2(), ANIM_STOP_TYPE_LOOP);
    // }
    // else {
    //     zombie.queue_anim(get_anim_frame_zombie_walk3, get_anim_length_zombie_walk3(), ANIM_STOP_TYPE_LOOP);
    // }
    // if(random() < 0.2) {
    //     zombie.queue_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
    // }
    // else if(random() < 0.25) {
    //     zombie.queue_anim(get_anim_frame_zombie_walk2, get_anim_length_zombie_walk2(), ANIM_STOP_TYPE_LOOP);
    // }
    // else if(random() < 0.33) {
    //     zombie.queue_anim(get_anim_frame_zombie_walk3, get_anim_length_zombie_walk3(), ANIM_STOP_TYPE_LOOP);
    // }
    // else if(random() < 0.5) {
    //     zombie.queue_anim(get_anim_frame_zombie_jog1, get_anim_length_zombie_jog1(), ANIM_STOP_TYPE_LOOP);
    // }
    // else {
    //     zombie.queue_anim(get_anim_frame_zombie_run1, get_anim_length_zombie_run1(), ANIM_STOP_TYPE_LOOP);
    // }


    // zombie.play_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_NEXT_ANIM);
    // zombie.queue_anim(get_anim_frame_zombie_rise, get_anim_length_zombie_rise(), ANIM_STOP_TYPE_LOOP);


    // TODO - Set frametime to something random?
    // zombie.cur_anim_frametime = 0.1;
    // zombie.next_anim_frametime = 0.05 + 0.1 * random();
    // zombie.next_anim_frametime = 0.2;
    // zombie.next_anim_frametime = 0.1;

};



// ========================================================================================================
// class Chase_AI : entity {
//     float interval;

//     // ------------------------------------------
//     // Animation Control fields
//     // ------------------------------------------
//     float cur_anim_cur_frame; // Current frame index
//     float cur_anim_end_frame; // Goal frame index
//     float cur_anim_frame_lerp; // float 0->1 indicating current lerp progress between frames

//     float cur_anim; // Some identifier for which type of animation to play
//     float cur_anim_end_type; // Pause? Stop? float

//     float counter;
//     // ------------------------------------------


//     nonvirtual void(vector org) init = {
//         setmodel(this, "models/ai/zfull.mdl");

//         // ---------------------------------
//         // Usual zombie setup stuff
//         // ---------------------------------
//         this.solid = SOLID_SLIDEBOX;
//         this.movetype = MOVETYPE_STEP;
//         setsize (this, '-8 -8 -32', '8 8 30');
//         this.origin = org;
//         setorigin(this, this.origin);
//         this.classname = "ai_zombie";
//         this.takedamage = DAMAGE_YES;
//         this.flags = this.flags | FL_PARTIALGROUND | FL_MONSTER;
//         this.health = 999999;
//         // SetUpHitBoxes(self);
//         // ---------------------------------
//         this.cur_anim_end_frame = 227; // Zombie last frame
//         this.nextthink = time + this.interval;
//         this.counter = 0;
//     };


//     virtual void() think = {
//         print("test: ");
//         print(ftos(time));
//         print(", ");
//         print(ftos(this.counter));
//         print("\n");
//         this.counter += 1;

//         if(this.counter > 10) {
//             this.frame = (this.frame + 20) % 227;
//             this.counter = 0;
//         }
//         this.nextthink = time + this.interval;
//     };


//     // Example functions for classes
//     nonvirtual void(entity e) set_enemy = {
//         this.enemy = e;

//     };

//     void() foo = {
//         this.nextthink = time + this.interval;
//     };


//     void(float x) test = {
//         print(ftos(x[0]));
//         print(ftos(x[1]));
//         print(ftos(x[2]));
//         print("\n");
//     };


// };










// // foo myfoo = spawn(foo, message:"Hello World", interval:5);
// //         myfoo.setEnemy(self);
// //     };


// class Zombie : Chase_AI {

// };

// class Crawler : Chase_AI {
    
// };

// class Dog : Chase_AI {
    
// };

// void() test_new_ent = {
// 	makevectors(self.v_angle);
// 	Chase_AI zombie = spawn(Chase_AI, message:"thas a zomber", interval:0.1);
// 	zombie.init(self.origin + v_forward * 100);


//     float x[3];
//     x[0] = 1;
//     // print(ftos(x[0]));
//     // print(ftos(x[1]));
//     // print(ftos(x[2]));
//     // print("\n");
//     float x[] = {
//         0, 2, 3, 5, 10, 20,
//     };
//     zombie.test(x);
// }




// framegroup1 = {
//     'start_frame': 0,
//     'end_frame': 10,
//     'duration': 10.0; // seconds
//     'start_callback': void(){},  // Called at the first frame of the range
//     'frame_callback': void(){},  // Called at every frame of the range (after start / finish callbacks)
//     'finish_callback': void(){}, // Called at the last frame of the range
// }



// void() th_die_dispatcher = {
//     if(random() < 0.33) { 
//         framegroup1();
//     }
//     else if(random() < 0.5) {
//         framegroup2();
//     }
//     else {
//         framegroup3();
//     }
// };


// framegroup_registry = {
//     'th_die': th_die_dispatcher,
//     'th_walk': ,
//     'th_run': ,
//     'th_attack': ,
//     'th_idle': ,
//     'th_chase_monkey': SUB_Null,
// }


// framegroup_registry = {
//     'th_die': {framegroup1, framegroup1, framegroup1, framegroup1, framegroup1, SUB_Null, SUB_Null, SUB_Null},
//     'th_walk': ,
//     'th_run': ,
//     'th_attack': ,
//     'th_idle': ,
//     'th_chase_monkey': SUB_Null,
// }



// typedef {

// }

// struct_t



// // For traversal
// traversal_registry = {
//     'traversal_hop_fence': SUB_Null,
//     'traversal_drop_down_ledge': ,
//     'traversal_jump_up_ledge': ,
//     'traversal_...': ,
//     'traversal_...': ,
// }









// void(float start_frame, float end_frame, float cur_frame) frame_callback = {
//     if(cur_frame == end_frame) {
//         // do something else
//     }
// }


// //-----------------------------------------------------------------
// var struct powerup_struct
// {
// 	float 	id;
// 	float 	occupied;
// 	float	flash_screen;
// 	string	model_path;
// 	string 	voiceover_path;
// 	void()	function;
// 	float() requirement_function;
// } powerup_array[MAX_POWERUPS] = {};

// float 	powerup_count;
// float	powerup_index;

// .float 	zombie_drop_id;

// //
// // PU_AddToStruct(id, model_path, voiceover_path)
// // Adds the Power-Up and info to the powerup struct
// //
// void(float id, float flash_screen, string model_path, string voiceover_path, void() function, float() requirement_function) 
// PU_AddToStruct =
// {
// 	if (id > MAX_POWERUPS - 1)
// 		return;

// 	// Precache Model and VO
// 	precache_model(model_path);
// 	precache_sound(voiceover_path);

// 	// Populate the Struct at Index
// 	powerup_array[powerup_count].id = id;
// 	powerup_array[powerup_count].occupied = true;
// 	powerup_array[powerup_count].flash_screen = flash_screen;
// 	powerup_array[powerup_count].model_path = model_path;
// 	powerup_array[powerup_count].voiceover_path = voiceover_path;
// 	powerup_array[powerup_count].function = function;
// 	powerup_array[powerup_count].requirement_function = requirement_function;

// 	// Increment Index
// 	powerup_count++;
// };




// PU_AddToStruct(PU_NUKE, 		true,	"models/pu/nuke!.mdl",		"sounds/pu/nuke.wav",			PU_Nuke,			PU_NullRequirement		);
// PU_AddToStruct(PU_INSTAKILL, 	false,	"models/pu/instakill!.mdl",	"sounds/pu/insta_kill.wav", 	PU_InstaKill,	PU_NullRequirement		);
// PU_AddToStruct(PU_DOUBLEPTS, 	false,	"models/pu/x2!.mdl",		"sounds/pu/double_points.wav",	PU_DoublePoints,	PU_NullRequirement		);
// PU_AddToStruct(PU_CARPENTER,	false,	"models/pu/carpenter!.mdl",	"sounds/pu/carpenter.wav",		PU_Carpenter,	PU_CarpenterRequirement	);
// PU_AddToStruct(PU_MAXAMMO,		false,	"models/pu/maxammo!.mdl",	"sounds/pu/maxammo.wav", 		PU_MaxAmmo,		PU_NullRequirement		);