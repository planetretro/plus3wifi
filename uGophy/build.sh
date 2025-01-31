#!/bin/sh
rm build/* &> /dev/null
sjasmplus -DPLUS3DOS main.asm
zmakebas -i 10 -s 10 -a 10 -l -p loader.bas -o build/loader.bas

