/*
 * SHA1 internal definitions
 * Copyright (c) 2003-2005, Jouni Malinen <j@w1.fi>
 *
 * This software may be distributed under the terms of the BSD license.
 * See README for more details.
 */

#ifndef __SHA1_INTERNAL_H__
#define __SHA1_INTERNAL_H__
typedef	unsigned int u32;
typedef	unsigned short u16;
typedef	unsigned char u8;
#define	CONFIG_CRYPTO_INTERNAL

#define SHA1_MAC_LEN 20
struct SHA1Context {
	u32 state[5];
	u32 count[2];
	unsigned char buffer[64];
};

void SHA1Init(struct SHA1Context *context);
void SHA1Update(struct SHA1Context *context, const void *data, u32 len);
void SHA1Final(unsigned char digest[20], struct SHA1Context *context);
void SHA1Transform(u32 state[5], const unsigned char buffer[64]);

extern int sha1_vector(size_t num_elem, const u8 *addr[], const size_t *len, u8 *mac);

extern int hmac_sha1(const u8 *key, size_t key_len, const u8 *data, size_t data_len, u8* mac);
extern int hmac_sha1_vector(const u8 *key, size_t key_len, size_t num_elem,
		     const u8 *addr[], const size_t *len, u8 *mac);

extern int sha1_prf(const u8 *key, size_t key_len, const char *label,
	     const u8 *data, size_t data_len, u8 *buf, size_t buf_len);
#endif /* SHA1_I_H */
