float menu_maps_init;

//
// Menu_Maps_Init()
// Array lookup optimization that stores
// the array index of Stock NZ:P maps
// from the user_maps struct.
//
void() Menu_Maps_Init =
{
    menu_maps_init = true;
    user_maps_page = 0;

    for(int i = 0; i < stock_maps.length; i++) {
        for(int j = 0; j < user_maps_count; j++) {
            if (user_maps[j].map_name == stock_maps[i].bsp_name)
                stock_maps[i].array_index = j;
        }
    }
};

void() Menu_Maps_NextPage =
{
    Menu_PlaySound(MENU_SND_ENTER);
    user_maps_page++;
}

void() Menu_Maps_PrevPage =
{
    Menu_PlaySound(MENU_SND_ENTER);
    user_maps_page--;
}

void(string bsp_name) Menu_Maps_LoadMap =
{
    localcmd(sprintf("map %s\n", bsp_name)); 
    current_menu = MENU_MAIN;
};

void() Menu_Maps =
{
    if (!menu_maps_init)
        Menu_Maps_Init();

    Menu_DrawBackground();

    string back_string = "";
    float back_menudest = 0;

    switch(menu_map_mode) {
        case MAP_SOLOSTOCK: Menu_DrawTitle("SELECT MAP: SOLO"); back_string = "Return to Main Menu."; back_menudest = MENU_MAIN; break;
        case MAP_SOLOUSER: Menu_DrawTitle("USER MAPS: SOLO"); back_string = "Return to Stock Map selection."; back_menudest = MENU_SOLO; break;
        case MAP_COOPSTOCK: Menu_DrawTitle("SELECT MAP: COOP"); break;
        case MAP_COOPUSER: Menu_DrawTitle("USER MAPS: COOP"); break;
        default: break;
    }

    Menu_DrawMapPanel();

    int i;

    // Stock Maps
    if (menu_map_mode == MAP_SOLOSTOCK || menu_map_mode == MAP_COOPSTOCK) {
        for(i = 0; i < stock_maps.length; i++) {
            Menu_MapButton(i + 1, sprintf("map_%s", stock_maps[i].bsp_name), stock_maps[i].bsp_name, -1) ? Menu_Maps_LoadMap(stock_maps[i].bsp_name) : 0;
        }
        Menu_DrawDivider(i + 1.25);
        Menu_Button(i + 1.5, "map_nzpusermaps", "USER MAPS", "View User-Created Maps.") ? current_menu = MENU_SOLOUSER : 0;
    } else {
        // calculate the amount of usermaps we can display on this page.
        int maps_on_page = 10; // default to 10, all that will fit on the UI.
        int maps_start_position = (user_maps_page * 10);

        // Not all 10 slots can be filled..
        if (maps_on_page > user_maps_count - maps_start_position)
            maps_on_page = user_maps_count - maps_start_position;

        for (i = maps_start_position; i < maps_on_page + maps_start_position; i++) {
            int menu_position = (i + 1) - (user_maps_page * 10);
            string bsp_name = user_maps[i].map_name;

            Menu_MapButton(menu_position, sprintf("map_%s", bsp_name), bsp_name, i) ? localcmd(sprintf("map %s\n", bsp_name)) : 0;
        }

        Menu_DrawDivider(11.25);

        if (maps_on_page + maps_start_position < user_maps_count)
            Menu_Button(-3, "map_usernext", "NEXT PAGE", "Advance to next User Map page.") ? Menu_Maps_NextPage() : 0;
        else
            Menu_GreyButton(-3, "NEXT PAGE");

        if (user_maps_page != 0)
            Menu_Button(-2, "map_userprev", "PREVIOUS PAGE", "Return to last User Map page.") ? Menu_Maps_PrevPage() : 0;
        else
            Menu_GreyButton(-2, "PREVIOUS PAGE");
    }

    Menu_Button(-1, "map_back", "BACK", back_string) ? current_menu = back_menudest : 0;

	sui_pop_frame();	
};