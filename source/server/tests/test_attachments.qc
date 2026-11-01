float(float condition, string message) Test_Assert;
void() AttachmentTest_CompleteDeferred;
float test_deferred, test_pending;
.vector attachment_test_min, attachment_test_max;
.float attachment_test_frame;
float attachment_test_contacts;
entity attachment_test_target;

void(entity parent, entity child, float role, float flags) Test_Attach =
{
	child.owner = parent;
	child.movetype = MOVETYPE_STEP;
	child.solid = SOLID_BBOX;
	child.deadflag = role != 1;
	child.frame = 40 + role;
	child.view_ofs = '2 3 5' * (role + 1);
	child.bbmins = '-2 -3 -4';
	child.bbmaxs = '2 3 4';
	Test_Assert(collision_attach(child, parent, child.view_ofs, child.bbmins, child.bbmaxs, flags, role), "Could not register collision child.");
};

void() Test_AttachmentsGeometry =
{
	entity first = spawn(), second = spawn();
	first.classname = second.classname = "ai_zombie";
	first.currentHitBoxSetup = second.currentHitBoxSetup = BASE_BBOX;
	first.origin = '100000 100000 100000'; second.origin = first.origin + '100 200 300';
	first.angles = '15 60 -25'; second.angles = '-30 170 10';
	first.frame = 71; second.frame = 81;
	entity parents[2]; parents[0] = first; parents[1] = second;
	for (int p = 1; p >= 0; p--) {
		entity parent = parents[p];
		parent.head = spawn(); parent.larm = spawn(); parent.rarm = spawn();
		Test_Attach(parent, parent.rarm, 2, COLLISION_ATTACH_FRAME_IF_DEAD);
		Test_Attach(parent, parent.larm, 1, COLLISION_ATTACH_FRAME_IF_DEAD);
		Test_Attach(parent, parent.head, 0, COLLISION_ATTACH_FRAME_IF_DEAD);
	}
	for (int p = 0; p < 2; p++) {
		makevectors(parents[p].angles);
		entity child = parents[p].head;
		for (int role = 0; role < 3; role++) {
			if (role == 1) child = parents[p].larm;
			if (role == 2) child = parents[p].rarm;
			vector offset = (v_right * child.view_ofs_x) + (v_forward * child.view_ofs_y) + (v_up * child.view_ofs_z);
			vector lower = child.bbmins + offset, upper = child.bbmaxs + offset;
			if (lower_x > upper_x) { lower_x += upper_x; upper_x = lower_x - upper_x; lower_x -= upper_x; }
			if (lower_y > upper_y) { lower_y += upper_y; upper_y = lower_y - upper_y; lower_y -= upper_y; }
			if (lower_z > upper_z) { lower_z += upper_z; upper_z = lower_z - upper_z; lower_z -= upper_z; }
			child.attachment_test_min = lower; child.attachment_test_max = upper;
			child.attachment_test_frame = child.deadflag ? parents[p].frame : child.frame;
			child.origin = child.angles = child.mins = child.maxs = '0 0 0';
		}
	}
	vector saved_forward = v_forward, saved_right = v_right, saved_up = v_up;
	collision_update();
	Test_Assert(v_forward == saved_forward && v_right == saved_right && v_up == saved_up, "Native batch changed makevectors side effects or parent order.");
	for (int p = 0; p < 2; p++) {
		entity child = parents[p].head;
		for (int role = 0; role < 3; role++) {
			if (role == 1) child = parents[p].larm;
			if (role == 2) child = parents[p].rarm;
			Test_Assert(child.origin == parents[p].origin && child.angles == parents[p].angles, "Native child pose differs from QC.");
			Test_Assert(child.mins == child.attachment_test_min && child.maxs == child.attachment_test_max, "Native bounds differ from QC arithmetic.");
			Test_Assert(child.size == child.maxs - child.mins && child.absmin == child.origin + child.mins - '1 1 1', "Collision bounds were not spatially linked.");
			Test_Assert(child.frame == child.attachment_test_frame, "Detached limb frame was overwritten.");
			remove(child);
		}
		remove(parents[p]);
	}
};

