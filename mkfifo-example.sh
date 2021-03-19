#!/bin/sh

# owner of the running process
user=$(whoami)

# temporary directories we should try to use
tmpdir_candidates="$TMPDIR /tmp"

# sub-path to use under tmpdir for fifo files
sub_path="spack/fifos"


# Find a temporary directory, and ensure that the directory has the
# username in it to distinguish users on the same machine.
#
# usage: get_user_tmpdir mydir
#   finds or creates a user-specific  temporary direcotry and stores
#   it in $mydir
function get_user_tmpdir() {
    resultvar="$1"

    # find a temp directory that exists
    for dir in $tmpdir_candidates; do
        if [ ! -d $dir ]; then
            continue
        fi

        # if the username is not already in the temp path, add it
        if [ "${dir#*$user}" != "$dir" ]; then
            tmpdir="$dir"
        else
            tmpdir="$dir/$user"
        fi

        # add a sub-path at the end
        tmpdir="$tmpdir/$sub_path"

        # create the directory if it doesn't exist
        if [ ! -d $tmpdir ]; then
            mkdir -p $tmpdir
        fi
        eval $resultvar="$tmpdir"
        return
    done

    echo "Error: could not find a temporary directory."
    echo "Tried:"
    for dir in $tmpdir_candidates; do
        echo "  $dir"
    done
    exit 1
}

# get the FIFO path info SPACK_SHELL_FIFO
get_user_tmpdir user_tmpdir
export SPACK_SHELL_FIFO="$user_tmpdir/$$.fifo"

# make a fifo for this spack run
mkfifo -m 700 $SPACK_SHELL_FIFO
echo created $SPACK_SHELL_FIFO

# cleanup function will remove the fifo on exit
function cleanup {
    rm -f $SPACK_SHELL_FIFO
}
trap cleanup EXIT INT HUP QUIT TERM

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)"

# run the script (stand-in for spack), which will write to the FIFO,
# and save the PID so we can wait on it later.
$script_dir/writefifo.py &
writefifo_pid=$!

# We want to read from the fifo while spack is running (in particular,
# the write on the spack side needs to happen after we've tried to read,
# so we want to do this quickly so that Spack doesn't have to wait long)
# With python startup time, this always seems to happen first but you
# never know.
read -r line < $SPACK_SHELL_FIFO

# echo what we read out of the fifo
echo $line

# now wait for it to finish (should be immediately after write)
# and return the error value from spack.
wait $writefifo_pid
exit $?
