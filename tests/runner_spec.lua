local assert = require("luassert.assert")
local stub = require("luassert.stub")
local match = require("luassert.match")
local fixtures = require("tests.fixtures")

describe("runner class", function()
  local runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config
  local runner_instance = runner:new(default_opts, config)
  local stubs = {}

  before_each(function()
    stubs.fs_find = stub(vim.fs, "find")
    stubs.nvim_create_buf = stub(vim.api, "nvim_create_buf")
    stubs.nvim_open_win = stub(vim.api, "nvim_open_win")
    stubs.get_parser = stub(vim.treesitter, "get_parser")
    stubs.nvim_win_get_cursor = stub(vim.api, "nvim_win_get_cursor")
    stubs.nvim_buf_get_name = stub(vim.api, "nvim_buf_get_name")
  end)
  after_each(function()
    for _, s in pairs(stubs) do
      if s and s.revert then
        s:revert()
      end
    end
  end)

  it("can require", function()
    require("pyrun.runner")
  end)
  it("can set manage.py file as field on runner instance", function()
    stubs.fs_find.returns({ "/home/user/project/manage.py" })
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    runner_instance:find_manage_file(fp)
    assert.equals(runner_instance.manage_file, "/home/user/project/manage.py")
  end)
  it("can set nil as manage_file field on runner instance", function()
    stubs.fs_find.returns({})
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    runner_instance:find_manage_file(fp)
    assert.equals(runner_instance.manage_file, nil)
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
    stubs.nvim_create_buf.returns(10)
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
    assert.stub(stubs.nvim_open_win).was_called_with(10, true, expected_opts)
  end)
  it("returns nil in case parser cannot be created", function()
    stubs.get_parser.returns(nil)
    assert.equals(runner_instance:get_closest_class(), nil)
  end)
  it("returns nil if there is no test class above cursor", function()
    --- test needs buffer and window created,
    --- so mocks need to be reverted before after_each
    stubs.nvim_open_win:revert()
    stubs.nvim_create_buf:revert()
    local bufnr, win_id, parser = fixtures.get_parser_for_ts_node()
    stubs.get_parser.returns(parser)
    stubs.nvim_win_get_cursor.returns({ 1, 0 })
    local class_to_run = runner_instance:get_closest_class()
    assert.equals(class_to_run, nil)
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can find closest class", function()
    --- test needs buffer and window created,
    --- so mocks need to be reverted before after_each
    stubs.nvim_open_win:revert()
    stubs.nvim_create_buf:revert()
    stubs.get_parser:revert()

    local bufnr, win_id, parser = fixtures.get_parser_for_ts_node()
    local expected_classes = {
      { line = 8,  name = "TestClassFromLine8" },
      { line = 20, name = "TestClassFromLine20" },
      { line = 28, name = "TestClassFromLine28" }
    }

    for _, class_info in pairs(expected_classes) do
      stubs.nvim_win_get_cursor.returns({ class_info.line + 2, 1 })
      local class_to_run = runner_instance:get_closest_class()
      assert.equals(class_to_run, class_info.name)
    end
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can run all tests", function()
    stubs.nvim_buf_get_name.returns("/home/user/project/apps/app/tests/test_file.py")
    stubs.fs_find.returns({ "/home/user/project/manage.py" })
    local create_window_and_buffer_stub = stub(runner, "create_window_and_buffer")
    create_window_and_buffer_stub.returns(1, 20)
    local run_command_stub = stub(runner, "run_command")
    runner_instance:run_all()
    local expected_command = { "python", "/home/user/project/manage.py", "test", "apps.app.tests.test_file" }
    local call_args = run_command_stub.calls[1].vals
    assert.are.same(1, call_args[2])
    assert.are.same(20, call_args[3])
    assert.are.same(expected_command, call_args[4])
    create_window_and_buffer_stub:revert()
    run_command_stub:revert()
  end)
end)
