#include <stdio.h>
#include <stdlib.h>
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
	usr_regs[0x10000/4]=1;
	asm volatile ("" : : : "memory");
}

int stop_source()
{
	usr_regs[0x10000/4]=0;
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
	//Now mmap the user registers
	usr_regs = mmap(NULL,1024*1024,PROT_READ|PROT_WRITE,MAP_SHARED,fu,0);
	if(usr_regs == MAP_FAILED) {
		perror("Can't mmap user registers");
		exit(2);		
	}
	data_buf = mmap(NULL, TOT_BUF_LEN, PROT_READ|PROT_WRITE, MAP_SHARED,fm,0);
	if(data_buf == MAP_FAILED) { 
		perror("Can't mmap data");
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
	//Start the data acquisition
	res=ioctl(fm,IOCTL_XDMA_WZ_START,0L);
	if(res<0) {
		perror("I can't start the data source");
		exit(3);
	}
	//Start the source
	
	clock_gettime(CLOCK_MONOTONIC,&ts);
	tstart=ts.tv_sec+1.0e-9*ts.tv_nsec;
	start_source();
	while(1) {
		int64_t cur_len=0;
			res=ioctl(fm,IOCTL_XDMA_WZ_GETBUF,(long) &bdesc);
			if(res<0) {
				perror("I can't get buffer");
				printf("transmitted: %ld\n",tot_len);
				exit(4);
			}
			if(first==1) {
				first = 0;
				//Ignore the first block, it may be corrupted after the previous run
			} else {
				//Check the correctness of the data
				int64_t dta_index=(int64_t) WZ_DMA_BUFLEN * (int64_t) bdesc.first_desc;
				struct dta_header * dh = (struct dta_header *) ( data_buf + dta_index );
				int dlen = get_len(dh);
				int dinit = get_init(dh);
				int dstep = get_step(dh);
				int i;
				int exp_len = dlen * 32;
				cur_len = ((int64_t)WZ_DMA_BUFLEN*((bdesc.last_desc - bdesc.first_desc) % (int64_t) WZ_DMA_NOFBUFS))+bdesc.last_len;
				//Check if the cur_len is correct
				if(cur_len != exp_len) {
					printf("buffer_nr=%d\n",bdesc.first_desc);
					printf("dlen = %d\n",dlen);
					printf("dinit= %d\n",dinit);
					printf("dstep = %d\n",dstep);
					printf("exp_len= %d\n",exp_len);
					printf("cur_len= %d\n",cur_len);
				}
				for(i=0;i<dlen;i+=32) {
					int j;
					dta_index = ( dta_index + 32 ) & (TOT_BUF_LEN-1);
					struct dta_payload * dp = (struct dta_payload *) &data_buf[dta_index];
					for(j=0;j<8;j++) {
						if(dp->dta[j] != dinit+j) {
							printf("data error! buffer %d dlen %d index: %d position: %d expexted: %d received: %d\n", bdesc.first_desc, dlen*32, dta_index, j, dinit+j, dp->dta[j]);
						}
					}
					dinit += dstep;
				}
				
			}
			bconf.first_desc=bdesc.first_desc;
			bconf.last_desc=bdesc.last_desc;
			tot_len += cur_len;
			res=ioctl(fm,IOCTL_XDMA_WZ_CONFIRM,(long) &bconf);
			if(res<0) {
				perror("I can't confirm buffer");
				exit(4);
			}
			if(tot_len > old_tot_len + 100000000L) {
				clock_gettime(CLOCK_MONOTONIC,&ts);
				tcur=ts.tv_sec+1.0e-9*ts.tv_nsec;
				printf("transmitted: %ld time: %g rate: %g\n",tot_len, tcur-tstart, tot_len/(tcur-tstart));
				old_tot_len = tot_len;
			}
	if(tot_len > 10L*1024L*1024L*1024L) break; //exit, to check if the the program closes cleanly
	}
	ioctl(fm,IOCTL_XDMA_WZ_STOP,0L);
	munmap((void *)data_buf, TOT_BUF_LEN);
	ioctl(fm,IOCTL_XDMA_WZ_FREE_BUFFERS,0L);
	close(fm);
	close(fc);
	close(fu);
}
