
fun! pastething#image#exepath(path, name) abort
  if a:path != v:null && len(a:path)>0
    return a:path
  elseif executable(a:name)
    return exepath(a:name)
  else
    return v:null
  endif
endfun

fun! pastething#image#getcliptools() abort
  let system_targets = v:null
  let system_clip = v:null
  if $WAYLAND_DISPLAY != ""
    let p = pastething#image#exepath(g:pastething_wlpaste_path, 'wl-paste')
    if p
      let system_targets = p . " --list-types"
      let system_clip = p . " --no-newline --type %s > %s"
    endif
  elseif $DISPLAY != ''
    let p = pastething#image#exepath(g:pastething_xclip_path, 'xclip')
    let system_targets = p .' -selection clipboard -t TARGETS -o'
    let system_clip = p . ' -selection clipboard -t %s -o > %s'
  endif
  return [system_targets, system_clip]
endfun

fun! pastething#image#check() abort
  let [system_targets, system_clip] = pastething#image#getcliptools()
  if system_clip == v:null || system_targets == v:null
    echoerr 'Needs xclip in X11 or wl-clipboard in Wayland.'
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

fun! pastething#image#save(imgdir, tmpname, def) abort
  let [system_targets, system_clip] = pastething#image#getcliptools()
  if system_clip == v:null || system_targets == v:null
    echoerr 'Needs xclip in X11 or wl-clipboard in Wayland.'
    return a:def
  endif

  let targets = filter(systemlist(system_targets), 'v:val =~# ''image/''')
  if empty(targets) | return a:def | endif

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


