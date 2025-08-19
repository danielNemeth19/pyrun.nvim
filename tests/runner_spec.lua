local assert = require("luassert.assert")
-- local mock = require("luassert.mock")
local stub = require("luassert.stub")
local fixtures = require("tests.fixtures")

local function buffer_setup(input, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(bufnr, true, { relative = "editor", width = 10, height = 10, row = 0, col = 0 })
  vim.api.nvim_set_option_value("filetype", filetype, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(input, '\n'))
  return bufnr
end

describe("runner class", function()
  local runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config

  it("can require", function()
    require("pyrun.runner")
  end)
  it("can set manage.py file as field on runner instance", function()
    local find_stub = stub(vim.fs, "find")
    find_stub.returns({ "/home/user/project/manage.py" })
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    local runner_instance = runner:new(default_opts, config)
    runner_instance:find_manage_file(fp)
    assert.equals(runner_instance.manage_file, "/home/user/project/manage.py")
    find_stub:revert()
  end)
  it("can set nil as manage_file field on runner instance", function()
    local find_stub = stub(vim.fs, "find")
    find_stub.returns({})
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    local runner_instance = runner:new(default_opts, config)
    runner_instance:find_manage_file(fp)
    assert.equals(runner_instance.manage_file, nil)
    find_stub:revert()
  end)
  it("can set module path", function()
    local runner_instance = runner:new(default_opts, config)
    runner_instance.manage_file = "/home/user/project/manage.py"
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    local module = runner_instance:set_module_path(fp)
    assert.equals(module, "apps.app.tests.test_file")
  end)
  it("can set module path for special chars too", function()
    local runner_instance = runner:new(default_opts, config)
    runner_instance.manage_file = "/home/user/my-project/manage.py"
    local fp = "/home/user/my-project/apps/app/tests/test_file.py"
    local module = runner_instance:set_module_path(fp)
    assert.equals(module, "apps.app.tests.test_file")
  end)
  it("can calculate top-left coordinate for centered window", function()
    local opts = { window_config = { width = 40, height = 20 } }
    local runner_instance = runner:new(opts, config)
    vim.o.columns = 80
    vim.o.lines = 40
    local x, y = runner_instance:get_coordinates()
    assert.equals(x, 20)
    assert.equals(y, 10)
  end)
  it("can create window and buffer", function()
    local opts = vim.tbl_deep_extend("force", {}, default_opts, { window_config = { width = 40, height = 20 } })
    local runner_instance = runner:new(opts, config)
    local win_opts = opts.window_config
    local create_buf_stub = stub(vim.api, "nvim_create_buf")
    create_buf_stub.returns(10)
    local open_win_stub = stub(vim.api, "nvim_open_win")
    runner_instance:create_window_and_buffer(win_opts, "test")
    local expected_opts = {
      border = win_opts['border'],
      col = 20,
      row = 10,
      width = 40,
      height = 20,
      title = win_opts['title_prefix'] .. "test",
      relative = "win",
      style = "minimal"
    }
    assert.stub(open_win_stub).was_called_with(10, true, expected_opts)
  end)
  it("returns nil in case parser cannot be created", function()
    local parser_stub = stub(vim.treesitter, "get_parser")
    parser_stub.returns(nil)
    local runner_instance = runner:new(default_opts, config)
    assert.equals(runner_instance:get_closest_class(), nil)
  end)
  it("can find closest class", function()
    local parser_stub = stub(vim.treesitter, "get_parser")
    parser_stub.returns(fixtures.get_parser())
    local runner_instance = runner:new(default_opts, config)
    runner_instance:get_closest_class()
  end)
end)
