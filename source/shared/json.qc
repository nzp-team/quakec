/*
	shared/json.qc

	JSON value helpers

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

#define JNODE_STRING 0
#define JNODE_NUMBER 1
#define JNODE_OBJECT 2
#define JNODE_ARRAY 3
#define JNODE_TRUE 4
#define JNODE_FALSE 5
#define JNODE_NULL 6
#define JNODE_BOOL 7

#define JSON_ERROR_NOT_FOUND 1

float json_file_missing;
string json_error_msg;

//
// Json_Fail(message)
// Sets the current configuration error.
//
void(string message) Json_Fail =
{
	json_error_msg = message;
};

//
// Json_ParseFile(path)
// Loads a JSON file and keeps its error for the configuration loader.
//
float(string path) Json_ParseFile =
{
	float root = json_parse_file(path);
	json_file_missing = json_get_error_code() == JSON_ERROR_NOT_FOUND;
	json_error_msg = root ? "" : json_get_error();
	return root;
};

//
// Json_Type(node)
// Returns the value type, treating a missing node as null.
//
float(float node) Json_Type =
{
	if (!node) return JNODE_NULL;
	return json_get_value_type(node);
};

//
// Json_IsType(node, type)
// Checks a node type, including either JSON boolean value.
//
float(float node, float type) Json_IsType =
{
	float actual = Json_Type(node);
	if (type == JNODE_BOOL) return actual == JNODE_TRUE || actual == JNODE_FALSE;
	return actual == type;
};

//
// Json_ObjectGet(obj, key)
// Finds a named value in an object.
//
float(float obj, string key) Json_ObjectGet =
{
	return json_find_object_child(obj, key);
};

//
// Json_ArrayLen(arr)
// Returns the number of values in an array.
//
float(float arr) Json_ArrayLen =
{
	if (Json_Type(arr) != JNODE_ARRAY) return 0;
	return json_get_length(arr);
};

//
// Json_ArrayAt(arr, index)
// Returns an array value by index.
//
float(float arr, float index) Json_ArrayAt =
{
	if (Json_Type(arr) != JNODE_ARRAY) return 0;
	return json_get_child_at_index(arr, index);
};

//
// Json_AsString(node, fallback)
// Returns a string value or the supplied fallback.
//
string(float node, string fallback) Json_AsString =
{
	if (Json_Type(node) != JNODE_STRING) return fallback;
	return json_get_string(node);
};

//
// Json_AsFloat(node, fallback)
// Returns a numeric value or the supplied fallback.
//
float(float node, float fallback) Json_AsFloat =
{
	float type = Json_Type(node);
	if (type == JNODE_NUMBER) return json_get_float(node);
	if (type == JNODE_TRUE) return true;
	if (type == JNODE_FALSE) return false;
	return fallback;
};

//
// Json_AsBool(node, fallback)
// Returns a boolean value or the supplied fallback.
//
float(float node, float fallback) Json_AsBool =
{
	float type = Json_Type(node);
	if (type == JNODE_TRUE) return true;
	if (type == JNODE_FALSE) return false;
	if (type == JNODE_NUMBER) return json_get_float(node) != 0;
	return fallback;
};

//
// Json_GetPath(root, path)
// Finds a value using a dot separated object path.
//
float(float root, string path) Json_GetPath =
{
	float start = 0;
	float current = root;
	while (current) {
		float end = strstrofs(path, ".", start);
		if (end < 0) end = strlen(path);
		current = Json_ObjectGet(current, substring(path, start, end - start));
		if (!current || end == strlen(path)) return current;
		start = end + 1;
	}
	return 0;
};

//
// Json_GetFloatPath(root, path, fallback)
// Reads a numeric value from an object path.
//
float(float root, string path, float fallback) Json_GetFloatPath =
{
	return Json_AsFloat(Json_GetPath(root, path), fallback);
};

//
// Json_GetBoolPath(root, path, fallback)
// Reads a boolean value from an object path.
//
float(float root, string path, float fallback) Json_GetBoolPath =
{
	return Json_AsBool(Json_GetPath(root, path), fallback);
};

//
// Json_GetStringPath(root, path, fallback)
// Reads a string value from an object path.
//
string(float root, string path, string fallback) Json_GetStringPath =
{
	return Json_AsString(Json_GetPath(root, path), fallback);
};

//
// Json_ArrayStringAt(array, index, fallback)
// Reads a string from an array.
//
string(float array, float index, string fallback) Json_ArrayStringAt =
{
	return Json_AsString(Json_ArrayAt(array, index), fallback);
};
