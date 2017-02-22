/*
 * This file contains WZab's extensions to the xdma driver provided by Xilinx
 * All my extensions are published under GPL v2
 * Wojciech M. Zabolotny <wzab@ise.pw.edu.pl>
 * 
 * This file will be included in the original xdma-core.c to make maintenace easier
 */
 
 
/* Mapping of the allocated buffers */  
void swz_mmap_open(struct vm_area_struct *vma)
{
}
 
void swz_mmap_close(struct vm_area_struct *vma)
{
}
 
static int swz_mmap_fault(struct vm_area_struct *vma, struct vm_fault *vmf)
{
    long offset;
    struct xdma_char *xchar = NULL;
    char * buffer = NULL;
    int buf_num = 0;
    xchar = (struct xdma_char *) vma->vm_private_data;
    //Calculate the offset (according to info in 
    // https://lxr.missinglinkelectronics.com/linux+v2.6.32/drivers/gpu/drm/i915/i915_gem.c#L1195
    // it is better not ot use the vmf->pgoff )
    printk(KERN_INFO "Fault virt: %llx, start of vma: %llx\n", (u64) vmf->virtual_address, (u64) vma->vm_start);
    offset = (unsigned long)(vmf->virtual_address - vma->vm_start);
    //Calculate the buffer number
    buf_num = offset/WZ_DMA_BUFLEN;
    //Check if the resulting number is not higher than the number of allocated buffers
    if(buf_num > WZ_DMA_NOFBUFS) {
        printk(KERN_ERR "Access outside the buffer\n");
        return -EFAULT;
    }
    //Calculate the offset inside the buffer
    offset = offset - buf_num * WZ_DMA_BUFLEN;
    buffer = xchar->engine->wz_ext.buf_addr[buf_num];
    //Get the pfn of the buffer
    vm_insert_pfn(vma,(unsigned long)(vmf->virtual_address),virt_to_phys(&buffer[offset]) >> PAGE_SHIFT);         
    return VM_FAULT_NOPAGE;
}
 
struct vm_operations_struct swz_mmap_vm_ops =
{
    .open =     swz_mmap_open,
    .close =    swz_mmap_close,
    .fault =    swz_mmap_fault,    
};


static int char_sgdma_wz_mmap(struct file *file, struct vm_area_struct *vma)
{
    struct xdma_char * xchar;
    xchar = (struct xdma_char *) file->private_data;
    //Check if the buffers are allocated
    if(!xchar->engine->wz_ext.buf_ready) {
        printk(KERN_ERR "Can't mmap when buffers are not allocated\n");
        return -EINVAL;    
    }
    vma->vm_ops = &swz_mmap_vm_ops;
    vma->vm_flags |= VM_IO | VM_RESERVED | VM_CAN_NONLINEAR | VM_PFNMAP;
    //file->private data contains the pointer to the xdma_char
    vma->vm_private_data = file->private_data;
    swz_mmap_open(vma);
    return 0;
}


/* Functions supporting the ioctls */
static int ioctl_do_wz_alloc_buffers(struct xdma_engine *engine, unsigned long arg) 
{
    int i;
    struct wz_xdma_engine_ext * ext;
    ext = &engine->wz_ext;
    //We allocate the buffers using dmam_alloc_noncoherent, so the user space
    //application may use cache.
    for(i=0;i<WZ_DMA_NOFBUFS;i++) {
        ext->buf_addr[i] = dmam_alloc_noncoherent(&engine->lro->pci_dev->dev,
                WZ_DMA_BUFLEN, &ext->buf_dma_t[i],GFP_USER);
				printk(KERN_INFO "Allocated buffer: virt=%llx, dma=%llx\n",(u64) ext->buf_addr[i],(u64) ext->buf_dma_t[i]);                
        if(ext->buf_addr[i] == NULL) {
            int j;
            //Free already allocated buffers
            for(j=0;j<i;j++) {
                dma_free_noncoherent(&engine->lro->pci_dev->dev,
                WZ_DMA_BUFLEN, ext->buf_addr[i], ext->buf_dma_t[i]);
            }
            ext->buf_ready = 0;
            return -ENOMEM;
        }
    }
    ext->buf_ready = 1;
    return 0;
}

static int ioctl_do_wz_free_buffers(struct xdma_engine *engine, unsigned long arg) 
{
    int i;
    struct wz_xdma_engine_ext * ext;
    ext = &engine->wz_ext;
  	printk(KERN_INFO "Starting to free buffers\n");
    if(ext->buf_ready) {
		for(i=0;i<WZ_DMA_NOFBUFS;i++) {
			dma_free_noncoherent(&engine->lro->pci_dev->dev,
			WZ_DMA_BUFLEN, ext->buf_addr[i], ext->buf_dma_t[i]);        
		}
    }
    ext->buf_ready = 0;
  	printk(KERN_INFO "All buffers freed\n");
  	return 0;
}

