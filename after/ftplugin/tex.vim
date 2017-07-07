" Copyright (c) 2017 Alexander Heinrich {{{
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

command! -buffer LatexPreview call latex_preview#preview()
command! -buffer -nargs=1 -complete=file LatexPreviewExport
  \  call latex_preview#export('<args>')

if exists('g:loaded_latex_preview')
  finish
endif
let g:loaded_latex_preview = 1

if !exists('*mkdir')
  echomsg "'mkdir' is not supported on your system"
  finish
endif

if !exists('g:latex_preview#document_viewer') " {{{
  for document_viewer in [ 'evince', 'okular', 'zathura', 'qpdfview' ]
    if executable(document_viewer) == 1
      let g:latex_preview#document_viewer = document_viewer
      break
    endif
  endfor

  if !exists('g:latex_preview#document_viewer')
    echomsg 'No supported document viewer was found on your system.'
    echomsg "You need to set 'g:latex_preview#document_viewer' manually"
    echomsg 'to a document viewer, that supports auto-reloading if the'
    echomsg 'document changes.'

    finish
  endif
endif " }}}
if !exists('g:latex_preview#compiler') " {{{
  if executable('pdflatex') != 1
    echomsg "'pdflatex' not found. Please set"
      \ . " 'g:latex_preview#compiler' to a valid"
    echomsg "program and make sure 'g:Latex_preview#get_compiler_args'"
      \ . " is set properly."

    finish
  endif

  let g:latex_preview#compiler = 'pdflatex'
endif " }}}
if !exists('g:latex_preview#compiler_args') " {{{
  let g:latex_preview#compiler_args = ''
endif " }}}

function! s:get_compiler_args(build_info) " {{{
  return '-output-directory ' . shellescape(a:build_info.tmpdir)
    \ . ' -interaction=nonstopmode ' . g:latex_preview#compiler_args
    \ . ' ' . shellescape(a:build_info.tmpdir . expand('%:t'))
endfunction " }}}
function! s:get_output_file(build_info) " {{{
  return a:build_info.tmpdir . expand('%:t:r') . '.pdf'
endfunction " }}}

if !exists('*g:Latex_preview#get_compiler_args')
  let g:Latex_preview#get_compiler_args = function('s:get_compiler_args')
endif

if !exists('*g:Latex_preview#get_output_file')
  let g:Latex_preview#get_output_file = function('s:get_output_file')
endif

if !exists('g:latex_preview#rebuild_events')
  let g:latex_preview#rebuild_events = 'BufWritePost'
endif

if !exists('g:latex_preview#least_delay')
  let g:latex_preview#least_delay = '0'
endif

augroup latex_preview " {{{
  autocmd!
  autocmd VimLeavePre * call latex_preview#clean_up()
augroup END " }}}
