rm build/* &> /dev/null
sjasmplus -DPLUS3DOS main.asm

zmakebas -i 10 -s 10 -a 10 -l -p loader.bas -o build/loader.bas
zmakebas -i 10 -s 10 -a 10 -l -p debug-loader.bas -o build/debug-loader.bas

