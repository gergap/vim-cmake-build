# vim-cmake-build

Build, Run, Debug integration for Vim for CMake based projects.

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

# Screencasts

TODO

# Installation

As usual you can install this plugin with your favourite plugin manager like Vundle or Pathogen.

# Configuration

TODO 

# Usage

TODO 

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

