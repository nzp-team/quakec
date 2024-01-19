/*
	server/weapons/tesla.qc

	Core logic for the Wunderwaffe special weapon.

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


// 
// Think function for tesla spark sprite spawned at zombie torso
// 
void() tesla_spark_think =
{
    float prev_frame = self.frame;
    while(self.frame == prev_frame) {
        self.frame = rint(random()*3);
    }
	if(self.ltime < time) {
		remove(self);
	}
	self.nextthink = time + 0.05;
}

// 
// Tesla spark sprite spawned at zombie torso
// 
void(vector pos) tesla_spark = {
	local entity lightning = spawn();
	setmodel(lightning, "models/sprites/lightning.spr");
	setorigin(lightning, pos);
	lightning.think = tesla_spark_think;
	lightning.nextthink = time + 0.05;
	lightning.ltime = time + 1;
}


// 
// 
// 
void(entity hit_ent, entity arc_parent, entity arc_owner, float arc_num, float do_arc) tesla_damage = {
    // set lib models to null
	// (if we remove them RelinkZombies will cry)
    if (!hit_ent.th_diewunder)
        return;

	if (hit_ent.head)
		setmodel(hit_ent.head, "");
	if (hit_ent.larm)
		setmodel(hit_ent.larm, "");
	if (hit_ent.rarm)
		setmodel(hit_ent.rarm, "");

    hit_ent.velocity.x = 0;
    hit_ent.velocity.y = 0;

	// window hop fix
	if (self.state == 1 || self.hop_step != 0) {
		self.state = self.hop_step = 0;
	}

    if(arc_owner != world && hit_ent.aistatus == "1") {
        arc_owner.tesla_n_kills += 1;
        
        // 50 points for waffe kills
        if(arc_owner.classname == "player") {
            arc_owner.kills += 1;
            addmoney(arc_owner, 50, true);
        }
    }

    if(do_arc == true) {
        // float wait_time = lerp(0.2,0.6, random()) * arc_num;
        // The first zombie does not wait, every arc thereafter does
        float wait_time = arc_num == 1 ? 0 : lerp(0.2,0.6, random()) * arc_num;
        hit_ent.tesla_next_arc_time = time + wait_time;
        // print("Entity ", hit_ent.classname, " set to arc after ",ftos(wait_time)," (t=", ftos(hit_ent.tesla_next_arc_time), ")\n");
    }
    else {
        // print("Entity ", hit_ent.classname, " NOT set to arc at.\n");
        hit_ent.tesla_next_arc_time = -1;
    }
    hit_ent.tesla_arc_parent = arc_parent;
    hit_ent.tesla_arc_owner = arc_owner;
    hit_ent.tesla_arc_num = arc_num;
	// play our wunder-ful anim
    entity oself = self;
    self = hit_ent;
    self.th_diewunder();
    self = oself;
}


vector(entity ent) tesla_arc_ofs_for_ent = {
    if(ent.classname == "ai_zombie") {
        if(ent.crawling == true) {
            return '0 0 -18';
        }
        else {
            return '0 0 20';
        }
    }
    else if(ent.classname == "ai_dog") {
        return '0 0 0';
    }
    
    return '0 0 0';
}


// entity cur_ent, entity prev_ent, entity player
void() tesla_arc = {
    if(self.tesla_next_arc_time < 0) {
        return;
    }
    if(self.tesla_next_arc_time > time) {
        return;
    }
    // print("\"",self.classname,"\" arcing ( arcs:",ftos(self.tesla_arc_num)," kills: ",ftos(self.tesla_arc_owner.tesla_n_kills),") for arctime: ");
    // print(ftos(self.tesla_next_arc_time),"\n");
    self.tesla_next_arc_time = -1;
    if(self.tesla_arc_owner.tesla_n_kills >= 10) {
        // print("\tAt max kills. Stopping.\n");
        return;
    }

    self.iszomb = 0;

    // If we can't arc any further, tell parent to keep trying
    if(self.tesla_arc_num >= 5) {
        // We already waited, do it immediately
        self.tesla_arc_parent.tesla_next_arc_time = 0;
        // print("\tAt max arc-counts, keep arcing from parent.\n");
        return;
    }

    // Maximum arcing distance for this zombie
    float max_dist = 300 - (20 * self.tesla_arc_num);
    // print("\tZombie arc to max dist: ", ftos(max_dist), "\n");

	entity best_ent = world;
    if(max_dist > 0) {
        // If arcing, find the closest zombie to current zombie:
        entity ent = findfloat(world, iszomb, 1);
        float dist;
        float best_dist = max_dist;
        while(ent != world) {
            if(ent != self && ent.aistatus == "1") {
                dist = vlen(self.origin - ent.origin);
                if(dist < best_dist) {
                    // Check traceline to make sure is visible
                    vector trace_start = self.origin + tesla_arc_ofs_for_ent(self);
                    vector trace_end = ent.origin + tesla_arc_ofs_for_ent(self);
                    traceline(trace_start, trace_end, 1, world); // MOVE_NOMONSTERS=1
                    if(trace_fraction >= 1.0) {
                        best_dist = dist;
                        best_ent = ent;
                    }
                }
            }
            ent = findfloat(ent, iszomb, 1);
        }
    }

    // print("\tZombie arcing to entity: \"", best_ent.classname, "\" dist: ", ftos(best_dist), "\n");


    // We found a zombie to arc to, continue arc from there
    if(best_ent != world) {
        tesla_damage(best_ent, self, self.tesla_arc_owner, self.tesla_arc_num + 1, true); 

        vector source_pos = self.origin + tesla_arc_ofs_for_ent(self);
        vector target_pos = best_ent.origin + tesla_arc_ofs_for_ent(best_ent);

#ifdef FTE

        te_lightning1(self, source_pos, target_pos);

#else

        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte(MSG_BROADCAST, TE_LIGHTNING1);
        WriteEntity(MSG_BROADCAST, self);
        WriteCoord(MSG_BROADCAST, source_pos.x);
        WriteCoord(MSG_BROADCAST, source_pos.y);
        WriteCoord(MSG_BROADCAST, source_pos.z);
        WriteCoord(MSG_BROADCAST, target_pos.x);
        WriteCoord(MSG_BROADCAST, target_pos.y);
        WriteCoord(MSG_BROADCAST, target_pos.z);

#endif // FTE

    }
    // No ent to arc to, tell arc parent to resume its search
    // else if(self.tesla_arc_parent != world) {
    //     // Don't wait, start immediately
    //     self.tesla_arc_parent.tesla_next_arc_time = 0;
    // }
    // Have self immediately arc again next frame
    self.tesla_next_arc_time = 0;
}



// Fire lightning out of the gun
void() W_FireTesla =
{
    vector source;
    entity tempe = spawn();

    makevectors(self.v_angle);
	source = self.origin + self.view_ofs;
    vector barrel_ofs = GetWeaponFlash_Offset(self.weapon);
	source += v_right * (barrel_ofs.x/1000);
    source += v_up * (barrel_ofs.y/1000);
    source += v_forward * (barrel_ofs.z/1000);

#ifdef FTE
	self.dimension_hit = HITBOX_DIM_LIMBS | HITBOX_DIM_ZOMBIES;
#endif // FTE

	FireTrace(1, 0, 0, 0);

#ifdef FTE
	self.dimension_hit = HITBOX_DIM_ZOMBIES;
#endif // FTE

    // Initial Lightning is Red when Pack-A-Punched
    if (IsPapWeapon(self.weapon)) {

#ifdef FTE

        te_lightning2(world, source, trace_endpos);

#else

        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte(MSG_BROADCAST, TE_LIGHTNING2);
        WriteEntity(MSG_BROADCAST, tempe);
        WriteCoord(MSG_BROADCAST, source_x);
        WriteCoord(MSG_BROADCAST, source_y);
        WriteCoord(MSG_BROADCAST, source_z);
        WriteCoord(MSG_BROADCAST, trace_endpos_x);
        WriteCoord(MSG_BROADCAST, trace_endpos_y);
        WriteCoord(MSG_BROADCAST, trace_endpos_z);

#endif // FTE

    } else {

#ifdef FTE

        te_lightning1(world, source, trace_endpos);

#else

        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte(MSG_BROADCAST, TE_LIGHTNING1);
        WriteEntity(MSG_BROADCAST, tempe);
        WriteCoord(MSG_BROADCAST, source_x);
        WriteCoord(MSG_BROADCAST, source_y);
        WriteCoord(MSG_BROADCAST, source_z);
        WriteCoord(MSG_BROADCAST, trace_endpos_x);
        WriteCoord(MSG_BROADCAST, trace_endpos_y);
        WriteCoord(MSG_BROADCAST, trace_endpos_z);

#endif // FTE

    }

    remove(tempe);

	self.tesla_n_kills = 0;
    
    entity hit_ent = trace_ent;
	if(hit_ent.classname == "ai_zombie_head" || hit_ent.classname == "ai_zombie_larm" || hit_ent.classname == "ai_zombie_rarm")
		hit_ent = hit_ent.owner;

    // print("W_FireTesla hit ent: ", hit_ent.classname, "\n");

    if(trace_ent != world && trace_ent.takedamage) {
        tesla_damage(hit_ent, world, self, 1, true); 
    }
    // Not a direct-hit, do splash damage:
    else {
        tesla_spark(trace_endpos);

        // TODO - Search for proximity to players and damage players
        // TODO - Electric overlay player HUD


        // ------- Find zombie closest to splash damage pos ---------
        // Damage any players within splash damage radius along the way
        float inner_radius = 30;
        float splash_radius = 110;
        entity ent = findradius(trace_endpos, splash_radius);
        float dist;
        entity best_ent = world;
        float best_dist = splash_radius;
        while(ent != world) {
            if(ent == self) {
                // ----------------------------------------
                // Player logic:
                // ----------------------------------------
                // - Same damage with or without jug
                // - Deal 75 damage at `inner_radius` qu
                // - Deal 0 damage at `splash_radius` qu
                // - Linearly interpolate damage in-between
                dist = vlen(ent.origin - trace_endpos);
                // lerp_frac: 1 at inner_radius, 0 at splash_radius
                float lerp_frac = (dist - splash_radius) / (inner_radius - splash_radius); 
                float damage = lerp(0, 75, lerp_frac);
                // print("Giving player ",ftos(damage), " damage.\n");

                if (other.perks & P_JUG)
    				DamageHandler(ent, self, damage, S_ZAPPER);
	    		else
		    		DamageHandler(ent, self, damage, S_ZAPPER);
                // ----------------------------------------
            }

            if(ent.aistatus == "1") {
                dist = vlen(ent.origin - trace_endpos);
                if(dist < best_dist) {
                    best_dist = dist;
                    best_ent = ent;
                }
            }
            ent = ent.chain;
        }
        if(best_ent != world) {
            tesla_damage(best_ent, world, self, 1, true); 
        }
    }
}