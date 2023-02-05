//A single navmesh vertex
struct navmesh_vertex
{
	vector pos;
};


struct navmesh_traversal 
{
	vector start_pos; // Start position of traversal animation in world space
	vector end_pos; // End position of traversal animation, relative to start_pos
	float angle;

	vector midpoint_pos; // Optional midpoint of traversal animation, relative to start_pos
	float use_midpoint; // 0? Ignore the midpoint. 1? Use the midpoint
	// Some way to associate the traversal to the zombie logic callback that should be called.

	// --- Derived Vars ---
	// (can be computed from above)
	// TODO - These references will need updating if polygons change
	// TODO - Should these be computed just-in-time?
	float start_poly; // Traversal starting polygon
	float end_poly; // Traversal ending polygon

};


//Either a tri or a quad
struct navmesh_poly
{
	float verts[4];
	float vert_count;
	string doortarget; // "" or matches the .wayTarget field of a door entity. Polygon is only used when door is open (i.e. door.state == STATE_BOTTOM)
	// TODO - Remove this, will be replaced by traversals
	int entrance_edge; // If != -1, specifies which edge index this polygon can be entered from. (0,1,2, or 3)

	//The following fields are only used for actually pathfinding on the navmesh
	//The values are calculated in the editor when the navmesh is saved, but are not assigned in the editor before that.
	//These values are saved in the navmesh file, and loaded into the server's navmesh
	//FIXME: Unhandled edge case when a polygon shares a single edge with more than one polygon (like dropping down from a ledge)
	float connected_polies_count;//How many polygons we share an edge with
	float connected_polies[4];//Index of the polygons that we share an edge with (similar to links), more than 4 should be impossible (FIXME: highly unlikely)
	float connected_polies_left_vert[4];//The left vertex of the shared edge
	float connected_polies_right_vert[4];//The right vertex of the shared edge
	float connected_polies_neighbor_edge_index[4]; // conected_polies_neighbor_edge_index[i] holds the ith neighbor's edge index we are traversing to enter the neighbor polygon. This is used for polygons that may only be entered from a specific direction.
	vector center;//The center of the polygon in 3D space (pre-calculated because why calculate it at runtime)
};


#define NAV_MAX_VERTS 1024
#define NAV_MAX_POLIES 512
#define NAV_MAX_TRAVERSALS 128


// ============================================================================
// Shared Navmesh functions used by both client and server
// ============================================================================

//Returns the distance between the 2d line l1->l2 and pos
float navmesh_2D_line_point_dist(vector l1, vector l2, vector pos)
{
	float dot = (l2 - l1) * (pos - l2);
	if(dot > 0)
		return vlen(l2 - pos);
		
	dot = (l1 - l2) * (pos - l1);
	if(dot > 0)
		return vlen(l1 - pos);
	
	//2D cross product between (next_vert-vert) and (pos-vert)
	//float dist = (l2.x - l1.x) * (pos.y - l1.y) - (l2.y - l1.y) * (pos.y - l1.y);
	//dist = dist / vlen(l1 - l2);
	
	float dist = vlen(crossproduct(l2-l1,l1-pos))/vlen(l1-l2);
	
	return fabs(dist);
}

//============= Navmesh Pathfind Defs =============
#define PATHFIND_POLY_SET_NONE 0
#define PATHFIND_POLY_SET_OPEN 1
#define PATHFIND_POLY_SET_CLOSED 2





struct pathfind_result
{
	//Contains the set that the ith polygon is in
	float poly_set[NAV_MAX_POLIES];
	//Contains the index of the last polygon that we used to get to the ith polygon
	float poly_prev[NAV_MAX_POLIES];
	//Contains the g-score of the ith polygon (distance from start node to ith node along the node path)
	float poly_g_score[NAV_MAX_POLIES];
	
	//f score = g score + h score
	float poly_f_score[NAV_MAX_POLIES];

	//Holds list of polygons in the path (indices of polygons from start to goal)
	float result_node_path[NAV_MAX_POLIES];
	//How many polies are in the path
	float result_node_length;

	//Together, these two arrays hold the list of polygon edges we cross on the path
	float portals_left_vert[NAV_MAX_POLIES];
	float portals_right_vert[NAV_MAX_POLIES];
	//How many portals are in the pathfind_portals_left_vert (same as pathfind_result_node_length - 1)
	float portals_length;

	// The traversal index of the ith polygon's traversal list that was used. -1 if no traversal used.
	float traversal_index[NAV_MAX_POLIES];
	
	//Final resultant path:
	//Contains a list of points that makes up the path
	vector result_path[NAV_MAX_POLIES];
	//How many points are in the path
	float result_length;
};

//Returns some number > 0 if point p is to the left of line a->b
//Returns some number < 0 if point is to the right of line a->b
//Returns 0 if point is on the line
//(Left / Right is defined in the xy plane, z=0)
float pathfind_point_is_to_left(vector a, vector b, vector p)
{
	return (b.x - a.x)*(p.y - a.y) - (b.y - a.y)*(p.x - a.x);
}

// ============================================================================
