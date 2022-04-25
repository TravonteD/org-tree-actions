(local OrgMappings (require :orgmode.org.mappings))
(local Section (require :orgmode.parser.section))
(local ts_utils (require :nvim-treesitter.ts_utils))

(fn find-headline [node]
  (if
    (= (node:type) :headline) node
    (= (node:type) :section) (. (ts_utils.get_named_children node) 1)
    (when (node:parent)
      (find-headline (node:parent)))))

(fn org-closest-headline []
  (: (vim.treesitter.get_parser 0 :org) :parse)
  (find-headline (ts_utils.get_node_at_cursor (vim.fn.win_getid))))

(fn set-text [node text]
  (let [(sr sc er ec) (node:range)]
    (if (= 0 (length text))
      (vim.api.nvim_buf_set_text 1 sr sc er (+ ec 1) [text])
      (vim.api.nvim_buf_set_text 1 sr sc er ec [text]))))

(fn parse-item [headline pattern]
  (-> (vim.tbl_filter (fn [node]
                        (local text (or (vim.treesitter.query.get_node_text node 0) ""))
                        (when (string.match text pattern)
                          node))
                      (-> headline
                          (: :field :item)
                          (. 1)
                          (ts_utils.get_named_children)))
      (. 1)))

(fn get-priority [headline]
  (parse-item headline "%[#%w%]"))
(fn get-todo [headline]
  (let [config (require :orgmode.config)
        keywords config.todo_keywords.ALL]
    (-> (icollect [_ word (ipairs keywords)]
              (let [todo (parse-item headline (string.gsub word "-" "%%-"))]
                (when todo
                  todo)))
        (. 1))))
(fn get-stars [headline]
  (-> headline
      (: :field :stars)
      (. 1)))

(fn set-priority [headline priority]
  (let [current-priority (get-priority headline)]
    (if current-priority
      (set-text current-priority (if (= priority "") "" (string.format "[#%s]" priority)))
      (let [todo (get-todo headline)]
        (if todo
          (let [text (vim.treesitter.query.get_node_text todo 1)]
            (set-text todo (string.format "%s [#%s]" text priority)))
          (let [stars (get-stars headline)
                text (vim.treesitter.query.get_node_text stars 0)]
            (set-text stars (string.format "%s [#%s]" text priority))))))))

(fn set-todo [headline keyword]
  (let [current-todo (get-todo headline)]
    (if current-todo
      (set-text current-todo keyword)
      (let [stars (get-stars headline)
            text (vim.treesitter.query.get_node_text stars 0)]
        (set-text stars (string.format "%s %s" text keyword))))))

(tset OrgMappings :set_priority
      (fn [_ direction]
        (let [PriorityState (require :orgmode.objects.priority_state)
              headline (org-closest-headline)
              priority (get-priority headline)
              current-priority (if priority (string.match (vim.treesitter.query.get_node_text priority 0) "%[#(%w+)%]") "")
              priority_state (PriorityState:new current-priority)
              new_priority (if
                             (= direction :up) (priority_state:increase)
                             (= direction :down) (priority_state:decrease)
                             (priority_state:prompt_user))]
          (set-priority headline new_priority))))

(tset OrgMappings :_change_todo_state
      (fn [_ direction use_fast_access]
        (let [TodoState (require :orgmode.objects.todo_state)
              headline (org-closest-headline)
              keyword (get-todo headline)
              current-keyword (if keyword (vim.treesitter.query.get_node_text keyword 0) "")
              todo_state (TodoState:new {:current_state current-keyword})
              new_state (if
                           (and use_fast_access (todo_state:has_fast_access)) (todo_state:open_fast_access)
                           (= direction :next) (todo_state:get_next)
                           (= direction :prev) (todo_state:get_prev)
                           (= direction :reset) (todo_state:get_todo)
                           false)]
          (set-todo headline (. new_state :value)))))
(tset OrgMappings :_todo_change_state
      (fn [self direction]
        (self:_change_todo_state direction true)))
