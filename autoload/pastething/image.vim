
fun! pastething#image#check()
  if $WAYLAND_DISPLAY != "" && executable('wl-copy')
    let system_targets = "wl-paste --list-types"
  elseif $DISPLAY != '' && executable('xclip')
    let system_targets = 'xclip -selection clipboard -t TARGETS -o'
  else
    echoerr 'pastething: Needs xclip in X11 or wl-clipboard ' .
          \ 'in Wayland to check for clipboard images'
    return 0
  endif
  let targets = filter(systemlist(system_targets), 'v:val =~# ''image/''')
  if empty(targets)
    return 0
  else
    return 1
  endif
endf

fun! pastething#image#create_dir()
  if exists('g:pastething_image_dir')
    let dir = g:pastething_image_dir
  else
    let dir = "."
  endif
  if !isdirectory(dir)
      call mkdir(dir,"p",0700)
  endif
  return fnameescape(dir)
endf


fun! pastething#image#save(imgdir, tmpname) abort
  if $WAYLAND_DISPLAY != "" && executable('wl-copy')
    let system_targets = "wl-paste --list-types"
    let system_clip = "wl-paste --no-newline --type %s > %s"
  elseif $DISPLAY != '' && executable('xclip')
    let system_targets = 'xclip -selection clipboard -t TARGETS -o'
    let system_clip = 'xclip -selection clipboard -t %s -o > %s'
  else
    echoerr 'Needs xclip in X11 or wl-clipboard in Wayland.'
    return 1
  endif

  let targets = filter(systemlist(system_targets), 'v:val =~# ''image/''')
  if empty(targets) | return 1 | endif

  if index(targets, "image/png") >= 0
    " Use PNG if available
    let mimetype = "image/png"
    let extension = "png"
  else
    " Fallback
    let mimetype = targets[0]
    let extension = split(mimetype, '/')[-1]
  endif

  let tmpfile = a:imgdir . '/' . a:tmpname . '.' . extension
  call system(printf(system_clip, mimetype, tmpfile))
  return tmpfile
endfun


fun! pastething#image#name_input()
  call inputsave()
  let name = input('Image name: ')
  call inputrestore()
  " if empty(g:mdip_tmpname)
  "   throw 'Aborting due to empty image name'
  " endif
  return name
endfun


