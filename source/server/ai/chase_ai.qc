var struct framegroup {
    float start_frame;
    float end_frame;
    float duration;
    // void(entity) start_callback; 	// Called at the first frame of the range
    void(entity) frame_callback;  	// Called at every frame of the range (after start / finish callbacks)
    // void(entity) end_callback; 	    // Called at the last frame of the range
    // FIXME - Increasing the size of this framegroup by one more function pointer causes chaos...
    // I assume I run out of space to pass framegroups along as arguments at any point...
    // It starts to write into weird memory locations, like overriding self / world... things just break down.
    // TODO - How can I refactor this to work?
    void(entity) think_callback;    // Called at each think invocation
    // -- Maybe I can get rid of start / end callbacks? idk
    // I should think about how I actually plan on using these...

    // TODO - Get rid of start / end callback, add fields to the AI_Chase class that denotes
    // TODO - These callbacks will be executed at the same time as frame anyways.
};


// FIXME - This framegroup  nonsense is causing chaos... the struct is too large apparently... what can I cut out?


framegroup make_empty_framegroup(__out framegroup fg) {
    fg.start_frame = -1;
    fg.end_frame = -1;
    fg.duration = 1.0;
    // fg.start_callback = SUB_Null;
    fg.frame_callback = SUB_Null;
    // fg.end_callback = SUB_Null;
    fg.think_callback = SUB_Null;
}

void init_framegroup(   float start_frame, float end_frame, float duration,
                        void(entity) frame_callback, 
                        void(entity) think_callback, 
                            __out framegroup fg) {
    fg.start_frame = start_frame;
    fg.end_frame = end_frame;
    fg.duration = duration;
    fg.frame_callback = frame_callback;
    fg.think_callback = think_callback;
}






class AI_Chase : entity {
    // framegroup_registry *th_reg;
    entity path_target; // If specified, path towards entity
    vector path_pos; // Otherwise, path towards location specified
    float think_delta_time; // Delta time (seconds) between each `this.think();`

    // ------------------------------
    // Current Framegroup value vars
    // ------------------------------
    float cur_fg_start_time;
    float cur_fg_start_frame;
    float cur_fg_end_frame;
    float cur_fg_duration;
    // void() endanimfunc = SUB_Null;
    // virtual void(entity) cur_fg_start_callback = SUB_Null;
    virtual void(entity) cur_fg_frame_callback = SUB_Null;
    // virtual void(entity) cur_fg_end_callback = SUB_Null;
    virtual void(entity) cur_fg_think_callback = SUB_Null;
    // ------------------------------
    // Framegroup state vars
    // ------------------------------
    float cur_fg_idx; // Counter for checking when the framegroup has been changed
    float cur_fg_frame_callback_next_frame;
    float cur_fg_frame_callback_is_start_frame; // Is set to true when performing cur_fg_frame_callback for the first framegroup frame 
    float cur_fg_frame_callback_is_end_frame;   // Is set to true when performing cur_fg_frame_callback for the final framegroup frame

    // ------------------------------


    // Constructor. Called when calling `spawn(AI_Chase);`
    virtual void() AI_Chase = {
        this.path_target = world;
        this.path_pos = world.origin;
        this.think_delta_time = 0.1; // Call `this.think();` 10x per second
        this.cur_fg_idx = 0;
    };


