/*
	server/ai/pathfind_core.qc

    Navmesh-based pathfinding

	Copyright (C) 2021 NZ:P Team

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

//===========================================================================================================
//==================================== Navmesh-based Pathfinding Functions ==================================
//===========================================================================================================

//Calculates the heuristic h score value (Our best guess for how far this node is from the goal node)
float sv_pathfind_calc_h_score(float current, float goal)
{
	//FIXME: we could just as easily return vlen()^2 for comparisons... (saves a sqrt operation)
	return vlen(sv_navmesh_polies[goal].center - sv_navmesh_polies[current].center);
}

//Returns the polygon with the lowest f score from polygons the open set
float sv_pathfind_get_lowest_f_score(navmesh_pathfind_result* res)
{
	//TODO: implement a better algorithm for finding the lowest score
	float best_score = 100000;
	float best_score_index = -1;
	
	for(float i = 0; i < sv_navmesh_poly_count; i++)
	{
		if(res->poly_set[i] == PATHFIND_POLY_SET_OPEN)
		{
			if(res->poly_f_score[i] < best_score)
			{
				best_score = res->poly_f_score[i];
				best_score_index = i;
			}
		}
	}
	return best_score_index;
}

void sv_pathfind_clear_result_data(navmesh_pathfind_result* res) {
	//Technically we only need to iterate over navmesh_poly_count...
	for(float i = 0; i < NAV_MAX_POLIES; i++) {
		res->poly_set[i] = PATHFIND_POLY_SET_NONE;
		res->poly_prev_poly[i] = -1;
		res->poly_prev_traversal[i] = -1;
		res->poly_g_score[i] = 0;
		res->poly_f_score[i] = 0;

		res->path_polygons[i] = -1;
		res->path_traversals[i] = -1;
				
		res->portals_left_pos[i].x = 0;
		res->portals_left_pos[i].y = 0;
		res->portals_left_pos[i].z = 0;
		res->portals_right_pos[i].x = 0;
		res->portals_right_pos[i].y = 0;
		res->portals_right_pos[i].z = 0;
		res->portals_traversal[i] = -1;

		res->point_path_points[i].x = 0;
		res->point_path_points[i].y = 0;
		res->point_path_points[i].y = 0;
		res->point_path_traversals[i] = -1;
	}
	for(float i = 0;i < NAV_MAX_TRAVERSALS; i++) {
		res->traversal_set[i] = PATHFIND_POLY_SET_NONE;
		res->traversal_prev_poly[i] = -1;
		res->traversal_g_score[i] = 0;
		res->traversal_f_score[i] = 0;
	}
	res->path_length = 0;
	res->portals_length = 0;
	res->point_path_length = 0;
}

//Applies a funnel algorithm to the path defined by the array res->result_node_path 
// and populates pathfind result path
void sv_pathfind_smooth_path(vector start_point, vector goal_point, navmesh_pathfind_result* res) {};
// void sv_pathfind_smooth_path(vector start_point, vector goal_point, navmesh_pathfind_result* res) {
// 	//Evaluate portals and identify left / right portal vertices
// 	for(float i = 1; i < res->result_node_length; i++)
// 	{
// 		float prev_poly = res->result_node_path[i-1];
// 		float poly = res->result_node_path[i];
		
// 		//TODO: find link index of portal
		
// 		//Finding what index prev_poly is linked to poly
		
// 		float link_index = -1;
		
// 		for(float j = 0; j < sv_navmesh_polies[prev_poly].connected_polies_count; j++)
// 		{
// 			if(sv_navmesh_polies[prev_poly].connected_polies[j] == poly)
// 			{
// 				link_index = j;
// 				break;
// 			}
// 		}
		
// 		//Use that index to get left and right vertices
// 		res->portals_left_vert[res->portals_length] = sv_navmesh_polies[prev_poly].connected_polies_left_vert[link_index];
// 		res->portals_right_vert[res->portals_length++] = sv_navmesh_polies[prev_poly].connected_polies_right_vert[link_index];
// 	}
// 	//the last left edge / right edge is the goal position
	
// 	/*print("Portals: ");
// 	for(float i = 0; i < res->portals_length; i++)
// 	{
// 		print("[");
// 		print(ftos(i));
// 		print("] = (");
// 		print(ftos(res->portals_left_vert[i]));
// 		print(" , ");
// 		print(ftos(res->portals_right_vert[i]));
// 		print(") , ");
// 	}*/
	
