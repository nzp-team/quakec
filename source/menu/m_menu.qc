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
};

void(string id, vector pos, vector size, float maxlen, __inout string text, __inout float cursor) text_input_control =
{
	vector textsize = [size_y - 4, size_y - 4];
	sui_push_frame(pos, size);
	vector basecolor = sui_is_hovered(id) ? MENU_BG_DARK + MENU_HIGHLIGHT * 0.08 : MENU_BG_DARK; 
	sui_fill([0, 0], size, basecolor, 0.6, 0);
	
	sui_text_input(id, [0, 0], size, maxlen, text, cursor);

	sui_cap_input_length(maxlen, text, cursor);
	
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

#ifdef MENU

//
// Menu_DrawMapPreview()
// Draws the Map preview seen in the
// Pre-Game menu.
//
string UserMapNameLookup(string bsp_name);
void() Menu_DrawMapPreview =
{
	string map_preview_name = UserMapNameLookup(current_selected_bsp);
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);

	// Map thumbnail
	sui_fill([150, 100], [228, 130], [0.4, 0.4, 0.4], 1, 0);
	sui_pic([150, 100], [225, 127], strcat("menu/custom/", current_selected_bsp, ".png"), [1, 1, 1], 1, 0);

	sui_text([150, 152], MENU_TEXT_MEDIUM, map_preview_name, [1, 1, 0], 1, 0);
};

