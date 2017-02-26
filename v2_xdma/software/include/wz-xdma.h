/*
 * This file contains WZab's extensions to the xdma driver provided by Xilinx
 * All my extensions are published under GPL v2
 * Wojciech M. Zabolotny <wzab@ise.pw.edu.pl>
 */

//Size of a single DMA buffer (MUST BE A POWER OF 2!)
#define WZ_DMA_BUFLEN (4*1024*1024)
//Number of allocated DMA buffers (MUST BE A POWER OF 2!)
#define WZ_DMA_NOFBUFS 32
//1024
#include <linux/kfifo.h>
struct xdma_engine;

struct wz_xdma_engine_ext{
    int nof_bufs; // Number of DMA buffers
    dma_addr_t buf_dma_t[WZ_DMA_NOFBUFS];
    void * buf_addr[WZ_DMA_NOFBUFS];
    //uint64_t * writeback;
    //dma_addr_t writeback_dma_t;
    struct xdma_transfer *transfer;
    struct xdma_desc * desc_copy;
    uint8_t buf_ready;
    //Fields used to keep track of the filled blocks
    int eop_count;
    int desc_head; //The descriptor that is being filled with the data
    int desc_tail; //The last descriptor that has been freed for transmission
    int block_first_desc;
    int block_scanned_desc;
    spinlock_t kfifo_lock;
    struct kfifo * kfifo;
};

