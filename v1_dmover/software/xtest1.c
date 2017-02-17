#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
void main()
{
   int f, i,j;
   uint32_t * m;
   f=open("resource1",O_RDWR);
   if(f<0) { 
           printf("I can't open resource!\n");
           exit(1);
	}
   m=(uint32_t *) mmap(NULL, 1024, PROT_READ | PROT_WRITE , MAP_SHARED,f,0);
   if(m==NULL) { 
           printf("I can't mmap resource!\n");
           exit(1);
	}
   printf("mapped!\n");
   m[1]=0xffffffff;
   for(j=0;j<32;j++) {
     m[0]=j;
     msync(&m[i],4,MS_SYNC);
     for(i=0;i<4;i++)
       printf("%d : %4.4x\n",i,m[i]);
   }
   munmap(m,1024);
}