// 	//starting at start_pos (not at start center point)
// 	//get vectors that point to first left edge and first right edge
	
// 	vector funnel_apex = start_point;
// 	float funnel_left_index = 0;
// 	//Index of the funnel's left vertex in the portal list
// 	vector funnel_left = sv_navmesh_verts[res->portals_left_vert[0]].pos;
// 	//Index of the funnel's right vertex in the portal list
// 	float funnel_right_index = 0;
// 	vector funnel_right = sv_navmesh_verts[res->portals_right_vert[0]].pos;
	
// 	vector next_funnel_left = '0 0 0';
// 	vector next_funnel_right = '0 0 0';
//     vector corner;
//     int portal_idx;
	
	
// 	float inside_right_edge;
// 	float inside_left_edge;
	
// 	while(1)
// 	{
// 		//print("=============Funnel iteration.==========\n");
// 		//Check if we have reached the end of the portals, consider the goal position as the last portal
// 		//If we are not at the last index of the left portal
		
// 		//Keeping track of whether or not advancing the left edge or right edge narrows the funnel
// 		float advanced_left = FALSE;
// 		float advanced_right = FALSE;
		
		
		
// 		//Consider the end goal point as the last portal
// 		//================ Checking left funnel edge =================
// 		if(funnel_left_index < res->portals_length)
// 		{
// 			//print("Trying to advance left edge.\n");
			
// 			if(funnel_left_index < res->portals_length - 1)
// 			{
// 				next_funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index+1]].pos;
// 			//	print("Next left edge is vert: ",ftos(res->portals_left_vert[funnel_left_index+1],".\n");
// 			}
// 			else
// 			{
// 			//	print("Trying next left edge as goal point.\n");
// 				//If funnel_left is pointing to the last portal in the array, consider the goal_point the last portal
// 				next_funnel_left = goal_point;
// 			}

// 			inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_left);
// 			//If the next left edge crosses the current right edge
// 			if(inside_right_edge < 0)
// 			{
// 				//print("next left edge crosses current right edge.\n");
// 				//Add funnel right point to path
// 				// res->result_path[res->result_length++] = funnel_right;
// 				corner = funnel_right;
// 				// ------------------------------------------------------------
// 				// Instead of adding the funnel's corner to the path, 
// 				// move away from the corner by some small amount
// 				// ------------------------------------------------------------
// 				// Find the first portal along the path with this corner
// 				portal_idx = funnel_right_index;
// 				for(int i = funnel_right_index; i >= 0; i--) {
// 					if(res->portals_right_vert[i] == res->portals_right_vert[funnel_right_index]) {
// 						portal_idx = i;
// 						continue;
// 					}
// 					break;
// 				}
// 				// For every portal with this corner, add a point to the path
// 				for(int i = portal_idx; i <= funnel_right_index; i++) {
// 					// Find the vertex opposite this portal edge
// 					vector opposite_corner = sv_navmesh_verts[res->portals_left_vert[i]].pos;
// 					// Move 20 qu or 20% of the edge length, whichever is smaller:
// 					float edge_len = vlen(opposite_corner - corner);
// 					vector edge_dir = normalize(opposite_corner - corner);
// 					vector delta_corner = edge_dir * min(edge_len * 0.2, 20);
// 					res->result_path[res->result_length++] = corner + delta_corner;
// 				}
// 				// ------------------------------------------------------------
// 				// res->result_path[res->result_length++] = corner;


// 				// TODO - Move 10% of the way the funnel's right portal vert to the left
				
