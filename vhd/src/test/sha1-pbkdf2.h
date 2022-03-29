#ifndef	 	__SHA1_PBKDF2_H__
#define	 	__SHA1_PBKDF2_H__

#include "sha1-internal.h"
extern int pbkdf2_sha1(const char *passphrase, const u8 *ssid, size_t ssid_len,
		int iterations, u8 *buf, size_t buflen);
#endif	 	//__SHA1_PBKDF2_H__
