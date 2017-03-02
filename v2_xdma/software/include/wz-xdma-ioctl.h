#include <wz-xdma-consts.h>
#ifndef WZ_XDMA_IOCTL_H
#define WZ_XDMA_IOCTL_H 1
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
} __attribute__((packed)); 

//When the application confirms, that the data have been processed, it
//sends only the numbers of the first and the last block
struct wz_xdma_data_block_confirm {
	uint32_t first_desc;
	uint32_t last_desc;
} __attribute__ ((packed));
//We also need means to monitor the number of free buffers.
//It is unclear if that data can be easily produced. (e.g.
//iterating through the list of descriptors is a bad idea).
//Because our list of descriptors is allocated as a continuous
//memory area, maybe we can rely on the address of the currently 
//processed descriptor?
//To be decided soon!
#endif