    virtual void() think = {
        if(this.cur_fg_start_time >= 0) {
            float cur_framegroup_idx = this.cur_fg_idx;
            float dt = time - this.cur_fg_start_time;
            float lerp_frac = (dt / this.cur_fg_duration);
            // Frame ranges are inclusive, do an un-clamped interpolation to include the final frame
            float cur_frame = unclamped_lerp(this.cur_fg_start_frame, this.cur_fg_end_frame, lerp_frac);
            // For rendering, keep frame number always within current animation
            if(this.cur_fg_end_frame > this.cur_fg_start_frame) {
                this.frame = clamp(cur_frame, this.cur_fg_start_frame, this.cur_fg_end_frame);
            }
            else {
                this.frame = clamp(cur_frame, this.cur_fg_end_frame, this.cur_fg_start_frame);
            }

            // print("Cur frame: ");
            // print(ftos(this.frame));
            // print(", start_frame: ");
            // print(ftos(this.cur_fg_start_frame));
            // print(", end_frame: ");
            // print(ftos(this.cur_fg_end_frame));
            // print(", cur_frame: ");
            // print(ftos(cur_frame));
            // print(", next frame callback: ");
            // print(ftos(this.cur_fg_frame_callback_next_frame));
            // print(", duration: ");
            // print(ftos(this.cur_fg_duration));
            // print("\n");

            // TODO - round frame to nearest frame?

            // If the animation is playing forward (low frame num to high frame num)
            if(this.cur_fg_end_frame > this.cur_fg_start_frame) {
                if(cur_frame >= this.cur_fg_frame_callback_next_frame) {
                    if(cur_frame >= this.cur_fg_end_frame + 1) {
                        this.cur_fg_frame_callback_is_end_frame = true;
                    }
                    this.cur_fg_frame_callback(this); // FIXME - This can override and invoke new things, need to be careful
                    // Callback may have assigned new framegroup
                    if(this.cur_fg_idx == cur_framegroup_idx) {
                        this.cur_fg_frame_callback_is_start_frame = false;
                        this.cur_fg_frame_callback_is_end_frame = false;
                        this.cur_fg_frame_callback_next_frame = floor(cur_frame) + 1;
                    }
                    // print("\tSet next frame callback frame to: ");
                    // print(ftos(this.cur_fg_frame_callback_next_frame));
                    // print("\n");
                }
            }
            // else the animation is playing in reverse (high frame num to low frame num)
            else {
                if(cur_frame <= this.cur_fg_frame_callback_next_frame) {
                    if(cur_frame <= this.cur_fg_end_frame - 1) {
                        this.cur_fg_frame_callback_is_end_frame = true;
                    }
                    this.cur_fg_frame_callback(this);
                    // Callback may have assigned new framegroup
                    if(this.cur_fg_idx == cur_fg_idx) {
                        this.cur_fg_frame_callback_is_start_frame = false;
                        this.cur_fg_frame_callback_is_end_frame = false;
                        this.cur_fg_frame_callback_next_frame = ceil(cur_frame) - 1;
                    }
                }
            }
            // Callback may have assigned new framegroup
            // if(this.cur_fg_idx == cur_fg_idx) {
                this.cur_fg_think_callback(this);
            // }
        }
        this.nextthink = time + this.think_delta_time;
    };

    virtual void (float duration) set_framegroup_duration = {
        // If no current framegroup, stop
        if(this.cur_fg_start_time < 0) {
            print("Warning: Attempted to set framegroup duration without an active framegroup.\n");
            return;
        }

        this.cur_fg_duration = duration;
        // --------------------------------------------------------------------
        // Adjust think_delta_time so no frames are skipped
        // --------------------------------------------------------------------
        float n_anim_frames = fabs(this.cur_fg_end_frame - this.cur_fg_start_frame);
        float time_per_frame = duration / n_anim_frames;
        // If faster than 10FPS, make thinks be called more often to not miss a frame callback
        if(time_per_frame < 0.10) {
            this.think_delta_time = time_per_frame * 0.5;
        }
        else {
            this.think_delta_time = 0.1;
        }
        // --------------------------------------------------------------------
    };

