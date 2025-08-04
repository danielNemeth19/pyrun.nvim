local pr = require("pyrun")

local colors = {
  success = {
    name = "PyrunTestSuccess",
    config = {
      default = true, link = "DiagnosticOk"
    }
  },
  failure = {
    name = "PyrunTestFailure",
    config = {
      default = true, link = "DiagnosticError"
    }
  }
}

for _, spec in pairs(colors) do
  vim.api.nvim_set_hl(0, spec.name, spec.config)
end

pr.colors = colors
