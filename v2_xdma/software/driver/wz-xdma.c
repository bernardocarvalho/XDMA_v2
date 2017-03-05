/*
 * This file contains WZab's extensions to the xdma driver provided by Xilinx
 * All my extensions are published under GPL v2
 * Wojciech M. Zabolotny <wzab@ise.pw.edu.pl>
 * 
 * This file will be included in the original xdma-core.c to make maintenace easier
 */
#define WZ_TRANSFER_CYCLIC 1
 
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
  int res=0;
  struct wz_xdma_engine_ext * ext;
  ext = &engine->wz_ext;
  init_waitqueue_head(&ext->getbuf_wq);
  //We allocate the buffers using dmam_alloc_noncoherent, so the user space
  //application may use cache.
  //pci_set_consistent_dma_mask(engine->lro->pci_dev, DMA_BIT_MASK(64));
  for(i=0;i<WZ_DMA_NOFBUFS;i++) {
    ext->buf_addr[i] = dmam_alloc_noncoherent(&engine->lro->pci_dev->dev,
					      WZ_DMA_BUFLEN, &ext->buf_dma_t[i],GFP_USER);
    printk(KERN_INFO "Allocated buffer: virt=%llx, dma=%llx\n",(u64) ext->buf_addr[i],(u64) ext->buf_dma_t[i]);                
    if(ext->buf_addr[i] == NULL) {
      res = -ENOMEM;
      goto err1;
    }
    //Make buffer ready for filling by the device
    dma_sync_single_range_for_device(&engine->lro->pci_dev->dev, 
				     ext->buf_dma_t[i],0,WZ_DMA_BUFLEN,DMA_FROM_DEVICE);
  }
  //pci_set_consistent_dma_mask(engine->lro->pci_dev, DMA_BIT_MASK(32));
  //Alloc the memory for copy of descriptors
  ext->desc_copy = (struct xdma_desc *) vmalloc(WZ_DMA_NOFBUFS*sizeof(struct xdma_desc));
  if(!ext->desc_copy) {
    printk(KERN_ERR "I can't allocate copies of descriptors\n");
    res = -ENOMEM;		
    goto err1;
  }
  //Here we also allocate kfifo - very pesimistic variant - number
  //of entries equal to number of buffers...
  spin_lock_init(&ext->kfifo_lock);
  ext->kfifo = kfifo_alloc(WZ_DMA_NOFBUFS*sizeof(struct wz_xdma_data_block_desc), GFP_KERNEL, &ext->kfifo_lock);
  if(IS_ERR(ext->kfifo)) {
    res = PTR_ERR(ext->kfifo);
    goto err1;
  }
  ext->buf_ready = 1;
  return 0;
 err1:
  //pci_set_consistent_dma_mask(engine->lro->pci_dev, DMA_BIT_MASK(32));
  //Free already allocated buffers
  for(i=0;i<WZ_DMA_NOFBUFS;i++) {
    if(ext->buf_addr[i]) {
      dmam_free_noncoherent(&engine->lro->pci_dev->dev,
			    WZ_DMA_BUFLEN, ext->buf_addr[i], ext->buf_dma_t[i]);
      ext->buf_addr[i] = NULL;
    }
  }
  if(ext->desc_copy) {
    vfree(ext->desc_copy);
    ext->desc_copy = NULL;
  }
  ext->buf_ready = 0;
  return res;
}

static int ioctl_do_wz_free_buffers(struct xdma_engine *engine, unsigned long arg) 
{
  int i;
  struct wz_xdma_engine_ext * ext;
  ext = &engine->wz_ext;
  printk(KERN_INFO "Starting to free buffers\n");
  if(ext->buf_ready) {
    for(i=0;i<WZ_DMA_NOFBUFS;i++) {
      dmam_free_noncoherent(&engine->lro->pci_dev->dev,
			    WZ_DMA_BUFLEN, ext->buf_addr[i], ext->buf_dma_t[i]);        
    }
  }
  if(ext->kfifo) {
    kfifo_free(ext->kfifo);
    ext->kfifo = NULL;
  }	
  ext->buf_ready = 0;
  if(ext->desc_copy) {
    vfree(ext->desc_copy);
    ext->desc_copy = NULL;
  }
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
    return -EINVAL;
  }
  ext->block_first_desc=0;
  ext->block_scanned_desc=0;
  //First build the XDMA transfer descriptors
  desc_first = xdma_desc_alloc(engine->lro->pci_dev,WZ_DMA_NOFBUFS,
			       &desc_first_dma_t, &desc_last);
  if(!desc_first) {
    printk(KERN_ERR "I can't allocate descriptors\n");
    return -ENOMEM;
  }