    virtual void (framegroup fgroup) set_framegroup = {
        // Increment framegroup counter. Reset every 100, we only use this to check when it has changed
        this.cur_fg_idx = (this.cur_fg_idx + 1) % 100;

        // FIXME - frame callback isn't guaranteed to be called for every frame because sometimes we skip over frames
        // FIXME - I should modify the think delta time to run at 80% of the time between frames, or 0.10 seconds, whichever is greater.
        // FIXME - That way, if are playing an animation really fast, it'll call think more often
        this.cur_fg_start_frame = fgroup.start_frame;
        this.cur_fg_end_frame = fgroup.end_frame;
        this.cur_fg_frame_callback = fgroup.frame_callback;
        this.cur_fg_think_callback = fgroup.think_callback;
        this.set_framegroup_duration(fgroup.duration);

        // Start the animation now
        this.cur_fg_frame_callback_is_start_frame = true;
        this.cur_fg_frame_callback_is_end_frame = false;
        this.frame = this.cur_fg_start_frame;
        this.cur_fg_start_time = time;
        this.cur_fg_frame_callback_next_frame = this.cur_fg_start_frame;
        // print("Done setting framegroup! Start frame: ");
        // print(ftos(fgroup.start_frame));
        // print(", End frame: ");
        // print(ftos(fgroup.end_frame));
        // print("\n");
    };


    virtual void () fg_die = {};
    virtual void () fg_walk = {};
    virtual void () fg_attack = {};
    virtual void () fg_idle = {};


    virtual void (float dist) do_walk_to_goal = {
        if(dist == 0) {
            return;
        }

        vector goal_pos = path_pos;
        if(this.path_target != world) {
            goal_pos = this.path_target.origin;
        }

        this.ideal_yaw = vectoyaw(goal_pos - this.origin);
        ChangeYaw();
        vector new_velocity;
        float dist_to_goal = vlen(goal_pos - this.origin);
        if(dist > dist_to_goal) {
            dist = dist_to_goal;
        }
        new_velocity = normalize(goal_pos - this.origin) * dist;
        new_velocity_z = this.velocity_z;
        this.velocity = new_velocity;
    };
};





class AI_Zombie : AI_Chase {
    entity enemy; // If near, attack

    // Constructor. Called when calling `spawn(AI_Zombie);`
    // virtual void() AI_Zombie = {};
    // This should be called explicitly:
    virtual void(vector org) init;

    virtual void () fg_die;
    virtual void () fg_walk;
    virtual void () fg_attack;
    virtual void () fg_idle;
};











framegroup 					fg_zombie_walk_0;
framegroup 					fg_zombie_walk_1;
framegroup 					fg_zombie_walk_2;
framegroup 					fg_zombie_jog_0;
framegroup 					fg_zombie_run_0;
// framegroup 					fg_zombie_run_1; // TODO - Either add new anims, or make new run FG with different speed?
// framegroup 					fg_zombie_run_2; // TODO - Either add new anims, or make new run FG with different speed?
framegroup 					fg_zombie_idle_0;
framegroup 					fg_zombie_attack_0;
framegroup 					fg_zombie_attack_1;
framegroup 					fg_zombie_die_0;
framegroup 					fg_zombie_die_1;
framegroup 					fg_zombie_die_2;






float get_zombie_walk_is_footstep(float frame) {
    frame = floor(frame);
    switch(frame) {
        // ------------ Zombie Walk 1 --------------
        case 39:        // Right foot
        case 44:        // Left foot
        case 47:        // Right foot
        case 51:     // Left foot
            return 1;
        default:
            return 0;
    }
}

float get_zombie_walk_dist_for_frame(float frame) {
    frame = floor(frame);
    switch(frame) {
        // ------------ Zombie Walk 1 --------------
        case 37:
            return 8;
        case 38:
        case 39:
        case 40:
        case 41:
        case 42:
            return 3.5;
        case 43:
            return 8.8;
        case 44:
            return 9;
        case 45:
        case 46:
            return 4;
        case 47:
            return 7.8;
        case 48:
            return 5.2;
        case 49:
            return 2.4;
        case 50:
            return 2.8;
        case 51:
            return 6.5;
        case 52:
            return 7.7;
        default:
            return 0.0;
    }
}

// Called at the first frame of the current animation
void zombie_walk_start_callback(entity ent) {
    // print("start called\n");
};

