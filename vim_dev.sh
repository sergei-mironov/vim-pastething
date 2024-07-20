#!/bin/sh

ROOT=`pwd`
exec vim -c "
if exists('g:loaded_vim_pastething')
  unlet g:loaded_vim_pastething
endif
let &runtimepath = '$ROOT,'.&runtimepath
runtime plugin/pastething.vim
runtime autoload/pastething.vim
runtime autoload/pastething/image.vim
" "$@"