// 				//Check if we are at the end of our portal list
// 				if(funnel_right_index >= res->portals_length - 1)
// 				{
// 					res->result_path[res->result_length++] = goal_point;
// 					return;
// 				}
				
				
// 				//Restart algorithm with the portal after the right point
// 				funnel_apex = funnel_right;
				
// 				funnel_left_index = funnel_right_index + 1;
// 				funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index]].pos;
// 				funnel_right_index = funnel_right_index + 1;
// 				funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index]].pos;
// 				continue;
// 			}
// 			//If the next left edge is in the funnel
// 			inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_left);
// 			if(inside_left_edge >= 0 && inside_right_edge >= 0)
// 			{
// 				//print("next left edge is in the funnel.\n");
// 				//Advance the left edge
// 				funnel_left = next_funnel_left;
// 				funnel_left_index++;
				
// 				advanced_left = TRUE;
				
// 				//Check if the portal we just added was the goal point (will be after the list)
// 				if(funnel_left_index >= res->portals_length)
// 				{
// 					res->result_path[res->result_length++] = goal_point;
// 					return;
// 				}
// 			}
// 		}
// 		//================ Checking right funnel edge =================
// 		if(funnel_right_index < res->portals_length)
// 		{
// 			//print("Trying to advance right edge:.\n");
			
// 			if(funnel_right_index < res->portals_length - 1)
// 			{
// 				next_funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index+1]].pos;
// 				//print("Next right edge is vert: ",ftos(res->portals_right_vert[funnel_right_index+1]),".\n");
// 			}
// 			else
// 			{
// 				//print("Trying next right edge as goal point.\n");
// 				//If funnel_right is pointing to the last portal in the array, consider the goal_point the last portal
// 				next_funnel_right = goal_point;
// 			}
			
// 			//If the next right edge crosses the current left edge
// 			inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_right);
// 			if(inside_left_edge < 0)
// 			{
// 				//print("next right edge crosses current left edge.\n");
// 				//Add funnel left point to path
// 				// res->result_path[res->result_length++] = funnel_left;
// 				corner = funnel_left;
// 				// ------------------------------------------------------------
// 				// Instead of adding the funnel's corner to the path, 
// 				// move away from the corner by some small amount
// 				// ------------------------------------------------------------
// 				// Find the first portal along the path with this corner
// 				portal_idx = funnel_left_index;
// 				for(int i = funnel_left_index; i >= 0; i--) {
// 					if(res->portals_left_vert[i] == res->portals_left_vert[funnel_left_index]) {
// 						portal_idx = i;
// 						continue;
// 					}
// 					break;
// 				}
// 				// For every portal with this corner, add a point to the path
// 				for(int i = portal_idx; i <= funnel_left_index; i++) {
// 					// Find the vertex opposite this portal edge
// 					vector opposite_corner = sv_navmesh_verts[res->portals_right_vert[i]].pos;
// 					// Move 20 qu or 20% of the edge length, whichever is smaller:
// 					float edge_len = vlen(opposite_corner - corner);
// 					vector edge_dir = normalize(opposite_corner - corner);
// 					vector delta_corner = edge_dir * min(edge_len * 0.2, 20);
// 					res->result_path[res->result_length++] = corner + delta_corner;
// 				}
// 				// ------------------------------------------------------------
// 				// res->result_path[res->result_length++] = corner;
				
// 				//Check if we are at the end of our portal list
// 				if(funnel_left_index >= res->portals_length - 1)
// 				{
// 					res->result_path[res->result_length++] = goal_point;
// 					return;
// 				}
				
				
// 				//Restart algorithm with the portal after the right point
// 				funnel_apex = funnel_left;
				
// 				funnel_right_index = funnel_left_index + 1;
// 				funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index]].pos;
// 				funnel_left_index = funnel_left_index + 1;
// 				funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index]].pos;
// 				continue;
// 			}
// 			//If the next right edge is in the funnel
// 			inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_right);			
// 			if(inside_left_edge >= 0 && inside_right_edge >= 0)
// 			{
// 				//print("next right edge is in the funnel.\n");
// 				//Advance the left edge
// 				funnel_right = next_funnel_right;
// 				funnel_right_index++;
				
