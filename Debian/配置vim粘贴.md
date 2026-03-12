```
cat > /root/.vimrc <<EOF
if &term =~ "screen" || &term =~ "xterm"
    let &t_BE = "\e[?2004h"
    let &t_BD = "\e[?2004l"
    exec "set t_PS=\e[200h"
    exec "set t_PE=\e[201h"
endif
EOF
```
