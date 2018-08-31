" cmake.vim - A Vim integration of CMake for Building, Running, and Debugging.
" Author: Gerhard Gappmeier <gerhard.gappmeier@ascolab.com>
" Version: 1.0
" Home: github.com/gergap/vim-cmake-build.git

" include protection
if exists('g:loaded_cmake') || &cp
  finish
endif
let g:loaded_cmake = 1
" ================================================
" some internal variables to find the perl scripts
" ================================================
let s:get_targets = expand('<sfile>:p:h:h').'/get_executables.pl'
let s:get_project_name = expand('<sfile>:p:h:h').'/get_project_name.pl'
let s:gdbinit = expand('<sfile>:p:h:h').'/.gdbinit'
let s:dashboard = expand('<sfile>:p:h:h').'/dashboard'
let s:debug_output = 0
" ===============================================
" global variables and settings
" ===============================================
" The default CMake build directory, relative to the project root
" containing the .git directory.
let g:blddir_dflt = 'bld'
" default working directory for launching the target. This can be an
" absolute path, or a relative one. Relative paths are also relative
" to the project directory.
let g:workdir_dflt='bin'
" arguments passed to the target
let g:args_dflt=""
" Configures the debugger for native binaries: E.g. cgdb, ddd, kdbg, nemiver
let g:debugger_dflt='cgdb'
" Configures the debugger for perl scripts. It supports VimDebug, an
" integrated perl debugger for Vim, or simply execute any external perl
" debugger like ddd.
" Possible values: '' (not used), 'VimDebug', 'ddd'
let g:perl_debugger_dflt='VimDebug'
" the cmake executable
let g:cmake_dflt='cmake'
" save project settings on exit
let g:cmake_save_on_exit_dflt=1
" create .gdbinit for loading/storing breakpoints when debugging.
" disable this if you need to use your own .gdbinit, in this case
" you can integrate this script into your .gdbinit
let g:cmake_create_gdb_init_dflt=1
" Create a new Tmux pane running gdb-dashboard
let g:cmake_create_tmux_dashboard_dflt=1
" ====================================================================
" automatically populated global variables (set by cmake_find_project)
" ====================================================================
" Project root directory. Can be set manually or is found automatically
" when working with files from a git repo.
let g:project_root = ''
" full path to generated CodeBlocks project. This is used to extract
" the executable build targets. You need to use the CMake generator
" 'CodeBlocks - Ninja' or 'CodeBlocks - Unix Makefiles' for this.
let g:cbp_project = ''
" The target executable to run, debug, or analyze in Valgrind
let g:target = ''

" good old printf debugging
function! s:debug_print(message)
    if s:debug_output
        echom a:message
    endif
endfunction

" evaluates user configuration variables and sets defaults if missing
function! s:cmake_evaluate_config()
    if !exists('g:blddir')
        let g:blddir=g:blddir_dflt
    endif
    if !exists('g:workdir')
        let g:workdir=g:workdir_dflt
    endif
    if !exists('g:args')
        let g:args=g:args_dflt
    endif
    if !exists('g:debugger')
        let g:debugger=g:debugger_dflt
    endif
    if !exists('g:perl_debugger')
        let g:perl_debugger=g:perl_debugger_dflt
    endif
    if !exists('g:cmake')
        let g:cmake=g:cmake_dflt
    endif
    if !exists('g:cmake_save_on_exit')
        let g:cmake_save_on_exit=g:cmake_save_on_exit_dflt
    endif
    if !exists('g:cmake_create_gdb_init')
        let g:cmake_create_gdb_init=g:cmake_create_gdb_init_dflt
    endif
    if !exists('g:cmake_create_tmux_dashboard')
        if !exists("g:loaded_vimux")
            " this feature requires tmux and the Vimux plugin
            let g:cmake_create_tmux_dashboard_dflt=0
        endif
        let g:cmake_create_tmux_dashboard=g:cmake_create_tmux_dashboard_dflt
    else
        if g:cmake_create_tmux_dashboard && !exists("g:loaded_vimux")
            echom "Disabled g:cmake_create_tmux_dashboard because Vimux was not found."
            let g:cmake_create_tmux_dashboard=0
        endif
    endif
