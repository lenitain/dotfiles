# backup <file>：原地留一份 <file>.bak 副本。

backup() {
    cp -- "$1" "$1.bak"
}
