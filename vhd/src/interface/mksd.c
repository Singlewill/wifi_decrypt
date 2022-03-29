#include <stdio.h>
#include <stdlib.h>
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



#define	MESSAGE_SIZE 64
unsigned char* ssid = "kalo";
unsigned char* passphrase = "12345678";

const unsigned char counter0[4] = {
	0x00, 0x00, 0x00, 0x01
};

const unsigned char counter1[4] = {
	0x00, 0x00, 0x00, 0x02	
};

  
//mic = 0xf8, 0x37, 0x47, 0x67, 0x41, 0x2c, 0xa6, 0x0a, 
//		0x82, 0xec, 0x32, 0xb8, 0x32, 0xd0, 0xe3, 0xec, 
unsigned char key2[] = {
	0x01, 0x03, 0x00, 0x75, 0x02, 0x01, 0x0a, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x01, 0x4c, 0x56, 0x4e, 0xf1, 0x97, 0x0b, 0x4d, 
	0xcf, 0xe9, 0x0f, 0xbc, 0xe7, 0x5c, 0xac, 0x18,
	0x99, 0xbf, 0x9a, 0x83, 0x70, 0x94, 0x2c, 0xeb, 
	0x3f, 0x44, 0xcd, 0x82, 0x4c, 0x41, 0x0d, 0x2b,
	0x5e, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0xf8, 0x37, 0x47, 0x67, 0x41, 0x2c, 0xa6, 
	0x0a, 0x82, 0xec, 0x32, 0xb8, 0x32, 0xd0, 0xe3,
	0xec, 0x00, 0x16, 0x30, 0x14, 0x01, 0x00, 0x00, 
	0x0f, 0xac, 0x02, 0x01, 0x00, 0x00, 0x0f, 0xac,
	0x04, 0x01, 0x00, 0x00, 0x0f, 0xac, 0x02, 0x00, 
	0x00
};
unsigned char nonce1[] = {
	0x4c, 0x56, 0x4e, 0xf1, 0x97, 0x0b, 0x4d, 0xcf, 
	0xe9, 0x0f, 0xbc, 0xe7, 0x5c, 0xac, 0x18, 0x99,
	0xbf, 0x9a, 0x83, 0x70, 0x94, 0x2c, 0xeb, 0x3f, 
	0x44, 0xcd, 0x82, 0x4c, 0x41, 0x0d, 0x2b, 0x5e
};

unsigned char nonce2[] = {
	0x98, 0x96, 0xa9, 0x23, 0x96, 0xbf, 0x67, 0xca, 
	0x4d, 0xe5, 0x3a, 0x3f, 0x34, 0x52, 0x99, 0xa7,
	0xd4, 0xd8, 0x7e, 0x72, 0x74, 0x18, 0xe1, 0xba, 
	0xa7, 0x8d, 0x4f, 0x41, 0x7a, 0xe7, 0xfa, 0x3d
};
unsigned char mac1[] = {
	0xf0, 0x43, 0x47, 0x8f, 0x63, 0x31
};

unsigned char mac2[] = {
	0x80, 0x37, 0x73, 0xf9, 0x13, 0xe0
};






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


