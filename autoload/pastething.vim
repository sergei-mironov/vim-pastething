if exists("g:loaded_vim_pastething")
  finish
endif

let g:pastething_type_url = "url"
let g:pastething_type_img = "img"
let g:pastething_type_other = "other"

if !exists("g:pastething_ftpatterns")
  let g:pastething_ftpatterns = {}
endif

fun! pastething#get_visual_selection() range
  let [line_start, column_start] = getcharpos("'<")[1:2]
  let [line_end, column_end] = getcharpos("'>")[1:2]
  let lines = getline(line_start, line_end)
  if len(lines) == 0
      return ""
  endif
  let lines[-1] = strcharpart(lines[-1], 0, column_end - (&selection == 'inclusive' ? 0 : 1))
  let lines[0] = strcharpart(lines[0], column_start - 1)
  return lines
endfun

fun! pastething#get_url_title(url, hint) range
  return a:hint
  " return substitute(a:hint, '\n', '', 'g')
endfun

fun! pastething#classify(val, hint) range
  let hint = a:hint
  let val = a:val

  let vmatch = val =~ '^https\?://'
  let hmatch = hint =~ '^https\?://'
  let isimg = g:pastething_image_enabled == 1 ? pastething#image#check() : 0

  if isimg
    return {"t":g:pastething_type_img, "title":hint}
  elseif vmatch && !hmatch
    return {"t":g:pastething_type_url,
           \"text":val,
           \"title":pastething#get_url_title(val, hint)}
  elseif hmatch && !vmatch
    return {"t":g:pastething_type_url,
           \"text":hint,
           \"title":pastething#get_url_title(hint, val)}
  else
    return {"t":g:pastething_type_other, "text":a:val}
  endif
endfun

fun! pastething#pattern_cursor_offset(pattern) range
  return match(a:pattern, '%C')
endfun

fun! pastething#expand_pattern(val, patterns, hint) range
  let obj = pastething#classify(a:val, a:hint)
  if obj['t'] == g:pastething_type_other
    return {'res':obj['text'], 'coff':-1}
  elseif obj['t'] == g:pastething_type_url
    let pattern = get(a:patterns, obj["t"], "%U")
    let pattern = substitute(pattern, "%T", obj["title"], '')
    let pattern = substitute(pattern, "%U", obj["text"], '')
    let coff = pastething#pattern_cursor_offset(pattern)
    let res = substitute(pattern, "%C", '', '')
    return {'res':res, 'coff':coff}
  elseif obj['t'] == g:pastething_type_img
    let pattern = get(a:patterns, obj["t"], "%U")
    let pattern = substitute(pattern, "%T", obj["title"], '')
    let pattern = substitute(pattern, "%U",
                \            pastething#image#save(pastething#image#create_dir(),
                \                                  pastething#image#name_input(),
                \                                  "<invalid_image_path>"), '')
    let coff = pastething#pattern_cursor_offset(pattern)
    let res = substitute(pattern, "%C", '', '')
    return {'res':res, 'coff':coff}
  else
    throw "Unknown classify result: " . string(obj)
  endif
endfun

fun! pastething#paste_normal_pattern(cmd, patterns) range
  let reg = v:register
  if reg ==# "\""
    let reg = "+"
  endif
  let cmd = a:cmd
  let rt = getregtype(reg)
  let val = getreg(reg)
  if rt ==# 'v'
    let exp = pastething#expand_pattern(val, a:patterns, '')
    let pos = getcurpos()
    let paste_start = pos[2]
    if g:pastething_insert_leading_spaces == 1
      if paste_start == 1 && paste_start != pos[4]
        if pos[4] < v:maxcol
          let exp["res"] = repeat(' ',pos[4]-1).exp["res"]
          let paste_start = pos[4]
        endif
      else
        if paste_start > 1 && cmd ==# "p"
          let paste_start = paste_start + 1
        endif
      endif
    endif
    call setreg(reg, exp["res"])
    execute "normal! \"".reg.cmd
    if exp['coff']>=0
      " echomsg "pos=".string(pos)."; paste_start=".string(paste_start)
      call setpos('.', [pos[0],pos[1],paste_start+exp['coff'],pos[3]])
    endif
    call setreg(reg ,val)
  else
    let exp = val
    execute "normal! \"".reg.cmd
  endif
  return exp
endfun

fun! pastething#paste_visual_pattern(cmd, patterns) range
  let m = visualmode()
  let reg = v:register
  if reg ==# "\""
    let reg = "+"
  endif
  let cmd = a:cmd
  let cadd = 0
  let selection = join(pastething#get_visual_selection(),"\n")
  let val = getreg(reg)

  if m == 'v'
    let exp = pastething#expand_pattern(val, a:patterns, selection)
    call setreg(reg, exp["res"])
    let pos = getpos("'<")
    execute "normal! gv\"".reg.cmd
    if exp['coff']>=0
      call setpos('.', [pos[0],pos[1],pos[2]+exp['coff']+cadd,pos[3]])
    endif
    call setreg(reg ,val)
  else
    let exp = val
    execute "normal! gv\"".reg.cmd
  endif
  return exp
endfun

fun! pastething#paste_insert_pattern(cmd, patterns) range
  if exists("g:pastething_insert_eol")
    throw "Variable g:pastething_insert_eol is no longer supported"
  endif
  let pos = getcurpos()
  let cmd = a:cmd
  if pos[2] != pos[4]
    let cmd = g:pastething_insert_after_eol_command
  endif
  let exp = pastething#paste_normal_pattern(cmd, a:patterns)
  if g:pastething_insert_after_eol_move_right == 1 && pos[2] != pos[4]
    " Move cursor is after the end-of-line
    execute "normal $"
  endif
  return exp
endfun

fun! pastething#pattern_set(ftype, vtype, pattern)
  let ftdict = get(g:pastething_ftpatterns, a:ftype, {})
  let ftdict[a:vtype] = a:pattern
  let g:pastething_ftpatterns[a:ftype] = ftdict
endfun

fun! pastething#pattern_set_buffer(vtype, pattern)
  if ! exists("b:pastething_patterns")
    let b:pastething_patterns = {}
  endif
  let b:pastething_patterns[a:vtype] = a:pattern
endfun

fun! pastething#patterns_get()
  return get(g:pastething_ftpatterns, &filetype, {})
endfun

fun! pastething#patterns_has(key)
  return get(get(g:pastething_ftpatterns, &filetype, {}), a:key, 0) != 0
endfun

fun! pastething#patterns_combine()
  let patterns = get(g:pastething_ftpatterns, &filetype, {})
  if exists("b:pastething_patterns")
    for key in keys(b:pastething_patterns)
      let patterns[key] = get(b:pastething_patterns, key, '')
    endfor
  endif
  return patterns
endfun

fun! pastething#paste_normal(cmd) range
  call pastething#paste_normal_pattern(
        \ a:cmd, pastething#patterns_combine())
endfun

fun! pastething#paste_insert(cmd) range
  call pastething#paste_insert_pattern(
        \ a:cmd, pastething#patterns_combine())
endfun

fun! pastething#paste_visual(cmd) range
  call pastething#paste_visual_pattern(
        \ a:cmd, pastething#patterns_combine())
endfun

let g:loaded_vim_pastething = 1