void() Test_AttachmentsConfiguration =
{
	entity parent = spawn(); parent.head = spawn(); parent.larm = spawn(); parent.rarm = spawn();
	parent.origin = '100000 100000 100000'; parent.currentHitBoxSetup = -1;
	entity previous = self; self = parent;
	SetZombieHitBox(BASE_BBOX); collision_update(); vector previous_bounds = parent.head.mins;
	SetZombieHitBox(IDLE_BBOX); collision_update();
	Test_Assert(parent.head.mins != previous_bounds, "Changed hitbox setup did not refresh attachment bounds.");
	SetZombieHitBox(EMPTY_BBOX); vector position = parent.head.origin;
	parent.origin += '100 0 0'; collision_update();
	Test_Assert(parent.head.origin == position, "Empty hitboxes remained registered.");
	self = previous;
	remove(parent.head); remove(parent.larm); remove(parent.rarm); remove(parent);
};

void() AttachmentTest_RemoveTouch = { attachment_test_contacts++; remove(other); };
void() AttachmentTest_CountTouch = { attachment_test_contacts++; };
void() AttachmentTest_ReparentTouch =
{
	attachment_test_contacts++;
	collision_attach(other, attachment_test_target, '0 0 0', '-2 -2 -2', '2 2 2', COLLISION_ATTACH_PASSIVE, 0);
};

void() Test_AttachmentsContacts =
{
	entity parent = spawn(), child = spawn(), first = spawn(), second = spawn();
	parent.origin = '100000 100000 100000'; child.movetype = MOVETYPE_STEP; child.solid = SOLID_BBOX;
	first.solid = second.solid = SOLID_TRIGGER;
	first.touch = AttachmentTest_RemoveTouch; second.touch = AttachmentTest_CountTouch;
	setsize(first, '-10 -10 -10', '10 10 10'); setorigin(first, parent.origin);
	setsize(second, '-10 -10 -10', '10 10 10'); setorigin(second, parent.origin);
	collision_attach(child, parent, '0 0 0', '-2 -2 -2', '2 2 2', COLLISION_ATTACH_PASSIVE, 0);
	attachment_test_contacts = 0; collision_update();
	Test_Assert(attachment_test_contacts == 1, "Freed child received another trigger callback.");
	remove(first); remove(second); remove(parent);
	parent = spawn(); child = spawn(); first = spawn(); second = spawn();
	attachment_test_target = spawn(); attachment_test_target.origin = '100100 100000 100000';
	parent.origin = '100000 100000 100000'; child.solid = SOLID_BBOX;
	first.solid = second.solid = SOLID_TRIGGER;
	first.touch = AttachmentTest_ReparentTouch; second.touch = AttachmentTest_CountTouch;
	setsize(first, '-10 -10 -10', '10 10 10'); setorigin(first, parent.origin);
	setsize(second, '-10 -10 -10', '10 10 10'); setorigin(second, parent.origin);
	collision_attach(child, parent, '0 0 0', '-2 -2 -2', '2 2 2', COLLISION_ATTACH_PASSIVE, 0);
	attachment_test_contacts = 0; collision_update();
	Test_Assert(attachment_test_contacts == 1, "Reparented child continued through a stale contact snapshot.");
	collision_update(); Test_Assert(child.origin == attachment_test_target.origin, "Reparented child did not follow its new parent.");
	remove(first); remove(second); remove(child); remove(parent); remove(attachment_test_target);
};

void() Test_AttachmentsElectricTrap =
{
	entity parent = spawn(), child = spawn(), trap = spawn();
	parent.origin = '100000 100000 100000'; parent.classname = "ai_zombie"; parent.head = child;
	child.owner = parent; child.classname = "ai_zombie_head"; child.solid = SOLID_BBOX;
	trap.solid = SOLID_TRIGGER; trap.touch = zapper_do_damage;
	setsize(trap, '-4 -4 -4', '4 4 4'); setorigin(trap, parent.origin + '0 0 35');
	collision_attach(child, parent, '0 0 35', '-2 -2 -2', '2 2 2', COLLISION_ATTACH_PASSIVE, 0);
	collision_update();
	Test_Assert(parent.electro_targeted && parent.death_timer_activated && parent.death_timer > time, "Limb-only electric trap contact did not reach the owning zombie.");
	remove(trap); remove(child); remove(parent);
};

