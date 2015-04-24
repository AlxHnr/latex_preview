" Copyright (c) 2014 Alexander Heinrich <alxhnr@nudelpost.de> {{{
" 
" This software is provided 'as-is', without any express or implied
" warranty. In no event will the authors be held liable for any damages
" arising from the use of this software.
" 
" Permission is granted to anyone to use this software for any purpose,
" including commercial applications, and to alter it and redistribute it
" freely, subject to the following restrictions:
" 
"    1. The origin of this software must not be misrepresented; you must
"       not claim that you wrote the original software. If you use this
"       software in a product, an acknowledgment in the product
"       documentation would be appreciated but is not required.
" 
"    2. Altered source versions must be plainly marked as such, and must
"       not be misrepresented as being the original software.
" 
"    3. This notice may not be removed or altered from any source
"       distribution.
" }}}

" -------------------------------------------------------------------------

" All failable functions in this script return a 1 to indicate success and
" a 0 to indicate failure. All script local functions don't do any error
" handling unless specified otherwise, so only pass valid values. You must
" also ensure that all requirements and dependencies of the called function
" are fulfilled.

" -------------------------------------------------------------------------

" The dictionary 's:instances' contains all the latex_preview instances
" that are active. The key is the number of the buffer. Each instance has
" the following values:
"
" - filename - The pathless filename.
" - tmpdir - Full path to its temporary directory, that ends with a slash.
" - tmpfile - Full path to its temporary file.
" - cd_command - Command to chdir into the dir of the real source file.
" - compiler - Compiler name.
" - build_command - Build command.
" - output_file - Needed by the document viewer and the export command.
" - build_pid - The PID of the last build process. Used to determine if its
"   still running.
" - last_build - The timestamp of the last started build.
" - document_viewer - Name of the document viewer that is used in the
"   instance.
" - document_viewer_pid - Its PID.
if !exists('s:instances')
	let s:instances = {}
endif

" -------------------------------------------------------------------------

" Various helper functions.
" Clears the last message and echoes 'str'.
function! s:clear_echo(str) " {{{
	redraw
	echo a:str
endfunction " }}}
function! s:pid_running(pid) " {{{
	call system('ps -p ' . a:pid . ' >/dev/null 2>&1')
	return v:shell_error == 0
endfunction " }}}
function! s:pid_wait(pid) " {{{
	call system('while ps -p ' . a:pid
		\	. '; do sleep 0.25; done >/dev/null 2>&1')
endfunction " }}}
function! s:pid_kill(pid) " {{{
	call system('kill -s SIGTERM ' . a:pid . ' &')
endfunction " }}}

" Ensures that 'path' is an existing directory. If not, and it failed to
" create one, it returns 0.
function! s:dir_ensure_existence(path) " {{{
	if isdirectory(a:path)
		return 1
	endif

	try
		call mkdir(a:path, 'p', 0700)
	catch /^Vim\%((\a\+)\)\=:E739/
		call s:clear_echo('Failed to create a temporary directory.')
		return 0
	endtry

	return 1
endfunction " }}}
function! s:dir_remove(path) " {{{
	call system('rm -rf ' . a:path)
endfunction " }}}

" -------------------------------------------------------------------------

" Does a blocking, verbose build with user interaction. This function
" assumes, that a 'id' is valid and its tmpdir, etc. is setup properly.
function! s:build_verbose(id) " {{{
	call s:build_wait_verbose(a:id)

	execute 'noautocmd silent! write! '
		\	. escape(s:instances[a:id].tmpfile, '\ ')

	call s:clear_echo("Building '" . s:instances[a:id].filename . "' ...")

	let l:error = system(s:instances[a:id].cd_command . ' && '
		\	. s:instances[a:id].build_command)
	let s:instances[a:id].build_pid = 0
	let s:instances[a:id].last_build = localtime()

	if v:shell_error != 0
		call s:clear_echo("Failed to run '" . s:instances[a:id].compiler . "'.")
		if confirm('Show the error message ?', "&Yes\n&No", 2) == 1
			echo l:error
		endif

		return 0
	endif

	call s:clear_echo("Build '" . s:instances[a:id].filename
		\	. "' successfully.")

	return 1
endfunction " }}}

" If there is a build process, wait until it finishes and message the user.
function! s:build_wait_verbose(id) " {{{
	if s:pid_running(s:instances[a:id].build_pid)
		call s:clear_echo(s:instances[a:id].compiler
			\	. ' is still running. Waiting ...')

		call s:pid_wait(s:instances[a:id].build_pid)
	endif
endfunction " }}}

