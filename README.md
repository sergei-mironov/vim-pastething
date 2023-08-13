<!--
vim: spell
-->

Pastething
==========

This repository contains a VIM paste (yank) pre-processing plugin suitable for editing text markup
languages like Markdown or LaTeX.

Features
--------

The plugin provides custom `p` and `P` command handlers for normal, insert and visual mode. Users
are expected to invoke these handlers. The plugin then operates as follows:

1. Collects some information about the paste action:
   * The type of the content to be pasted. Currently the plugin distinguishes normal text,
     URLs and images (either `xclip` or `wl-paste` is required for images).
   * Potential annotation text (active visual selection text)
2. Maps the type of paste and the type of current file into the paste substitution pattern
   configured by users. Example of markdown pattern for images: `![%T%C](%U)` where `%T` stands for
   title, `%U` - for the URL and `%C` marks the cursor position after the paste is complete.
3. Substitutes the collected information into the pattern and actually pastes the result into the
   file. For images the plugin saves the actual image into a pre-configured directory and puts the
   path to the new file into the pattern.

Installation
------------

Put `./vim` into the Vim runtime search path by using your favorite Vim plugin manager.

Configuration
-------------

1. Overwrite [global options](./vim/plugin/pastething.vim):
   ``` vim
   let g:pastething_insert_eol = 1
   let g:pastething_image_enabled = 1
   let g:pastething_image_dir = 'img'
   ```

2. Setup the patterns for file types of interest.
   Example:
   * `./vim/ftplugin/markdown.vim`:
     ``` vim
     call g:pastething#pattern_set('markdown', g:pastething_type_url, "[%T%C](%U)")
     call g:pastething#pattern_set('markdown', g:pastething_type_img, "![%T%C](%U)")
     ```
   *  `./vim/ftplugin/tex.vim`:
     ``` vim
     call g:pastething#pattern_set('tex', g:pastething_type_url, "\\href{%U}{%T%C}")
     ```

3. Setup the paste command mappings:
   ``` vim
   nnoremap p :call pastething#paste_normal("p")<CR>
   nnoremap P :call pastething#paste_normal("P")<CR>
   vnoremap p :call pastething#paste_visual("p")<CR>
   inoremap <Esc>p <C-o>:call pastething#paste_insert("P")<CR>
   ```