// 				advanced_right = TRUE;
				
// 				//Check if the portal we just added was the goal point (will be after the list)
// 				if(funnel_right_index >= res->portals_length)
// 				{
// 					res->result_path[res->result_length++] = goal_point;
// 					return;
// 				}
// 			}
// 		}
// 		if(advanced_left == FALSE && advanced_right == FALSE)
// 		{
// 			//print("Hit funnel freeze condition.\n");
			
// 			float left_vert = -1;
// 			float left_type = -1;
// 			float left_portal_index = -1;//index of the vertex in the list of portals
			
// 			float right_vert = -1;
// 			float right_type = -1;
// 			float right_portal_index = -1;//index of the vertex in the list of portals
			
// 			float crossed = 1;//Indicates the vert crossed the funnel
// 			float contained = 2;//Indicates a vert is in the funnel
			
// 			float last_vert = -1;//used to skip calculating the same vertex more than once
			
			
// 			//Find the closest vertex in the portal left with the lowest index that crosses the funnel or is in the funnel
// 			for(float i = funnel_left_index + 1; i < res->portals_length + 1; i++)
// 			{
// 				if(i < res->portals_length - 1)
// 				{
// 					//Don't calculate the same vertex again
// 					if(last_vert == res->portals_left_vert[i])
// 						continue;
// 					last_vert = res->portals_left_vert[i];
// 					next_funnel_left = sv_navmesh_verts[last_vert].pos;
// 				}
// 				else//consider goal pos as last portal edge
// 				{
// 					next_funnel_left = goal_point;
// 				}
				
// 				inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_left);
				
// 				//If the left vertex crosses the funnel (left vertex is outside the funnel's right edge)
// 				if(inside_right_edge < 0)
// 				{
// 					left_vert = res->portals_left_vert[i];
// 					left_type = crossed;
// 					break;
// 				}
				
// 				inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_left);
				
// 				//If the left vertex is within the funnel
// 				if(inside_left_edge >= 0 && inside_right_edge >= 0)
// 				{
// 					left_vert = res->portals_left_vert[i];
// 					left_type = contained;
// 					left_portal_index = i;
// 					break;
// 				}
// 			}
			
// 			last_vert = -1;
			
// 			//Find the closest vertex in the portal right with the lowest index that crosses the funnel or is in the funnel
// 			for(float i = funnel_right_index + 1; i < res->portals_length; i++)
// 			{
// 				if(i < res->portals_length - 1)
// 				{
// 					//Don't calculate the same vertex again
// 					if(last_vert == res->portals_right_vert[i])
// 						continue;
// 					last_vert = res->portals_right_vert[i];
// 					next_funnel_right = sv_navmesh_verts[last_vert].pos;
// 				}
// 				else//consider goal pos as last portal edge
// 				{
// 					next_funnel_right = goal_point;
// 				}
				
// 				inside_left_edge = pathfind_point_is_to_left(funnel_left,funnel_apex,next_funnel_right);
				
// 				//If the right vertex crosses the funnel (right vertex is outside the funnel's left edge)
// 				if(inside_left_edge < 0)
// 				{
// 					right_vert = res->portals_right_vert[i];
// 					right_type = crossed;
// 					break;
// 				}
				
// 				inside_right_edge = pathfind_point_is_to_left(funnel_apex,funnel_right,next_funnel_right);
				
// 				//If the right vertex is within the funnel
// 				if(inside_left_edge >= 0 && inside_right_edge >= 0)
// 				{
// 					right_vert = res->portals_right_vert[i];
// 					right_type = contained;
// 					right_portal_index = i;
// 					break;
// 				}
// 			}
			
// 			//If no vertices were found, goal is reachable from here
// 			if(left_vert == -1 && right_vert == -1)
// 			{
// 				res->result_path[res->result_length++] = goal_point;
// 				return;
// 			}
			
			
// 			float use_left;
			
