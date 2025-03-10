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
        \ {->execute('Do '.a:args[len(split(a:args, ' ')[0]):], '')})
endfunction

function! dothen#_as_do(text)
  let command = split(a:text)
  if len(command) == 0
    return ''
  elseif command[0] == 'Do'
    return a:text
  elseif command[0] == 'Sh'
    return a:text
  elseif command[0] == 'Timer'
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
  let commands = split(a:args, g:dothen#sep)
  let callback = len(commands) > 1 ? dothen#_next_to_then(a:args) : ''
  if has('nvim')
    call jobstart(['sh', '-c', commands[0]],
        \{'on_exit': {j,d,e->execute([dothen#_as_do(callback)], '')},
        \'on_stdout': {j,d,e->dothen#_receive_nvim(d)}})
  else
    call job_start(commands[0],
        \{'close_cb': {x->execute([dothen#_as_do(callback)], '')},
        \'out_cb': function('dothen#_receive')})
  endif
endfunction

function! dothen#_putchar(char, line, col)
  let string = getline(a:line)
  if a:col <= 0
    call setline(a:line, a:char. string[len(a:char):])
  elseif len(getline(a:line)) > a:col
    let string = string[:a:col-1].a:char.string[a:col+len(a:char):]
    call setline(a:line, string)
  else
    call setline(a:line, string .repeat(' ',(a:col - len(string))) .a:char)
  endif
endfunction

function! PutLine(line, text)
  call setline(line('.') + a:line, a:text)
endfunction

function! PutLines(line, text)
  let put_line = a:line
  for t in a:text
    call setline(line('.') + put_line, t)
    let put_line = put_line + 1
  endfor
endfunction

function! FadeInText(line, text, col=0, sep=50)
  let time = 0
  let col = a:col
  let line = line('.') + a:line
  for t in a:text
    call dothen#_timer_func(time * a:sep,
          \['dothen#_putchar', t, line, col])
    let time = time + 1
    let col = col + len(t)
  endfor
endfunction

function! FadeInLines(line, texts, col=0, sep=50)
  let multi_line = a:line
  let wait_time = 0
  for text in a:texts
    call dothen#_timer_func(wait_time,
          \['FadeInText', multi_line, text, a:col, a:sep])
    let wait_time = wait_time + a:sep * strchars(text)
    let multi_line = multi_line + 1
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
