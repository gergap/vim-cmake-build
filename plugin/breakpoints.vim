" breakpoints.vim - Integrates GDB breakpoint configuration in Vim
" Author: Gerhard Gappmeier <gerhard.gappmeier@ascolab.com>
" Version: 1.0
" Home: github.com/gergap/vim-cmake-build.git

" include protection
if exists('g:autoloaded_breakpoints') || &cp
  finish
endif
let g:autoloaded_breakpoints = 1
" break point index that will be incremented for each breakpoint
let g:bpindex = 1
" list of breakpoints. this is an associative array with the location
" as key. Location is the string "<filename>:<lineno>" like used by GDB.
" The value is another associative array which represents a struct with
" the following elements:
" file: the filename of the breakpoint
" line: the line number of the breakpoint
" index: the breakpoint index
let g:bplist = {}
let s:get_bp_icon = expand('<sfile>:p:h:h').'/icons/breakpoint.xpm'

" Initializes the breakpoint functionality by defining a new sign type.
function! s:BreakpointInit()
    hi Breakpoint ctermfg=red ctermbg=black
    hi BreakpointLine ctermfg=black ctermbg=red
    exe 'sign define breakpoint text=🅑 icon='.s:get_bp_icon.' texthl=Breakpoint linehl=BreakpointLine'
endfunction

" Creates a new split with information about all existing breakpoints
function! s:BreakpointList()
    new
    call setline(1, "List of breakpoints:")
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nomodified
    for bp in values(g:bplist)
        let pbinfo = bp.index.': '.bp.file.':'.bp.line
        call append(line('$'), pbinfo)
    endfor
endfunction

" Populates a location list with breakpoints.
function! s:BreakpointLocList()
    let locations = []
    for bp in values(g:bplist)
        let loc = { 'filename': bp.file, 'lnum': bp.line }
        call add(locations, loc)
    endfor
    call setloclist(0, locations, 'r')
    exe "lopen"
endfunction

function! s:SetBreakpoint(file, line)
    let bp = { 'file':a:file, 'line':a:line, 'index':g:bpindex }
    " increment breakpoint index
    let g:bpindex = g:bpindex+1
    " store breakpoint info in global list
    let loc = bp.file.':'.bp.line
    let g:bplist[loc] = bp
    " set sign
    exe "sign place ".bp.index." name=breakpoint line=".bp.line." file=".bp.file
endfunction

function! s:RemoveBreakpoint(bp)
    let loc = a:bp.file.':'.a:bp.line
    " remove breakpoint from global list
    call remove(g:bplist, loc)
    " remove sign
    exe "sign unplace ".a:bp.index
endfunction

function! s:RemoveAllBreakpoints()
    for bp in values(g:bplist)
        call s:RemoveBreakpoint(bp)
    endfor
endfunction

" Reads a list of breakpoints from file.
" This file can be generated by GDB using the provided GDB hook script.
" It does not work with GDB's "save breakpoints" function because, this 
" does not create the full path.
function! breakpoints#load()
    call s:RemoveAllBreakpoints()
    let filename = cmake#get_workingdir().'/.breakpoints.gdb'
    if !cmake#file_exists(filename)
        return
    endif
    let lines = readfile(filename)
    let g:bpindex = 1
    let g:bplist = {}
    exe "tabnew"
    for line in lines
        let loc = strpart(line, 6)
        let parts = split(loc, ':')
        let file = parts[0]
        let line = parts[1]
        " check if buffer for file exists
        if bufloaded(file) == 0
            " load file into buffer (required to set sign)
            exe "edit ".file
"            noautocmd exe "edit ".file
        endif
        call s:SetBreakpoint(file, line)
    endfor
    exe "tabclose"
endfunction

" Saves Vim's list of breakpoints in a file that can be sourced by .gdbinit.
function! breakpoints#save()
    let filename = cmake#get_workingdir().'/.breakpoints.gdb'
    let bplist=["set breakpoint pending on"]
    for bp in values(g:bplist)
        let loc = bp.file.':'.bp.line
        let bpline = 'break '.loc
        call add(bplist, bpline)
    endfor
    call writefile(bplist, filename)
endfunction

" Toggles the breakpoint in the current line.
" This function does not check if this make sense. Every line is accepted.
function! s:BPtoggle()
    let file = expand('%:p')
    let line = line('.')
    let loc = file.':'.line
    let notfound = {}
    let bp = get(g:bplist, loc, notfound)
    if bp != notfound
        call s:RemoveBreakpoint(bp)
    else
        call s:SetBreakpoint(file, line)
    endif
endfunction

nnoremap <space> :call <SID>BPtoggle()<cr>

command! BPlist call s:BreakpointList()
command! BPloclist call s:BreakpointLocList()
command! BPtoggle call s:BPtoggle()
command! BPload call breakpoints#load()
command! BPsave call breakpoints$save()

call s:BreakpointInit()


