enum anim_stop_type : float {
    ANIM_STOP_TYPE_STOP, // Animation stops and freezes at final frame.
    ANIM_STOP_TYPE_LOOP, // Animation starts again from the first frame.
    ANIM_STOP_TYPE_NEXT_ANIM, // Another animation is played when this one finishes.
};



float zombie_anim_idle_modelindex;
float zombie_anim_rise_modelindex;
float zombie_anim_walk1_modelindex;
float zombie_anim_walk2_modelindex;
float zombie_anim_walk3_modelindex;
float zombie_anim_jog1_modelindex;
float zombie_anim_run1_modelindex;
float zombie_anim_climbledge_modelindex;


#define AI_STATE_PATHING 0
#define AI_STATE_TRAVERSING 1


enum IQM_EVENT:float {
    IQM_EVENT_SOUND = 1,
    IQM_EVENT_MOVE_SPEED = 2,
    IQM_EVENT_ZOMBIE_FOOTSTEP = 3,
};



#define ZOMBIE_LIMB_STATE_HEAD	1
#define ZOMBIE_LIMB_STATE_ARM_L	2
#define ZOMBIE_LIMB_STATE_ARM_R	4
#define ZOMBIE_LIMB_STATE_LEG_L	8
#define ZOMBIE_LIMB_STATE_LEG_R	16


void() play_zombie_footstep {
    if(random() < 0.5) {
        sound(self, 5, "sounds/zombie/s0.wav", 1, ATTN_NORM);
    }
    else {
        sound(self, 5, "sounds/zombie/s1.wav", 1, ATTN_NORM);
    }
}




// AI_Chase entity defines a generic entity type that knows how to navigate 
// the map using the map's navmesh
// AI_Chase entities are designed to use Skeletal IQM models
class AI_Chase : entity {
    // -----------------------------
    // AI state vars
    // -----------------------------
    entity path_target; // If specified, path towards entity
    entity enemy;
    vector path_pos; // Otherwise, path towards location specified
    float state;
    float substate;
    // -----------------------------

    // -----------------------------
    // Traversal state vars
    // -----------------------------
    float cur_traversal_idx;
    float cur_traversal_end_time;
    float cur_traversal_start_time;

    // Think callback executed every logic tick, independent of current animation
    virtual void() think_callback = SUB_Null;
    // // We also have a frame callback that's called each time a new animation frame is reached
    // virtual void() frame_callback = SUB_Null;

    float think_delta_time; // Time (in seconds) between entity's ".think()" invocations
    // ------------------------------
    // Animation variables
    // ------------------------------
    // --- Current animation vars ---
    float cur_anim_model_idx;
    float cur_anim_framegroup;
    float cur_anim_start_time; // Time at which the animation was started
    float cur_anim_last_time; // Time into the animation at which the last `think` was invoked
    float cur_anim_playback_speed; // 1.0 = Normal speed, 2.0 = Twice as fast, 0.5 = Half-speed, etc.
    // float cur_anim_move_dist;
    // Cached derived vars:
    float cur_anim_duration; // Length (in seconds) of current animation at 1.0 playback speed

    // --- Next / Queued animation vars ---
    float next_anim_model_idx;
    float next_anim_framegroup;
    float next_anim_playback_speed;

    float pathfind_result_idx; // TODO - Need to increment this on instantiation
    float pathfind_cur_point_idx;

    // TODO - Move this to AI_Zombie subclass?
    float limbs_state;


    // ------------------------------------------------------------------------
    // Animation movement integration fields / code
    // ------------------------------------------------------------------------
    float cur_anim_move_dist; // Accumulates `dist` for all events overlapping region
    float cur_anim_move_region_start_time; // Start time of search region
    float cur_anim_move_region_end_time; // End time of search region
    float cur_anim_move_last_event_dist; // `dist` value for the last event processed
    float cur_anim_move_last_event_start; // Event start time for the last event processed


    // Returns the fraction of an event that overlaps with the saerch region 
    // The search region is defined over: [this.cur_anim_move_region_start_time, this.cur_anim_move_region_end_time]
    virtual float(float event_start_time, float event_end_time) anim_move_get_event_intersection;

    // Callback for built-in `processmodelevents` to integrate all animation movement between two timestamps
    virtual void(float event_timestamp, int event_code, string event_data) anim_move_accumulate_iqm_event_movement;
    virtual float() calc_anim_movement_speed;
    // ------------------------------------------------------------------------

    virtual void (float move_speed) do_walk_to_goal;
    virtual float(entity to, float sendflags) send_entity_func;
    
    // Constructor. Called when calling `spawn(AI_Chase);`
    virtual void() AI_Chase;

    // void() take_damage = {
    //     // TODO - Update limb states, mark as needing networking
    // }

    virtual void(float timestamp, int event_code, string event_data) handle_iqm_event;

    // Stop what you're doing and play this animation immediately.
    virtual void(float anim_model_idx, float anim_framegroup) play_anim;

    // Queue up another animation to play when the current one finishes
    virtual void(float anim_model_idx, float anim_framegroup) queue_anim;

    // The "logic tick" of the entity.
    virtual void() think;


    // virtual void () fg_die = {};
    // virtual void () fg_walk = {};
    // virtual void () fg_attack = {};
    // virtual void () fg_idle = {};
    // virtual void (float dist) do_walk_to_goal;
};






