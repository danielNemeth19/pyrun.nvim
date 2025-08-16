local assert = require("luassert.assert")

describe("runner class", function()
  local plugin = require("pyrun.runner")
  it("can require", function()
    require("pyrun.runner")
  end)
  -- it("can set module path", function()
    -- local fp = "/home/user/project/apps/app/tests/test_file.py"
    -- local manage_fp = "/home/user/project/manage.py"
    -- local module = plugin.set_module_path(fp, manage_fp)
    -- assert.equals(module, "apps.app.tests.test_file")
  -- end)
  -- it("can set module path for special chars too", function()
    -- local fp = "/home/user/my-project/apps/app/tests/test_file.py"
    -- local manage_fp = "/home/user/my-project/manage.py"
    -- local module = plugin.set_module_path(fp, manage_fp)
    -- assert.equals(module, "apps.app.tests.test_file")
  -- end)
  -- it("can calculate top-left coordinate for centered window", function()
    -- vim.o.columns = 80
    -- vim.o.lines = 40
    -- local x, y = plugin.get_coordinates(40, 20)
    -- assert.equals(x, 20)
    -- assert.equals(y, 10)
  -- end)
end)