int padding_mac_nonce(unsigned char* buff,  
		unsigned char* mac1,
		unsigned char* mac2,
		unsigned char* nonce1,
		unsigned char* nonce2)
{
	memcpy(buff, PRF_LABEL, PRF_LABEL_LEN);
	if (memcmp((const void*)mac1, (const void*)mac2, ETH_ALEN) < 0) {
		memcpy(buff + PRF_LABEL_LEN, mac1, ETH_ALEN); 
		memcpy(buff + PRF_LABEL_LEN  + ETH_ALEN, mac2, ETH_ALEN);
	} else {
		memcpy(buff + PRF_LABEL_LEN, mac2, ETH_ALEN); 
		memcpy(buff + PRF_LABEL_LEN + ETH_ALEN, mac1, ETH_ALEN);
	}

	if (memcmp((const void*)nonce1, (const void*)nonce2, WPA_NONCE_LEN) < 0) {
		memcpy(buff + PRF_LABEL_LEN + 2 * ETH_ALEN, nonce1, WPA_NONCE_LEN);
		memcpy(buff + PRF_LABEL_LEN  + 2 * ETH_ALEN + WPA_NONCE_LEN, nonce2,
				WPA_NONCE_LEN);
	} else {
		memcpy(buff + PRF_LABEL_LEN + 2 * ETH_ALEN, nonce2, WPA_NONCE_LEN);
		memcpy(buff + PRF_LABEL_LEN + 2 * ETH_ALEN + WPA_NONCE_LEN, nonce1,
				WPA_NONCE_LEN);
	}

	return PRF_LABEL_LEN + 2 * ETH_ALEN + 2 * WPA_NONCE_LEN;


}
int main(void)
{
	int i;
	int ret = 0;
	int readsize = 0;
	unsigned char buff[128];
	int buff_size;
	unsigned char  counter = 0x02;
	// 64K
	unsigned char* tx_buff= malloc(MESSAGE_SIZE);
	if (tx_buff == NULL) {
		printf("malloc failed.\n")	;
		return -1;
	}


	FILE* fd = fopen("./sd.txt", "w");
	if (fd == NULL) {
		printf("fopen failed.\n")	;
		return -1;
	}


	
	//1,发送ssid1
	memset(tx_buff, 0, MESSAGE_SIZE);
	tx_buff[0] = strlen(ssid) + sizeof(counter0);
	memcpy(tx_buff + 1, ssid, strlen(ssid));
	memcpy(tx_buff + 1+ strlen(ssid), counter0, sizeof(counter0));
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}

	//2,发送ssid2
	memset(tx_buff, 0, MESSAGE_SIZE);
	tx_buff[0] = strlen(ssid) + sizeof(counter1);
	memcpy(tx_buff + 1, ssid, strlen(ssid));
	memcpy(tx_buff + 1 + strlen(ssid), counter1, sizeof(counter0));
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}

	//3, 发送key2_1
	memset(tx_buff, 0, MESSAGE_SIZE);
	memcpy(tx_buff, key2, 64);
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}


	//4，发送key2_2
	memset(tx_buff, 0, MESSAGE_SIZE);
	tx_buff[0] = sizeof(key2) - 64;
	memcpy(tx_buff + 1, key2 + 64, sizeof(key2) - 64);
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}

	//5, 发送MAC_NONCE_1
	buff_size = padding_mac_nonce(buff, mac1, mac2, nonce1, nonce2);
	memset(tx_buff, 0, MESSAGE_SIZE);
	memcpy(tx_buff, buff, 64);
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}
	//6,发送MAC_NONCE_2
	memset(tx_buff, 0, MESSAGE_SIZE);
	memcpy(tx_buff, buff + 64, buff_size - 64);
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}

	//补齐两个sec,512字节
	memset(tx_buff, 0, MESSAGE_SIZE);
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}
	memset(tx_buff, 0, MESSAGE_SIZE);
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}
	////////////////////////////////////////////////////////
	


	printf("send first sector over !!\n");

	//后面的位置放密码包
	//先放一个正确的
	memset(tx_buff, 0, MESSAGE_SIZE);
	memcpy(tx_buff, passphrase, strlen(passphrase));
	ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
	if (ret < 0) {
		printf("1 : write failed ..\n")	;
		return -1;
	}
	//再放其他的
	while(1)
	{
		memset(tx_buff, counter++, MESSAGE_SIZE);
		ret = fwrite(tx_buff, MESSAGE_SIZE, 1, fd);
		if (ret < 0) {
			printf("fwrite failed \n");
			return -1;
		}
		usleep(50000);

		if (counter == 0xff)
			break;
	
	}

	
	fclose(fd);
	return 0;
}

