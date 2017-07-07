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