void() AttachmentTest_Think = { self.count++; };
void() AttachmentTest_ParentThink = { self.oldorigin = self.origin; self.nextthink = time + frametime; };
void() AttachmentTest_PhysicsComplete =
{
	entity parent = self.owner, child = parent.head;
	Test_Assert(child.count == 1, "Passive attachment lost its think callback.");
	Test_Assert(child.velocity == '0 0 100', "Passive attachment ran independent gravity or collision physics.");
	Test_Assert(child.origin == parent.oldorigin, "Normal movement violated EndFrame snapshot timing.");
	collision_update(); Test_Assert(child.origin == parent.origin, "EndFrame batch did not follow the moving parent.");
	remove(child); remove(parent); AttachmentTest_CompleteDeferred(); remove(self);
};

void() Test_AttachmentsPassivePhysics =
{
	entity parent = spawn(), child = spawn(), verifier = spawn();
	parent.origin = '200000 200000 200000'; parent.velocity = '100 0 0'; parent.movetype = MOVETYPE_NOCLIP;
	parent.head = child; parent.think = AttachmentTest_ParentThink; parent.nextthink = time + frametime;
	child.velocity = '0 0 100'; child.movetype = MOVETYPE_STEP; child.solid = SOLID_BBOX;
	child.think = AttachmentTest_Think; child.nextthink = time + frametime;
	collision_attach(child, parent, '0 0 0', '-2 -2 -2', '2 2 2', COLLISION_ATTACH_PASSIVE, 0); collision_update();
	verifier.owner = parent; verifier.think = AttachmentTest_PhysicsComplete; verifier.nextthink = time + 0.2;
	verifier.message = "Test_AttachmentsPassivePhysics"; test_deferred = true; test_pending++;
};

void() Test_AttachmentsParentRemoval =
{
	entity parent = spawn();
	parent.classname = "ai_zombie";
	parent.origin = '100000 100000 100000';
	parent.head = spawn();
	parent.larm = spawn();
	parent.rarm = spawn();
	Test_Attach(parent, parent.head, 0, COLLISION_ATTACH_PASSIVE);
	Test_Attach(parent, parent.larm, 1, COLLISION_ATTACH_PASSIVE);
	Test_Attach(parent, parent.rarm, 2, COLLISION_ATTACH_PASSIVE);
	parent.currentHitBoxSetup = BASE_BBOX;
	collision_update();
	entity saved_head = parent.head, saved_left = parent.larm, saved_right = parent.rarm;
	vector previous = saved_head.origin;
	remove(parent);
	collision_update();
	Test_Assert(saved_head.origin == previous, "Freed parent retained collision children.");
	remove(saved_head);
	remove(saved_left);
	remove(saved_right);
};

void() AttachmentTest_ReuseTriggerTouch =
{
	attachment_test_contacts++;
	vector position = attachment_test_target.origin;
	remove(attachment_test_target);
	entity replacement = spawn();
	replacement.solid = SOLID_TRIGGER;
	replacement.touch = AttachmentTest_CountTouch;
	setsize(replacement, '-10 -10 -10', '10 10 10');
	setorigin(replacement, position);
	attachment_test_target = replacement;
};

void() Test_AttachmentsReusedTrigger =
{
	entity parent = spawn(), child = spawn(), first = spawn(), second = spawn();
	parent.origin = '100000 100000 100000';
	child.solid = SOLID_BBOX;
	child.movetype = MOVETYPE_STEP;
	first.solid = second.solid = SOLID_TRIGGER;
	first.touch = AttachmentTest_ReuseTriggerTouch;
	second.touch = AttachmentTest_CountTouch;
	setsize(first, '-10 -10 -10', '10 10 10');
	setorigin(first, parent.origin);
	setsize(second, '-10 -10 -10', '10 10 10');
	setorigin(second, parent.origin);
	attachment_test_target = second;
	collision_attach(child, parent, '0 0 0', '-2 -2 -2', '2 2 2', COLLISION_ATTACH_PASSIVE, 0);
	attachment_test_contacts = 0;
	collision_update();
	Test_Assert(attachment_test_target == second, "Trigger fixture did not reuse the deleted edict slot.");
	Test_Assert(attachment_test_contacts == 1, sprintf("Reused trigger contact count: %d (expected 1).", attachment_test_contacts));
	remove(first);
	remove(attachment_test_target);
	remove(child);
	remove(parent);
};
