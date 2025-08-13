local function buffer_setup(input, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(bufnr, true, { relative = "editor", width = 10, height = 10, row = 0, col = 0 })
  vim.api.nvim_set_option_value("filetype", filetype, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(input, '\n'))
  return bufnr
end

local function get_lines_from_buffer(bufnr)
  local row_num = vim.api.nvim_buf_line_count(bufnr)
  local buffer_content = vim.api.nvim_buf_get_lines(bufnr, 0, row_num, false)
  return buffer_content
end

local pytest = [[
import json

from django.test import TestCase
from django.http import JsonResponse
from django.urls import reverse


class TestGetUrls(TestCase):
    def test_getting_urls_response_in_json(self):
        response = self.client.get(reverse("get_urls"))
        self.assertEqual(response.status_code, 200)
        self.assertIsInstance(response, JsonResponse)

    def test_get_urls_returns_all_urls(self):
        response = self.client.get(reverse("get_urls"))
        json_data = response.json()
        self.assertEqual(len(json_data.keys()), 10)

class TestOther(TestCase):
    pass

class TestOther2(TestCase):
    pass
]]

local function analyze(node, buffid, indent)
  indent = indent or ""
  print(indent .. node:type(), vim.treesitter.get_node_text(node, buffid))
  for child in node:iter_children() do
    analyze(child, buffid, indent .. "    ")
  end
end


describe("pyrun-init", function()
  it("gets names of classes", function()
    local bufnr = buffer_setup(pytest, "python")
    local content = get_lines_from_buffer(bufnr)
    for idx, row in ipairs(content) do
      print(idx, row)
    end
    local parser = vim.treesitter.get_parser(bufnr, "python")
    local tree = parser:parse()[1]
    local root = tree:root()

    vim.api.nvim_win_set_cursor(0, {20, 11})

    local pos = vim.api.nvim_win_get_cursor(0)
    local line, _ = pos[1], pos[2]

    local query = vim.treesitter.query.parse("python", [[(class_definition name: (identifier) @type)]])
    for id, node, metadata, match, tree in query:iter_captures(root, 0, 0, line, { match_limit = 1 }) do
      P({ node:type(), vim.treesitter.get_node_text(node, bufnr), metadata, match:info(), tree:root() })
      local start_row, start_col, end_row, end_col = node:range()
      print(start_row, start_col, end_row, end_col)
    end
  end)
end)
