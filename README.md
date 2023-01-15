# Nazi Zombies: Portable QuakeC

## Navmesh branch
Welcome to NZP's experimental navmesh implementation.
This branch will be periodically updated as the navmesh implementation goes along.
Currently, navmeshes are only supported on the PC version of NZP.


#### Commands:

General Navmesh Editor Commands:
```
nav_editor -- Toggle navmesh edit mode 
    NOTE: There's currently a known bug where starting a new map with this enabled will crash the game. Make sure you toggle it off before starting a new map.
nav_place_vert -- Place new navmesh vertex at player location

nav_select_vert -- Select vertex nearest to player (Can only select up to 4 at a time)
nav_deselect_vert -- Deselect vertex nearest to player, if selected.
nav_deselect_all -- Deselect all currently-selected vertices.
nav_make_poly -- Create a navmesh polygon with currently selected vertices.

nav_toggle_poly_door -- Marks a polygon to only be active when a door has been opened.
    To select the door, walk into the door brush in the navmesh editor to have its "doortarget" field be copied.
    Then, select the polygon (via selecting its verts), and execute this command.
nav_print_poly_door -- Print the currently-selected polygon's doortarget field.
nav_toggle_poly_entrance_edge -- Marks a polygon as only enterable from a specific edge.
    This is experimental, and will likely be removed in the future.
    Keep calling it to cycle through the edges or disable it.

```




Potentially Dangerous Commands:
```
nav_delete_verts -- Delete currently selected vertices and their polygons.
nav_delete_poly  -- Delete polygon comprised of all currently selected verts.
nav_load_navmesh -- Load navmesh from map's nav file. CAUTION: WILL OVERRIDE CURRENTLY LOADED EDITOR NAVMESH.
nav_save_navmesh -- Save current navmesh. CAUTION: WILL OVERRIDE THE MAP'S NAVMESH FILE.
nav_clear_navmesh -- Clear current navmesh. Will need to be confirmed with "y" or "yes"
```

Debugging Commands:
> Once test start and goal entities have been placed, the resulting navmesh path will be drawn.
```
navtest_place_start -- Used for testing navmeshes in editor. Place start entity.
navtest_place_goal -- Used for testing navmeshes in editor. Place goal entity. 
```

Corner-Placement-Tool Commands:
> Placing corners is easy when you can walk into a concave corner and hit "nav_place_vert". Placing corners is next to impossible when you need to try and eyeball a convex corner to get the perfect vertex placement. This tool will try and auto-calculate the perfect vertex position.
To use it, activate it, look at a corner, and confirm.
```
nav_place_corner -- Enter corner-vertex-placement tool
nav_cancel_corner -- Exit corner-vertex-placement tool
nav_confirm_corner -- Place new vertex at the corner-vertex-placement tool's current drawn location.
```


Other Commands
> Useful for internal stuff, but you won't need to call these.
```
nav_calc_connected_polies -- Recomputes polygon neighbors for all polygons
nav_calc_poly_centers -- Recomputes centers for all polygons
```


### A few notes:

The navmesh editor relies on the following two shader definitions for the navmesh to draw properly in the editor.
Add the following entries into nzp/scripts/models.shader:
```
debug/wireframe
{
	cull disable
	program shaders/outline.glsl
	{
	}
}

debug/solid_nocull
{
	cull disable
	{
		alphaGen vertex
		rgbGen vertex
		map $nearest:textures/dev/white.tga
		blendFunc blend
	}
}
```

Recommended keybinds for navmesh editor:
```
bind , "nav_select_vert"
bind . "nav_deselect_vert"
bind / "nav_deselect_all"
bind h "navtest_place_start"
bind i "nav_confirm_corner"
bind j "navtest_place_goal"
bind k "nav_editor"
bind l "nav_make_poly"
bind n "nav_place_vert"
bind o "nav_cancel_corner"
bind u "nav_place_corner"
```

&ndash; blubs

---


## About
This is the QuakeC portion of the NZ:P source code. QuakeC is responsible for most game-related code such as weapon logic, ai, and Perks. You can read more about QuakeC on the [Wikipedia page](https://en.wikipedia.org/wiki/QuakeC). NZ:P makes use of CSQC for PC/FTE.

## Project Structure
Here is a brief explanation for each of the (sub)directories in this repository:
* `bin`: Command line binaries for [FTEQCC](https://www.fteqcc.org/) + the ini configuration file.
* `progs`: `*.src` files, a list of QuakeC source files each platform is dependent on. 
* `source`:
  * `client`: FTE-exclusive CSQC, used for the HUD, achievements, and other server->client requests.
  * `server`: Game code relevant to all platforms, contains most expected logic.
  * `shared`: Definitions for weapon stats and some utility functions shared by both the `client` and `server`.
* `tools`: Build scripts to compile the QuakeC into `.dat` and `.lno` files.

## Updating
While it's usually recommended to stay on the QuakeC version provided with your build of NZ:P, you may want to update it to the current development builds to test new features and changes. To do this, navigate to the [Releases](https://github.com/nzp-team/quakec/releases/tag/bleeding-edge) page and follow the instructions there for downloading and installing.

## Building (Beginner Friendly)
There are no prerequisites or dependancies needed to build QuakeC other than a working Windows or Linux-based machine (MacOS is **not** natively supported, but you can use [WINE](https://www.winehq.org/)).

Before you can build the NZ:P QuakeC, you must either [download](https://github.com/nzp-team/quakec/archive/refs/heads/main.zip) this repository (easy) or [clone it](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) (for developers).

To build, simply navigate to the `tools` directory and run the `qc-compiler-*` script for your platform. If unfamiliar with executing shell (`.sh`) scripts on Linux systems, give this [itsFOSS article](https://itsfoss.com/run-shell-script-linux/) a read.

After having done this, a `build` directory will have been created, and inside of it will be more directories named after every platform. Copy the contents of the platform directories into your `nzp` game directory. (Example: For PSP, copy `progs.dat` and `progs.lno` from `build/handheld` to `PSP/GAME/nzportable/nzp`).