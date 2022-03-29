#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/select.h>
#include <sys/time.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>

#include "config.h"



#define RX_LEN  1024

static void init_uart(int fd)
{
	struct termios opt;		//uart sutup param struct
	bzero(&opt, sizeof(struct termios));		//clear
	tcgetattr(fd, &opt);		//get current uart setup param
	cfsetispeed(&opt, B9600);	 //set input band rate to 115200
	cfsetospeed(&opt, B9600);	 //set output band rate to 115200
	opt.c_cflag |= (CLOCAL | CREAD);		//enable read and local status
	opt.c_cflag &= ~PARENB;		//8 data bit and 1 stop bit
	opt.c_cflag &= ~CSTOPB;
	opt.c_cflag &= ~CSIZE;
	opt.c_cflag |= CS8;
	opt.c_iflag &= ~(ICRNL | IXON);		//解决0x0d在linux下变成0x0a的问题

	opt.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);	//raw data in and out
	opt.c_oflag &= ~(OPOST);

	opt.c_cc[VTIME] = 0;	//wait time and min num of recieve char
	opt.c_cc[VMIN] = 0;

	tcflush(fd, TCIFLUSH);		//handle last char
	tcsetattr(fd, TCSANOW, &opt);	//active new setup

}


int main(void)
{
	int i;
	int fd ;
	int readsize = 0;
	unsigned char rx_buff[RX_LEN] = {0};


	
	fd	= open("/dev/ttyUSB0", O_RDWR|O_NOCTTY|O_NDELAY | O_NONBLOCK);
	if (fd == -1)
	{
		printf("open failed! fd is %d\n", fd);
		return -1;
	}
	init_uart(fd);

	while(1)
	{

		memset(rx_buff, 0, RX_LEN);
		readsize = read(fd, rx_buff, RX_LEN);
		if (readsize < 0) {
			printf("read failed \n");
			return -1;
		}
		if (readsize > 0) {
			if (readsize == RX_LEN)
			{
				readsize -= 1;
			}
			
			printf("readsize is %d : \n", readsize);
			rx_buff[readsize] = '\0';
			for (i = 0; i < readsize; i++) {
				printf("0x%02x ",rx_buff[i]);
				if (i%16 == 0)
					printf("\n");
			}
			printf("\n");
			printf("\n");
			printf("\n");
			printf("\n");
			printf("\n");
			
		}
		usleep(500000);
	
	}

	
	close(fd);
	return 0;
}

