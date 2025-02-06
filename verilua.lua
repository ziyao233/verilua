-- SPDX-License-Identifier: MPL-2.0
--[[
--	verilua
--	/verilua.lua
--	Copyright (c) 2025 Yao Zi.
--]]

local io 		= require "io";
local string		= require "string";

local cjson		= require "cjson";

local template		= require "template";

local cObjDir		= "obj_dir";

local function
verilatorOutputFile(modname, ext)
	return ("%s/V%s.%s"):format(cObjDir, modname, ext);
end

local modname = assert(arg[1]);
local jsonNetList = assert(io.open(verilatorOutputFile(
					arg[1], "tree.json"),
				   'r')):read('a');
local netlist = assert(cjson.decode(jsonNetList));

local tpl = template.Template(assert(lmerge.resource("glue.template.cpp")));

assert(io.open(verilatorOutputFile(modname, "glue.cpp"), 'w')):write(
	tpl:replace({ mod = netlist.modulesp[1], name = modname }));