#endif // MENU

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
// Menu_DrawYesNoPanel()
// Draws a ribbon over the screen typically used
// for Yes/No message boxes.
//
void(string line_1, string line_2) Menu_DrawYesNoPanel =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_fill([0, 0], sui_current_frame_size(), [0.01, 0, 0], 0.5, 0);

	// Black Fill
	sui_fill([0, 160], [sui_current_frame_size()[0], 160], [0, 0, 0], 1, 0);

	// Yellow borders
	sui_fill([0, 160], [sui_current_frame_size()[0], 3], [1, 1, 0], 0.9, 0);
	sui_fill([0, sui_current_frame_size()[1] - 160], [sui_current_frame_size()[0], 3], [1, 1, 0], 0.9, 0);

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_START]);
	sui_text([0, 170], MENU_TEXT_MEDIUM, line_1, [1, 1, 1], 1, 0);
	sui_text([0, 190], MENU_TEXT_MEDIUM, line_2, [1, 1, 1], 1, 0);
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
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
// Menu_DrawOptionKey(order, value)
// Draws a key/glyph at a given order.
//
void(float order, string bind) Menu_DrawOptionKey =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	vector position = [320, 50 + (order * 25)];
	float keynum = stringtokeynum(bind);

	if (keynum >= 816 && keynum <= 839) {
		vector tilemap_position = [0, 0];

		// Get the position of the button in the tilemap.
		switch(keynum) {
			case K_GP_A: tilemap_position = [0, 0]; break;
			case K_GP_B: tilemap_position = [0.125, 0]; break;
			case K_GP_X: tilemap_position = [0.250, 0]; break;
			case K_GP_Y: tilemap_position = [0.375, 0]; break;
			case K_GP_LSHOULDER: tilemap_position = [0.250, 0.125]; break;
			case K_GP_RSHOULDER: tilemap_position = [0.375, 0.125]; break;
			case K_GP_LTRIGGER: tilemap_position = [0.500, 0.125]; break;
			case K_GP_RTRIGGER: tilemap_position = [0.625, 0.125]; break;
			case K_GP_BACK: tilemap_position = [0.875, 0.125]; break;
			case K_GP_START: tilemap_position = [0.750, 0.125]; break;
			case K_GP_LTHUMB: tilemap_position = [0, 0.125]; break;
			case K_GP_RTHUMB: tilemap_position = [0.125, 0.125]; break;
			case K_GP_DPAD_UP: tilemap_position = [0.500, 0]; break;
			case K_GP_DPAD_DOWN: tilemap_position = [0.625, 0]; break;
			case K_GP_DPAD_LEFT: tilemap_position = [0.750, 0]; break;
			case K_GP_DPAD_RIGHT: tilemap_position = [0.875, 0]; break;
		}

		sui_subpic([position_x, position_y - 2], [MENU_TEXT_MEDIUM_x + 5, MENU_TEXT_MEDIUM_x + 5], sprintf("gfx/controller_glyphs/%s.tga", cvar_string("cl_controllerglyphs")), [1, 1, 1], tilemap_position, [0.125, 0.125], 1, 0);
	}
	else {
		sui_text(position, MENU_TEXT_MEDIUM, bind, [1, 1, 0], 1, 0);
	}
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
		if (user_maps[index].map_author != "") {
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
// Menu_DrawControllerGlyphDemo(order)
// Draws ABXY on the same line as an OptionVal to demonstrate
// the current cl_controllerglyphs value.
//
void(float order) Menu_DrawControllerGlyphDemo =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	vector tilemap_positions[4] = {[0, 0], [0.125, 0], [0.250, 0], [0.375, 0]};
	vector position = [450, 50 + (order * 25)];

	for(int i = 0; i < 4; i++) {
		sui_subpic(position, [MENU_TEXT_MEDIUM_x, MENU_TEXT_MEDIUM_x], sprintf("gfx/controller_glyphs/%s.tga", cvar_string("cl_controllerglyphs")), [1, 1, 1], tilemap_positions[i], [0.125, 0.125], 1, 0);
		position_x += 14;
	}
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
void() Menu_DrawBackground =
{
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

#ifdef MENU

	float elapsed_background_time = time - menu_starttime;

	// 
	// Slight background pan
	//
	float x_pos = 0 - (((sui_current_frame_size()[0] * 1.05) - sui_current_frame_size()[0]) * (elapsed_background_time/7));

	sui_pic([x_pos, 0], [sui_current_frame_size()[0] * 1.05, sui_current_frame_size()[1]], menu_background, [1, 1, 1], 1, 1);
	sui_fill([0, 0], sui_current_frame_size(), [0, 0, 0], 0.7, 0);

	//
	// Fade new images in/out
	//
	float alpha = 0;

	if (elapsed_background_time < 1.0) {
        alpha = 1.0f - sin((elapsed_background_time / 1.0f) * (M_PI / 2));  // Opacity from 1 -> 0
    } else if (elapsed_background_time < 6.0f) {
        alpha = 0.0f;
    } else if (elapsed_background_time < 7.0f) {
        alpha = sin(((elapsed_background_time - 6.0f) / 1.0f) * (M_PI / 2));  // Opacity from 0 -> 1
    }

	sui_fill([0, 0], sui_current_frame_size(), [0, 0, 0], alpha, 0);

#else

	sui_fill([0, 0], sui_current_frame_size(), [0, 0, 0], 0.8, 0);

#endif // MENU

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
// Menu_CvarSlider(order, minmaxsteps, cvar_s, is_int, no_text, zero_is_one)
// Draws a Slider at the given order position
// that controls a cvar.
//
void(float order, vector minmaxsteps, string cvar_s, float is_int, float no_text, float zero_is_one) Menu_CvarSlider =
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
		float number_to_draw = current;

		if (number_to_draw == 0 && zero_is_one == true)
			number_to_draw = 1;

		if (is_int)
			sui_text(position + [175, 0, 0], MENU_TEXT_MEDIUM, ftos(rint(number_to_draw)), [1, 1, 1], 1, 0);
		else
			sui_text(position + [175, 0, 0], MENU_TEXT_MEDIUM, sprintf("%.2f", number_to_draw), [1, 1, 1], 1, 0);
	}
};

static void(string id, vector pos, vector size, __inout string text, __inout float cursor) handle_text_input =
{
	// best length to fit the largest character in the font
	// ex: AAAAAAAAAAAAAAAAAAAAAAA
	float maxlen = 23;

	sui_action_element(pos, size, id, sui_noop);
	if (sui_is_clicked(id)) cursor = strlen(text);
	if (sui_is_hovered(id))
	{
		float char = 0;
		float scan = 0;
		while(sui_get_input(char, scan)) sui_handle_text_input(char, scan, maxlen, text, cursor);
	}
};

