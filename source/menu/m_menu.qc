vector MENU_BG = '0.2 0.3 0.4';
vector MENU_BG_DARK = '0.1 0.15 0.2';
vector MENU_BORDER = '0.3 0.4 0.5';
vector MENU_BUTTON = '0.3 0.4 0.5';
vector MENU_BUTTON_BORDER = '0.35 0.45 0.55';
vector MENU_TEXT_1 = '1 1 1';
vector MENU_TEXT_2 = '0.7 0.75 0.75';
vector MENU_HIGHLIGHT = '1 1 1';
vector MENU_DARKEN = '1 1 1';

vector MENU_TEXT_SUPERSMALL = '10 10 0';
vector MENU_TEXT_SMALL = '12 12 0';
vector MENU_TEXT_MEDIUM = '14 14 0';
vector MENU_TEXT_LARGE = '28 28 0';

void() input_tester =
{
	float char = 0;
	float scan = 0;
	string printme = "";
	while (sui_get_input(char, scan))
	{
		printme = strcat(printme, chr2str(char));
	}
	if (printme != "") printf("INPUT: %s\n", printme); 
};

void(string id, vector pos, vector size, float maxlen, __inout string text, __inout float cursor) text_input_control =
{
	vector textsize = [size_y - 4, size_y - 4];
	sui_push_frame(pos, size);
	vector basecolor = sui_is_hovered(id) ? MENU_BG_DARK + MENU_HIGHLIGHT * 0.08 : MENU_BG_DARK; 
	sui_fill([0, 0], size, basecolor, 0.6, 0);
	
	sui_text_input(id, [0, 0], size, text, cursor);
	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	float focused = sui_is_last_clicked(id);
	// Under focus
	focused ? sui_border_box([0, 0], size, 1, MENU_BORDER, 0.6, 0) : 0;	
	
	sui_push_frame([2, 0], [size_x - 4, size_y - 4]);
	
	float cursorx;
	if (stringwidth(text, 1, textsize) > size_x - 4)
	{
		sui_clip_to_frame();
		cursorx = 0;
		sui_set_align([SUI_ALIGN_END, SUI_ALIGN_CENTER]);
		sui_text([0, 0], textsize, text, MENU_TEXT_1, 1, 0);
	}
	else
	{
		cursorx = stringwidth(substring(text, 0, cursor), 1, textsize);
		sui_text([0, 0], textsize, text, MENU_TEXT_1, 1, 0);
	}
	if (focused) 
	{
		sui_fill([cursorx, 0], [2, textsize_y], MENU_TEXT_1, fabs(sin(time * 4)), 0);
	}
	sui_reset_clip();
	sui_pop_frame();
	
	sui_pop_frame();
};

//
// Menu_DrawDivider(order)
// Draws a division line between menu
// entries.
//
void(float order) Menu_DrawDivider =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	vector position = [0, 45 + (order * 25)];
	sui_fill(position, [285, 2], [0.2, 0.2, 0.2], 1, 0);
};

//
// Menu_SocialBadge(order, id, text, index)
// Displays a social badge with a URL
// when hovered over with the mouse.
//
void(float order, string id, string text, float index) Menu_SocialBadge =
{
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);

	vector position = [-6, -62 - ((order - 1) * 30)];
	vector coords_size = [0.5, 0.5];
	vector coords_pos = [0, 0];

	switch(index) {
		case 1: coords_pos = [0, 0]; break;
		case 2: coords_pos = [0.5, 0]; break;
		case 3: coords_pos = [0, 0.5]; break;
		case 4: coords_pos = [0.5, 0.5]; break;
	}

	sui_subpic(position, [28, 28], "gfx/menu/social", [1, 1, 1], coords_pos, coords_size, 1, 0);

	if (sui_is_hovered(id)) {
		sui_fill(position - [36, 8], [getTextWidth(text, MENU_TEXT_SUPERSMALL_x) + 1, 10], [0, 0, 0], 0.9, 0);
		sui_text(position - [35, 8], MENU_TEXT_SUPERSMALL, text, [1, 1, 0], 1, 0);
	}

	sui_action_element(position, [28, 28], id, sui_noop);
};

//
// Menu_DrawMapPanel()
// Draws a translucent box on the right
// side of the window to make map text easier
// to read.
//
void() Menu_DrawMapPanel =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_fill([300, 55], [sui_current_frame_size()[0], sui_current_frame_size()[1] - 55 - 58], [0, 0, 0], 0.9, 0);
	sui_fill([300, 55], [3, sui_current_frame_size()[1] - 55 - 58], [1, 1, 0], 0.9, 0);
};