endfunction

" Finds the toplevel CMake project in the current git project.
" This requires a Git repo to work, and vim-fugitive.
function s:cmake_find_project()
    call s:cmake_evaluate_config()
    if g:loaded_fugitive
        let gitdir = fugitive#extract_git_dir(expand('%'))
        let g:project_root = fnamemodify(gitdir, ':p:h:h')
        let cmake_project = g:project_root."/CMakeLists.txt"
        let project_name = system(s:get_project_name.' '.cmake_project)
        let g:cbp_project = g:project_root.'/'.g:blddir.'/'.project_name.'.cbp'
    else
        echoerr "The plugin vim-fugitive is not loaded."
    endif
endfunction

" Creates new buffer containing all the executable targets and sets
" up a mapping to select a target by pressing <CR>
function! s:create_target_buffer()
    call s:cmake_evaluate_config()
    new
    normal iSelect target executable:
    setlocal ft=cmake_targetlist
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nomodified
    execute "read !".s:get_targets.' '.g:cbp_project
    nmap <buffer> <CR> :call cmake#target_select()<cr>
    normal! ggj
endfunction

" Select the target of the current line.
function! cmake#target_select()
    let g:target=getline('.')
    echom "selected target=".g:target
    execute "bd"
endfunction

" Returns 1 if the given path is absolute, otherwise 0.
function! s:is_absolute(path)
    if strpart(a:path, 0, 1) == '/'
        return 1
    else
        return 0
    endif
endfunction

function! s:file_exists(path)
    if !empty(glob(a:path))
        return 1
    else
        return 0
    endif
endfunction

" Computes the working directory to use based on the configuration settings.
function! cmake#get_workingdir()
    if s:is_absolute(g:workdir)
        " use absolute path as is
        return g:workdir
    else
        " use relative to project root
        return g:project_root.'/'.g:workdir
    endif
endfunction

" Sets the target working directory.
" This is used by run_target, run_valgrind and run_debugger.
function! s:set_working_dir()
    if g:workdir == ''
        " nothing to do, keep current working directory
        return
    endif

    " compute target working dir
    let workdir=cmake#get_workingdir()

    " check if path exists
    if s:file_exists(workdir)
        call s:debug_print("workdir=".workdir)
        exe "cd ".workdir
    else
        echoerr "Configured working directory '".workdir."' does not exist."
    endif
endfunction

" Runs the target without debugging.
" If the current buffer contains a perl script this is executed using the perl interpreter
" in the current working directory. This way you can simply launch any perl
" script by hitting a key.
" Otherwise the configured g:target is launched in g:workdir with the arguments
" g:args.
function! s:run_target()
    call s:cmake_evaluate_config()
    if &ft == "perl"
        exe "!perl % ".g:args
    else
        if exists("g:target")
            let s:dir=getcwd()
            call s:set_working_dir()
            execute "!".g:target g:args
            exe "cd ".s:dir
        else
            echo "No target is defined. Please execute 'let g:target=\"<your target>\"' or use CMakeTargetList command to select one."
        endif
    endif
endfunction

" Run the target in valgrind.
" This requires the plugin 'vim-scripts/valgrind.vim' for Valgrind
" integration. This functions uses the same configuration like RunTarget:
" g:target, g:workdir and g:args.
function! s:run_valgrind()
    call s:cmake_evaluate_config()
    if exists("g:target")
        let s:dir=getcwd()
        call s:set_working_dir()
        execute ":Valgrind ".g:target." ".g:args
        exe "cd ".s:dir
    else
        echo "No target is defined. Please execute 'let g:target=\"<your target>\"'"
    endif
endfunction

" Creates a .gdbinit file in the working directory for loading and storing
" breakpoints
function! s:create_gdb_init()
    if g:cmake_create_gdb_init
        let workdir=cmake#get_workingdir()
        " cmake contains a cross platform copy command
        call system(g:cmake.' -E copy '.s:gdbinit.' '.workdir)
    endif
endfunction

" Creates a .gdbinit file in the working directory for loading and storing
" breakpoints
function! s:create_gdb_dashboard()
    if g:cmake_create_tmux_dashboard
        call VimuxRunCommand(s:dashboard)
    endif
