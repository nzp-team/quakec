var struct credits_s
{
	string header;
	string contributors[4];
};

string credits_models[4] =
{
    "blubs, Ju[s]tice, Derped_Crusader, cypress,",
    "BCDeshiG, Revnova, Naievil, Stoohp,",
    "Jacob Giguere, Lexi",
    ""
};

string credits_code[4] =
{
    "blubs, Jukki, DR_Mabuse1981, Naievil, cypress,",
    "Scatterbox, Peter0x44",
    "",
    ""
};

string credits_art[4] =
{
    "Ju[s]tice, blubs, cypress, Derped_Crusader",
    "",
    "",
    ""
};

string credits_music[4] =
{
    "blubs, Marty P., cypress",
    "",
    "",
    ""
};

string credits_sfx[4] =
{
    "blubs, Biodude, cypress",
    "",
    "",
    ""
};

string credits_thx[4] =
{
    "Spike, eukara, Shpuld, Crow_Bar, st1x51,",
    "fgsfdsfgs, MasterFeizz, Rinnegatamante,",
    "Azenn"
};

credits_s credits[] =
{
    {
        "MODELING, MAPS",
        {
            credits_models[0],
            credits_models[1],
            credits_models[2],
            credits_models[3]    
        }
    },
    {
        "PROGRAMMING", 
        {
            credits_code[0],
            credits_code[1],
            credits_code[2],
            credits_code[3]
        }
    },
    {
        "2D ART", 
        {
            credits_art[0],
            credits_art[1],
            credits_art[2],
            credits_art[3]
        }
    },
    {
        "MUSIC", 
        {
            credits_music[0],
            credits_music[1],
            credits_music[2],
            credits_music[3]
        }
    },
    {
        "SFX", 
        {
            credits_sfx[0],
            credits_sfx[1],
            credits_sfx[2],
            credits_sfx[3]
        }
    },
    {
        "SPECIAL THANKS", 
        {
            credits_thx[0],
            credits_thx[1],
            credits_thx[2],
            credits_thx[3]
        }
    }
};

void() Menu_Credits =
{
    Menu_DrawBackground();
    Menu_DrawTitle("CREDITS");
    Menu_DrawMapPanel();

    for(int i = 0; i < credits.length; i++) {
        Menu_DrawCreditHeader(i, credits[i].header);

        for(int j = 0; j < 4; j++) {
            Menu_DrawCreditContributor(i, j, credits[i].contributors[j]);
        }
    }

    Menu_Button(-1, "cr_back", "BACK", "Return to Main Menu.") ? current_menu = MENU_MAIN : 0;

	sui_pop_frame();
};