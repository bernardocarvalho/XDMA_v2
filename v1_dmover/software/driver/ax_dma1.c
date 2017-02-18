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

//Structure describing the status of the WZAB_AXS1 device
struct axs1_ctx{
	uint32_t * 
}

static volatile uint32_t * fmem=NULL; //Pointer to registers area
static volatile uint32_t * fmem2=NULL; //Pointer to registers area
#define N_OF_RES (3)
//If 64-bit bars are used:
//static int res_nums[N_OF_RES]={0,2};
//If 32-bit bars are used:
static int res_nums[N_OF_RES]={0,1,2};

#define RES_REGS (1)
#define PER_REGS (0)


static resource_size_t mmio_start[N_OF_RES], mmio_end[N_OF_RES],
    mmio_flags[N_OF_RES], mmio_len[N_OF_RES];
#define DMA_SIZE (4*1024*1024)

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
  if(val==1) { //copy buffer 1 to buffer 2
    fmem2[0x18/4]=0xC0000000;
    fmem2[0x20/4]=0x80000000;
    mb();
    fmem2[0x28/4]=1024*1024;
    return 4;
  };
  if(val==2) { //copy buffer 2 to buffer 1
    fmem2[0x18/4]=0x80000000;
    fmem2[0x20/4]=0xC0000000;
    mb();
    fmem2[0x28/4]=1024*1024;
    mb();
    return 4;
  };
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

  int res = 0;
  int i ;
  if (my_pdev) {
      //We can't handle more than one device
      printk(KERN_INFO "The driver handles already one device: %p\n", my_pdev);
      return -EINVAL;
  }
  res =  pci_enable_device(pdev);
  if (res) {
    dev_err(&pdev->dev, "Can't enable PCI device, aborting\n");
    res = -ENODEV;
    goto err1;
  }
  for(i=0;i<N_OF_RES;i++) {
    mmio_start[i] = pci_resource_start(pdev, res_nums[i]);
    mmio_end[i] = pci_resource_end(pdev, res_nums[i]);
    mmio_flags[i] = pci_resource_flags(pdev, res_nums[i]);
    mmio_len[i] = pci_resource_len(pdev, res_nums[i]);
    printk(KERN_INFO "Resource: %d start:%llx, end:%llx, flags:%llx, len=%llx\n",
        i,mmio_start[i],mmio_end[i], mmio_flags[i], mmio_len[i]);
    if (!(mmio_flags[i] & IORESOURCE_MEM)) {
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
  dmabuf=dma_alloc_coherent(&pdev->dev,DMA_SIZE,&dmaaddr,GFP_USER);
  if(dmabuf==NULL) {
      printk(KERN_INFO "I can't allocate the DMA buffer\n");
      res = -ENOMEM;
      goto err1;
  }
  printk(KERN_INFO "Allocated DMA buffer at phys: %p virt %p\n",dmaaddr,dmabuf);
  res = pci_request_regions(pdev, DEVICE_NAME);
  if (res)
    goto err1;
  pci_set_master(pdev);
  /* Let's check if the register block is read correctly */
  fmem = ioremap(mmio_start[RES_REGS],mmio_len[RES_REGS]);
  if(!fmem) {
    printk ("<1>Mapping of memory for %s registers failed\n",
	    DEVICE_NAME);
    res= -ENOMEM;
    goto err1;
  }
  //The first register should return our PCI_ID
  {
      uint32_t pci_id = PCI_VENDOR_ID_WZAB |  (PCI_DEVICE_ID_WZAB_BM1 << 16);
      if(*fmem != pci_id) {
          dev_info(&pdev->dev, "Not accessible registers BAR? expected id: %lx, read id: %lx\n",pci_id, *fmem);
          goto err1;
      }
  }  
  //Now we can program the localtion of DMA buffer to the AXIBAR2PCIEBAR
  fmem[0x208/4]=(dmaaddr >> 32);
  fmem[0x20c/4]=(dmaaddr & 0xFFffFFff);
  //Map AXI connected registers
  fmem2 = ioremap(mmio_start[PER_REGS],mmio_len[PER_REGS]);
  if(!fmem2) {
    printk ("<1>Mapping of memory for %s registers failed\n",
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
  if (fmem) {
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

