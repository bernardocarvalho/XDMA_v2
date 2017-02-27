/*
 * This file contains WZab's extensions to the xdma driver provided by Xilinx
 * All my extensions are published under GPL v2
 * Wojciech M. Zabolotny <wzab@ise.pw.edu.pl>
 */

static int char_sgdma_wz_mmap(struct file *filp, struct vm_area_struct *vma);
static int wz_engine_service_cyclic_interrupt(struct xdma_engine *engine);
static void wz_engine_destroy(struct xdma_engine *engine);

/* Functions supporting the ioctls */
static int ioctl_do_wz_alloc_buffers(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_start(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_stop(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_getbuf(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_confirm(struct xdma_engine *engine, unsigned long arg);
static int ioctl_do_wz_free_buffers(struct xdma_engine *engine, unsigned long arg);