// Called once per animation frame:
void zombie_walk_frame_callback(entity ent) {
    AI_Zombie zombie_ent = (AI_Zombie) ent;
    // print("frame called\n");
    // print("frame called. At frame: ");
    // print(ftos(ent.frame));
    // // print(", is first frame? ");
    // // print(ftos(zombie_ent.cur_fg_frame_callback_is_start_frame));
    // // print(", is final frame? ");
    // // print(ftos(zombie_ent.cur_fg_frame_callback_is_end_frame));
    // print("\n");

    if(get_zombie_walk_is_footstep(ent.frame)) {
        if(random() < 0.5) {
            sound(self, 5, "sounds/zombie/s0.wav", 1, ATTN_NORM);
        }
        else {
            sound(self, 5, "sounds/zombie/s1.wav", 1, ATTN_NORM);
        }
    }

    if(zombie_ent.cur_fg_frame_callback_is_end_frame) {
        // print("At final frame, restarting walk\n");
        zombie_ent.fg_walk();
    }

    // TODO - If at final frame, call fg_walk again...
    // AI_Zombie zombie_ent = (AI_Zombie) ent;
    // zombie_ent.fg_walk();
    // ent.fg_walk();
};


// Called once per ent.think invocation
void zombie_walk_think_callback(entity ent) {
    // print("Think called\n");
    // print("Think called for frame: ");
    // print(ftos(ent.frame));
    // print("\n");
    AI_Zombie zombie_ent = (AI_Zombie) ent;
    // zombie_ent.fg_walk();
    
    // "::classname" denotes the global ".string classname" field.
    entity player_ent = find( world, ::classname, "player"); 
    if(player_ent != world) {
        zombie_ent.path_target = player_ent;
        ent.enemy = player_ent;
    }

    float n_anim_frames = fabs(zombie_ent.cur_fg_end_frame - zombie_ent.cur_fg_start_frame);
    // float dist_per_frame = 5.23125; // qu
    float dist_per_frame = get_zombie_walk_dist_for_frame(zombie_ent.frame);
    float time_per_frame = zombie_ent.cur_fg_duration / n_anim_frames;
    float speed = dist_per_frame / time_per_frame;
    zombie_ent.do_walk_to_goal(speed);
};


void create_framegroups() {
    // walk0   37      52
    // walk1   53      66
    // walk3   67      82
    // jog0    116     129
    // run0    78      85
    // idle0   0       12
    // attack0 86      90
    // attack1 91      96
    // death0  123     133
    // death1  134     138
    // death2  139     148

    // In blender, it's frames 38 to 53, inclusive
    // make_empty_framegroup(fg_zombie_walk_0);
    init_framegroup( 38, 53, 1.0, zombie_walk_frame_callback, zombie_walk_think_callback, fg_zombie_walk_0);
    init_framegroup(  53,   66,   10.0, SUB_Null, SUB_Null, fg_zombie_walk_1);
    init_framegroup(  67,   82,   10.0, SUB_Null, SUB_Null, fg_zombie_walk_2);
    init_framegroup(  116,  129,  10.0, SUB_Null, SUB_Null, fg_zombie_jog_0);
    init_framegroup(  78,   85,   10.0, SUB_Null, SUB_Null, fg_zombie_run_0);
    init_framegroup(  0,    12,   10.0, SUB_Null, SUB_Null, fg_zombie_idle_0);
    init_framegroup(  86,   90,   10.0, SUB_Null, SUB_Null, fg_zombie_attack_0);
    init_framegroup(  91,   96,   10.0, SUB_Null, SUB_Null, fg_zombie_attack_1);
    init_framegroup(  123,  133,  10.0, SUB_Null, SUB_Null, fg_zombie_die_0);
    init_framegroup(  134,  138,  10.0, SUB_Null, SUB_Null, fg_zombie_die_1);
    init_framegroup(  139,  148,  10.0, SUB_Null, SUB_Null, fg_zombie_die_2);
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
    // ---------------------------------
    this.think_delta_time = 0.1; // 10x per second
    this.nextthink = time + this.think_delta_time;
    this.cur_fg_start_time = -1;
}


// void() AI_Zombie::think = {
//     print("we do be thinkin!\n");
//     // TODO - how to call superclass think?
// }


