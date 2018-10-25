#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
//nclude <byteswap.h>
#include <string.h>
#include <errno.h>
//#include <signal.h>
#include <fcntl.h>
//#include <ctype.h>
//#include <termios.h>
#include <assert.h>
#include <time.h>

#include <sys/types.h>
#include <sys/mman.h>

#define FATAL do { fprintf(stderr, "Error at line %d, file %s (%d) [%s]\n", __LINE__, __FILE__, errno, strerror(errno)); exit(1); } while(0)

#define MAP_SIZE (32*1024UL)
#define MAP_MASK (MAP_SIZE - 1)
// This is a Litle endian system #if __BYTE_ORDER == __LITTLE_ENDIAN

#define DEV_NAME "/dev/xdma0"

//static int test_stream_dma(char *devicename, uint32_t addr, uint32_t size, uint32_t offset, uint32_t count, char *filename);
//static int test_stream_dma(char *devicename,  uint32_t size, uint32_t count, char *filename);
static int test_stream_dma(char *devicename,  uint32_t size,  uint32_t count, char *filename, char * buff);

#define DEVICE_NAME_DEFAULT "/dev/xdma/card0/c2h0"
#define FILENAME_NAME_DEFAULT "data/output_file.bin"
//#define SIZE_DEFAULT (4096)
//#define SIZE_DEFAULT (8192)
#define SIZE_DEFAULT (16384)
#define COUNT_DEFAULT (2)

static int no_write = 0;

