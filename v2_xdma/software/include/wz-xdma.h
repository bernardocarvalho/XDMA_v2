/*
 * This file contains WZab's extensions to the xdma driver provided by Xilinx
 * All my extensions are published under GPL v2
 * Wojciech M. Zabolotny <wzab@ise.pw.edu.pl>
 */
 
//Size of a single DMA buffer
#define WZ_DMA_BUFLEN (4*1024*1024)
//Number of allocated DMA buffers
#define WZ_DMA_NOFBUFS 1024

struct xdma_engine;

struct wz_xdma_engine_ext{
    int nof_bufs; // Number of DMA buffers
    dma_addr_t buf_dma_t[WZ_DMA_NOFBUFS];
    void * buf_addr[WZ_DMA_NOFBUFS];
    uint8_t buf_ready;
};


static int char_sgdma_wz_mmap(struct file *filp, struct vm_area_struct *vma);

/* Functions supporting the ioctls */
static int ioctl_do_wz_alloc_buffers(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_start(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_stop(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_getbuf(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_free_buffers(struct xdma_engine *engine, unsigned long arg);
