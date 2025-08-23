M = {}

local lang = "python"

local python_code = [[
import json

from django.test import TestCase
from django.http import JsonResponse
from django.urls import reverse


class TestClassFromLine8(TestCase):
    def test_getting_urls_response_in_json(self):
        response = self.client.get(reverse("get_urls"))
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response, JsonResponse)

    def test_get_urls_returns_all_urls(self):
        response = self.client.get(reverse("get_urls"))
        json_data = response.json()
        self.assertEqual(len(json_data.keys()), 10)


class TestClassFromLine20(TestCase):
    def test_get_urls_returns_correct_url_for_root(self):
        response = self.client.get(reverse("get_urls"))
        json_data = response.json()
        self.assertEqual(json_data["home"], "/")
        self.assertEqual(json_data["set_csrf"], "/set-csrf/")


class TestClassFromLine28(TestCase):
    def test_get_urls_does_not_include_healthz_itself(self):
        response = self.client.get(reverse("get_urls"))
        json_data = response.json()
        self.assertNotIn("healthz", json_data)
        self.assertNotIn("urls", json_data)
]]

--- To create a TS parser:
--- a buffer is needed with content and filetype set
--- however, treesitter attaches lazily: it needs the buffer to be visible
--- so a window needs to be opened before the parser is created.
--- Without the window, get_parser() wouldn't fail,
--- but calling :parse() would raise out of bound error.
--- NOTE: this fixture only needs to provide the buffer and the window,
--- parser will be created (without mocking) by the source code
--- @param input string
--- @param filetype string
--- @return integer bufnr
--- @return integer win_id
function M._setup(input, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = 10,
    height = 10,
    row = 0,
    col = 0
  })
  vim.api.nvim_set_option_value("filetype", filetype, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(input, '\n'))
  return bufnr, win_id
end

---@param opts table|nil
function M.setup_opened_buffer(opts)
  opts = opts or {}
  local code, filetype = python_code, lang
  if opts.invalid then
    code, filetype = "", "unsupportedft"
  end
  return M._setup(code, filetype)
end

---@param bufnr integer
function M.stream_content(bufnr)
  local row_num = vim.api.nvim_buf_line_count(bufnr)
  local buffer_content = vim.api.nvim_buf_get_lines(bufnr, 0, row_num, false)
  for ix, row in ipairs(buffer_content) do
    print(ix, "> ", row)
  end
end

return M
