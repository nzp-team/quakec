var struct framegroup {
    float start_frame;
    float end_frame;
    float duration;
    void() start_callback; 	    // Called at the first frame of the range
    void() frame_callback;  	// Called at every frame of the range (after start / finish callbacks)
    void() finish_callback; 	// Called at the last frame of the range
    // void() think_callback       // Called at each think invocation
};

// #define MAX_FRAMEGROUP_CATEGORY_SIZE 4

// var struct framegroup_registry_category {
//     framegroup framegroups[MAX_FRAMEGROUP_CATEGORY_SIZE];
//     float num_framegroups;
// };


// var struct framegroup_registry {
//     framegroup_registry_category fg_die;
//     framegroup_registry_category fg_walk;
//     framegroup_registry_category fg_idle;
//     framegroup_registry_category fg_attack;
// };


// framegroup_registry zombie_th_reg;
// framegroup_registry crawler_th_reg;
// framegroup_registry dog_th_reg;

framegroup 					zombie_attack_0;
framegroup 					zombie_attack_1;
framegroup 					zombie_idle_0;
framegroup 					zombie_die_0;
framegroup 					zombie_die_1;
framegroup 					zombie_die_2;
framegroup 					zombie_walk_0;
framegroup 					zombie_walk_1;
framegroup 					zombie_walk_2;
framegroup 					zombie_jog_0;
framegroup 					zombie_run_1;
framegroup 					zombie_run_2;
framegroup 					zombie_run_3;


void create_framegroup(float start_frame, float end_frame, float duration, void() start_callback, 
                               void() frame_callback, void() finish_callback, __out framegroup fg) {
    fg.start_frame = start_frame;
    fg.end_frame = end_frame;
    fg.duration = duration;
    fg.start_callback = start_callback;
    fg.frame_callback = frame_callback;
    fg.finish_callback = finish_callback;
    // fg.think_callback = think_callback;
    // TODO - Add think_callback to function args
};


// float register_framegroup(framegroup_registry_category *reg_cat, framegroup *fgroup) {
//     if(reg_cat->num_framegroups >= MAX_FRAMEGROUP_CATEGORY_SIZE)
//         return -1;
//     reg_cat->framegroups[reg_cat->num_framegroups] = fgroup;
//     reg_cat->num_framegroups++;
//     return 0;
// }

// void register_framegroup(__out framegroup_registry_category reg_cat, framegroup fgroup) {
//     print(strcat("\tinside before:",ftos(reg_cat.num_framegroups),", "));

//     if(reg_cat.num_framegroups >= MAX_FRAMEGROUP_CATEGORY_SIZE) {
//         return -1;
//     }
//     reg_cat.framegroups[reg_cat.num_framegroups] = fgroup;
//     reg_cat.num_framegroups += 1;
//     print(strcat(" added one!"));
//     print(strcat(" after:",ftos(reg_cat.num_framegroups),"\n"));
//     return 0;
// }


// void(framegroup_registry_category reg_cat) random_dispatch = {
//   float chosen_action = rand() * reg_cat.num_actions; // FTEQCC rounds down floats when used as indices
//   framegroup chosen_framegroup = reg_cat[chosen_action];
//   do_something(chosen_framegroup);
// };


class AI_Chase : entity {
    // framegroup_registry *th_reg;

    nonvirtual float () fg_die = {
        // random_dispatch(th_reg->th_die);
    };
    nonvirtual float () fg_walk = {
        // random_dispatch(th_reg->th_die);
    };
    nonvirtual float () fg_attack = {
        // random_dispatch(th_reg->th_die);
    };
    nonvirtual float () fg_idle = {
        // random_dispatch(th_reg->th_die);
    };
};




framegroup 					fg_zombie_walk_0;
framegroup 					fg_zombie_walk_1;
framegroup 					fg_zombie_walk_2;
framegroup 					fg_zombie_jog_0;
framegroup 					fg_zombie_run_0;
framegroup 					fg_zombie_idle_0;
framegroup 					fg_zombie_attack_0;
framegroup 					fg_zombie_attack_1;
framegroup 					fg_zombie_die_0;
framegroup 					fg_zombie_die_1;
framegroup 					fg_zombie_die_2;



