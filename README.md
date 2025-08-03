# Pyrun

Project is aimed at running all python unit tests in the current buffer at any granularity.

## Table of Contents
* [Current state](#current-state)
* [Usage](#usage)
* [TODO](#todo)

## Current state
Currently, the plugin only supports Django projects and it is only capable to run all tests found in the current buffer.

The output of the test run is presented in a floating window, centered in the middle of the screen.

Right now the plugin doesn't allow for user configurations.

## Usage:

| Insert  | Normal    | Action                                     |
| ------- | --------- | ------------------------------------------ |
|   -     |`<leader>t`| Triggers running all tests in file         |
|   -     |`q`        | Closes floating window showing test run    |

The result of the test run is shown in a floating window. To close it, use `q`. 

For this to work, the floating window needs to be active. You can a make it active with `C-w w`

## TODO:
* configurable keymaps
* implement running closest test case
* implement running closest test class
* providing custom commands
* improve coloring of test result: right now everything is green ('success')
* look at stderr buffering - maybe show test result output without buffering?