" Calls 's:build_verbose()' twice. Most LaTeX compilers need up to 2 runs
" to build stuff like i.e. the table of contents.
function! s:build_twice(id) " {{{
	return s:build_verbose(a:id) && s:build_verbose(a:id)
endfunction " }}}

" The same as 's:build_verbose()', but without any user interaction, output
" and error handling. It just spawns another build process in the
" background. But only if the last build is not still running and happened
" some time ago. See 'g:latex_preview#least_delay'. It has the same
" requirements as 's:build_verbose()'.
function! s:build_background(id) " {{{
	" return if its to early or another build is still running.
	if ((localtime() - s:instances[a:id].last_build) <
		\	g:latex_preview#least_delay) ||
		\	s:pid_running(s:instances[a:id].build_pid)
		return
	endif

	execute 'noautocmd silent! write! '
		\	. escape(s:instances[a:id].tmpfile, '\ ')

	let s:instances[a:id].build_pid =
		\	system(s:instances[a:id].cd_command . ' >/dev/null 2>&1 && ('
		\	. s:instances[a:id].build_command . ' >/dev/null 2>&1 &'
		\	. ' echo -n $!)')

	let s:instances[a:id].last_build = localtime()
endfunction " }}}

" -------------------------------------------------------------------------

" Start the document viewer and sets some variables. Returns 1 on success
" and 0 on failure.
function! s:instance_setup_document_viewer(id) " {{{
	call s:build_wait_verbose(a:id)

	let s:instances[a:id].document_viewer = g:latex_preview#document_viewer
	let s:instances[a:id].document_viewer_pid =
		\	system(s:instances[a:id].document_viewer . ' '
		\	. shellescape(s:instances[a:id].output_file)
		\	. ' >/dev/null 2>&1 & echo -n $!')

	" Return on shell errors, or if the document viewer isnt running anymore.
	if v:shell_error != 0 ||
		\	!s:pid_running(s:instances[a:id].document_viewer_pid)

		call s:clear_echo("failed to start '"
			\	. s:instances[a:id].document_viewer . "'")

		return 0
	endif

	call s:clear_echo("started preview of '"
		\	. s:instances[a:id].filename . "'")

	return 1
endfunction " }}}

" -------------------------------------------------------------------------

" Creates a new, empty instance and sets all variables. This function also
" creates a temporary directory and setups all autocmds. This function does
" not check if 'id' already exists in 's:instances'. It just re-defines it.
" This function must be run from inside the buffer with 'id'. It returns 1
" on success and 0 on failure. If this function fails, 'id' wont be created
" at all.
function! s:instance_new(id) " {{{
	if empty(expand('%'))
		echomsg 'latex_preview: Refusing unnamed buffers.'
		return 0
	endif

	let l:tmpdir = tempname() . '/'
	if !s:dir_ensure_existence(l:tmpdir)
		return 0
	endif

	let s:instances[a:id] = {}
	let s:instances[a:id].tmpdir = l:tmpdir
	let s:instances[a:id].filename = expand('%:t')
	let s:instances[a:id].tmpfile = s:instances[a:id].tmpdir . expand('%:t')

	let s:instances[a:id].cd_command = 'cd ' . shellescape(expand('%:p:h'))
	let s:instances[a:id].compiler = g:latex_preview#compiler

	let l:build_info =
		\	{
		\		'tmpdir'  : s:instances[a:id].tmpdir,
		\		'tmpfile' : s:instances[a:id].tmpfile
		\	}

	let s:instances[a:id].build_command = g:latex_preview#compiler
		\	. ' ' . g:Latex_preview#get_compiler_args(l:build_info)

	let s:instances[a:id].output_file =
		\	g:Latex_preview#get_output_file(l:build_info)

	let s:instances[a:id].build_pid = 0
	let s:instances[a:id].last_build = 0

	let s:instances[a:id].document_viewer = g:latex_preview#document_viewer
	let s:instances[a:id].document_viewer_pid = 0

	augroup latex_preview
		execute 'autocmd! * <buffer=' . a:id . '>'

		execute 'autocmd ' . g:latex_preview#rebuild_events
			\ . ' <buffer=' . a:id . '> call s:build_background(' . a:id . ')'
	augroup END

	execute 'command! -buffer LatexPreviewStop call s:instance_destroy('
		\	. a:id . ')'
	execute 'command! -buffer LatexPreviewRebuild call s:rebuild_verbose('
		\	. a:id . ')'

	return 1
endfunction " }}}

" Destroys the instance 'id', removes all the temporary directories and
" stops the document viewer. It also removes all the autocmds and commands.
" It is safe to pass a non-existing 'id'. But if it exists, all its
" variables must be set.
function! s:instance_destroy(id) " {{{
	if !exists('s:instances[a:id]')
		return
	endif

	augroup latex_preview
		execute 'autocmd! * <buffer=' . a:id . '>'
	augroup END

	silent! delcommand LatexPreviewStop
	silent! delcommand LatexPreviewRebuild

	" We need our tmpdir, to shut down processes properly. 's:pid_kill()'
	" internally calls 'system()', which needs a tmpdir.
	if !s:dir_ensure_existence(s:instances[a:id].tmpdir)
		unlet s:instances[a:id]
		return
	endif

	if s:pid_running(s:instances[a:id].document_viewer_pid)
		call s:pid_kill(s:instances[a:id].document_viewer_pid)
	endif

	if s:pid_running(s:instances[a:id].build_pid)
		call s:pid_kill(s:instances[a:id].build_pid)
	endif

	call s:dir_remove(s:instances[a:id].tmpdir)
	unlet s:instances[a:id]
endfunction " }}}

" Re-initializes and restarts everything inside the current instance, that
" is not doing what its supposed to do. It destroys the entire instance on
" errors and returns 0. Otherwise it will return 1.
function! s:instance_reinit(id) " {{{
	let l:need_rebuild = 0

	" if the tmpdir is broken we need to rebuild and restart the viewer.
	if !isdirectory(s:instances[a:id].tmpdir)
		if !s:dir_ensure_existence(s:instances[a:id].tmpdir)
			call s:instance_destroy(a:id)

			return 0
		endif

		if s:pid_running(s:instances[a:id].document_viewer_pid)
			call s:pid_kill(s:instances[a:id].document_viewer_pid)
		endif

		let l:need_rebuild = 1
	endif

	if s:pid_running(s:instances[a:id].document_viewer_pid)
		call s:clear_echo(s:instances[a:id].document_viewer
			\	. ' is already running. (PID '
			\	. s:instances[a:id].document_viewer_pid . ')')
		return
	endif

	if (l:need_rebuild && !s:build_twice(a:id)) ||
		\	!s:instance_setup_document_viewer(a:id)
		call s:instance_destroy(a:id)

		return 0
	endif

	return 1
endfunction " }}}

" -------------------------------------------------------------------------

" Launches a new preview session. If it already exists, it tries to
" re-init the existing one.
function! latex_preview#preview() " {{{
	let l:id = bufnr('%')

	if exists('s:instances[l:id]')
		call s:instance_reinit(l:id)
	elseif !s:instance_new(l:id) || !s:build_twice(l:id) ||
		\	!s:instance_setup_document_viewer(l:id)
		call s:instance_destroy(l:id)
	endif
endfunction " }}}

" Does a verbose build, and tries to fix the instance if we have no tmpdir.
" This function was intended to be called trough 'LatexPreviewRebuild' by
" the user.
function! s:rebuild_verbose(id) " {{{
	if !isdirectory(s:instances[a:id].tmpdir)
		call s:instance_reinit(a:id)
	else
		call s:build_verbose(a:id)
	endif
endfunction " }}}

" Copies the build output file of 'id' to 'path' and messages the user.
function! s:export_build_output(id, path) " {{{
	let l:error = system('cp ' . shellescape(s:instances[a:id].output_file)
		\	. ' ' . shellescape(a:path))

	if v:shell_error != 0
		echo l:error
		return
	endif

	let l:output_file = a:path

	if isdirectory(a:path)
		if a:path !~ '.*\/$'
			let l:output_file .= '/'
		endif

		let l:output_file .= fnamemodify(s:instances[a:id].output_file, ':t')
	endif

	call s:clear_echo("Exported '" . s:instances[a:id].filename
		\	. "' to '" . l:output_file . "'.")
endfunction " }}}

" Builds and exports the current buffer to 'path'. If this buffer has a
" working instance, it uses its output file. Otherwise it setups a
" temporary instance for just one build and destroys it afterwards.
function! latex_preview#export(path) " {{{
	let l:id = bufnr('%')

	if exists('s:instances[l:id]')
		call s:export_build_output(l:id, a:path)
	else
		if s:instance_new(l:id) && s:build_twice(l:id)
			call s:export_build_output(l:id, a:path)
		endif

		call s:instance_destroy(l:id)
	endif
endfunction " }}}

" Destroys each instance known to 'latex_preview'.
function! latex_preview#clean_up() " {{{
	for buf_id in keys(s:instances)
		call s:instance_destroy(buf_id)
	endfor
endfunction " }}}