void start_callback() {
    print("start called\n");
};
void frame_callback() {
    print("frame called\n");
};
void end_callback() {
    print("end called\n");
};
// TODO - Add `think` callback


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

    create_framegroup(  38,     53,     10.0,   start_callback, frame_callback, end_callback, fg_zombie_walk_0);
    // create_framegroup(  53,     38,     10.0,   start_callback, frame_callback, end_callback, fg_zombie_walk_0);
    create_framegroup(  53,     66,     10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_walk_1);
    create_framegroup(  67,     82,     10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_walk_2);
    create_framegroup(  116,    129,    10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_jog_0);
    create_framegroup(  78,     85,     10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_run_0);
    create_framegroup(  0,      12,     10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_idle_0);
    create_framegroup(  86,     90,     10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_attack_0);
    create_framegroup(  91,     96,     10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_attack_1);
    create_framegroup(  123,    133,    10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_die_0);
    create_framegroup(  134,    138,    10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_die_1);
    create_framegroup(  139,    148,    10.0,   SUB_Null, SUB_Null, SUB_Null, fg_zombie_die_2);
};





// class Zombie : Chase_AI {

//     // Constructor after calling `spawn(Zombie, ...);`
//     void initialize() {

//     }
  
//     // void () init_class {
//     //     // Define the framegroups
//     //     // // Register `die` framegroups
//     //     // register_framegroup(&zombie_th_reg, zombie_th_reg.th_die, zombie_die_0);
//     //     // register_framegroup(&zombie_th_reg, zombie_th_reg.th_die, zombie_die_1);
//     //     // register_framegroup(&zombie_th_reg, zombie_th_reg.th_die, zombie_die_2);
//     //     // // Register `walk` framegroups
//     //     // register_framegroup(&zombie_th_reg, zombie_th_reg.th_walk, zombie_walk_0);
//     //     // register_framegroup(&zombie_th_reg, zombie_th_reg.th_walk, zombie_walk_1);
//     //     // register_framegroup(&zombie_th_reg, zombie_th_reg.th_walk, zombie_walk_2);
//     // };
        
//     // // Instance constructor
//     // void () init {
//     //         this.th_reg = 
//     // }

//     float () fg_die = {
//     // random_dispatch(th_reg->th_die);
//     }
//     float () fg_walk = {
//     // random_dispatch(th_reg->th_die);
//     }
//     float () fg_attack = {
//     // random_dispatch(th_reg->th_die);
//     }
//     float () fg_idle = {
//     // random_dispatch(th_reg->th_die);
//     }  


// // //   float () th_walk = {
// // //     // random_dispatch(th_reg->th_die);
// // //     // TODO - Check what round we're on, and manually choose which walk routine to perform....
// // //     	if(rounds < 3) {
// // //         	// randomly choose between th_walk1, th_walk2, th_walk3
// // //       }
// // //   		else if {
// // //         	// 
// // //       }
// // //   }

// };


// Performs 1D linear interpolation between x1 and x2 on t=0 to t=1
// NOTE - the value of t is clamped to always be 0<=t<=1
float(float x1, float x2, float t) lerp = {
    // t = min(max(t,0.0), 1.0);
    // Thanks, QC
    if(t < 0.0) {
        t = 0.0;
    }
    else if(t > 1.0) {
        t = 1.0;
    }
    return t * (x2 - x1) + x1;
};


class AI_Zombie : AI_Chase {
    float counter;

    // ------------------------
    float cur_fg_frame_callback_next_frame;
    // ------------------------
    float cur_fg_start_time;
    float cur_fg_start_frame;
    float cur_fg_end_frame;
    float cur_fg_duration;
    // void() endanimfunc = SUB_Null;
    virtual void() cur_fg_start_callback = SUB_Null;
    virtual void() cur_fg_frame_callback = SUB_Null;
    virtual void() cur_fg_finish_callback = SUB_Null;
    // virtual void() cur_fg_think_callback = SUB_Null;
    // ------------------------


    // Constructor after calling `spawn(Zombie, ...);`
    nonvirtual void(vector org) init = {
        setmodel(this, "models/ai/zfull.mdl");
        // ---------------------------------
        // Usual zombie setup stuff
        // ---------------------------------
        this.solid = SOLID_SLIDEBOX;
        this.movetype = MOVETYPE_STEP;
        setsize (this, '-8 -8 -32', '8 8 30');
        this.origin = org;
        setorigin(this, this.origin);
        this.classname = "ai_zombie";
        this.takedamage = DAMAGE_YES;
        this.flags = this.flags | FL_PARTIALGROUND | FL_MONSTER;
        this.health = 999999;
        // SetUpHitBoxes(self);
        // ---------------------------------
        // this.cur_anim_end_frame = 227; // Zombie last frame
        this.nextthink = time + 0.1;
        this.counter = 0;
        this.cur_fg_start_time = -1;
    };



