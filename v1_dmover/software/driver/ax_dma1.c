/* Quick and dirty WZAB PCIe Bus Mastering device driver
 * for Artix
 * Copyright (C) 2017 by Wojciech M. Zabolotny
 * wzab<at>ise.pw.edu.pl
 * Significantly based on multiple drivers included in
 * sources of Linux
 * Therefore this source is licensed under GPL v2
 * Driver is written so, that it should be compatible 
 * even with ancient 2.6.xx kernels
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <asm/uaccess.h>
MODULE_LICENSE("GPL v2");
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/sched.h>
#include <linux/mm.h>
#include <linux/pci.h>
#include <asm/io.h>
#include <linux/interrupt.h>
#include <asm/uaccess.h>

//PCI IDs below are not registred! Use only for experiments!
#define PCI_VENDOR_ID_WZAB 0x32ab
#define PCI_DEVICE_ID_WZAB_BM1 0x7014
//Address layout at the PCI side:
//RES0 - PER_REGS (1MB)
//RES1 - AXI_CTL (16KB)
//RES2 - BRAM 4MB (really 1MB)

static DEFINE_PCI_DEVICE_TABLE(tst1_pci_tbl) = {
  {PCI_VENDOR_ID_WZAB, PCI_DEVICE_ID_WZAB_BM1, PCI_ANY_ID, PCI_ANY_ID, 0, 0, 0 },
  {0,}
};
MODULE_DEVICE_TABLE(pci, tst1_pci_tbl);

#define SUCCESS 0
#define DEVICE_NAME "wzab_axs1"

#define N_OF_RES (3)
//Our device contains three BARs
//The first one is the PCI core register file
#define PCI_REGS (0)
//The second one is the GPIO area (with "start" GPIO at 0x10000)
#define GPIO_REGS (1)
//The third one is the AXI_STREAM_FIFO
#define DMOV_REGS (2)
//Structure describing the status of the WZAB_AXS1 device
struct axs1_ctx{
	struct pci_dev * pdev;
	uint32_t * gpio_regs;
    uint32_t * pci_regs;
    uint32_t * dmov_regs;
	resource_size_t mmio_start[N_OF_RES];
	resource_size_t mmio_end[N_OF_RES];
    resource_size_t mmio_flags[N_OF_RES];
    resource_size_t mmio_len[N_OF_RES];
}
#define DMA_SIZE 4*1024*1024

inline static struct axs1_ctx * axs1_ctx_alloc()
{
	axs1_ctx * ctx = kzalloc(sizeof(struct axs1_ctx), GFP_KERNEL);
}

inline static void axs1_ctx_free(axs1_ctx * ctx)
{
	if(ctx->pdev) { //ctx is linked, so check for resources, that must be freed
		if(ctx->gpio_regs) iounmap(ctx->gpio_regs);
		if(ctx->pci_regs) iounmap(ctx->pci_regs);
		if(ctx->dmov_regs) iounmap(ctx->dmov_regs);
	}
	kfree(ctx);
}

static void * dmabuf = NULL;
static dma_addr_t dmaaddr = 0;

//It is a dirty trick, but we can service only one device :-(
static struct pci_dev * my_pdev = NULL;

void cleanup_tst1( void );
void cleanup_tst1( void );
int init_tst1( void );
static int tst1_open(struct inode *inode, struct file *file);
static int tst1_release(struct inode *inode, struct file *file);
ssize_t tst1_read(struct file *filp,
		  char __user *buf,size_t count, loff_t *off);
ssize_t tst1_write(struct file *filp,
		   const char __user *buf,size_t count, loff_t *off);
loff_t tst1_llseek(struct file *filp, loff_t off, int origin);

int tst1_mmap(struct file *filp, struct vm_area_struct *vma);

dev_t my_dev=0;
struct cdev * my_cdev = NULL;
static struct class *class_my_tst = NULL;

struct file_operations Fops = {
  .owner = THIS_MODULE,
  //.read=tst1_read, /* read */
  .write=tst1_write, /* write */
  .open=tst1_open,
  .release=tst1_release,  /* a.k.a. close */
  .llseek=no_llseek,
  .mmap=tst1_mmap
};


ssize_t tst1_write(struct file *filp, const char __user *buf,size_t count, loff_t *off)
{
  uint32_t val;
  if (count != 4) return -EINVAL; //Only 4-byte access allowed
  __copy_from_user(&val,buf,4);
  return -EINVAL;
}

/* Cleanup resources */
void tst1_remove(struct pci_dev *pdev )
{
  if (dmabuf) {
      dma_free_coherent(&pdev->dev, DMA_SIZE, dmabuf, dmaaddr);
  }
  if(my_dev && class_my_tst) {
    device_destroy(class_my_tst,my_dev);
  }
  if(fmem) {
      iounmap(fmem);
      fmem = NULL;
  }
  if(fmem2) {
      iounmap(fmem2);
      fmem2 = NULL;
  }
  if(my_cdev) cdev_del(my_cdev);
  my_cdev=NULL;
  unregister_chrdev_region(my_dev, 1);
  if(class_my_tst) {
    class_destroy(class_my_tst);
    class_my_tst=NULL;
  }
  pci_release_regions(pdev);
  pci_disable_device(pdev);
  //printk("<1>drv_tst1 removed!\n");
  if(my_pdev == pdev) {
      printk(KERN_INFO "Device %p removed !\n", pdev);
      my_pdev = NULL;
  }
}

