.PHONY: test
.SILENT: test clean
test: lua/org-tree-actions.lua test/org-tree-actions-test.lua
	nvim --headless +"luafile test/org-tree-actions-test.lua" +'q!'

lua/org-tree-actions.lua: fnl/org-tree-actions.fnl
	fennel --compile $< > $@

test/org-tree-actions-test.lua: test/org-tree-actions-test.fnl
	fennel --compile $< > $@

clean: test.org
	rm $<
