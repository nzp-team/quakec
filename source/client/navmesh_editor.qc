
// ============================================================================
//						Navmesh editing functions
// ============================================================================

#define NAV_MAX_SELECTED_VERTS 4

int *selected_verts;
float selected_vert_count;
navmesh_vertex *cl_navmesh_verts;
float cl_navmesh_vert_count;
navmesh_poly *cl_navmesh_polies;
float cl_navmesh_poly_count;
navmesh_traversal *cl_navmesh_traversals;
float cl_navmesh_traversal_count;
float cl_navmesh_selected_traversal;


float cl_navmesh_traversal_edit_mode;
float cl_navmesh_traversal_editor_cur_point;




// float selected_verts[NAV_MAX_SELECTED_VERTS];
// float selected_vert_count;

// navmesh_vertex cl_navmesh_verts[NAV_MAX_VERTS];
// float cl_navmesh_vert_count;

// navmesh_poly cl_navmesh_polies[NAV_MAX_POLIES];
// float cl_navmesh_poly_count;


float cl_navmesh_place_corner_state;
#define NAVMESH_PLACE_CORNER_PLACING 1
#define NAVMESH_PLACE_CORNER_CONFIRM 2

// Declarations
void(vector pos, vector scale, vector color, float alpha) cl_navmesh_draw_test_ent;
float(vector pos, float poly_index) cl_navmesh_is_inside_poly;
void() cl_navmesh_delete_verts;
void(float poly_index) cl_navmesh_delete_poly_at_index;
float(vector pos) cl_navmesh_get_containing_poly;


//This is for placing a temp entity to test the pathfinding
vector goalent_pos;
float goalent_set;
vector startent_pos;
float startent_set;

