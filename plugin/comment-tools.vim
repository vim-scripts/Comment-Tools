" comment-tools.vim -- Manipulate Comments
" File: "/home/johannes/prj/vim/comment-tools/comment-tools.vim"
" 
" Maintainer: Johannes Tanzler <johannes.tanzler@aon.at>
" Version:    1.0
" 
" Created: Thu, 22 May 2003 11:45:48 +0200
" Last Modification: "Tue, 10 Jun 2003 10:53:56 +0200 (johannes)"
 
" Copyright (C) 2003  by Johannes Tanzler <johannes.tanzler@aon.at> {{{
"
" This library is free software; you can redistribute it and/or
" modify it under the terms of the GNU Lesser General Public
" License as published by the Free Software Foundation; either
" version 2 of the License, or (at your option) any later version.
"
" This library is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
" Lesser General Public License for more details.
"
" You should have received a copy of the GNU Lesser General Public
" License along with this library; if not, write to the Free Software
" Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
"
" }}}


if exists("did_comment_tools")
    finish
end
let did_comment_tools = 1

if !exists("g:CommentTools_Column")
    let g:CommentTools_Column = 40
endif

function! s:AppendComment()
    ruby << EOF
    require 'vim/vim-ruby'
    require 'vim/comment-tools'
    $curbuf.append_comment($curwin.line, VIM::evaluate("g:CommentTools_Column"))
EOF
endfunction

function! s:FormatComment() range
    ruby << EOF
    require 'vim/comment-tools'
    $curbuf.format_comments(VIM::evaluate("a:firstline"), VIM::evaluate("a:lastline"))
EOF
endfunction

" function! s:KillComments()
"     ruby << EOF
"     require 'vim/comment-tools'
"     $curbuf.kill_comment($curwin.line)
" EOF
" endfunction

" Key bindings:
noremap  <Plug>AppendComment :call <SID>AppendComment()<CR>
nmap <silent> <M-;> <Plug>AppendComment
nmap <silent> <Leader>; <Plug>AppendComment
imap <silent> <M-;> <Esc><Plug>AppendComment
imap <silent> <Leader>; <Esc><Plug>AppendComment

vnoremap <Plug>FormatComment :call <SID>FormatComment()<CR>
vmap <silent> <Leader>; <Plug>FormatComment()
vmap <silent> <M-;> <Plug>FormatComment()

" Functions
" command KillComments :call <SID>KillComments()