//
// Menu_DrawOptionValue(order, value)
// Draws the value of the option at a given order.
//
void(float order, string value) Menu_DrawOptionValue =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	vector position = [320, 50 + (order * 25)];
	sui_text(position, MENU_TEXT_MEDIUM, value, [1, 1, 1], 1, 0);
};

//
// Menu_MapButton(order, id, bsp_name)
// Displays a fancy menu option that loads
// and draws the details for the given
// .BSP.
//
float(float order, string id, string bsp_name, float usermap_index) Menu_MapButton =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	float is_hovered = sui_is_hovered(id);
	vector text_color = is_hovered ? [1, 0, 0] : [1, 1, 1];
	vector position = [6, 50 + (order * 25)];
	vector bbox_pos = position - [6, 5, 0];
	vector bbox_size = [290, 22];

	if (is_hovered) {
		// Background
		sui_fill(bbox_pos, bbox_size, [0, 0, 0], 0.9, 0);
		// Top
		sui_fill(bbox_pos, [bbox_size_x, 2], [0.4, 0, 0], 1, 0);
		// Bottom
		sui_fill(bbox_pos + [0, bbox_size_y - 2], [bbox_size_x, 2], [0.4, 0, 0], 1, 0);
		// Right
		sui_fill(bbox_pos + [bbox_size_x - 2, 0], [2, bbox_size_y], [0.4, 0, 0], 1, 0);
	}

	int i;
	int index = 0;

	// Draw the map data from stock_maps
	if (usermap_index == -1) {
		for(i = 0; i < stock_maps.length; i++) {
			if (stock_maps[i].bsp_name == bsp_name) {
				index = stock_maps[i].array_index;
				break;
			}
		}
	} else {
		index = usermap_index;
	}

	// Map title
	string title = user_maps[index].map_name_pretty;
	if (!title)
		title = user_maps[index].map_name;
	sui_text(position - [getTextWidth(strtoupper(title), MENU_TEXT_MEDIUM_x), 0, 0] + [275, 0, 0], MENU_TEXT_MEDIUM, strtoupper(title), text_color, 1, 0);

	if (is_hovered) {
		sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);

		// Map thumbnail
		if (user_maps[index].map_use_thumbnail) {
			sui_fill([150, -70], [302, 174], [0.4, 0.4, 0.4], 1, 0);
			sui_pic([150, -70], [300, 170], strcat("menu/custom/", user_maps[index].map_name, ".png"), [1, 1, 1], 1, 0);
		}
			
		// Map description
		for(i = 0; i < 8; i++) {
			sui_text([150, 30 + (i * 14)], MENU_TEXT_SMALL, user_maps[index].map_desc[i], [1, 1, 1], 1, 0);
		}

		// Author/Description
		if (user_maps[index].map_author) {
			sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
			string author = user_maps[index].map_author;

			sui_text([0, -30], MENU_TEXT_MEDIUM, title, [1, 1, 1], 1, 0);
			sui_text([0, -15], MENU_TEXT_MEDIUM, author, [1, 1, 0], 1, 0);
		}
	
		sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	}

	sui_action_element(bbox_pos, bbox_size, id, sui_noop);
	
	return sui_is_clicked(id);
}

//
// Menu_GreyButton(order, title)
// Draws Grey (unselect-able text) in place of
// menu button.
//
void(float order, string title) Menu_GreyButton =
{
	vector alignment;

	if (order > 0) alignment = [SUI_ALIGN_START, SUI_ALIGN_START];
	else alignment = [SUI_ALIGN_START, SUI_ALIGN_END];

	sui_set_align(alignment);

	vector text_color = [0.5, 0.3, 0.3]; // make it kinda red, for flavor.
	vector position;

	if (order > 0) {
		position = [6, 50 + (order * 25)];
	} else {
		position = [6, -50 + (order * 25)];
	}

	sui_text(position  - [getTextWidth(title, MENU_TEXT_MEDIUM_x), 0, 0] + [275, 0, 0], MENU_TEXT_MEDIUM, title, text_color, 1, 0);
};