    virtual void() think = {
        
        if(this.cur_fg_start_time >= 0) {
            float dt = time - this.cur_fg_start_time;
            // float lerp_frac = (dt / this.cur_fg_duration);
            float lerp_frac = (dt / this.cur_fg_duration) % 1.0; // LOOP

            this.frame = lerp(this.cur_fg_start_frame, this.cur_fg_end_frame, lerp_frac);

            // If the animation is playing forward (low frame num to high frame num)
            if(this.cur_fg_end_frame > this.cur_fg_start_frame) {
                if(this.frame >= this.cur_fg_frame_callback_next_frame) {
                    this.cur_fg_frame_callback_next_frame = floor(this.frame) + 1;
                    this.cur_fg_frame_callback();
                    if(this.frame >= this.cur_fg_end_frame) {
                        this.cur_fg_finish_callback();
                    }
                }
            }
            // else the animation is playing in reverse (high frame num to low frame num)
            else {
                if(this.frame <= this.cur_fg_frame_callback_next_frame) {
                    this.cur_fg_frame_callback();
                    this.cur_fg_frame_callback_next_frame = ceil(this.frame) - 1;
                    if(this.frame <= this.cur_fg_end_frame) {
                        this.cur_fg_finish_callback();
                    }
                }
            }
        }


        // Need to compute the exact fractional frame that we should be on
        // Knowns:
        //  - total duration of the animation
        //  - start and end frames


        // print("test: ");
        // print(ftos(time));
        // print(", ");
        // print(ftos(this.counter));
        // print("\n");
        // this.counter += 1;

        // if(this.counter > 10) {
        //     this.frame = (this.frame + 20) % 227;
        //     this.counter = 0;
        // }
        this.nextthink = time + 0.1;
    };


    nonvirtual void (framegroup fgroup) set_frame_group = {
        // float temp_anim_dur = 0.5 + (fgroup.duration * random()) * 0.5;
        float temp_anim_dur = 10;
        // float temp_anim_dur = 10;
        this.cur_fg_start_frame = fgroup.start_frame;
        this.cur_fg_end_frame = fgroup.end_frame;
        this.cur_fg_duration = temp_anim_dur;
        this.cur_fg_start_callback = fgroup.start_callback;
        this.cur_fg_frame_callback = fgroup.frame_callback;
        this.cur_fg_finish_callback = fgroup.finish_callback;
        // Start the animation now
        this.frame = this.cur_fg_start_frame;
        this.cur_fg_start_time = time;
        this.cur_fg_start_callback();
        this.cur_fg_frame_callback_next_frame = this.cur_fg_start_frame;
    };

    float () fg_walk = {
        this.set_frame_group(fg_zombie_walk_0);
    };
    float () fg_die = {
        // TODO - Execute -- zombie_die_0
    };
    float () fg_attack = {
        // TODO - Execute an attack framegroup
    };
    float () fg_idle = {
        // TODO - Execute the idle framegroup
    };
};




// var struct test_struct {
//     float x;
//     float y[4];
//     void() some_funcs[4];
// };

// void make_new_struct(__out test_struct s) {
//     s.x = 10;
//     s.y[0] = 20;
//     s.y[1] = 21;
//     s.y[2] = 22;
//     s.y[3] = 23;
//     s.some_funcs[0] = SUB_Null;
//     s.some_funcs[1] = SUB_Null;
//     s.some_funcs[2] = SUB_Null;
//     s.some_funcs[3] = SUB_Null;
// };

// var struct awesome_struct {
//     test_struct why[4];
// };




// #define TESTFUNCSIZE 30
// var struct struct_000 {
//     float x[TESTFUNCSIZE];
// };

// void testfunc(__inout struct_000 s) {
//     for(float i = 0; i < TESTFUNCSIZE; i++){
//         s.x[i] *= 2.0;
//     }
// };

// void() somefunc = {
//     // Make the struct and fill it with indices
//     struct_000 s;
//     for(float i = 0; i < TESTFUNCSIZE; i++){
//         s.x[i] = i;
//     }
//     // Print the vals before passing 'em in
//     print("Outside before: ");
//     for(float i = 0; i < TESTFUNCSIZE; i++){
//         print(ftos(s.x[i])); 
//         print(", ");
//     }
//     print("\n");
//     // Pass 'em in
//     testfunc(s);
//     // Print the vals after modifying them
//     print("Outside after: ");
//     for(float i = 0; i < TESTFUNCSIZE; i++){
//         print(ftos(s.x[i])); 
//         print(", ");
//     }
//     print("\n");
// };





void() test_new_ent = {
    create_framegroups();

	makevectors(self.v_angle);
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

}



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