#ifdef WZ_TRANSFER_CYCLIC
  //Later we will need to make the transfer cyclic, but now it is commented out.
  xdma_desc_link(desc_last, desc_first, desc_first_dma_t); 
#endif
  //Fill the descriptors with data of our buffers.
  //Allocation of the writeback buffer is removed!
  //we will use the descriptor area for that purpose, to implement the 
  //hardware-based overrun protection, as described in
  // https://forums.xilinx.com/t5/PCI-Express/DMA-Bridge-Subsystem-for-PCI-Express-v3-0-usage-in-cyclic-mode/m-p/751088#M8456
  /* ext->writeback = dmam_alloc_coherent(&engine->lro->pci_dev->dev,
     sizeof(uint64_t)*WZ_DMA_NOFBUFS, &ext->writeback_dma_t,GFP_KERNEL);
     if(!ext->writeback) {
     printk(KERN_ERR "I can't allocate writeback buffer\n");
     return -EFAULT;
     }
  */
  desc = desc_first;
  for (i=0;i<WZ_DMA_NOFBUFS;i++){
    xdma_desc_set(&desc[i],ext->buf_dma_t[i],desc_first_dma_t+i*sizeof(struct xdma_desc),WZ_DMA_BUFLEN,0);
    control = 0; //XDMA_DESC_EOP;
    control |= XDMA_DESC_COMPLETED;
    xdma_desc_control(&desc[i], control);
    //Copy the descriptor, so that it can be restored after writeback!
    memcpy(&ext->desc_copy[i],&desc[i],sizeof(struct xdma_desc));
  }
  //Now we should prepare a copy of descriptors (as writeback destroys them!)
	
  //Set STOP flag in the last descriptor
  //xdma_desc_control_set(&desc[WZ_DMA_NOFBUFS-1],XDMA_DESC_STOPPED);
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
  ext->transfer->cyclic = 0;
#ifdef WZ_TRANSFER_CYCLIC
  ext->transfer->cyclic = 1;
#endif
  /* initialize wait queue */
  init_waitqueue_head(&ext->transfer->wq);
  //Start the transfer
  printk(KERN_INFO "Starting transfer\n");
  transfer_queue(engine, ext->transfer);
  //engine_start(engine);
  return 0;
};

static int ioctl_do_wz_confirm(struct xdma_engine *engine, unsigned long arg)
{
  struct wz_xdma_engine_ext * ext;
  struct wz_xdma_data_block_confirm db_conf;
  int res;
  int i;
  ext = &engine->wz_ext;
  res = copy_from_user(&db_conf,(void __user *) arg,sizeof(struct wz_xdma_data_block_confirm));
  if(res) {
    printk(KERN_ERR "Couldn't copy the confirmation descriptor\n");
    return -EINVAL;
  }
  //Check if the numbers are reasonable
  if((db_conf.first_desc < 0) ||
     (db_conf.first_desc >= WZ_DMA_NOFBUFS) ||
     (db_conf.last_desc < 0) ||
     (db_conf.last_desc >= WZ_DMA_NOFBUFS)) {
    printk(KERN_ERR "Incorrect buffer numbers in the confirmation description: first:%d last:%d should be between 0 and %d",
	   db_conf.first_desc, db_conf.last_desc, WZ_DMA_NOFBUFS);
  }
  //Confirm descriptors by rewriting info overwritten by writeback
  i=db_conf.first_desc;
  while(true) {
    //Ensure, that the buffer is synchronized for device
    dma_sync_single_range_for_device(&engine->lro->pci_dev->dev, 
				     ext->buf_dma_t[i],0,WZ_DMA_BUFLEN,DMA_FROM_DEVICE);
    //Restore the descriptor so, that the control word with MAGIC is written as the last!
    ext->transfer->desc_virt[i].bytes = ext->desc_copy[i].bytes;
    ext->transfer->desc_virt[i].src_addr_lo = ext->desc_copy[i].src_addr_lo;
    ext->transfer->desc_virt[i].src_addr_hi = ext->desc_copy[i].src_addr_hi;
    ext->transfer->desc_virt[i].dst_addr_lo = ext->desc_copy[i].dst_addr_lo;
    ext->transfer->desc_virt[i].dst_addr_hi = ext->desc_copy[i].dst_addr_hi;
    ext->transfer->desc_virt[i].next_lo = ext->desc_copy[i].next_lo;
    ext->transfer->desc_virt[i].next_hi = ext->desc_copy[i].next_hi;
    mb();
    ext->transfer->desc_virt[i].control = ext->desc_copy[i].control;
    mb();
    if (i == db_conf.last_desc) break;
    i = (i+1) & (WZ_DMA_NOFBUFS - 1);
  } 
  return 0;
}

