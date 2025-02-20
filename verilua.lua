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
local cLuaPkgname	= "lua5.4";

local function
verilatorOutputFile(modname, ext)
	return ("%s/V%s.%s"):format(cObjDir, modname, ext);
end

local function
veriluaGlueFile(modname, ext)
	return ("%s/V%s-glue.%s"):format(cObjDir, modname, ext);
end

local function
doGenerate(modname)
	local jsonNetList = assert(io.open(verilatorOutputFile(modname,
							       "tree.json"),
					   'r')):read('a');
	local netlist = assert(cjson.decode(jsonNetList));
	local res = assert(lmerge.resource("glue.template.cpp"));
	local tpl = template.Template(res);
	local output = assert(io.open(veriluaGlueFile(modname, "cpp"), 'w'));

	output:write(tpl:replace({
					mod	= netlist.modulesp[1],
					name	= modname
				 }));
end

local function
runStep(fmt, ...)
	local cmd = string.format(fmt, ...);
	local ok = os.execute(cmd);

	if not ok then
		io.stderr:write(('='):rep(40) .. '\n');
		io.stderr:write(("failed to run command: %s\n"):format(cmd));
		os.execute(1);
	end
end

local function
runPureStepWithRes(fmt, ...)
	runStep(fmt .. " >/dev/null 2>/dev/null", ...);

	local cmd = string.format(fmt, ...);
	return io.popen(cmd, 'r'):read('a');
end

local function
doBuildPkg(modname)
	local luaCFLAGS = runPureStepWithRes("pkg-config --cflags %s",
					     cLuaPkgname);
	local luaLDFLAGS = runPureStepWithRes("pkg-config --cflags %s",
					      cLuaPkgname);

	-- Generate netlist
	runStep('verilator --json-only %s', modname .. ".v");

	-- Generate glue
	doGenerate(modname);

	-- Compile
	runStep('verilator --cc --build -CFLAGS "-fPIC %s" %s %s',
		luaCFLAGS, veriluaGlueFile(modname, "cpp"), modname);

	-- Link
	runStep('c++ -shared %s %s/libV%s.a %s/libverilated.a ' ..
		'-o %s %s',
		veriluaGlueFile(modname, "o"), cObjDir, modname, cObjDir,
		verilatorOutputFile(modname, "so"), luaLDFLAGS);
end

local commands = {
	["generate"] = {
				func	= doGenerate,
		       },
	["buildpkg"] = {
				func	= doBuildPkg,
		       },
};

local modname = assert(arg[2]);
assert(commands[assert(arg[1])]).func(modname);
