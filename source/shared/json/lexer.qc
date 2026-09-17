/*
	shared/json/lexer.qc

	JSON Tokenization

	Copyright (C) 2021-2026 NZ:P Team

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

#define JSON_FILE_READ 0
#define JTOK_EOF 0
#define JTOK_LBRACE 1
#define JTOK_RBRACE 2
#define JTOK_LBRACKET 3
#define JTOK_RBRACKET 4
#define JTOK_COLON 5
#define JTOK_COMMA 6
#define JTOK_STRING 10
#define JTOK_NUMBER 11
#define JTOK_TRUE 12
#define JTOK_FALSE 13
#define JTOK_NULL 14
#define JTOK_ERROR 99

string json_src;
float json_pos, json_len, json_offset;
float json_file, json_file_active, json_source_owned;
float json_tok;
string json_tok_s;
float json_tok_f;
float json_error, json_error_pos;
string json_error_msg;

void() Json_ClearTokenString =
{
    if (json_tok_s != "") strunzone(json_tok_s);
    json_tok_s = "";
};

void() Json_ClearError =
{
    json_error = false;
    json_error_pos = 0;
    json_error_msg = "";
};

void(string message) Json_Fail =
{
    json_error = true;
    json_error_pos = json_offset + json_pos;
    json_error_msg = message;
    json_tok = JTOK_ERROR;
};

//
// Json_ReadLine()
// Vril's fgets() and string builtins share a 2048-byte scratch buffer.
// Zone each line and read files incrementally instead of concatenating them.
//
void() Json_ReadLine =
{
    string line;
    if (json_source_owned) strunzone(json_src);
    json_source_owned = false;
    json_src = "";
    line = fgets(json_file);
    json_offset += json_len + 1;
    json_pos = json_len = 0;

    // EOF is handle zero. Blank lines have a nonzero handle, despite
    // comparing equal to "" by contents.
    if ((float)(__variant)line == 0) {
        fclose(json_file);
        json_file_active = false;
        return;
    }
    json_len = strlen(line);
    if (json_len >= 2047) {
        Json_Fail("JSON line exceeds 2046 bytes");
        return;
    }
    // Discard indentation before scanning tokens to keep startup within the VM budget.
    json_src = strzone(strtrim(line));
    json_len = strlen(json_src);
    json_source_owned = true;
};

void() Json_EndLex =
{
    if (json_file_active) fclose(json_file);
    json_file_active = false;
    if (json_source_owned) strunzone(json_src);
    json_source_owned = false;
    json_src = "";
    Json_ClearTokenString();
};

void(string text) Json_BeginLex =
{
    Json_EndLex();
    Json_ClearError();
    json_src = strzone(text);
    json_source_owned = true;
    json_pos = json_offset = 0;
    json_len = strlen(json_src);
    json_tok = JTOK_EOF;
};

//
// Json_SkipWhitespaceAndComments()
// Reading another line is only allowed between tokens or in a block comment.
// Strings, numbers and keywords cannot continue across a physical newline.
//
void() Json_SkipWhitespaceAndComments =
{
    string c;
    float block_comment = false;
    while (!json_error) {
        if (json_pos >= json_len) {
            if (json_file_active) { Json_ReadLine(); continue; }
            if (block_comment) Json_Fail("Unterminated block comment");
            return;
        }
        c = substring(json_src, json_pos, 1);
        if (block_comment) {
            if (c == "*" && substring(json_src, json_pos + 1, 1) == "/") {
                json_pos += 2;
                block_comment = false;
            } else json_pos++;
            continue;
        }
        if (c == " " || c == "\t" || c == "\n" || c == "\r") { json_pos++; continue; }
        if (c == "/") {
            c = substring(json_src, json_pos + 1, 1);
            if (c == "*") { json_pos += 2; block_comment = true; continue; }
            if (c == "/") {
                while (json_pos < json_len) {
                    c = substring(json_src, json_pos, 1);
                    json_pos++;
                    if (c == "\n" || c == "\r") break;
                }
                continue;
            }
        }
        return;
    }
};

void(string part) Json_AppendToken =
{
    string next;
    if (strlen(json_tok_s) + strlen(part) > 1023) {
        Json_Fail("JSON token exceeds 1023 bytes");
        return;
    }
    if (part == "") return;
    next = strzone(strcat(json_tok_s, part));
    Json_ClearTokenString();
    json_tok_s = next;
};

//
// Json_LexString()
// Copy runs of ordinary characters together. Zoning each character creates
// thousands of temporary handles and exhausts Vril's zone during startup.
//
void() Json_LexString =
{
    float end, escape, stop, control;
    string c, part;
    json_pos++;
    while (!json_error) {
        end = strstrofs(json_src, "\"", json_pos);
        if (end < 0) { Json_Fail("Unterminated string"); return; }
        escape = strstrofs(json_src, "\\", json_pos);
        stop = end;
        if (escape >= 0 && escape < end) stop = escape;
        control = strstrofs(json_src, "\n", json_pos);
        if (control >= 0 && control < stop) { Json_Fail("Unescaped newline in string"); return; }
        control = strstrofs(json_src, "\r", json_pos);
        if (control >= 0 && control < stop) { Json_Fail("Unescaped carriage return in string"); return; }
        control = strstrofs(json_src, "\t", json_pos);
        if (control >= 0 && control < stop) { Json_Fail("Unescaped tab in string"); return; }
        Json_AppendToken(substring(json_src, json_pos, stop - json_pos));
        if (json_error) return;
        json_pos = stop + 1;
        if (stop == end) return;
        c = substring(json_src, json_pos, 1);
        if (c == "\"" || c == "\\" || c == "/") Json_AppendToken(c);
        else if (c == "n") Json_AppendToken("\n");
        else if (c == "r") Json_AppendToken("\r");
        else if (c == "t") Json_AppendToken("\t");
        else if (c == "b") Json_AppendToken("\b");
        else if (c == "f") Json_AppendToken("\f");
        else { Json_Fail("Unsupported string escape (use UTF-8 for Unicode)"); return; }
        json_pos++;
    }
};

float(string c) Json_IsDigit =
{
    return c == "0" || c == "1" || c == "2" || c == "3" || c == "4" ||
        c == "5" || c == "6" || c == "7" || c == "8" || c == "9";
};

void() Json_LexNumber =
{
    float start = json_pos;
    string c;
    if (substring(json_src, json_pos, 1) == "-") json_pos++;
    c = substring(json_src, json_pos, 1);
    if (c == "0") json_pos++;
    else {
        if (!Json_IsDigit(c)) { Json_Fail("Expected digit"); return; }
        while (Json_IsDigit(substring(json_src, json_pos, 1))) json_pos++;
    }
    if (substring(json_src, json_pos, 1) == ".") {
        json_pos++;
        if (!Json_IsDigit(substring(json_src, json_pos, 1))) { Json_Fail("Expected digit after decimal point"); return; }
        while (Json_IsDigit(substring(json_src, json_pos, 1))) json_pos++;
    }
    c = substring(json_src, json_pos, 1);
    if (c == "e" || c == "E") {
        json_pos++;
        c = substring(json_src, json_pos, 1);
        if (c == "+" || c == "-") json_pos++;
        if (!Json_IsDigit(substring(json_src, json_pos, 1))) { Json_Fail("Expected exponent digits"); return; }
        while (Json_IsDigit(substring(json_src, json_pos, 1))) json_pos++;
    }
    Json_AppendToken(substring(json_src, start, json_pos - start));
    json_tok_f = stof(json_tok_s);
};

void() Json_NextToken =
{
    string c;
    if (json_error) return;
    Json_ClearTokenString();
    json_tok_f = 0;
    Json_SkipWhitespaceAndComments();
    if (json_error) return;
    if (json_pos >= json_len) { json_tok = JTOK_EOF; return; }
    c = substring(json_src, json_pos, 1);
    if (c == "{") { json_pos++; json_tok = JTOK_LBRACE; return; }
    if (c == "}") { json_pos++; json_tok = JTOK_RBRACE; return; }
    if (c == "[") { json_pos++; json_tok = JTOK_LBRACKET; return; }
    if (c == "]") { json_pos++; json_tok = JTOK_RBRACKET; return; }
    if (c == ":") { json_pos++; json_tok = JTOK_COLON; return; }
    if (c == ",") { json_pos++; json_tok = JTOK_COMMA; return; }
    if (c == "\"") { json_tok = JTOK_STRING; Json_LexString(); return; }
    if (c == "-" || Json_IsDigit(c)) { json_tok = JTOK_NUMBER; Json_LexNumber(); return; }
    if (substring(json_src, json_pos, 4) == "true") { json_pos += 4; json_tok = JTOK_TRUE; return; }
    if (substring(json_src, json_pos, 5) == "false") { json_pos += 5; json_tok = JTOK_FALSE; return; }
    if (substring(json_src, json_pos, 4) == "null") { json_pos += 4; json_tok = JTOK_NULL; return; }
    Json_Fail("Unexpected character");
};

// Debug helper: show current token
string() Json_TokenName =
{
	switch (json_tok) {
		case JTOK_EOF: return "EOF";
		case JTOK_LBRACE: return "{";
		case JTOK_RBRACE: return "}";
		case JTOK_LBRACKET: return "[";
		case JTOK_RBRACKET: return "]";
		case JTOK_COLON: return ":";
		case JTOK_COMMA: return ",";
		case JTOK_STRING: return "STRING";
		case JTOK_NUMBER: return "NUMBER";
		case JTOK_TRUE: return "TRUE";
		case JTOK_FALSE: return "FALSE";
		case JTOK_NULL: return "NULL";
		case JTOK_ERROR: return "ERROR";
		default: return "???";
	}
};

