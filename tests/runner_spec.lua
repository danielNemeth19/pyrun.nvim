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
    stubs.nvim_echo = stub(vim.api, "nvim_echo")
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
  it("can return false if buffer is not a test file and logs message", function()
    local bufnr, win_id = fixtures.setup_opened_buffer()
    vim.api.nvim_buf_set_name(bufnr, "/home/user/project/apps/app/tests/helper.py")
    assert.equals(runner:get_module_path(), false)
    assert.stub(stubs.nvim_echo).was_called_with({ { "Not a test file" } }, true, { err = false })
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can return false if no manage.py file can be found and logs message", function()
    local bufnr, win_id = fixtures.setup_opened_buffer()
    vim.api.nvim_buf_set_name(bufnr, "/home/user/project/apps/app/tests/test_file.py")
    stubs.fs_find.returns({ nil })
    assert.equals(runner:get_module_path(), false)
    assert.stub(stubs.nvim_echo).was_called_with({ { "Not a Django project" } }, true, { err = false })
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
      relative = "editor",
      style = "minimal"
    }
    assert.stub(stubs.nvim_open_win).was_called_with(10, true, expected_opts)
  end)
end)

describe("Finding test targets", function()
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

describe("Running tests", function()
  local Runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config
  local runner = Runner:new(default_opts, config)
  local stubs = {}
  local module_path = "apps.app.tests.test_file"
  local bufnr, win_id

  before_each(function()
    stubs.get_module_path = stub(runner, "get_module_path")
    stubs.nvim_win_get_cursor = stub(vim.api, "nvim_win_get_cursor")
    stubs.create_window_and_buffer = stub(runner, "create_window_and_buffer")
    stubs.run_command = stub(runner, "run_command")
    stubs.nvim_echo = stub(vim.api, "nvim_echo")
    runner.manage_file = "/home/user/project/manage.py"
    bufnr, win_id = fixtures.setup_opened_buffer()
  end)
  after_each(function()
    for _, s in pairs(stubs) do
      if s and s.revert then
        s:revert()
      end
    end
    vim.api.nvim_win_close(win_id, true)
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can run closest class", function()
    stubs.get_module_path.returns(module_path)
    stubs.nvim_win_get_cursor.returns({ 10, 4 })
    stubs.create_window_and_buffer.returns(1, 20)
    local expected_class = "TestClassFromLine8"
    local expected_command = {
      "python",
      runner.manage_file,
      "test",
      module_path .. "." .. expected_class
    }
    runner:run_closest_class()
    local call_args = stubs.run_command.calls[1].vals
    assert.are.same(1, call_args[2])
    assert.are.same(20, call_args[3])
    assert.are.same(expected_command, call_args[4])
  end)
  it("can log message if there's no class above cursor to run", function()
    stubs.nvim_win_get_cursor.returns({ 7, 0 })
    assert.is_nil(runner:run_closest_class())
    assert.stub(stubs.nvim_echo).was_called_with({ { "No test class above cursor" } }, true, { err = true })
  end)
  it("can log message if class found is not a test class", function()
    stubs.nvim_win_get_cursor.returns({ 47, 0 })
    assert.is_nil(runner:run_closest_class())
    assert.stub(stubs.nvim_echo).was_called_with({ { "No test class above cursor" } }, true, { err = true })
  end)
  it("can run closest test", function()
    stubs.get_module_path.returns(module_path)
    stubs.nvim_win_get_cursor.returns({ 16, 11 })
    stubs.create_window_and_buffer.returns(1, 20)
    local expected_class = "TestClassFromLine8"
    local expected_test = "test_get_urls_returns_all_urls"
    local expected_command = {
      "python",
      runner.manage_file,
      "test",
      module_path .. "." .. expected_class .. "." .. expected_test
    }
    runner:run_closest_test()
    local call_args = stubs.run_command.calls[1].vals
    assert.are.same(1, call_args[2])
    assert.are.same(20, call_args[3])
    assert.are.same(expected_command, call_args[4])
  end)
  it("can log message if no test class above test", function()
    stubs.get_module_path.returns(module_path)
    stubs.nvim_win_get_cursor.returns({ 49, 10 })
    assert.is_nil(runner:run_closest_test())
    assert.stub(stubs.nvim_echo).was_called_with({ { "No test class above cursor" } }, true, { err = true })
  end)
  it("can log message if method is not a unittest", function()
    stubs.get_module_path.returns(module_path)
    stubs.nvim_win_get_cursor.returns({ 31, 10 })
    assert.is_nil(runner:run_closest_test())
    assert.stub(stubs.nvim_echo).was_called_with({ { "Target is not a unittest" } }, true, { err = true })
  end)
  it("can run all tests", function()
    vim.api.nvim_buf_set_name(bufnr, "/home/user/project/apps/app/tests/test_file.py")
    stubs.get_module_path.returns(module_path)
    stubs.nvim_win_get_cursor.returns({ 1, 10 })
    stubs.create_window_and_buffer.returns(1, 20)
    runner:run_all()
    local expected_command = {
      "python",
      runner.manage_file,
      "test",
      module_path
    }
    local call_args = stubs.run_command.calls[1].vals
    assert.are.same(1, call_args[2])
    assert.are.same(20, call_args[3])
    assert.are.same(expected_command, call_args[4])
  end)
  it("can return with no-op if module_path returns false", function()
    stubs.get_module_path.returns(false)
    assert.is_nil(runner:run_all())
  end)
end)

describe("appending lines", function()
  local Runner = require("pyrun.runner")
  local default_opts = require("pyrun.config").opts
  local config = require("pyrun.config").config
  local success_color = config.color_names.success
  local failure_color = config.color_names.failure

  it("can add test result chars without endlines", function()
    local runner = Runner:new(default_opts, config)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local current_lines = {
      "Creating test database", "Found 5 test(s).", ""
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, current_lines)
    for _ = 1, 5 do
      runner:append_and_hl_char(bufnr, ".")
    end
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "Run 5 tests" })
    local test_result = vim.api.nvim_buf_get_lines(bufnr, 2, 3, false)
    assert.are.same(test_result, {"....."})
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can add failure chars without endlines", function()
    local runner = Runner:new(default_opts, config)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local current_lines = {
      "Creating test database", "Found 4 test(s).", ""
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, current_lines)
    runner:append_and_hl_char(bufnr, "F")
    runner:append_and_hl_char(bufnr, ".")
    runner:append_and_hl_char(bufnr, "F")
    runner:append_and_hl_char(bufnr, ".")

    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "Run 4 tests" })
    local test_result = vim.api.nvim_buf_get_lines(bufnr, 2, 3, false)
    assert.are.same(test_result, {"F.F."})
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can add error chars without endlines", function()
    local runner = Runner:new(default_opts, config)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local current_lines = {
      "Creating test database", "Found 4 test(s).", ""
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, current_lines)
    runner:append_and_hl_char(bufnr, "E")
    runner:append_and_hl_char(bufnr, ".")
    runner:append_and_hl_char(bufnr, ".")
    runner:append_and_hl_char(bufnr, "E")

    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "Run 4 tests" })
    local test_result = vim.api.nvim_buf_get_lines(bufnr, 2, 3, false)
    assert.are.same(test_result, {"E..E"})
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
  it("can update highlight groups based on test results", function()
    local runner = Runner:new(default_opts, config)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local current_lines = {
      "Creating test database", "Found 7 test(s).", ""
    }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, current_lines)
    runner:append_and_hl_char(bufnr, ".")
    runner:append_and_hl_char(bufnr, ".")
    runner:append_and_hl_char(bufnr, "F")
    runner:append_and_hl_char(bufnr, "F")
    runner:append_and_hl_char(bufnr, ".")
    runner:append_and_hl_char(bufnr, ".")
    runner:append_and_hl_char(bufnr, "F")

    assert.are.same(runner.hl_map[1], {start_pos = 0, end_pos = 2, color = success_color})
    assert.are.same(runner.hl_map[2], {start_pos = 2, end_pos = 4, color = failure_color})
    assert.are.same(runner.hl_map[3], {start_pos = 4, end_pos = 6, color = success_color})
    assert.are.same(runner.hl_map[4], {start_pos = 6, end_pos = 7, color = failure_color})
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end)
end)

