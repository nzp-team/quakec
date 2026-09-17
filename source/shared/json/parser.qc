/*
	shared/json/parser.qc

	JSON Parsing and Value resolution

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

// MARK: Node model

#define JNODE_NULL     0
#define JNODE_OBJECT   1
#define JNODE_ARRAY    2
#define JNODE_STRING   3
#define JNODE_NUMBER   4
#define JNODE_BOOL     5

#define JSON_MAX_NODES  1024
#define JSON_MAX_DEPTH  8

float json_depth;

float  j_type[JSON_MAX_NODES];
float  j_first[JSON_MAX_NODES];
float  j_next[JSON_MAX_NODES];

string j_key[JSON_MAX_NODES];
float  j_keycrc[JSON_MAX_NODES];

string j_s[JSON_MAX_NODES];
float  j_f[JSON_MAX_NODES];
float  j_b[JSON_MAX_NODES];

float  j_used;

// Object lookups share a hash table. Generation tags avoid clearing every bucket.
#define JSON_KEY_BUCKETS 1024
float j_key_heads[JSON_KEY_BUCKETS];
float j_key_generation[JSON_KEY_BUCKETS];
float j_key_next[JSON_MAX_NODES];
float j_parent[JSON_MAX_NODES];
float j_generation;

float(float object, float hash) Json_KeyBucket =
{
	float value = hash + object * 31;
	return value - floor(value / JSON_KEY_BUCKETS) * JSON_KEY_BUCKETS;
};

// Validation and application ask for the same paths in each file.
// Cache them for this parse so we only walk each dotted path once.
#define JSON_MAX_PATHS 512
string j_path[JSON_MAX_PATHS];
float j_path_root[JSON_MAX_PATHS];
float j_path_crc[JSON_MAX_PATHS];
float j_path_node[JSON_MAX_PATHS];
float j_path_slots[JSON_MAX_PATHS];
float j_path_count;


void() Json_ResetNodes =
{
	// Every parse owns its keys and string values. No node survives a reset.
	for (float i = 1; i < j_used; i++) {
		if (j_key[i] != "") strunzone(j_key[i]);
		if (j_s[i] != "") strunzone(j_s[i]);
		j_key[i] = j_s[i] = "";
	}
	for (float entry = 0; entry < j_path_count; entry++) {
		float slot = j_path_slots[entry];
		strunzone(j_path[slot]);
		j_path[slot] = "";
		j_path_root[slot] = 0;
	}
	j_path_count = 0;
	j_generation++;
	j_used = 1;
	json_depth = 0;
};

float(float type) Json_NewNode =
{
	float i;

	if (j_used >= JSON_MAX_NODES) {
		Json_Fail("JSON node pool exhausted");
		return 0;
	}

	i = j_used;
	j_used++;

	j_type[i] = type;
	j_first[i] = 0;
	j_next[i] = 0;

	j_key[i] = "";
	j_keycrc[i] = 0;

	j_s[i] = "";
	j_f[i] = 0;
	j_b[i] = 0;

	return i;
};

// MARK: Parsing

float(float want) Json_Accept =
{
	if (json_tok == want) {
		Json_NextToken();
		return true;
	}
	return false;
};

float(float want) Json_Expect =
{
	if (json_tok != want) {
        string fail_str = strcat("Expected token ", ftos(want));
        fail_str = strcat(fail_str, " got ");
        fail_str = strcat(fail_str, Json_TokenName());
        Json_Fail(fail_str);
		return false;
	}

	Json_NextToken();
	return true;
};

// Forward decls
float() Json_ParseValue;
float() Json_ParseObject;
float() Json_ParseArray;
float(float obj, string key) Json_ObjectGet;

//
// Json_ParseCurrent()
// Finish input cleanup even when parsing fails. Callers can inspect
// json_error_msg and json_error_pos before starting the next file.
//
float() Json_ParseCurrent =
{
	float root;
	Json_NextToken();
	root = Json_ParseValue();
	if (!json_error && json_tok != JTOK_EOF)
		Json_Fail("Trailing garbage after JSON root");
	Json_EndLex();
	if (json_error) return 0;
	return root;
};

float(string text) Json_ParseText =
{
	Json_ResetNodes();
	Json_BeginLex(text);
	return Json_ParseCurrent();
};

float json_file_missing;

float(string path) Json_ParseFile =
{
	Json_ResetNodes();
	Json_EndLex();
	Json_ClearError();
	json_file_missing = false;
	json_offset = -1;
	json_len = 0;
	json_file = fopen(path, JSON_FILE_READ);
	if (json_file < 0) {
		json_file_missing = true;
		return 0;
	}
	json_file_active = true;
	Json_ReadLine();
	return Json_ParseCurrent();
};

// MARK: Value resolution

float() Json_ParseValue =
{
	float n;

	if (json_error) return 0;
	if (json_tok == JTOK_LBRACE || json_tok == JTOK_LBRACKET) {
		if (json_depth >= JSON_MAX_DEPTH) {
			Json_Fail("JSON nesting exceeds 8 levels");
			return 0;
		}
		json_depth++;
		if (json_tok == JTOK_LBRACE) n = Json_ParseObject();
		else n = Json_ParseArray();
		json_depth--;
		return n;
	}

	if (json_tok == JTOK_STRING) {
		n = Json_NewNode(JNODE_STRING);
		if (!n) return 0;

		if (json_tok_s != "") j_s[n] = strzone(json_tok_s);
		Json_NextToken();
		return n;
	}

	if (json_tok == JTOK_NUMBER) {
		n = Json_NewNode(JNODE_NUMBER);
		if (!n) return 0;

		j_f[n] = json_tok_f;

		Json_NextToken();
		return n;
	}

	if (json_tok == JTOK_TRUE || json_tok == JTOK_FALSE) {
		n = Json_NewNode(JNODE_BOOL);
		if (!n) return 0;

		j_b[n] = (json_tok == JTOK_TRUE);
		Json_NextToken();
		return n;
	}

	if (json_tok == JTOK_NULL) {
		n = Json_NewNode(JNODE_NULL);
		if (!n) return 0;

		Json_NextToken();
		return n;
	}

	Json_Fail(strcat("Unexpected token in value: ", Json_TokenName()));
	return 0;
};

float() Json_ParseObject =
{
	float obj;
	float last;
	string key;
	float child;

	obj = Json_NewNode(JNODE_OBJECT);
	if (!obj) return 0;

	// consume '{'
	Json_NextToken();

	// empty object
	if (Json_Accept(JTOK_RBRACE))
		return obj;

	last = 0;

	while (1) {
		if (json_tok != JTOK_STRING) {
			Json_Fail("Expected string key in object");
			return 0;
		}

		if (Json_ObjectGet(obj, json_tok_s)) {
			Json_Fail("Duplicate object key");
			return 0;
		}
		key = json_tok_s != "" ? strzone(json_tok_s) : "";
		Json_NextToken();

		if (!Json_Expect(JTOK_COLON)) {
			if (key != "") strunzone(key);
			return 0;
		}

		child = Json_ParseValue();
		if (json_error) { if (key != "") strunzone(key); return 0; }

		j_key[child] = key;
		j_keycrc[child] = crc16(1, key);
		float bucket = Json_KeyBucket(obj, j_keycrc[child]);
		j_key_next[child] = j_key_generation[bucket] == j_generation ? j_key_heads[bucket] : 0;
		j_key_heads[bucket] = child;
		j_key_generation[bucket] = j_generation;
		j_parent[child] = obj;

		if (!j_first[obj])
			j_first[obj] = child;
		else
			j_next[last] = child;

		last = child;

		if (Json_Accept(JTOK_COMMA))
			continue;

		if (Json_Accept(JTOK_RBRACE))
			break;

		Json_Fail("Expected ',' or '}' in object");
		return 0;
	}

	return obj;
};

// MARK: Arrays

float() Json_ParseArray =
{
	float arr;
	float last;
	float child;

	arr = Json_NewNode(JNODE_ARRAY);
	if (!arr) return 0;

	// consume '['
	Json_NextToken();

	// empty array
	if (Json_Accept(JTOK_RBRACKET))
		return arr;

	last = 0;

	while (1) {
		child = Json_ParseValue();
		if (json_error) return 0;

		if (!j_first[arr])
			j_first[arr] = child;
		else
			j_next[last] = child;

		last = child;

		if (Json_Accept(JTOK_COMMA))
			continue;

		if (Json_Accept(JTOK_RBRACKET))
			break;

		Json_Fail("Expected ',' or ']' in array");
		return 0;
	}

	return arr;
};

float(float obj, string key) Json_ObjectGet =
{
	float want;
	float c;

	if (!obj || j_type[obj] != JNODE_OBJECT)
		return 0;

	want = crc16(1, key);

	float bucket = Json_KeyBucket(obj, want);
	if (j_key_generation[bucket] != j_generation) return 0;
	for (c = j_key_heads[bucket]; c; c = j_key_next[c]) {
		if (j_parent[c] != obj || j_keycrc[c] != want)
			continue;
		if (j_key[c] == key)
			return c;
	}

	return 0;
};

float(float arr) Json_ArrayLen =
{
	float n, c;

	if (!arr || j_type[arr] != JNODE_ARRAY)
		return 0;

	n = 0;
	for (c = j_first[arr]; c; c = j_next[c])
		n++;

	return n;
};

float(float arr, float idx) Json_ArrayAt =
{
	float c;
	float i;

	if (!arr || j_type[arr] != JNODE_ARRAY)
		return 0;

	i = 0;
	for (c = j_first[arr]; c; c = j_next[c]) {
		if (i == idx)
			return c;
		i++;
	}

	return 0;
};

// Typed accessors (safe defaults)
string(float n, string def) Json_AsString =
{
	if (!n) return def;
	if (j_type[n] != JNODE_STRING) return def;
	return j_s[n];
};

float(float n, float def) Json_AsFloat =
{
	if (!n) return def;
	if (j_type[n] == JNODE_NUMBER) return j_f[n];
	if (j_type[n] == JNODE_BOOL) return j_b[n];
	return def;
};

float(float n, float def) Json_AsBool =
{
	if (!n) return def;
	if (j_type[n] == JNODE_BOOL) return j_b[n];
	if (j_type[n] == JNODE_NUMBER) return (j_f[n] != 0);
	return def;
};

//
// Json_GetPath(root, path)
// Dots separate object keys. Arrays use Json_ArrayAt() instead.
//
float(float root, string path) Json_FindPath =
{
	float start, end, current;
	string key;
	if (!root) return 0;
	current = root;
	start = 0;
	while (1) {
		end = strstrofs(path, ".", start);
		if (end < 0) end = strlen(path);
		key = substring(path, start, end - start);
		current = Json_ObjectGet(current, key);
		if (!current || end == strlen(path)) return current;
		start = end + 1;
	}
};

float(float root, string path) Json_GetPath =
{
	float hash, node, slot;
	if (!root) return 0;
	hash = crc16(1, path);
	slot = hash - floor(hash / JSON_MAX_PATHS) * JSON_MAX_PATHS;
	// Collisions replace a cache entry, never a JSON value.
	if (j_path_root[slot] == root && j_path_crc[slot] == hash && j_path[slot] == path)
		return j_path_node[slot];
	node = Json_FindPath(root, path);
	if (j_path_root[slot]) strunzone(j_path[slot]);
	else j_path_slots[j_path_count++] = slot;
	j_path[slot] = strzone(path);
	j_path_crc[slot] = hash;
	j_path_root[slot] = root;
	j_path_node[slot] = node;
	return node;
};

// MARK: Value heleprs

float(float root, string path, float def) Json_GetFloatPath =
{
	float n;

	n = Json_GetPath(root, path);
	return Json_AsFloat(n, def);
};

float(float root, string path, float def) Json_GetBoolPath =
{
	float n;

	n = Json_GetPath(root, path);
	return Json_AsBool(n, def);
};

string(float root, string path, string def) Json_GetStringPath =
{
	float n;

	n = Json_GetPath(root, path);
	return Json_AsString(n, def);
};

float(float obj, string key, float def) Json_GetFloat =
{
	float n;

	n = Json_ObjectGet(obj, key);
	return Json_AsFloat(n, def);
};

float(float obj, string key, float def) Json_GetBool =
{
	float n;

	n = Json_ObjectGet(obj, key);
	return Json_AsBool(n, def);
};

string(float obj, string key, string def) Json_GetString =
{
	float n;

	n = Json_ObjectGet(obj, key);
	return Json_AsString(n, def);
};

string(float arr, float idx, string def) Json_ArrayStringAt =
{
	float n;

	n = Json_ArrayAt(arr, idx);
	return Json_AsString(n, def);
};

float(float arr, float idx, float def) Json_ArrayFloatAt =
{
	float n;

	n = Json_ArrayAt(arr, idx);
	return Json_AsFloat(n, def);
};

float(float arr, float idx, float def) Json_ArrayBoolAt =
{
	float n;

	n = Json_ArrayAt(arr, idx);
	return Json_AsBool(n, def);
};
