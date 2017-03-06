/*
 * This file contains WZab's extensions to the xdma driver provided by Xilinx
 * All my extensions are published under GPL v2
 * Wojciech M. Zabolotny <wzab@ise.pw.edu.pl>
 */
#ifndef WZ_XDMA_H
#define WZ_XDMA_H 1
#include <linux/kfifo.h>
#include <wz-xdma-consts.h>
#include <wz-xdma-ioctl.h>
#include <wz-kernel-versions.h>
struct xdma_engine;

struct wz_xdma_engine_ext{
    int nof_bufs; // Number of DMA buffers
    dma_addr_t buf_dma_t[WZ_DMA_NOFBUFS];
    struct page * buf_page[WZ_DMA_NOFBUFS];
    //uint64_t * writeback;
    //dma_addr_t writeback_dma_t;
    struct xdma_transfer *transfer;
    struct xdma_desc * desc_copy;
    struct xdma_desc * desc[WZ_DMA_NOFBUFS];
    dma_addr_t desc_dma[WZ_DMA_NOFBUFS];
    uint8_t buf_ready;
    //Fields used to keep track of the filled blocks
    int eop_count;
    int desc_head; //The descriptor that is being filled with the data
    int desc_tail; //The last descriptor that has been freed for transmission
    int block_first_desc;
    int block_scanned_desc;
    #if  LINUX_VERSION_CODE < KERNEL_VER_KFIFO1
    spinlock_t kfifo_lock;
    struct kfifo * kfifo;
    #else
    STRUCT_KFIFO_PTR(struct  wz_xdma_data_block_desc) kfifo;
    #endif
    wait_queue_head_t getbuf_wq;
};

#endif
