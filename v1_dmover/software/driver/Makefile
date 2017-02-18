ifneq ($(KERNELRELEASE),)
    obj-m	:= ax_dma1.o
else
KDIR	:= /lib/modules/$(shell uname -r)/build
PWD	:= $(shell pwd)
default:
	$(MAKE) -C $(KDIR) SUBDIRS=$(PWD) modules
endif
demo:
	gcc -o user_enc1 user_enc1.c
