local assert = require("luassert.assert")
local stub = require("luassert.stub")
local fixtures = require("tests.fixtures")

describe("Runner can set module path", function()
  local Runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config
  local runner = Runner:new(default_opts, config)
  local stubs = {}

  before_each(function()
    stubs.fs_find = stub(vim.fs, "find")
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
    runner:find_manage_file(fp)
    assert.equals(runner.manage_file, "/home/user/project/manage.py")
  end)
  it("can set nil as manage_file field on runner instance", function()
    stubs.fs_find.returns({})
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    runner:find_manage_file(fp)
    assert.equals(runner.manage_file, nil)
  end)
  it("can convert filename to module name", function()
    runner.manage_file = "/home/user/project/manage.py"
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    local module = runner:filepath_to_module_name(fp)
    assert.equals(module, "apps.app.tests.test_file")
  end)
  it("can convert filename to module path for special chars too", function()
    runner.manage_file = "/home/user/my-project/manage.py"
    local fp = "/home/user/my-project/apps/app/tests/test_file.py"
    local module = runner:filepath_to_module_name(fp)
    assert.equals(module, "apps.app.tests.test_file")
  end)
  it("can get module path", function()
    local bufnr, win_id = fixtures.setup_opened_buffer()
    vim.api.nvim_buf_set_name(bufnr, "/home/user/project/apps/app/tests/test_file.py")
    stubs.fs_find.returns({ "/home/user/project/manage.py" })
    local module_path = runner:get_module_path()
    assert.equals(module_path, "apps.app.tests.test_file")
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can return none if no manage.py file can be found", function()
    local bufnr, win_id = fixtures.setup_opened_buffer()
    vim.api.nvim_buf_set_name(bufnr, "/home/user/project/apps/app/tests/test_file.py")
    stubs.fs_find.returns({ nil })
    assert.is_nil(runner:get_module_path())
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

describe("Runner can manage buffer and floating window", function()
  local Runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config
  local stubs = {}

  before_each(function()
    stubs.nvim_create_buf = stub(vim.api, "nvim_create_buf")
    stubs.nvim_open_win = stub(vim.api, "nvim_open_win")
  end)
  after_each(function()
    for _, s in pairs(stubs) do
      if s and s.revert then
        s:revert()
      end
    end
  end)

  it("can calculate top-left coordinate for centered window", function()
    local opts = { window_config = { width = 40, height = 20 } }
    local custom_runner = Runner:new(opts, config)
    vim.o.columns = 80
    vim.o.lines = 40
    local x, y = custom_runner:get_coordinates()
    assert.equals(x, 20)
    assert.equals(y, 10)
  end)
  it("can create window and buffer", function()
    local opts = vim.tbl_deep_extend("force", {}, default_opts, { window_config = { width = 40, height = 20 } })
    local custom_runner = Runner:new(opts, config)
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
end)

describe("Runner can find closest target", function()
  local Runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config
  local runner = Runner:new(default_opts, config)
  local stubs = {}

  before_each(function()
    stubs.nvim_win_get_cursor = stub(vim.api, "nvim_win_get_cursor")
  end)
  after_each(function()
    for _, s in pairs(stubs) do
      if s and s.revert then
        s:revert()
      end
    end
  end)

  it("returns nil in case parser cannot be created", function()
    local bufnr, win_id = fixtures.setup_opened_buffer({ invalid = true })
    assert.is_nil(runner:get_closest_target("class"))
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("returns nil if there is no test class above cursor", function()
    local bufnr, win_id = fixtures.setup_opened_buffer()
    stubs.nvim_win_get_cursor.returns({ 1, 0 })
    local class_to_run = runner:get_closest_target("class")
    assert.equals(class_to_run, nil)
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("returns nil class found in not a test class", function()
    local bufnr, win_id = fixtures.setup_opened_buffer()
    stubs.nvim_win_get_cursor.returns({ 46, 11 })
    local class_to_run = runner:get_closest_target("class")
    assert.equals(class_to_run, "AbstractTestClassFromLine44")
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can find closest class", function()
    local bufnr, win_id = fixtures.setup_opened_buffer()
    local expected_classes = {
      { line = 8,  name = "TestClassFromLine8" },
      { line = 20, name = "TestClassFromLine20" },
      { line = 36, name = "TestClassFromLine36" }
    }

    for _, class_info in pairs(expected_classes) do
      stubs.nvim_win_get_cursor.returns({ class_info.line + 2, 1 })
      local class_to_run = runner:get_closest_target("class")
      assert.equals(class_to_run, class_info.name)
    end
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can find closest test", function()
    local bufnr, win_id = fixtures.setup_opened_buffer()
    local expected_tests = {
      { line = 9,  name = "test_getting_urls_response_in_json" },
      { line = 14, name = "test_get_urls_returns_all_urls" }
    }
    for _, test_info in pairs(expected_tests) do
      stubs.nvim_win_get_cursor.returns({ test_info.line + 1, 1 })
      local test_to_run = runner:get_closest_target("test")
      assert.equals(test_info.name, test_to_run)
    end
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

describe("Runner can run tests", function()
  local Runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config
  local runner
  local stubs = {}

  before_each(function()
    runner = Runner:new(default_opts, config)
    stubs.get_module_path = stub(runner, "get_module_path")
    stubs.create_window_and_buffer = stub(runner, "create_window_and_buffer")
    stubs.run_command = stub(runner, "run_command")
    stubs.get_closest_target = stub(runner, "get_closest_target")
    stubs.nvim_echo = stub(vim.api, "nvim_echo")
  end)
  after_each(function()
    for _, s in pairs(stubs) do
      if s and s.revert then
        s:revert()
      end
    end
  end)
  it("can run closest class", function()
    stubs.get_module_path.returns("apps.app.tests.test_file")
    stubs.get_closest_target.returns("TestClasstoRun")
    runner.manage_file = "/home/user/project/manage.py"
    stubs.create_window_and_buffer.returns(1, 20)
    runner:run_closest_class()
    local expected_command = {
      "python",
      "/home/user/project/manage.py",
      "test",
      "apps.app.tests.test_file.TestClasstoRun"
    }
    local call_args = stubs.run_command.calls[1].vals
    assert.are.same(1, call_args[2])
    assert.are.same(20, call_args[3])
    assert.are.same(expected_command, call_args[4])
  end)
  it("can log message if there's no class above cursor to run", function()
    stubs.get_module_path.returns(nil)
    stubs.get_closest_target.returns(nil)
    assert.is_nil(runner:run_closest_class())
    assert.stub(stubs.nvim_echo).was_called_with({ { "No test class above cursor" } }, true, { err = true })
  end)
  it("can log message if class found is not a test class", function()
    stubs.get_module_path.returns(nil)
    stubs.get_closest_target.returns("AbstractTestClass")
    assert.is_nil(runner:run_closest_class())
    assert.stub(stubs.nvim_echo).was_called_with({ { "No test class above cursor" } }, true, { err = true })
  end)
  it("can run closest test", function()
    stubs.get_module_path.returns("apps.app.tests.test_file")
    stubs.get_closest_target.invokes(function(_, arg)
      if arg == "class" then
        return "TestClasstoRun"
      end
      if arg == "test" then
        return "test_function"
      end
    end)
    runner.manage_file = "/home/user/project/manage.py"
    stubs.create_window_and_buffer.returns(1, 20)
    runner:run_closest_test()
    local expected_command = {
      "python",
      "/home/user/project/manage.py",
      "test",
      "apps.app.tests.test_file.TestClasstoRun.test_function"
    }
    local call_args = stubs.run_command.calls[1].vals
    assert.are.same(1, call_args[2])
    assert.are.same(20, call_args[3])
    assert.are.same(expected_command, call_args[4])
  end)
  it("can log message if no test class above test", function()
    stubs.get_module_path.returns(nil)
    stubs.get_closest_target.returns("AbstractTestClass")
    assert.is_nil(runner:run_closest_test())
    assert.stub(stubs.nvim_echo).was_called_with({ { "No test class above cursor" } }, true, { err = true })
  end)
  it("can log message if no method is not a unittest", function()
    stubs.get_module_path.returns(nil)
    stubs.get_closest_target.invokes(function(_, arg)
      if arg == "class" then
        return "TestClasstoRun"
      end
      if arg == "test" then
        return "_helper_method"
      end
    end)
    assert.is_nil(runner:run_closest_test())
    assert.stub(stubs.nvim_echo).was_called_with({ { "Method is not a unittest" } }, true, { err = true })
  end)
  it("can run all tests", function()
    stubs.get_module_path.returns("apps.app.tests.test_file")
    runner.manage_file = "/home/user/project/manage.py"
    stubs.create_window_and_buffer.returns(1, 20)
    runner:run_all()
    local expected_command = { "python", "/home/user/project/manage.py", "test", "apps.app.tests.test_file" }
    local call_args = stubs.run_command.calls[1].vals
    assert.are.same(1, call_args[2])
    assert.are.same(20, call_args[3])
    assert.are.same(expected_command, call_args[4])
  end)
  it("can log if run all is called on a non-django project", function()
    stubs.get_module_path.returns(nil)
    assert.is_nil(runner:run_all())
    assert.stub(stubs.nvim_echo).was_called_with({ { "Not a Django project" } }, true, { err = true })
  end)
end)