static void(string id, vector pos, vector size, string text, float cursor) draw_text_input =
{
	sui_push_frame(pos - [6, 5], size);
	sui_fill([0, 0], size, [0, 0, 0], 1.0, 0);
	sui_border_box([0, 0], size, 2, [0.2, 0.2, 0.2], 0.3, 0);
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text([6, 0], MENU_TEXT_SMALL, text, MENU_TEXT_1, 1, 0);
	float cursor_x = getTextWidth(substring(text, 0, cursor), MENU_TEXT_SMALL.x);
	if (sui_is_hovered(id))
		sui_text([6 + cursor_x, 0], MENU_TEXT_SMALL, "|", [1.0, 0.25, 0.25], 1, 0);
	sui_pop_frame();
};

//
// Menu_TextInput(id, order, text, cursor)
// Draws a Text Input box at the given order position
//
void(string id, float order, __inout string text, __inout float cursor) Menu_TextInput =
{
	vector pos = [320, 50 + (order * 25)];
	vector size = [290, 22];

	handle_text_input(id, pos, size, text, cursor);

	draw_text_input(id, pos, size, text, cursor);
};

//
// Menu_PasswordInput(id, order, text, cursor)
// Draws a Text Input box at the given order position (blocked out with asterisks)
//
void(string id, float order, __inout string text, __inout float cursor) Menu_PasswordInput =
{
	vector pos = [320, 50 + (order * 25)];
	vector size = [290, 22];
	string safe = "";

	for (int i = 0; i < strlen(text); i++)
		safe = sprintf("%s%s", safe, "*");

	handle_text_input(id, pos, size, text, cursor);

	draw_text_input(id, pos, size, safe, cursor);
};

static string(string s) str2ascii =
{
	for (int i = 0; i < strlen(s); i++)
	{
		if (s[i] < 32 || s[i] > 126)
			s[i] = 63; // question mark
	}
	return s;
};

//
// Menu_CleanUpServerAddress(server_address)
// Strips stuff from the CNAME like /udp/ etc.
// if it causes conflicts when trying to connect.
//
string Menu_CleanUpServerAddress(string server_address) =
{
	// Strip /udp/
	if (substring(server_address, 0, 5) == "/udp/") {
		return substring(server_address, 5, strlen(server_address) - 5);
	}

	return server_address;
};

//
// Menu_ServerList(id, pos, size, scrollofs, num_servers)
// Draw the master server list
//
void(float type) Menu_PlaySound;
void(string id, vector pos, vector size, __inout vector scrollofs, float num_servers) Menu_ServerList =
{
	vector rowsize = [size.x, 16];
	vector listitem_pos = [0, 0, 0];
	sui_fill(pos, size, [0, 0, 0], 0.75, 0);

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);

	int server_display_x = 0;
	int map_display_x = 0;
	int player_display_x = 0;

	sui_list_view_begin(strcat(id, "scrl"), pos, size, rowsize, num_servers, scrollofs, [0, 16]);
	for (float index = sui_list_item(listitem_pos); index > -1; index = sui_list_item(listitem_pos))
	{
		sui_push_frame(listitem_pos, rowsize);

		string listitem_id = strcat(id, "scrl", ftos(index));
		sui_action_element([0, 0], rowsize, listitem_id, sui_noop);

		// bg
		vector bpos = [0, 0];
		vector bsize = [(rowsize.x / 8) * 5, rowsize.y];
		sui_fill(bpos, rowsize, [0.25, 0.1, 0.1], 0.5, 0);

		// hovered bg
		if (sui_is_hovered(listitem_id))
			sui_fill(bpos, rowsize, [0.25, 0.1, 0.1], 0.5, 0);

#ifdef MENU
		// do it
		if (sui_is_clicked(listitem_id)) {
			Menu_PlaySound(MENU_SND_ENTER);
			m_toggle(false);
			map_name_override = gethostcachestring(gethostcacheindexforkey("map"), index);
			
			string server_address = Menu_CleanUpServerAddress(gethostcachestring(gethostcacheindexforkey("cname"), index));
			localcmd("connect ", server_address, "\n");
		}
#endif // MENU

		// name
		server_display_x = bpos.x;
		sui_fill(bpos, bsize, [0.25, 0.1, 0.1], 0.5, 0);
		sui_text(bpos + [8, 2], MENU_TEXT_SMALL, str2ascii(gethostcachestring(gethostcacheindexforkey("name"), index)), MENU_TEXT_1, 1, 0);

		// map
		bsize.x = (rowsize.x / 8);
		bpos.x = bsize.x * 5;
		map_display_x = bpos.x;
		sui_text(bpos + [8, 2], MENU_TEXT_SMALL, gethostcachestring(gethostcacheindexforkey("map"), index), MENU_TEXT_1, 1, 0);

		// players
		bpos.x = bsize.x * 7;
		player_display_x = bpos.x;
		string s = sprintf("%d/%d",
			stof(gethostcachestring(gethostcacheindexforkey("numhumans"), index)),
			stof(gethostcachestring(gethostcacheindexforkey("maxplayers"), index))
		);
		sui_fill(bpos, bsize, [0.25, 0.1, 0.1], 0.5, 0);
		sui_text(bpos + [8, 2], MENU_TEXT_SMALL, s, MENU_TEXT_1, 1, 0);

		// hovered border
		bpos = [0, 0];
		if (sui_is_hovered(listitem_id))
			sui_border_box(bpos, rowsize, 1, [0.4, 0.4, 0], 1, 0);

		sui_pop_frame();
	}
	sui_list_view_end();

	// Table
	if (map_display_x == 0)
		return;
	
	sui_text([server_display_x, pos.y] + [8, -135], MENU_TEXT_SMALL, "Server Name", MENU_TEXT_1, 1, 0);
	sui_text([map_display_x, pos.y] + [8, -135], MENU_TEXT_SMALL, "Map", MENU_TEXT_1, 1, 0);
	sui_text([player_display_x, pos.y] + [8, -135], MENU_TEXT_SMALL, "Players", MENU_TEXT_1, 1, 0);
};