//
// Menu_Button(order, id, title, description)
// Displays a menu option and draws the description
// plus flair if selected.
//
float(float order, string id, string title, string description) Menu_Button =
{
	vector alignment;

	if (order > 0) alignment = [SUI_ALIGN_START, SUI_ALIGN_START];
	else alignment = [SUI_ALIGN_START, SUI_ALIGN_END];

	sui_set_align(alignment);

	float is_hovered = sui_is_hovered(id);
	vector text_color = is_hovered ? [1, 0, 0] : [1, 1, 1];
	vector position, bbox_pos;
	
	if (order > 0) {
		position = [6, 50 + (order * 25)];
		bbox_pos = position - [6, 5, 0];
	} else {
		position = [6, -50 + (order * 25)];
		bbox_pos = position + [-6, 5, 0];
	}

	vector bbox_size = [290, 22];

	if (is_hovered) {
		// Description
		sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_END]);
		sui_text([0, -30], MENU_TEXT_MEDIUM, description, [1, 1, 1], 1, 0);
		sui_set_align(alignment);

		// Background
		sui_fill(bbox_pos, bbox_size, [0, 0, 0], 0.9, 0);

		if (order > 0) {
			// Top
			sui_fill(bbox_pos, [bbox_size_x, 2], [0.4, 0, 0], 1, 0);
			// Bottom
			sui_fill(bbox_pos + [0, bbox_size_y - 2], [bbox_size_x, 2], [0.4, 0, 0], 1, 0);
		} else {
			// Top
			sui_fill(bbox_pos - [0, bbox_size_y], [bbox_size_x, 2], [0.4, 0, 0], 1, 0);
			// Bottom
			sui_fill(bbox_pos, [bbox_size_x, 2], [0.4, 0, 0], 1, 0);
		}

		// Right
		sui_fill(bbox_pos + [bbox_size_x - 2, 0], [2, bbox_size_y], [0.4, 0, 0], 1, 0);
	}

	sui_text(position  - [getTextWidth(title, MENU_TEXT_MEDIUM_x), 0, 0] + [275, 0, 0], MENU_TEXT_MEDIUM, title, text_color, 1, 0);
	sui_action_element(bbox_pos, bbox_size, id, sui_noop);
	
	return sui_is_clicked(id);
};

float(string id, vector pos, vector size, string text) my_button =
{
	sui_push_frame(pos, size);
	vector basecolor = sui_is_hovered(id) ? MENU_BUTTON + MENU_HIGHLIGHT * 0.1 : MENU_BUTTON; 
	basecolor = sui_is_held(id) ? MENU_BUTTON - MENU_DARKEN * 0.1 : basecolor;
	sui_fill([0, 0], size, basecolor, 0.6, 0);
	sui_border_box([0, 0], size, 1, MENU_BUTTON_BORDER, 0.4, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_text([0, 0], MENU_TEXT_SMALL, text, MENU_TEXT_1, 1, 0);	
	sui_action_element([0, 0], size, id, sui_noop);
	sui_pop_frame();
	
	return sui_is_clicked(id);
};

//
// Menu_DrawCreditHeader()
// Wrapper for drawing the role/title in credits.
//
void(float order, string header) Menu_DrawCreditHeader =
{
	vector position = [8, 60 + (order * 60)];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(position - [getTextWidth(header, MENU_TEXT_SMALL_x), 0, 0] + [275, 0, 0], MENU_TEXT_SMALL, header, [1, 1, 0], 1, 0);
};

//
// Menu_DrawCreditContributor()
// Wrapper for drawing the contributor list in credits.
//
void(float order, float sub_order, string header) Menu_DrawCreditContributor =
{
	vector position = [315, 60 + (order * 60)];
	position_y += sub_order * (MENU_TEXT_SUPERSMALL_x + 3);

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(position, MENU_TEXT_SUPERSMALL, header, [1, 1, 1], 1, 0);
};

//
// Menu_DrawBuildDate()
// Wrapper for drawing the build date
// retrieved from nzp/version.txt
//
void() Menu_DrawBuildDate =
{
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text([-6, 8], MENU_TEXT_SMALL, build_datetime, [1, 1, 1], 1, 0);
	sui_text([-6, 22], MENU_TEXT_SMALL, sprintf("Welcome, %s", cvar_string("name")), [1, 1, 0], 1, 0);
};

//
// Menu_DrawBackground()
// Wrapper for drawing menu background,
// i.e., the Zombie pose with a black
// background for readibility, and some
// style lines.
//
string() Menu_PickBackground;
void() Menu_DrawBackground =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_pic([0, 0], sui_current_frame_size(), menu_background, [1, 1, 1], 1, 1);
	sui_fill([0, 0], sui_current_frame_size(), [0, 0, 0], 0.7, 0);

	// Top Bars
	sui_fill([0, 0], [sui_current_frame_size()[0], 55], [0, 0, 0], 0.9, 0);
	sui_fill([0, 52], [sui_current_frame_size()[0], 3], [0.2, 0.2, 0.2], 1, 0);

	// Bottom Bars
	sui_fill([0, sui_current_frame_size()[1] - 55], [sui_current_frame_size()[0], 55], [0, 0, 0], 0.9, 0);
	sui_fill([0, sui_current_frame_size()[1] - 58], [sui_current_frame_size()[0], 3], [0.2, 0.2, 0.2], 1, 0);
};

