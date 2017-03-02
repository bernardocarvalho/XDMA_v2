#!/usr/bin/python
import fcntl
import mmap
import struct
import time
#Function for reading of control register
fu=open("/dev/wz-xdma0_user","rw+")
fc=open("/dev/wz-xdma0_control","rw+")
f=open("/dev/wz-xdma0_c2h_0","rw")
#How to create ioctl codes.?
#I can use f.fileno() or f (fileno will be called transparrently)
#Allocate buffers
#Free buffers
fcntl.ioctl(f,ord("q")<<8 | 10, 0)
#Allocate buffers
fcntl.ioctl(f,ord("q")<<8 | 7, 0)
#fcntl.ioctl(f,ord("q")<<8 | 11, 0)
m=mmap.mmap(f.fileno(),10*1024*1024,mmap.MAP_SHARED,mmap.PROT_READ,0)
mc=mmap.mmap(fc.fileno(),64*1024,mmap.MAP_SHARED,mmap.PROT_READ | mmap.PROT_WRITE,0)
mu=mmap.mmap(fu.fileno(),0x20000,mmap.MAP_SHARED,mmap.PROT_READ | mmap.PROT_WRITE,0)
def cr_read(ad):
   return struct.unpack("<L",mc[ad:ad+4])[0]

def cr_write(ad,val):
   mc[ad:ad+4] = struct.pack("<L",val)

def ur_read(ad):
   return struct.unpack("<L",mu[ad:ad+4])[0]

def ur_write(ad,val):
   mu[ad:ad+4] = struct.pack("<L",val)

#Make sure, that the mapping works
print m[0:100]
#Start the DMA
#fcntl.ioctl(f,ord("q")<<8 | 8, 0)
def take_data():
   # Restart source
   ur_write(0x10000,0)
   # Start DMA
   fcntl.ioctl(f,ord("q")<<8 | 8, 0)
   time.sleep(0.2)
   ur_write(0x10000,1)
   # Wait
   time.sleep(0.2)
   print [hex(ord(i)) for i in m[0:10]]
   time.sleep(0.2)
   print [hex(ord(i)) for i in m[0:10]]
   time.sleep(0.2)
   print [hex(ord(i)) for i in m[0:10]]
   time.sleep(0.2)
   print [hex(ord(i)) for i in m[0:10]]
   time.sleep(0.2)
   print [hex(ord(i)) for i in m[0:10]]
   time.sleep(0.2)
   print [hex(ord(i)) for i in m[0:10]]
   time.sleep(0.2)
   print [hex(ord(i)) for i in m[0:10]]
   time.sleep(0.2)
   print [hex(ord(i)) for i in m[0:10]]
   # Stop DMA
   print "DMA status:"+hex(cr_read(0x1040))
   fcntl.ioctl(f,ord("q")<<8 | 9, 0)