void() Menu_StartCoop =
{
	localcmd("sv_public 2; sv_listen_qw 1\n");
	current_menu = MENU_COOPSTOCK;
};

void() Menu_StartSolo =
{
	localcmd("sv_public 0; sv_listen_qw 0\n");
	current_menu = MENU_SOLO;
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

void(float type) Menu_PlaySound =
{
	string sound = "";

	if (type == MENU_SND_NAVIGATE) sound = cvar_string("menu_navigatesound");
	else if (type == MENU_SND_ENTER) sound = cvar_string("menu_entersound");
	else if (type == MENU_SND_BEEP) sound = cvar_string("menu_beepsound");

	localsound(sound, 0, cvar("nzp_uivolume"));
};

float last_menu;
void(vector size) root_menu =
{
	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_fill([0, 0], size, '0 0 0', 0.5, 0);
	switch (current_menu)
	{

#ifdef MENU

		case MENU_MAIN: Menu_Main(); break;
		case MENU_SOLO: menu_map_mode = MAP_SOLOSTOCK; Menu_Maps(); break;
		case MENU_SOLOUSER: menu_map_mode = MAP_SOLOUSER; Menu_Maps(); break;
		case MENU_COOP: Menu_Coop(); break;
		case MENU_COOPJOIN: Menu_Coop_Join(); break;
		case MENU_COOPBROWSE: Menu_Coop_Browse(); break;
		case MENU_COOPDIRECT: Menu_Coop_Direct(); break;
		case MENU_COOPCREATE: Menu_Coop_Create(); break;
		case MENU_COOPSTOCK: menu_map_mode = MAP_COOPSTOCK; Menu_Maps(); break;
		case MENU_COOPUSER: menu_map_mode = MAP_COOPUSER; Menu_Maps(); break;
		case MENU_CREDITS: Menu_Credits(); break;
		case MENU_LOBBY: Menu_Lobby(); break;
		case MENU_GAMESETTINGS: Menu_GameSettings(); break;

#else

		case MENU_PAUSE: Menu_Pause(); break;

#endif // MENU

		case MENU_OPTIONS: Menu_Options(); break;
		case MENU_VIDEO: Menu_Video(); break;
		case MENU_AUDIO: Menu_Audio(); break;
		case MENU_CONTROL: Menu_Control(); break;
		case MENU_GAMEPAD: Menu_Gamepad(); break;
		case MENU_BINDINGS: Menu_Bindings(); break;
		case MENU_ACCESSIBILITY: Menu_Accessibility(); break;

		default: break;
	}

	// Menu enter sound
	if (last_menu != current_menu) {
		Menu_PlaySound(MENU_SND_ENTER);
		last_menu = current_menu;
		sui_reset_hover();
	}
};
