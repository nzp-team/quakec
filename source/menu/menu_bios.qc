string menu_bios_buttons[13] = {
    "bi_0", 
    "bi_1", 
    "bi_2", 
    "bi_3", 
    "bi_4", 
    "bi_5", 
    "bi_6", 
    "bi_7", 
    "bi_8", 
    "bi_9", 
    "bi_10", 
    "bi_11", 
    "bi_back"
};

var struct
{
    string name;
    string map;
    string portrait;
    vector portrait_coords;
    string description[17];
} menu_bio_info[] =
{
    {
        "TANK DEMPSEY",
        "VERRUCKT",
        "portait_0.tga",
        [0, 0],
        {
            "Great American Hero: Tank Dempsey is a legend among men. Rigid",
            "and well disciplined, Tank is a man of strength and sheer will.",
            "Of those who have tried none of his enemies have ever been",
            "able to keep this monster down for long. Personally chosen by",
            "Purnell to lead the rescue mission of missing operative Peter",
            "McCain; after displaying immense skill during prior missions",
            "it's no wonder why the choice was made. His skills in hand to",
            "hand combat, weapons expertise, and headstrong nature make him",
            "the perfect candidate for this expedition. Known for his",
            "unwavering determination, tales of his exploits are widespread;",
            "it's said that he once took out an entire cohort of enemies",
            "armed only with a bobby pin and his medal of honor, that's just",
            "one of many stories spun about his heroics. No one knows the",
            "full extent of what he could be capable of, but if the rumors",
            "have any merrit, he isn't a man you want to make an enemy of.", 
            "Only one thing is known for certain, Dempsey may one day perish,",
            "but his legend will never die."
        }
    },
    {
        "??????????",
        "??????",
        "portrait_0.tga",
        [0.5, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_0.tga",
        [0, 0.5],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_0.tga",
        [0.5, 0.5],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_1.tga",
        [0, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_1.tga",
        [0, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_1.tga",
        [0, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_1.tga",
        [0, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_2.tga",
        [0, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_2.tga",
        [0, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_2.tga",
        [0, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    },
    {
        "??????????",
        "??????",
        "portrait_2.tga",
        [0, 0],
        {
            "???",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            "",
            ""
        }
    }
};

int menu_bios_biosubmenu;

string(string prev_id) Menu_Bios_GetNextButton =
{
    if (menu_bios_biosubmenu != 0)
        return "bi_back";

    if (prev_id == "")
        return menu_bios_buttons[0];

    string ret = menu_bios_buttons[0];

    for(float i = 0; i < menu_bios_buttons.length; i++) {
        if (menu_bios_buttons[i] == prev_id) {
            if (i + 1 >= menu_bios_buttons.length)
                break;

            ret = menu_bios_buttons[i + 1];
            break;
        }
    }

    return ret;
};

string(string next_id) Menu_Bios_GetPreviousButton =
{
    if (menu_bios_biosubmenu != 0)
        return "bi_back";

    if (next_id == "")
        return menu_bios_buttons[menu_bios_buttons.length - 1];

    string ret = menu_bios_buttons[menu_bios_buttons.length - 1];

    for(float i = menu_bios_buttons.length - 1; i > 0; i--) {
        if (menu_bios_buttons[i] == next_id) {
            if (i - 1 < 0)
                break;

            ret = menu_bios_buttons[i - 1];
            break;
        }
    }

    return ret;
};

void(int idx) Menu_Bios_EnterSubMenu =
{
    if (idx > 1)
        return;
    Menu_PlaySound(MENU_SND_ENTER);
    menu_bios_biosubmenu = idx;
};

void() Menu_Bios =
{
    Menu_DrawBackground();
    Menu_DrawTitle("CHARACTER BIOS");
    Menu_DrawMapPanel();

    if (menu_bios_biosubmenu == 0)
    {
        for (float i = 0; i < 12; i++) {
            Menu_BioButton(
                i + 1, 
                sprintf("bi_%d", i), 
                menu_bio_info[i].name, 
                menu_bio_info[i].map, 
                menu_bio_info[i].portrait,
                menu_bio_info[i].portrait_coords
            ) ? Menu_Bios_EnterSubMenu(i + 1) : 0;
        }

        Menu_DrawDivider(13.25);

        Menu_Button(-1, "bi_back", "BACK", "Return to Main Menu.") ? current_menu = MENU_MAIN : 0;
    }
    else
    {

        Menu_DrawCharacterPanel(
            menu_bio_info[menu_bios_biosubmenu - 1].description[0],
            menu_bio_info[menu_bios_biosubmenu - 1].description[1],
            menu_bio_info[menu_bios_biosubmenu - 1].description[2],
            menu_bio_info[menu_bios_biosubmenu - 1].description[3],
            menu_bio_info[menu_bios_biosubmenu - 1].description[4],
            menu_bio_info[menu_bios_biosubmenu - 1].description[5],
            menu_bio_info[menu_bios_biosubmenu - 1].description[6],
            menu_bio_info[menu_bios_biosubmenu - 1].description[7],
            menu_bio_info[menu_bios_biosubmenu - 1].description[8],
            menu_bio_info[menu_bios_biosubmenu - 1].description[9],
            menu_bio_info[menu_bios_biosubmenu - 1].description[10],
            menu_bio_info[menu_bios_biosubmenu - 1].description[11],
            menu_bio_info[menu_bios_biosubmenu - 1].description[12],
            menu_bio_info[menu_bios_biosubmenu - 1].description[13],
            menu_bio_info[menu_bios_biosubmenu - 1].description[14],
            menu_bio_info[menu_bios_biosubmenu - 1].description[15],
            menu_bio_info[menu_bios_biosubmenu - 1].description[16]
        );

        Menu_Button(-1, "bi_back", "BACK", "") ? Menu_Bios_EnterSubMenu(0) : 0;
    }
    
	sui_pop_frame();	
};