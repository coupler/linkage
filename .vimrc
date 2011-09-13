function! s:AlternateFile()
  let fn = substitute(expand('%'), "^".getcwd()."/", "", "")
  let head = fnamemodify(fn, ':h')
  let tail = fnamemodify(fn, ':t')

  if match(head, '^lib') >= 0
    return substitute(head, '^lib/linkage', 'test/unit', '').'/test_'.tail
  elseif match(head, '^test') >= 0
    return substitute(head, '^test/unit', 'lib/linkage', '').'/'.substitute(tail, '^test_', '', '')
  endif
  return ''
endfunction

function! s:Alternate(cmd)
  let file = s:AlternateFile()
  "if file != '' && filereadable(file)
    if a:cmd == 'T'
      let cmd = 'tabe'
    elseif a:cmd == 'S'
      let cmd = 'sp'
    else
      let cmd = 'e'
    endif
    exe ':'.cmd.' '.file
  "else
    "echomsg 'No alternate file is defined: '.file
  "endif
endfunction

command! A  :call s:Alternate('')
command! AE :call s:Alternate('E')
command! AS :call s:Alternate('S')
command! AV :call s:Alternate('V')
command! AT :call s:Alternate('T')