static int tst1_open(struct inode *inode, 
		     struct file *file)
{
  int res=0;
  nonseekable_open(inode, file);
  return SUCCESS;
}

static int tst1_release(struct inode *inode, 
			struct file *file)
{
  return SUCCESS;
}

void tst1_vma_open (struct vm_area_struct * area)
{  }

void tst1_vma_close (struct vm_area_struct * area)
{  }

static struct vm_operations_struct tst1_vm_ops = {
  .open=tst1_vma_open,
  .close=tst1_vma_close,
};

int tst1_mmap(struct file *filp,
	      struct vm_area_struct *vma)
{
  unsigned long physical;
  unsigned long vsize;
  unsigned long psize;
  int res;
  unsigned long off = vma->vm_pgoff;
  vsize = vma->vm_end - vma->vm_start;
  if((off<0) || (off>N_OF_RES)) return -EINVAL;
  if(off==N_OF_RES) {
      //Map the DMA buffer
      if(vsize>DMA_SIZE)
         return -EINVAL;
      #ifdef ARCH_HAS_DMA_MMAP_COHERENT
       printk(KERN_INFO "Mapping with dma_map_coherent DMA buffer at phys: %p virt %p\n",dmaaddr,dmabuf);
       res = dma_mmap_coherent(&my_pdev->dev, vma, dmabuf, dmaaddr,  vsize);
      #else
       physical = virt_to_phys(dmabuf);
       //Added basing on http://4q8.de/?p=231
       //vma->vm_flags |= VM_IO;
       //vma->vm_page_prot=pgprot_noncached(vma->vm_page_prot);
       //END
       printk(KERN_INFO "Mapping with remap_pfn_range DMA buffer at phys: %p virt %p\n",physical,dmabuf);
       res = remap_pfn_range(vma,vma->vm_start, physical >> PAGE_SHIFT , vsize, vma->vm_page_prot);       
      #endif
       if(res==0) {
           printk(KERN_INFO "Mapped DMA buffer at phys: %p\n",dmaaddr);
       }
      return res;
  } else {
    physical = mmio_start[res_nums[off]];
    psize = mmio_len[res_nums[off]];
    if(vsize>psize)
        return -EINVAL;
    //Added basing on http://4q8.de/?p=231
    vma->vm_flags |= VM_IO;
    vma->vm_page_prot=pgprot_noncached(vma->vm_page_prot);
    //END
    remap_pfn_range(vma,vma->vm_start, physical >> PAGE_SHIFT , vsize, vma->vm_page_prot);
    if (vma->vm_ops)
        return -EINVAL; //It should never happen
    vma->vm_ops = &tst1_vm_ops;
    tst1_vma_open(vma); //This time no open(vma) was called
    //printk("<1>mmap of registers succeeded!\n");
    return 0;
  };
}

