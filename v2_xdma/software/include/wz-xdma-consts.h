#ifndef WZ_XDMA_CONSTS_H
#define WZ_XDMA_CONSTS_H
//Size of a single DMA buffer (MUST BE A POWER OF 2!)
#define WZ_DMA_BUFLEN (4*1024*1024)
//Number of allocated DMA buffers (MUST BE A POWER OF 2!)
//Now we reduce the buffer area to 2GB!
#define WZ_DMA_NOFBUFS 512
//1024
#endif
