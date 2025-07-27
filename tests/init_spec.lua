local assert = require("luassert.assert")

describe("pyrun-init", function()
  local plugin = require("pyrun")
  it("can require", function()
    require("pyrun")
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
  it("buffer", function()
    plugin.open_window()
  end)
end)
