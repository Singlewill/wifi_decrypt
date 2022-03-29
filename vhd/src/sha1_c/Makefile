#! /bin/sh
OBJECT=sha1-internal.o   main.o
TARGET=sha1_test

export STAGING_DIR=""
#CC="/home/ll/src/openwrt/wndr4300/staging_dir/toolchain-mips_34kc_gcc-5.2.0_musl-1.1.11/bin/mips-openwrt-linux-musl-gcc"
#LD="/home/ll/src/openwrt/wndr4300/staging_dir/toolchain-mips_34kc_gcc-5.2.0_musl-1.1.11/bin/mips-openwrt-linux-musl-gcc"
CCFLAGS="-static"
LDFLAGS="-static"
CC=gcc
LD=gcc


all: $(TARGET)

$(TARGET): $(OBJECT)
	$(LD) $(OBJECT) -o $(TARGET) $(LDFLAGS)

%.o : %.c
	$(CC) $(CCFLAGS) -c -o $@ $<


clean:
	rm $(TARGET) $(OBJECT) -rf

