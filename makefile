LMERGE		?= lmerge

SRCS		:= template.lua verilua.lua

verilua: glue.template.cpp $(SRCS)
	$(LMERGE) -m verilua.lua $(SRCS) -r glue.template.cpp -o $@
