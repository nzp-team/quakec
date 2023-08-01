//A single navmesh vertex
struct navmesh_vertex {
	vector pos;
};


struct navmesh_traversal {
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
	// float start_poly; // Traversal starting polygon // FIXME - we may not need this
	float end_poly; // Traversal ending polygon
};




#define NAV_MAX_VERTS 1024
#define NAV_MAX_POLIES 512
#define NAV_MAX_TRAVERSALS 128
#define NAV_MAX_POLY_TRAVERSALS 32 // Maximum number of traversals connected to a polygon





//Either a tri or a quad
struct navmesh_poly {
	float verts[4];
	float vert_count;
	string doortarget; // "" or matches the .wayTarget field of a door entity. Polygon is only used when door is open (i.e. door.state == STATE_BOTTOM)
	// TODO - Remove this, will be replaced by traversals
	int entrance_edge; // If != -1, specifies which edge index this polygon can be entered from. (0,1,2, or 3)

	float connected_traversals_count; // How many traversals start in this polygon
	float connected_traversals[NAV_MAX_POLY_TRAVERSALS]; // List of traversals that start in this polygon

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




// ============================================================================
// Shared Navmesh functions used by both client and server
// ============================================================================

//Returns the distance between the 2d line l1->l2 and pos
float navmesh_2D_line_point_dist(vector l1, vector l2, vector pos) {
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








struct navmesh_pathfind_result {
	// ---------------------------------------------------------
	// A* Pathfinding Algorithm Fields
	// ---------------------------------------------------------
	// Contains the set that the ith polygon is in
	float poly_set[NAV_MAX_POLIES];
	// Contains the index of the last polygon that we used to get to the ith polygon
	float poly_prev_poly[NAV_MAX_POLIES];
	// Contains the index 
	float poly_prev_traversal[NAV_MAX_POLIES];
	// Contains the g-score of the ith polygon (distance from start node to ith node along the node path)
	float poly_g_score[NAV_MAX_POLIES];
		// f-score = g-score + h-score
	float poly_f_score[NAV_MAX_POLIES];

	// Traversal index (for the global list of traversals) of the ith polygon's traversal that was used. -1 if no traversal used.
	float traversal_set[NAV_MAX_TRAVERSALS];
	// Contains the index of the last polygon that used to get to the ith-traversal
	float traversal_prev_poly[NAV_MAX_TRAVERSALS];
	// Contains the g-score of the ith traversal (distance from start node to ith node along the node path)
	float traversal_g_score[NAV_MAX_TRAVERSALS];
	// f-score = g-score + h-score
	float traversal_f_score[NAV_MAX_TRAVERSALS];
	// ---------------------------------------------------------


	// ---------------------------------------------------------
	// Once Pathfinding is finished, trace path and store it here
	// ---------------------------------------------------------
	// Holds list of polygons in the path (indices of polygons from start to goal)
	// For every node in the path, one of these two lists will not be -1
	float path_polygons[NAV_MAX_POLIES];
	float path_traversals[NAV_MAX_POLIES];
	// Length of found path (polies + traversals)
	float path_length;
	// ---------------------------------------------------------


	// ---------------------------------------------------------
	// Apply path-smoothing (via funnel algorithm) to compute final path
	// ---------------------------------------------------------
	// List of portals contained in computed path.
	// A portal is a shared edge between polygons, or a traversal
	// It denotes crossing from one polygon to another, or crossing a polygon into a traversal
	// This contains the number of portals in the path (same as path_length - 1)
	float portals_length;
	// The left vertex of the i-th portal (-1 if the i-th portal is a traversal)
	vector portals_left_pos[NAV_MAX_POLIES];
	// The right vertex of the i-th portal (-1 if the i-th portal is a traversal)
	vector portals_right_pos[NAV_MAX_POLIES];
	// If the i-th portal is a traversal, contains the traversal index, -1 otherwise.
	float portals_traversal[NAV_MAX_POLIES];
	// ---------------------------------------------------------

	
	// ---------------------------------------------------------
	// Final path is a list of 3D points and traversals
	// ---------------------------------------------------------
	// Contains a list of points that makes up the path
	vector point_path_points[NAV_MAX_POLIES];
	// If i-th element is not -1, then the i-th point will be a traversal rather than a point
	float point_path_traversals[NAV_MAX_POLIES];
	//How many points/traversals are in the final path
	float point_path_length;
	// ---------------------------------------------------------
};

//Returns some number > 0 if point p is to the left of line a->b
//Returns some number < 0 if point is to the right of line a->b
//Returns 0 if point is on the line
//(Left / Right is defined in the xy plane, z=0)
float pathfind_point_is_to_left(vector a, vector b, vector p) {
	return (b.x - a.x)*(p.y - a.y) - (b.y - a.y)*(p.x - a.x);
}


// For some point `p` and some funnel `left` -> `corner` -> `right`
// Returns some number -1 <= x <= 1 is point p is in funnel
// 		0 if on the center line
// Returns some number < -1 if p is outside of the funnel to the left
// Returns some number > 1 if p is outside of the funnel to the right
// All points are assumed to be in xy plane (z=0, z is ignored)
float pathfind_point_in_funnel(vector p, vector corner, vector left, vector right) {
	float p_left_of_left_edge = pathfind_point_is_to_left(corner, left, p);
	float p_right_of_right_edge = -pathfind_point_is_to_left(corner, right, p);

	// If outside of left edge:
	if(p_left_of_left_edge > 0) {
		return -2;
	}
	// If outside of right edge:
	if(p_right_of_right_edge > 0) {
		return 2;
	}

	// Otherwise, we are in funnel
	// TODO - Do I need to compute proximity to funnel midpoint?
	return 0;
}

// ============================================================================
