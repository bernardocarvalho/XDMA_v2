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
    uint64_t * writeback;
    dma_addr_t writeback_dma_t;
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

//Structures used to notify the application about the received block of data
//The block always starts at the first descriptor, and may and in the middle 
//of the last descriptor. Hence the structure describing the block consists
//Of three fields.
//
// Important fact: The information about the filled blocks is stored in the
// descriptors. It is extracted from there only when the GETBLOCK is called!
struct wz_xdma_data_block_desc{
	uint32_t first_desc;
	uint32_t last_desc;
	uint32_t last_len;
} __packed; 

//When the application confirms, that the data have been processed, it
//sends only the numbers of the first and the last block
struct wz_xdma_data_block_confirm {
	uint32_t first_desc;
	uint32_t last_desc;
} __packed;
//We also need means to monitor the number of free buffers.
//It is unclear if that data can be easily produced. (e.g.
//iterating through the list of descriptors is a bad idea).
//Because our list of descriptors is allocated as a continuous
//memory area, maybe we can rely on the address of the currently 
//processed descriptor?
//To be decided soon!
