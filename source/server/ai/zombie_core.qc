/*
	server/ai/zombie_core.qc

	zombie things

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

#define ZOMBIE_DAMAGE_THROUGH_WINDOW 		60

void() Zombie_Walk_Setup;
void() crawler_rip_board1;
void() crawler_da1;
void() crawler_die1;
void() crawler_death_wunder1;
void() LinkZombiesHitbox;


float EMPTY_BBOX = 0;
float BASE_BBOX = 1;
float IDLE_BBOX = 2;
//Rising from ground bbox
float WALK1_BBOX = 4;
float WALK2_BBOX = 5;
float WALK3_BBOX = 6;
float JOG_BBOX = 7;
float RUN_BBOX = 8;
float CRAWLER_BBOX = 9;

void(float what) play_sound_z =
{
	if(self.classname == "ai_zombie")
	{
		local float e;
		e = random();
		
		if(what == 1)//attack
		{
			if (e < 0.125)
				sound(self, CHAN_WEAPON, "sounds/zombie/a0.wav", 1, ATTN_NORM);
			else if (e < 0.25)
				sound(self, CHAN_WEAPON, "sounds/zombie/a1.wav", 1, ATTN_NORM);
			else if (e < 0.375)
				sound(self, CHAN_WEAPON, "sounds/zombie/a2.wav", 1, ATTN_NORM); 
			else if( e < 0.5)
				sound(self, CHAN_WEAPON, "sounds/zombie/a3.wav", 1, ATTN_NORM);
			else if( e < 0.625)
				sound(self, CHAN_WEAPON, "sounds/zombie/a4.wav", 1, ATTN_NORM);  
			else if( e < 0.75)
				sound(self, CHAN_WEAPON, "sounds/zombie/a5.wav", 1, ATTN_NORM);  
			else if( e < 0.875)
				sound(self, CHAN_WEAPON, "sounds/zombie/a6.wav", 1, ATTN_NORM); 
			else
				sound(self, CHAN_WEAPON, "sounds/zombie/a7.wav", 1, ATTN_NORM);   
			return;
		}
		if(what == 2)//walking!
		{
			
			if(self.s_time < time && self.s_time > 0)
			{
				sounds_playing --;
				self.s_time = 0;
			}
			if(sounds_playing >= 3)
			{
				return;
			}
			sounds_playing++;
			self.s_time = time + 1;
			
			
			if(self.sound_time < time)
			{
				play_sound_z(4);
				
				if(self.crawling == TRUE)
				{
					self.sound_time = time + 3 + random()*2;
					if(e < 0.2)
						sound(self, CHAN_VOICE, "sounds/zombie/t0.wav", 1, ATTN_NORM);   
					else if (e < 0.4)
						sound(self, CHAN_VOICE, "sounds/zombie/t1.wav", 1, ATTN_NORM);   
					else if (e < 0.6)
						sound(self, CHAN_VOICE, "sounds/zombie/t2.wav", 1, ATTN_NORM);   
					else if (e < 0.8)
						sound(self, CHAN_VOICE, "sounds/zombie/t3.wav", 1, ATTN_NORM);   
					else
						sound(self, CHAN_VOICE, "sounds/zombie/t4.wav", 1, ATTN_NORM);    
					return;
				}					
				if(self.walktype == 1 || self.walktype == 2 || self.walktype == 3)
				{
					self.sound_time = time + 3 + random();
					if (e < 0.1)
						sound(self, CHAN_VOICE, "sounds/zombie/w0.wav", 1, ATTN_NORM);    
					else if (e < 0.2)
						sound(self, CHAN_VOICE, "sounds/zombie/w1.wav", 1, ATTN_NORM);     
					else if (e < 0.3)
						sound(self, CHAN_VOICE, "sounds/zombie/w2.wav", 1, ATTN_NORM);      
					else if( e < 0.4)
						sound(self, CHAN_VOICE, "sounds/zombie/w3.wav", 1, ATTN_NORM);      
					else if( e < 0.5)
						sound(self, CHAN_VOICE, "sounds/zombie/w4.wav", 1, ATTN_NORM);       
					else if( e < 0.6)
						sound(self, CHAN_VOICE, "sounds/zombie/w5.wav", 1, ATTN_NORM);    
					else if( e < 0.7)
						sound(self, CHAN_VOICE, "sounds/zombie/w6.wav", 1, ATTN_NORM);    
					else if( e < 0.8)
						sound(self, CHAN_VOICE, "sounds/zombie/w7.wav", 1, ATTN_NORM);    
					else if( e < 0.9)
						sound(self, CHAN_VOICE, "sounds/zombie/w8.wav", 1, ATTN_NORM);    
					else
						sound(self, CHAN_VOICE, "sounds/zombie/w9.wav", 1, ATTN_NORM);    
					return;
				}
				else if(self.walktype == 4 || self.walktype == 5)
				{
					self.sound_time = time + 4 + random()*2;
					if (e < 0.1)
						sound(self, CHAN_VOICE, "sounds/zombie/r0.wav", 1, ATTN_NORM);     
					else if (e < 0.2)
						sound(self, CHAN_VOICE, "sounds/zombie/r1.wav", 1, ATTN_NORM);  
					else if (e < 0.3)
						sound(self, CHAN_VOICE, "sounds/zombie/r2.wav", 1, ATTN_NORM); 
					else if( e < 0.4)
						sound(self, CHAN_VOICE, "sounds/zombie/r3.wav", 1, ATTN_NORM);   
					else if( e < 0.5)
						sound(self, CHAN_VOICE, "sounds/zombie/r4.wav", 1, ATTN_NORM);    
					else if( e < 0.6)
						sound(self, CHAN_VOICE, "sounds/zombie/r5.wav", 1, ATTN_NORM); 
					else if( e < 0.7)
						sound(self, CHAN_VOICE, "sounds/zombie/r6.wav", 1, ATTN_NORM); 
					else if( e < 0.8)
						sound(self, CHAN_VOICE, "sounds/zombie/r7.wav", 1, ATTN_NORM); 
					else if( e < 0.9)
						sound(self, CHAN_VOICE, "sounds/zombie/r8.wav", 1, ATTN_NORM); 
					else
						sound(self, CHAN_VOICE, "sounds/zombie/r9.wav", 1, ATTN_NORM); 
					return;
				}
				
			}
		}
		if(what == 3)//death!
		{
			if (e < 0.125)
				sound(self, CHAN_BODY, "sounds/zombie/d0.wav", 1, ATTN_NORM); 
			else if (e < 0.25)
				sound(self, CHAN_BODY, "sounds/zombie/d1.wav", 1, ATTN_NORM); 
			else if (e < 0.375)
				sound(self, CHAN_BODY, "sounds/zombie/d2.wav", 1, ATTN_NORM);   
			else if( e < 0.5)
				sound(self, CHAN_BODY, "sounds/zombie/d3.wav", 1, ATTN_NORM);    
			else if( e < 0.625)
				sound(self, CHAN_BODY, "sounds/zombie/d4.wav", 1, ATTN_NORM);    
			else if( e < 0.75)
				sound(self, CHAN_BODY, "sounds/zombie/d5.wav", 1, ATTN_NORM); 
			else if( e < 0.875)
				sound(self, CHAN_BODY, "sounds/zombie/d6.wav", 1, ATTN_NORM);  
			else
				sound(self, CHAN_BODY, "sounds/zombie/d7.wav", 1, ATTN_NORM); 
			return;
			
		}
		if(what == 4)//Taunt!
		{
			if(random() < 0.83)
				return;
			
			if(e < 0.2)
				sound(self, CHAN_ITEM, "sounds/zombie/t0.wav", 1, ATTN_NORM);   
			else if (e < 0.4)
				sound(self, CHAN_ITEM, "sounds/zombie/t1.wav", 1, ATTN_NORM);  
			else if (e < 0.6)
				sound(self, CHAN_ITEM, "sounds/zombie/t2.wav", 1, ATTN_NORM);   
			else if (e < 0.8)
				sound(self, CHAN_ITEM, "sounds/zombie/t3.wav", 1, ATTN_NORM);  
			else
				sound(self, CHAN_ITEM, "sounds/zombie/t4.wav", 1, ATTN_NORM);    
			return;
		}
		if (what == 5) // Electric Zap
		{
			sound(self, CHAN_ITEM, "sounds/machines/elec_shock.wav", 1, ATTN_NORM);
		}
	}
};

void(__inout vector what, float howmuch) vector_scale_hack =
{
	what_x *= howmuch;
	what_y *= howmuch;
	what_z *= howmuch;
}

void(float which) SetZombieHitBox =
{

	//Zombie's bbox is constant across all hitbox setups, so we don't update it.
	
	if(self.currentHitBoxSetup == which)
		return;

	//which = IDLE_BBOX;
	
	switch(which)
	{
		case EMPTY_BBOX:
			self.head.view_ofs = '0 0 0';
			self.rarm.view_ofs = '0 0 0';
			self.larm.view_ofs = '0 0 0';
			break;
		case IDLE_BBOX: 
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '0 10 35';
		
			self.larm.bbmins = '-5 -5 -15';
			self.larm.bbmaxs  = '5 5 15';
			self.larm.view_ofs = '-10 10 10';
		
			self.rarm.bbmins = '-5 -5 -15';
			self.rarm.bbmaxs = '5 5 15';
			self.rarm.view_ofs = '10 10 10';
			break;
		case WALK1_BBOX:
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '2 -3 35';

			self.larm.bbmins = '-5 -7 -15';
			self.larm.bbmaxs = '5 7 15';
			self.larm.view_ofs = '-10 -4 15';

			self.rarm.bbmins = '-5 -8 -11';
			self.rarm.bbmaxs = '5 8 11';
			self.rarm.view_ofs = '10 11 11';
			break;
		case WALK2_BBOX:
			self.head.bbmins = '-7 -5 -5';
			self.head.bbmaxs = '7 5 5';
			self.head.view_ofs = '-11 6 36';

			self.larm.bbmins = '-5 -6 -15';
			self.larm.bbmaxs = '5 6 15';
			self.larm.view_ofs = '-14 3 15';
	
			self.rarm.bbmins = '-5 -5 -11';
			self.rarm.bbmaxs = '5 5 11';
			self.rarm.view_ofs = '4 13 11';
			break;
		case WALK3_BBOX:
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '-2 13 31';
	
			self.larm.bbmins = '-4 -6 -14';
			self.larm.bbmaxs = '4 6 14';
			self.larm.view_ofs = '-12 3 11';
	
			self.rarm.bbmins = '-5 -5 -11';
			self.rarm.bbmaxs = '5 5 11';
			self.rarm.view_ofs = '14 6 12';
			break;
		case JOG_BBOX:
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '0 5 36';
			
			self.larm.bbmins = '-5 -13 -5';
			self.larm.bbmaxs = '5 13 5';
			self.larm.view_ofs = '-8 19 24';
			
			self.rarm.bbmins = '-5 -13 -5';
			self.rarm.bbmaxs = '5 13 5';
			self.rarm.view_ofs = '10 19 24';
			break;
		case RUN_BBOX:
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '3 17 32';
	
			self.larm.bbmins = '-4 -10 -9';
			self.larm.bbmaxs = '4 10 9';
			self.larm.view_ofs = '-12 28 18';
			
			self.rarm.bbmins = '-4 -13 -10';
			self.rarm.bbmaxs = '4 13 10';
			self.rarm.view_ofs = '12 -2 19';
			break;
		case CRAWLER_BBOX:
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '2 18 -14';
	
			self.larm.bbmins = '-4 -10 -9';
			self.larm.bbmaxs = '4 10 9';
			self.larm.view_ofs = '-9 24 -27';
			
			self.rarm.bbmins = '-4 -13 -10';
			self.rarm.bbmaxs = '4 13 10';
			self.rarm.view_ofs = '12 15 -25';
			break;
		default:  //also known as BASE_BBOX
			self.head.bbmins = '-5 -5 -5';
			self.head.bbmaxs = '5 5 5';
			self.head.view_ofs = '0 0 35';
			
			self.larm.bbmins = '-5 -5 -15';
			self.larm.bbmaxs = '5 5 15';
			self.larm.view_ofs = '-10 0 5';
			
			self.rarm.bbmins = '-5 -5 -15';
			self.rarm.bbmaxs = '5 5 15';
			self.rarm.view_ofs = '10 0 5';
			break;
	}

	self.currentHitBoxSetup = which;

	if (map_compatibility_mode == MAP_COMPAT_BETA) {
		vector_scale_hack(self.head.bbmins, self.head.scale);
		vector_scale_hack(self.head.bbmaxs, self.head.scale);
		vector_scale_hack(self.head.view_ofs, self.head.scale);

		vector_scale_hack(self.larm.bbmins, self.larm.scale);
		vector_scale_hack(self.larm.bbmaxs, self.larm.scale);
		vector_scale_hack(self.larm.view_ofs, self.larm.scale);

		vector_scale_hack(self.rarm.bbmins, self.rarm.scale);
		vector_scale_hack(self.rarm.bbmaxs, self.rarm.scale);
		vector_scale_hack(self.rarm.view_ofs, self.rarm.scale);
	}
};

//
// Zombie_ProcessRespawn()
// Logic called by Zombie_Think for checking
// the last origin every second, for determining
// if a zombie is "stuck" inside and needs to re-spawn.
//
void() Zombie_ProcessRespawn =
{
	// Check once every 3 seconds
	if (self.respawn_timer < time && !self.outside) {
		// Check if the Zombie has barely moved (16qu)
		if (vlen(self.new_ofs - self.origin) <= 16) {
			// Continue to iterate
			self.respawn_iterator++;

			// 30 seconds have passed -- assume properly stuck, respawn.
			if (self.respawn_iterator >= 10) {
				self.respawn_iterator = 0;

				// Kill it.
				self.th_die();

				// This is a pseudo-hack that just tells the rounds core that we should
				// spawn another.
				Current_Zombies--;
				Remaining_Zombies++;
			}
		} else {
			// Set to zero -- Zombie is moving appropriately.
			self.respawn_iterator = 0;
		}

		// Iterate another 3 seconds.
		self.respawn_timer = time + 3;

		// Update our last origin
		self.new_ofs = self.origin;
	}
}

void() zombie_decide;
void() Zombie_Think = //called every frame for zombies
{
	if (self.onfire) {
		Effect_Fire(self.origin);

		if (self.ltime < time && self.onfire){
			DamageHandler(self, self.firer, 300, S_FLAME);
			self.ltime = time + 2;

			if (self.fire_timeout < time)
				self.onfire = false;
		}
	}

	Zombie_ProcessRespawn();

	// Electro-Shock Death
	if (self.death_timer < time && self.death_timer_activated == true) {
		self.th_die();
	}

	if (self.bleedingtime < time && !self.head.deadflag)
	{
		self.bleedingtime = time + 1;
		DamageHandler (self, self.usedent, z_health * 0.2, S_HEADSHOT);
	}

	// If we're mid attack and our enemy has moved out of range
	if (self.is_attacking && vlen(self.enemy.origin - self.origin) > 64) {
		// Cancel the animation, start walking again to catch up.
		self.is_attacking = false;

		// zombie_decide() here used to call an idle loop if they were
		// outside, lesson learned.
		if (!self.outside)
			self.th_walk();
	}
}

void() zombie_footstep
{
	if(self.laststep == 1)
	{
		self.laststep = 0;
		sound(self, 5, "sounds/zombie/s0.wav", 0.6, ATTN_NORM);
	}
	else
	{
		self.laststep = 1;
		sound(self, 5, "sounds/zombie/s1.wav", 0.6, ATTN_NORM);
	}
}

//////////////////////////////////////////////////////////////////////
//37-52
$frame walk1 walk2 walk3 walk4 walk5 walk6 walk7 walk8 walk9 walk10 walk11 walk12 walk13 walk14 walk15 walk16
//walk15
//walk 1!
void()	zombie_walk1		=[	$walk1,		zombie_walk2	] 	{self.nextthink = time + 0.12;Zombie_Walk(8);SetZombieHitBox(WALK1_BBOX);/*if(freeze_time < time)*/ self.frame = 37;Zombie_Think();};
void()	zombie_walk2		=[	$walk2,		zombie_walk3	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 38;Zombie_Think();};
void()	zombie_walk3		=[	$walk3,		zombie_walk4	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 39;Zombie_Think();};
void()	zombie_walk4		=[	$walk4,		zombie_walk5	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 40;Zombie_Think();};
void()	zombie_walk5		=[	$walk5,		zombie_walk6	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 41;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walk6		=[	$walk6,		zombie_walk7	] 	{self.nextthink = time + 0.12;Zombie_Walk(3.5); self.frame = 42;Zombie_Think();};
void()	zombie_walk7		=[	$walk7,		zombie_walk8	] 	{self.nextthink = time + 0.12;Zombie_Walk(8.8); self.frame = 43;Zombie_Think();};
void()	zombie_walk8		=[	$walk8,		zombie_walk9	] 	{self.nextthink = time + 0.12;Zombie_Walk(9); self.frame = 44;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walk9		=[	$walk9,		zombie_walk10	] 	{self.nextthink = time + 0.12;Zombie_Walk(4); self.frame = 45;Zombie_Think();};
void()	zombie_walk10		=[	$walk10,		zombie_walk11	] 	{self.nextthink = time + 0.12;Zombie_Walk(4); self.frame = 46;Zombie_Think();};
void()	zombie_walk11		=[	$walk11,		zombie_walk12	] 	{self.nextthink = time + 0.12;Zombie_Walk(7.8); self.frame = 47;Zombie_Think();};
void()	zombie_walk12		=[	$walk12,		zombie_walk13	] 	{self.nextthink = time + 0.12;Zombie_Walk(5.2); self.frame = 48;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walk13		=[	$walk13,		zombie_walk14	] 	{self.nextthink = time + 0.12;Zombie_Walk(2.4); self.frame = 49;Zombie_Think();};
void()	zombie_walk14		=[	$walk14,		zombie_walk15	] 	{self.nextthink = time + 0.12;Zombie_Walk(2.8); self.frame = 50;Zombie_Think();};
void()	zombie_walk15		=[	$walk15,		zombie_walk16	] 	{self.nextthink = time + 0.12;Zombie_Walk(6.5); self.frame = 51;Zombie_Think();};
void()	zombie_walk16		=[	$walk16,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.12;Zombie_Walk(7.7); self.frame = 52;Zombie_Think();zombie_footstep();};//footstep

/////////////////////////////////////////////////////////////////////////
//53-66
//Walk 2!
$frame bwalk1 bwalk2 bwalk3 bwalk4 bwalk5 bwalk6 bwalk7 bwalk8 bwalk9 bwalk10 bwalk11 bwalk12 bwalk13 bwalk14

void()	zombie_walkb1		=[	$bwalk1,		zombie_walkb2	] 	{self.nextthink = time + 0.13;Zombie_Walk(4.2);SetZombieHitBox(WALK2_BBOX);/*if(freeze_time < time)*/ self.frame = 53;Zombie_Think();};
void()	zombie_walkb2		=[	$bwalk2,		zombie_walkb3	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.9); self.frame = 54;Zombie_Think();};
void()	zombie_walkb3		=[	$bwalk3,		zombie_walkb4	] 	{self.nextthink = time + 0.13;Zombie_Walk(3); self.frame = 55;Zombie_Think();};
void()	zombie_walkb4		=[	$bwalk4,		zombie_walkb5	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.7); self.frame = 56;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkb5		=[	$bwalk5,		zombie_walkb6	] 	{self.nextthink = time + 0.13;Zombie_Walk(4.2); self.frame = 57;Zombie_Think();};
void()	zombie_walkb6		=[	$bwalk6,		zombie_walkb7	] 	{self.nextthink = time + 0.13;Zombie_Walk(7.2); self.frame = 58;Zombie_Think();};
void()	zombie_walkb7		=[	$bwalk7,		zombie_walkb8	] 	{self.nextthink = time + 0.13;Zombie_Walk(4.5); self.frame = 59;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkb8		=[	$bwalk8,		zombie_walkb9	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.4); self.frame = 60;Zombie_Think();};
void()	zombie_walkb9		=[	$bwalk9,		zombie_walkb10	] 	{self.nextthink = time + 0.13;Zombie_Walk(1.2); self.frame = 61;Zombie_Think();};
void()	zombie_walkb10		=[	$bwalk10,		zombie_walkb11	] 	{self.nextthink = time + 0.13;Zombie_Walk(6.7); self.frame = 62;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkb11		=[	$bwalk11,		zombie_walkb12	] 	{self.nextthink = time + 0.13;Zombie_Walk(8.4); self.frame = 63;Zombie_Think();};
void()	zombie_walkb12		=[	$bwalk12,		zombie_walkb13	] 	{self.nextthink = time + 0.13;Zombie_Walk(1.3); self.frame = 64;Zombie_Think();};
void()	zombie_walkb13		=[	$bwalk13,		zombie_walkb14	] 	{self.nextthink = time + 0.13;Zombie_Walk(6.3); self.frame = 65;Zombie_Think();};
void()	zombie_walkb14		=[	$bwalk14,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.6); self.frame = 66;Zombie_Think();zombie_footstep();};//footstep

/////////////////////////////////////////////////////////////////////////
//67-82
//Walk 3!
$frame cwalk1 cwalk2 cwalk3 cwalk4 cwalk5 cwalk6 cwalk7 cwalk8 cwalk9 cwalk10 cwalk11 cwalk12 cwalk13 cwalk14 cwalk15 cwalk16

void()	zombie_walkc1		=[	$cwalk1,		zombie_walkc2	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.4);SetZombieHitBox(WALK3_BBOX);/*if(freeze_time < time)*/ self.frame = 67;Zombie_Think();};
void()	zombie_walkc2		=[	$cwalk2,		zombie_walkc3	] 	{self.nextthink = time + 0.13;Zombie_Walk(2); self.frame = 68;Zombie_Think();};
void()	zombie_walkc3		=[	$cwalk3,		zombie_walkc4	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.4); self.frame = 69;Zombie_Think();};
void()	zombie_walkc4		=[	$cwalk4,		zombie_walkc5	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.6); self.frame = 70;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkc5		=[	$cwalk5,		zombie_walkc6	] 	{self.nextthink = time + 0.13;Zombie_Walk(3); self.frame = 71;Zombie_Think();};
void()	zombie_walkc6		=[	$cwalk6,		zombie_walkc7	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.1); self.frame = 72;Zombie_Think();};
void()	zombie_walkc7		=[	$cwalk7,		zombie_walkc8	] 	{self.nextthink = time + 0.13;Zombie_Walk(3); self.frame = 73;Zombie_Think();};
void()	zombie_walkc8		=[	$cwalk8,		zombie_walkc9	] 	{self.nextthink = time + 0.13;Zombie_Walk(2.9); self.frame = 74;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkc9		=[	$cwalk9,		zombie_walkc10	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.3); self.frame = 75;Zombie_Think();};
void()	zombie_walkc10		=[	$cwalk10,		zombie_walkc11	] 	{self.nextthink = time + 0.13;Zombie_Walk(2.2); self.frame = 76;Zombie_Think();};
void()	zombie_walkc11		=[	$cwalk11,		zombie_walkc12	] 	{self.nextthink = time + 0.13;Zombie_Walk(3.7); self.frame = 77;Zombie_Think();};
void()	zombie_walkc12		=[	$cwalk12,		zombie_walkc13	] 	{self.nextthink = time + 0.13;Zombie_Walk(4.2); self.frame = 78;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_walkc13		=[	$cwalk13,		zombie_walkc14	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.3); self.frame = 79;Zombie_Think();};
void()	zombie_walkc14		=[	$cwalk14,		zombie_walkc15	] 	{self.nextthink = time + 0.13;Zombie_Walk(5.2); self.frame = 80;Zombie_Think();};
void()	zombie_walkc15		=[	$cwalk15,		zombie_walkc16	] 	{self.nextthink = time + 0.13;Zombie_Walk(2.2); self.frame = 81;Zombie_Think();};
void()	zombie_walkc16		=[	$cwalk16,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.13;Zombie_Walk(2.4); self.frame = 82;Zombie_Think();zombie_footstep();};//footstep


