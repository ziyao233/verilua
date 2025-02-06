// SPDX-License-Identifier: MPL-2.0
/*
 *	verilua
 *	glue.template.cpp
 *	Copyright (c) 2025 Yao Zi.
 */

$$
	mod = tpl.arg.mod;
	name = tpl.arg.name;

	inputs, outputs = {}, {};
	local indirs = { ["INPUT"] = true, ["INOUT"] = true };
	local outdirs = { [ "OUTPUT"] = true, ["INOUT"] = true };

	for _, stmt in pairs(mod.stmtsp) do
		if stmt.type ~= "VAR" then
			goto continue;
		end

		local dir = stmt.direction;
		if indirs[dir] then
			table.insert(inputs, stmt);
		end
		if outdirs[dir] then
			table.insert(outputs, stmt);
		end
::continue::
	end
$$

extern "C" {
#include <lua.h>
#include <lua.hpp>
};

#include <iostream>
#include <cstring>

$$ tpl.result = ('#include "V%s.h"'):format(name) $$

#define MODNAME 	$$ tpl.result = name $$
#define MODTYPE 	$$ tpl.result = 'V' .. name $$
#define METANAME	$$ tpl.result = ('"verilua.%s"'):format(name) $$

static int
module_gc(lua_State *l)
{
	MODTYPE **p = (MODTYPE **)luaL_checkudata(l, 1, METANAME);

	delete (*p);

	return 0;
}

static int
module_set(lua_State *l)
{
	MODTYPE **p = (MODTYPE **)luaL_checkudata(l, 1, METANAME);
	const char *key	= luaL_checkstring(l, 2);
	uint64_t value	= luaL_checkinteger(l, 3);

$$
	local count = 0;
	tpl.result= {};
	for _, stmt in pairs(inputs) do
	table.insert(tpl.result,
([[	%sif (!strcmp(key, "%s"))
		(*p)->%s = value;
]]):format(count == 0 and "" or "else ", stmt.name, stmt.name));
		count = count + 1;
	end
$$	else
		luaL_error(l, "unknown variable %s", key);

	return 0;
}

static int
module_get(lua_State *l)
{
	MODTYPE **p = (MODTYPE **)luaL_checkudata(l, 1, METANAME);
	const char *key	= luaL_checkstring(l, 2);
	uint64_t value	= 0;

$$
	local count = 0;
	tpl.result= {};
	for _, stmt in pairs(outputs) do
	table.insert(tpl.result,
([[	%sif (!strcmp(key, "%s"))
		value = (*p)->%s;
]]):format(count == 0 and "" or "else ", stmt.name, stmt.name));
		count = count + 1;
	end
$$	else
		luaL_error(l, "unknown variable %s", key);

	lua_pushinteger(l, value);

	return 1;
}

static int
module_eval(lua_State *l)
{
	MODTYPE **p = (MODTYPE **)luaL_checkudata(l, 1, METANAME);

	(*p)->eval();

	return 0;
}

static const luaL_Reg module_methods[] = {
	{ "__gc", module_gc },
	{ "set", module_set },
	{ "get", module_get},
	{ "eval", module_eval },
	{ NULL, NULL },
};

static int
module_new(lua_State *l)
{
	MODTYPE **p = (MODTYPE **)lua_newuserdatauv(l, sizeof(MODTYPE *), 0);

	*p = new MODTYPE;
	luaL_setmetatable(l, METANAME);

	return 1;
}

static const luaL_Reg packageMethods[] = {
	{ "new", module_new },
	{ NULL, NULL },
};

extern "C" int
$$ tpl.result = ("luaopen_V%s"):format(name) $$
(lua_State *l)
{
	luaL_newmetatable(l, METANAME);

	lua_pushvalue(l, -1);
	lua_setfield(l, -2, "__index");

	luaL_setfuncs(l, module_methods, 0);

	luaL_newlib(l, packageMethods);

	return 1;
}