void () AI_Zombie::fg_walk = {
    this.set_framegroup(fg_zombie_walk_0);
    this.set_framegroup_duration(fg_zombie_walk_0.duration * (1.0 + 3.0 * random()));
    // print("Set anim duration to: ");
    // print(ftos(this.cur_fg_duration));
    // print("\n");
}
void () AI_Zombie::fg_die = {
    // TODO - Execute -- zombie_die_0
}
void () AI_Zombie::fg_attack = {
    // TODO - Execute an attack framegroup
}
void () AI_Zombie::fg_idle = {
    // TODO - Execute the idle framegroup
}



void() test_new_ent = {
    create_framegroups();

	makevectors(self.v_angle);
    // AI_Chase test_ent = spawn(AI_Chase);
	AI_Zombie zombie = spawn(AI_Zombie);
	zombie.init(self.origin + v_forward * 100);
    zombie.fg_walk();









    // somefunc();
    // framegroup_registry zombie_th_reg;
    // // framegroup_registry crawler_th_reg;
    // // framegroup_registry dog_th_reg;

    // framegroup 					zombie_attack_0;
    // // framegroup 					zombie_attack_1;
    // // framegroup 					zombie_idle_0;
    // // framegroup 					zombie_die_0;
    // // framegroup 					zombie_die_1;
    // // framegroup 					zombie_die_2;
    // // framegroup 					zombie_walk_0;
    // // framegroup 					zombie_walk_1;
    // // framegroup 					zombie_walk_2;
    // // framegroup 					zombie_jog_0;
    // // framegroup 					zombie_run_1;
    // // framegroup 					zombie_run_2;
    // // framegroup 					zombie_run_3;



    // create_framegroup( zombie_attack_0, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_attack_1, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_idle_0, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_die_0, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_die_1, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_die_2, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_walk_0, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_walk_1, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_walk_2, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_jog_0, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_run_1, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_run_2, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);
    // // create_framegroup( zombie_run_3, 0, 10, 5.0, SUB_Null, SUB_Null, SUB_Null);


    // // zombie_th_reg.fg_attack.num_framegroups = 2;

    // print(strcat("Num before:",ftos(zombie_th_reg.fg_attack.num_framegroups),"\n"));
    // register_framegroup( zombie_th_reg.fg_attack, zombie_attack_0);
    // print(strcat("Num after:",ftos(zombie_th_reg.fg_attack.num_framegroups),"\n"));



    // zombie_th_reg.fg_attack = register_framegroup( zombie_th_reg.fg_attack, zombie_attack_0);
    // print(strcat("Num before:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // zombie_th_reg.fg_attack = register_framegroup( zombie_th_reg.fg_attack, zombie_attack_0);
    // print(strcat("Num after:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // print(strcat("Num before:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // zombie_th_reg.fg_attack = register_framegroup( zombie_th_reg.fg_attack, zombie_attack_0);
    // print(strcat("Num after:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // print(strcat("Num before:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // zombie_th_reg.fg_attack = register_framegroup( zombie_th_reg.fg_attack, zombie_attack_0);
    // print(strcat("Num after:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // print(strcat("Num before:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // zombie_th_reg.fg_attack = register_framegroup( zombie_th_reg.fg_attack, zombie_attack_0);
    // print(strcat("Num after:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // print(strcat("Num before:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // zombie_th_reg.fg_attack = register_framegroup( zombie_th_reg.fg_attack, zombie_attack_0);
    // print(strcat("Num after:",ftos(zombie_th_reg.fg_attack.num_framegroups)));
    // print(ftos(result));
    // print("\n");
    // result = register_framegroup( &(zombie_th_reg.fg_attack), &zombie_attack_1);
    // print(ftos(result));
    // print("\n");
    // result = register_framegroup( &(zombie_th_reg.fg_idle), &zombie_idle_0);
    // print(ftos(result));
    // print("\n");
    // result = register_framegroup( &(zombie_th_reg.fg_die), &zombie_die_0);
    // print(ftos(result));
    // print("\n");
    // result = register_framegroup( &(zombie_th_reg.fg_die), &zombie_die_1);
    // print(ftos(result));
    // print("\n");

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