//
// Menu_DrawTitle(menu_title)
// Wrapper for drawing the current Menu title
// in the desired location + at the desired size.
//
void(string menu_title) Menu_DrawTitle =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text([6, 18], MENU_TEXT_LARGE, menu_title, [1, 1, 1], 1, 0);
};

void(string id, vector pos, vector size, vector minmaxsteps, __inout float value) my_slider =
{
	sui_push_frame(pos, size);
	
	value = sui_slidercontrol(id, [0, 0], size, minmaxsteps, value, sui_slider_noop);
	float maxval = minmaxsteps[1];
	float sliderx = (value / maxval) * size_x;
	sui_fill([0, size_y * 0.25], [size_x, size_y * 0.5], [0.5, 0.1, 0.1], 1.0, 0);
	sui_fill([sliderx - 2, 0], [4, size_y], [0.6, 0.4, 0.4], 1.0, 0);
	
	sui_pop_frame();
};

void(vector pos, vector size, vector minmaxsteps, string cvar_s, string name, string format) cvar_slider =
{
	float current = cvar(cvar_s);
	float old = current;
	sui_push_frame(pos, [size_x, size_y * 0.5 - 4]);
	sui_text([0, 0], MENU_TEXT_SMALL, name, MENU_TEXT_1, 1, 0);
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text([0, 0], MENU_TEXT_SMALL, sprintf(format, current), MENU_TEXT_1, 1, 0);
	sui_pop_frame();
	my_slider(strcat(cvar_s, "sldr"), [pos_x, pos_y + size_y * 0.5], [size_x, size_y * 0.5], minmaxsteps, current);
	if (current != old) cvar_set(cvar_s, ftos(current));
};

//
// Menu_CvarSlider(order, minmaxsteps, cvar_s, is_int, no_text)
// Draws a Slider at the given order position
// that controls a cvar.
//
void(float order, vector minmaxsteps, string cvar_s, float is_int, float no_text) Menu_CvarSlider =
{
	float current = cvar(cvar_s);
	float old = current;

	vector position = [320, 50 + (order * 25)];
	vector size = [150, 30];

	my_slider(strcat(cvar_s, "sldr"), [position_x, (position_y - 17) + size_y * 0.5], [size_x, size_y * 0.5], minmaxsteps, current);

	if (current != old) {
		if (is_int)
			cvar_set(cvar_s, ftos(rint(current)));
		else
			cvar_set(cvar_s, ftos(current));
	}

	if (!no_text) {
		if (is_int)
			sui_text(position + [175, 0, 0], MENU_TEXT_MEDIUM, ftos(rint(current)), [1, 1, 1], 1, 0);
		else
			sui_text(position + [175, 0, 0], MENU_TEXT_MEDIUM, ftos(current), [1, 1, 1], 1, 0);
	}
};

struct name_command {
	string name;
	string command;
};

name_command bindlist[] = 
{
	{ "Forward", "+forward" },
	{ "Back", "+back" },
	{ "Left", "+moveleft" },
	{ "Right", "+moveright" },
	{ "Jump", "+jump" }
};

void(string id, vector pos, vector size, string name, string command) bind_button =
{
	sui_push_frame(pos, size);
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	string key = sui_binder(id, [0, 0], size, name, command);
	if (sui_is_hovered(id)) sui_fill([0, 0], size, MENU_HIGHLIGHT, 0.1, 0);
	sui_text([6, 0], MENU_TEXT_SMALL, name, MENU_TEXT_1, 1, 0);
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_CENTER]);
	sui_text([-6, 0], MENU_TEXT_SMALL, key, MENU_TEXT_1, 1, 0);
	
	sui_pop_frame();
};


