# vim-cmake-build

Build, Run, Debug integration for Vim for CMake based projects.

You can configure the working directory and command line arguments using
simple Vim variables. These settings will be used for all three execution modes.

## Perl support

As a nice bonus the execution of Perl scripts is also supported. When the current buffer
is of filetype `perl`, then the script is executed using the Perl interpreter. Debugging
is also supported using either [VimDebug.vim], the Vim Debugger for Perl or any external debugger
like [DDD].

Note that in this case `g:target`, `g:workdir` are ignored. It simply runs the current script
in the current working directory. `g:args` is passed to the script, though.

# Requirements

Actually really required is nothing, because the functions for running a target directly
or in the debugger always will work. But the main functionality of this plugin
is finding the project root using Git and extracting info from a CMakeLists.txt. To make
this working you need at least [vim-fugitive].

Required software:

* CMake
* Perl
* [mk] script

Strongly recommended Vim plugins:

* [vim-fugitive] the "best Git wrapper of all time".

Optional plugins:

* [valgrind.vim] a Valgrind integration for Vim.
* [VimDebug.vim] a Perl debugger integration for Vim.

[vim-fugitive]: https://github.com/tpope/vim-fugitive
[valgrind.vim]: https://github.com/vim-scripts/valgrind.vim
[VimDebug.vim]: https://github.com/kablamo/VimDebug.vim
[mk]: https://github.com/gergap/mk
[DDD]: https://www.gnu.org/software/ddd

# Screencasts

TODO

# Installation

As usual you can install this plugin with your favourite plugin manager like Vundle or Pathogen.

# Configuration

## Key mappings

To add the default key mappings you can add the following lines to your `.vimrc`,

```Vim script
nmap <leader>d :CMakeDebug<CR>
nmap <leader>x :CMakeExecute<CR>
nmap <leader>v :CMakeValgrind<CR>
```

## Configuration variables

All these variables contain some default values. You can change these in your
`.vimrc` after the plugin is loaded.

```Vim script
" The default CMake build directory, relative to the project root
" containing the .git directory.
let g:bld_dir = 'bld'
" default working directory for launching the target. This can be an
" absolute path, or a relative one. Relative paths are also relative
" to the project directory.
let g:workdir='bin'
" arguments passed to the target
let g:args=""
" Configures the debugger for native binaries: E.g. cgdb, ddd, kdbg, nemiver
let g:debugger='cgdb'
" Configures the debugger for perl scripts. It supports VimDebug, an
" integrated perl debugger for Vim, or simply execute any external perl
" debugger like ddd.
" Possible values: '' (not used), 'VimDebug', 'ddd'
let g:perl_debugger='ddd'
" the cmake executable
let g:cmake='cmake'
" save project settings on exit
let g:cmake_save_on_exit=1
```

# Default key mappings

* `<leader>x` Execute target.
* `<leader>d` Debug target.
* `<leader>v` Execute target in Valgrind.

# Commands

* `CMakeFindProject`: Finds the top level CMakeLists.txt inside the current Git
repository. This gets invoked automatically when you start Vim and the plugin
is loaded.  But if the Git repository didn't exist when your started Vim, or
you simply want to change the project you can invoke this command manually.
* `CMakeTargetList`: Shows all executable CMake targets in new buffer. Simply
navigate to the line containing the target you want to use and hit <CR>.
This will select the target and closes the buffer.
* `CMakeExecute`: Executes the target without debugging.
* `CMakeDebug`: Executes the target in the debugger.
* `CMakeValgrind`: Executes the target using Valgrind.

# Usage

Simply open any source file of a Git project. The plugin will automatically find the project root
and the top level CMakeLists.txt file. Then execute the command `:CMakeTargetList`, and select the line
of the target your want to execute by hitting `j` multiple times and press `<CR>` to use the selected line.

Then use one of the default mappings above to run the selected target.

# History

I refactored this plugin from some existing code in my `.vimrc`, which contains mappings for launching,
debugging and running Valgrind. I needed to configured the variables g:target, g:workdir, and g:args manually,
and because I'm lazy I though it would be useful to make the target selectable interactively,
and because all my programs are CMake based, I'm pulling out this information about available executable
targets from CMake.
In addition I integrated my existing [GitHub][mk] script for building CMake based projects and store the settings
permanently in a dot file when leaving Vim, and reload it on next start. This way Vim "remembers" what
the active target was.

# Technical background

It is not so easy to get a list of executable targets out from CMake directly. But by generating a CodeBlocks project
along with the usual Unix Makefile or Ninja file it is possible to get this from the CodeBlocks project file.
A simple Perl script parses this XML file and outputs the desired information.
To make this working you need to change the CMake generator from `Unix Makefiles` to `CodeBlocks - Unix Makefiles` or
from `Ninja` to `CodeBlocks - Ninja` if your prefer building using Ninja, like I do.
Actually this is done automatically when building using [GitHub][mk].

