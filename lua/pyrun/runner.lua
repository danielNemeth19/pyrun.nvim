---@class Runner
---@field opts pyrun.Opts
---@field config pyrun.Config
---@field lang string
---@field manage_file string
local Runner = {}
Runner.__index = Runner

---@param opts pyrun.Opts
---@param config pyrun.Config
---@return Runner
function Runner:new(opts, config)
  local instance = setmetatable({}, self)
  instance.lang = "python"
  instance.opts = opts
  instance.config = config
  return instance
end

---@param filepath string
function Runner:find_manage_file(filepath)
  local result = vim.fs.find("manage.py", {
    limit = 1,
    upward = true,
    type = "file",
    path = filepath
  })
  local manage_file = result[1]
  self.manage_file = manage_file
end

---@param fp string
---@return string module_path
function Runner:filepath_to_module_name(fp)
  local project_root = vim.fs.dirname(self.manage_file)
  -- to get path of test file relative to project root, without leading "/"
  local relative_path = fp:sub(project_root:len() + 2, fp:len())
  local without_ext = vim.fn.fnamemodify(relative_path, ":r")
  local module_path = without_ext:gsub("/", ".")
  return module_path
end

function Runner:get_module_path()
  local fp = vim.api.nvim_buf_get_name(0)
  self:find_manage_file(fp)
  if not self.manage_file then
    return
  end
  local module_path = self:filepath_to_module_name(fp)
  return module_path
end

---@return integer x_col
---@return integer y_row
function Runner:get_coordinates()
  local center_c = vim.o.columns / 2
  local center_r = vim.o.lines / 2
  local x_col = center_c - (self.opts.window_config.width / 2)
  local y_row = center_r - (self.opts.window_config.height / 2)
  return x_col, y_row
end

---@param opts pyrun.window_config
---@param title_suffix string
---@return integer
---@return integer
function Runner:create_window_and_buffer(opts, title_suffix)
  local col, row = self:get_coordinates()
  local bufnr = vim.api.nvim_create_buf(true, true)
  local title = opts.title_prefix .. title_suffix
  opts = vim.tbl_extend('force', opts, { col = col, row = row, title = title })
  opts.title_prefix = nil
  local win_id = vim.api.nvim_open_win(bufnr, true, opts)
  return bufnr, win_id
end

---@param root_node TSNode
---@param current_line integer
---@param target "class" | "test"
---@return string closest_target
function Runner:_get_closest_target(root_node, current_line, target)
  local targets = {}
  local query_string = ""
  if target == "class" then
    query_string = "(class_definition name: (identifier) @type)"
  elseif target == "test" then
    query_string = "(function_definition name: (identifier) @type)"
  end
  local query = vim.treesitter.query.parse(self.lang, query_string)
  for _, node in query:iter_captures(root_node, 0, 0, current_line) do
    local current_target = vim.treesitter.get_node_text(node, 0)
    table.insert(targets, current_target)
  end
  local closest_target = targets[#targets]
  return closest_target
end

---@param target "class" | "test"
function Runner:get_closest_target(target)
  local parser = vim.treesitter.get_parser(0, nil, { error = false })
  if not parser then
    return
  end
  local tree = parser:parse()[1]
  local root = tree:root()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line, _ = pos[1], pos[2]
  local closest_target = self:_get_closest_target(root, line, target)
  return closest_target
end

function Runner:run_closest_class()
  local module_path = self:get_module_path()
  local class_to_run = self:get_closest_target("class")
  if not class_to_run or class_to_run:sub(1, 4) ~= "Test" then
    vim.api.nvim_echo({ { "No test class above cursor" } }, true, { err = true })
    return
  end
  local class_path = module_path .. "." .. class_to_run
  local command = { self.lang, self.manage_file, "test", class_path }
  local bufnr, win_id = self:create_window_and_buffer(self.opts.window_config, class_to_run)
  self:run_command(bufnr, win_id, command)
end

function Runner:run_closest_test()
  local module_path = self:get_module_path()
  local class_to_run = self:get_closest_target("class")
  if not class_to_run or class_to_run:sub(1, 4) ~= "Test" then
    vim.api.nvim_echo({ { "No test class above cursor" } }, true, { err = true })
    return
  end
  local test_to_run = self:get_closest_target("test")
  if not test_to_run or test_to_run:sub(1, 5) ~= "test_" then
    vim.api.nvim_echo({ { "Method is not a unittest" } }, true, { err = true })
    return
  end
  local test_path = module_path .. "." .. class_to_run .. "." .. test_to_run
  local window_title = class_to_run .. "." .. test_to_run
  local command = { self.lang, self.manage_file, "test", test_path }
  local bufnr, win_id = self:create_window_and_buffer(self.opts.window_config, window_title)
  self:run_command(bufnr, win_id, command)
end

function Runner:run_all()
  local module_path = self:get_module_path()
  if not module_path then
    vim.api.nvim_echo({ { "Not a Django project" } }, true, { err = true })
    return
  end
  local command = { self.lang, self.manage_file, "test", module_path }
  local bufnr, win_id = self:create_window_and_buffer(self.opts.window_config, module_path)
  self:run_command(bufnr, win_id, command)
end

---@param bufnr integer
---@param win_id integer
---@param command table
function Runner:run_command(bufnr, win_id, command)
  vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
    end,
    on_stderr = function(_, data)
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
      for line, row in ipairs(lines) do
        local first_char = string.sub(row, 1, 1)
        if first_char == "." then
          vim.hl.range(
            bufnr,
            self.config.ns_id,
            self.config.color_names.success,
            { line - 1, 0 }, { line - 1, -1 },
            { inclusive = true }
          )
        end
      end
    end,
    stderr_buffered = true,
    on_exit = function()
      vim.keymap.set("n", self.opts.keymaps.close_float, function()
        vim.api.nvim_win_close(win_id, false)
      end, { buffer = bufnr })
    end
  })
end

return Runner
