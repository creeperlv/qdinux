# QDINUX

*Q*uick and *D*irty L*inux* distrubition for only quick boot in QEMU.

It is literally a toy distribution.

If you want something useful and minimal, I suggest you to use Tiny Core Linux.

# Build With Debian 12

You need gcc musl xz-utils bzip2 make flex bison bc yacc libelf-dev libssl-dev cpio

To start build automatically, just run `./build.sh`

# Run `qdinux`

By default, it builds the system for x86_64. Thus, you need qemu-system-x86_64 to run it.

To run in terminal, just run `./launch.sh`.

# What it contains?

- tcc
- LuaJIT
- busybox

# LICENSE

GPL V2 as this distribution uses linux kernel.
