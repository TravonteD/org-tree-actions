(require :org-tree-actions)
(fn asserteq [actual expected message]
  (when (not (= actual expected))
    (print "FAIL" (string.format "%s: %s, %s" message (vim.inspect expected) (vim.inspect actual)))))
(fn setl [lines]
  (vim.api.nvim_buf_set_lines 0 0 -1 false lines))
(fn getl []
  (vim.api.nvim_buf_get_lines 0 0 -1 false))
(fn reset []
  (setl [""]))

(vim.cmd "edit test.org")

;; Priority Test
(setl ["* test"])
(vim.cmd "norm cir")
(asserteq (. (getl) 1) "* [#A] test" "Priority: Adds a priority from nothing")
(vim.cmd "norm cir")
(asserteq (. (getl) 1) "* [#B] test" "Priority: Moves to the next priority")
(vim.cmd "norm cir")
(vim.cmd "norm cir")
(asserteq (. (getl) 1) "* test" "Priority: Removes the priority properly")
(setl ["* TODO test"])
(vim.cmd "norm cir")
(asserteq (. (getl) 1) "* TODO [#A] test" "Priority with keyword: Adds a priority from nothing")
(vim.cmd "norm cir")
(asserteq (. (getl) 1) "* TODO [#B] test" "Priority with keyword: Moves to the next priority")
(vim.cmd "norm cir")
(vim.cmd "norm cir")
(asserteq (. (getl) 1) "* TODO test" "Priority with keyword: Removes the priority properly")
(reset)

;; Keyword Swap Test
(local config (require :orgmode.config))
(tset config :todo_keywords :ALL [:TODO :STARTED :WONT-DO])
(setl ["* test"])
(vim.cmd "norm cit")
(asserteq (. (getl) 1) "* TODO test" "Keyword: adds a keyword from nothing")
(vim.cmd "norm cit")
(asserteq (. (getl) 1) "* STARTED test" "Keyword: Moves to the next keyword")
(vim.cmd "norm cit")
(asserteq (. (getl) 1) "* WONT-DO test" "Keyword: Moves to the next keyword")
(vim.cmd "norm cit")
(asserteq (. (getl) 1) "* test" "Keyword: Removes the keyword cleanly")

;; Logbook Test
(local config (require :orgmode.config))
(tset config :todo_keywords :ALL [:TODO :DONE])
(setl ["* TODO test"])
(vim.cmd "norm cit")
(local timestamp (vim.fn.strftime "%Y-%m-%d %a %H:%M"))
(asserteq (. (getl) 1) "* DONE test" "org-log-done")
(asserteq (. (getl) 2) (string.format "CLOSED: [%s]" timestamp) "org-log-done")