static int tst1_probe(struct pci_dev *pdev, const struct pci_device_id *ent)
{
  struct axs1_ctx * ctx = NULL;
  int res = 0;
  int i ;
  res =  pci_enable_device(pdev);
  if (res) {
    dev_err(&pdev->dev, "Can't enable PCI device, aborting\n");
    res = -ENODEV;
    goto err1;
  }
  ctx = axs1_ctx_alloc();
  if (ctx==NULL) {
    dev_err(&pdev->dev, "Can't allocate context for PCI device, aborting\n");
    res = -ENOMEM;
    goto err1;
  }
  ctx->pdev = pdev; //Link ctx with the device
  pci_set_drvdata(pdev,ctx); //Link device with the ctx
  //Now read the resources
  for(i=0;i<N_OF_RES;i++) {
    ctx->mmio_start[i] = pci_resource_start(pdev, res_nums[i]);
    ctx->mmio_end[i] = pci_resource_end(pdev, res_nums[i]);
    ctx->mmio_flags[i] = pci_resource_flags(pdev, res_nums[i]);
    ctx->mmio_len[i] = pci_resource_len(pdev, res_nums[i]);
    printk(KERN_INFO "Resource: %d start:%llx, end:%llx, flags:%llx, len=%llx\n",
        i,ctx->mmio_start[i],ctx->mmio_end[i], ctx->mmio_flags[i], ctx->mmio_len[i]);
    if (!(ctx->mmio_flags[i] & IORESOURCE_MEM)) {
        dev_err(&pdev->dev, "region %i not an MMIO resource, aborting\n",i);
        res = -ENODEV;
        goto err1;
    }
  }
  if (!pci_set_dma_mask(pdev, DMA_BIT_MASK(64))) {
    if (pci_set_consistent_dma_mask(pdev, DMA_BIT_MASK(64))) {
        dev_info(&pdev->dev,
           "Unable to obtain 64bit DMA for consistent allocations\n");
              goto err1;
        }
    }
  //Let's allocate the buffer for BM DMA
  ctx->dmabuf=dma_alloc_coherent(&pdev->dev,DMA_SIZE,&ctx->dmaaddr,GFP_USER);
  if(ctx->dmabuf==NULL) {
      printk(KERN_INFO "I can't allocate the DMA buffer\n");
      res = -ENOMEM;
      goto err1;
  }
  printk(KERN_INFO "Allocated DMA buffer at phys: %p virt %p\n",ctx->dmaaddr,ctx->dmabuf);
  res = pci_request_regions(pdev, DEVICE_NAME);
  if (res)
    goto err1;
  pci_set_master(pdev);
  /* Let's check if the register block is read correctly */
  ctx->pci_regs = ioremap(mmio_start[PCI_REGS],mmio_len[PCI_REGS]);
  if(ctx->pci_regs) {
    printk ("<1>Mapping of memory for %s PCI registers failed\n",
	    DEVICE_NAME);
    res= -ENOMEM;
    goto err1;
  }
  //The first register should return our PCI_ID
  {
      uint32_t pci_id = PCI_VENDOR_ID_WZAB |  (PCI_DEVICE_ID_WZAB_BM1 << 16);
      if(*(ctx->pci_regs) != pci_id) {
          dev_info(&pdev->dev, "Not accessible registers BAR? expected id: %lx, read id: %lx\n",pci_id, *(ctx->pci_regs));
          goto err1;
      }
  }  
  //Now we can program the location of DMA buffer to the AXIBAR2PCIEBAR
  ctx->pci_regs[0x208/4]=(ctx->dmaaddr >> 32);
  ctx->pci_regs[0x20c/4]=(ctx->dmaaddr & 0xFFffFFff);
  //Map AXI connected registers
  ctx->gpio_regs = ioremap(mmio_start[GPIO_REGS],mmio_len[GPIO_REGS]);
  if(!ctx->gpio_regs) {
    printk ("<1>Mapping of memory for %s GPIO registers failed\n",
	    DEVICE_NAME);
    res= -ENOMEM;
    goto err1;
  }
  //Map FIFO control registers
  ctx->fifo_regs = ioremap(mmio_start[FIFO_REGS],mmio_len[FIFO_REGS]);
  if(!ctx->fifo_regs) {
    printk ("<1>Mapping of memory for %s FIFO registers failed\n",
	    DEVICE_NAME);
    res= -ENOMEM;
    goto err1;
  }
  //Create the class
  class_my_tst = class_create(THIS_MODULE, "my_enc_class");
  if (IS_ERR(class_my_tst)) {
    printk(KERN_ERR "Error creating my_tst class.\n");
    res=PTR_ERR(class_my_tst);
    goto err1;
  }
  /* Alocate device number */
  res=alloc_chrdev_region(&my_dev, 0, 1, DEVICE_NAME);
  if(res) {
    printk ("<1>Alocation of the device number for %s failed\n",
	    DEVICE_NAME);
    goto err1; 
  };
  my_cdev = cdev_alloc( );
  if(my_cdev == NULL) {
    printk ("<1>Allocation of cdev for %s failed\n",
	    DEVICE_NAME);
    goto err1;
  }
  my_cdev->ops = &Fops;
  my_cdev->owner = THIS_MODULE;
  /* Add character device */
  res=cdev_add(my_cdev, my_dev, 1);
  if(res) {
    printk ("<1>Registration of the device number for %s failed\n",
	    DEVICE_NAME);
    goto err1;
  };
  device_create(class_my_tst,NULL,my_dev,NULL,"my_bm%d",MINOR(my_dev));
  printk (KERN_INFO "%s The major device number is %d.\n",
	  "Registeration is a success.",
	  MAJOR(my_dev));
  printk(KERN_INFO "Registred device at: %p\n",pdev);
  my_pdev = pdev;
  return 0;
 err1:
  if (ctx) {
    if (ctx->) {
      iounmap(fmem);
      fmem = NULL;
  }
  if (fmem2) {
      iounmap(fmem2);
      fmem2 = NULL;
  }
  if (dmabuf) {
      dma_free_coherent(&pdev->dev, DMA_SIZE, dmabuf, dmaaddr);
  }
  return res;
}

static struct pci_driver tst1_pci_driver = {
  .name		= DEVICE_NAME,
  .id_table	= tst1_pci_tbl,
  .probe		= tst1_probe,
  .remove		= tst1_remove,
};

static int __init tst1_init_module(void)
{
  /* when a module, this is printed whether or not devices are found in probe */
#ifdef MODULE
  //  printk(version);
#endif
  return pci_register_driver(&tst1_pci_driver);
}


static void __exit tst1_cleanup_module(void)
{
  pci_unregister_driver(&tst1_pci_driver);
}


module_init(tst1_init_module);
module_exit(tst1_cleanup_module);

