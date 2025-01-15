/*
	client/draw.qc

	Enhanced CSQC 2D Drawing Code

	Copyright (C) 2021-2024 NZ:P Team

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

int font_kerningamount[96];

// ! " # $ % & ' ( ) * _ , - . / 0
// 1 2 3 4 5 6 7 8 9 : ; < = > ? @
// A B C D E F G H I J K L M N O P
// Q R S T U V W X Y Z [ \ ] ^ _ `
// a b c d e f g h i j k l m n o p
// q r s t u v w x y z { | } ~
int font_kerningamount[96];

void InitKerningMap(void)
{
	// Initialize the kerning amount as 8px for each
	// char in the event we cant load the file.
	for(int i = 0; i < 96; i++) {
		font_kerningamount[i] = 8;
	}

    int kerning_map = fopen("gfx/kerning_map.txt", FILE_READ);
    if (kerning_map == -1) {
        return;
    }

    tokenize(fgets(kerning_map));
    for(int i = 0; i < 96 * 2; i += 2) {
        font_kerningamount[i / 2] = stof(argv(i));
    }

    fclose(kerning_map);
}

float(string text, float size) getTextWidth =
{
    int width = 0;

    for(int i = 0; i < strlen(text); i++) {
        float chr = str2chr(text, i);
        // Hooray for variable-spacing!
		if (chr == ' ')
			width += 4 * (size/8);
        else if (chr < 33 || chr > 126)
            width += 8 * (size/8);
        else
            width += (font_kerningamount[(chr - 33)] + 1) * (size/8);
    }

    return width;
}

void(vector position, string text, vector size, vector rgb, float alpha, float drawflag) Draw_String =
{
    int x, y;
    x = position_x;
    y = position_y;
    for(int i = 0; i < strlen(text); i++) {
        float chr = str2chr(text, i);
        drawcharacter([x, y], chr, size, rgb, alpha, drawflag);
        
        // Hooray for variable-spacing!
		if (chr == ' ')
			x += 4 * (size_x/8);
        else if (chr < 33 || chr > 126)
            x += 8 * (size_x/8);
        else
            x += (font_kerningamount[(chr - 33)] + 1) * (size_x/8);
    }
};

void(vector pos, string label, vector v) Draw_FancyVector =
{
	Draw_String(pos, label, [12, 12], [1, 1, 0], 1, 0);
	Draw_String(pos + [32, 16], sprintf("X: %d", v.x), [12, 12], [1, 1, 1], 1, 0);
	Draw_String(pos + [32, 32], sprintf("Y: %d", v.y), [12, 12], [1, 1, 1], 1, 0);
	Draw_String(pos + [32, 48], sprintf("Z: %d", v.z), [12, 12], [1, 1, 1], 1, 0);
};

void(vector pos, string label, float f, string suffix) Draw_FancyFloat =
{
	Draw_String(pos, label, [12, 12], [1, 1, 0], 1, 0);
	Draw_String(pos + [32, 16], sprintf("%d %s", f, suffix), [12, 12], [1, 1, 1], 1, 0);
};