void(string id, vector pos, vector size, __inout vector scrollofs) bind_list =
{
	sui_fill(pos, size, MENU_BG_DARK, 0.75, 0);
	sui_list_view_begin(strcat(id, "scrl"), pos, size, [size_x - 6, 24], bindlist.length, scrollofs, [0, 6]);
	vector listitem_pos = '0 0 0';
	for (float index = sui_list_item(listitem_pos); index > -1; index = sui_list_item(listitem_pos))
	{
		sui_push_frame(listitem_pos, [size_x - 6, 24]);
		bind_button(strcat(id, ftos(index)), [0, 0], [size_x - 6, 24], bindlist[index].name, bindlist[index].command);
		sui_pop_frame();
	}
	sui_list_view_end();	
};

vector binds_scroll;
void() settings_menu =
{
	vector pos = [0, 0];
	vector size = [360, 280];
	
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([0, 4], MENU_TEXT_MEDIUM, "Settings", MENU_TEXT_1, 1, 0);

	
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	
	float xpos = 8;
	float ypos = 32;
	float width = size_x * 0.5 - 8 * 2;
	sui_text([xpos, ypos], MENU_TEXT_SMALL, "Controls", MENU_TEXT_1, 1, 0);
	ypos += 16;
	bind_list("bindlist", [xpos, ypos], [width, 160], binds_scroll);
	ypos += 160 + 8;

	cvar_slider([xpos, ypos], [width, 32], [0.1, 10], "sensitivity", "Sensitivity", "%.2f");
	ypos += 32;

	ypos = 32;
	xpos = 8 + width + 8 + 8;
	
	cvar_slider([xpos, ypos], [width, 32], [0, 1], "volume", "Volume", "%.2f");
	ypos += 32 + 4;
	cvar_slider([xpos, ypos], [width, 32], [0, 1], "musicvolume", "Music Volume", "%.2f");
	ypos += 32 + 4 + 8;
	
	sui_text([xpos, ypos], MENU_TEXT_SMALL, "Video", MENU_TEXT_1, 1, 0);
	ypos += 16;
	my_button("fs_btn", [xpos, ypos], [width, 20], "Fullscreen") ? localcmd("vid_fullscreen 2; vid_restart\n") : 0;
	ypos += 24;
	my_button("wn_btn", [xpos, ypos], [width, 20], "Windowed") ? localcmd("vid_fullscreen 0; vid_width 1024; vid_height 768; vid_restart\n") : 0;
	ypos += 24;
	sui_text([xpos, ypos], MENU_TEXT_SMALL, "Window can be resized.", MENU_TEXT_1, 0.8, 0);
	ypos += 16;
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("stg_back", [-8, -8], [80, 20], "Back") ? current_menu = MENU_MAIN : 0;
	
	sui_pop_frame();
};

void() help_menu =
{
	vector pos = [0, 0];
	vector size = [360, 280];
	
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([0, 4], MENU_TEXT_MEDIUM, "Help", MENU_TEXT_1, 1, 0);
	
	float xpos = 0;
	float ypos = 32;
	sui_text([xpos, ypos], MENU_TEXT_SMALL, "Bunch of Help and About", MENU_TEXT_1, 1, 0);
	
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_END]);
	my_button("hlp_back", [-8, -8], [80, 20], "Back") ? current_menu = MENU_MAIN : 0;

	sui_pop_frame();	
};

void(float type) Menu_PlaySound =
{
	string sound = "";

	if (type == MENU_SND_NAVIGATE) sound = cvar_string("menu_navigatesound");
	else if (type == MENU_SND_ENTER) sound = cvar_string("menu_entersound");

	localsound(sound, 0, cvar("nzp_uivolume"));
};

float last_menu;
void(vector size) root_menu =
{
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_fill([0, 0], size, '0 0 0', 0.5, 0);
	switch (current_menu)
	{
		case MENU_MAIN: Menu_Main(); break;
		case MENU_SOLO: menu_map_mode = MAP_SOLOSTOCK; Menu_Maps(); break;
		case MENU_SOLOUSER: menu_map_mode = MAP_SOLOUSER; Menu_Maps(); break;
		case MENU_OPTIONS: Menu_Options(); break;
		case MENU_VIDEO: Menu_Video(); break;
		case MENU_AUDIO: Menu_Audio(); break;
		case MENU_CONTROL: Menu_Control(); break;
		case MENU_GAMEPAD: Menu_Gamepad(); break;
		case MENU_CREDITS: Menu_Credits(); break;
		case MENU_HELP: help_menu();
		default: break;
	}

	// Menu enter sound
	if (last_menu != current_menu) {
		Menu_PlaySound(MENU_SND_ENTER);
		last_menu = current_menu;
	}
};