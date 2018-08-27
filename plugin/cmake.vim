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
let s:debug_output = 0
" ===============================================
" global variables and settings
" ===============================================
" The default CMake build directory, relative to the project root
" containing the .git directory.
let g:bld_dir = 'bld'
" default working directory for launching the target. This can be an
" absolute path, or a relative one. Relative paths are also relative
" to the project directory.
let g:workdir="bin"
" arguments passed to the target
let g:args=""
" Configures the debugger for native binaries: E.g. cgdb, ddd, kdbg, nemiver
let g:debugger="cgdb"
" Configures the debugger for perl scripts. It supports VimDebug, an
" integrated perl debugger for Vim, or simply execute any external perl
" debugger like ddd.
let g:perl_debugger="VimDebug"
"let g:perl_debugger="ddd"
" the cmake executable
let g:cmake="cmake"
" save project settings on exit
let g:cmake_save_on_exit=1
" create default key mappings
let g:cmake_create_default_mappings=0
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

" Finds the toplevel CMake project in the current git project.
" This requires a Git repo to work, and vim-fugitive.
function s:cmake_find_project()
    if g:loaded_fugitive
        let gitdir = fugitive#extract_git_dir(expand('%'))
        let g:project_root = fnamemodify(gitdir, ':p:h:h')
        let cmake_project = g:project_root."/CMakeLists.txt"
        let project_name = system(s:get_project_name.' '.cmake_project)
        let g:cbp_project = g:project_root.'/'.g:bld_dir.'/'.project_name.'.cbp'
    else
        echoerr "The plugin vim-fugitive is not loaded."
    endif
endfunction

" Creates new buffer containing all the executable targets and sets
" up a mapping to select a target by pressing <CR>
function! s:create_target_buffer()
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
function! s:get_workingdir()
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
    let workdir=s:get_workingdir()

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
    if exists("g:target")
        let s:dir=getcwd()
        call s:set_working_dir()
        execute ":Valgrind ".g:target." ".g:args
        exe "cd ".s:dir
    else
        echo "No target is defined. Please execute 'let g:target=\"<your target>\"'"
    endif
endfunction

" Run the target in the debugger.
" This supports debugging Perl scripts as well as native binaries.
" note on installing VimDebug:
" cpanm Vim::Debug
" vimdebug-install -d ~/.vimrc
" see also 'perldoc Vim::Debug'
function! s:run_debugger()
    if &ft == "perl"
        if g:perl_debugger == 'VimDebug'
            exe "VDstart main"
        else
            execute "silent !"g:perl_debugger.' '.g:target
        endif
    else
        if exists("g:target")
            let s:dir=getcwd()
            call s:set_working_dir()
            execute "silent !"g:debugger.' '.g:target
            execute "redraw!"
            " restore directory
            exe "cd ".s:dir
        else
            echo "No target is defined. Please execute 'let g:target=\"<your target>\"'"
        endif
    endif
endfunction

" Checks if the configuration is correct.
function! s:sanity_check()
    if g:perl_debugger == 'VimDebug'
        if exists('*DBGRstart')
            call s:debug_print("VimDebug exists.")
        else
            echoerr "Your have configured 'VimDebug' as your perl debugger, but 'DBGRstart' function does not exist."
        endif
    else
        if executable(g:perl_debugger)
            s:debug_print("Found ".g:perl_debugger.".")
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

function! s:load_settings()
    if g:project_root == ''
        return
    endif
    let settingsfile=g:project_root.'/.settings.vim'
    if s:file_exists(settingsfile)
        exe 'source '.settingsfile
    endif
endfunction

function! s:save_settings()
    if g:project_root == '' || g:cmake_save_on_exit == 0
        return
    endif
    let settingsfile=g:project_root.'/.settings.vim'
    call writefile(["let g:target='".g:target."'"], settingsfile)
endfunction

" Define custom commands
command! CMakeTargetList call s:create_target_buffer()
command! CMakeDebug      call s:run_debugger()
command! CMakeExecute    call s:run_target()
command! CMakeValgrind   call s:run_valgrind()
" Define custom mappings
if g:cmake_create_default_mappings
    nmap <leader>d :CMakeDebug<CR>
    nmap <leader>x :CMakeExecute<CR>
    nmap <leader>v :CMakeValgrind<CR>
endif
" autocommands
augroup cmakegroup
    autocmd!
    autocmd VimLeave * call s:save_settings()
augroup END

" start
call s:sanity_check()
call s:cmake_find_project()
call s:load_settings()


