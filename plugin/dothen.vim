scriptencoding utf-8
" vimslide
" Last Change:	2024 Nov 25
" Maintainer:	Shoichiro Nakanishi <sheepwing@kyudai.jp>
" License:	Mit licence

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_vimslide')
  finish
endif

let g:dothen#sep = 'Then'
command! -nargs=1 Do call Do(<f-args>)

function! dothen#_wrapper_func(x, y)
  call function(a:x[0], a:x[1:])()
endfunction

function! dothen#_timer(time, args)
  return timer_start(a:time,
        \{->execute([a:args], '')})
endfunction

function! dothen#_timer_func(time, args)
  return timer_start(a:time, 'dothen#_wrapper_func'->function([a:args]))
endfunction

function! dothen#_next_to_then(args)
    return dothen#_as_do(a:args[len(split(a:args, g:dothen#sep)[0]) + len(g:dothen#sep):])
endfunction

function! Do(args)
  exec split(a:args, g:dothen#sep)[0]
  if len(split(a:args, g:dothen#sep)) > 1
    exec dothen#_as_do(dothen#_next_to_then(a:args))
  endif
endfunction

function! Timer(args)
  if len(split(a:args, ' '))==0
    return
  endif
  call timer_start(split(a:args, ' ')[0],
        \ {->execute(a:args[len(split(a:args, ' ')[0]):], '')})
endfunction

function! dothen#_as_do(text)
  let s:command = split(a:text)
  if len(s:command) == 0
    return ''
  elseif s:command[0] == 'Do'
    return a:text
  elseif s:command[0] == 'Sh'
    return a:text
  elseif s:command[0] == 'Timer'
    return a:text
  endif
  return 'Do '.a:text
endfunction


function! dothen#_receive(x, y)
  call insert(g:DothenBuffer, ch_read(a:x))
endfunction

function! dothen#_receive_nvim(x)
  let g:DothenBuffer = g:DothenBuffer + a:x
endfunction

func! Sh(args)
  let g:DothenBuffer = []
  let s:commands = split(a:args, g:dothen#sep)
  let s:callback = len(s:commands) > 1 ? dothen#_next_to_then(a:args) : ''
  if has('nvim')
    call jobstart(['sh', '-c', s:commands[0]],
        \{'on_exit': {j,d,e->([dothen#_as_do(s:callback)])},
        \'on_stdout': {j,d,e->dothen#_receive_nvim(d)}})
  else
    call job_start(s:commands[0],
        \{'close_cb': {x->execute([dothen#_as_do(s:callback)], '')},
        \'out_cb': function('dothen#_receive')})
  endif
endfunction

function! dothen#_putchar(char, line, col)
  let s:string = getline(a:line)
  if a:col <= 0
    call setline(a:line, a:char. s:string[len(a:char):])
  elseif len(getline(a:line)) > a:col
    let s:string = s:string[:a:col-1].a:char.s:string[a:col+len(a:char):]
    call setline(a:line, s:string)
  else
    call setline(a:line, s:string .repeat(' ',(a:col - len(s:string))) .a:char)
  endif
endfunction

function! PutLine(line, text)
  call setline(line('.') + a:line, a:text)
endfunction

function! PutLines(line, text)
  let s:put_line = a:line
  for t in a:text
    call setline(line('.') + s:put_line, t)
    let s:put_line = s:put_line + 1
  endfor
endfunction

function! FadeInText(line, text, col=0, sep=50)
  let s:time = 0
  let s:col = a:col
  let s:line = line('.') + a:line
  for t in a:text
    call dothen#_timer_func(s:time * a:sep,
          \['dothen#_putchar', t, s:line, s:col])
    let s:time = s:time + 1
    let s:col = s:col + len(t)
  endfor
endfunction

function! FadeInLines(line, texts, col=0, sep=50)
  let s:multi_line = a:line
  let s:wait_time = 0
  for text in a:texts
    call dothen#_timer_func(s:wait_time,
          \['FadeInText', s:multi_line, text, a:col, a:sep])
    let s:wait_time = s:wait_time + a:sep * strchars(text)
    let s:multi_line = s:multi_line + 1
  endfor
endfunction

function! FadeInPage(name, sep=50)
  call PutLines(0, repeat([''], len(a:name)))
  call FadeInLines(0, a:name, 0, a:sep)
endfunction

command! -nargs=1 FadeInPage call FadeInPage(<args>)
command! -nargs=1 FadeInLines call FadeInLines(<f-args>)
command! -nargs=1 Sh call Sh(<f-args>)
command! -nargs=1 Timer call Timer(<f-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
