local assert = require("luassert.assert")

describe("pyrun-init", function()
  local plugin = require("pyrun")
  local Runner = require("pyrun.runner")
  ---@type pyrun.Opts
  local called_opts
  ---@type pyrun.Config
  local called_config
  local orig_new

  before_each(function()
    orig_new = Runner.new
    Runner.new = function(self, opts, config)
      called_opts = opts
      called_config = config
      return orig_new(self, opts, config)
    end
  end)
  after_each(function()
    Runner.new = orig_new
  end)
  it("can require", function()
    require("pyrun")
  end)
  it("can be configured with default options", function()
    local default_opts = require("pyrun.config").opts
    plugin.setup()
    assert.same(default_opts, called_opts)
  end)
  it("can be configured with custom options", function()
    local default_win_opts = require("pyrun.config").opts.window_config
    local opts = {
      window_config = {
        title_prefix = "Test title"
      }
    }
    plugin.setup(opts)
    ---@type pyrun.window_config
    local win_opts = called_opts.window_config
    assert.equals(win_opts.title_prefix, "Test title")
    for k, v in pairs(default_win_opts) do
      if k ~= 'title_prefix' then
        assert.equals(win_opts[k], v)
      end
    end
  end)
  it("sets color names accordingly to config", function()
    ---@type pyrun.Colors
    local expected_color_map = {
      success = "PyrunTestSuccess",
      failure = "PyrunTestFailure"
    }
    plugin.setup()
    assert.same(called_config.color_names, expected_color_map)
  end)
end)
