#!/bin/sh
qemu-system-x86_64 -kernel ./boot/bzImage -initrd initrd.img -nographic -append 'console=ttyS0'
