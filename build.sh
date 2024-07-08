#!/bin/sh

BUILD_ROOT=$(pwd)
KRL_VER=6.9.8
BBX_VER=1.36.1
KRL_MAJOR=6
mkdir -p src
mkdir -p rootfs
ROOTFS=$(pwd)/rootfs
BOOTDIR=$(pwd)/boot
mkdir -p $BOOTDIR
mkdir -p rootfs/bin
mkdir -p rootfs/usr
mkdir -p rootfs/usr/local
mkdir -p rootfs/usr/local/bin
cd src
if [ -z $SKIP_KERNEL ];
then
	echo "Build Kernel"
	if [ -z $SKIP_DOWNLOAD_KERNEL ];
	then
		if [ -z $KERNEL_ORG ];
		then
			KERNEL_ORG=https://mirrors.edge.kernel.org/pub/linux
		fi
		wget $KERNEL_ORG/kernel/v$KRL_MAJOR.x/linux-$KRL_VER.tar.xz -O linux.tar.xz
	fi
	tar -xf linux.tar.xz
	cd linux-$KRL_VER
	make defconfig
	make -j -s || exit
	cd ..
fi

cp linux-$KRL_VER/arch/x86_64/boot/bzImage $BOOTDIR

if [ -z $SKIP_BUSYBOX ];
then
	echo "Build Busybox"
	if [ -z $SKIP_BUSYBOX_DL ];
	then
		wget https://www.busybox.net/downloads/busybox-$BBX_VER.tar.bz2 -O busybox.tar.bz2
		tar -xf busybox.tar.bz2
	fi
	cd busybox-$BBX_VER
	make defconfig
	sed 's/^.*CONFIG_STATIC[^_].*$/CONFIG_STATIC=y/g' -i .config
	make -j8 busybox -s || exit
	cp ./busybox ../../rootfs/bin
	cd ..
fi

if [ -z $NO_TCC ];
then
	if [ -z $SKIP_TCC ];
	then
		#wget http://download.savannah.gnu.org/releases/tinycc/tcc-0.9.27.tar.bz2
		#tar -xf tcc-0.9.27.tar.bz2
		git clone https://github.com/TinyCC/tinycc.git

		if [ -d ./tccbin ]; 
		then
		rm ./tccbin -rf
		fi
		cd tinycc
		./configure --prefix=../../rootfs/usr/local --sysroot=/usr/local/ --exec-prefix=../../rootfs/usr/local --extra-cflags="-static" --extra-ldflags="-static" --enable-static
		make -j -s
		#make test
		make install -s
		cd ..
	fi
fi

if [ -z "$NO_LUAJIT" ];
then
	git clone https://luajit.org/git/luajit.git
	cd luajit
	sed '/BUILDMODE=/c\BUILDMODE=static' -i ./src/Makefile
	CC=musl-gcc DESTDIR=$ROOTFS LDFLAGS="-static" make -j
	CC=musl-gcc DESTDIR=$ROOTFS LDFLAGS="-static" make install
	cd ..
fi

echo "Make initrd"
cd ../rootfs
mkdir -p bin dev proc sys etc home
cp ../default-etc/profile ./etc/
cp ../default-etc/passwd ./etc/
cp ../default-etc/shadow ./etc/
cd bin
for prog in $(./busybox --list); do
ln -s /bin/busybox ./$prog
done
cd ..
echo "#!/bin/sh" > init
echo "mount -t sysfs sysfs /sys" >> init
echo "mount -t proc proc /proc" >> init
echo "mount -t devtmpfs udev /dev" >> init
echo "sysctl -w kernel.printk='2 4 1 7'" >> init
echo "export ENV=\"/etc/profile\"" >> init
echo "hostname qdinux" >> init
echo "echo \"root:root\"|chpasswd" >> init
echo "clear" >> init
echo "login" >> init
echo "poweroff -f" >> init
chmod -R 777 .
find . | cpio -o -H newc > ../initrd.img 
cd ..
