M = {}

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

local function buffer_setup(input, filetype)
  local bufnr = vim.api.nvim_create_buf(false, true)
  print(bufnr)
  print("is valid: ", vim.api.nvim_buf_is_valid(bufnr))
  vim.api.nvim_set_option_value("filetype", filetype, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, vim.split(input, '\n'))
  return bufnr
end

local function get_lines_from_buffer(bufnr)
  local row_num = vim.api.nvim_buf_line_count(bufnr)
  local buffer_content = vim.api.nvim_buf_get_lines(bufnr, 0, row_num, false)
  return buffer_content
end

local test_var = "barmi"

function M.get_parser()
  local bufnr = buffer_setup(pytest, "python")
  -- print(bufnr)
  -- local content = get_lines_from_buffer(bufnr)
  -- print(content)
  -- local parser = vim.treesitter.get_parser(bufnr, "python")
  return bufnr
end

return M