// 			//If both verts were found
// 			//Find which vertex has a lower index
// 			if(left_vert != -1 && right_vert != -1) 
// 			{
// 				if(left_portal_index < right_portal_index)
// 				{	
// 					use_left = TRUE;
// 				}
// 				else
// 				{	
// 					use_left = FALSE;
// 				}	
// 			}
			
// 			//if left vert was found
// 			else if(left_vert != -1)
// 			{
// 				use_left = TRUE;
// 			}
// 			//else right vert was found
// 			else
// 			{
// 				use_left = FALSE;
// 			}
			
// 			if(use_left)
// 			{
// 				if(left_type == crossed)
// 				{
// 					//Place corner at current right funnel edge
// 					res->result_path[res->result_length++] = funnel_right;
					
// 					//Restart algorithm with the portal after the right point
// 					funnel_apex = funnel_right;
					
// 					//Check if portal after this portal is goal:
// 					funnel_right_index++;
// 					if(funnel_right_index >= res->portals_length)
// 					{
// 						res->result_path[res->result_length++] = goal_point;
// 						return;
// 					}
					
// 					funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index]].pos;
// 					funnel_left_index = funnel_right_index;
// 					funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index]].pos;
// 					continue;
// 				}
// 				else//in funnel
// 				{
// 					//If the next funnel right is the goal, we are done
// 					//Check if portal after this portal is goal:
// 					if(right_portal_index >= res->portals_length)
// 					{
// 						res->result_path[res->result_length++] = goal_point;
// 						return;
// 					}
// 					//Update current left funnel edge to use this vertex
// 					funnel_left = next_funnel_left;
// 					funnel_left_index = left_portal_index;
					
// 					continue;
// 				}
// 			}
// 			else//use right
// 			{
// 				if(right_type == crossed)
// 				{
// 					//Place corner at current left funnel edge
// 					res->result_path[res->result_length++] = funnel_left;
					
// 					//Restart algorithm with the portal after the left point
// 					funnel_apex = funnel_left;
					
// 					//Check if portal after this portal is goal:
// 					funnel_left_index++;
// 					if(funnel_left_index >= res->portals_length)
// 					{
// 						res->result_path[res->result_length++] = goal_point;
// 						return;
// 					}
					
// 					funnel_left = sv_navmesh_verts[res->portals_left_vert[funnel_left_index]].pos;
// 					funnel_right_index = funnel_left_index;
// 					funnel_right = sv_navmesh_verts[res->portals_right_vert[funnel_right_index]].pos;
// 					continue;
// 				}
// 				else//in funnel
// 				{
// 					//If the next funnel right is the goal, we are done
// 					//Check if portal after this portal is goal:
// 					if(right_portal_index >= res->portals_length)
// 					{
// 						res->result_path[res->result_length++] = goal_point;
// 						return;
// 					}
// 					//Update current right funnel edge to use this vertex
// 					funnel_right = next_funnel_right;
// 					funnel_right_index = right_portal_index;
					
// 					continue;
// 				}
// 			}			
// 		}
// 	//print("==========================\n");
// 	}
// }

//Evaluates the path that is found in the pathfinding algorithm and populates an array with the nodes in the path from start to goal
void sv_pathfind_trace_path(float start, float goal, navmesh_pathfind_result* res) {}
// void sv_pathfind_trace_path(float start, float goal, navmesh_pathfind_result* res) 
// {
// 	float current = start;
// 	//Count the length of the path (how many polygons the path traverses)
// 	current = goal;
// 	res->result_node_length = 1;
// 	do
// 	{
// 		//print("Poly ");
// 		//print(ftos(current));
// 		//print(" came from  ");
// 		//print(ftos(res->poly_prev[current]));
// 		//print(".\n");
// 		current = res->poly_prev[current];
// 		res->result_node_length++;
// 	} while(current != start);
	
	
// 	//Starting at goal waypoint, add the traversed waypoints to the result path in reverse order
// 	current = goal;
// 	for(float i = 0; i < res->result_node_length; i++)
// 	{
// 		res->result_node_path[res->result_node_length - 1 - i] = current;
// 		current = res->poly_prev[current];
// 	}
	
	
// 	// print("Pathfind success, path length: ");
// 	// print(ftos(res->result_node_length));
// 	// print(", Path: [");
// 	// for(float i = 0; i < res->result_node_length; i++)
// 	// {
// 	// 	if(i > 0)
// 	// 		print(" , ");
// 	// 	print(ftos(res->result_node_path[i]));
// 	// }
// 	// print(" ].\n");
// }