endfunction

" Close GDB dashboard again
function! s:close_gdb_dashboard()
    if g:cmake_create_tmux_dashboard
        call VimuxCloseRunner()
    endif
endfunction

" Run the target in the debugger.
" This supports debugging Perl scripts as well as native binaries.
" note on installing VimDebug:
" cpanm Vim::Debug
" vimdebug-install -d ~/.vimrc
" see also 'perldoc Vim::Debug'
function! s:run_debugger()
    call s:cmake_evaluate_config()
    if &ft == "perl"
        if g:perl_debugger == 'VimDebug'
            exe "VDstart main"
        else
            execute "silent !"g:perl_debugger.' '.g:target
        endif
    else
        if exists("g:target")
            call breakpoints#save()
            call s:create_gdb_init()
            call s:create_gdb_dashboard()
            if g:args == ''
                " no arguments
                let cmd=g:debugger.' '.g:target
            else
                " arguments defined
                if (g:debugger=='gdb' || g:debugger=='cgdb')
                    let cmd=g:debugger.' --args '.g:target.' '.g:args
                elseif (g:debugger=='kdbg')
                    let cmd=g:debugger.' -a "'.g:args.'" '.g:target
                elseif (g:debugger=='nemiver')
                    let cmd=g:debugger.' '.g:target.' '.g:args
                else
                    echo "Passing args to this debugger is not possible. Use the GUI or a .gdbinit file to set the args."
                    let cmd=g:debugger.' '.g:target
                endif
            endif
            let s:dir=getcwd()
            call s:set_working_dir()
            execute "silent !".cmd
            execute "redraw!"
            " restore directory
            exe "cd ".s:dir
            call s:close_gdb_dashboard()
            call breakpoints#load()
        else
            echo "No target is defined. Please execute 'let g:target=\"<your target>\"'"
        endif
    endif
endfunction

" Checks if the configuration is correct.
function! s:sanity_check()
    call s:cmake_evaluate_config()
    if g:perl_debugger == ''
        echo "No perl debugger configured."
    elseif g:perl_debugger == 'VimDebug'
        if exists('*DBGRstart')
            call s:debug_print("VimDebug exists.")
        else
            echoerr "Your have configured 'VimDebug' as your perl debugger, but 'DBGRstart' function does not exist."
        endif
    else
        if executable(g:perl_debugger)
            call s:debug_print("Found ".g:perl_debugger.".")
        else
            echoerr "The configured perl debugger '".g:perl_debugger."' was not found."
        endif
    endif
    if executable(g:debugger)
        call s:debug_print("Found ".g:debugger.".")
    else
        echoerr "The configured debugger '".g:debugger."' was not found."
    endif
    if executable(g:cmake)
        call s:debug_print("Found ".g:cmake.".")
    else
        echoerr "The configured CMake executable '".g:cmake."' was not found."
    endif
endfunction

" loads vim plugin settings from file
function! s:load_settings()
    if g:project_root == ''
        return
    endif
    let settingsfile=g:project_root.'/.settings.vim'
    if s:file_exists(settingsfile)
        exe 'source '.settingsfile
    endif
    silent! call breakpoints#load()
endfunction

" saves vim plugin settings to file
" g:target: selected debug target
" g:args  : commandline arguments for target
function! s:save_settings()
    if g:project_root == '' || g:cmake_save_on_exit == 0
        return
    endif
    let settingsfile=g:project_root.'/.settings.vim'
    let settings=["let g:target='".g:target."'", "let g:args='".g:args."'"]
    call writefile(settings, settingsfile)
    silent! call breakpoints#save()
endfunction

" Define custom commands
command! CMakeFindProject call s:cmake_find_project()
command! CMakeTargetList  call s:create_target_buffer()
command! CMakeDebug       call s:run_debugger()
command! CMakeExecute     call s:run_target()
command! CMakeValgrind    call s:run_valgrind()
" autocommands
augroup cmakegroup
    autocmd!
    autocmd VimLeave * call s:save_settings()
augroup END

function! s:plugin_init()
    call s:sanity_check()
    call s:cmake_find_project()
    call s:load_settings()
endfunction

" start
call s:plugin_init()