void cl_navmesh_draw_box(vector pos,vector size, vector color, float alpha) {
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);

	// Size is radius:
	size = size * 0.5;
	
	//bottom face
	R_PolygonVertex(pos + [-size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Top face
	R_PolygonVertex(pos + [-size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Front face
	R_PolygonVertex(pos + [-size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Back face
	R_PolygonVertex(pos + [-size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Left face
	R_PolygonVertex(pos + [-size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [-size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Right face
	R_PolygonVertex(pos + [size.x,-size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,-size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,size.y,size.z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [size.x,-size.y,size.z], [0,0,0], color,alpha);
	R_EndPolygon();
}

void cl_navmesh_draw_vert(vector pos,vector color, float alpha) {
	cl_navmesh_draw_box(pos, [4,4,4], color, alpha);
}


void cl_navmesh_draw_plane(vector pos, vector nor, float size, vector color, float alpha) {
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);

	vector nor_angles = vectoangles(nor);
	makevectors(nor_angles);
	vector tl = pos + (-v_right + v_up) * size;
	vector tr = pos + ( v_right + v_up) * size;
	vector bl = pos + (-v_right - v_up) * size;
	vector br = pos + ( v_right - v_up) * size;

	// Front face 
	R_PolygonVertex(bl, [0,0,0], color,alpha);
	R_PolygonVertex(br, [0,0,0], color,alpha);
	R_PolygonVertex(tr, [0,0,0], color,alpha);
	R_PolygonVertex(tl, [0,0,0], color,alpha);
	R_EndPolygon();

	// Back face -- not needed when backface culling is disabled
	// R_PolygonVertex(bl, [0,0,0], color,alpha);
	// R_PolygonVertex(tl, [0,0,0], color,alpha);
	// R_PolygonVertex(tr, [0,0,0], color,alpha);
	// R_PolygonVertex(br, [0,0,0], color,alpha);
	// R_EndPolygon();
}




void cl_navmesh_draw_line(vector start, vector end, float edge_width, vector color, float alpha) {
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	R_PolygonVertex(end + [0,0,-edge_width], [0,0,0], color, alpha);
	R_PolygonVertex(end + [0,0,edge_width], [0,0,0], color, alpha);
	R_PolygonVertex(start + [0,0,edge_width], [0,0,0], color, alpha);
	R_PolygonVertex(start + [0,0,-edge_width], [0,0,0], color, alpha);
	R_EndPolygon();
}

void cl_navmesh_draw_edge(vector start, vector end, vector color, float alpha) {
	cl_navmesh_draw_line(start,end,1,color,alpha);
}

void cl_navmesh_draw_quad(vector a, vector b, vector c, vector d, vector color, float alpha, int draw_edges) {
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
		
	R_PolygonVertex(a, [0,0,0], color, alpha);
	R_PolygonVertex(b, [0,0,0], color, alpha);
	R_PolygonVertex(c, [0,0,0], color, alpha);
	R_PolygonVertex(d, [0,0,0], color, alpha);
	R_EndPolygon();
	
	//Drawing polygon border
	if(draw_edges == TRUE) {
		vector border_color = [0.5, 0.5, 0.5];
		float border_alpha = 0.2;
		cl_navmesh_draw_edge(a,b, border_color, border_alpha);
		cl_navmesh_draw_edge(b,c, border_color, border_alpha);
		cl_navmesh_draw_edge(c,d, border_color, border_alpha);
		cl_navmesh_draw_edge(d,a, border_color, border_alpha);
	}
}

// Draws a 3D line using a box
void cl_navmesh_draw_line_3d(vector start, vector end, float edge_width, vector color, float alpha) {
	// drawline(edge_width, start, end, color, alpha, drawflag???);
	// return;
	vector v_f = normalize(end - start);
	vector v_r = normalize(crossproduct(v_f, '0 0 1'));
	vector v_u = normalize(crossproduct(v_r, v_f));

	// Special degenerate case: v_f is straight up
	if(end.x == start.x && end.y == start.y) {
		v_f = '0 0 1';
		v_r = '1 0 0';
		v_u = '0 1 0';
	}

	// 4 corners around start
	vector start_bl = start + edge_width * (-v_r - v_u);
	vector start_br = start + edge_width * ( v_r - v_u);
	vector start_tr = start + edge_width * ( v_r + v_u);
	vector start_tl = start + edge_width * (-v_r + v_u);
	// 4 corners around end
	vector end_bl = end + edge_width * (-v_r - v_u);
	vector end_br = end + edge_width * ( v_r - v_u);
	vector end_tr = end + edge_width * ( v_r + v_u);
	vector end_tl = end + edge_width * (-v_r + v_u);

	cl_navmesh_draw_quad(start_bl, start_br, start_tr, start_tl, 	color, alpha, false); // Start quad
	cl_navmesh_draw_quad(start_tr, end_tr, end_tl, start_tl, 		color, alpha, false); // Top quad
	cl_navmesh_draw_quad(start_br, end_br, end_bl, start_bl, 		color, alpha, false); // Bottom quad
	cl_navmesh_draw_quad(start_br, end_br, end_tr, start_tr, 		color, alpha, false); // Right quad
	cl_navmesh_draw_quad(start_bl, end_bl, end_tl, start_tl, 		color, alpha, false); // Left quad
	cl_navmesh_draw_quad(end_bl, end_tl, end_tr, end_br, 			color, alpha, false); // End quad
}

void cl_navmesh_draw_tri(vector a, vector b, vector c, vector color, float alpha, int draw_edges) {
//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	R_PolygonVertex(a, [0,0,0], color, alpha);
	R_PolygonVertex(b, [0,0,0], color, alpha);
	R_PolygonVertex(c, [0,0,0], color, alpha);
	R_EndPolygon();
	
	//Drawing polygon border
	if(draw_edges == TRUE)
	{
		vector border_color = [0.5, 0.5, 0.5];
		float border_alpha = 0.2;
		cl_navmesh_draw_edge(a,b, border_color, border_alpha);
		cl_navmesh_draw_edge(b,c, border_color, border_alpha);
		cl_navmesh_draw_edge(c,a, border_color, border_alpha);
	}
}

void cl_navmesh_draw_poly(float poly_index) {
	vector face_color = [0.2,0.8,0.2];	
	float face_alpha = 0.1;
	
	vector a = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[0]].pos;
	vector b = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[1]].pos;
	vector c = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[2]].pos;

	// Draw door polygons as red
	if(cl_navmesh_polies[poly_index].doortarget != "") {
		face_color = [0.8,0.2,0.2];
	}

	if(cl_navmesh_polies[poly_index].vert_count == 3)
	{
		cl_navmesh_draw_tri(a,b,c,face_color,face_alpha,TRUE);
	}
	else
	{
		vector d = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[3]].pos;
		cl_navmesh_draw_quad(a,b,c,d,face_color,face_alpha,TRUE);
	}
}


// Calculates world-space coordinate of traversal endpoint
vector cl_navmesh_get_traversal_midpoint(float traversal_index) {
	vector start_pos = cl_navmesh_traversals[traversal_index].start_pos;
	vector midpoint_pos = cl_navmesh_traversals[traversal_index].midpoint_pos;
	// vector end_pos = cl_navmesh_traversals[traversal_index].end_pos;
	float angle = cl_navmesh_traversals[traversal_index].angle;
	// Midpoint / endpoint pos are relative to start_pos:
	makevectors([0, angle, 0]);
	midpoint_pos = start_pos + (v_right * midpoint_pos.x) + (v_forward * midpoint_pos.y) + (v_up * midpoint_pos.z);
	// end_pos = start_pos + (v_right * end_pos.x) + (v_forward * end_pos.y) + (v_up * end_pos.z);
	return midpoint_pos;
}

// Calculates world-space coordinate of traversal midpoint
vector cl_navmesh_get_traversal_end_pos(float traversal_index) {
	vector start_pos = cl_navmesh_traversals[traversal_index].start_pos;
	// vector midpoint_pos = cl_navmesh_traversals[traversal_index].midpoint_pos;
	vector end_pos = cl_navmesh_traversals[traversal_index].end_pos;
	float angle = cl_navmesh_traversals[traversal_index].angle;
	// Midpoint / endpoint pos are relative to start_pos:
	makevectors([0, angle, 0]);
	// midpoint_pos = start_pos + (v_right * midpoint_pos.x) + (v_forward * midpoint_pos.y) + (v_up * midpoint_pos.z);
	end_pos = start_pos + (v_right * end_pos.x) + (v_forward * end_pos.y) + (v_up * end_pos.z);
	return end_pos;
}



void cl_navmesh_draw_traversal(float traversal_index) {
	vector start_pos = cl_navmesh_traversals[traversal_index].start_pos;
	vector midpoint_pos = cl_navmesh_traversals[traversal_index].midpoint_pos;
	vector end_pos = cl_navmesh_traversals[traversal_index].end_pos;
	float angle = cl_navmesh_traversals[traversal_index].angle;

	// Midpoint / endpoint pos are relative to start_pos:
	makevectors([0, angle, 0]);
	midpoint_pos = start_pos + (v_right * midpoint_pos.x) + (v_forward * midpoint_pos.y) + (v_up * midpoint_pos.z);
	end_pos = start_pos + (v_right * end_pos.x) + (v_forward * end_pos.y) + (v_up * end_pos.z);

	vector active_color = '0 1 1';
	vector inactive_color = '0.5 0 0';
	vector edge_color = '0.8 0.8 0.8';
	float active_alpha = 0.4;
	float inactive_alpha = 0.2;
	float edge_alpha = 0.3;
	float edge_width = 0.1;

	if(cl_navmesh_selected_traversal != traversal_index) {
		active_alpha = 0.4;
		inactive_alpha = 0.0;
		edge_alpha = 0.4;
		edge_color = '0 0.2 0.5';
		active_color = '0 0.2 0.5';
	}

	cl_navmesh_draw_box(start_pos, [4,4,4], active_color, 0.8);
	cl_navmesh_draw_box(end_pos, [4,4,4], active_color, 0.8);

	if(cl_navmesh_traversals[traversal_index].use_midpoint) {
		cl_navmesh_draw_box(midpoint_pos, [4,4,4], active_color, active_alpha);
		cl_navmesh_draw_line_3d(start_pos, midpoint_pos, edge_width, edge_color, active_alpha);
		cl_navmesh_draw_line_3d(midpoint_pos, end_pos, edge_width, edge_color, edge_alpha);
	}
	else {
		cl_navmesh_draw_box(midpoint_pos, [4,4,4], inactive_color, inactive_alpha);
		cl_navmesh_draw_line_3d(start_pos, end_pos, edge_width, edge_color, edge_alpha);
	}

	// Draw arrows along edge:
	vector arrow_pos;
	float arrowhead_length = 2;
	vector v_f;
	vector v_r;
	vector v_u;
	float inc = 0.09;
	float start = inc * (time % 1.0);

	for(float t = start; t <= 1.0; t += inc) {
		if(cl_navmesh_traversals[traversal_index].use_midpoint) {
			if(t < 0.5) {
				arrow_pos = start_pos + 2.0 * t * (midpoint_pos - start_pos);
				v_f = normalize(midpoint_pos - start_pos);
				v_r = normalize(crossproduct(v_f, '0 0 1'));
				v_u = normalize(crossproduct(v_r, v_f));
			}
			else {
				arrow_pos = midpoint_pos + 2.0 * (t - 0.5) * (end_pos - midpoint_pos);
				v_f = normalize(end_pos - midpoint_pos);
				v_r = normalize(crossproduct(v_f, '0 0 1'));
				v_u = normalize(crossproduct(v_r, v_f));
			}
		}
		else {
			arrow_pos = start_pos + t * (end_pos - start_pos);
			v_f = normalize(end_pos - start_pos);
			v_r = normalize(crossproduct(v_f, '0 0 1'));
			v_u = normalize(crossproduct(v_r, v_f));
		}

		cl_navmesh_draw_line_3d(arrow_pos, arrow_pos + arrowhead_length * (-v_f - v_r), edge_width, edge_color, edge_alpha);
		cl_navmesh_draw_line_3d(arrow_pos, arrow_pos + arrowhead_length * (-v_f + v_r), edge_width, edge_color, edge_alpha);
	}

	// Traversal edit mode modifications:
	if(cl_navmesh_selected_traversal == traversal_index) {
		if(cl_navmesh_traversal_edit_mode) {
			vector pos = '0 0 0';
			if(cl_navmesh_traversal_editor_cur_point == 0) {
				pos = start_pos;
			}
			else if(cl_navmesh_traversal_editor_cur_point == 1) {
				pos = midpoint_pos;
			}
			else if(cl_navmesh_traversal_editor_cur_point == 2) {
				pos = end_pos;
			}

			float g = 2; // gap from center
			float l = 1.5; // line length
			vector select_color = '1 1 0';
			float select_width = 0.1; // line width
			float select_alpha = 0.8;

			// FTL
			cl_navmesh_draw_line_3d(pos + [-g, -g, g], pos + [-g, -g, g] + [l,0,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [-g, -g, g], pos + [-g, -g, g] + [0,l,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [-g, -g, g], pos + [-g, -g, g] + [0,0,-l] , select_width, select_color, select_alpha);
			// FTR
			cl_navmesh_draw_line_3d(pos + [g, -g, g], pos + [g, -g, g] + [-l,0,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [g, -g, g], pos + [g, -g, g] + [0,l,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [g, -g, g], pos + [g, -g, g] + [0,0,-l] , select_width, select_color, select_alpha);
			// BTL
			cl_navmesh_draw_line_3d(pos + [-g, g, g], pos + [-g, g, g] + [l,0,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [-g, g, g], pos + [-g, g, g] + [0,-l,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [-g, g, g], pos + [-g, g, g] + [0,0,-l] , select_width, select_color, select_alpha);
			// BTR
			cl_navmesh_draw_line_3d(pos + [g, g, g], pos + [g, g, g] + [-l,0,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [g, g, g], pos + [g, g, g] + [0,-l,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [g, g, g], pos + [g, g, g] + [0,0,-l] , select_width, select_color, select_alpha);
			// FBL
			cl_navmesh_draw_line_3d(pos + [-g, -g, -g], pos + [-g, -g, -g] + [l,0,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [-g, -g, -g], pos + [-g, -g, -g] + [0,l,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [-g, -g, -g], pos + [-g, -g, -g] + [0,0,l] , select_width, select_color, select_alpha);
			// FBR 
			cl_navmesh_draw_line_3d(pos + [g, -g, -g], pos + [g, -g, -g] + [-l,0,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [g, -g, -g], pos + [g, -g, -g] + [0,l,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [g, -g, -g], pos + [g, -g, -g] + [0,0,l] , select_width, select_color, select_alpha);
			// BBL
			cl_navmesh_draw_line_3d(pos + [-g, g, -g], pos + [-g, g, -g] + [l,0,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [-g, g, -g], pos + [-g, g, -g] + [0,-l,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [-g, g, -g], pos + [-g, g, -g] + [0,0,l] , select_width, select_color, select_alpha);
			// BBR
			cl_navmesh_draw_line_3d(pos + [g, g, -g], pos + [g, g, -g] + [-l,0,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [g, g, -g], pos + [g, g, -g] + [0,-l,0] , select_width, select_color, select_alpha);
			cl_navmesh_draw_line_3d(pos + [g, g, -g], pos + [g, g, -g] + [0,0,l] , select_width, select_color, select_alpha);
		}
	}
}

float cl_navmesh_is_vert_selected(float vert_index)
{
	for(float i = 0; i < selected_vert_count; i++)
	{
		if(selected_verts[i] == vert_index)
			return TRUE;
	}
	return FALSE;
}


void() cl_navmesh_pathfind_draw_result_path;
void() cl_navmesh_pathfind_draw_result_portals;
void() cl_navmesh_pathfind_draw_result_point_path;



void cl_navmesh_editor_draw() {	
	for(float i = 0; i < cl_navmesh_vert_count; i++) {
		vector color = [0,0,1];
		if(cl_navmesh_is_vert_selected(i)) {
			color = [1,1,0];
		}
			
		cl_navmesh_draw_vert(cl_navmesh_verts[i].pos,color,0.4 );
	}
	
	for(float i = 0; i < cl_navmesh_poly_count; i++) {
		cl_navmesh_draw_poly(i);
	}


	for(float i = 0; i < cl_navmesh_traversal_count; i++) {
		cl_navmesh_draw_traversal(i);
	}
	
	cl_navmesh_draw_test_ent(startent_pos, [1,1,1], [0,1,0], 0.4);
	cl_navmesh_draw_test_ent(goalent_pos, [1,1,1], [1,0,0], 0.4);
	
	cl_navmesh_pathfind_draw_result_path();
	cl_navmesh_pathfind_draw_result_portals();
	cl_navmesh_pathfind_draw_result_point_path();
	
	
	//The following code block is for detecting and placing waypoints at bsp map corners
	if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_PLACING || cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_CONFIRM)
	{
		
		//vector vorg = getentity(player_localentnum, GE_ORIGIN);
		//vector vorg = getviewprop(VF_ORIGIN) - VEC_VIEW_OFS;
		vector vorg = getviewprop(VF_ORIGIN);
		vector vang = getviewprop(VF_ANGLES);
	
		vector vang_left1 = vang + [0,6,0];//Two degrees to the left
		vector vang_left2 = vang + [0,5,0];//Three degrees to the left
		vector vang_right1 = vang + [0,-6,0];//Two degrees to the right
		vector vang_right2 = vang + [0,-5,0];//Three degrees to the right
		
		makevectors(vang);
		vector vang_fwd = v_forward;
		
		makevectors(vang_left1);
		vector vang_left1_fwd = v_forward;
		//Trace out to wall
		tracebox(vorg,VEC_HULL_MIN,VEC_HULL_MAX,vorg+(vang_left1_fwd * 2000),1,self);
		vector wall_hit_left1 = vorg+(vang_left1_fwd * 2000)*trace_fraction;
		//Trace down to ground
		tracebox(wall_hit_left1,VEC_HULL_MIN,VEC_HULL_MAX,wall_hit_left1+([0,0,-1] * 2000),1,self);
		
		vector hit_left1 = wall_hit_left1 + (([0,0,-1] * 2000) * trace_fraction);
		
		makevectors(vang_left2);
		vector vang_left2_fwd = v_forward;
		//Trace out to wall
		tracebox(vorg,VEC_HULL_MIN,VEC_HULL_MAX,vorg+(vang_left2_fwd * 2000),1,self);
		vector wall_hit_left2 = vorg+(vang_left2_fwd * 2000)*trace_fraction;
		//Trace down to ground
		tracebox(wall_hit_left2,VEC_HULL_MIN,VEC_HULL_MAX,wall_hit_left2+([0,0,-1] * 2000),1,self);
		
		vector hit_left2 = wall_hit_left2 + (([0,0,-1] * 2000) * trace_fraction);
		
		
		makevectors(vang_right1);
		vector vang_right1_fwd = v_forward;
		//Trace out to wall
		tracebox(vorg,VEC_HULL_MIN,VEC_HULL_MAX,vorg+(vang_right1_fwd * 2000),1,self);
		vector wall_hit_right1 = vorg+(vang_right1_fwd * 2000)*trace_fraction;
		//Trace down to ground
		tracebox(wall_hit_right1,VEC_HULL_MIN,VEC_HULL_MAX,wall_hit_right1+([0,0,-1] * 2000),1,self);
		
		vector hit_right1 = wall_hit_right1 + (([0,0,-1] * 2000) * trace_fraction);
		
		
		makevectors(vang_right2);
		vector vang_right2_fwd = v_forward;
		//Trace out to wall
		tracebox(vorg,VEC_HULL_MIN,VEC_HULL_MAX,vorg+(vang_right2_fwd * 2000),1,self);
		vector wall_hit_right2 = vorg+(vang_right2_fwd * 2000)*trace_fraction;
		//Trace down to ground
		tracebox(wall_hit_right2,VEC_HULL_MIN,VEC_HULL_MAX,wall_hit_right2+([0,0,-1] * 2000),1,self);
		
		vector hit_right2 = wall_hit_right2 + (([0,0,-1] * 2000) * trace_fraction);
		
		cl_navmesh_draw_vert(hit_left1, [0,0,1],0.4 );
		cl_navmesh_draw_vert(hit_left2, [0,0,1],0.4 );
		cl_navmesh_draw_vert(hit_right1, [0,0,1],0.4 );
		cl_navmesh_draw_vert(hit_right2, [0,0,1],0.4 );

		// Draw walls that we have hit (2 flat planes on the walls we hit)
		vector up = [0,0,1];
		vector left_wall_pos = (hit_left1 + hit_left2) * 0.5;
		vector left_wall_nor = -1 * crossproduct(hit_left1 - hit_left2, up);

		vector right_wall_pos = (hit_right1 + hit_right2) * 0.5;
		vector right_wall_nor = -1 * crossproduct(hit_right1 - hit_right2, up);

		cl_navmesh_draw_plane(left_wall_pos, left_wall_nor, 50, [0,1,1], 0.1);
		cl_navmesh_draw_plane(right_wall_pos, right_wall_nor, 50, [1,0,1], 0.1);
		
		
		//===================== Calculate the resolved vertex pos =======================
		//This solution only works for 90 degree corners
		
		//Line 1 extends from l1a in direction l1_dir
		/*vector l1a;
		l1a = hit_left2;
		vector l1_dir = normalize(hit_left1 - l1a);
		//The third point
		vector p2 = hit_right1;
		
		//Considering only l1_dir in the 2d plane of z=0
		
		vector vert_loc;
		vert_loc.z = l1a.z;
		
		//Is the line vertical?
		if(l1_dir.x == 0)//Is the line vertical?
		{
			vert_loc.x = l1a.x;
			vert_loc.y = p2.y;
			//FIXME
		}
		else if(l1_dir.y == 0)//Is the line horizontal?
		{
			vert_loc.x = p2.x;
			vert_loc.y = l1a.y;
			//FIXME
		}
		else
		{
			//Getting slope of line 1
			float m = (hit_left1.y - hit_left2.y) / (hit_left1.x - hit_left2.x);
			
			float x1 = p2.x - l1a.x;
			float y1 = p2.y - l1a.y;
			
			vert_loc.x = (x1 + m*y1)/(m*m + 1);
			vert_loc.y = (-1/m) * (vert_loc.x-x1) + y1;
		}
		
		vert_loc.x += l1a.x;
		vert_loc.y += l1a.y;*/
		
		
		//===============================================================================
		//This solution should work with any corner
		//===============================================================================
		
		//Line 1: hit_left1 -> hit_left2
		//Line 2: hit_right1 -> hit_right2
		vector vert_loc;
		
		float skew = 0;
		float horizontal = 1;
		float vertical = 2;
		
		float line_1_orient = skew;
		float line_2_orient = skew;
		
		//Check left wall is horizontal
		if(hit_left1.y == hit_left2.y)
		{
			line_1_orient = horizontal;
		}
		//Check if the left wall is vertical
		else if(hit_left1.x == hit_left2.x)
		{
			line_1_orient = vertical;
		}
		
		//Check if the right wall is horizontal
		if(hit_right1.y == hit_right2.y)
		{
			line_2_orient = horizontal;
		}
		//Check if the right wall is vertical
		else if(hit_right1.x == hit_right2.x)
		{
			line_2_orient = vertical;
		}
		
		//Checking if the lines are parallel and not skew
		if(line_1_orient == line_2_orient && line_1_orient != skew)
		{
			if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_CONFIRM)
			{
				print("Cannot place corner for parallel walls (there is no corner).\n");
				cl_navmesh_place_corner_state = NAVMESH_PLACE_CORNER_PLACING;
			}
			return;
		}
		
		//Checking other special cases
		else if(line_1_orient == horizontal && line_2_orient == vertical)
		{
			vert_loc.x = hit_right1.x;
			vert_loc.y = hit_left1.y;
		}
		else if(line_1_orient == vertical && line_2_orient == horizontal)
		{
			vert_loc.x = hit_left1.x;
			vert_loc.y = hit_right1.y;
		}
		else if(line_1_orient == vertical)//line 2 is skew
		{
			vert_loc.x = hit_left1.x;
			//Plugging in vert_loc.x into equation of line 2 to get vert_loc.y
			//Slope of line 2
			float m2_a = (hit_right2.y - hit_right1.y)/(hit_right2.x - hit_right1.x);
			vert_loc.y = m2_a*(vert_loc.x - hit_right1.x) + hit_right1.y;
		}

		else if(line_2_orient == vertical)//line 1 is skew
		{
			vert_loc.x = hit_right1.x;
			//P;ugging in vert_loc.x into equation of line 1 to get vert_loc.y
			//Slope of line 1
			float m1_a = (hit_left2.y - hit_left1.y)/(hit_left2.x - hit_left1.x);
			vert_loc.y = m1_a*(vert_loc.x - hit_left1.x) + hit_left1.y;
		}
		else//Both lines are skew or horizontal
		{
			//Slope of line 1
			float m1 = (hit_left2.y - hit_left1.y)/(hit_left2.x - hit_left1.x);
			//Slope of line 2
			float m2 = (hit_right2.y - hit_right1.y)/(hit_right2.x - hit_right1.x);
			
			//Checking if the walls are parallel
			if(m1 == m2)
			{
				if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_CONFIRM)
				{
					print("Cannot place corner for skew parallel walls (there is no corner).\n");
					cl_navmesh_place_corner_state = NAVMESH_PLACE_CORNER_PLACING;
				}
				return;
			}
			
			//Resolving the corner vertex location (this is derived from the solution of the two lines)
			vert_loc.x = ((m1 * hit_left1.x) - (m2 * hit_right1.x) + hit_right1.y - hit_left1.y) / (m1 - m2);
			//Plugging in vert_loc.x to the equation of the first line to get vert_loc.y
			vert_loc.y = m1*(vert_loc.x - hit_left1.x) + hit_left1.y;
		}
		
		//Placing the vert as the highest z-value
		float highest_z = hit_left1.z;
		
		if(hit_left2.z > highest_z)
			highest_z = hit_left2.z;
		if(hit_right1.z > highest_z)
			highest_z = hit_right1.z;
		if(hit_right2.z > highest_z)
			highest_z = hit_right2.z;
		vert_loc.z = highest_z;
		
		//Traceboxing down from that vert position to get actual height
		tracebox(vert_loc,VEC_HULL_MIN,VEC_HULL_MAX,vert_loc+([0,0,-1] * 2000),1,self);
		vert_loc.z = vert_loc.z + (-2000 * trace_fraction);
		
		
		//================================================================================
		
		//Render the resolved vertex pos
		cl_navmesh_draw_vert(vert_loc, [1,1,0],0.4 );

		// Draw a vertical line at the resolved vert pos:
		cl_navmesh_draw_box(vert_loc, [0.5, 0.5, 120], [1,1,1], 0.05);



			
		if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_CONFIRM)
		{	
			cl_navmesh_verts[cl_navmesh_vert_count].pos.x = vert_loc.x;
			cl_navmesh_verts[cl_navmesh_vert_count].pos.y = vert_loc.y;
			cl_navmesh_verts[cl_navmesh_vert_count].pos.z = vert_loc.z;
			
			cl_navmesh_vert_count++;
			
			cl_navmesh_place_corner_state = 0;
		}
		
	}
	
	//For using tracebox to place vertices
	/*vector vorg = getviewprop(VF_ORIGIN);
	vector vang = getviewprop(VF_ANGLES);
	
	makevectors(vang);
	
	//v_forward, v_right, v_up
	getviewprop(VF_ACTIVESEAT);
	
	//Tracebox out from there
	//Zombie dimensions
	tracebox(vorg,[-8,-8,-32],[8,8,30],vorg+(v_forward * 2000),1,self);
	
	
	//Tracebox down from there
	vector vpos1 = vorg+(v_forward*2000)*trace_fraction;
	cl_navmesh_draw_vert(vpos1, [0,0,1],0.4 );
	
	tracebox(vpos1,[-8,-8,-32],[8,8,30],vpos1+([0,0,-1] * 2000),1,self);
	vector vpos2 = vpos1+(([0,0,-1] * 2000) * trace_fraction);
	
	cl_navmesh_draw_vert(vpos2, [1,1,0],0.4 );*/
	
	//Tracebox down from there	
}

//Places a vertex at player position
void cl_navmesh_place_vert()
{
	if(cl_navmesh_vert_count >= NAV_MAX_VERTS)
	{
		print("Can't add vertex, max vert count has been reached.\n");
		return;
	}
	
	//Placing the vert at player origin
	vector vert_pos = getentity(player_localentnum, GE_ORIGIN);
	
	cl_navmesh_verts[cl_navmesh_vert_count].pos.x = vert_pos.x;
	cl_navmesh_verts[cl_navmesh_vert_count].pos.y = vert_pos.y;
	cl_navmesh_verts[cl_navmesh_vert_count].pos.z = vert_pos.z;

	print("Vertex ");
	print(ftos(cl_navmesh_vert_count));
	print(" created at ", vtos(vert_pos),"\n");
	
	cl_navmesh_vert_count++;
}

//Deletes all selected vertices
void cl_navmesh_delete_verts() 
{
	if(selected_vert_count <= 0)
	{
		print("No vertices selected.\n");
		return;
	}
	
	for(float i = 0; i < selected_vert_count; i++)
	{
		float vert = selected_verts[i];
		print("Deleting vert: ");
		print(ftos(vert));
		print(".\n");
		//Check if vertex is in any polygons, if so delete that polygon
		for(float j = 0; j < cl_navmesh_poly_count; j++)
		{
			for(float k = 0; k < cl_navmesh_polies[j].vert_count; k++)
			{
				if(cl_navmesh_polies[j].verts[k] == vert)
				{
					cl_navmesh_delete_poly_at_index(j);	
					j -= 1;
					break;
			}
		}
		}
		
		
		//Bringing all vertices down to not leave any holes in the array
		//Moving down every index to the right of what we deselected to not leave any holes
		for(float j = vert; j < cl_navmesh_vert_count - 1; j++)
		{
			cl_navmesh_verts[j].pos.x = cl_navmesh_verts[j+1].pos.x;
			cl_navmesh_verts[j].pos.y = cl_navmesh_verts[j+1].pos.y;
			cl_navmesh_verts[j].pos.z = cl_navmesh_verts[j+1].pos.z;
		}
		//Clearing the last one
		cl_navmesh_verts[cl_navmesh_vert_count-1].pos = [0,0,0];
		cl_navmesh_vert_count--;
		
		
		//Fixing references to verts in all polygons
		for(float j = 0; j < cl_navmesh_poly_count; j++)
		{
			for(float k = 0; k < cl_navmesh_polies[j].vert_count; k++)
			{
				if(cl_navmesh_polies[j].verts[k] >= vert)
					cl_navmesh_polies[j].verts[k]--;
			}
		}
		//Fixing references of selected verts
		for(float j = i; j < selected_vert_count; j++)
		{
			if(selected_verts[j] >= vert)
				selected_verts[j]--;
		}
	}
	selected_vert_count = 0;
	for(float i = 0; i < NAV_MAX_SELECTED_VERTS; i++)
	{
		selected_verts[i] = -1;
	}
}


//=================================== Navmesh vertex selection functions ===================================
//Returns index of the vertex that is nearest to the player
float cl_navmesh_get_nearest_vert()
{
	if(cl_navmesh_vert_count <= 0)
	{
		return -1;
	}
	
	vector player_pos = getentity(player_localentnum, GE_ORIGIN);
	float closest_dist = vlen(player_pos - cl_navmesh_verts[0].pos);
	float closest_index = 0;
	
	float temp_dist;
	
	for(float i = 1; i < cl_navmesh_vert_count; i++)
	{
		temp_dist = vlen(player_pos - cl_navmesh_verts[i].pos);
		
		if(temp_dist < closest_dist)
		{
			closest_dist = temp_dist;
			closest_index = i;
		}
	}
	return closest_index;
}

//Selects the nearest vertex
void cl_navmesh_select_vert()
{
	if(selected_vert_count >= NAV_MAX_SELECTED_VERTS)
	{
		print("Can't select another vertex, max vertices selected.\n");
		return;
	}
	
	float vert = cl_navmesh_get_nearest_vert();
	if(vert == -1)
	{
		print("No vertices to select");
		return;
	}
	if(cl_navmesh_is_vert_selected(vert))
	{
		print("Vert is already selected.\n");
		return;
	}
	
	print("Vertex ");
	print(ftos(vert));
	print(" selected.\n");
	selected_verts[selected_vert_count++] = vert;
}


//Deselects the nearest vertex
void cl_navmesh_deselect_vert()
{
	float vert = cl_navmesh_get_nearest_vert();
	
	if(vert == -1)
	{
		print("No vertices to select.\n");
		return;
	}
	
	for(float i = 0; i < selected_vert_count; i++)
	{
		if(selected_verts[i] == vert)
		{
			print("Vertex ");
			print(ftos(selected_verts[i]));
			print(" deselected.\n");
			// Clear selected vert
			selected_verts[i] = -1;			
			//Moving down every index to the right of what we deselected to not leave any holes
			for(float j = i; j < selected_vert_count - 1; j++)
			{
				selected_verts[j] = selected_verts[j+1];
			}
			selected_verts[selected_vert_count - 1] = -1;
			selected_vert_count--;
			
			return;
		}
	}
	print("Vertex is not selected.\n");
}

//Deselects all vertices
void cl_navmesh_deselect_all()
{
	for(float i = 0; i < NAV_MAX_SELECTED_VERTS; i++)
	{
		selected_verts[i] = -1;
	}
	selected_vert_count = 0;

	cl_navmesh_selected_traversal = -1;
	cl_navmesh_traversal_edit_mode = false;
	cl_navmesh_traversal_editor_cur_point = 0;
	//print("All vertices deselected.\n");
}

//=============================================================================================================

// Returns the index of the currently selected polygon
// Otherwise, returns -1
int cl_navmesh_get_selected_poly()
{
	//Check if this polygon already exists
	float verts_selected[4];
	
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		verts_selected[0] = FALSE;
		verts_selected[1] = FALSE;
		verts_selected[2] = FALSE;
		verts_selected[3] = FALSE;
		
		//Check each of the poly's verts
		for(float j = 0; j < cl_navmesh_polies[i].vert_count; j++)
		{
			//Check each of our selected verts to see if they are in this polygon
			for(float k = 0; k < selected_vert_count; k++)
			{
				if(cl_navmesh_polies[i].verts[j] == selected_verts[k])
				{
					verts_selected[j] = TRUE;
				}
			}
			
			//This poly vert was not selected
			if(verts_selected[j] == FALSE)
			{
				break;
			}
		}
		
		if(cl_navmesh_polies[i].vert_count == 3)
		{
			if(verts_selected[0] == TRUE && verts_selected[1] == TRUE && verts_selected[2] == TRUE)
			{
				return i;
			}
		}
		else if(cl_navmesh_polies[i].vert_count == 4)
		{
			if(verts_selected[0] == TRUE && verts_selected[1] == TRUE && verts_selected[2] == TRUE && verts_selected[3] == TRUE)
			{
				return i;
			}
		}
	}
	return -1;
}


void cl_navmesh_make_poly()
{
	if(selected_vert_count < 3)
	{
		print("Not enough selected vertices to make a polygon (need 3).\n");
		return;
	}
	
	if(cl_navmesh_poly_count >= NAV_MAX_POLIES)
	{
		print("Max polygon count reached.\n");
		return;
	}
	
	if(cl_navmesh_get_selected_poly() != -1) {
		print("This polygon already exists.\n");
		return;
	}
	
	
	//Sorting the verts so the polygon is build consecutively (i.e. vert 0 -> vert 1 is an edge, 1->2, 2->3, and 3->0 are all edges)
	//Furthermore, this sorting will ensure the verts are sorted in a counter clockwise order, so we also apply it to tris
	

	//Printing all polygon vertices
	print("Selected Verts: [");
	for(float j = 0; j < selected_vert_count; j++)
	{
		print("(",ftos(j),", ",ftos(selected_verts[j]),", ",vtos(cl_navmesh_verts[selected_verts[j]].pos),") , ");
	}
	print("]\n\n");
	
	//Calculating center of the polygon
	local vector center = [0,0,0];
	for(float j = 0; j < selected_vert_count; j++)
	{
		center += cl_navmesh_verts[selected_verts[j]].pos;
	}
	center /= selected_vert_count;
	
	print("Center of selected polygon: ",vtos(center),".\n\n");
	
	float vert_angle[NAV_MAX_SELECTED_VERTS];
	
	//For suppressing uninitialised vert_angle compiler warning
	vert_angle[0] = 0;
	
	//Calculating vertex angles:
	for(float j = 0; j < selected_vert_count; j++) {
		//Calculating angle of vert
		vert_angle[j] = atan2(cl_navmesh_verts[selected_verts[j]].pos.y - center.y,cl_navmesh_verts[selected_verts[j]].pos.x - center.x);
	}
	
	//Sorting from least to greatest
	for(float j = 0; j < selected_vert_count; j++) {
		//Finding lowest value from j to selected_vert_count
		float lowest_value = vert_angle[j];
		float lowest_index = j;
		for(float k = j; k < selected_vert_count; k++) {
			if(vert_angle[k] < lowest_value) {
				lowest_value = vert_angle[k];
				lowest_index = k;
			}
		}
		//Swapping the lowest value with index j
		float temp_angle = vert_angle[j];
		vert_angle[j] = vert_angle[lowest_index];
		vert_angle[lowest_index] = temp_angle;
		
		float temp_vert = selected_verts[j];
		selected_verts[j] = selected_verts[lowest_index];
		selected_verts[lowest_index] = temp_vert;
	}
	
	//Vert angles
	print("Sorted Verts: [");
	for(float j = 0; j < selected_vert_count; j++) {
		print("(",ftos(j),", ",ftos(selected_verts[j]),", ",vtos(cl_navmesh_verts[selected_verts[j]].pos),") ,");
	}
	print("]\n\n");
	
	print("Sorted Vert angles: [");
	for(float j = 0; j < selected_vert_count; j++) {
		print(", ",ftos(vert_angle[j]));
	}
	print("]\n\n");

	// Verify that the polygon is concave.
	for(int i = 0; i < selected_vert_count; i++) {
		vector prev_vert_pos = cl_navmesh_verts[selected_verts[(i + selected_vert_count - 1) % selected_vert_count]].pos;
		vector vert_pos = cl_navmesh_verts[selected_verts[i]].pos;
		vector next_vert_pos = cl_navmesh_verts[selected_verts[(i + 1) % selected_vert_count]].pos;

		// For the polygon to be concave, next_vert _must_ be to the left of the line prev_vert -> vert
		if(pathfind_point_is_to_left(prev_vert_pos, vert_pos, next_vert_pos) <= 0) {
			print("Specified polygon is not concave.\n");
			print("\tprev vert: ", ftos(selected_verts[(i + selected_vert_count - 1) % selected_vert_count]), "\n");
			print("\tvert: ", ftos(selected_verts[(i) % selected_vert_count]), "\n");
			print("\tnext vert: ", ftos(selected_verts[(i + 1) % selected_vert_count]), "\n");
			return;
		}
	}
	
	

	for(float i = 0; i < selected_vert_count; i++)
	{
		cl_navmesh_polies[cl_navmesh_poly_count].verts[i] = selected_verts[i];
	}
	cl_navmesh_polies[cl_navmesh_poly_count].vert_count = selected_vert_count;
	cl_navmesh_poly_count++;
}

void cl_navmesh_delete_poly_at_index(float poly_index)
{
	//Starting at this polygon, move every polygon after in the array down one (leave no holes in the array)
	//Moving down every index to the right of what we deselected to not leave any holes
	for(float i = poly_index; i < cl_navmesh_poly_count - 1; i++)
	{
		// Copy down the verts
		cl_navmesh_polies[i].vert_count = cl_navmesh_polies[i+1].vert_count;
		for(float j = 0; j < cl_navmesh_polies[i].verts.length; j++)
		{
			cl_navmesh_polies[i].verts[j] = cl_navmesh_polies[i+1].verts[j];
		}

		// Copy down other fields:
		cl_navmesh_polies[i].doortarget = cl_navmesh_polies[i+1].doortarget;

	}
	//Clear the last polygon in the list
	cl_navmesh_polies[cl_navmesh_poly_count-1].vert_count = 0;
	for(float j = 0; j < cl_navmesh_polies[cl_navmesh_poly_count-1].verts.length; j++)
	{
		cl_navmesh_polies[cl_navmesh_poly_count-1].verts[j] = -1;
	}
	cl_navmesh_polies[cl_navmesh_poly_count-1].doortarget = "";

	cl_navmesh_poly_count--;
}

void cl_navmesh_delete_poly()
{
	float verts_selected[4];
	float poly_index = -1;
	//Find index of the polygon whose vertices are all selected
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		verts_selected[0] = FALSE;
		verts_selected[1] = FALSE;
		verts_selected[2] = FALSE;
		verts_selected[3] = FALSE;
		
		//Check each of the poly's verts
		for(float j = 0; j < cl_navmesh_polies[i].vert_count; j++)
		{
			//Check each of our selected verts to see if they are in this polygon
			for(float k = 0; k < selected_vert_count; k++)
			{
				if(cl_navmesh_polies[i].verts[j] == selected_verts[k])
				{
					verts_selected[j] = TRUE;
				}
			}
			
			//This poly vert was not selected
			if(verts_selected[j] == FALSE)
			{
				break;
			}
		}
		
		if(cl_navmesh_polies[i].vert_count == 3)
		{
			if(verts_selected[0] == TRUE && verts_selected[1] == TRUE && verts_selected[2] == TRUE)
			{
				poly_index = i;
				break;
			}
		}
		else if(cl_navmesh_polies[i].vert_count == 4)
		{
			if(verts_selected[0] == TRUE && verts_selected[1] == TRUE && verts_selected[2] == TRUE && verts_selected[3] == TRUE)
			{
				poly_index = i;
				break;
			}
		}
	}
	if(poly_index == -1)
	{
		print("A polygon is not selected.\n");
		return;
	}

	cl_navmesh_delete_poly_at_index(poly_index);	
	print("Deleted polygon.\n");
}

//Treats 1st and 2nd selected verts as line 1, 3rd and 4th verts as line 2, places a new vertex at the intersection of these lines
void cl_navmesh_resolve_corner()
{
	if(selected_vert_count < 3)
	{
		print("You need to select at least 3 vertices to resolve a corner.\n");
		return;
	}
	
	//Line 1 extends from l1a in direction l1_dir
	vector l1a;
	l1a = cl_navmesh_verts[selected_verts[0]].pos;
	vector l1_dir = normalize(cl_navmesh_verts[selected_verts[1]].pos - l1a);
	//The third point
	vector p2 = cl_navmesh_verts[selected_verts[2]].pos;
	
	
	//Considering only l1_dir in the 2d plane of z=0
	
	vector vert_loc;
	vert_loc.z = l1a.z;
	
	//Is the line vertical?
	if(l1_dir.x == 0)//Is the line vertical?
	{
		vert_loc.x = l1a.x;
		vert_loc.y = p2.y;
	}
	else if(l1_dir.y == 0)//Is the line horizontal?
	{
		vert_loc.x = p2.x;
		vert_loc.y = l1a.y;
	}
	else
	{
		//Getting slope of line 1
		float m = l1_dir.y / l1_dir.x;
		
		float x1 = p2.x - l1a.x;
		float y1 = p2.y - l1a.y;
		
		vert_loc.x = (x1 + m*y1)/(m*m + 1);
		vert_loc.y = (-1/m) * (vert_loc.x-x1) + y1;
	}
	
	vert_loc.x += l1a.x;
	vert_loc.y += l1a.y;
	
	
	//Place a new vert at the location
	cl_navmesh_verts[cl_navmesh_vert_count].pos.x = vert_loc.x;
	cl_navmesh_verts[cl_navmesh_vert_count].pos.y = vert_loc.y;
	cl_navmesh_verts[cl_navmesh_vert_count].pos.z = vert_loc.z;
	
	print("Resolved corner with vertex ");
	print(ftos(cl_navmesh_vert_count));
	print(" at (");
	print(ftos(vert_loc.x));
	print(" , ");
	print(ftos(vert_loc.y));
	print(" , ");
	print(ftos(vert_loc.z));
	print(").\n");
	
	
	cl_navmesh_vert_count++;
}

void cl_navmesh_place_corner()
{
	cl_navmesh_place_corner_state = NAVMESH_PLACE_CORNER_PLACING;
}
void cl_navmesh_cancel_corner()
{
	cl_navmesh_place_corner_state = 0;
}
void cl_navmesh_confirm_corner()
{
	if(cl_navmesh_place_corner_state == NAVMESH_PLACE_CORNER_PLACING)
		cl_navmesh_place_corner_state = NAVMESH_PLACE_CORNER_CONFIRM;
}


void cl_navmesh_clear_connected_polies()
{
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		cl_navmesh_polies[i].connected_polies_count = 0;

		for(float j = 0; j < 4; j++)
		{
			cl_navmesh_polies[i].connected_polies[j] = -1;
			cl_navmesh_polies[i].connected_polies_left_vert[j] = -1;
			cl_navmesh_polies[i].connected_polies_right_vert[j] = -1;
			cl_navmesh_polies[i].connected_polies_neighbor_edge_index[j] = -1;
		}

		cl_navmesh_polies[i].connected_traversals_count = 0;
		for(float j = 0; j < NAV_MAX_POLY_TRAVERSALS; j++) {
			cl_navmesh_polies[i].connected_traversals[j] = -1;
		}
	}
}


void cl_navmesh_calc_connected_polies() {
	cl_navmesh_clear_connected_polies();

	for(float i = 0; i < cl_navmesh_poly_count; i++) {
		for(float j = i + 1; j < cl_navmesh_poly_count; j++) {
			
			//Check if poly j shares an edge with poly i
			
			//Edge case: where two opposite corners (two corners not on the same edge) of a quad are shared with another poly
			//but this edge case is a result of terrible topology, so I will not consider it
			
			//Check if poly j shares at least 2 vertices with poly i
			//I'm not sure what sharing more than 2 verts means... but it's a result of bad topology, so I will not consider it
			//		if two quads share 4: they are the same 			-> bad topology
			//		if two quads share 3: one of them is convex, one is concave 	-> bad topology
			//		if a quad shares 3 with a tri: the tri is within the quad 	-> bad topology
			//		if two tris share 3: they are the same 				-> bad topology
			
			
			float shared_vert_ids[2];
			shared_vert_ids[0] = -1;
			shared_vert_ids[1] = -1;

			float poly_i_shared_verts_index[2]; // The index of the vert in the ith polygon's vertex list
			float poly_j_shared_verts_index[2]; // The index of the vert in the ith polygon's vertex list

			poly_i_shared_verts_index[0] = -1;
			poly_i_shared_verts_index[1] = -1;
			poly_j_shared_verts_index[0] = -1;
			poly_j_shared_verts_index[1] = -1;
			float verts_found = 0;
				
			for(float k = 0; k < cl_navmesh_polies[i].vert_count; k++) {
				for(float l = 0; l < cl_navmesh_polies[j].vert_count; l++) {
					if(cl_navmesh_polies[i].verts[k] == cl_navmesh_polies[j].verts[l]) {
						//If we have found more verts than should be allowed, count them for error print
						if(verts_found >= 2) {
							verts_found++;
							continue;
						}
						
						shared_vert_ids[verts_found] = cl_navmesh_polies[i].verts[k];
						poly_i_shared_verts_index[verts_found] = k;
						poly_j_shared_verts_index[verts_found] = l;
						verts_found++;
					}
				}
			}
			
			//Print a warning if more than 2, should be impossible
			if(verts_found > 2) {
				print("Warning: polygon ");
				print(ftos(i));
				print(" shares ");
				print(ftos(verts_found));
				print(" vertices with polygon ");
				print(ftos(j));
				print(". There is an issue somewhere.\n");
			}
			else if(verts_found == 2) {
				//Setting the polygons as connected to each other
				if(cl_navmesh_polies[i].connected_polies_count >= 4) {
					print("Warning: polygon ");
					print(ftos(i));
					print(" shares an edge with more than 4 other polygons.\n");
					break;
				}
				if(cl_navmesh_polies[j].connected_polies_count >= 4) {
					print("Warning: polygon ");
					print(ftos(j));
					print(" shares an edge with more than 4 other polygons.\n");
					break;
				}
				cl_navmesh_polies[i].connected_polies[cl_navmesh_polies[i].connected_polies_count] = j;
				cl_navmesh_polies[j].connected_polies[cl_navmesh_polies[j].connected_polies_count] = i;
				
				
				//=======================================================================================
				//Calculating shared edge left / right vertices

				//Calculating from the perspective of moving from poly[i] to poly[j]
				
				//Because polygon's vertices are stored in a ccw winding order:
				//connected polygons must share two consecutive verts.
				//the CCW winding of the triangle dictates that the next shared vertex is to the left of, and in the index after the first shared vertex
				//i.e. of the two consecutive verts shard, the former is to the right, the latter is to the left
				
				//if first one is a quad: shared edge must be, where the first index is right and second index is left
				//3-0, 0-1, 1-2, 2-3
				//if first one is a tri: shared edge must be, where the first index is right and second index is left
				//2-0, 0-1, 1-2
				
				//Two distinct cases:
				//The index of second is one greater than the index of the first
				//OR
				//The index of the first is 0, and index of second is 2 or 3
				
				
				// Sort the vertices to be from left to right when crossing from polygon i to j
				// 
				// let a,b = poly_i_shared_verts_index
				//
				//		0 ---------- 3
				//		| 			 |
				//		| 			 |
				//		| 			 |
				//		| 			 |
				//		1 ---------- 2
				//		
				//		Possible Values:
				// 
				//				b = 0 	b = 1 	b = 2 	b = 3
				//		a = 0	  X		  B		  F		  F
				//		a = 1	  F		  X		  B		  X
				//		a = 2	  B		  F		  X		  B
				//		a = 3	  B		  X		  F		  X
				// 
				//     F -- Forward (a is left vert, b is right vert)
				//     B -- Backward (a is right vert, b is left vert)
				//     X -- Can't happen

				// if(a == (b + 1) % poly_i_vert_count)
				if(poly_i_shared_verts_index[0] == (poly_i_shared_verts_index[1] + 1) % cl_navmesh_polies[i].vert_count) {
					// poly_i_shared_verts_index[0] denotes the left vertex when crossing from i to j
					// poly_i_shared_verts_index[1] denotes the right vertex when crossing from i to j
					// Do nothing
				}
				else {
					// Flip the vert lists so the above is true.
					float temp;
					temp = shared_vert_ids[0];
					shared_vert_ids[0] = shared_vert_ids[1];
					shared_vert_ids[1] = temp;

					temp = poly_i_shared_verts_index[0];
					poly_i_shared_verts_index[0] = poly_i_shared_verts_index[1];
					poly_i_shared_verts_index[1] = temp;

					temp = poly_j_shared_verts_index[0];
					poly_j_shared_verts_index[0] = poly_j_shared_verts_index[1];
					poly_j_shared_verts_index[1] = temp;
				}

				
				//Assigning the link's left/right edges
				cl_navmesh_polies[i].connected_polies_left_vert[cl_navmesh_polies[i].connected_polies_count] = shared_vert_ids[0];
				cl_navmesh_polies[i].connected_polies_right_vert[cl_navmesh_polies[i].connected_polies_count] = shared_vert_ids[1];
				
				//From j to i, left vert is on the right, and right vert is on the left
				cl_navmesh_polies[j].connected_polies_left_vert[cl_navmesh_polies[j].connected_polies_count] = shared_vert_ids[1];
				cl_navmesh_polies[j].connected_polies_right_vert[cl_navmesh_polies[j].connected_polies_count] = shared_vert_ids[0];
				
				// When crossing from polygon i to polygon j, the right-hand vertex index is the edge index for polygon i
				float poly_i_edge_index = poly_i_shared_verts_index[1];
				// When crossing from polygon j to polygon i, the left-hand vertex index is the edge index for polygon j
				float poly_j_edge_index = poly_j_shared_verts_index[0];

				// For polygon i, record which of polygon's j edges we are crossing to get into polygon j
				cl_navmesh_polies[i].connected_polies_neighbor_edge_index[cl_navmesh_polies[i].connected_polies_count] = poly_j_edge_index;
				// For polygon j, record which of polygon's i edges we are crossing to get into polygon i
				cl_navmesh_polies[j].connected_polies_neighbor_edge_index[cl_navmesh_polies[j].connected_polies_count] = poly_i_edge_index;


				cl_navmesh_polies[i].connected_polies_count++;
				cl_navmesh_polies[j].connected_polies_count++;
				//=======================================================================================
				
				// print("Poly ");
				// print(ftos(i));
				// print(" is connected to ");
				// print(ftos(j));
				// print(" and poly ");
				// print(ftos(j));
				// print(" is connected to ");
				// print(ftos(i));
				// print(".\n");
			}	
		}
	}

	for(float i = 0; i < cl_navmesh_traversal_count; i++) {
		print("Checking traversal for connected polies\n");
		makevectors([0, cl_navmesh_traversals[i].angle, 0]);

		// Get start_pos and end_pos in world-space
		vector start_pos = cl_navmesh_traversals[i].start_pos;
		vector end_pos = start_pos + (v_right * cl_navmesh_traversals[i].end_pos.x) + (v_forward * cl_navmesh_traversals[i].end_pos.y) + (v_up * cl_navmesh_traversals[i].end_pos.z);

		float start_pos_poly = -1;
		float end_pos_poly = -1;

		for(float j = 0; j < cl_navmesh_poly_count; j++) {
			if(start_pos_poly == -1 && cl_navmesh_is_inside_poly(start_pos, j)) {
				start_pos_poly = j;
			}
			if(end_pos_poly == -1 && cl_navmesh_is_inside_poly(end_pos, j)) {
				end_pos_poly = j;
			}
			if(start_pos_poly != -1 && end_pos_poly != -1) {
				break;
			}
		}

		print("Traversal ");
		print(ftos(i));
		print(" starts in poly ");
		print(ftos(start_pos_poly));
		print(" and ends in poly ");
		print(ftos(end_pos_poly));
		print("\n");

		if(start_pos_poly == -1) {
			print("Warning: Traversal ");
			print(ftos(i));
			print(" does not start inside of a navmesh polygon. This traversal will not be used.\n");
			continue;
		}
		else if(end_pos_poly == -1) {
			print("Warning: Traversal ");
			print(ftos(i));
			print(" does not end inside of a navmesh polygon. This traversal will not be used.\n");
			continue;
		}
		else if(start_pos_poly == end_pos_poly) {
			print("Warning: Traversal ");
			print(ftos(i));
			print(" starts and ends inside of the same navmesh polygon. This traversal will not be used.\n");
			continue;
		}

		if(cl_navmesh_polies[start_pos_poly].connected_traversals_count >= NAV_MAX_POLY_TRAVERSALS) {
			print("Warning: Traversal ");
			print(ftos(i));
			print(" starts inside of a polygon that is already connected to the maximum number of traversals allowed (");
			print(ftos(NAV_MAX_POLY_TRAVERSALS));
			print("). This traversal will not be used.\n");
			continue;
		}

		// Add to polygon's list of connected traversals
		cl_navmesh_polies[start_pos_poly].connected_traversals[cl_navmesh_polies[start_pos_poly].connected_traversals_count] = i;
		cl_navmesh_polies[start_pos_poly].connected_traversals_count += 1;
		cl_navmesh_traversals[i].end_poly = end_pos_poly;
		// TODO - Add traversal to end polygon list of traversals?
	}

	print("Connected polygons calculated.\n");
}

//We calculate this outside of polygon creation / editing because the polygon centers are not important to creation, only to actually using in pathfinding
void cl_navmesh_calc_polies_centers()
{
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{
		local vector cen = [0,0,0];
		for(float j = 0; j < cl_navmesh_polies[i].vert_count; j++)
		{
			cen += cl_navmesh_verts[cl_navmesh_polies[i].verts[j]].pos;
		}
		cen /= cl_navmesh_polies[i].vert_count;
		cl_navmesh_polies[i].center.x = cen.x;
		cl_navmesh_polies[i].center.y = cen.y;
		cl_navmesh_polies[i].center.z = cen.z;
	}
	print("Centers calculated.\n");
}


//Navmesh file specification for v0.0.0:
//Vertex count
//For each vert:
	//Vertex position vector
//Polygon count
//For each polygon:
		//vertex count (must be 3 or 4)
		//vertex 0 index
		//vertex 1 index
		//vertex 2 index
		//vertex 3 index (will be -1 for a tri)
		//center (vector)
		//link count
		//link 0 index (will be set or -1 for a tri)
		//link 1 index (will be set or -1 for a tri)
		//link 2 index (will be set or -1 for a tri)
		//link 3 index (will be set or -1 for a tri)
		//link 0 left vert index (will be set or -1 for a tri)
		//link 1 left vert index (will be set or -1 for a tri)
		//link 2 left vert index (will be set or -1 for a tri)
		//link 3 left vert index (will be set or -1 for a tri)
		//link 0 right vert index (will be set or -1 for a tri)
		//link 1 right vert index (will be set or -1 for a tri)
		//link 2 right vert index (will be set or -1 for a tri)
		//link 3 right vert index (will be set or -1 for a tri)


//Saves the current cl_navmesh to a file
void cl_navmesh_editor_save_navmesh() {
	int v_major = 0;
	int v_minor = 1;
	int v_patch = 0;
	float file;
	string h;
	
	h = strcat(mappath, ".nav");
	file = fopen(h,FILE_WRITE);
	
	if(file == -1) {
		print("Error: unable to write to file \"",h,"\".\n");
		return;
	}
	// Write version number:
	fputs( file, itos(v_major), ".", itos(v_minor), ".", itos(v_patch),"\n");
	
	//Calculating all links and polygon centers
	//===========================================
	cl_navmesh_calc_polies_centers();
	cl_navmesh_calc_connected_polies();
	//===========================================

	//Write vertex count
	fputs(file,ftos(cl_navmesh_vert_count),"\n");
	
	//Write all vertex positions
	for(float i = 0; i < cl_navmesh_vert_count; i++) {
		fputs(file,vtos(cl_navmesh_verts[i].pos),"\n");
	}
	
	//Write polygon count
	fputs(file,ftos(cl_navmesh_poly_count),"\n");
	
	//Write all polygon data to file
	for(float i = 0; i < cl_navmesh_poly_count; i++) {
		// Write vert count
		fputs(file,ftos(cl_navmesh_polies[i].vert_count),"\n");
		// Write vertices
		fputs(file,ftos(cl_navmesh_polies[i].verts[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].verts[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].verts[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].verts[3]),"\n");
		fputs(file,vtos(cl_navmesh_polies[i].center),"\n");
		
		// Write link count
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_count),"\n");
		// Write links
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies[3]),"\n");
		// Write left vertices of the links
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_left_vert[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_left_vert[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_left_vert[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_left_vert[3]),"\n");
		// Write right vertices of the links
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_right_vert[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_right_vert[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_right_vert[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_right_vert[3]),"\n");	
		// Write the neighbor edge indices
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_neighbor_edge_index[0]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_neighbor_edge_index[1]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_neighbor_edge_index[2]),"\n");
		fputs(file,ftos(cl_navmesh_polies[i].connected_polies_neighbor_edge_index[3]),"\n");
		// Write connected traversals
		fputs(file,ftos(cl_navmesh_polies[i].connected_traversals_count),"\n");
		for(float j = 0; j < cl_navmesh_polies[i].connected_traversals_count; j++) {
			fputs(file,ftos(cl_navmesh_polies[i].connected_traversals[j]),"\n");
		}
		// Write polygon doortarget
		fputs(file,cl_navmesh_polies[i].doortarget,"\n");

		if(cl_navmesh_polies[i].doortarget != "") {
			print("CLSAVENAVMESH - Polygon at index ",ftos(i)," has doortarget: \"", cl_navmesh_polies[i].doortarget, "\"" );
		}
	}

	// -----------------------------------------------------------------------
	// Write Traversals
	// -----------------------------------------------------------------------
	print("Writing "); 
	print((ftos(cl_navmesh_traversal_count)));
	print(" traversals.\n");
	fputs(file,ftos(cl_navmesh_traversal_count),"\n");
	for(float i = 0; i < cl_navmesh_traversal_count; i++) {
		fputs(file,vtos(cl_navmesh_traversals[i].start_pos),"\n");
		fputs(file,vtos(cl_navmesh_traversals[i].midpoint_pos),"\n");
		fputs(file,vtos(cl_navmesh_traversals[i].end_pos),"\n");
		fputs(file,ftos(cl_navmesh_traversals[i].angle),"\n");
		fputs(file,ftos(cl_navmesh_traversals[i].use_midpoint),"\n");
		fputs(file,ftos(cl_navmesh_traversals[i].end_poly),"\n");
	}
	// -----------------------------------------------------------------------

	fclose(file);
	
	print("Navmesh saved to file \"",h,"\".\n");
}
//Overwrites current navmesh with an empty navmesh
void cl_navmesh_editor_clear_navmesh()
{
	cl_navmesh_deselect_all();
	cl_navmesh_vert_count = 0;
	for(float i = 0; i < NAV_MAX_VERTS; i++)
	{
		cl_navmesh_verts[i].pos.x = 0;
		cl_navmesh_verts[i].pos.y = 0;
		cl_navmesh_verts[i].pos.z = 0;
	}
	cl_navmesh_poly_count = 0;
	for(float i = 0; i < NAV_MAX_POLIES; i++)
	{
		cl_navmesh_polies[i].vert_count = 0;
		
		cl_navmesh_polies[i].verts[0] = -1;
		cl_navmesh_polies[i].verts[1] = -1;
		cl_navmesh_polies[i].verts[2] = -1;
		cl_navmesh_polies[i].verts[3] = -1;
		
		cl_navmesh_polies[i].center.x = 0;
		cl_navmesh_polies[i].center.y = 0;
		cl_navmesh_polies[i].center.z = 0;
		
		cl_navmesh_polies[i].connected_polies_count = 0;
		
		cl_navmesh_polies[i].connected_polies[0] = -1;
		cl_navmesh_polies[i].connected_polies[1] = -1;
		cl_navmesh_polies[i].connected_polies[2] = -1;
		cl_navmesh_polies[i].connected_polies[3] = -1;
		
		cl_navmesh_polies[i].connected_polies_left_vert[0] = -1;
		cl_navmesh_polies[i].connected_polies_left_vert[1] = -1;
		cl_navmesh_polies[i].connected_polies_left_vert[2] = -1;
		cl_navmesh_polies[i].connected_polies_left_vert[3] = -1;
		
		cl_navmesh_polies[i].connected_polies_right_vert[0] = -1;
		cl_navmesh_polies[i].connected_polies_right_vert[1] = -1;
		cl_navmesh_polies[i].connected_polies_right_vert[2] = -1;
		cl_navmesh_polies[i].connected_polies_right_vert[3] = -1;

		cl_navmesh_polies[i].connected_polies_neighbor_edge_index[0] = -1;
		cl_navmesh_polies[i].connected_polies_neighbor_edge_index[1] = -1;
		cl_navmesh_polies[i].connected_polies_neighbor_edge_index[2] = -1;
		cl_navmesh_polies[i].connected_polies_neighbor_edge_index[3] = -1;

		for(float j = 0; j < NAV_MAX_POLY_TRAVERSALS; j++) {
			cl_navmesh_polies[i].connected_traversals[j] = -1;
		}
		cl_navmesh_polies[i].connected_traversals_count = 0;

		cl_navmesh_polies[i].doortarget = "";
	}
	cl_navmesh_traversal_count = 0;
	for(float i = 0; i < NAV_MAX_TRAVERSALS; i++) {
		cl_navmesh_traversals[i].start_pos.x = 0;
		cl_navmesh_traversals[i].start_pos.y = 0;
		cl_navmesh_traversals[i].start_pos.z = 0;
		cl_navmesh_traversals[i].midpoint_pos.x = 0;
		cl_navmesh_traversals[i].midpoint_pos.y = 0;
		cl_navmesh_traversals[i].midpoint_pos.z = 0;
		cl_navmesh_traversals[i].end_pos.x = 0;
		cl_navmesh_traversals[i].end_pos.y = 0;
		cl_navmesh_traversals[i].end_pos.z = 0;
		cl_navmesh_traversals[i].angle = 0;
		cl_navmesh_traversals[i].use_midpoint = false;
		cl_navmesh_traversals[i].end_poly = -1;
	}
}
//Overwrites currently loaded navmesh with navmesh stored in fail
void cl_navmesh_editor_load_navmesh() {
	string filepath;
	float file;
	
	filepath = strcat(mappath, ".nav");
	file = fopen(filepath,FILE_READ);
	
	if(file == -1) {
		print("Error: file \"",filepath,"\" not found.\n");
		return;
	}

	
	// First line contains navmesh file semver
	string nav_file_version = fgets(file);
	print("Loading v", nav_file_version, " navmesh file \"", filepath, "\"...\n");
	
	// TODO - Add backwards compatibility for older navmesh file versions.

	// Next line contains vertex count
	float vert_count = stof(fgets(file));
	
	if(vert_count > NAV_MAX_VERTS) {
		print("Error: navmesh file \"",filepath,"\" has an invalid vert count. (" , vert_count, " > ", ftos(NAV_MAX_VERTS),").\n");
		fclose(file);
		return;
	}
	
	//It appears to be valid, so clear the current navmesh before continuing.
	cl_navmesh_editor_clear_navmesh();
	
	cl_navmesh_vert_count = vert_count;
	print("Vert count: ",vert_count,"\n");


	//Reading all of the vertex positions
	for(float i = 0; i < cl_navmesh_vert_count; i++) {
		cl_navmesh_verts[i].pos = stov(fgets(file));
	}
	
	//Next line contains the number of polygons
	cl_navmesh_poly_count = stof(fgets(file));
	
	//The next lines are each polygon
	for(float i = 0; i < cl_navmesh_poly_count; i++) {
		//Getting vertex count
		cl_navmesh_polies[i].vert_count = stof(fgets(file));
		//Getting vertices
		cl_navmesh_polies[i].verts[0] = stof(fgets(file));
		cl_navmesh_polies[i].verts[1] = stof(fgets(file));
		cl_navmesh_polies[i].verts[2] = stof(fgets(file));
		cl_navmesh_polies[i].verts[3] = stof(fgets(file));
		//Don't care about polygon center
		fgets(file);
		//Don't care about link count
		fgets(file);
		//Don't care about links for now FIXME HANDLE DIRECTIONAL LINKS
		fgets(file);//0
		fgets(file);//1
		fgets(file);//2
		fgets(file);//3
		//Don't care about link's left vertices
		fgets(file);//0
		fgets(file);//1
		fgets(file);//2
		fgets(file);//3
		//Don't care about link's right vertices
		fgets(file);//0
		fgets(file);//1
		fgets(file);//2
		fgets(file);//3
		// Don't care about neighbor entrance edge indices
		fgets(file);//0
		fgets(file);//1
		fgets(file);//2
		fgets(file);//3

		// If navmesh file version 0.0.0, no traversals
		// FIXME - Need a better way to do this..
		if(nav_file_version != "0.0.0") {
			// Don't care about connected traversals
			float n_traversals = stof(fgets(file));
			for(float j = 0; j < n_traversals; j++) {
				fgets(file); // discard the j-th traversal index
			}
		}

		// Load doortarget field
		cl_navmesh_polies[i].doortarget = fgets(file);

		if(cl_navmesh_polies[i].doortarget != "") {
			print("CLLOADNAVMESH - Polygon at index ",ftos(i)," has doortarget: \"", cl_navmesh_polies[i].doortarget, "\"" );
		}
		// cl_navmesh_polies[i].doortarget = ""; // Temp fix to load old files
		// If v0.0.0, discard entrance edge (no longer used)
		if(nav_file_version == "0.0.0") {
			fgets(file);
		}
	}

	// -----------------------------------------------------------------------
	// Load Traversals
	// -----------------------------------------------------------------------
	// If navmesh file version 0.0.0, no traversals
	if(nav_file_version != "0.0.0") {
		// Next line contains the number of traverals
		cl_navmesh_traversal_count = stof(fgets(file));
		
		// Next lines are each traversal
		for(float i = 0; i < cl_navmesh_traversal_count; i++) {
			cl_navmesh_traversals[i].start_pos = stov(fgets(file));
			cl_navmesh_traversals[i].midpoint_pos = stov(fgets(file));
			cl_navmesh_traversals[i].end_pos = stov(fgets(file));
			cl_navmesh_traversals[i].angle = stof(fgets(file));
			cl_navmesh_traversals[i].use_midpoint = stof(fgets(file));
			// Don't care about traversal end polygon index
			fgets(file);
		}
	}
	// -----------------------------------------------------------------------
	
	fclose(file);
}


//==================================================================


//==========================================================================================================================
//============================ The following methods are methods required in the pathfinding code ==========================
//==========================================================================================================================


float(float start, float goal, vector start_pos, vector end_pos) cl_navmesh_pathfind_start;

void cl_navmesh_draw_test_ent(vector pos, vector scale, vector color, float alpha)
{
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	//vector	VEC_HULL_MIN = '-16 -16 -32';
	//vector	VEC_HULL_MAX = '16 16 40';
	
	float min_x = -16 * scale_x;
	float min_y = -16 * scale_y;
	float min_z = -32 * scale_z;
	float max_x = 16 * scale_x;
	float max_y = 16 * scale_y;
	float max_z = 40 * scale_z;
	
	
	
	//bottom face
	R_PolygonVertex(pos + [min_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,min_y,min_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Top face
	R_PolygonVertex(pos + [min_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,min_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Front face
	R_PolygonVertex(pos + [min_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,min_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Back face
	R_PolygonVertex(pos + [min_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,max_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Left face
	R_PolygonVertex(pos + [min_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [min_x,min_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
	//Right face
	R_PolygonVertex(pos + [max_x,min_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,min_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,max_y,max_z], [0,0,0], color,alpha);
	R_PolygonVertex(pos + [max_x,min_y,max_z], [0,0,0], color,alpha);
	R_EndPolygon();
}

void cl_navmesh_place_test_goalent() {
	goalent_pos = getentity(player_localentnum, GE_ORIGIN);
	goalent_set = TRUE;
	
	//Calculate data that the navmesh exporer will calculate
	cl_navmesh_calc_polies_centers();
	cl_navmesh_calc_connected_polies();
	
	if(goalent_set == TRUE && startent_set == TRUE) {
		print("Getting start poly: ");
		float start = cl_navmesh_get_containing_poly(startent_pos);
		print("Getting goal poly: ");
		float goal = cl_navmesh_get_containing_poly(goalent_pos);
		cl_navmesh_pathfind_start(start,goal,startent_pos,goalent_pos);
	}
}

void cl_navmesh_place_test_startent() {
	startent_pos = getentity(player_localentnum, GE_ORIGIN);
	startent_set = TRUE;
	
	//Calculate data that the navmesh exporer will calculate
	cl_navmesh_calc_polies_centers();
	cl_navmesh_calc_connected_polies();
	
	if(goalent_set == TRUE && startent_set == TRUE) {
		print("Getting start poly: ");
		float start = cl_navmesh_get_containing_poly(startent_pos);
		print("Getting goal poly: ");
		float goal = cl_navmesh_get_containing_poly(goalent_pos);
		cl_navmesh_pathfind_start(start,goal,startent_pos,goalent_pos);
	}
}

//Returns 1 if pos is inside poly at index poly_index, 0 otherwise
float cl_navmesh_is_inside_poly(vector pos, float poly_index) {
	
	//TODO: check if z coord is close enough to poly
	
	local vector vert_to_pos;//points from vert to pos
	local vector vert_to_next;//points from vert to the next vertex
	local vector vert;
	local vector next_vert;
	float vert_count = cl_navmesh_polies[poly_index].vert_count;
	//We are considered to be in the polygon, if pos is on the left of all edges of the polygon (if verts are ordered in CW order)
	for(float i = 0; i < vert_count; i++) {
		vert = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[i]].pos;
		next_vert = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[(i + 1) % vert_count]].pos;
		
		vert_to_pos = pos - vert;
		vert_to_next = next_vert - vert;
		
		//Check if vert_to_pos is to the left of vert_to_next
		if(vert_to_next.x * vert_to_pos.y - vert_to_next.y * vert_to_pos.x < 0)
			return 0;
	}
	
	
	//FOR DEBUG: select that polygon if succesfull
	cl_navmesh_deselect_all();
	selected_vert_count = cl_navmesh_polies[poly_index].vert_count;
	for(float i = 0; i < selected_vert_count; i++) {
		selected_verts[i] = cl_navmesh_polies[poly_index].verts[i];
	}	
	//============================================
	
	
	return 1;
}

//Returns distance from pos to an edge of the poly if pos is very close to an edge of the poly at index poly_index, -1 otherwise
float cl_navmesh_dist_to_poly(vector pos, float poly_index)
{
	float leeway = 30;//Must be within 30 qu of edge to be considered close
	
	//TODO: check if close enough on z-axis
	
	local vector vert_to_pos;//points from vert to pos
	local vector vert_to_next;//points from vert to the next vertex
	
	
	local vector vert;
	local vector next_vert;
	float vert_count = cl_navmesh_polies[poly_index].vert_count;
	
	float shortest_dist = 100000;
	
	//Only considering 2D
	//pos.z = 0;
	
	//We are considered to be in the polygon, if pos is on the left of all edges of the polygon (if verts are ordered in CW order)
	for(float i = 0; i < vert_count; i++)
	{
		vert = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[i]].pos;
		next_vert = cl_navmesh_verts[cl_navmesh_polies[poly_index].verts[(i + 1) % vert_count]].pos;
		
		//Calculating in 2D:
		//vert.z = 0;
		//next_vert.z = 0;
		
		float temp_dist = navmesh_2D_line_point_dist(vert, next_vert, pos);
		
		if(temp_dist < shortest_dist)
		{
			shortest_dist = temp_dist;
		}	
	}
	
	if(shortest_dist < leeway)
		return shortest_dist;
	
	return -1;
}

//Returns polygon that pos is inside of. 
//If we are in no polygon, returns a polygon whose edge we are sufficiently close to (might be in but are not due to a small error)
//Otherwise, returns -1
float cl_navmesh_get_containing_poly(vector pos)
{
	//Get nearest polygon, and check if pos is in that polygon
	float closest_poly = -1;
	float closest_poly_dist = 1000000;
	
	//In reality, there's no need to try ALL polygons, the one we are in should be within the nearest 10 or so, but checking all to be safe
	for(float i = 0; i < cl_navmesh_poly_count; i++)
	{	
		//Check if we are sufficiently close enough to polygon i in the z-axis
		//Current method of checking: if pos is within 30 qu of polygon z-axis bounds
		float poly_min_z = cl_navmesh_verts[cl_navmesh_polies[i].verts[0]].pos.z;
		float poly_max_z = poly_min_z;

		for(float j = 0; j < cl_navmesh_polies[i].vert_count; j++)
		{
			float vert_z = cl_navmesh_verts[cl_navmesh_polies[i].verts[j]].pos.z;
			poly_min_z = min(poly_min_z, vert_z);
			poly_max_z = max(poly_max_z, vert_z);
		}

		// If we NOT between [min - 30, max + 30], skip this polygon
		// if(fabs(sv_navmesh_polies[0].center.z - pos.z) >= 30)
		if(pos.z < poly_min_z - 30 || pos.z > poly_max_z + 30)
		{
			continue;
		}
		
		//Check if we are in the 2d plane of polygon i
		if(cl_navmesh_is_inside_poly(pos,i))
		{
			// NOTE - Because is_inside_poly only checks if we are in it on X & Y axes,
			// NOTE   we may have found a polygon on a floor below us or above us.
			// NOTE   However, this may not be an issue. A polygon on a floor below
			// NOTE   us would be at least about 80-ish qu away, and the checks done for 
			// NOTE   z proximity might be enough to stop us from choosing polygons on 
			// NOTE   different floors. I shall assume this works fine, and wait for a 
			// NOTE   counter-example that shows we'll need a more sophisticated strategy.
			print("Ent pos is inside poly: ");
			print(ftos(i));
			print(".\n");
			return i;
		}
		
		//If we are not in polygon i, check if we are very close to one of its edges
		float dist = cl_navmesh_dist_to_poly(pos,i);
		
		if(dist >= 0)
		{
			if(dist < closest_poly_dist)
			{
				closest_poly = i;
				closest_poly_dist = dist;
			}
		}

	}
	
	
	//FOR DEBUG: select that polygon if successful
	if(closest_poly != -1)
	{
		cl_navmesh_deselect_all();
		selected_vert_count = cl_navmesh_polies[closest_poly].vert_count;
		for(float i = 0; i < selected_vert_count; i++)
		{
			selected_verts[i] = cl_navmesh_polies[closest_poly].verts[i];
		}
	}
	//============================================
	
	if(closest_poly == -1)
	{
		print("Ent pos is not in or near any polygons.\n");
	}
	else
	{
		print("Ent pos is near but not in poly: closest_poly.\n");
	}
	
	return closest_poly;
}




//================================================================================================================
//=============================================== Actual A* functions ============================================
//================================================================================================================

//Calculates the heuristic h score value for a navmesh polygon (Our best guess for how far this node is from the goal node)
float cl_pathfind_calc_poly_h_score(float current_poly_idx, float goal_poly_idx) {
	//FIXME: we could just as easily return vlen()^2 for comparisons... (saves a sqrt operation)
	return vlen(cl_navmesh_polies[goal_poly_idx].center - cl_navmesh_polies[current_poly_idx].center);
}

//Calculates the heuristic h score value for a navmesh traversal (Our best guess for how far this node is from the goal node)
float cl_pathfind_calc_traversal_h_score(float current_traversal_idx, float goal_poly_idx) {
	//FIXME: we could just as easily return vlen()^2 for comparisons... (saves a sqrt operation)
	vector traversal_end_pos = cl_navmesh_get_traversal_end_pos(current_traversal_idx);
	return vlen(cl_navmesh_polies[goal_poly_idx].center - traversal_end_pos);
}

//Struct containing all arrays that the pathfind code requires to operate
navmesh_pathfind_result *cl_test_pathfind_result;

//Returns the polygon with the lowest f score from polygons the open set
float cl_pathfind_get_lowest_f_score_poly() {
	//TODO: implement a better algorithm for finding the lowest score
	float best_score = 100000;
	float best_score_index = -1;
	
	for(float i = 0; i < cl_navmesh_poly_count; i++) {
		if(cl_test_pathfind_result->poly_set[i] == PATHFIND_POLY_SET_OPEN) {
			if(cl_test_pathfind_result->poly_f_score[i] < best_score) {
				best_score = cl_test_pathfind_result->poly_f_score[i];
				best_score_index = i;
			}
		}
	}
	return best_score_index;
}


//Returns the traversal with the lowest f score from traversals the open set
float cl_pathfind_get_lowest_f_score_traversal() {
	//TODO: implement a better algorithm for finding the lowest score
	float best_score = 100000;
	float best_score_index = -1;
	
	for(float i = 0; i < cl_navmesh_traversal_count; i++) {
		if(cl_test_pathfind_result->traversal_set[i] == PATHFIND_POLY_SET_OPEN) {
			if(cl_test_pathfind_result->traversal_f_score[i] < best_score) {
				best_score = cl_test_pathfind_result->traversal_f_score[i];
				best_score_index = i;
			}
		}
	}	
	return best_score_index;
}


void cl_pathfind_clear_result_data() {
	//Technically we only need to iterate over navmesh_poly_count...
	for(float i = 0; i < NAV_MAX_POLIES; i++) {
		cl_test_pathfind_result->poly_set[i] = PATHFIND_POLY_SET_NONE;
		cl_test_pathfind_result->poly_prev_poly[i] = -1;
		cl_test_pathfind_result->poly_prev_traversal[i] = -1;
		cl_test_pathfind_result->poly_g_score[i] = 0;
		cl_test_pathfind_result->poly_f_score[i] = 0;

		cl_test_pathfind_result->path_polygons[i] = -1;
		cl_test_pathfind_result->path_traversals[i] = -1;
				
		cl_test_pathfind_result->portals_left_pos[i].x = 0;
		cl_test_pathfind_result->portals_left_pos[i].y = 0;
		cl_test_pathfind_result->portals_left_pos[i].z = 0;
		cl_test_pathfind_result->portals_right_pos[i].x = 0;
		cl_test_pathfind_result->portals_right_pos[i].y = 0;
		cl_test_pathfind_result->portals_right_pos[i].z = 0;
		cl_test_pathfind_result->portals_traversal[i] = -1;

		cl_test_pathfind_result->point_path_points[i].x = 0;
		cl_test_pathfind_result->point_path_points[i].y = 0;
		cl_test_pathfind_result->point_path_points[i].y = 0;
		cl_test_pathfind_result->point_path_traversals[i] = -1;
	}
	for(float i = 0;i < NAV_MAX_TRAVERSALS; i++) {
		cl_test_pathfind_result->traversal_set[i] = PATHFIND_POLY_SET_NONE;
		cl_test_pathfind_result->traversal_prev_poly[i] = -1;
		cl_test_pathfind_result->traversal_g_score[i] = 0;
		cl_test_pathfind_result->traversal_f_score[i] = 0;
	}
	cl_test_pathfind_result->path_length = 0;
	cl_test_pathfind_result->portals_length = 0;
	cl_test_pathfind_result->point_path_length = 0;
}


// vector cl_pathfind_get_left_portal_corner(navmesh_pathfind_result *res, int portal_idx) {
// 	// return cl_navmesh_verts[res->portals_left_vert[portal_idx]].pos;

// 	// Find the vertex opposite this portal edge
// 	vector corner = cl_navmesh_verts[res->portals_left_vert[portal_idx]].pos;
// 	vector opposite_corner = cl_navmesh_verts[res->portals_right_vert[portal_idx]].pos;
// 	// Move 20 qu or 20% of the edge length, whichever is smaller:
// 	float edge_len = vlen(opposite_corner - corner);
// 	vector edge_dir = normalize(opposite_corner - corner);
// 	return corner + edge_dir * min(edge_len * 0.2, 20);
// }

// vector cl_pathfind_get_right_portal_corner(navmesh_pathfind_result *res, int portal_idx) {
// 	// return cl_navmesh_verts[res->portals_right_vert[portal_idx]].pos;

// 	// Find the vertex opposite this portal edge
// 	vector corner = cl_navmesh_verts[res->portals_right_vert[portal_idx]].pos;
// 	vector opposite_corner = cl_navmesh_verts[res->portals_left_vert[portal_idx]].pos;
// 	// Move 20 qu or 20% of the edge length, whichever is smaller:
// 	float edge_len = vlen(opposite_corner - corner);
// 	vector edge_dir = normalize(opposite_corner - corner);
// 	return corner + edge_dir * min(edge_len * 0.2, 20);
// }


//Applies a funnel algorithm to the path defined by the array cl_test_pathfind_result->result_node_path 
// and populates pathfind result path
void cl_pathfind_smooth_path(vector start_point, vector goal_point) {

	float cur_poly;
	float cur_traversal;
	float prev_poly;
	float prev_traversal;
	vector cur_portal_left_pos = '0 0 0';
	vector cur_portal_right_pos = '0 0 0';
	float cur_portal_traversal = -1;
	vector traversal_start_pos;
	vector traversal_end_pos;

	// Build the list of portals
	for(float i = 1; i < cl_test_pathfind_result->path_length; i++) {
		cur_poly = cl_test_pathfind_result->path_polygons[i];
		cur_traversal = cl_test_pathfind_result->path_traversals[i];
		prev_poly = cl_test_pathfind_result->path_polygons[i-1];
		prev_traversal = cl_test_pathfind_result->path_traversals[i-1];

		// If polygon and came from polygon, portal = shared edge
		if(cur_poly != -1 && prev_poly != -1) {
			// Find which of prev_poly's edges connects to cur_poly
			float prev_poly_edge_index = -1;
			for(float j = 0; j < cl_navmesh_polies[prev_poly].connected_polies_count; j++) {
				if(cl_navmesh_polies[prev_poly].connected_polies[j] == cur_poly) {
					prev_poly_edge_index = j;
					break;
				}
			}
			cur_portal_left_pos = cl_navmesh_verts[cl_navmesh_polies[prev_poly].connected_polies_left_vert[prev_poly_edge_index]].pos;
			cur_portal_right_pos = cl_navmesh_verts[cl_navmesh_polies[prev_poly].connected_polies_right_vert[prev_poly_edge_index]].pos;
			cur_portal_traversal = -1;

			// ----------------------------------------------------------------
			// Narrow the portal from each side by 20% or 20qu, whichever is smaller
			// ----------------------------------------------------------------
			float edge_len = vlen(cur_portal_right_pos - cur_portal_left_pos);
			vector edge_dir = normalize(cur_portal_right_pos - cur_portal_left_pos);
			float ofs = min(edge_len * 0.2, 20);
			cur_portal_left_pos = cur_portal_left_pos + edge_dir * ofs;
			cur_portal_right_pos = cur_portal_right_pos - edge_dir * ofs;
			// ----------------------------------------------------------------
		}
		// If polygon and came from traversal, portal = traversal exit
		else if(cur_poly != -1 && prev_traversal != -1) {
			traversal_end_pos = cl_navmesh_get_traversal_end_pos(prev_traversal);
			cur_portal_left_pos = traversal_end_pos;
			cur_portal_right_pos = traversal_end_pos;
			cur_portal_traversal = -1;
			// TODO - Denote that it came from traversal? maybe we don't care?
		}
		// If traversal and came from polygon, portal = traversal start
		else if(cur_traversal != -1 && prev_poly != -1) {
			traversal_start_pos = cl_navmesh_traversals[cur_traversal].start_pos;
			cur_portal_left_pos = traversal_start_pos;
			cur_portal_right_pos = traversal_start_pos;
			cur_portal_traversal = cur_traversal;
		}

		cl_test_pathfind_result->portals_left_pos[cl_test_pathfind_result->portals_length] = cur_portal_left_pos;
		cl_test_pathfind_result->portals_right_pos[cl_test_pathfind_result->portals_length] = cur_portal_right_pos;
		cl_test_pathfind_result->portals_traversal[cl_test_pathfind_result->portals_length] = cur_portal_traversal;
		cl_test_pathfind_result->portals_length++;
	}


	// TODO - Should I add goal_pos as the final portal?
	cl_test_pathfind_result->portals_left_pos[cl_test_pathfind_result->portals_length] = goal_point;
	cl_test_pathfind_result->portals_right_pos[cl_test_pathfind_result->portals_length] = goal_point;
	cl_test_pathfind_result->portals_traversal[cl_test_pathfind_result->portals_length] = -1;
	cl_test_pathfind_result->portals_length++;



	vector cur_funnel_corner = start_point;
	vector cur_funnel_left = cl_test_pathfind_result->portals_left_pos[0];
	vector cur_funnel_right = cl_test_pathfind_result->portals_right_pos[0];
	float cur_funnel_left_portal_idx = 0;
	float cur_funnel_right_portal_idx = 0;

	// Loop through all portals, adding necessary funnel corners to final path
	for(float i = 0; i < cl_test_pathfind_result->portals_length; i++) {
		cur_portal_left_pos = cl_test_pathfind_result->portals_left_pos[i];
		cur_portal_right_pos = cl_test_pathfind_result->portals_right_pos[i];
		cur_portal_traversal = cl_test_pathfind_result->portals_traversal[i];


		// TODO - Project portal points to axis made by cur funnel points
		// Then we can check 
		// TODO - Compute value for a point:
		// TODO		0: On funnel center
		// TODO		< -1 outside of funnel to the left
		// TODO		> 1 outside of funnel to the right

		float cur_portal_left_in_funnel = pathfind_point_in_funnel( cur_portal_left_pos,  cur_funnel_corner, cur_funnel_left, cur_funnel_right);
		float cur_portal_right_in_funnel = pathfind_point_in_funnel(cur_portal_right_pos, cur_funnel_corner, cur_funnel_left, cur_funnel_right);

		print("{'portal_idx': ", ftos(i), ", 'portal': ");
		print(" [(", ftos(cur_portal_left_pos.x), ",", ftos(cur_portal_left_pos.y), "), (", ftos(cur_portal_right_pos.x), ",", ftos(cur_portal_right_pos.y));
		print(")], 'traversal': ", ftos(cur_portal_traversal), ", ");
		print("'funnel_result': (", ftos(cur_portal_left_in_funnel), ",", ftos(cur_portal_right_in_funnel), "), ");
		print("'funnel': [");
		print("(", ftos(cur_funnel_left.x), ",", ftos(cur_funnel_left.y), "), ");
		print("(", ftos(cur_funnel_corner.x), ",", ftos(cur_funnel_corner.y), "), ");
		print("(", ftos(cur_funnel_right.x), ",", ftos(cur_funnel_right.y), ")");
		print("]},\n");
		// print(vtos(cur_funnel_left));


		// If cur portal left point is in cur funnel, narrow the cur funnel
		if(cur_portal_left_in_funnel >= -1 && cur_portal_left_in_funnel <= 1) {
			cur_funnel_left = cur_portal_left_pos;
			cur_funnel_left_portal_idx = i;
		}
		// If cur portal right point is in cur funnel, narrow the cur funnel
		if(cur_portal_right_in_funnel >= -1 && cur_portal_right_in_funnel <= 1) {
			cur_funnel_right = cur_portal_right_pos;
			cur_funnel_right_portal_idx = i;
		}

		// If cur portal is completely outside (to left of) current funnel
		if(cur_portal_left_in_funnel < -1 && cur_portal_right_in_funnel < -1) {
			// Add cur funnel left point to final path:
			cl_test_pathfind_result->point_path_points[cl_test_pathfind_result->point_path_length] = cur_funnel_left;
			cl_test_pathfind_result->point_path_traversals[cl_test_pathfind_result->point_path_length] = -1;
			cl_test_pathfind_result->point_path_length++;

			// Update funnel to start at the current funnel left endpoint, pointing to the next portal in the list
			// Set next funnel to start at cur funnel left point
			cur_funnel_corner = cur_funnel_left;

			// Advance the funnel's left point to the next portal
			cur_funnel_left_portal_idx += 1;
			cur_funnel_right = cl_test_pathfind_result->portals_right_pos[cur_funnel_left_portal_idx];
			cur_funnel_left = cl_test_pathfind_result->portals_left_pos[cur_funnel_left_portal_idx];
			cur_funnel_right_portal_idx = cur_funnel_left_portal_idx;
			// Restart funnel algorithm from the funnel's endpoint
			i = cur_funnel_left_portal_idx - 1;
			continue;
		}
		// If cur portal is completely outside (to right of) current funnel
		else if(cur_portal_left_in_funnel > 1 && cur_portal_right_in_funnel > 1) {
			// Add cur funnel right point to final path:
			cl_test_pathfind_result->point_path_points[cl_test_pathfind_result->point_path_length] = cur_funnel_right;
			cl_test_pathfind_result->point_path_traversals[cl_test_pathfind_result->point_path_length] = -1;
			cl_test_pathfind_result->point_path_length++;

			// Update funnel to start at the current funnel right endpoint, pointing to the next portal in the list
			// Set next funnel to start at cur funnel right point
			cur_funnel_corner = cur_funnel_right;

			// Advance the funnel's right point to the next portal
			cur_funnel_right_portal_idx += 1;
			cur_funnel_right = cl_test_pathfind_result->portals_right_pos[cur_funnel_right_portal_idx];
			cur_funnel_left = cl_test_pathfind_result->portals_left_pos[cur_funnel_right_portal_idx];
			cur_funnel_left_portal_idx = cur_funnel_right_portal_idx;
			// Restart funnel algorithm from the funnel's endpoint
			i = cur_funnel_right_portal_idx - 1;
			continue;
		}

		// If cur portal is a traversal
		if(cur_portal_traversal != -1) {
			vector start_pos = cl_navmesh_traversals[cur_portal_traversal].start_pos;
			vector end_pos = cl_navmesh_get_traversal_end_pos(cur_portal_traversal);
			// Add traversal start point to final path:
			cl_test_pathfind_result->point_path_points[cl_test_pathfind_result->point_path_length] = start_pos;
			cl_test_pathfind_result->point_path_traversals[cl_test_pathfind_result->point_path_length] = cur_portal_traversal;
			cl_test_pathfind_result->point_path_length++;
			// Add traversal end point to final path:
			// FIXME - Should I remove this?
			cl_test_pathfind_result->point_path_points[cl_test_pathfind_result->point_path_length] = end_pos;
			cl_test_pathfind_result->point_path_traversals[cl_test_pathfind_result->point_path_length] = -1;
			cl_test_pathfind_result->point_path_length++;


			// Set funnel to start at traversal endpoint and use the next portal
			cur_funnel_corner = end_pos;
			cur_funnel_left = cl_test_pathfind_result->portals_left_pos[i+1];
			cur_funnel_right = cl_test_pathfind_result->portals_right_pos[i+1];
			cur_funnel_left_portal_idx = i+1;
			cur_funnel_right_portal_idx = i+1;
		}
	}

	// Always add goal point to the path
	cl_test_pathfind_result->point_path_points[cl_test_pathfind_result->point_path_length] = goal_point;
	cl_test_pathfind_result->point_path_traversals[cl_test_pathfind_result->point_path_length] = -1;
	cl_test_pathfind_result->point_path_length++;
}


//Evaluates the path that is found in the pathfinding algorithm and populates an array with the nodes in the path from start to goal
void cl_pathfind_trace_path(float start_poly, float goal_poly) {
	// print("Polygon from poly: ");
	// for(float i = 0; i < cl_navmesh_poly_count; i++) {
	// 	print(ftos(i));
	// 	print(": ");
	// 	print(ftos(cl_test_pathfind_result->poly_prev_poly[i]));
	// 	print(", ");
	// }
	// print("\n");
	// print("Polygon from traversal: ");
	// for(float i = 0; i < cl_navmesh_poly_count; i++) {
	// 	print(ftos(i));
	// 	print(": ");
	// 	print(ftos(cl_test_pathfind_result->poly_prev_traversal[i]));
	// 	print(", ");
	// }
	// print("\n");
	// print("Traversal from polygon:");
	// for(float i = 0; i < cl_navmesh_traversal_count; i++) {
	// 	print(ftos(i));
	// 	print(": ");
	// 	print(ftos(cl_test_pathfind_result->traversal_prev_poly[i]));
	// 	print(", ");
	// }
	// print("\n");


	//Count the length of the path (how many polygons the path traverses)
	float current_poly = goal_poly;
	float current_traversal = -1;
	cl_test_pathfind_result->path_length = 1;
	do {
		// Current node is a polygon
		if(current_poly != -1) {
			current_traversal = cl_test_pathfind_result->poly_prev_traversal[current_poly];
			current_poly = cl_test_pathfind_result->poly_prev_poly[current_poly];
		}
		// Current node is a traversal
		else if(current_traversal != -1) {
			current_poly = cl_test_pathfind_result->traversal_prev_poly[current_traversal];
			current_traversal = -1;
		}
		cl_test_pathfind_result->path_length++;
	} while(current_poly != start_poly);
	
	
	// Starting at goal_poly, add the traversed polygons / traversals to the result path in reverse order
	current_poly = goal_poly;
	current_traversal = -1;
	for(float i = 0; i < cl_test_pathfind_result->path_length; i++) {
		// print("Current node (P=");
		// print(ftos(current_poly));
		// print(",T=");
		// print(ftos(current_traversal));
		// print(") came from ");

		cl_test_pathfind_result->path_polygons[cl_test_pathfind_result->path_length - 1 - i] = current_poly;
		cl_test_pathfind_result->path_traversals[cl_test_pathfind_result->path_length - 1 - i] = current_traversal;
		// Current node is a polygon
		if(current_poly != -1) {
			current_traversal = cl_test_pathfind_result->poly_prev_traversal[current_poly];
			current_poly = cl_test_pathfind_result->poly_prev_poly[current_poly];
		}
		// Current node is a traversal
		else if(current_traversal != -1) {
			current_poly = cl_test_pathfind_result->traversal_prev_poly[current_traversal];
			current_traversal = -1;
		}

		// print(" (P=");
		// print(ftos(current_poly));
		// print(",T=");
		// print(ftos(current_traversal));
		// print(")\n");
	}
	
	print("Pathfind success, path length: ");
	print(ftos(cl_test_pathfind_result->path_length));
	print(".\n");
	print("Path: ");
	for(float i = 0; i < cl_test_pathfind_result->path_length; i++) {
		if(i > 0) {
			print(" , ");
		}
		if(cl_test_pathfind_result->path_polygons[i] != -1) {
			print("P");
			print(ftos(cl_test_pathfind_result->path_polygons[i]));
		}
		else if(cl_test_pathfind_result->path_traversals[i] != -1) {
			print("T");
			print(ftos(cl_test_pathfind_result->path_traversals[i]));
		}
	}
	print(" .\n");
}

//Accepts start polygon and goal polygon
//Returns 1 on success.
//Returns 0 on fail.
float cl_navmesh_pathfind_start(float start_poly, float goal_poly, vector start_pos, vector end_pos) {
	//Clearing previous data
	cl_pathfind_clear_result_data();

	if(start_poly == -1) {
		print("Error: pathfind start node invalid.\n");
		return 0;
	}
	if(goal_poly == -1) {
		print("Error: pathfind goal node invalid.\n");
		return 0;
	}
	if(start_poly == goal_poly) {
		//Calculating node path
		cl_test_pathfind_result->path_polygons[0] = start_poly;
		cl_test_pathfind_result->path_traversals[0] = -1;
		cl_test_pathfind_result->path_length = 1;
		print("Pathind success: trivial case (start = goal).\n");
		
		//Calculating vector based path (go directly to goal)
		cl_test_pathfind_result->point_path_points[0].x = end_pos.x;
		cl_test_pathfind_result->point_path_points[0].y = end_pos.y;
		cl_test_pathfind_result->point_path_points[0].z = end_pos.z;
		// Indicate non-traversal
		cl_test_pathfind_result->point_path_traversals[0] = -1;
		cl_test_pathfind_result->point_path_length = 1;
		return 1;
	}
	
	//Adding start polygon to the open set
	cl_test_pathfind_result->poly_set[start_poly] = PATHFIND_POLY_SET_OPEN;
	cl_test_pathfind_result->poly_g_score[start_poly] = 0;
	cl_test_pathfind_result->poly_f_score[start_poly] = 0 + cl_pathfind_calc_poly_h_score(start_poly , goal_poly);
		
	// print("Pathfind init. Start: ");
	// print(ftos(start_poly));
	// print(" , Goal: ");
	// print(ftos(goal_poly));
	// print(".\n");
	
	float current_poly = start_poly;
	float current_traversal = -1;
	float pathfind_success = FALSE;
	
	// While we have a traversal OR a polygon
	while(current_poly != -1 || current_traversal != -1) {

		// If we are currently evaluating a polygon:
		if(current_poly != -1) {
			if(current_poly == goal_poly) {
				//print("Current is now goal. Breaking.\n");
				pathfind_success = TRUE;
				break;
			}

			//Add current node to the closed set
			cl_test_pathfind_result->poly_set[current_poly] = PATHFIND_POLY_SET_CLOSED;
			//Add connected neighbor polygons to the open set
			for(float i = 0; i < cl_navmesh_polies[current_poly].connected_polies_count; i++) {
				float neighbor_poly = cl_navmesh_polies[current_poly].connected_polies[i];
				
				// print("Checking poly ");
				// print(ftos(current_poly));
				// print("'s neighbor poly ");
				// print(ftos(neighbor_poly));
				// print(".\n");

				// ----------------------------------------------------------------
				// Door check
				// ----------------------------------------------------------------
				// NOTE - If polygon's door hasn't been opened, don't consider it.
				// NOTE - This check isn't done in the navmesh editor.
				// ----------------------------------------------------------------


				if(cl_test_pathfind_result->poly_set[neighbor_poly] != PATHFIND_POLY_SET_CLOSED) {
					//print("Neighbor is not in closed list.\n");
					//Calculate tentative f score
					//Calculate tentative g score (distance from start to current + distance from current to neighbor)
					float tentative_g_score = cl_test_pathfind_result->poly_g_score[current_poly] + vlen(cl_navmesh_polies[neighbor_poly].center - cl_navmesh_polies[current_poly].center);
					
					// If not in open-set, or this is a better score, set score for this polygon
					if(cl_test_pathfind_result->poly_set[neighbor_poly] != PATHFIND_POLY_SET_OPEN || tentative_g_score < cl_test_pathfind_result->poly_g_score[neighbor_poly]) {
						//print("Neighbor is not in open list, or a better g score has been found.\n");
						//Adding neighbor to open set
						cl_test_pathfind_result->poly_set[neighbor_poly] = PATHFIND_POLY_SET_OPEN;
						
						//Updating scores for neighbor node
						float tentative_f_score = tentative_g_score + cl_pathfind_calc_poly_h_score(neighbor_poly , goal_poly);
						cl_test_pathfind_result->poly_g_score[neighbor_poly] = tentative_g_score;
						cl_test_pathfind_result->poly_f_score[neighbor_poly] = tentative_f_score;
						
						//Linking neighbor node to current node (for tracing path)
						cl_test_pathfind_result->poly_prev_poly[neighbor_poly] = current_poly;
						cl_test_pathfind_result->poly_prev_traversal[neighbor_poly] = -1;
						
						// print("Assigning Poly ");
						// print(ftos(neighbor_poly));
						// print(" came from poly ");
						// print(ftos(current_poly));
						// print(".\n");
					}
				}
			}

			//Add connected neighbor traversals to the open set
			for(float i = 0; i < cl_navmesh_polies[current_poly].connected_traversals_count; i++) {
				float neighbor_traversal = cl_navmesh_polies[current_poly].connected_traversals[i];

				// print("Checking poly ");
				// print(ftos(current_poly));
				// print("'s neighbor traversal ");
				// print(ftos(neighbor_traversal));
				// print(".\n");

				if(cl_test_pathfind_result->traversal_set[neighbor_traversal] != PATHFIND_POLY_SET_CLOSED) {
					//Calculate tentative f score
					//Calculate tentative g score (distance from start to current + distance from current to neighbor)
					// vector traversal_start_pos = cl_navmesh_traversals[neighbor].start_pos;
					vector traversal_end_pos = cl_navmesh_get_traversal_end_pos(neighbor_traversal);
					// TODO - Should I cache traversal length?
					float tentative_g_score = cl_test_pathfind_result->poly_g_score[current_poly] + vlen(traversal_end_pos - cl_navmesh_polies[current_poly].center);

					// If not in open-set, or this is a better score, set score for this traversal
					if(cl_test_pathfind_result->traversal_set[neighbor_traversal] != PATHFIND_POLY_SET_OPEN || tentative_g_score < cl_test_pathfind_result->traversal_g_score[neighbor_traversal]) {
						//print("Neighbor is not in open list, or a better g score has been found.\n");
						//Adding neighbor to open set
						cl_test_pathfind_result->traversal_set[neighbor_traversal] = PATHFIND_POLY_SET_OPEN;
						
						//Updating scores for neighbor node
						float tentative_f_score = tentative_g_score + cl_pathfind_calc_traversal_h_score(neighbor_traversal, goal_poly);
						cl_test_pathfind_result->traversal_g_score[neighbor_traversal] = tentative_g_score;
						cl_test_pathfind_result->traversal_f_score[neighbor_traversal] = tentative_f_score;
						
						//Linking neighbor node to current node (for tracing path)
						cl_test_pathfind_result->traversal_prev_poly[neighbor_traversal] = current_poly;
						// print("Assigning traversal ");
						// print(ftos(neighbor_traversal));
						// print(" came from poly ");
						// print(ftos(current_poly));
						// print(".\n");
					}

				}
			}
		}
		else if(current_traversal != -1) {
			// print("Checking traversal: ");
			// print(ftos(current_traversal));
			// print(" with end polygon: ");
			// print(ftos(cl_navmesh_traversals[current_traversal].end_poly));
			// print("\n");
			//Add current traversal to the closed set
			cl_test_pathfind_result->traversal_set[current_traversal] = PATHFIND_POLY_SET_CLOSED;

			// Traversals have single neighbor polygons (at the traversal endpoint)
			float neighbor_poly = cl_navmesh_traversals[current_traversal].end_poly;
			if(neighbor_poly != -1) {

				// print("Checking traversal ");
				// print(ftos(current_traversal));
				// print("'s neighbor poly ");
				// print(ftos(neighbor_poly));
				// print(".\n");

				if(cl_test_pathfind_result->poly_set[neighbor_poly] != PATHFIND_POLY_SET_CLOSED) {
					//print("Neighbor is not in closed list.\n");
					//Calculate tentative f score
					//Calculate tentative g score (distance from start to current + distance from current to neighbor)
					vector traversal_end_pos = cl_navmesh_get_traversal_end_pos(current_traversal);
					float tentative_g_score = cl_test_pathfind_result->traversal_g_score[current_traversal] + vlen(cl_navmesh_polies[neighbor_poly].center - traversal_end_pos);
					
					// If not in open-set, or this is a better score, set score for this polygon
					if(cl_test_pathfind_result->poly_set[neighbor_poly] != PATHFIND_POLY_SET_OPEN || tentative_g_score < cl_test_pathfind_result->poly_g_score[neighbor_poly]) {
						//print("Neighbor is not in open list, or a better g score has been found.\n");
						//Adding neighbor to open set
						cl_test_pathfind_result->poly_set[neighbor_poly] = PATHFIND_POLY_SET_OPEN;
						
						//Updating scores for neighbor node
						float tentative_f_score = tentative_g_score + cl_pathfind_calc_poly_h_score(neighbor_poly , goal_poly);
						cl_test_pathfind_result->poly_g_score[neighbor_poly] = tentative_g_score;
						cl_test_pathfind_result->poly_f_score[neighbor_poly] = tentative_f_score;
						
						//Linking neighbor node to current node (for tracing path)
						cl_test_pathfind_result->poly_prev_poly[neighbor_poly] = -1;
						cl_test_pathfind_result->poly_prev_traversal[neighbor_poly] = current_traversal;
						
						// print("Assigning Poly ");
						// print(ftos(neighbor_poly));
						// print(" came from traversal ");
						// print(ftos(current_traversal));
						// print(".\n");
					}
				}
			}
		}

		float best_openset_poly = cl_pathfind_get_lowest_f_score_poly();
		float best_openset_traversal = cl_pathfind_get_lowest_f_score_traversal();

		// print("Best openset poly: ");
		// print(ftos(best_openset_poly));
		// print("\n");
		// print("Best openset traversal: ");
		// print(ftos(best_openset_traversal));
		// print("\n");

		// If we have both, compare their f-scores
		if(best_openset_poly != -1 && best_openset_traversal != -1) {
			// If traversal score is better, don't consider polygon
			if(cl_test_pathfind_result->traversal_f_score[best_openset_poly] < cl_test_pathfind_result->poly_f_score[best_openset_poly]) {
				best_openset_poly = -1;
			}
			// If polygon score is better, don't consider traversal
			else {
				best_openset_traversal = -1;
			}
		}
		// Assign what we found, loop will terminate if we have neither
		current_traversal = best_openset_traversal;
		current_poly = best_openset_poly;
		// --------------------------------------------------------------------
	}

	//Tracing the pathfind results
	if(pathfind_success == TRUE) {
		cl_pathfind_trace_path(start_poly, goal_poly);
		cl_pathfind_smooth_path(start_pos, end_pos);
		return 1;
	}
	print("Pathfind fail");
	return 0;
}


//This renders the raw pathfind results (polygon center to polygon center)
void cl_navmesh_pathfind_draw_result_path() {
	if(cl_test_pathfind_result->path_length < 1)
		return;
	//================= Drawing Polygon Center ======================
	//=======================================
	//Assigning the shader as something else so that fte doesn't batch the calls (leading to colors not changing between draw calls)
	R_BeginPolygon("debug/wireframe",0);
	R_BeginPolygon("debug/solid_nocull",0);
	
	vector ofs = [0,0,-5];
	vector size = [5,5,5];
	vector color = [1,0.1,0.5];
	float alpha = 0.2;//0.3
	float edge_width = 2;
	float edge_alpha = 0.2;//0.3

	vector cur_point = '0 0 0';
	vector cur_end_point = '0 0 0';
	vector prev_point = '0 0 0';
	
	for(float i = 0; i < cl_test_pathfind_result->path_length; i++) {
		// Current path entry is a polygon, draw box at polygon center
		if(cl_test_pathfind_result->path_polygons[i] != -1) {
			cur_point = cl_navmesh_polies[cl_test_pathfind_result->path_polygons[i]].center + ofs;
			cur_end_point = cur_point;
			cl_navmesh_draw_box(cur_point, size, color, alpha);
		}
		// Current path entry is a traversal, draw box at start and end
		else if(cl_test_pathfind_result->path_traversals[i] != -1) {
			cur_point = cl_navmesh_traversals[cl_test_pathfind_result->path_traversals[i]].start_pos + ofs;
			cur_end_point = cl_navmesh_get_traversal_end_pos(cl_test_pathfind_result->path_traversals[i]) + ofs;
			cl_navmesh_draw_box(cur_point, size, color, alpha);
			cl_navmesh_draw_box(cur_end_point, size, color, alpha);
			cl_navmesh_draw_line(cur_end_point, cur_point, edge_width, color, edge_alpha);
		}

		// Draw an edge connecting i-th node to previous node
		if(i > 0) {
			cl_navmesh_draw_line(prev_point, cur_point, edge_width, color, edge_alpha);
		}

		prev_point = cur_end_point;
	}
}


void cl_navmesh_pathfind_draw_result_portals() {
	// TODO - Update this to account for traversals (at least once I implement funnel algorithm for traversals)
	if(cl_test_pathfind_result->portals_length < 1)
		return;
	vector color;
	color = [0.5,0.5,1.0];
	float edge_width = 4;
	float edge_alpha = 0.2;//0.3

	vector portal_left;
	vector portal_right;
	
	for(float i = 0; i < cl_test_pathfind_result->portals_length; i++) {
		portal_left = cl_test_pathfind_result->portals_left_pos[i];
		portal_right = cl_test_pathfind_result->portals_right_pos[i];

		cl_navmesh_draw_vert(portal_left + [0,0,-10],[0.5,0.5,1],0.4);
		cl_navmesh_draw_vert(portal_right + [0,0,-8],[0.5,1,0.5],0.4);
		
		R_BeginPolygon("debug/wireframe",0);
		R_BeginPolygon("debug/solid_nocull",0);
		
		//Draw an edge connecting portals
		cl_navmesh_draw_line(portal_left + [0,0,-10], portal_right + [0,0,-8], edge_width, color, edge_alpha);
	}
}

void cl_navmesh_pathfind_draw_result_point_path() {
	// TODO - Update this to account for traversals
	if(cl_test_pathfind_result->point_path_length < 1)
		return;
		
	vector color;
	color = [1.0,0.0,0.0];
	float edge_width = 4;
	float alpha = 0.4;
	float edge_alpha = 0.2;//0.3
	vector ofs = [0,0,10];
	
	//Drawing the a line connecting the start and first path node
	cl_navmesh_draw_vert(startent_pos + ofs, color, alpha);
	cl_navmesh_draw_line(startent_pos + ofs, cl_test_pathfind_result->point_path_points[0] + ofs, edge_width, color, edge_alpha);


	vector cur_point = '0 0 0';
	vector prev_point = '0 0 0';
	
	for(float i = 0; i < cl_test_pathfind_result->point_path_length; i++) {
		cur_point = cl_test_pathfind_result->point_path_points[i];
		cl_navmesh_draw_vert(cur_point + ofs, color, alpha);

		// TODO - if traversal, draw endpoint and line?
		
		if(i > 0) {
			//Draw an edge connecting path points
			cl_navmesh_draw_line(cur_point + ofs, prev_point + ofs, edge_width, color, edge_alpha);
		}
		prev_point = cur_point;
	}
}

void cl_toggle_navmesh_editor()
{
	
	
	if(cvar("navmesh_edit_mode")) {
		cvar_set("navmesh_edit_mode", "0");
		print("cl_navmesh editor: 0\n");
	}
	else {
		print("cl_navmesh editor: 1\n");
		cvar_set("navmesh_edit_mode", "1");

		if(selected_verts == 0) {
			selected_verts = memalloc(sizeof(float) * NAV_MAX_SELECTED_VERTS);
		}
		if(cl_navmesh_verts == 0) {
			cl_navmesh_verts = memalloc(sizeof(navmesh_vertex) * NAV_MAX_VERTS);
		}
		if(cl_navmesh_polies == 0) {
			cl_navmesh_polies = memalloc(sizeof(navmesh_poly) * NAV_MAX_POLIES);
		}
		if(cl_navmesh_traversals == 0) {
			cl_navmesh_traversals = memalloc(sizeof(navmesh_traversal) * NAV_MAX_TRAVERSALS);
		}
		// Allocate memory for pathfind result
		if(cl_test_pathfind_result == 0) {
			cl_test_pathfind_result = memalloc(sizeof(navmesh_pathfind_result));
			cl_pathfind_clear_result_data();
		}
		

		cl_navmesh_deselect_all();
		cl_navmesh_selected_traversal = -1;
		cl_navmesh_traversal_edit_mode = false;
		cl_navmesh_traversal_editor_cur_point = 0;
	}
}


void cl_register_navmesh_commands() = 
{
	registercommand("nav_editor");
	registercommand("nav_place_vert");
	registercommand("nav_delete_verts");
	registercommand("nav_select_vert");
	registercommand("nav_deselect_vert");
	registercommand("nav_deselect_all");
	registercommand("nav_make_poly");
	registercommand("nav_delete_poly");
	registercommand("nav_resolve_corner");
	registercommand("nav_place_corner");
	registercommand("nav_cancel_corner");
	registercommand("nav_confirm_corner");
	registercommand("nav_calc_connected_polies");
	registercommand("nav_calc_poly_centers");
	registercommand("navtest_place_goal");
	registercommand("navtest_place_start");
	registercommand("nav_save_navmesh");
	registercommand("nav_clear_navmesh");
	registercommand("y");
	registercommand("yes");
	registercommand("nav_load_navmesh");
	registercommand("nav_toggle_poly_door");
	registercommand("nav_print_poly_door");

	// --- Traversal Commands ---
	registercommand("nav_place_traversal");
	registercommand("nav_select_traversal");
	registercommand("nav_clone_traversal");
	registercommand("nav_delete_traversal");
	registercommand("nav_edit_traversal");
	registercommand("nav_next_traversal_type");
	registercommand("nav_prev_traversal_type");

	// --- Traversal Edit Mode Commands ---
	registercommand("nav_trav_next_point");
	registercommand("nav_trav_toggle_point");
	registercommand("nav_trav_get_point_pos");
	registercommand("nav_trav_set_point_pos");
	registercommand("nav_trav_get_angle");
	registercommand("nav_trav_set_angle");

}

float cl_confirm_clear_navmesh;

void cl_navmesh_editor_toggle_poly_door() {
	int selected_polygon = cl_navmesh_get_selected_poly();
	if(selected_polygon == -1) {
		print("Can't make door polygon. No polygon selected.\n");
		return;
	}

	// strcat will copy the string
	string editor_active_door = strcat(cvar_string("nav_editor_active_door"));

	// If current polygon doortarget isn't set to the editor's currently active door, set it
	// if(strcmp(cl_navmesh_polies[selected_polygon].doortarget, editor_active_door) != 0) {
	if(cl_navmesh_polies[selected_polygon].doortarget != editor_active_door) {
		cl_navmesh_polies[selected_polygon].doortarget = editor_active_door;
	}
	// Otherwise, clear it.
	else {
		cl_navmesh_polies[selected_polygon].doortarget = "";
	}

	print("Selected Polygon doortarget set to: \"");
	print(cl_navmesh_polies[selected_polygon].doortarget);
	print("\"\n");
}


// Print the currently selected polygon's doortarget field
void cl_navmesh_editor_print_poly_door() {
	int selected_polygon = cl_navmesh_get_selected_poly();
	if(selected_polygon == -1) {
		print("Can't print door polygon. No polygon selected.\n");
		return;
	}

	print("Current selected polygon (");
	print(itos(selected_polygon));
	print(") doortarget: \"");
	print(cl_navmesh_polies[selected_polygon].doortarget);
	print("\"\n");
}



void cl_navmesh_editor_place_traversal() {
	cl_navmesh_traversal_edit_mode = false;
	cl_navmesh_traversal_editor_cur_point = 0;

	if(cl_navmesh_traversal_count >= NAV_MAX_TRAVERSALS) {
		print("Can't add traversal, max traversal count has been reached.\n");
		return;
	}

	// Place the traversal at the player origin
	vector player_pos = getentity(player_localentnum, GE_ORIGIN);
	vector player_angles = getentity(player_localentnum, GE_ANGLES);
	cl_navmesh_traversals[cl_navmesh_traversal_count].start_pos.x = player_pos.x;
	cl_navmesh_traversals[cl_navmesh_traversal_count].start_pos.y = player_pos.y;
	cl_navmesh_traversals[cl_navmesh_traversal_count].start_pos.z = player_pos.z;

	// Make traversal face same direction as player
	cl_navmesh_traversals[cl_navmesh_traversal_count].angle = player_angles.y;

	// -------------------------------
	// Set up default traversal (teleport)
	// TODO - Move this to a separate function
	// -------------------------------
	// X - Right, Y - Forward, Z - up
	cl_navmesh_traversals[cl_navmesh_traversal_count].midpoint_pos = '0 24 24';
	cl_navmesh_traversals[cl_navmesh_traversal_count].use_midpoint = false;
	cl_navmesh_traversals[cl_navmesh_traversal_count].use_midpoint = true;
	cl_navmesh_traversals[cl_navmesh_traversal_count].end_pos = '0 48 0';
	// TODO - somehow set traversal type ID?
	// -------------------------------

	print("Traveral ");
	print(ftos(cl_navmesh_traversal_count));
	print(" created at ", vtos(player_pos),"\n");
	print("Angles:");
	print(vtos(player_angles));
	
	// Immediately select it
	cl_navmesh_selected_traversal = cl_navmesh_traversal_count;
	cl_navmesh_traversal_count++;
};



float cl_navmesh_get_nearest_traversal() {
	if(cl_navmesh_traversal_count <= 0) {
		return -1;
	}
	
	vector player_pos = getentity(player_localentnum, GE_ORIGIN);
	float closest_dist = vlen(player_pos - cl_navmesh_traversals[0].start_pos);
	float closest_index = 0;
	
	float temp_dist;
	
	for(float i = 1; i < cl_navmesh_traversal_count; i++)
	{
		temp_dist = vlen(player_pos - cl_navmesh_traversals[i].start_pos);
		
		if(temp_dist < closest_dist)
		{
			closest_dist = temp_dist;
			closest_index = i;
		}
	}
	return closest_index;
}

// Copies a traversal from index src to index dest
void cl_navmesh_editor_copy_traversal(float src, float dest, float copy_pos, float copy_angle) {
	if(copy_pos) {
		cl_navmesh_traversals[dest].start_pos = 	cl_navmesh_traversals[src].start_pos;
	}
	if(copy_angle) {
		cl_navmesh_traversals[dest].angle = 		cl_navmesh_traversals[src].angle;
	}
	cl_navmesh_traversals[dest].end_pos = 		cl_navmesh_traversals[src].end_pos;
	cl_navmesh_traversals[dest].midpoint_pos = 	cl_navmesh_traversals[src].midpoint_pos;
	cl_navmesh_traversals[dest].use_midpoint = 	cl_navmesh_traversals[src].use_midpoint;
}


// Selects the nearest traversal (if nearest traversal is selcted, deselects it)
void cl_navmesh_editor_select_traversal() {
	cl_navmesh_traversal_edit_mode = false;
	cl_navmesh_traversal_editor_cur_point = 0;

	int trav_idx = cl_navmesh_get_nearest_traversal();
	if(trav_idx == -1) {
		print("No traversals to select");
		return;
	}
	if(trav_idx == cl_navmesh_selected_traversal) {
		print("Travseral deselected.\n");
		cl_navmesh_selected_traversal = -1;
		return;
	}
	
	print("Traversal ");
	print(ftos(trav_idx));
	print(" selected.\n");

	cl_navmesh_selected_traversal = trav_idx;
};


void cl_navmesh_editor_clone_traversal() {
	cl_navmesh_traversal_edit_mode = false;
	cl_navmesh_traversal_editor_cur_point = 0;

	if(cl_navmesh_traversal_count >= NAV_MAX_TRAVERSALS) {
		print("Can't clone traversal, max traversal count has been reached.\n");
		return;
	}
	float prev_trav = cl_navmesh_selected_traversal;
	cl_navmesh_editor_place_traversal();
	// place_traversal implicitly updates `cl_navmesh_selected_traversal` to the new one
	cl_navmesh_editor_copy_traversal(prev_trav, cl_navmesh_selected_traversal, false, false);
};


void cl_navmesh_editor_delete_traversal() {
	cl_navmesh_traversal_edit_mode = false;
	cl_navmesh_traversal_editor_cur_point = 0;

	if(cl_navmesh_selected_traversal == -1) {
		print("No traversal selected.\n");
		return;
	}

	print("Deleting traversal: ");
	print(ftos(cl_navmesh_selected_traversal));
	print(".\n");
	
	//Bringing all traversals down to not leave any holes in the array
	//Moving down every index to the right of what is selected to not leave any holes
	for(float i = cl_navmesh_selected_traversal; i < cl_navmesh_traversal_count - 1; i++) {
		// Copy traversal (i+1) to traversal (i)
		cl_navmesh_editor_copy_traversal(i+1, i, true, true);
	}
	// TOOD - Clear the last one?
	cl_navmesh_traversal_count--;
	// TODO - Fix any references from polygons -> traversals?
	cl_navmesh_selected_traversal = -1;
};

void cl_navmesh_editor_edit_traversal() {
	if(cl_navmesh_selected_traversal == -1) {
		print("No traversal selected.\n");
		return;
	}
	
	if(cl_navmesh_traversal_edit_mode) {
		cl_navmesh_traversal_edit_mode = false;
	}
	else {
		cl_navmesh_traversal_edit_mode = true;
	}
	cl_navmesh_traversal_editor_cur_point = 0;
};

void cl_navmesh_editor_next_traversal_type() {
	// TODO - Scroll through list once traversals are defined
};

void cl_navmesh_editor_prev_traversal_type() {
	// TODO - Scroll through list once traversals are defined
};

void cl_navmesh_traversal_editor_next_point() {
	if(cl_navmesh_selected_traversal == -1) {
		print("No traversal selected.\n");
		return;
	}
	if(cl_navmesh_traversal_edit_mode == false) {
		print("Not in traversal edit mode.\n");
		return;
	}
	cl_navmesh_traversal_editor_cur_point = (cl_navmesh_traversal_editor_cur_point + 1) % 3;
};

void cl_navmesh_traversal_editor_toggle_point() {
	if(cl_navmesh_selected_traversal == -1) {
		print("No traversal selected.\n");
		return;
	}
	if(cl_navmesh_traversal_edit_mode == false) {
		print("Not in traversal edit mode.\n");
		return;
	}
	if(cl_navmesh_traversal_editor_cur_point != 1){
		print("Can only toggle midpoint.\n");
		return;
	}
	if(cl_navmesh_traversals[cl_navmesh_selected_traversal].use_midpoint) {
		cl_navmesh_traversals[cl_navmesh_selected_traversal].use_midpoint = false;
	}
	else {
		cl_navmesh_traversals[cl_navmesh_selected_traversal].use_midpoint = true;
	}
};

void cl_navmesh_traversal_editor_get_point_pos() {
	if(cl_navmesh_selected_traversal == -1) {
		print("No traversal selected.\n");
		return;
	}
	if(cl_navmesh_traversal_edit_mode == false) {
		print("Not in traversal edit mode.\n");
		return;
	}
	if(cl_navmesh_traversal_editor_cur_point == 0) {
		print("Traversal start point: ");
		print(vtos(cl_navmesh_traversals[cl_navmesh_selected_traversal].start_pos));
		print(".\n");
	}
	else if(cl_navmesh_traversal_editor_cur_point == 1) {
		print("Traversal mid point: ");
		print(vtos(cl_navmesh_traversals[cl_navmesh_selected_traversal].midpoint_pos));
		print(". (relative to start point)\n");
	}
	else if(cl_navmesh_traversal_editor_cur_point == 2) {
		print("Traversal end point: ");
		print(vtos(cl_navmesh_traversals[cl_navmesh_selected_traversal].end_pos));
		print(". (relative to start point)\n");
	}
};

void cl_navmesh_traversal_editor_set_point_pos(vector pos) {
	if(cl_navmesh_selected_traversal == -1) {
		print("No traversal selected.\n");
		return;
	}
	if(cl_navmesh_traversal_edit_mode == false) {
		print("Not in traversal edit mode.\n");
		return;
	}

	if(cl_navmesh_traversal_editor_cur_point == 0) {
		cl_navmesh_traversals[cl_navmesh_selected_traversal].start_pos = pos;

		print("Traversal start pos set to: ");
		print(vtos(cl_navmesh_traversals[cl_navmesh_selected_traversal].start_pos));
		print(".\n");
	}
	else if(cl_navmesh_traversal_editor_cur_point == 1) {
		cl_navmesh_traversals[cl_navmesh_selected_traversal].midpoint_pos = pos;

		print("Traversal mid pos set to: ");
		print(vtos(cl_navmesh_traversals[cl_navmesh_selected_traversal].midpoint_pos));
		print(". (relative to start pos)\n");
	}
	else if(cl_navmesh_traversal_editor_cur_point == 2) {
		cl_navmesh_traversals[cl_navmesh_selected_traversal].end_pos = pos;

		print("Traversal end pos set to: ");
		print(vtos(cl_navmesh_traversals[cl_navmesh_selected_traversal].end_pos));
		print(". (relative to start pos)\n");
	}


};

void cl_navmesh_traversal_editor_get_angle() {
	if(cl_navmesh_selected_traversal == -1) {
		print("No traversal selected.\n");
		return;
	}
	if(cl_navmesh_traversal_edit_mode == false) {
		print("Not in traversal edit mode.\n");
		return;
	}

	print("Traversal angle: ");
	print(ftos(cl_navmesh_traversals[cl_navmesh_selected_traversal].angle));
	print(".\n");
};

void cl_navmesh_traversal_editor_set_angle(float angle) {
	if(cl_navmesh_selected_traversal == -1) {
		print("No traversal selected.\n");
		return;
	}
	if(cl_navmesh_traversal_edit_mode == false) {
		print("Not in traversal edit mode.\n");
		return;
	}

	cl_navmesh_traversals[cl_navmesh_selected_traversal].angle = angle;

	print("Traversal angle set to: ");
	print(ftos(cl_navmesh_traversals[cl_navmesh_selected_traversal].angle));
	print(".\n");
};


















float(string cmd) cl_navmesh_console_commands = 
{
	tokenize(cmd);
	switch(argv(0))
	{
		case "nav_editor":
			cl_toggle_navmesh_editor();
			return TRUE;
		default:
			break;
	}
	
	//nav_clear_navmesh must be run twice consecutively to execute it (for safety)
	switch(argv(0))
	{
		case "nav_clear_navmesh":
			cl_confirm_clear_navmesh = 1;
			print("Are you sure you want to clear the navmesh? All unsaved changes will be lost.\n");
			return TRUE;
		case "y":
		case "yes":
			if(cl_confirm_clear_navmesh == 1)
			{
				print("Navmesh cleared.\n");
				cl_navmesh_editor_clear_navmesh();
			}
			cl_confirm_clear_navmesh = 0;
			return TRUE;
		default:
			cl_confirm_clear_navmesh = 0;
			break;
	}
	
	if(!cvar("navmesh_edit_mode"))
		return FALSE;
	switch(argv(0))
	{
		case "nav_place_vert":
			cl_navmesh_place_vert();
			return TRUE;
		case "nav_delete_verts":
			cl_navmesh_delete_verts();
			return TRUE;
		case "nav_select_vert":
			cl_navmesh_select_vert();
			return TRUE;
		case "nav_deselect_vert":
			cl_navmesh_deselect_vert();
			return TRUE;
		case "nav_deselect_all":
			cl_navmesh_deselect_all();
			print("All vertices deselected.\n");
			return TRUE;
		case "nav_make_poly":
			cl_navmesh_make_poly();
			return TRUE;
		case "nav_delete_poly":
			cl_navmesh_delete_poly();
			return TRUE;
		case "nav_resolve_corner":
			cl_navmesh_resolve_corner();
			return TRUE;
		case "nav_place_corner":
			cl_navmesh_place_corner();
			return TRUE;
		case "nav_cancel_corner":
			cl_navmesh_cancel_corner();
			return TRUE;
		case "nav_confirm_corner":
			cl_navmesh_confirm_corner();
			return TRUE;
		case "nav_calc_connected_polies":
			cl_navmesh_calc_connected_polies();
			return TRUE;
		case "nav_calc_poly_centers":
			cl_navmesh_calc_polies_centers();
			return TRUE;
		case "navtest_place_goal":
			cl_navmesh_place_test_goalent();
			return TRUE;
		case "navtest_place_start":
			cl_navmesh_place_test_startent();
			return TRUE;
		case "nav_save_navmesh":
			cl_navmesh_editor_save_navmesh();
			return TRUE;
		case "nav_load_navmesh":
			cl_navmesh_editor_load_navmesh();
			return TRUE;
		case "nav_toggle_poly_door":
			cl_navmesh_editor_toggle_poly_door();
			return TRUE;
		case "nav_print_poly_door":
			cl_navmesh_editor_print_poly_door();
			return TRUE;
		case "nav_place_traversal":
			cl_navmesh_editor_place_traversal();
			return TRUE;
		case "nav_select_traversal":
			cl_navmesh_editor_select_traversal();
			return TRUE;
		case "nav_clone_traversal":
			cl_navmesh_editor_clone_traversal();
			return TRUE;
		case "nav_delete_traversal":
			cl_navmesh_editor_delete_traversal();
			return TRUE;
		case "nav_edit_traversal":
			cl_navmesh_editor_edit_traversal();
			return TRUE;
		case "nav_next_traversal_type":
			cl_navmesh_editor_next_traversal_type();
			return TRUE;
		case "nav_prev_traversal_type":
			cl_navmesh_editor_prev_traversal_type();
			return TRUE;
		case "nav_trav_next_point":
			cl_navmesh_traversal_editor_next_point();
			return TRUE;
		case "nav_trav_toggle_point":
			cl_navmesh_traversal_editor_toggle_point();
			return TRUE;
		case "nav_trav_get_point_pos":
			cl_navmesh_traversal_editor_get_point_pos();
			return TRUE;
		case "nav_trav_set_point_pos":
			cl_navmesh_traversal_editor_set_point_pos(stov(argv(1)));
			return TRUE;
		case "nav_trav_get_angle":
			cl_navmesh_traversal_editor_get_angle();
			return TRUE;
		case "nav_trav_set_angle":
			cl_navmesh_traversal_editor_set_angle(stof(argv(1)));
			return TRUE;
		default:
			break;
	}
	return FALSE;
}