//Accepts start polygon and goal polygon
//Returns 1 on success.
//Returns 0 on fail.
float sv_navmesh_pathfind_start(float start, float goal, vector start_pos, vector end_pos, navmesh_pathfind_result* res) {}
// float sv_navmesh_pathfind_start(float start, float goal, vector start_pos, vector end_pos, navmesh_pathfind_result* res) {
// 	if(start == -1) {
// 		//print("Error: pathfind start node invalid.\n");
// 		return 0;
// 	}
// 	if(goal == -1) {
// 		//print("Error: pathfind goal node invalid.\n");
// 		return 0;
// 	}
// 	if(start == goal) {
// 		//Calculating node path
// 		res->result_node_path[0] = start;
// 		res->result_node_length = 1;
// 		// print("Pathind success: trivial case (start = goal).\n");
		
// 		//Calculating vector based path (go directly to goal)
// 		res->result_path[0].x = end_pos.x;
// 		res->result_path[0].y = end_pos.y;
// 		res->result_path[0].z = end_pos.z;
// 		res->result_length = 1;
// 		return 1;
// 	}
	
// 	//Clearing previous data
// 	sv_pathfind_clear_result_data(res);
	
// 	//Adding start polygon to the open set
// 	res->poly_set[start] = PATHFIND_POLY_SET_OPEN;
// 	res->poly_g_score[start] = 0;
// 	res->poly_f_score[start] = 0 + sv_pathfind_calc_h_score(start , goal);
	
// 	//Fields that need to be set:
// 	//res->poly_set[NAV_MAX_POLIES];
// 	//res->prev_poly[NAV_MAX_POLIES];
// 	//res->poly_g_score[NAV_MAX_POLIES];
// 	//res->poly_f_score[NAV_MAX_POLIES];
	
// 	// print("Pathfind init. Start: ");
// 	// print(ftos(start));
// 	// print(" , Goal: ");
// 	// print(ftos(goal));
// 	// print(".\n");
	
// 	float current = start;
	
// 	float pathfind_success = FALSE;
	
// 	while(current != -1) {
// 		if(current == goal) {
// 			//print("Current is now goal. Breaking.\n");
// 			pathfind_success = TRUE;
// 			break;
// 		}
// 		//Add current node to the closed set
// 		res->poly_set[current] = PATHFIND_POLY_SET_CLOSED;
// 		//Add connected nodes to the open set
// 		for(float i = 0; i < sv_navmesh_polies[current].connected_polies_count; i++) {
// 			float neighbor = sv_navmesh_polies[current].connected_polies[i];
			
// 			//print("Checking poly ");
// 			//print(ftos(current));
// 			//print("'s neighbor ");
// 			//print(ftos(neighbor));
// 			//print(".\n");

// 			// ----------------------------------------------------------------
// 			// Door check
// 			// ----------------------------------------------------------------
// 			// If this polygon references a door:
// 			if(sv_navmesh_polies[neighbor].doortarget != "") {
// 				entity door;
// 				door = find(world, wayTarget, sv_navmesh_polies[neighbor].doortarget);
// 				if(door != world) {
// 					// If the referenced door is closed, don't consider this polygon.
// 					if(door.state == STATE_BOTTOM) {
// 						continue;
// 					}
// 				}
// 			}
// 			// ----------------------------------------------------------------

