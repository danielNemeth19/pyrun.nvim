local assert = require("luassert.assert")
local stub = require("luassert.stub")
local fixtures = require("tests.fixtures")

describe("runner class", function()
  local runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config
  local runner_instance = runner:new(default_opts, config)

  it("can require", function()
    require("pyrun.runner")
  end)
  it("can set manage.py file as field on runner instance", function()
    local find_stub = stub(vim.fs, "find")
    find_stub.returns({ "/home/user/project/manage.py" })
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    runner_instance:find_manage_file(fp)
    assert.equals(runner_instance.manage_file, "/home/user/project/manage.py")
    find_stub:revert()
  end)
  it("can set nil as manage_file field on runner instance", function()
    local find_stub = stub(vim.fs, "find")
    find_stub.returns({})
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    runner_instance:find_manage_file(fp)
    assert.equals(runner_instance.manage_file, nil)
    find_stub:revert()
  end)
  it("can set module path", function()
    runner_instance.manage_file = "/home/user/project/manage.py"
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    local module = runner_instance:set_module_path(fp)
    assert.equals(module, "apps.app.tests.test_file")
  end)
  it("can set module path for special chars too", function()
    runner_instance.manage_file = "/home/user/my-project/manage.py"
    local fp = "/home/user/my-project/apps/app/tests/test_file.py"
    local module = runner_instance:set_module_path(fp)
    assert.equals(module, "apps.app.tests.test_file")
  end)
  it("can calculate top-left coordinate for centered window", function()
    local opts = { window_config = { width = 40, height = 20 } }
    local custom_runner = runner:new(opts, config)
    vim.o.columns = 80
    vim.o.lines = 40
    local x, y = custom_runner:get_coordinates()
    assert.equals(x, 20)
    assert.equals(y, 10)
  end)
  it("can create window and buffer", function()
    local opts = vim.tbl_deep_extend("force", {}, default_opts, { window_config = { width = 40, height = 20 } })
    local custom_runner = runner:new(opts, config)
    local win_opts = opts.window_config
    local create_buf_stub = stub(vim.api, "nvim_create_buf")
    create_buf_stub.returns(10)
    local open_win_stub = stub(vim.api, "nvim_open_win")
    custom_runner:create_window_and_buffer(win_opts, "test")
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
    create_buf_stub:revert()
    open_win_stub:revert()
  end)
  it("returns nil in case parser cannot be created", function()
    local parser_stub = stub(vim.treesitter, "get_parser")
    parser_stub.returns(nil)
    assert.equals(runner_instance:get_closest_class(), nil)
    parser_stub:revert()
  end)
  it("returns nil if there is no test class above cursor", function ()
    local bufnr, win_id, parser = fixtures.get_parser_for_ts_node()
    local parser_stub = stub(vim.treesitter, "get_parser")
    parser_stub.returns(parser)
    local set_cursor_stub = stub(vim.api, "nvim_win_get_cursor")
    set_cursor_stub.returns({1, 0})
    local class_to_run = runner_instance:get_closest_class()
    assert.equals(class_to_run, nil)
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    parser_stub:revert()
    set_cursor_stub:revert()
  end)
  it("can find closest class", function()
    local bufnr, win_id, parser = fixtures.get_parser_for_ts_node()
    local parser_stub = stub(vim.treesitter, "get_parser")
    parser_stub.returns(parser)
    local set_cursor_stub = stub(vim.api, "nvim_win_get_cursor")

    local expected_classes = {
      { line = 8, name = "TestClassFromLine8" },
      { line = 20, name = "TestClassFromLine20" },
      { line = 28, name = "TestClassFromLine28" }
    }

    for _, class_info in pairs(expected_classes) do
      set_cursor_stub.returns({class_info.line + 2, 1})
      local class_to_run = runner_instance:get_closest_class()
      assert.equals(class_to_run, class_info.name)
    end
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    parser_stub:revert()
    set_cursor_stub:revert()
  end)
end)