/* 
 * At the moment it is unclear, how we can handle interrupts. It seems, that the 
 * interrupt handling scheme in xdma is quite complex and relying on it may impact
 * the performance... 
 * However we need to get the quick verification of the concept first.
 */
  

static int ioctl_do_wz_start(struct xdma_engine *engine, unsigned long arg)
{
    int i;
    struct wz_xdma_engine_ext * ext;
    struct xdma_desc * desc;
    struct xdma_desc * desc_first;
    struct xdma_desc * desc_last;
	uint32_t control;
    dma_addr_t desc_first_dma_t;

    ext = &engine->wz_ext;
	if(! ext->buf_ready) {
        printk(KERN_ERR "I can't start transfer if buffers are not allocated\n");
        return -EFAULT;
	}
    //First build the XDMA transfer descriptors
    desc_first = xdma_desc_alloc(engine->lro->pci_dev,WZ_DMA_NOFBUFS,
			&desc_first_dma_t, &desc_last);
	if(!desc_first) {
        printk(KERN_ERR "I can't allocate descriptors\n");
        return -EFAULT;
	}
	//Later we will need to make the transfer cyclic, but now it is commented out.
	// xdma_desc_link(ext->xdma_desc_last, ext->xdma_desc, ext->xdma_desc_addr_t); 
    //Fill the descriptors with data of our buffers.
	//Alloc the writeback buffer
	ext->writeback = dmam_alloc_coherent(&engine->lro->pci_dev->dev,
                sizeof(uint64_t)*WZ_DMA_NOFBUFS, &ext->writeback_dma_t,GFP_KERNEL);
    if(!ext->writeback) {
        printk(KERN_ERR "I can't allocate writeback buffer\n");
        return -EFAULT;
	}
    desc = desc_first;
    for (i=0;i<WZ_DMA_NOFBUFS;i++){
		xdma_desc_set(&desc[i],ext->buf_dma_t[i],ext->writeback_dma_t+i*sizeof(uint64_t),WZ_DMA_BUFLEN,0);
		control = XDMA_DESC_EOP;
		//control |= XDMA_DESC_COMPLETED;
		xdma_desc_control(&desc[i], control);
	}
    //Set STOP flag in the last descriptor
    xdma_desc_control_set(&desc[WZ_DMA_NOFBUFS-1],XDMA_DESC_STOPPED);
	printk(KERN_INFO "Descriptors filled\n");
    //@@@ Maybe the above should be moved to alloc_buffers???
    //Submmit the whole descriptor list (how?!)
    //We simply imitate the transfer building 
    ext->transfer = kzalloc(sizeof(struct xdma_transfer), GFP_KERNEL);
    if(!ext->transfer) {
		xdma_desc_free(engine->lro->pci_dev,WZ_DMA_NOFBUFS,
			desc_first, desc_first_dma_t);
        printk(KERN_ERR "I can't start transfer if buffers are not allocated\n");
        return -ENOMEM;
	}
	ext->transfer->desc_virt = desc_first;
	ext->transfer->desc_bus = desc_first_dma_t;
	ext->transfer->desc_adjacent = 0;
	ext->transfer->desc_num = WZ_DMA_NOFBUFS;
	ext->transfer->dir_to_dev = 0;
	ext->transfer->sgl_nents = 1;
	ext->transfer->cyclic = 0; //At the moment! To be changed later!
    //Start the transfer
	printk(KERN_INFO "Starting transfer\n");
    transfer_queue(engine, ext->transfer);
    //engine_start(engine);
    return 0;
};

static int ioctl_do_wz_stop(struct xdma_engine *engine, unsigned long arg)
{
    struct wz_xdma_engine_ext * ext;
    struct xdma_desc * desc;
    ext = &engine->wz_ext;
    //Stop the transfer
    xdma_engine_stop(engine);
    //engine_cyclic_stop(engine);
    //Clear the transfer descriptors
    transfer_destroy(engine->lro, ext->transfer);
    ext->transfer = NULL;
    //Free the writeback buffers
    dmam_free_coherent(&engine->lro->pci_dev->dev,
		sizeof(uint64_t)*WZ_DMA_NOFBUFS, ext->writeback, ext->writeback_dma_t);
	ext->writeback = NULL;
	ext->writeback_dma_t = 0;
    return 0;
};

static int ioctl_do_wz_getbuf(struct xdma_engine *engine, unsigned long arg)
{
	return -EINVAL;
};
