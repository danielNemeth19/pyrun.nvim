# Pyrun

Project is aimed at running all python unit tests in the current buffer at any granularity.

## Table of Contents
* [Current state](#current-state)
* [Installation](#installation)
* [Configuration](#configuration)
    * [Using defaults](#using-defaults)
    * [Customization](#customization)
* [Default Mappings](#default-mappings)
* [TODO](#todo)

## Current state
Currently, the plugin only supports Django projects. It is capable to run:
* all tests found in the current buffer
* all tests of the 'closest' test class - this is decided based on the cursor position. In this mode, plugin runs all tests in the parent class under the cursor.

The output of the test run is presented in a floating window, centered in the middle of the screen.

## Installation
### [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
return {
  {
    "danielNemeth19/pyrun.nvim",
    ft = "python",
    opts = {
      -- See Customization section for options
    },
  },
}
```

## Configuration
### Using defaults
The plugin is lazy loaded for python files. In case you want to use the plugin without any customization, the preferred config is:
```lua
return {
  {
    "danielNemeth19/pyrun.nvim",
    ft = "python",
    opts = {},
  },
}
```
Lazy will call the plugin's setup function in case an `opts` property is defined.
An empty `opts` table means the defaults will be applied, since an empty table will be merged with the default config.

Alternatively, you can omit `opts` and set `config` to true -> Lazy would then call `setup()` (no arguments) for you: 

```lua
return {
  {
    "danielNemeth19/pyrun.nvim",
    ft = "python",
    config = true
  }
}
```

Of course, calling `setup()` manually from `config` is also possible.

See [lazy spec setup](https://lazy.folke.io/spec#spec-setup) for more details.

### Customization
Below all the configuration options currently supported.

```lua
  {
    keymaps = {
      run_all = "<leader>t",
      close_float = "q"
    },
    window_config = {
      relative = "win",
      width = 150,
      height = 40,
      style = "minimal",
      border = "single",
      title = "Running tests"
    }
  }
```
To change anything, just set the corresponding key in opts, e.g.:
```lua
return {
  {
    "danielNemeth19/pyrun.nvim",
    ft = "python",
    opts = {
      window_config = {
        title = "Custom title"
      }
    }
  }
}
```

## Default Mappings:
| Insert  | Normal     | Action                               |
| ------- | ---------- | -------------------------------------|
|   -     |`<leader>tt`| Runs all tests in file               |
|   -     |`<leader>t` | Runs all tests of parent test class* |
|   -     |`q`         | Closes results window                |

The result of the test run is shown in a floating window. To close it, use `q`. 

\*In this mode runs all tests in the parent test class when the cursor is inside any test belonging to that class.

## TODO:
* implement running closest test case - done
* implement running closest test class
* investigate treesitter playground for `def` and `class` targeting - done for `class`, on track for `def`
* providing custom commands
* improve coloring of test result: right now everything is green ('success')
* look at stderr buffering - maybe show test result output without buffering?
* lazy loading based on \*test\*.py files
* Logging, with custom command to open log file
