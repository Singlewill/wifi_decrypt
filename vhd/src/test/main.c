#include <stdio.h>
#include <string.h>
#include "sha1-internal.h"
#include "sha1-pbkdf2.h"
#include "aes_wrap.h"
struct wpa_ptk {
	unsigned char kck[24]; /* EAPOL-Key Key Confirmation Key (KCK) */
	unsigned char kek[32]; /* EAPOL-Key Key Encryption Key (KEK) */
	unsigned char tk[32]; /* Temporal Key (TK) */
	int kck_len;
	int kek_len;
	int tk_len;
};  
//0xf8, 0x37, 0x47, 0x67, 0x41, 0x2c, 0xa6, 0x0a, 
//0x82, 0xec, 0x32, 0xb8, 0x32, 0xd0, 0xe3, 0xec, 
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
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 
		  0x00, 0x16, 0x30, 0x14, 0x01, 0x00, 0x00, 
	0x0f, 0xac, 0x02, 0x01, 0x00, 0x00, 0x0f, 0xac,
	0x04, 0x01, 0x00, 0x00, 0x0f, 0xac, 0x02, 0x00, 
	0x00

};


unsigned char* ssid = "kalo";
unsigned char* passphrase = "12345678";

unsigned char ANonce[] = {
	0x4c, 0x56, 0x4e, 0xf1, 0x97, 0x0b, 0x4d, 0xcf, 
	0xe9, 0x0f, 0xbc, 0xe7, 0x5c, 0xac, 0x18, 0x99,
	0xbf, 0x9a, 0x83, 0x70, 0x94, 0x2c, 0xeb, 0x3f, 
	0x44, 0xcd, 0x82, 0x4c, 0x41, 0x0d, 0x2b, 0x5e
};

unsigned char SNonce[] = {
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

int main()
{
	int i;
	int ret ;
	unsigned char pmk[32];
	/*1, 通过SSID和密码生成ＰＭＫ*/
	pbkdf2_sha1(passphrase, ssid, 4, 4096, pmk, 32);
	printf("pmk is : \n");
	for (i = 0; i < 32; i++)
	{
		printf("0x%02x, ", pmk[i])	;
		if (i%8 == 7)
			printf("\n");
	}
	printf("\n");

	printf("pmk is : \n");
	for (i = 0; i < 32; i++)
	{
		printf("%02x", pmk[i])	;
	}
	printf("\n");


	/**************************************************/
	unsigned char data[6 * 2 + 32 * 2];
	unsigned char tmp[24 + 32 + 32];
	memcpy(data, mac2, 6);
	memcpy(data + 6, mac1, 6);
	
	memcpy(data + 12, ANonce, 32);
	memcpy(data + 12 + 32, SNonce, 32);

	/*2, */
	sha1_prf(pmk, 32, "Pairwise key expansion", data, sizeof(data), tmp, 48);

	struct wpa_ptk ptk;
	memcpy(ptk.kck, tmp, 16);
	memcpy(ptk.kek, tmp + 16, 16);
	memcpy(ptk.tk, tmp + 32, 16);
	ptk.kck_len = 16;
	ptk.kek_len = 16;
	ptk.tk_len = 16;

	printf("ptk.kck is :\n");
	for (i = 0; i < 16; i++)
	{
		printf("0x%02x, ", ptk.kck[i])	;
		if (i%8 == 7)
			printf("\n");
	}
	printf("\n");

	printf("ptk.kek is :\n");
	for (i = 0; i < 16; i++)
	{
		printf("0x%02x, ", ptk.kek[i])	;
		if (i%8 == 7)
			printf("\n");
	}
	printf("\n");

	printf("ptk.tk is :\n");
	for (i = 0; i < 16; i++)
	{
		printf("0x%02x, ", ptk.tk[i])	;
		if (i%8 == 7)
			printf("\n");
	}
	printf("\n");
	/**********************************************************************/
	unsigned char mic[48];
	/*3, */
	hmac_sha1(ptk.kck, 16, key2, sizeof(key2), mic);		//取前16位
	printf("1, mic is :\n");
	for (i = 0; i < 16; i ++)
	{
		printf("0x%02x, ", mic[i])	;
		if (i%8 == 7)
			printf("\n");
	}
	printf("\n");
	return 0;
	
	/*******************************************************************/
	/*
	
	unsigned char buff[96] = {0};
	unsigned char*  p = buff;

	unsigned char key_data[96] = {0};
	memcpy(buff, kde, 86);
	p+=86;
	*p = 0xdd;
	int key_data_len = 96;
    aes_wrap(kek, 16, (key_data_len - 8) / 8, buff, key_data);
	FILE* file = fopen("./key_data", "w");
	fwrite(key_data, 96, 1, file);
	fclose(file);
	*/


	/*******************************************************/
	
	/*
	unsigned char key_mic[48];
	hmac_sha1(kck, 16, key3, sizeof(key3), key_mic);
	printf("mic is :\n");
	for (i = 0; i < 16; i ++)
	{
		printf("0x%02x, ", key_mic[i])	;
		if (i%8 == 7)
			printf("\n");
	}
	printf("\n");
	*/
	
	

}


