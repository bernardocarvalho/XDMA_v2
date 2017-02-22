#!/usr/bin/python
import fcntl
import mmap
fu=open("/dev/wz-xdma0_user","rw+")
f=open("/dev/wz-xdma0_c2h_0","rw")
#How to create ioctl codes.?
#I can use f.fileno() or f (fileno will be called transparrently)
#Allocate buffers
fcntl.ioctl(f,ord("q")<<8 | 7, 0)
#fcntl.ioctl(f,ord("q")<<8 | 11, 0)
m=mmap.mmap(f.fileno(),10*1024*1024,mmap.MAP_SHARED,mmap.PROT_READ,0)
mu=mmap.mmap(fu.fileno(),0x20000,mmap.MAP_SHARED,mmap.PROT_READ | mmap.PROT_WRITE,0)
add=0x10000
#Switch on the data source
mu[add:(add+4)]="\00\00\00\00"
mu[add:(add+4)]="\01\00\00\00"
#Make sure, that the mapping works
print m[0:100]
#Start the DMA
#fcntl.ioctl(f,ord("q")<<8 | 8, 0)