static int ioctl_do_wz_stop(struct xdma_engine *engine, unsigned long arg)
{
  struct wz_xdma_engine_ext * ext;
  int res;
  ext = &engine->wz_ext;
  //Stop the transfer (?Should it be done?)
  //xdma_engine_stop(engine);
  spin_lock(&engine->lock); //Sources say that it should be called with lock taken
  engine_cyclic_stop(engine);
  spin_unlock(&engine->lock);
  //wait until engine stops
  res = wait_event_interruptible(engine->shutdown_wq, !engine->running);
  if (res) {
    printk(KERN_ERR "wz_stop: wait_event_interruptible=%d\n", res);
    return res;
  }
  if (engine->running) {
    printk(KERN_ERR "wz_stop: engine still running?!\n");
    return -EINVAL;
  }
  //Clear the transfer descriptors
  spin_lock(&engine->lock);
  if(ext->transfer) transfer_destroy(engine->lro, ext->transfer);
  ext->transfer = NULL;
  spin_unlock(&engine->lock);
  //Free the writeback buffers - commented out - no writeback buffers now!
  //dmam_free_coherent(&engine->lro->pci_dev->dev,
  //	sizeof(uint64_t)*WZ_DMA_NOFBUFS, ext->writeback, ext->writeback_dma_t);
  //ext->writeback = NULL;
  //ext->writeback_dma_t = 0;
  return 0;
};

//Now, after remake of cyclic interrupt, the getbuf function gets really simple
//We only check if there is a new block descriptor in the FIFO, and if there is
//we return it to the application.

static int ioctl_do_wz_getbuf(struct xdma_engine *engine, unsigned long arg)
{
  int res;
  struct wz_xdma_data_block_desc db_desc;
  struct wz_xdma_engine_ext * ext;
  ext = &engine->wz_ext;
  //To recover blocks, that were not reported due to FIFO overload,
  //it would be good to rescan the descriptors here by calling the:
  //wz_engine_service_cyclic_interrupt
  //However, it is not clear if it can be called outside the 
  //interrupt context...
  res = wait_event_interruptible(ext->getbuf_wq, 
				 (kfifo_len(ext->kfifo) >= sizeof(struct wz_xdma_data_block_desc))
				 || !engine->running);
  if(res<0) return res;
  if(!engine->running) return -EIO;
  //Now we can be sure, that there is buffer ready to service
  res = kfifo_get(ext->kfifo,(unsigned char *)&db_desc, sizeof(struct wz_xdma_data_block_desc));
  if (res < sizeof(struct wz_xdma_data_block_desc)) {
    printk(KERN_ERR "It should never happen! FIFO corruption?");
    return -EINVAL;
  }
  res = copy_to_user((void __user *)arg, &db_desc,
		     sizeof(struct wz_xdma_data_block_desc));
  if (res) {
    printk(KERN_ERR "Error copying result to user\n");
    return -EINVAL;
  }
  return 0;
};
// No !!! The above design is wrong!!! I don't want to traverse the descriptors' list twice!
// Once, counting the EOPs, and the second time, assembling the blocks!
// Therefore, assembling of blocks is moved to the service interrupt.
// Results are stored in FIFO (problematic, because 2.6.32 still requires the old
// and unconvenient FIFO interface)

// If the KFIFO is filled, it would be good to rescan the received buffers
// even if no new interrupt is received. Is it possible to call the function below
// from the getbuf???