void zombie_traversal_logic() {
    // AI_Zombie zombie_ent = (AI_Zombie) self;
    AI_Chase zombie_ent = (AI_Chase) self;

    float traversal_idx = zombie_ent.cur_traversal_idx;
    vector start_pos = sv_navmesh_traversals[traversal_idx].start_pos;
    vector midpoint_pos;
    vector end_pos = sv_navmesh_get_traversal_end_pos(traversal_idx);


    string traversal_type;
    traversal_type = "ledge";
    // traversal_type = "leap";
    // traversal_type = "jump_gap";
    // traversal_type = "hop_barricade";
    // traversal_type = "hop_fence";
    // traversal_type = "window";
    // traversal_type = "teleport";

    // Jump up logic
    if(traversal_type == "ledge") {
        // Adjust zombie angle to its smallest representation
        zombie_ent.angles.y = ((zombie_ent.angles.y + 180) % 360) - 180;
        // Apply smallest delta angle
        float delta_angle = sv_navmesh_traversals[traversal_idx].angle - zombie_ent.angles.y;
        delta_angle = ((delta_angle + 180) % 360) - 180;
        zombie_ent.angles.y += 0.5 * delta_angle;

        // Jump up traversal consists of the following substates:
        //      0: Start traversal, play jump up anim
        //      1: Wait for jump up anim to complete
        //      2: Move zombie up to ledge
        //      3: Play zombie get up animation
        //
        // Check height of ledge we're climbing:
        float traversal_height = end_pos.z - start_pos.z;
        float traversal_time;
        float lerp_frac;
        float anim_time;
        vector ledge_pos;



        // Fall down
        if(traversal_height < 0 ) {
            if(zombie_ent.substate == 0) {
                zombie_ent.movetype = MOVETYPE_STEP;
                // zombie_ent.play_anim(get_anim_frame_zombie_fall, get_anim_length_zombie_fall(), ANIM_STOP_TYPE_STOP);
                // zombie_ent.queue_anim(get_anim_frame_zombie_fall_loop, get_anim_length_zombie_fall_loop(), ANIM_STOP_TYPE_LOOP);
                traversal_time = min(-traversal_height * (0.35 / 100.0), 2.0);
                zombie_ent.cur_traversal_start_time = time;
                zombie_ent.cur_traversal_end_time = time + traversal_time;
                zombie_ent.substate = 1;
            }
            else if(zombie_ent.substate == 1) {
                lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
                zombie_ent.origin = lerpVector(start_pos, end_pos, lerp_frac * lerp_frac);
                if(lerp_frac >= 1.0) {
                    // zombie_ent.play_anim(get_anim_frame_zombie_land, get_anim_length_zombie_land(), ANIM_STOP_TYPE_NEXT_ANIM);
                    // zombie_ent.cur_anim_frametime = 0.05;
                    // zombie_ent.queue_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
                    zombie_ent.state = AI_STATE_PATHING;
                    zombie_ent.movetype = MOVETYPE_WALK;
                }
            }
        }
        // Short ledge
        // else if(traversal_height < 98) {
        //     makevectors([0, sv_navmesh_traversals[traversal_idx].angle, 0]);
        //     ledge_pos = end_pos - '0 0 72' - v_forward * 21;

        //     if(zombie_ent.substate == 0) {
        //         zombie_ent.movetype = MOVETYPE_STEP;
        //         // If short jump up, play short jump / short climb anim
        //         // zombie_ent.play_anim(get_anim_frame_zombie_jump_low, get_anim_length_zombie_jump_low(), ANIM_STOP_TYPE_STOP);
        //         anim_time = 1;
        //         // anim_time = (zombie_ent.cur_anim_length - 1) * zombie_ent.cur_anim_frametime;
        //         // zombie_ent.cur_traversal_end_time = time + anim_time - (2 * zombie_ent.cur_anim_frametime);
        //         zombie_ent.cur_traversal_end_time = time + anim_time;
        //         // zombie_ent.cur_traversal_end_time = 0;
        //         // Stash anim stop-time in this variable so we can tell when to proceed: (minus three frames)

        //         zombie_ent.cur_traversal_start_time = time;
        //         zombie_ent.cur_traversal_end_time = time + 0.3;
        //         zombie_ent.substate = 1;
        //     }
        //     if(zombie_ent.substate == 1) {
        //         lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
        //         zombie_ent.origin = lerpVector(start_pos, ledge_pos, lerp_frac);

        //         if(lerp_frac >= 1) {
        //             zombie_ent.substate = 2;
        //             // If short jump up, play short climb anim
        //             // zombie_ent.play_anim(get_anim_frame_zombie_climb_low, get_anim_length_zombie_climb_low(), ANIM_STOP_TYPE_STOP);
        //             // anim_time = (zombie_ent.cur_anim_length - 1) * zombie_ent.cur_anim_frametime;
        //             anim_time = 1;
        //             zombie_ent.cur_traversal_start_time = time;
        //             zombie_ent.cur_traversal_end_time = time + anim_time;
        //         }
        //     }
        //     else if(zombie_ent.substate == 2) {
        //         lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
        //         start_pos = end_pos - '0 0 72' - v_forward * 21;
        //         zombie_ent.origin = lerpVector(start_pos, end_pos, lerp_frac);
        //         if(lerp_frac >= 1.0) {
        //             zombie_ent.state = AI_STATE_PATHING;
        //             zombie_ent.movetype = MOVETYPE_WALK;
        //             // FIXME - Need a better way to revert to walking
        //             // zombie_ent.play_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
        //         }
        //     }
        // }
        // Tall ledge
        else {
            makevectors([0, sv_navmesh_traversals[traversal_idx].angle, 0]);
            // ledge_pos = end_pos - '0 0 98' - v_forward * 28;
            ledge_pos = end_pos - '0 0 94' - v_forward * 28;

            if(zombie_ent.substate == 0) {
                zombie_ent.movetype = MOVETYPE_STEP;
                zombie_ent.play_anim(zombie_anim_climbledge_modelindex, 0);
                // Wait until jump animation is near completion to start moving zombie
                zombie_ent.cur_traversal_end_time = time + zombie_ent.cur_anim_duration - 0.3;
                zombie_ent.substate = 1;

                // zombie_ent.cur_anim_get_frame_func = (float(float)) SUB_Null;
                // Figure out how fast to move the zombie
                // float traversal_length = vlen(end_pos - start_pos);
                // zombie_ent.cur_traversal_start_time = time;
            }
            else if(zombie_ent.substate == 1) {
                if(zombie_ent.cur_traversal_end_time <= time) {
                    // Zombie moves from bottom to top of ledge in fixed time:
                    traversal_time = 0.15; // seconds
                    // TODO - Should we determine how fast the zombie moves based on traversal distance? 
                    // TODO   Otherwise zombie will always jump up in 0.5 seconds regardless of ledge height
                    zombie_ent.cur_traversal_start_time = time;
                    zombie_ent.cur_traversal_end_time = time + traversal_time;
                    zombie_ent.substate = 2;
                }
            }
            else if(zombie_ent.substate == 2) {
                // Move zombie up to ledge
                lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
                setorigin(zombie_ent, lerpVector(start_pos, ledge_pos, lerp_frac));

                // Once at ledge, play climb animation:
                if(lerp_frac >= 1) {
                    zombie_ent.substate = 3;
                    zombie_ent.play_anim(zombie_anim_climbledge_modelindex, 1);
                    zombie_ent.cur_traversal_start_time = time;
                    // Wait until animation near completion to advance
                    zombie_ent.cur_traversal_end_time = time + (zombie_ent.cur_anim_duration - 0.2);
                }
            }
            else if(zombie_ent.substate == 3) {
                lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
                setorigin(zombie_ent, lerpVector(ledge_pos, end_pos, lerp_frac));

                if(lerp_frac >= 1.0) {
                    zombie_ent.state = AI_STATE_PATHING;
                    zombie_ent.movetype = MOVETYPE_WALK;
                    // FIXME - Need a better way to revert to walking
                    zombie_ent.play_anim(zombie_anim_walk1_modelindex, 0);
                }
            }
        }
        // Mark to send origin / angles to clients
        zombie_ent.SendFlags |= 1;

        return;
    }
    // TODO - Implement leap
    // else if(traversal_type == "leap") {
    //     midpoint_pos = sv_navmesh_get_traversal_midpoint_pos(traversal_idx);

    //     // Adjust zombie angle to its smallest representation
    //     zombie_ent.angles.y = ((zombie_ent.angles.y + 180) % 360) - 180;
    //     // Apply smallest delta angle
    //     float delta_angle = sv_navmesh_traversals[traversal_idx].angle - zombie_ent.angles.y;
    //     delta_angle = ((delta_angle + 180) % 360) - 180;
    //     zombie_ent.angles.y += 0.5 * delta_angle;        

    //     // Leap traversal consists of the following substates:
    //     //      0: Play leap animation (frames 218-233)
    //     //      1: Wait for frame 233
    //     //      2: Move zombie across arc to end pos, ends at frame 241
    //     //      3: Wait at endpos for frame 247

    //     // TODO - Adjust traversal speed?
    //     // TODO - Break up leap start / leap-mid-air / leap land anims?
    //     // float traversal_length = 

    //     float lerp_frac;

    //     if(zombie_ent.substate == 0) {
    //         zombie_ent.movetype = MOVETYPE_STEP;
    //         // zombie_ent.play_anim(get_anim_frame_zombie_leap_jump, get_anim_length_zombie_leap_jump(), ANIM_STOP_TYPE_STOP);
    //         zombie_ent.substate = 1;
    //         // Advance to next substate (1->2) after 5 frames
    //         zombie_ent.cur_traversal_start_time = time;
    //         zombie_ent.cur_traversal_end_time = time + (5 * zombie_ent.cur_anim_frametime);
    //     }
    //     else if(zombie_ent.substate == 1) {
    //         if(zombie_ent.cur_traversal_end_time <= time) {
    //             zombie_ent.substate = 2;
    //             // Advance to next substate (2->3) after 8 frames
    //             zombie_ent.cur_traversal_start_time = time;
    //             zombie_ent.cur_traversal_end_time = time + (8 * zombie_ent.cur_anim_frametime);
    //         }
    //     }
    //     else if(zombie_ent.substate == 2) {
    //         lerp_frac = (time - zombie_ent.cur_traversal_start_time) / (zombie_ent.cur_traversal_end_time - zombie_ent.cur_traversal_start_time);
    //         zombie_ent.origin = lerp_vector_bezier(start_pos, midpoint_pos, end_pos, lerp_frac);

    //         if(lerp_frac >= 1) {
    //             zombie_ent.substate = 3;
    //             // zombie_ent.play_anim(get_anim_frame_zombie_leap_land, get_anim_length_zombie_leap_land(), ANIM_STOP_TYPE_STOP);
    //             float anim_time = (zombie_ent.cur_anim_length - 1) * zombie_ent.cur_anim_frametime;
    //             // Finish traversal at the end of the land animation
    //             zombie_ent.cur_traversal_start_time = time;
    //             zombie_ent.cur_traversal_end_time = time + anim_time;

    //         }
    //     }
    //     else if(zombie_ent.substate == 3) {
    //         if(zombie_ent.cur_traversal_end_time <= time) {
    //             zombie_ent.state = AI_STATE_PATHING;
    //             zombie_ent.movetype = MOVETYPE_WALK;
    //             // FIXME - Need a better way to revert to walking
    //             // zombie_ent.play_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
    //         }
    //    }
    //     return;
    // }



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












// Returns the fraction of an event that overlaps with the saerch region 
// The search region is defined over: [this.cur_anim_move_region_start_time, this.cur_anim_move_region_end_time]
float(float event_start_time, float event_end_time) AI_Chase::anim_move_get_event_intersection {
    if(event_end_time < this.cur_anim_move_region_start_time) {
        return 0;
    } 
    if(event_start_time > this.cur_anim_move_region_end_time) {
        return 0;
    }
    // At this point we know there's overlap.
    // Compute intersection of search region and event region
    float overlap_start = clamp(this.cur_anim_move_region_start_time, event_start_time, event_end_time);
    float overlap_end = clamp(this.cur_anim_move_region_end_time, event_start_time, event_end_time);
    // Compute interpolation factors at the start and stop of the intersection
    float overlap_start_lerp_frac = (overlap_start - event_start_time) / (event_end_time - event_start_time);
    float overlap_end_lerp_frac = (overlap_end - event_start_time) / (event_end_time - event_start_time);
    float overlap = overlap_end_lerp_frac - overlap_start_lerp_frac;
    return overlap;
};

// Callback for built-in `processmodelevents` to integrate all animation movement between two timestamps
void(float event_timestamp, int event_code, string event_data) AI_Chase::anim_move_accumulate_iqm_event_movement {
    if(event_code == IQM_EVENT_MOVE_SPEED) {
        float event_dist = stof(event_data);
        float anim_looped = true; // FIXME - Assumes all anims are looped. Is there any way to tell whether an animation is looped?

        float last_event_start_time = this.cur_anim_move_last_event_start;
        float last_event_end_time = event_timestamp;

        // On the first iteration, last_event_timestamp is -1
        // No edge cases here!
        while(true) {
            // If `last_event` falls completely after search region, stop
            if(last_event_start_time > this.cur_anim_move_region_end_time) {
                break;
            }
            this.cur_anim_move_dist += this.cur_anim_move_last_event_dist * anim_move_get_event_intersection(last_event_start_time, last_event_end_time);
            // If the animation isn't looped, only consider the first iteration
            if(anim_looped == false) {
                break;
            }
            last_event_start_time += this.cur_anim_duration;
            last_event_end_time += this.cur_anim_duration;
        }

        // Store current event as last event
        this.cur_anim_move_last_event_dist = event_dist;
        this.cur_anim_move_last_event_start = event_timestamp;
    }
};

float() AI_Chase::calc_anim_movement_speed {
    float walk_dist = 0;
    // Given current animation state, read through the IQM events to determine exactly how much to move at this logic tick
    // float prev_time = time - ent.think_delta_time;


    // float anim_last_frametime = this.cur_anim_last_time % this.cur_anim_duration;
    // float anim_cur_frametime = ((time - this.cur_anim_start_time) * this.cur_anim_playback_speed) % this.cur_anim_duration;
    float anim_last_frametime = this.cur_anim_last_time;
    float anim_cur_frametime = ((time - this.cur_anim_start_time) * this.cur_anim_playback_speed);


    // print("Current anim frametimes: ", ftos(anim_last_frametime), " -> ", ftos(anim_cur_frametime), "\n");

    this.cur_anim_move_dist = 0;
    this.cur_anim_move_last_event_dist = 0;
    this.cur_anim_move_last_event_start = -1;
    // We know anim_last_frametime < anim_cur_frametime
    // Wrap anim_last_frametime so it falls within [0, anim_duration]
    // Then make anim_cur_frametime relative to that (not wrapped)
    this.cur_anim_move_region_end_time = anim_cur_frametime - anim_last_frametime; // First set it to delta
    this.cur_anim_move_region_start_time = anim_last_frametime % this.cur_anim_duration; // Wrap `last_frametime`
    this.cur_anim_move_region_end_time += this.cur_anim_move_region_start_time; // Add `start_time` back in to get region end relative to region start

    // Search through the entire animation:
    float region_start = 0;
    float region_end = this.cur_anim_duration + 1;
    // print("Accumulating moves over: (", ftos(region_start), ",", ftos(region_end), "), Search range: (", ftos(this.cur_anim_move_region_start_time));
    // print(",", ftos(this.cur_anim_move_region_end_time),").\n");
    processmodelevents(this.cur_anim_model_idx, this.cur_anim_framegroup, region_start, region_end, this.anim_move_accumulate_iqm_event_movement);
    // Call one more time so the final event has a chance to be deposited
    this.anim_move_accumulate_iqm_event_movement(this.cur_anim_duration, IQM_EVENT_MOVE_SPEED, "0");
    // print("\tFinal Result: ",ftos(this.cur_anim_move_dist),"\n");
    walk_dist = this.cur_anim_move_dist;


    // OKAY - We now have exactly how much the zombie should have moved between the last two logic ticks...
    // To get speed, we simply divide by think_delta_time, no?
    float movement_speed = walk_dist / this.think_delta_time;
    return movement_speed;
};
// ------------------------------------------------------------------------




void (float move_speed) AI_Chase::do_walk_to_goal {
    if(move_speed == 0) {
        return;
    }
    // move_speed=0;

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
            print("Distance from target: ", ftos(vlen_xy(this.origin - goal_pos)), ", Cur point: ", ftos(this.pathfind_cur_point_idx), "\n");
            print("Current traversal: ", ftos(res->point_path_traversals[this.pathfind_cur_point_idx]),"\n");
            // If this point path is a traversal, teleport to traversal end spot

            if(res->point_path_traversals[this.pathfind_cur_point_idx] != -1) {
                this.state = AI_STATE_TRAVERSING;
                this.substate = 0;
                this.cur_traversal_idx = res->point_path_traversals[this.pathfind_cur_point_idx];
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

    // ChangeYaw();
    // Apply smallest delta angle
    float delta_angle = this.ideal_yaw - this.angles.y;
    delta_angle = ((delta_angle + 180) % 360) - 180;
    this.angles.y += 0.3 * delta_angle;

    vector new_velocity;
    // float walk_dist = move_speed * this.think_delta_time; 
    // float dist_to_goal = vlen(goal_pos - this.origin);
    // if(walk_dist > dist_to_goal) {
    //     // TODO - If zombie vel is high enough, and think is too infrequent, we 
    //     // TODO   can overshoot. If this condition is true, we will have hit
    //     // TODO   the goal position.
    //     // TOOD - Mark that the zombie _should_ have gotten to its goal by the next think invocation
    //     // Force the zombie to be relocated to the position?
    //     move_speed = dist_to_goal / this.think_delta_time;
    // }
    new_velocity = normalize(goal_pos - this.origin) * move_speed;
    new_velocity_z = this.velocity_z;
    this.velocity = new_velocity;
    this.SendFlags |= 1;
};


float(entity to, float sendflags) AI_Chase::send_entity_func {
    WriteByte(MSG_ENTITY, ENT_TYPE_ZOMBIE);
    // Write bytflags indicating payload contents
    WriteByte(MSG_ENTITY, sendflags);
    // Send ent location (Required by CSQC)
    if(sendflags & 1) {
        WriteCoord( MSG_ENTITY, self.origin_x);
        WriteCoord( MSG_ENTITY, self.origin_y);
        WriteCoord( MSG_ENTITY, self.origin_z);
        WriteCoord( MSG_ENTITY, self.angles_x);
        WriteCoord( MSG_ENTITY, self.angles_y);
        WriteCoord( MSG_ENTITY, self.angles_z);
        WriteShort( MSG_ENTITY, self.velocity_x);
        WriteShort( MSG_ENTITY, self.velocity_y);
        WriteShort( MSG_ENTITY, self.velocity_z);
        WriteFloat( MSG_ENTITY, self.flags); // Flags, important for physics
    }
    // Send animation state variables
    if(sendflags & 2) {
        WriteByte( MSG_ENTITY, self.cur_anim_model_idx);
        WriteByte( MSG_ENTITY, self.cur_anim_framegroup);
        WriteFloat( MSG_ENTITY, self.cur_anim_start_time);
        WriteFloat( MSG_ENTITY, self.cur_anim_playback_speed);
    }
    // Send skin number
    if(sendflags & 4) {
        WriteByte( MSG_ENTITY, self.skin);
    }
    // Send limb state
    if(sendflags & 8) {
        WriteByte( MSG_ENTITY, self.limbs_state);
    }
    // Send skeleton index
    if(sendflags & 64) {
        WriteByte( MSG_ENTITY, self.skeletonindex);
        // print("SSQC skeleton index: ", ftos(self.skeletonindex), "\n");
    }
    // Send model index
    if(sendflags & 128) {
        WriteByte( MSG_ENTITY, self.modelindex);
    }
    // TODO - Send limb state / texture info
    return TRUE;
};



// Constructor. Called when calling `spawn(AI_Chase);`
void() AI_Chase::AI_Chase {
    this.path_target = world;
    // this.path_pos = world.origin;
    this.cur_anim_model_idx = -1;
    this.next_anim_model_idx = -1;
    this.think_delta_time = 0.1; // Call `this.think();` 10x per second

    // TODO - Set model? Create skeleton?
    // Should this be done in constructor?
    this.SendEntity = this.send_entity_func;
    this.cur_anim_playback_speed = 1;
};

// void() take_damage = {
//     // TODO - Update limb states, mark as needing networking
// }

void(float timestamp, int event_code, string event_data) AI_Chase::handle_iqm_event {
    switch(event_code) {
        // case IQM_EVENT_MOVE_SPEED: // FRAME MOVEMENT DIST
        //     this.cur_anim_move_dist += stof(event_data);
        //     print("Handling event! move dist: ", ftos(this.cur_anim_move_dist), "\n");
        //     break;
        case IQM_EVENT_ZOMBIE_FOOTSTEP:
            play_zombie_footstep(); // TODO - Should this be done via reference to sound file?
            break;
        default:
            break;
    }
};

// Stop what you're doing and play this animation immediately.
void(float anim_model_idx, float anim_framegroup) AI_Chase::play_anim {
    this.cur_anim_model_idx = anim_model_idx;
    this.cur_anim_framegroup = anim_framegroup;
    this.cur_anim_start_time = time;
    this.cur_anim_last_time = 0;
    this.cur_anim_playback_speed = 1; // Reset value
    this.cur_anim_duration = frameduration(this.cur_anim_model_idx, this.cur_anim_framegroup);
    // Indicate that we need to broadcast the current anim frame info:
    self.SendFlags |= 2; // Indicate that we should update client-side animations
};

// Queue up another animation to play when the current one finishes
void(float anim_model_idx, float anim_framegroup) AI_Chase::queue_anim {
    this.next_anim_model_idx = anim_model_idx;
    this.next_anim_framegroup = anim_framegroup;
    this.next_anim_playback_speed = 1.0;
};


// The "logic tick" of the entity.
void() AI_Chase::think {
    if(this.cur_anim_model_idx >= 0) {
        // print("Think!, ", ftos(cur_anim_time));
        float cur_anim_time = (time - this.cur_anim_start_time) * this.cur_anim_playback_speed;
        // Update entity skeleton to have the latest pose
        skelblend_t skel_blend_data;
        skel_blend_data.firstbone = -1;
        skel_blend_data.lastbone = -1;
        skel_blend_data.scale[0] = 1;
        skel_blend_data.sourcemodelindex = this.cur_anim_model_idx;
        skel_blend_data.animation[0] = this.cur_anim_framegroup;
        skel_blend_data.animationtime[0] = cur_anim_time;
        skel_build_ptr(this.skeletonindex, 1, &skel_blend_data, sizeof(skel_blend_data));

        // Process all animation frame events that elapsed since the last `think` function was called
        float events_start_time = this.cur_anim_last_time % this.cur_anim_duration;
        float events_end_time = cur_anim_time % this.cur_anim_duration;


        // If the animation was looped, and start time is near the anim end, while end time is near the anim start
        // Run the events elapsed at the end of the anim and start of the anim thus far
        if(events_end_time < events_start_time) {
            // Process elapsed events at the end of the animation
            float segment_start = events_start_time;
            float segment_end = this.cur_anim_duration;
            processmodelevents(this.cur_anim_model_idx, this.cur_anim_framegroup, segment_start, segment_end, this.handle_iqm_event);
            // Process elapsed events at the start of the animation
            segment_start = 0;
            segment_end = events_end_time;
            processmodelevents(this.cur_anim_model_idx, this.cur_anim_framegroup, segment_start, segment_end, this.handle_iqm_event);
        } 
        // Otherwise just process the elapsed events
        else {
            processmodelevents(this.cur_anim_model_idx, this.cur_anim_framegroup, events_start_time, events_end_time, this.handle_iqm_event);
        }

        // If we have a queued animation, check if this animation is over (or is very close to being over)
        if(this.next_anim_model_idx >= 0 && (cur_anim_time + this.think_delta_time * this.cur_anim_playback_speed) >= this.cur_anim_duration) {
            this.play_anim( this.next_anim_model_idx, this.next_anim_framegroup);
            this.cur_anim_playback_speed = this.next_anim_playback_speed;
            this.SendFlags |= 2; // Indicate that we should update client-side animations
            // Reset queued anim fields
            this.next_anim_playback_speed = 1.0;
            this.next_anim_model_idx = -1;
            this.next_anim_framegroup = 0;
        }
    }

    this.nextthink = time + this.think_delta_time;
    this.think_callback();


    if(this.cur_anim_model_idx >= 0) {
        // Recalculate cur_anim_time, in case another animation was triggered
        this.cur_anim_last_time = (time - this.cur_anim_start_time) * this.cur_anim_playback_speed;
    }
};






// class AI_Zombie : AI_Chase {
//     entity enemy; // If near, attack

//     // Constructor. Called when calling `spawn(AI_Zombie);`
//     // virtual void() AI_Zombie = {};
//     // This should be called explicitly:
//     virtual void(vector org) init;

//     // virtual void () fg_die;
//     // virtual void () fg_walk;
//     // virtual void () fg_attack;
//     // virtual void () fg_idle;

//     // static void () setup_frames = {
//     //     // this.zombie_idle_frames = {1,2,3,4,5,6,7,8,9,10,11,12,13};
//     //     // this.cur_frames = zombie_idle_frames;
//     //     // FIXME - I can't figure out a way to assign an array...
//     //     // Even if I convert an animation to a struct, I can't do arbitrary-length arrays...
//     //     // I also can't fill them in in this convenient syntax... it's ridiculous.
//     // };
// };

// AI_Zombie.zombie_idle_frames = {1,2,3,4,5,6,7,8,9,10,11,12,13};




void zombie_think_callback() {
    AI_Chase zombie = (AI_Chase) self;

    if(zombie.state == AI_STATE_PATHING) {
        // "::classname" denotes the global ".string classname" field.
        entity player_ent = find( world, classname, "player"); 
        if(player_ent != world) {
            zombie.path_target = player_ent;
            zombie.enemy = player_ent;
        }

        // TEMP FIXME:
        // zombie.limbs_state = 0;
        // if(random() < 0.9) zombie.limbs_state |= ZOMBIE_LIMB_STATE_HEAD;
        // if(random() < 0.9) zombie.limbs_state |= ZOMBIE_LIMB_STATE_ARM_L;
        // if(random() < 0.9) zombie.limbs_state |= ZOMBIE_LIMB_STATE_ARM_R;
        // if(random() < 0.9) zombie.limbs_state |= ZOMBIE_LIMB_STATE_LEG_L;
        // if(random() < 0.9) zombie.limbs_state |= ZOMBIE_LIMB_STATE_LEG_R;
        // zombie.SendFlags |= 8;


        // ----------------------------------------------------
        // ----------------------------------------------------

        float walk_speed = zombie.calc_anim_movement_speed();
        // print("Walk speed: ", ftos(walk_speed), "\n");
        zombie.do_walk_to_goal(walk_speed);
    }
    else if(zombie.state == AI_STATE_TRAVERSING) {
        // TODO - traversal logic needs to be redone...
        zombie_traversal_logic();

        // // FIXME - For now, teleport to end of traversal:
        // float traversal_idx = zombie.cur_traversal_idx;
        // vector end_pos = sv_navmesh_get_traversal_end_pos(traversal_idx);
        // setorigin(zombie, end_pos);
        // zombie.state = AI_STATE_PATHING;
    }
};





void() test_new_ent = {
	makevectors(self.v_angle);

    // Precache all zombie animations:
    if(zombie_anim_walk1_modelindex == 0) {
        precache_model("models/ai/zombie_anim_idle.iqm");
        precache_model("models/ai/zombie_anim_rise.iqm");
        precache_model("models/ai/zombie_anim_walk1.iqm");
        precache_model("models/ai/zombie_anim_walk2.iqm");
        precache_model("models/ai/zombie_anim_walk3.iqm");
        precache_model("models/ai/zombie_anim_jog1.iqm");
        precache_model("models/ai/zombie_anim_run1.iqm");
        precache_model("models/ai/zombie_anim_climbledge.iqm");
        zombie_anim_idle_modelindex = getmodelindex("models/ai/zombie_anim_idle.iqm");
        zombie_anim_rise_modelindex = getmodelindex("models/ai/zombie_anim_rise.iqm");
        zombie_anim_walk1_modelindex = getmodelindex("models/ai/zombie_anim_walk1.iqm");
        zombie_anim_walk2_modelindex = getmodelindex("models/ai/zombie_anim_walk2.iqm");
        zombie_anim_walk3_modelindex = getmodelindex("models/ai/zombie_anim_walk3.iqm");
        zombie_anim_jog1_modelindex = getmodelindex("models/ai/zombie_anim_jog1.iqm");
        zombie_anim_run1_modelindex = getmodelindex("models/ai/zombie_anim_run1.iqm");
        zombie_anim_climbledge_modelindex = getmodelindex("models/ai/zombie_anim_climbledge.iqm");
    }

    AI_Chase zombie = spawn(AI_Chase);
    // zombie.init() // TODO - Which args to use here?
    setorigin(zombie, self.origin + v_forward * 100);

    // TODO - Set zombie skin...
    if(random() < 0.5) {
        zombie.skin = 0;
    }
    else {
        zombie.skin = 1;
    }

    // ------------------------------------------------------------------------
    zombie.dimension_solid |= HITBOX_DIM_ZOMBIES;
    zombie.movetype = MOVETYPE_WALK;
    zombie.solid = SOLID_SLIDEBOX;
    setsize(zombie, VEC_HULL_MIN, VEC_HULL_MAX);
    zombie.owner = world;
    zombie.classname = "ai_zombie";
    zombie.gravity = 1.0;
    zombie.takedamage = DAMAGE_YES;
    zombie.flags = zombie.flags | FL_PARTIALGROUND | FL_MONSTER;
    zombie.health = 999999;
    // ------------------------------------------------------------------------
    zombie.limbs_state |= ZOMBIE_LIMB_STATE_HEAD;
    zombie.limbs_state |= ZOMBIE_LIMB_STATE_ARM_L;
    zombie.limbs_state |= ZOMBIE_LIMB_STATE_ARM_R;
    zombie.limbs_state |= ZOMBIE_LIMB_STATE_LEG_L;
    zombie.limbs_state |= ZOMBIE_LIMB_STATE_LEG_R;
    // ------------------------------------------------------------------------
    precache_model("models/ai/nazi_zombie.iqm"); 
    setmodel(zombie, "models/ai/nazi_zombie.iqm");
    skelblend_t skel_blend_data;
    zombie.skeletonindex = skel_create(zombie.modelindex);
    skel_blend_data.sourcemodelindex = zombie_anim_idle_modelindex;
    skel_blend_data.firstbone = -1;
    skel_blend_data.lastbone = -1;
    skel_blend_data.scale[0] = 1;
    skel_blend_data.animationtime[0] = 0;
    skel_build_ptr(zombie.skeletonindex, 1, &skel_blend_data, sizeof(skel_blend_data));
    // ------------------------------------------------------------------------
    zombie.play_anim(zombie_anim_rise_modelindex, 0);
    zombie.queue_anim(zombie_anim_walk1_modelindex, 0);

    // zombie.play_anim(zombie_anim_walk2_modelindex, 0);
    // zombie.play_anim(zombie_anim_walk3_modelindex, 0);
    // zombie.play_anim(zombie_anim_jog1_modelindex, 0);
    // zombie.play_anim(zombie_anim_run1_modelindex, 0);
    // zombie.cur_anim_playback_speed = 1.0;
    // zombie.cur_anim_playback_speed = 0.8; // Good for run-anim
    // zombie.cur_anim_playback_speed = 0.8 + random() * 0.4;
    // zombie.cur_anim_playback_speed = 0.2 + random() * 0.8;
    // zombie.cur_anim_playback_speed = 0.2 + random() * 2.0;
    zombie.state = AI_STATE_PATHING;
    zombie.nextthink = time + zombie.think_delta_time;
    zombie.think_callback = zombie_think_callback;


    // -------------–-------------–-------------–-------------–-------------–--
    // MDL-based
    // -------------–-------------–-------------–-------------–-------------–--
	// zombie.init(self.origin + v_forward * 100);
    // zombie.frame = get_anim_frame_zombie_rise(0);
    // zombie.play_anim(get_anim_frame_zombie_rise, get_anim_length_zombie_rise(), ANIM_STOP_TYPE_NEXT_ANIM);
    // zombie.queue_anim(get_anim_frame_zombie_walk1, get_anim_length_zombie_walk1(), ANIM_STOP_TYPE_LOOP);
    // zombie.think_callback = zombie_think_callback;
    // zombie.state = AI_STATE_PATHING;
    // // zombie.play_anim(get_anim_frame_zombie_rise, get_anim_length_zombie_rise(), ANIM_STOP_TYPE_LOOP);
    // -------------–-------------–-------------–-------------–-------------–--
};























// DEFINE_ANIM(zombie_idle, 1,2,3,4,5,6,7,8,9,10,11,12,13);                                                // Defines: get_anim_frame_zombie_idle,                  get_anim_length_zombie_idle
// DEFINE_ANIM(zombie_rise, 14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37);      // Defines: get_anim_frame_zombie_rise,                  get_anim_length_zombie_rise
// // DEFINE_ANIM(zombie_rise, 114,115,116,117,118,119,175,176,177,178,179,180,181);      // Defines: get_anim_frame_zombie_rise,                  get_anim_length_zombie_rise
// // DEFINE_ANIM(zombie_rise, 161,162,163,164,165,166,171,172,173,174,175,176,177,178,179,180,181);
// DEFINE_ANIM(zombie_walk1, 38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53);                             // Defines: get_anim_frame_zombie_walk1,                 get_anim_length_zombie_walk1
// DEFINE_ANIM(zombie_walk2, 54,55,56,57,58,59,60,61,62,63,64,65,66,67);                                   // Defines: get_anim_frame_zombie_walk2,                 get_anim_length_zombie_walk2
// DEFINE_ANIM(zombie_walk3, 68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83);                             // Defines: get_anim_frame_zombie_walk3,                 get_anim_length_zombie_walk3
// DEFINE_ANIM(zombie_jog1, 84,85,86,87,88,89,90,91,92);                                                   // Defines: get_anim_frame_zombie_jog1,                  get_anim_length_zombie_jog1
// DEFINE_ANIM(zombie_run1, 93,94,95,96,97,98,99,100,101,102);                                             // Defines: get_anim_frame_zombie_run1,                  get_anim_length_zombie_run1
// DEFINE_ANIM(zombie_attack1, 103,104,105,106,107);                                                       // Defines: get_anim_frame_zombie_attack1,               get_anim_length_zombie_attack1
// DEFINE_ANIM(zombie_attack2, 108,109,110,111,112,113);                                                   // Defines: get_anim_frame_zombie_attack2,               get_anim_length_zombie_attack2
// DEFINE_ANIM(zombie_window_rip_board1, 181,182,183,184,185,186,187,188,189,190,191);                     // Defines: get_anim_frame_zombie_window_rip_board1,     get_anim_length_zombie_window_rip_board1
// DEFINE_ANIM(zombie_window_rip_board2, 191,192,193,194,195,196,197,198,199,200,201);                     // Defines: get_anim_frame_zombie_window_rip_board2,     get_anim_length_zombie_window_rip_board2
// DEFINE_ANIM(zombie_window_attack, 201,202,203,204,205,206,207,208,209,210);                             // Defines: get_anim_frame_zombie_window_attack,         get_anim_length_zombie_window_attack
// DEFINE_ANIM(zombie_window_hop, 114,115,116,117,118,119,120,121,122,123);                                // Defines: get_anim_frame_zombie_window_hop,            get_anim_length_zombie_window_hop
// DEFINE_ANIM(zombie_die1, 124,125,126,127,128,129,130,131,132,133,134);                                  // Defines: get_anim_frame_zombie_die1,                  get_anim_length_zombie_die1
// DEFINE_ANIM(zombie_die2, 135,136,137,138,139);                                                          // Defines: get_anim_frame_zombie_die2,                  get_anim_length_zombie_die2
// DEFINE_ANIM(zombie_die3, 140,141,142,143,144,145,146,147,148,149);                                      // Defines: get_anim_frame_zombie_die3,                  get_anim_length_zombie_die3
// DEFINE_ANIM(zombie_die_wunder, 211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227);    // Defines: get_anim_frame_zombie_die_wunder,            get_anim_length_zombie_die_wunder
// DEFINE_ANIM(zombie_fall, 150,151,152,153);                                                              // Defines: get_anim_frame_zombie_fall,                  get_anim_length_zombie_fall
// DEFINE_ANIM(zombie_land, 154,155,156,157,158,159,159);                                                  // Defines: get_anim_frame_zombie_land,                  get_anim_length_zombie_land
// DEFINE_ANIM(zombie_jump, 160,161,162,163,164,165,166);                                                  // Defines: get_anim_frame_zombie_jump,                  get_anim_length_zombie_jump
// DEFINE_ANIM(zombie_climb, 167,168,169,170,171,172,173,174,175,176,177,178,179,180);                     // Defines: get_anim_frame_zombie_climb,                 get_anim_length_zombie_climb
// DEFINE_ANIM(zombie_jump_low, 163,164,165);                                                              // Defines: get_anim_frame_zombie_jump_low,              get_anim_length_zombie_jump_low
// DEFINE_ANIM(zombie_climb_low, 170,171,172,173,174,175,176,177,178,179,180);                             // Defines: get_anim_frame_zombie_climb_low,             get_anim_length_zombie_climb_low
// DEFINE_ANIM(zombie_fall_loop, 151,152,153,152);                                                         // Defines: get_anim_frame_zombie_fall_loop,            get_anim_length_zombie_fall_loop
// DEFINE_ANIM(zombie_leap, 228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247);   // Defines: get_anim_frame_zombie_leap,            get_anim_length_zombie_leap
// DEFINE_ANIM(zombie_leap_jump, 228,229,230,231,232,233,234,235,236,237,238,239,240,241);                 // Defines: get_anim_frame_zombie_leap_jump,            get_anim_length_zombie_leap_jump
// DEFINE_ANIM(zombie_leap_land, 242,243,244,245,246,247);                                                 // Defines: get_anim_frame_zombie_leap_land,            get_anim_length_zombie_leap_land
// DEFINE_ANIM(zombie_fence_jump, 228,229,230,231,232,233,234,235,248,249,250,116,117,118,119,120,121,251,152,153); // Defines: get_anim_frame_zombie_fence,            get_anim_length_zombie_fence
// DEFINE_ANIM(zombie_fence_land, 154,155,156,157,158,159);                                                // Defines: get_anim_frame_zombie_fence_land,            get_anim_length_zombie_fence_land
























// void(vector org) AI_Zombie::init = {
//     setmodel(this, "models/ai/zfull.mdl");
//     // ---------------------------------
//     // Usual zombie setup stuff
//     // ---------------------------------
//     this.solid = SOLID_CORPSE;
// #ifdef PC
// 	this.dimension_solid = HITBOX_DIM_ZOMBIES;
// #endif // PC

//     // this.movetype = MOVETYPE_STEP;
//     this.movetype = MOVETYPE_WALK;
//     setsize (this, '-8 -8 -32', '8 8 30');
//     this.origin = org;
//     setorigin(this, this.origin);
//     this.classname = "ai_zombie";
//     this.gravity = 1.0;
//     this.takedamage = DAMAGE_YES;
//     this.flags = this.flags | FL_PARTIALGROUND | FL_MONSTER;
//     this.health = 999999;
//     // SetUpHitBoxes(self);
//     // ---------------------------------
//     this.yaw_speed = 20;
//     this.cur_anim_frametime = 0.1;
//     // ---------------------------------
//     // this.think_delta_time = 0.1; // 10x per second
//     // this.nextthink = time + this.think_delta_time;
//     this.nextthink = time + this.cur_anim_frametime;
//     // this.cur_fg_start_time = -1;
// }


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

