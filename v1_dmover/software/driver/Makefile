ifneq ($(KERNELRELEASE),)
    obj-m	:= bm1_drv.o
else
KDIR	:= /lib/modules/$(shell uname -r)/build
PWD	:= $(shell pwd)
default:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules
endif
demo:
	gcc -o user_enc1 user_enc1.c
