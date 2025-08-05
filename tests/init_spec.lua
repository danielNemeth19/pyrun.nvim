local assert = require("luassert.assert")

describe("pyrun-init", function()
  local plugin = require("pyrun")
  it("can require", function()
    require("pyrun")
  end)
  it("can be configured with default options", function ()
    local default_opts = require("pyrun.config").default_opts
    plugin.setup()
    assert.same(default_opts, plugin.options)
  end)
  it("can be configured with custom options", function ()
    local default_win_opts = require("pyrun.config").default_opts.window_config
    local opts = {
      window_config = {
        title = "Test title"
      }
    }
    plugin.setup(opts)
    local win_opts = plugin.options.window_config
    assert.equals(win_opts.title, "Test title")
    for k, v in pairs(default_win_opts) do
      if k ~= 'title' then
        assert.equals(win_opts[k], v)
      end
    end
  end)
  it("can set module path", function()
    local fp = "/home/user/project/apps/app/tests/test_file.py"
    local manage_fp = "/home/user/project/manage.py"
    local module = plugin.set_module_path(fp, manage_fp)
    assert.equals(module, "apps.app.tests.test_file")
  end)
  it("can set module path for special chars too", function()
    local fp = "/home/user/my-project/apps/app/tests/test_file.py"
    local manage_fp = "/home/user/my-project/manage.py"
    local module = plugin.set_module_path(fp, manage_fp)
    assert.equals(module, "apps.app.tests.test_file")
  end)
  it("can calculate top-left coordinate for centered window", function()
    vim.o.columns = 80
    vim.o.lines = 40
    local x, y = plugin.get_coordinates(40, 20)
    assert.equals(x, 20)
    assert.equals(y, 10)
  end)
end)
