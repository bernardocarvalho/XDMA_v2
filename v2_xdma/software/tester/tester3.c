#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <stdint.h>
#include <xdma-ioctl.h>
#include <time.h>
//#include <wz-xdma-ioctl.h>
#include <fcntl.h>
#define TOT_BUF_LEN ((int64_t) WZ_DMA_BUFLEN * (int64_t) WZ_DMA_NOFBUFS)
int fu=-1;
int fc=-1;
int fm=-1;
volatile uint32_t * usr_regs = NULL;
volatile char * data_buf = NULL;
struct timespec ts;
double tstart, tcur;
volatile uint64_t dummy1 = 0;

struct wz_xdma_data_block_desc bdesc;
struct wz_xdma_data_block_confirm bconf;
struct dta_payload {
	uint32_t dta[8];
} __attribute__((packed)); 

struct dta_header {
	uint32_t flags;
	uint32_t len;
	uint32_t filler[6];
} __attribute__((packed)); 
unsigned int get_step(struct dta_header * pt)
{
	return (pt->flags >> 8) & 0xf;
}

unsigned int get_init(struct dta_header * pt)
{
	return pt->flags & 0xff;
}

unsigned int get_len(struct dta_header * pt)
{
	return pt->len;
}

int first = 1;

int64_t tot_len = 0;
int64_t old_tot_len = 0;

int start_source()
{
    usr_regs[0x0F]=0xFFFF; // SHAPI dev_scratch_reg
	asm volatile ("" : : : "memory"); // Compier Barrier
	printf("BAR0 Reg 0x0F: 0x%08X\n",usr_regs[0x0F]);
}

int stop_source()
{
	usr_regs[0x0F]=0;
	asm volatile ("" : : : "memory");
}


int main(int argc, char * argv[])
{
	int res;
	fu=open("/dev/wz-xdma0_user", O_RDWR);
	if(fu<0) {
		perror("Can't open /dev/wz-xdma0_user");
		exit(1);
	};
	fc=open("/dev/wz-xdma0_control", O_RDWR);
	if(fc<0) {
		perror("Can't open /dev/wz-xdma0_control");
		exit(1);
	};
	fm=open("/dev/wz-xdma0_c2h_0",O_RDWR );
	if(fm<0) {
		perror("Can't open /dev/wz-xdma0_c2h_0");
		exit(1);
	};
    //Allocate buffers
	res=ioctl(fm,IOCTL_XDMA_WZ_ALLOC_BUFFERS,0L);
	if(res<0) {
		perror("I can't alloc DMA buffers");
		exit(3);
	}
	//Now mmap the user registers BAR0 1MB space
	usr_regs = mmap(NULL,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fu,0);
	if(usr_regs == MAP_FAILED) {
		perror("Can't mmap user registers");
		exit(2);		
	}
	printf("BAR0 Reg 0: 0x%X\n",usr_regs[0x00000/4]);
	printf("BAR0 Reg 0: 0x%X\n",usr_regs[0x2]);
    
	printf("WZ_DMA_BUFLEN: %d, WZ_DMA_NOFBUFS: %d, TOT_BUF_LEN: %d\n", 
		WZ_DMA_BUFLEN, WZ_DMA_NOFBUFS, TOT_BUF_LEN);
	data_buf = mmap(NULL, TOT_BUF_LEN, PROT_READ|PROT_WRITE, MAP_SHARED,fm,0);
    if(data_buf == MAP_FAILED) { 
        perror("Can't mmap data_buf");
        exit(2);        
	}
//Ensure, that all pages are mapped
    {
		uint64_t i;
		for(i=0;i<TOT_BUF_LEN/sizeof(uint64_t);i++)
			dummy1 += data_buf[i];
	}
	//Stop the source
    stop_source();
	//Start the dma acquisition 
	
    res=ioctl(fm,IOCTL_XDMA_WZ_START,0L);
	if(res<0) {
		perror("I can't start the data source");
		exit(3);
	}
	//Start the source
	
	clock_gettime(CLOCK_MONOTONIC,&ts);
	tstart=ts.tv_sec+1.0e-9*ts.tv_nsec;
	start_source();
    
    usleep(10);

    clock_gettime(CLOCK_MONOTONIC,&ts);
    tcur=ts.tv_sec+1.0e-9*ts.tv_nsec;
	//Stop the source
    stop_source();
    
	//Stop the dma acquisition 
    ioctl(fm,IOCTL_XDMA_WZ_STOP,0L);
    munmap((void *)data_buf, TOT_BUF_LEN);
    ioctl(fm,IOCTL_XDMA_WZ_FREE_BUFFERS,0L);

	close(fm);
	close(fc);
	close(fu);
}

