# `mkfifo` example

This is a simple demonstrator for how to:

1. create a fifo using `mkfifo` in a shell script
2. launch a Python process that knows about the FIFO (via an env var)
3. receive data from the Python process on the shell side

We want to use this to avoid the dance that Spack currently does around
commands with shell support.

With this, any command could have shell support (it would just need to
write appropriate shell commands to the FIFO), and Spack's setup scripts
could be much shorter -- they would not need to parse the command line,
and we would not have to maintain parsing code for multiple shells.
