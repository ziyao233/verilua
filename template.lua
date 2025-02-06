-- SPDX-License-Identifier: MPL-2.0
--[[
--	verilua
--	Template.lua
--	Copyright (c) 2021-2024 Yao Zi. All rights reserved.
--]]

local string	= require("string");
local math	= require("math");
local io	= require("io");

local templateProtoType = {};
local templateMeta = { __index = templateProtoType };

local Template = function(src)
	return setmetatable({ src = src }, templateMeta);
end

local function
getLineNumber(src, pos)
	local line = 1;
	for _ in src:sub(1, pos):gmatch('\n') do
		line = line + 1;
	end
	return line;
end

local function
reportError(src, pos, msg, ...)
	error(("line %d in template: %s"):
	      format(getLineNumber(src, pos), msg:format(...)));
end

local function
executeCode(src, pos, env, code)
	env.tpl.result = {};

	local f, msg = load(code, "Code in template", "t", env);
	if not f then
		reportError(src, pos,
			    "failed to compile code:\n%s", msg);
	end

	local ok, msg = pcall(f);
	if not ok then
		reportError(src, pos,
			    "failed to evaluate code:\n%s", msg);
	end

	local result = env.tpl.result;

	return type(result) == "table" and table.concat(result) or
					   tostring(result);
end

templateProtoType.replace = function(self, arg)
	local env = {
			tpl	= {
					arg	= arg,
				  },
		    };
	setmetatable(env, { __index = _G });

	local res = string.gsub(self.src,"$(=*)()$(.-)$%1%$",
				function(_equals, pos, code)
					return executeCode(self.src, pos, env,
							   code);
				end);
	return res;
end

return { Template = Template };
