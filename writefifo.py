#!/usr/bin/env python3

import os
import sys
import time

fifo_path = os.environ["SPACK_SHELL_FIFO"]
print("Spack found fifo:", fifo_path)

fifo_fd = None
tries = 0
while tries < 10 and not fifo_fd:
    try:
        tries +=1
        fifo_fd = os.open(fifo_path, os.O_WRONLY | os.O_NONBLOCK)
        print("success after %d tries!" % tries)
        break
    except OSError:
        print(tries)
        time.sleep(.001)
else:
    print("failed to open fifo!")
    sys.exit(1)

os.write(fifo_fd, b"THIS CAME THROUGH THE FIFO!")
