#ifndef WZ_XDMA_CONSTS_H
#define WZ_XDMA_CONSTS_H
//Size of a single DMA buffer (MUST BE A POWER OF 2!)
#define WZ_DMA_BUFLEN (2*1024*1024)
//Number of allocated DMA buffers (MUST BE A POWER OF 2!)
//Now we try to use the whole buffer set - 4GB!
#define WZ_DMA_NOFBUFS 256
//1024
#endif