// 			// ----------------------------------------------------------------
// 			// Entrance edge
// 			// ----------------------------------------------------------------
// 			// Check if we can enter the neighbor polygon from the current polygon
// 			// across the edge connecting the current and neighbor polygons.

// 			// If entrance_edge != -1, we can only enter the polygon from the edge at index "entrance_edge"
// 			if(sv_navmesh_polies[neighbor].entrance_edge != -1) {
// 				// Check if the edge we're crossing from current to neighbor is the entrance edge
// 				if(sv_navmesh_polies[neighbor].entrance_edge != sv_navmesh_polies[current].connected_polies_neighbor_edge_index[i]) {
// 					// If it's not the entrance edge, skip this neighbor.
// 					// We can't walk from current to neighbor.
// 					continue;
// 				}
// 			}
// 			// ----------------------------------------------------------------


// 			if(res->poly_set[neighbor] != PATHFIND_POLY_SET_CLOSED) {
// 				//print("Neighbor is not in closed list.\n");
// 				//Calculate tentative f score
// 				//Calculate tentative g score (distance from start to current + distance from current to neighbor)
// 				float tentative_g_score = res->poly_g_score[current] + vlen(sv_navmesh_polies[neighbor].center - sv_navmesh_polies[current].center);
				
// 				if(res->poly_set[neighbor] != PATHFIND_POLY_SET_OPEN || tentative_g_score < res->poly_g_score[neighbor]) {
// 					//print("Neighbor is not in open list, or a better g score has been found.\n");
// 					//Adding neighbor to open set
// 					res->poly_set[neighbor] = PATHFIND_POLY_SET_OPEN;
					
// 					//Updating scores for neighbor node
// 					float tentative_f_score = tentative_g_score + sv_pathfind_calc_h_score(neighbor , goal);
// 					res->poly_g_score[neighbor] = tentative_g_score;
// 					res->poly_f_score[neighbor] = tentative_f_score;
					
// 					//Linking neighbor node to current node (for tracing path)
// 					res->poly_prev[neighbor] = current;
					
// 					//print("Assigning Poly ");
// 					//print(ftos(neighbor));
// 					//print(" came from  ");
// 					//print(ftos(current));
// 					//print(".\n");
// 				}
				
// 			}
// 		}		
		
// 		current = sv_pathfind_get_lowest_f_score(res);
// 	}
	
	
// 	//Tracing the pathfind results
// 	if(pathfind_success == TRUE) {
// 		sv_pathfind_trace_path(start,goal,res);
// 		sv_pathfind_smooth_path(start_pos,end_pos,res);
		
// 		return 1;
// 	}
// 	print("Pathfind fail");
// 	return 0;
// }

float sv_navmesh_pathfind(entity from, entity to) {}
// float sv_navmesh_pathfind(entity from, entity to) {
//     // TODO ... How do I get...?
//     // Every AI_Chase entity gets an integer
//     // TODO - In pathfinding, each entity needs a place to store its results...
//     // TODO - I should really make a MAX_AI number 
//     // TODO - I can have an array of pre-allocated pathfind results, and dynamically use them?
//     // TODO - Or maybe I have one reserved per AI, and one supplemental one reesrved per AI...



//     // FIXME - Will need to pre-allocate a certain number of AI_Chase ents and reuse them... or maybe
//     // FIXME   I need to pre-allocate a certain number of zombies, and dogs?
//     // FIXME   I wanted to subclass zombies to crawlers to override their behaviors...


//     // We can perform pathfinding logic without losing our current path.

//     // TODO - In pathfinding, I need a reference to the calling entity to know which traversal types this entity can use
//     AI_Chase chase_ent = (AI_Chase) from;
// 	navmesh_pathfind_result* res = &(sv_zombie_pathfind_result[chase_ent.pathfind_result_idx]);
	
// 	float start = sv_navmesh_get_containing_poly(from.origin);
// 	float goal = sv_navmesh_get_containing_poly(to.origin);
	
// 	return sv_navmesh_pathfind_start(start,goal,from.origin,to.origin,res);
// }

//===========================================================================================================
