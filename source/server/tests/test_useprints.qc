/*
	server/tests/test_useprints.qc

	Useprint registry tests.

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

float(float condition, string message) Test_Assert;

void() Test_Useprint_RegisterAllocatesDefinition =
{
	float old_count = useprint_count;
	float old_lock = useprint_registration_locked;
	useprint_registration_locked = false;

	float index = Useprint_Register("test useprint allocation", '0 0 0');

	Test_Assert(index == old_count, "Useprint was assigned the wrong index!");
	Test_Assert(useprint_count == old_count + 1, "Useprint registry count was not incremented!");
	Test_Assert(useprint_strings[index] == "test useprint allocation", "Useprint string was not stored!");
	Test_Assert(useprint_colors[index] == '1 1 1', "An unspecified useprint color did not default to white!");

	useprint_count = old_count;
	useprint_registration_locked = old_lock;
};

void() Test_Useprint_RegisterDeduplicatesDefinition =
{
	float old_count = useprint_count;
	float old_lock = useprint_registration_locked;
	useprint_registration_locked = false;

	float first = Useprint_Register("test useprint duplicate", '0.25 0.5 0.75');
	float count_after_first = useprint_count;
	float second = Useprint_Register("test useprint duplicate", '0.25 0.5 0.75');

	Test_Assert(first == second, "Identical useprints received different indexes!");
	Test_Assert(useprint_count == count_after_first, "A duplicate useprint grew the registry!");

	useprint_count = old_count;
	useprint_registration_locked = old_lock;
};

void() Test_Useprint_RegisterSeparatesColors =
{
	float old_count = useprint_count;
	float old_lock = useprint_registration_locked;
	useprint_registration_locked = false;

	float white = Useprint_Register("test colored useprint", '1 1 1');
	float red = Useprint_Register("test colored useprint", '1 0 0');

	Test_Assert(white != red, "Differently colored useprints shared an index!");
	Test_Assert(useprint_colors[white] == '1 1 1', "White useprint stored the wrong color!");
	Test_Assert(useprint_colors[red] == '1 0 0', "Red useprint stored the wrong color!");

	useprint_count = old_count;
	useprint_registration_locked = old_lock;
};

void() Test_Useprint_GenericSlotsStoreIndexes =
{
	float old_count = useprint_count;
	float old_lock = useprint_registration_locked;
	useprint_registration_locked = false;

	entity item = spawn();
	item.useprint_string_1 = "test slot one %b";
	item.useprint_string_2 = "test slot two %s";
	item.useprint_string_3 = item.useprint_string_1;
	item.useprint_color_2 = '0 1 0';

	item.useprint_index_1 = Useprint_Register(item.useprint_string_1, item.useprint_color_1);
	item.useprint_index_2 = Useprint_Register(item.useprint_string_2, item.useprint_color_2);
	item.useprint_index_3 = Useprint_Register(item.useprint_string_3, item.useprint_color_3);

	Test_Assert(item.useprint_index_1 != 0, "Generic useprint slot one was not registered!");
	Test_Assert(item.useprint_index_2 != item.useprint_index_1, "Distinct generic slots shared an index!");
	Test_Assert(item.useprint_index_3 == item.useprint_index_1, "Equivalent generic slots were not deduplicated!");

	remove(item);
	useprint_count = old_count;
	useprint_registration_locked = old_lock;
};

void() Test_Useprint_RegistryLockedAfterClientJoin =
{
	Test_Assert(useprint_registration_locked, "Useprint registration was not locked before gameplay!");
};