int main(int argc, char **argv) {
	int fd;
	void *map_base, *virt_addr;
	uint32_t read_result, writeval;
	off_t target;
	/* access width */
	//int access_width = 'w';
	char device[80];
	char *filename = FILENAME_NAME_DEFAULT;
//	uint32_t address = 0;
	uint32_t size = SIZE_DEFAULT;
//	uint32_t offset = 0;
	uint32_t count = COUNT_DEFAULT;
	char * dmaBuff; //user space buffer for data

	/* not enough arguments given?
	   if (argc < 2) {
	   fprintf(stderr, "\nUsage:\t%s <device> ]\n"
	   "\tdevice  : character device to access\n",
	//    "\taddress : memory address to access\n"
	//    "\ttype    : access operation type : [b]yte, [h]alfword, [w]ord\n"
	//    "\tdata    : data to be written for a write\n\n",
	argv[0]);
	exit(1);
	}
	*/
	dmaBuff = (char *) calloc(count * size, sizeof (char)); // user space buffer for data

	//	printf("argc = %d\n", argc);

	//	device = strdup(argv[1]);
	sprintf(device,"%s_user", DEV_NAME);
	printf("device: %s\n", device);
	if ((fd = open(device, O_RDWR | O_SYNC)) == -1) FATAL;
	printf("character device %s opened.\n", device);
	fflush(stdout);

	/* map one page */
	map_base = mmap(0, MAP_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (map_base == (void *) -1) FATAL;
	printf("Memory mapped at address %p.\n", map_base);
	fflush(stdout);

	/* calculate the virtual address to be accessed */
	target = 0;
	virt_addr = map_base + target;

	read_result = *((uint32_t *) virt_addr);
	/* swap 32-bit endianess if host is not little-endian */
	//	      read_result = ltohl(read_result);
	printf("Read 32-bit value at address 0x%08x (%p): 0x%08x\n", (unsigned int)target, virt_addr, (unsigned int)read_result);

	target = 0x14; //Time stamp
	virt_addr = map_base + target;
	read_result = *((uint32_t *) virt_addr);
	printf("Read FW Timestamp value at address 0x%08x (%p): %u\n", (unsigned int)target, virt_addr, (unsigned int)read_result);

	target = 0x3C; // dev_scratch_reg
	virt_addr = map_base + target;
	writeval = 0xFFFFFFFF;
//printf("Write 32-bits value 0x%08x to 0x%08x (%p)\n", (unsigned int)writeval, (unsigned int)target, virt_addr);
	*((uint32_t *) virt_addr) = writeval;

	read_result = *((uint32_t *) virt_addr);
	printf("Written 0x%08x; readback 0x%08x\n", writeval, read_result);
	usleep(10);
	/*Make C2H Stream DMA*/
	sprintf(device,"%s_c2h_0", DEV_NAME);
	//count = 4;
	printf("DMA device = %s,  size = 0x%08x,  count = %u\n", device,  size,  count);
	test_stream_dma(device, size, count, filename, dmaBuff);

	writeval = 0;
//	printf("Write 32-bits value 0x%08x to 0x%08x (%p)\n", (unsigned int)writeval, (unsigned int)target, virt_addr);
	*((uint32_t *) virt_addr) = writeval;
	read_result = *((uint32_t *) virt_addr);
	printf("Written 0x%08x; readback 0x%08x\n", writeval, read_result);

	if (munmap(map_base, MAP_SIZE) == -1) FATAL;
	close(fd);
	free(dmaBuff);
	return 0;
}

/* Subtract timespec t2 from t1
 *
 * Both t1 and t2 must already be normalized
 * i.e. 0 <= nsec < 1000000000 */
static void timespec_sub(struct timespec *t1, const struct timespec *t2)
{
  assert(t1->tv_nsec >= 0);
  assert(t1->tv_nsec < 1000000000);
  assert(t2->tv_nsec >= 0);
  assert(t2->tv_nsec < 1000000000);
  t1->tv_sec -= t2->tv_sec;
  t1->tv_nsec -= t2->tv_nsec;
  if (t1->tv_nsec >= 1000000000)
  {
    t1->tv_sec++;
    t1->tv_nsec -= 1000000000;
  }
  else if (t1->tv_nsec < 0)
  {
    t1->tv_sec--;
    t1->tv_nsec += 1000000000;
  }
}

static int test_stream_dma(char *devicename,  uint32_t size,  uint32_t count, char *filename, char * dbuff)
{
	int rc;
	int ndma=count;
	char *buffer = NULL;
	char *allocated = NULL;
	struct timespec ts_start, ts_end;

	posix_memalign((void **)&allocated, 4096/*alignment*/,  size + 4096);
	assert(allocated);
	buffer = allocated;// + offset;
	printf("host memory buffer = %p\n", buffer);

	int file_fd = -1;
	int fpga_fd = open(devicename, O_RDWR | O_NONBLOCK);
	assert(fpga_fd >= 0);

	/* create file to write data to */
	if (filename) {
		file_fd = open(filename, O_RDWR | O_CREAT | O_TRUNC | O_SYNC, 0666);
		assert(file_fd >= 0);
	}

	memset(buffer, 0x00,  size);
	while (ndma--) {
		/* select AXI MM address */
		//off_t off = lseek(fpga_fd, addr, SEEK_SET);
		rc = clock_gettime(CLOCK_MONOTONIC, &ts_start);
		/* read data from AXI MM into buffer using SGDMA */
		rc = read(fpga_fd, buffer, size);
		if ((rc > 0) && (rc < size)) {
			printf("count: %d, Short read of %d bytes into a %d bytes buffer, could be a packet read?\n", ndma, rc, size);
		}
		rc = clock_gettime(CLOCK_MONOTONIC, &ts_end);
		memcpy(dbuff, buffer, size);
		usleep(10);
	//rc = write(file_fd, buffer, size);
		dbuff +=size;
	}
	/* subtract the start time from the end time */
	timespec_sub(&ts_end, &ts_start);
	/* display passed time, a bit less accurate but side-effects are accounted for */
	printf("CLOCK_MONOTONIC reports %ld.%09ld seconds (total) for last transfer of %d bytes\n", ts_end.tv_sec, ts_end.tv_nsec, size);
	// = allocated;
	ndma =count;
	/* file argument given? */
	/*if ((file_fd >= 0) & (no_write == 0)) {*/
		/*while (ndma--) {*/
			/*[> write buffer to file <]*/
			/*rc = write(file_fd, buffer, size);*/
			/*assert(rc == size);*/
			/*buffer +=size;*/
		/*}*/
	/*}*/

	close(fpga_fd);
	if (file_fd >=0) {
		close(file_fd);
	}
	free(allocated);
}