//The function below is a modified copy of engine_transfer_dequeue
//(reference to rx_transfer_cyclic is removed)
static void wz_engine_transfer_dequeue(struct xdma_engine *engine)
{
  struct wz_xdma_engine_ext * ext;
  struct xdma_transfer *transfer;

  BUG_ON(!engine);
  ext = &engine->wz_ext;

  /* pick first transfer on the queue (was submitted to the engine) */
  transfer = list_entry(engine->transfer_list.next, struct xdma_transfer,
			entry);
  BUG_ON(!transfer);
  BUG_ON(transfer != ext->transfer);
  dbg_tfr("%s engine completed cyclic transfer 0x%p (%d desc).\n",
	  engine->name, transfer, transfer->desc_num);
  /* remove completed transfer from list */
  list_del(engine->transfer_list.next);
}

//The function below is called after the interupt
static int wz_engine_service_cyclic_interrupt(struct xdma_engine *engine)
{
  struct wz_xdma_engine_ext * ext;
  struct wz_xdma_data_block_desc db_desc;
  int check_desc;
  int res;
  BUG_ON(!engine);
  BUG_ON(engine->magic != MAGIC_ENGINE);
  engine_status_read(engine,1);
  ext = &engine->wz_ext;
  //We start scanning from the last scanned descriptor
  check_desc = ext->block_scanned_desc;
  while(true) {
    struct xdma_desc * cur_desc;
    struct xdma_result * cur_res;
    cur_desc = &ext->transfer->desc_virt[check_desc];
    cur_res = (struct xdma_result *) cur_desc;
    if(((cur_res->status >> 16) & 0xffff) !=  C2H_WB) {
      //This descriptor does not contain writeback MAGIC
      //All received descriptors are processed
      ext->block_scanned_desc = check_desc;
      break; 
    }
    //Ensure, that the buffer is synchronized for CPU
    dma_sync_single_range_for_cpu(&engine->lro->pci_dev->dev, 
				  ext->buf_dma_t[check_desc],0,WZ_DMA_BUFLEN,DMA_FROM_DEVICE);
    //Check if EOP is set in this descriptor
    if( cur_res->status & 1 ) {
      //This is the last packet in the block!
      db_desc.first_desc = ext->block_first_desc;
      db_desc.last_desc = check_desc;
      db_desc.last_len = cur_res->length;
      //Copy it to the FIFO if there is enough space
      if((ext->kfifo->size - kfifo_len(ext->kfifo)) >= 
	 sizeof(struct wz_xdma_data_block_desc)) {
	res = kfifo_put(ext->kfifo,(const unsigned char *) &db_desc,
			sizeof(struct wz_xdma_data_block_desc));
	//Block reported, shift the pointer to the first buffer of assembled block
	check_desc = (check_desc + 1) & (WZ_DMA_NOFBUFS - 1);
	ext->block_first_desc = check_desc; //The next block MUST start in the next descriptor!
	ext->block_scanned_desc = check_desc;
	//Wake up readers!
	wake_up_interruptible(&ext->getbuf_wq);
      } else {
	// The block has been assembled, but there is no free space in FIFO
	// we have to postpone scanning and repeat it next time (may be the FIFO
	// will be emptied?)
	break;
      }
    } else {
      //Only shift the pointer to the scanned descriptor
      check_desc = (check_desc + 1) & (WZ_DMA_NOFBUFS - 1);
    }
  }
  /* engine was running but is no longer busy? */
  if ((engine->running) && !(engine->status & XDMA_STAT_BUSY)) {
    /* transfers on queue? */
    if (!list_empty(&engine->transfer_list))
      wz_engine_transfer_dequeue(engine);

    engine_service_shutdown(engine);
    wake_up_interruptible(&ext->getbuf_wq); //Last chance to wakeup readers!
  }
  return 0;
}

//Function below is called when the XDMA engine is released
static void wz_engine_cleanup(struct xdma_engine *engine)
{
  //We rely on the fact, that those particular ioctl handlers do not access the file object, so they may 
  //be called even when the file is already closed!
  //If it is not a true any more, the handlers must be split between the file dependend part 
  //and the separate clean-up function that can be called both - from the ioctl and here.
  ioctl_do_wz_stop(engine, 0L);
  ioctl_do_wz_free_buffers(engine,0L);
}
