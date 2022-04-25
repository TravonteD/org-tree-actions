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
                        (local text (or (vim.treesitter.query.get_node_text node 1) ""))
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
  (parse-item headline "TODO"))
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
                text (vim.treesitter.query.get_node_text stars 1)]
            (set-text stars (string.format "%s [#%s]" text priority))))))))

(tset Section :set_priority #(set-priority (org-closest-headline) $2))