/////////////////////////////////////////////////////////////////////
//116- 129
$frame jog1 jog2 jog3 jog4 jog5 jog6 jog7 jog8

void()	zombie_jog1		=[	$jog1,		zombie_jog2	] 	{self.nextthink = time + 0.08;Zombie_Walk(6);SetZombieHitBox(JOG_BBOX);/*if(freeze_time < time)*/ self.frame = 83;Zombie_Think();};//FOOTSTEP
void()	zombie_jog2		=[	$jog2,		zombie_jog3	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 84;Zombie_Think();};
void()	zombie_jog3		=[	$jog3,		zombie_jog4	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 85;Zombie_Think();};
void()	zombie_jog4		=[	$jog4,		zombie_jog5	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 86;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_jog5		=[	$jog5,		zombie_jog6	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 87;Zombie_Think();};
void()	zombie_jog6		=[	$jog6,		zombie_jog7	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 88;Zombie_Think();};
void()	zombie_jog7		=[	$jog7,		zombie_jog8	] 		{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 89;Zombie_Think();};
void()	zombie_jog8		=[	$jog8,		Zombie_Walk_Setup	] 	{self.nextthink = time + 0.08;Zombie_Walk(6); self.frame = 90;Zombie_Think();zombie_footstep();};//footstep

/////////////////////////////////////////////////////////////////////
//78-85
$frame run1 run2 run3 run4 run5 run6 run7 run8 run9 run10 
//12 unless 14
void()	zombie_run1		=[	$run1,		zombie_run2	] 	{Zombie_Walk(13);/*if(freeze_time < time)*/ self.frame = 92;SetZombieHitBox(RUN_BBOX);Zombie_Think();zombie_footstep();};//footstep
void()	zombie_run2		=[	$run2,		zombie_run3	] 	{Zombie_Walk(13);self.frame = 93;Zombie_Think();};
void()	zombie_run3		=[	$run3,		zombie_run4	] 	{Zombie_Walk(13); self.frame = 94;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_run4		=[	$run4,		zombie_run5	] 	{Zombie_Walk(13); self.frame = 95;Zombie_Think();};
void()	zombie_run5		=[	$run5,		zombie_run6	] 	{Zombie_Walk(13); self.frame = 96;Zombie_Think();};
void()	zombie_run6		=[	$run6,		zombie_run7	] 	{Zombie_Walk(13); self.frame = 97;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_run7		=[	$run7,		zombie_run8	] 	{Zombie_Walk(13); self.frame = 98;Zombie_Think();};
void()	zombie_run8		=[	$run8,		zombie_run9	] 	{Zombie_Walk(13); self.frame = 99;Zombie_Think();zombie_footstep();};//footstep
void()	zombie_run9		=[	$run9,		zombie_run10	] 	{Zombie_Walk(13); self.frame = 100;Zombie_Think();};
void()	zombie_run10		=[	$run10,	Zombie_Walk_Setup	] 	{Zombie_Walk(13); self.frame = 101;Zombie_Think();};

void() Zombie_Walk_Setup = 
{
	if(Remaining_Zombies == 1 && rounds >= 4)
	{
		self.walktype = 5;
	}
	
	if(self.walktype == 1)
	{
		zombie_walk1();
	}
	
	else if(self.walktype == 2)
	{
		zombie_walkb1();
	}
	
	else if(self.walktype == 3)
	{
		zombie_walkc1();
	}
	
	else if(self.walktype == 4)
	{
		zombie_jog1();
	}
	else if(self.walktype == 5)
	{
		zombie_run1();
	}
};
///////////////////////////////////////////////////////////////////// ZOMBIE IDLE 1
//0-12
$frame idle1 idle2 idle3 idle4 idle5 idle6 idle7 idle8 idle9 idle10 idle11 idle12 idle13 idle14
void() zombie_idle		=[	$idle1, 		zombie_idle1	]		{Zombie_Walk(0);self.frame = 0;SetZombieHitBox(IDLE_BBOX);Zombie_Think();};
void() zombie_idle1		=[	$idle2, 		zombie_idle2	]		{Zombie_Walk(0);self.frame = 1;Zombie_Think();};
void() zombie_idle2		=[	$idle3, 		zombie_idle3	]		{Zombie_Walk(0);self.frame = 2;Zombie_Think();};
void() zombie_idle3		=[	$idle4, 		zombie_idle4	]		{Zombie_Walk(0);self.frame = 3;Zombie_Think();};
void() zombie_idle4		=[	$idle5, 		zombie_idle5	]		{Zombie_Walk(0);self.frame = 4;Zombie_Think();};
void() zombie_idle5		=[	$idle6, 		zombie_idle6	]		{Zombie_Walk(0);self.frame = 5;Zombie_Think();};
void() zombie_idle6		=[	$idle7, 		zombie_idle7	]		{Zombie_Walk(0);self.frame = 6;Zombie_Think();};
void() zombie_idle7		=[	$idle8, 		zombie_idle8	]		{Zombie_Walk(0);self.frame = 7;Zombie_Think();};
void() zombie_idle8		=[	$idle9, 		zombie_idle9	]		{Zombie_Walk(0);self.frame = 8;Zombie_Think();};
void() zombie_idle9		=[	$idle10, 		zombie_idle10	]		{Zombie_Walk(0);self.frame = 9;Zombie_Think();};
void() zombie_idle10		=[	$idle12, 		zombie_idle11	]		{Zombie_Walk(0);self.frame = 10;Zombie_Think();};
void() zombie_idle11		=[	$idle13, 		zombie_idle12	]		{Zombie_Walk(0);self.frame = 11;Zombie_Think();};
void() zombie_idle12		=[	$idle14, 		zombie_idle1	]		{Zombie_Walk(0);self.frame = 12;Zombie_Think();};

void() zombie_decide = 
{
	if(self.outside == TRUE)
	{
		self.th_idle();
	}
	else
	{
		self.th_walk();
	}
};
/////////////////////////////////////////////////////////

void() Window_Damage;
void() Window_Damage_Setup =
{
	local entity old_self;
	old_self = self;
	self = self.goalentity;
	Window_Damage();
	self = old_self;
};
void() zombie_attack2 =
{
	if(self.outside == TRUE)
	{
		if(self.goalentity.classname == "window")
		{
			if(self.enemy.classname != "window")
			{
				self.enemy = self.goalentity;
			}
		}
	}
	
	if(self.goalentity.classname == "window")
	{
		Window_Damage_Setup();
	}
	// motolegacy -- Prohibit damage to the Player if the Nuke Power-Up logic is currently
	// running.
	else if (self.enemy.classname == "player" && nuke_powerup_active == false)
	{
		if(vlen(self.enemy.origin - self.origin) < 64)
		{
			if (self.classname == "ai_dog")
				DamageHandler (self.enemy, self, 40, S_ZOMBIE);
			else
				DamageHandler (self.enemy, self, 50, S_ZOMBIE);
		}
	}
	else return;
};

//////////////////////////////WINDOW HOPPING
//113-122
void(float pushaway) moveforwardalittle =
{
	makevectors(self.angles);
	local float amount;
	amount = 4.35;//was 8.7, but running twice as much so...
	if(self.crawling == TRUE)
		amount = 2.33;
	
	self.origin = self.origin + (v_forward * amount);
	setorigin(self, self.origin);
	self.zoom = 1;
	
	if(pushaway == 1)
	{
		local entity ent;
		ent = findradius(self.origin,50);
		while(ent)
		{
			if(ent.classname == "player" && !ent.downed)
			{
				ent.velocity = ent.velocity + (v_forward * 250);
			}
			ent = ent.chain;
		}
	}
};

$frame hop1 hop2 hop3 hop4 hop5 hop6 hop7 hop8 hop9 hop10
void() zombie_hop1	=[	$hop1,	zombie_hop1_5	] {self.movetype = self.head.movetype = MOVETYPE_STEP;self.frame = self.head.frame = 113;self.nextthink = time + 0.05;moveforwardalittle(1); self.state = 1;Zombie_Think();};
void() zombie_hop1_5	=[	$hop1,	zombie_hop2	] {self.frame = self.head.frame = 113;self.nextthink = time + 0.05;moveforwardalittle(0); };
void() zombie_hop2	=[	$hop2,	zombie_hop2_5	] {self.frame = self.head.frame = 114;self.nextthink = time + 0.05;moveforwardalittle(1);Zombie_Think();};	
void() zombie_hop2_5	=[	$hop2,	zombie_hop3	] {self.frame = self.head.frame = 114;self.nextthink = time+0.05;moveforwardalittle(0);};	
void() zombie_hop3	=[	$hop3,	zombie_hop3_5	] {self.frame = self.head.frame = 115;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop3_5	=[	$hop3,	zombie_hop4	] {self.frame = self.head.frame = 115;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop4	=[	$hop4,	zombie_hop4_5	] {self.frame = self.head.frame = 116;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop4_5	=[	$hop4,	zombie_hop5	] {self.frame = self.head.frame = 116;self.nextthink = time+0.05;moveforwardalittle(1);};
void() zombie_hop5	=[	$hop5,	zombie_hop5_5	] {self.frame = self.head.frame = 117;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop5_5	=[	$hop5,	zombie_hop6	] {self.frame = self.head.frame = 117;self.nextthink = time+0.05;moveforwardalittle(1);};
void() zombie_hop6	=[	$hop6,	zombie_hop6_5	] {self.frame = self.head.frame = 118;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop6_5	=[	$hop6,	zombie_hop7	] {self.frame = self.head.frame = 118;self.nextthink = time+0.05;moveforwardalittle(1);};
void() zombie_hop7	=[	$hop7,	zombie_hop7_5	] {self.frame = self.head.frame = 119;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop7_5	=[	$hop7,	zombie_hop8	] {self.frame = self.head.frame = 119;self.nextthink = time+0.05;moveforwardalittle(1);};
void() zombie_hop8	=[	$hop8,	zombie_hop8_5	] {self.frame = self.head.frame = 120;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();zombie_footstep();};
void() zombie_hop8_5	=[	$hop8,	zombie_hop9	] {self.frame = self.head.frame = 120;self.nextthink = time+0.05;moveforwardalittle(1);};
void() zombie_hop9	=[	$hop9,	zombie_hop9_5	] {self.frame = self.head.frame = 121;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop9_5	=[	$hop9,	zombie_hop10	] {self.frame = self.head.frame = 121;self.nextthink = time+0.05;moveforwardalittle(0);};
void() zombie_hop10	=[	$hop10,	zombie_hop10_5	] {self.frame = self.head.frame = 122;self.nextthink = time+0.05;moveforwardalittle(1);Zombie_Think();};
void() zombie_hop10_5=[	$hop10,	SUB_Null		] {self.frame = self.head.frame = 122;	
															self.oldorigin = self.origin = self.goalentity.hop_spot;
															setorigin(self, self.origin); 
															self.state = 0;
															self.hop_step = 6;
															if(self.crawling == 2) 
															{
																makeCrawler(self); 
																//return;
															}
															self.movetype = MOVETYPE_WALK;
															self.th_walk();
														};

//ripboard1
//181-191
$frame zrip1 zrip2 zrip3 zrip4 zrip5 zrip6 zrip7 zrip8 zrip9 zrip10 zrip11
void() zombie_ripboardA1			=[	$zrip1,		zombie_ripboardA2		]	{self.frame = 181;SetZombieHitBox(IDLE_BBOX);Zombie_Think();};
void() zombie_ripboardA2			=[	$zrip2,		zombie_ripboardA3		]	{self.frame = 182;Zombie_Think();};
void() zombie_ripboardA3			=[	$zrip3,		zombie_ripboardA4		]	{self.frame = 183;Zombie_Think();};
void() zombie_ripboardA4			=[	$zrip4,		zombie_ripboardA5		]	{self.frame = 184;Zombie_Think();};
void() zombie_ripboardA5			=[	$zrip5,		zombie_ripboardA6		]	{self.frame = 185;Zombie_Think();};
void() zombie_ripboardA6			=[	$zrip6,		zombie_ripboardA7		]	{self.frame = 186;Zombie_Think();};
void() zombie_ripboardA7			=[	$zrip7,		zombie_ripboardA8		]	{self.frame = 187;zombie_attack2();Zombie_Think();};
void() zombie_ripboardA8			=[	$zrip8,		zombie_ripboardA9		]	{self.frame = 188;Zombie_Think();};
void() zombie_ripboardA9			=[	$zrip9,		zombie_ripboardA10		]	{self.frame = 189;Zombie_Think();};
void() zombie_ripboardA10			=[	$zrip10,		zombie_ripboardA11		]	{self.frame = 190;Zombie_Think();};
void() zombie_ripboardA11			=[	$zrip11,		zombie_decide		]	{self.frame = 191;Zombie_Think();};
/////////////////////////////////////////////////////////
//ripboard2
//192-201
$frame zripB1 zripB2 zripB3 zripB4 zripB5 zripB6 zripB7 zripB8 zripB9 zripB10 zripB11
void() zombie_ripboardB1			=[	$zripB1,		zombie_ripboardB2		]	{self.frame = 192;SetZombieHitBox(IDLE_BBOX);Zombie_Think();};
void() zombie_ripboardB2			=[	$zripB2,		zombie_ripboardB3		]	{self.frame = 193;Zombie_Think();};
void() zombie_ripboardB3			=[	$zripB3,		zombie_ripboardB4		]	{self.frame = 194;Zombie_Think();};
void() zombie_ripboardB4			=[	$zripB4,		zombie_ripboardB5		]	{self.frame = 195;Zombie_Think();};
void() zombie_ripboardB5			=[	$zripB5,		zombie_ripboardB6		]	{self.frame = 196;Zombie_Think();};
void() zombie_ripboardB6			=[	$zripB6,		zombie_ripboardB7		]	{self.frame = 197;zombie_attack2();Zombie_Think();};
void() zombie_ripboardB7			=[	$zripB7,		zombie_ripboardB8		]	{self.frame = 198;Zombie_Think();};
void() zombie_ripboardB8			=[	$zripB8,		zombie_ripboardB9		]	{self.frame = 199;Zombie_Think();};
void() zombie_ripboardB9			=[	$zripB9,		zombie_ripboardB10		]	{self.frame = 200;Zombie_Think();};
void() zombie_ripboardB10			=[	$zripB10,		zombie_decide		]	{self.frame = 201;Zombie_Think();};
/////////////////////////////////////////////////////////
//attack through window
//180-181
//181-185
//186-188
void() zombie_attack_through_window =
{
	play_sound_z(1);
	local entity who;
	who = findradius(self.origin, 70);
	while(who)
	{
		if(who.classname == "player")
		{
			DamageHandler (who, self, ZOMBIE_DAMAGE_THROUGH_WINDOW, S_ZOMBIE);
		}
		who = who.chain;
	}
};
//202-210

//
// Zombie Attacks
//
void() zombie_attack2;

$frame zatkw1 zatkw2 zatkw3 zatkw4 zatkw5 zatkw6 zatkw7 zatkw8 zatkw9
void() zombie_attack_through_w1		=[	$zatkw1,		zombie_attack_through_w2		]	{self.is_attacking = true; self.frame = 202;SetZombieHitBox(IDLE_BBOX);Zombie_Think();};//START

void() zombie_attack_through_w2		=[	$zatkw2,		zombie_attack_through_w3		]	{self.frame = 203;zombie_attack_through_window();Zombie_Think();};//SWINGING
void() zombie_attack_through_w3		=[	$zatkw3,		zombie_attack_through_w4		]	{self.frame = 204;Zombie_Think();};//SWINGING
void() zombie_attack_through_w4		=[	$zatkw4,		zombie_attack_through_w5		]	{self.frame = 205;Zombie_Think();};//SWINGING
void() zombie_attack_through_w5		=[	$zatkw5,		zombie_attack_through_w6		]	{self.frame = 206;Zombie_Think();};//SWINGING
void() zombie_attack_through_w6		=[	$zatkw6,		zombie_attack_through_w7		]	{self.frame = 207;Zombie_Think();};//SWINGING

void() zombie_attack_through_w7		=[	$zatkw2,		zombie_attack_through_w8		]	{self.frame = 203;Zombie_Think();};//SWINGING
void() zombie_attack_through_w8		=[	$zatkw3,		zombie_attack_through_w9		]	{self.frame = 204;Zombie_Think();};//SWINGING
void() zombie_attack_through_w9		=[	$zatkw4,		zombie_attack_through_w10		]	{self.frame = 205;Zombie_Think();};//SWINGING
void() zombie_attack_through_w10		=[	$zatkw5,		zombie_attack_through_w11		]	{self.frame = 206;Zombie_Think();};//SWINGING
void() zombie_attack_through_w11		=[	$zatkw6,		zombie_attack_through_w12		]	{self.frame = 207;Zombie_Think();};//SWINGING

void() zombie_attack_through_w12		=[	$zatkw2,		zombie_attack_through_w13		]	{self.frame = 203;Zombie_Think();};//SWINGING
void() zombie_attack_through_w13		=[	$zatkw3,		zombie_attack_through_w14		]	{self.frame = 204;Zombie_Think();};//SWINGING
void() zombie_attack_through_w14		=[	$zatkw4,		zombie_attack_through_w15		]	{self.frame = 205;Zombie_Think();};//SWINGING
void() zombie_attack_through_w15		=[	$zatkw5,		zombie_attack_through_w16		]	{self.frame = 206;zombie_attack_through_window();Zombie_Think();};//SWINGING
void() zombie_attack_through_w16		=[	$zatkw6,		zombie_attack_through_w17		]	{self.frame = 207;Zombie_Think();};//SWINGING

void() zombie_attack_through_w17		=[	$zatkw7,		zombie_attack_through_w18		]	{self.frame = 208;Zombie_Think();};//ENDING
void() zombie_attack_through_w18		=[	$zatkw8,		zombie_attack_through_w19		]	{self.frame = 209;Zombie_Think();};//ENDING
void() zombie_attack_through_w19		=[	$zatkw9,		zombie_decide		]	{self.is_attacking = false; self.frame = 210;Zombie_Think();};//ENDING

void() zm_swipe_right_slow	=[	1, 	zm_swipe_right_slow1	]	{self.is_attacking = true; self.frame = 102; SetZombieHitBox(BASE_BBOX); Zombie_Think(); };
void() zm_swipe_right_slow1	=[	2, 	zm_swipe_right_slow2	]	{self.frame = 103; Zombie_Think(); };
void() zm_swipe_right_slow2	=[	3, 	zm_swipe_right_slow3	]	{self.frame = 104; Zombie_Think(); };
void() zm_swipe_right_slow3	=[	4, 	zm_swipe_right_slow4	]	{zombie_attack2(); self.frame = 105; Zombie_Think(); };
void() zm_swipe_right_slow4	=[	5, 	zombie_decide			]	{self.is_attacking = false; self.frame = 106; Zombie_Think(); };

void() zm_swipe_right_fast	=[	1, 	zm_swipe_right_fast1	]	{self.is_attacking = true; self.frame = 104; Zombie_Think(); };
void() zm_swipe_right_fast1	=[	2, 	zm_swipe_right_fast2	]	{zombie_attack2(); self.frame = 105; Zombie_Think(); };
void() zm_swipe_right_fast2	=[	3, 	zombie_decide			]	{self.is_attacking = false; self.frame = 106; Zombie_Think(); };

void() zm_swipe_left_slow	=[	1, 	zm_swipe_left_slow1		]	{self.is_attacking = true; self.frame = 107; SetZombieHitBox(BASE_BBOX); Zombie_Think(); };
void() zm_swipe_left_slow1	=[	2, 	zm_swipe_left_slow2		]	{self.frame = 108; Zombie_Think(); };
void() zm_swipe_left_slow2	=[	3, 	zm_swipe_left_slow3		]	{self.frame = 109; Zombie_Think(); };
void() zm_swipe_left_slow3	=[	4, 	zm_swipe_left_slow4		]	{zombie_attack2(); self.frame = 110; Zombie_Think(); };
void() zm_swipe_left_slow4	=[	5, 	zm_swipe_left_slow5		]	{self.frame = 111; Zombie_Think(); };
void() zm_swipe_left_slow5	=[	6, 	zombie_decide			]	{self.is_attacking = false; self.frame = 112; Zombie_Think(); };

void() zm_swipe_left_fast	=[	1, 	zm_swipe_left_fast1		]	{self.is_attacking = true; self.frame = 109; SetZombieHitBox(BASE_BBOX); Zombie_Think(); };
void() zm_swipe_left_fast1	=[	2, 	zm_swipe_left_fast2		]	{zombie_attack2(); self.frame = 110; Zombie_Think(); };
void() zm_swipe_left_fast2	=[	3, 	zm_swipe_left_fast3		]	{self.frame = 111; Zombie_Think(); };
void() zm_swipe_left_fast3	=[	4, 	zombie_decide			]	{self.is_attacking = false; self.frame = 112; Zombie_Think(); };

void() zm_swipe_both_slow	=[	1, 	zm_swipe_both_slow1		]	{self.is_attacking = true; self.frame = 102; SetZombieHitBox(BASE_BBOX); Zombie_Think(); };
void() zm_swipe_both_slow1	=[	2, 	zm_swipe_both_slow2		]	{self.frame = 103; Zombie_Think(); };
void() zm_swipe_both_slow2	=[	3, 	zm_swipe_both_slow3		]	{self.frame = 104; Zombie_Think(); };
void() zm_swipe_both_slow3	=[	4, 	zm_swipe_both_slow4		]	{zombie_attack2(); self.frame = 105; Zombie_Think(); };
void() zm_swipe_both_slow4	=[	5, 	zm_swipe_both_slow5		]	{self.frame = 106; Zombie_Think(); };
void() zm_swipe_both_slow5	=[	6, 	zm_swipe_both_slow6		]	{self.frame = 107; Zombie_Think(); };
void() zm_swipe_both_slow6	=[	7, 	zm_swipe_both_slow7		]	{self.frame = 108; Zombie_Think(); };
void() zm_swipe_both_slow7	=[	8, 	zm_swipe_both_slow8		]	{self.frame = 109; Zombie_Think(); };
void() zm_swipe_both_slow8	=[	9, 	zm_swipe_both_slow9		]	{self.frame = 110; Zombie_Think(); };
void() zm_swipe_both_slow9	=[	10, zombie_decide			]	{zombie_attack2(); self.is_attacking = false; self.frame = 111; Zombie_Think(); };

void() zm_swipe_both_fast	=[	1, 	zm_swipe_both_fast1		]	{self.is_attacking = true; self.frame = 104; SetZombieHitBox(BASE_BBOX); Zombie_Think(); };
void() zm_swipe_both_fast1	=[	2, 	zm_swipe_both_fast2		]	{zombie_attack2(); self.frame = 105; Zombie_Think(); };
void() zm_swipe_both_fast2	=[	3, 	zm_swipe_both_fast3		]	{self.frame = 106; Zombie_Think(); };
void() zm_swipe_both_fast3	=[	4, 	zm_swipe_both_fast4		]	{self.frame = 109; Zombie_Think(); };
void() zm_swipe_both_fast4	=[	5, 	zm_swipe_both_fast5		]	{self.frame = 110; Zombie_Think(); };
void() zm_swipe_both_fast5	=[	6, 	zm_swipe_both_fast6		]	{self.frame = 111; Zombie_Think(); };
void() zm_swipe_both_fast6	=[	7, 	zombie_decide			]	{zombie_attack2(); self.is_attacking = false; self.frame = 112; Zombie_Think(); };

void(float which) zombie_attack_choose =
{
	
	self.angles_y = vectoyaw(self.enemy.origin - self.origin);
	
	if(which != 1)
	{
		if(random() > 0.4)
		{
			return;
		}
	}
	
	play_sound_z(1);

	//
	// choose what attack to play
	//

	// cypress -- we used to do a really cool thing here where
	// zombies could only attack with an arm they had, but this
	// became problematic for repetitive animations + it really
	// made double-swiping stand out :( maybe one day we could
	// have this back!

	float attack_type = random();
	float attack_is_slow = (random() < 0.5); // :^)

	// Right Arm
	if (attack_type < 0.33) {
		// Slow
		if (attack_is_slow)
			zm_swipe_right_slow();
		// Fast
		else
			zm_swipe_right_fast();
	}
	// Left Arm
	else if (attack_type < 0.66) {
		// Slow
		if (attack_is_slow)
			zm_swipe_left_slow();
		// Fast
		else
			zm_swipe_left_fast();
	}
	// Both (right, followed by left arm)
	else {
		// Slow
		if (attack_is_slow)
			zm_swipe_both_slow();
		// Fast
		else
			zm_swipe_both_fast();
	}
};

$frame zda1 zda2 zda3 zda4 zda5 zda6 zda7 zda8 zda9 zda10 zda11 zda12 zda13 zda14
void() zombie_zda		=[	$zda1, 		zombie_zda1	]		{self.frame = 0;zombie_attack_choose(0);SetZombieHitBox(IDLE_BBOX);Zombie_Think();};
void() zombie_zda1		=[	$zda2, 		zombie_zda2	]		{self.frame = 1;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda2		=[	$zda3, 		zombie_zda3	]		{self.frame = 2;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda3		=[	$zda4, 		zombie_zda4	]		{self.frame = 3;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda4		=[	$zda5, 		zombie_zda5	]		{self.frame = 4;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda5		=[	$zda6, 		zombie_zda6	]		{self.frame = 5;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda6		=[	$zda7, 		zombie_zda7	]		{self.frame = 6;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda7		=[	$zda8, 		zombie_zda8	]		{self.frame = 7;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda8		=[	$zda9, 		zombie_zda9	]		{self.frame = 8;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda9		=[	$zda10, 		zombie_zda10	]		{self.frame = 9;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda10		=[	$zda12, 		zombie_zda11	]		{self.frame = 10;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda11		=[	$zda13, 		zombie_zda12	]		{self.frame = 11;zombie_attack_choose(0);Zombie_Think();};
void() zombie_zda12		=[	$zda14, 		zombie_zda1	]		{self.frame = 12;zombie_attack_choose(1);Zombie_Think();};

void() zombie_attack =
{
	self.velocity = '0 0 0';

    if(self.state == 1) // If the zombie is in this state (rising, or something else) they shouldn't be able to attack!
        return;

	if (self.electro_targeted == true)
		return;

	if(self.outside == TRUE)
	{
		self.angles_y = self.goalentity.angles_y;
	}
	else
	{
		self.angles_y = vectoyaw(self.enemy.origin - self.origin);
	}
		
	
	if(self.crawling == TRUE)
	{
		if(self.outside == TRUE)
			crawler_rip_board1();
		else
			crawler_da1();//crawler delay attack
	}
	else
	{
		//zombie_attack_through_w1();
		
		if(self.outside == TRUE)
		{
			if(random() < 0.30)
			{
				local entity who;
				local float found;
				found = 0;
				who = findradius(self.origin, 70);
				while (who != world && found == false)
				{
					if(who.classname == "player")
					{
						found = true;
					}
					else
						who = who.chain;
				}
				if (found == true)
				{
					zombie_attack_through_w1();
					return;
				}
			}
			
			if(random() < 0.5)
				zombie_ripboardA1();
			else
				zombie_ripboardB1();
		}
		else
		{
			zombie_zda();//Zombie Delay Attack
		}
	}
	
};

//==========================Falling Code==========================
void CheckLand() =
{
	if ((self.flags & FL_ONGROUND))
	{
		if (self.fall == TRUE)
		{
			self.fall = FALSE;
			self.th_land();
		}
	}
};

//Falling
//149-152
$frame fall1 fall2 fall3 fall4

void() zombie_fall1		=[	$fall1,		zombie_fall2	]	{self.frame = 149;SetZombieHitBox(BASE_BBOX);self.fall = TRUE;CheckLand();Zombie_Think();};
void() zombie_fall2		=[	$fall2,		zombie_fall3	]	{self.frame = 150;CheckLand();Zombie_Think();};
void() zombie_fall3		=[	$fall3,		zombie_fall4	]	{self.frame = 151;CheckLand();Zombie_Think();};
void() zombie_fall4		=[	$fall4,		zombie_fall3	]	{self.frame = 152;CheckLand();Zombie_Think();};

//Landing
//153-159
$frame land1 land2 land3 land4 land5 land6 land7
void() zombie_land1		=[	$land1,		zombie_land2	]	{self.frame = 153;SetZombieHitBox(BASE_BBOX);Zombie_Think();zombie_footstep();zombie_footstep();};
void() zombie_land2		=[	$land2,		zombie_land3	]	{self.frame = 154;Zombie_Think();};
void() zombie_land3		=[	$land3,		zombie_land4	]	{self.frame = 155;Zombie_Think();};
void() zombie_land4		=[	$land4,		zombie_land5	]	{self.frame = 156;Zombie_Think();};
void() zombie_land5		=[	$land5,		zombie_land6	]	{self.frame = 157;Zombie_Think();};
void() zombie_land6		=[	$land6,		zombie_land7	]	{self.frame = 158;Zombie_Think();};
void() zombie_land7		=[	$land7,		Zombie_Walk_Setup	]	{self.frame = 159;Zombie_Think();};

void() removeZombie =
{
	self.aistatus = "0";
	setmodel(self,"");

	// Hounds don't gib.
	if (self.classname != "ai_dog") {
		setmodel(self.larm,"");
		setmodel(self.rarm,"");
		setmodel(self.head,"");

#ifdef FTE

		remove(self.larm);
		remove(self.rarm);
		remove(self.head);

#else

		updateLimb (self, 0, world);
		updateLimb (self, 1, world);
		updateLimb (self, 2, world);

#endif // FTE

	}
	
	setorigin(self,'0 0 0');
	setorigin (self.goaldummy, '0 0 0');
	
	// cypress (20 dec 2023) -- added a nextthink() call here
	// so the next server frame we'll have always run SUB_Null().
	// there was some weird behavior here where a zombie's th_idle()
	// call would carry forward interrupting the procedure for walking
	// to a barricade.
	self.nextthink = time + 0.05;
	self.think = SUB_Null;
	self.classname = "freeZombieEntity";
	self.goalentity = world;
	self.enemy = world;
	self.solid = 0;
	self.movetype = 0;

	self.outside = TRUE;
	self.hop_step = 0;
	self.onfire = false;
	self.fire_timeout = 0;
	self.calc_time = 0;
	self.tries = 0;
	self.takedamage = DAMAGE_NO;
	self.flags = 0;
	self.crawling = 0;
	self.bleedingtime = 0;
	self.iszomb = 0; // 1 for alive AI, 0 for corpses / unallocated reserevd ents
	self.owner = world;

	self.spawnflags = 0;
	self.is_attacking = false;
	
	self.yaw_speed = 0;
	
	self.health = 0;
	self.th_die = SUB_Null;
	self.th_walk = SUB_Null;
	self.th_melee = SUB_Null;
	self.th_idle = SUB_Null;
	self.th_windowhop = SUB_Null;
	
	self.th_fall = SUB_Null;
	self.th_falling = SUB_Null;
	self.th_land = SUB_Null;
	
	self.th_jump = SUB_Null;
	self.th_grabledge = SUB_Null;
	self.th_diewunder = SUB_Null;
	//Disabling collision bboxes
	SetZombieHitBox(EMPTY_BBOX);
};

///////////////////////////////////////////////////////////////////// ZOMBIE DEATH 1
//123-133
$frame death1 death2 death3 death4 death5 death6 death7 death8 death9 death10 death11
void()	zombie_deathA1		=[	$death1,		zombie_death2	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.frame = 123;};
void()	zombie_death2		=[	$death2,		zombie_death3	] 	{self.frame = 124;};
void()	zombie_death3		=[	$death3,		zombie_death4	] 	{self.frame = 125;};
void()	zombie_death4		=[	$death4,		zombie_death5	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.frame = 126;};
void()	zombie_death5		=[	$death5,		zombie_death6	] 	{self.frame = 127;};
void()	zombie_death6		=[	$death6,		zombie_death7	] 	{self.frame = 128;};
void()	zombie_death7		=[	$death7,		zombie_death8	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.frame = 129;};
void()	zombie_death8		=[	$death8,		zombie_death9	] 	{self.frame = 130;};
void()	zombie_death9		=[	$death9,		zombie_death10	] 	{self.frame = 131;};
void()	zombie_death10		=[	$death10,		zombie_death11	] 	{self.frame = 132;zombie_footstep();};
void()	zombie_death11		=[	$death11,		SUB_Null	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.iszomb = 0; self.nextthink = time + 3; self.think = removeZombie;  self.frame = 133;};

//////////////////////////////////////////////////////////////////////////////////// ZOMBIE DEATH 2
//134-138
$frame deathB1 deathB2 deathB3 deathB4 deathB5

void()	zombie_deathB1		=[	$deathB1,		zombie_deathB2	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.frame = 134;};
void()	zombie_deathB2		=[	$deathB2,		zombie_deathB3	] 	{self.frame = 135;};
void()	zombie_deathB3		=[	$deathB3,		zombie_deathB4	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.frame = 136;};
void()	zombie_deathB4		=[	$deathB4,		zombie_deathB5	] 	{self.frame = 137;zombie_footstep();};
void()	zombie_deathB5		=[	$deathB5,		SUB_Null		] 	{if (self.onfire) {Effect_Fire(self.origin);} self.iszomb = 0; self.nextthink = time + 3; self.think = removeZombie; self.frame = 138;};


//////////////////////////////////////////////////////////////////////////////////// ZOMBIE DEATH 3
//139-148

$frame deathC1 deathC2 deathC3 deathC4 deathC5 deathC6 deathC7 deathC8 deathC9 deathC10

void()	zombie_deathC1		=[	$deathC1,		zombie_deathC2	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.frame = 139;};
void()	zombie_deathC2		=[	$deathC2,		zombie_deathC3	] 	{self.frame = 140;};
void()	zombie_deathC3		=[	$deathC3,		zombie_deathC4	] 	{self.frame = 141;};
void()	zombie_deathC4		=[	$deathC4,		zombie_deathC5	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.frame = 142;};
void()	zombie_deathC5		=[	$deathC5,		zombie_deathC6	] 	{self.frame = 143;};
void()	zombie_deathC6		=[	$deathC6,		zombie_deathC7	] 	{self.frame = 144;};
void()	zombie_deathC7		=[	$deathC7,		zombie_deathC8	] 	{if (self.onfire) {Effect_Fire(self.origin);} self.frame = 145;};
void()	zombie_deathC8		=[	$deathC8,		zombie_deathC9	] 	{self.frame = 146;zombie_footstep();};
void()	zombie_deathC9		=[	$deathC9,		zombie_deathC10	] 	{self.frame = 147;};
void()	zombie_deathC10		=[	$deathC10,		SUB_Null		] 	{if (self.onfire) {Effect_Fire(self.origin);} self.iszomb = 0; self.nextthink = time + 3; self.think = removeZombie; self.frame = 148;};



void(entity ent) Zombie_Death_Cleanup = {
	// Already dead
	if(ent.aistatus == "0") {
		return;
	}

	// Insta-Kill should always cause the head to gib on Zombie death.
	if (ent.head && instakill_finished > time) {
		makevectors(ent.head.owner.angles);
 		vector where = ent.origin + (ent.head.view_ofs_x * v_right) + (ent.head.view_ofs_y * v_forward) + (ent.head.view_ofs_z * v_up);
 		spawn_gibs(where);
 		ent.head.deadflag = false;
		ent.head.solid = SOLID_NOT;
		setmodel(ent.head, "");
		ent.head.frame = 0;

#ifndef FTE

		updateLimb (ent, 0, world);

#endif // FTE

	} 

	ent.aistatus = "0";
	ent.solid = SOLID_NOT;
	ent.movetype = MOVETYPE_NONE;
	ent.takedamage = DAMAGE_NO;
	
	ent.head.classname = "";
	ent.head.solid = SOLID_NOT;
	ent.head.movetype = MOVETYPE_NONE;
	ent.head.takedamage = DAMAGE_NO;
	ent.larm.solid = SOLID_NOT;
	ent.larm.movetype = MOVETYPE_NONE;
	ent.larm.takedamage = DAMAGE_NO;
	ent.rarm.solid = SOLID_NOT;
	ent.rarm.movetype = MOVETYPE_NONE;
	ent.rarm.takedamage = DAMAGE_NO;

	sound(ent, CHAN_WEAPON, "sounds/null.wav" ,1, ATTN_NORM);
	sound(ent, CHAN_VOICE, "sounds/null.wav" ,1, ATTN_NORM);
	sound(ent, CHAN_BODY, "sounds/null.wav" ,1, ATTN_NORM);
	sound(ent, CHAN_ITEM, "sounds/null.wav" ,1, ATTN_NORM);
	
	ent.usedent = world;
	
	if(ent.goalentity.classname == "window")
	{
		if(ent.goalentity.box1owner == ent)
			ent.goalentity.box1owner = world;
		if(ent.goalentity.box2owner == ent)
			ent.goalentity.box2owner = world;
		if(ent.goalentity.box3owner == ent)
			ent.goalentity.box3owner = world;
		if(ent.goalentity.usedent == ent)
			ent.goalentity.usedent = world;
	}
	
	ent.health = 0;
	ent.respawn_iterator = 0;
	Remaining_Zombies = Remaining_Zombies - 1;
}


void() Zombie_Death =
{
	Zombie_Death_Cleanup(self);
	
	// Death Noises
	if (self.electro_targeted == false)
		play_sound_z(3);
	else
		play_sound_z(5);

	//Gotta' make sure we set it back down instead of glitching it up, yo'
	if(self.s_time > 0 && sounds_playing > 0)
	{
		sounds_playing --;
		self.s_time = 0;
	}
	
	if(self.outside == false && self.electro_targeted == false)
	{
		if (totalpowerups < POWERUPS_PER_ROUND)
		{
			if (total_powerup_points >= powerup_score_threshold)
			{
				Spawn_Powerup(self.origin, -1);
				powerup_activate *= 1.14;
				powerup_score_threshold = total_powerup_points + powerup_activate;
			}
			else if (random () <= 0.02)
				Spawn_Powerup(self.origin, -1);
		}
	}
	
	if(self.crawling == TRUE)
	{
		crawler_die1();
	}
	else
	{
		if(random() < 0.3)
		{
			zombie_deathA1();
		}
		else if(random() < 0.5)
		{
			zombie_deathB1();
		}
		else 
		{
			zombie_deathC1();
		}
	}
};

//
// --------------------
// Electric Damage
// --------------------
//

//
// Z_ElectroShock
// Mark Zombie to die by non-Waffe Electricity.
//
void() Z_ElectroShock =
{
	// Mark the Zombie as to-be-dead
	self.electro_targeted = true;

	// Determine a time for the Zombie to die. (0.1-1.25s)
	self.death_timer = (rint((random() * 11.5) + 1)/10) + time;
	self.death_timer_activated = true;

	// Spawn a Sparkle
	if(self.crawling == true) {
		tesla_spark(self.origin - '0 0 18');
	}
	else {
		tesla_spark(self.origin + '0 0 13');
	}
	// Zombie_Tesla_Light();

	// Decide what to Gib
	float r = random();

	// Head?
	if (r < 0.20 && self.head.deadflag) {
		self.head.frame = 0;
		self.head.health = 0;
		self.head.deadflag = false;
		self.head.solid = SOLID_NOT;
		setmodel(self.head, "");
		makevectors(self.angles);
		spawn_gibs(self.origin + (self.head.view_ofs_x * v_right) 
		+ (self.head.view_ofs_y * v_forward) + (self.head.view_ofs_z * v_up));
		SpawnBlood(self.origin, self.origin, 50);
	}
	// Right Arm?
	r = random();
	if (r < 0.20 && self.rarm.deadflag) {
		self.rarm.frame = 0;
		self.rarm.health = 0;
		self.rarm.deadflag = false;
		self.rarm.solid = SOLID_NOT;
		setmodel(self.rarm, "");
		makevectors(self.angles);
		spawn_gibs(self.origin + (self.rarm.view_ofs_x * v_right) 
		+ (self.rarm.view_ofs_y * v_forward) + (self.rarm.view_ofs_z * v_up));
		SpawnBlood(self.origin, self.origin, 50);
	}
	// Left Arm?
	r = random();
	if (r < 0.20 && self.larm.deadflag) {
		self.larm.frame = 0;
		self.larm.health = 0;
		self.larm.deadflag = false;
		self.larm.solid = SOLID_NOT;
		setmodel(self.larm, "");
		makevectors(self.angles);
		spawn_gibs(self.origin + (self.larm.view_ofs_x * v_right) 
		+ (self.larm.view_ofs_y * v_forward) + (self.larm.view_ofs_z * v_up));
		SpawnBlood(self.origin, self.origin, 50);
	}

	// Play the first Electro-Sound
	play_sound_z(5);
}

/////////////////////ZOMBIE WAFFE STUFF/////////////////////

// Wunder'd
// 149-152 (FIXME - animate wunder'd zombies)
$frame wunder1 wunder2 wunder3 wunder4 wunder5 wunder6 wunder7 wunder8 wunder9 wunder10

void() zombie_wunder1		=[	$wunder1,		zombie_wunder2	]	{tesla_arc(); play_sound_z(4); self.frame = 149;};
void() zombie_wunder2		=[	$wunder2,		zombie_wunder3	]	{tesla_arc(); self.frame = 150;};
void() zombie_wunder3		=[	$wunder3,		zombie_wunder4	]	{tesla_arc();  self.frame = 151;};
void() zombie_wunder4		=[	$wunder4,		zombie_wunder5	]	{tesla_arc(); self.frame = 152;};
void() zombie_wunder5		=[	$wunder5,		zombie_wunder6	]	{tesla_arc(); self.frame = 151;};
void() zombie_wunder6		=[	$wunder6,		zombie_wunder7	]	{tesla_arc(); self.frame = 152;};
void() zombie_wunder7		=[	$wunder7,		zombie_wunder8	]	{tesla_arc(); self.frame = 151;};
void() zombie_wunder8		=[	$wunder8,		zombie_wunder9	]	{tesla_arc(); play_sound_z(3); self.frame = 152;};
void() zombie_wunder9		=[	$wunder9,		zombie_wunder10	]	{tesla_arc(); self.frame = 151;};
void() zombie_wunder10		=[	$wunder10,		SUB_Null 		]	{
	tesla_arc(); self.iszomb = 0; self.nextthink = time + 3; self.think = removeZombie;self.frame = 152;
	// Play final death anim:
	if(random() < 0.3) {
		zombie_deathA1();
	}
	else if(random() < 0.5) {
		zombie_deathB1();
	}
	else {
		zombie_deathC1();
	}
};




void() Zombie_Tesla_Death = {
	Zombie_Death_Cleanup(self);
	if(self.crawling == true) {
		tesla_spark(self.origin - '0 0 18');
		crawler_death_wunder1();
	}
	else {
		tesla_spark(self.origin + '0 0 13');
		zombie_wunder1();
	}
};

//
// Zombie_HeadCanGib(weapon)
// Checks if a Zombie is in a state where
// it's head can gib.
//
float(entity who, float weapon) Zombie_HeadCanGib =
{
	// First, is this weapon even capable?
	if (!WepDef_WeaponCanGibEnemy(weapon))
		return false;

	// Has it's head already been ripped off?
	if (!who.head.deadflag)
		return false;

	// If they have more than 10%(?) of health,
	// don't gib.
	float health_ratio = who.head.health / z_health;
	if (health_ratio > 0.10)
		return false;

	// Seems to pass, let it gib!
	return true;
};

/////////////////////ZOMBIE SPAWNING/////////////////////
void() zombieRise =
{
	//better not move wile rising, would happen sometimes
	self.velocity_x = 0;
	self.velocity_y = 0;
	
	if(self.frame < 13)//begin
	{
		self.frame = 12;//since we're going to add one anyways
		self.state = 1;//don't make crawler, yo!
	}
	if(self.frame == 36)
	{
		self.state = 0;
		if(self.crawling == 2)
		{
			makeCrawler(self);
			return;
		}
		self.th_walk();
		return;
	}
	self.frame ++;
	self.think = zombieRise;
	self.nextthink = time + 0.1;
	//LinkZombiesHitbox();
	//bprint (PRINT_HIGH, "Linked hitboxes");
};
void() spawn_zombie =
{
	setsize(self, '0 0 0', '0 0 0');
	if (self.spawnflags & INACTIVE)
	{
		if (cvar("developer"))
			setmodel(self, "models/player.mdl");
		self.classname = "spawn_zombie_in";
	}
	else
	{
		if (cvar("developer"))
			setmodel(self, "models/ai/zfull.mdl");
		self.classname = "spawn_zombie";
		self.spawn_id = zombie_spawn_points;
		zombie_spawn_points++;
	}
	
	//self.think = zombie_spawn_think;
	//self.nextthink = time + 0.5;
	
	self.solid = SOLID_NOT;
};

void(entity where) spawn_a_zombieB;
void() set_z_health =
{
	if(rounds <= 10)
	{
		z_health = 50 + (rounds * 100);
	}
	else
	{	
		local float i;
		i = rounds - 10;
		z_health = 1040;
		while(i > 0)
		{
			z_health *= 1.1; 
			i--;
		}
	}
};

//
// Zombie_ReassignSpawnIDs()
// To be called whenever we mess with a spawn point,
// this makes sure that spawn_a_zombieA() can never
// try to spawn a zombie at a point which index is
// inactive.
//
void() Zombie_ReassignSpawnIDs =
{
	float num_spawns = zombie_spawn_points;

	// First, clear the list.
	zombie_spawn_points = 0;

	while(num_spawns > 0) {
		entity zombie_spawn = findfloat(world, spawn_id, num_spawns);
		if (zombie_spawn) {
			zombie_spawn.spawn_id = 0;
		}
		num_spawns--;

		if (num_spawns)
			zombie_spawn = findfloat(world, spawn_id, num_spawns);
	}

	// Now do the re-assignment
	entity zombie_spawns = find(world, classname, "spawn_zombie");
	while(zombie_spawns) {
		zombie_spawns.spawn_id = zombie_spawn_points;
		zombie_spawn_points++;

		zombie_spawns = find(zombie_spawns, classname, "spawn_zombie");
	}
}

inline entity() getFreeZombieEnt =
{
	entity who;
	who = find(world,classname,"freeZombieEntity");
	
	return who;
};

float() spawn_a_zombieA =
{
	// cypress (20 dec 2023) -- rewrote this routine to be a little less
	// needlessly bloaty/bogged down and be in greater parity.

	// don't bother doing anything if it's not even time yet (avoids needless
	// iteration over ent chain)
	if (zombie_spawn_timer > time)
		return false;

	// look for a free entity
	entity zombie_ent = getFreeZombieEnt();

	// no free entity found, maximum are in play.
	if (!zombie_ent)
		return false;

	// look for a random spawn point. note -- before there was a routine that
	// prevented spawns from repeating one after the other before. i liked the
	// evened out use of the playspace at the beginning of the game but this
	// isn't standard CoD functionality and it has negative consequences with 
	// larger areas.
	entity zombie_spawn;
	float zombie_spawn_id = rint((random() * (zombie_spawn_points - 1))); // starts at 0!

	zombie_spawn = find(world, classname, "spawn_zombie");
	while(zombie_spawn != world) {
		if (zombie_spawn.spawn_id == zombie_spawn_id)
			break;

		zombie_spawn = find(zombie_spawn, classname, "spawn_zombie");
	}

	if (zombie_spawn == world) {
		if (cvar("developer"))
			bprint(PRINT_HIGH, "spawn_a_zombieA: No active spawn point exists! Bailing!\n");
		return false;
	}

	// prompt stage 2: the actual spawning of the zombie.
	spawn_a_zombieB(zombie_spawn);
	spawn_delay = time + delay_at_round;
	return true;
};

void(float i) spawnSingleZombEnt =
{
	local entity zSpawn;
	zSpawn = spawn();
	zSpawn.classname = "freeZombieEntity";
	zSpawn.aistatus = "0";
	zSpawn.goaldummy = spawn();
	if (cvar("developer")) {
		setmodel(zSpawn.goaldummy, "models/way/normal_way.spr");
	}


	zSpawn.goaldummy.classname = "waypoint_target";
	
	zSpawn.head = spawn();
	zSpawn.head.classname = "in_ai_zombie_head";
	zSpawn.head.owner = zSpawn;
	zSpawn.head.solid = SOLID_NOT;
	zSpawn.head.movetype = MOVETYPE_STEP;
	zSpawn.head.takedamage = DAMAGE_NO;

#ifndef FTE

	updateLimb (zSpawn, 0, zSpawn.head);

#endif // FTE
	
	zSpawn.larm = spawn();
	zSpawn.larm.classname = "in_ai_zombie_larm";
	zSpawn.larm.owner = zSpawn;
	zSpawn.larm.solid = SOLID_NOT;
	zSpawn.larm.movetype = MOVETYPE_STEP;
	zSpawn.larm.takedamage = DAMAGE_NO;

#ifndef FTE

	updateLimb (zSpawn, 1, zSpawn.larm);

#endif // FTE
	
	zSpawn.rarm = spawn();
	zSpawn.rarm.classname = "in_ai_zombie_rarm";
	zSpawn.rarm.owner = zSpawn;
	zSpawn.rarm.solid = SOLID_NOT;
	zSpawn.rarm.movetype = MOVETYPE_STEP;
	zSpawn.rarm.takedamage = DAMAGE_NO;

#ifndef FTE
	updateLimb (zSpawn, 2, zSpawn.rarm);
#endif // FTE

};

void(entity szombie)  SetUpHitBoxes =
{
	szombie.head.solid = SOLID_CORPSE;
	szombie.head.movetype = MOVETYPE_STEP;
	szombie.head.classname = "ai_zombie_head";
	szombie.head.takedamage = DAMAGE_YES;

	szombie.larm.solid = SOLID_CORPSE;
	szombie.larm.movetype = MOVETYPE_STEP;
	szombie.larm.classname = "ai_zombie_larm";
	szombie.larm.takedamage = DAMAGE_YES;

	szombie.rarm.solid = SOLID_CORPSE;
	szombie.rarm.movetype = MOVETYPE_STEP;
	szombie.rarm.classname = "ai_zombie_rarm";
	szombie.rarm.takedamage = DAMAGE_YES;
	
#ifdef FTE

	szombie.head.dimension_solid = HITBOX_DIM_LIMBS;
	szombie.larm.dimension_solid = HITBOX_DIM_LIMBS;
	szombie.rarm.dimension_solid = HITBOX_DIM_LIMBS;

#endif	// FTE

	local entity oldself = self;
	self = szombie;
	SetZombieHitBox(BASE_BBOX);
	self = oldself;
};

void(entity szombie) SetZombieWalk =
{	
	float zombie_move_speed_threshold = (rounds - 1) * 8;
	float walktype_chance = rint((random() * 35)) + zombie_move_speed_threshold;

	// Walking Zombie
	if (walktype_chance <= 35) {
		float which_walk_anim = random();

		if (which_walk_anim < 0.33)
			szombie.walktype = 1;
		else if (which_walk_anim < 0.66)
			szombie.walktype = 2;
		else
			szombie.walktype = 3;
	}
	// Jogging Zombie
	else if (walktype_chance <= 70) {
		szombie.walktype = 4;
	} 
	// Sprinting Zombie
	else {
		szombie.walktype = 5;
	}
};

void() spawnAllZombEnts =
{
	local float i;
	i = 0;

	// cypress -- let host engine dictate
	// max ai at once.

#ifdef FTE

	while(i < 24)

#else

	while(i < nzp_maxai())

#endif // FTE
	{
		spawnSingleZombEnt(i);
		i++;
	}
};

void(entity where) spawn_a_zombieB =
{
	local entity szombie;//USED FOR WHAT TO SPAWN
	//szombie = spawn();
	
	szombie = getFreeZombieEnt();
	if(szombie == world || zombie_spawn_timer > time)
	{
		//bprint(PRINT_HIGH, "STOPPED AT B\n");
		//dprint("Out of zombie entities \n");
		return;
	}

#ifdef FTE
	szombie.head = spawn();
	szombie.rarm = spawn();
	szombie.larm = spawn();

	szombie.head.owner = szombie.rarm.owner = szombie.larm.owner = szombie;

#endif // FTE

	szombie.origin = where.origin;
	
	szombie.frame = 0;
	
	szombie.target = where.target;
	//blubsvel
	//szombie.movetype = MOVETYPE_STEP;

	szombie.head.deadflag = 1;
	szombie.larm.deadflag = 1;
	szombie.rarm.deadflag = 1;

	setmodel(szombie.head, "models/ai/zh^.mdl");
	setmodel(szombie.rarm, "models/ai/zar(.mdl");
	setmodel(szombie.larm, "models/ai/zal(.mdl");

#ifndef FTE

	updateLimb (szombie, 0, szombie.head);
	updateLimb (szombie, 1, szombie.larm);
	updateLimb (szombie, 2, szombie.rarm);

#endif // FTE
	
	
	szombie.solid = SOLID_CORPSE;

#ifdef FTE

	szombie.dimension_solid = HITBOX_DIM_ZOMBIES;

#endif // FTE

	szombie.movetype = MOVETYPE_WALK;
	setmodel(szombie, "models/ai/zb%.mdl");
	szombie.hop_step = 0;

	// cypress (20 dec 2023) -- see comment from removeZombie(),
	// this is just a sanity check just in case someone decides
	// to play around with a freeZombieEntity and breaks that check..
	szombie.nextthink = time + 0.05;
	szombie.think = SUB_Null;

	szombie.gravity = 1.0;
	
	if (map_compatibility_mode == MAP_COMPAT_BETA) {
		szombie.mins = '-6 -6 -24';
		szombie.maxs = '6 6 22';

#ifdef FTE

		// Need to force-set the hull for FTE or else Zombie setorigin()
		// calls will fail in tight spaces.
		szombie.hull = 1;

#endif // FTE

	} else {
		szombie.mins = '-8 -8 -32';
		szombie.maxs = '8 8 30';
	}
	
	setsize (szombie, szombie.mins, szombie.maxs);
		
	
	//====================================
	
	if(pointcontents(szombie.origin - '0 0 36') == -2)
	{
		while(pointcontents (szombie.origin - '0 0 36') == -2)
		{
			szombie.origin = szombie.origin + '0 0 1';
			setorigin(szombie,szombie.origin );
		}
	}

	szombie.classname = "ai_zombie";
	szombie.aistatus = "1";
	setorigin (szombie.goaldummy, '0 0 0');
	szombie.origin_z = szombie.origin_z + 1;
	szombie.outside = true;
	szombie.takedamage = DAMAGE_YES;
	setorigin(szombie, szombie.origin);
	szombie.flags = szombie.flags | FL_PARTIALGROUND | FL_MONSTER;

	szombie.spawnflags = where.spawnflags;
	//////////FIX FOR OUTSIDE
	if(szombie.spawnflags & 4)
	{
		szombie.outside = FALSE;
	}
	
	/////////
	
	szombie.ideal_yaw = szombie.angles_y;
	szombie.yaw_speed = 20;
	szombie.iszomb = 1;
	szombie.death_timer = 0;
	szombie.death_timer_activated = false;
	szombie.electro_targeted = false;
	
	// We used to set different limb health, too, but we now handle any limb damage differences in weapon stats.
	szombie.health = szombie.head.health = szombie.larm.health = szombie.rarm.health = z_health;

	szombie.th_die = Zombie_Death;
	szombie.th_walk = Zombie_Walk_Setup;
	szombie.th_melee = zombie_attack;
	szombie.th_idle = zombie_idle;
	szombie.th_windowhop = zombie_hop1;
	
	szombie.th_fall = zombie_fall1;
	szombie.th_land = zombie_land1;

	szombie.th_diewunder = Zombie_Tesla_Death;
	
	//szombie.th_jump = zombie_jump1;
	//szombie.th_grabledge = zombie_grabledge1;
	

	//==================================================================================================
	SetZombieWalk(szombie);
	//==================================================================================================
	
	SetUpHitBoxes(szombie); 
	//szombie.walktype = 5;
	////////////////////////////////////////////////////
	szombie.reload_delay = 30 + time;//save  floats, equals respawn time.
	local entity old_self;
	old_self = self;
	self = szombie;
	if (self.spawnflags & 2)//RISER
	{
		zombieRise();
	}
	else
		self.th_walk();
	self = old_self;
	
	//LinkZombiesHitbox();

	//
	// Zombie skin setting
	//
	float tex;
	tex = random();

	if (tex > 0.75)
		szombie.skin = 0;
	else if (tex > 0.50)
		szombie.skin = 1;
	else if (tex > 0.25)
		szombie.skin = 2;
	else
		szombie.skin = 3;

	szombie.head.skin = szombie.larm.skin = szombie.rarm.skin = szombie.skin;

	if (map_compatibility_mode == MAP_COMPAT_BETA)
		szombie.head.scale = szombie.larm.scale = szombie.rarm.scale = szombie.scale = 0.73;

	// set up timer for next spawn
	zombie_spawn_timer = zombie_spawn_delay + time;
};

void() zombie_dummy =
{
	self.frame = 0;
	
	self.solid = SOLID_SLIDEBOX;
	self.movetype = MOVETYPE_STEP;

	
	setmodel(self, "models/ai/zfull.mdl");
	
	setsize (self, '-8 -8 -32', '8 8 30');
	setorigin(self, self.origin);
	self.classname = "ai_zombie";
	self.takedamage = DAMAGE_YES;
	self.flags = self.flags | FL_PARTIALGROUND | FL_MONSTER;
	self.health = 999999;
	SetUpHitBoxes(self);
};
