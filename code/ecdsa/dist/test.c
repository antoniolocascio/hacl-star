#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdbool.h>
#include <stdint.h>
#include <time.h>

// #include "ecdhp256-tvs.h"
// #include "ecdhp256_tv_w.h"
// #include "ecdsap256_tv_w.h"

#include "test_helpers.h"
#include <inttypes.h>

#include "Hacl_P256.h"

static inline bool compare(size_t len, uint8_t* comp, uint8_t* exp) {
  bool ok = true;
  for (size_t i = 0; i < len; i++)
    ok = ok & (exp[i] == comp[i]);
  return ok;
}



void print_felem(int len, uint64_t* a)
{
	for (int i = 0; i < len; i++)
		printf("%" PRIu64 "\n", a[i]);
}



// p256 = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff
// a256 = p256 - 3
// b256 = 27580193559959705877849011840389048093056905856361568521428707301988689241309860865136260764883745107765439761230575

// gx = 0xaa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7
// gy = 0x3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f

// FF = GF(p256)

// EC = EllipticCurve([FF(a256), FF(b256)])

// G = EC(FF(gx), FF(gy))
// P = (G * 20).xy()
// x, y = P

// for i in range(384/8 -1, -1, -1):
//     print(hex((Integer(y) >> (i * 8)) % (2 ** 8)) +  ", ")
  
bool test_nist()
{

	static uint8_t privateKey_P256[32] = {
	0x7d, 0x7d, 0xc5, 0xf7, 0x1e, 0xb2, 0x9d, 0xda, 0xf8, 0x0d, 0x62, 0x14, 0x63, 0x2e, 0xea, 0xe0, 0x3d, 0x90, 0x58, 0xaf, 0x1f, 0xb6, 0xd2, 0x2e, 0xd8, 0x0b, 0xad, 0xb6, 0x2b, 0xc1, 0xa5, 0x34 
	};

	static uint8_t expectedPublicKeyX_P256[32] = {
	0xea, 0xd2, 0x18, 0x59, 0x01, 0x19, 0xe8, 0x87, 0x6b, 0x29, 0x14, 0x6f, 0xf8, 0x9c, 0xa6, 0x17, 0x70, 0xc4, 0xed, 0xbb, 0xf9, 0x7d, 0x38, 0xce, 0x38, 0x5e, 0xd2, 0x81, 0xd8, 0xa6, 0xb2, 0x30 
	};
	
	static uint8_t expectedPublicKeyY_P256[32] = {
	0x28, 0xaf, 0x61, 0x28, 0x1f, 0xd3, 0x5e, 0x2f, 0xa7, 0x00, 0x25, 0x23, 0xac, 0xc8, 0x5a, 0x42, 0x9c, 0xb0, 0x6e, 0xe6, 0x64, 0x83, 0x25, 0x38, 0x9f, 0x59, 0xed, 0xfc, 0xe1, 0x40, 0x51, 0x41 
	};

	static uint8_t publicKeyX1_P256[32] = {
	0x70, 0x0c, 0x48, 0xf7, 0x7f, 0x56, 0x58, 0x4c, 0x5c, 0xc6, 0x32, 0xca, 0x65, 0x64, 0x0d, 0xb9, 0x1b, 0x6b, 0xac, 0xce, 0x3a, 0x4d, 0xf6, 0xb4, 0x2c, 0xe7, 0xcc, 0x83, 0x88, 0x33, 0xd2, 0x87 
	};

	static uint8_t publicKeyY1_P256[32] = {
	0xdb, 0x71, 0xe5, 0x09, 0xe3, 0xfd, 0x9b, 0x06, 0x0d, 0xdb, 0x20, 0xba, 0x5c, 0x51, 0xdc, 0xc5, 0x94, 0x8d, 0x46, 0xfb, 0xf6, 0x40, 0xdf, 0xe0, 0x44, 0x17, 0x82, 0xca, 0xb8, 0x5f, 0xa4, 0xac 
	};

	static uint8_t expectedResult_P256[32] = {
	0x46, 0xfc, 0x62, 0x10, 0x64, 0x20, 0xff, 0x01, 0x2e, 0x54, 0xa4, 0x34, 0xfb, 0xdd, 0x2d, 0x25, 0xcc, 0xc5, 0x85, 0x20, 0x60, 0x56, 0x1e, 0x68, 0x04, 0x0d, 0xd7, 0x77, 0x89, 0x97, 0xbd, 0x7b 
	};

	static uint8_t publicKeyX1_P384[48] = {
	0x60, 0x55, 0x8, 0xec, 0x2, 0xc5, 0x34, 0xbc, 0xee, 0xe9, 0x48, 0x4c, 0x86, 0x8, 0x6d, 0x21, 0x39, 0x84, 0x9e, 0x2b, 0x11, 0xc1, 0xa9, 0xca, 0x1e, 0x28, 0x8, 0xde, 0xc2, 0xea, 0xf1, 0x61, 0xac, 0x8a, 0x10, 0x5d, 0x70, 0xd4, 0xf8, 0x5c, 0x50, 0x59, 0x9b, 0xe5, 0x80, 0xa, 0x62, 0x3f, 
	};

	static uint8_t publicKeyY1_P384[48] = {
	0x51, 0x58, 0xee, 0x87, 0x96, 0x2a, 0xc6, 0xb8, 0x1f, 0x0, 0xa1, 0x3, 0xb8, 0x54, 0x3a, 0x7, 0x38, 0x1b, 0x76, 0x39, 0xa3, 0xa6, 0x5f, 0x13, 0x53, 0xae, 0xf1, 0x1b, 0x73, 0x31, 0x6, 0xdd, 0xe9, 0x2e, 0x99, 0xb7, 0x8d, 0xe3, 0x67, 0xb4, 0x8e, 0x23, 0x8c, 0x38, 0xda, 0xd8, 0xee, 0xdd, 
	};

	static uint8_t privateKey_ecdh_r[48] = {
	0xd7, 0x0, 0xf7, 0x3d, 0x9d, 0xbb, 0xc4, 0x24, 0x6d, 0x89, 0xf5, 0x7b, 0x3f, 0x42, 0x2, 0xbc, 0x91, 0xaa, 0xf1, 0x8a, 0xba, 0x3e, 0xae, 0x92, 0x65, 0x8a, 0xa4, 0x9d, 0x95, 0x18, 0x2d, 0xe3, 0x33, 0xf9, 0x99, 0x14, 0xc, 0x8a, 0x6d, 0x4b, 0x60, 0x8d, 0xc3, 0x48, 0x26, 0x17, 0xdd, 0xba, 
	};

	static uint8_t expectedResult_P384[48] = {
	0x1, 0x79, 0x7e, 0x16, 0x9d, 0x88, 0x36, 0xe2, 0xb7, 0x17, 0x12, 0x77, 0x1, 0x3d, 0xcb, 0x5a, 0x5, 0xaf, 0x45, 0x51, 0x75, 0xd9, 0x7e, 0xdb, 0xd0, 0x5f, 0x44, 0xd2, 0xeb, 0xee, 0xe2, 0x30, 0x87, 0x3a, 0x37, 0x8f, 0x9d, 0xc5, 0x46, 0x87, 0xa8, 0x2, 0xb, 0x8e, 0xcd, 0x40, 0x56, 0x97,
	};


	uint8_t privateKey_P384[48] = {
	0xb6, 0x52, 0x2a, 0x5d, 0xcd, 0xfd, 0x1d, 0x85, 0xbe, 0x7c, 0xb0, 0xab, 0x70, 0x88, 0xad, 0x79, 0x25, 0x45, 0xc7, 0x5e, 0x28, 0x94, 0x0d, 0xa5,
	0x5a, 0x02, 0x27, 0x48, 0x8b, 0xd9, 0x23, 0xde, 0xd1, 0x36, 0x4d, 0x39, 0x38, 0xa7, 0x25, 0x58, 0xaa, 0x17, 0xbb, 0x64, 0xb8, 0x19, 0x31, 0x8c
	};

	static uint8_t expectedPublicKeyX_P384[48] = {0x5e, 0x42, 0xed, 0x38, 0x98, 0xdb, 0x60, 0x78, 0xed, 0x2, 0xa0, 0x1b, 0xb7, 0x53, 0x26, 0x16, 0x1b, 0x85, 0x54, 0xa7, 0xa9, 0xa4, 0xeb, 0xe5, 0x5a, 0x37, 0xf5, 0x9c, 0x52, 0x17, 0x5d, 0xa8, 0x8e, 0xf3, 0x5f, 0xd1, 0x83, 0xad, 0x73, 0x80, 0xc5, 0x9c, 0x52, 0x75, 0xf6, 0x4b, 0xa9, 0x9e};
	static uint8_t expectedPublicKeyY_P384[48] = {0x48, 0x9f, 0xda, 0x84, 0x40, 0x89, 0xf3, 0xd3, 0xcb, 0x40, 0x1b, 0x34, 0x4c, 0x67, 0x65, 0xbe, 0xb2, 0xe5, 0x2f, 0x70, 0x78, 0xd7, 0x8c, 0x58, 0xe2, 0x4, 0xe8, 0x2d, 0xee, 0x75, 0xc0, 0xa3, 0xe3, 0x22, 0xd5, 0x47, 0xe6, 0x36, 0x75, 0xe5, 0xde, 0x5d, 0x99, 0x75, 0x98, 0x4d, 0xf4, 0xb3};


	bool ok = true;

	int lenP256 = 32;
	
	uint8_t* result = (uint8_t*) malloc (sizeof (uint8_t) * (lenP256 * 2));

	bool successDHI_P256 = Hacl_P256_ecp256dh_i(result, privateKey_P256);
	ok = ok && successDHI_P256;
	ok = ok && compare_and_print(lenP256, result, expectedPublicKeyX_P256);
	ok = ok && compare_and_print(lenP256, result + lenP256, expectedPublicKeyY_P256);



	uint8_t* pk = (uint8_t*) malloc (sizeof (uint8_t) * (lenP256 * 2));
	uint8_t* result_ecdh_p256 = (uint8_t*) malloc (sizeof (uint8_t) * (lenP256 * 2));
	memcpy(pk, publicKeyX1_P256, lenP256);
	memcpy(pk + lenP256, publicKeyY1_P256,  lenP256);
	   
	bool successDHR = Hacl_P256_ecp256dh_r(result, pk, privateKey_P256);
	ok = ok && successDHR;
	ok = ok && compare_and_print(lenP256, result, expectedResult_P256);



	int lenP384 = 48;
	
	uint8_t* result_p384 = (uint8_t*) malloc (sizeof (uint8_t) * (lenP384 * 2));

	for (int i = 0; i < (lenP384 * 2); i++)
		result_p384[i] = 0;

	bool successDHI_P384 = Hacl_P256_ecp384dh_i(result_p384, privateKey_P384);
	ok = ok && successDHI_P384;
	ok = ok && compare_and_print(lenP384, result_p384, expectedPublicKeyX_P384);
	ok = ok && compare_and_print(lenP384, result_p384 + lenP384, expectedPublicKeyY_P384);

	uint8_t* pk_p384 = (uint8_t*) malloc (sizeof (uint8_t) * (lenP384 * 2));
	uint8_t* result_ecdh_p384 = (uint8_t*) malloc (sizeof (uint8_t) * (lenP384 * 2));
	memcpy(pk_p384, publicKeyX1_P384, lenP384);
	memcpy(pk_p384 + lenP384, publicKeyY1_P384,  lenP384);
	   
	bool successDHR_p384 = Hacl_P256_ecp384dh_r(result_p384, pk_p384, privateKey_ecdh_r);
	ok = ok && successDHR_p384;
	ok = ok && compare_and_print(lenP384, result_p384, expectedResult_P384);



	// uint8_t* pk_ecdsa = (uint8_t*) malloc (sizeof (uint8_t) * 64);

	// static uint8_t pkx_0  [32] = { 
	// 0x29, 0x27, 0xb1, 0x05, 0x12, 0xba, 0xe3, 0xed, 0xdc, 0xfe, 0x46, 0x78, 0x28, 0x12, 0x8b, 0xad, 0x29, 0x03, 0x26, 0x99, 0x19, 0xf7, 0x08, 0x60, 0x69, 0xc8, 0xc4, 0xdf, 0x6c, 0x73, 0x28, 0x38}; 

	// static uint8_t pky_0  [32] = {
	// 0xc7, 0x78, 0x79, 0x64, 0xea, 0xac, 0x00, 0xe5, 0x92, 0x1f, 0xb1, 0x49, 0x8a, 0x60, 0xf4, 0x60, 0x67, 0x66, 0xb3, 0xd9, 0x68, 0x50, 0x01, 0x55, 0x8d, 0x1a, 0x97, 0x4e, 0x73, 0x41, 0x51, 0x3e};

	// #define mLen0 6 

	// static uint8_t msg_0  [6] = {
	// 0x31, 0x32, 0x33, 0x34, 0x30, 0x30
	// }; 

	// static uint8_t r_0  [32] = {
	// 0x2b, 0xa3, 0xa8, 0xbe, 0x6b, 0x94, 0xd5, 0xec, 0x80, 0xa6, 0xd9, 0xd1, 0x19, 0x0a, 0x43, 0x6e, 0xff, 0xe5, 0x0d, 0x85, 0xa1, 0xee, 0xe8, 0x59, 0xb8, 0xcc, 0x6a, 0xf9, 0xbd, 0x5c, 0x2e, 0x18
	// }; 

	// static uint8_t s_0  [32] = {
	// 0x4c, 0xd6, 0x0b, 0x85, 0x5d, 0x44, 0x2f, 0x5b, 0x3c, 0x7b, 0x11, 0xeb, 0x6c, 0x4e, 0x0a, 0xe7, 0x52, 0x5f, 0xe7, 0x10, 0xfa, 0xb9, 0xaa, 0x7c, 0x77, 0xa6, 0x7f, 0x79, 0xe6, 0xfa, 0xdd, 0x76
	// }; 

	// #define result___0 0

	// memcpy(pk_ecdsa, pkx_0, 32);
	// memcpy(pk_ecdsa + 32, pky_0, 32);


	// bool verificationSuccessful = Hacl_P256_ecdsa_verif_p256_sha2(mLen0, msg_0, pk, r_0, s_0);	
	// if (verificationSuccessful)	
	// 	ok = ok && true;
	// else
	// 	ok = ok && false;

	return ok;

	// privateKey_ecdh_r

}






	// uint8_t* pk = (uint8_t*) malloc (sizeof (uint8_t) * 64);
	// bool ok;

	// static uint8_t pkx_0  [32] = { 
	// 0x29, 0x27, 0xb1, 0x05, 0x12, 0xba, 0xe3, 0xed, 0xdc, 0xfe, 0x46, 0x78, 0x28, 0x12, 0x8b, 0xad, 0x29, 0x03, 0x26, 0x99, 0x19, 0xf7, 0x08, 0x60, 0x69, 0xc8, 0xc4, 0xdf, 0x6c, 0x73, 0x28, 0x38}; 

	// static uint8_t pky_0  [32] = {
	// 0xc7, 0x78, 0x79, 0x64, 0xea, 0xac, 0x00, 0xe5, 0x92, 0x1f, 0xb1, 0x49, 0x8a, 0x60, 0xf4, 0x60, 0x67, 0x66, 0xb3, 0xd9, 0x68, 0x50, 0x01, 0x55, 0x8d, 0x1a, 0x97, 0x4e, 0x73, 0x41, 0x51, 0x3e};

	// #define mLen0 6 

	// static uint8_t msg_0  [6] = {
	// 0x31, 0x32, 0x33, 0x34, 0x30, 0x30
	// }; 

	// static uint8_t r_0  [32] = {
	// 0x2b, 0xa3, 0xa8, 0xbe, 0x6b, 0x94, 0xd5, 0xec, 0x80, 0xa6, 0xd9, 0xd1, 0x19, 0x0a, 0x43, 0x6e, 0xff, 0xe5, 0x0d, 0x85, 0xa1, 0xee, 0xe8, 0x59, 0xb8, 0xcc, 0x6a, 0xf9, 0xbd, 0x5c, 0x2e, 0x18
	// }; 

	// static uint8_t s_0  [32] = {
	// 0x4c, 0xd6, 0x0b, 0x85, 0x5d, 0x44, 0x2f, 0x5b, 0x3c, 0x7b, 0x11, 0xeb, 0x6c, 0x4e, 0x0a, 0xe7, 0x52, 0x5f, 0xe7, 0x10, 0xfa, 0xb9, 0xaa, 0x7c, 0x77, 0xa6, 0x7f, 0x79, 0xe6, 0xfa, 0xdd, 0x76
	// }; 

	// #define result___0 0

	// memcpy(pk, pkx_0, 32);
	// memcpy(pk + 32, pky_0, 32);


	// bool verificationSuccessful = Hacl_P256_ecdsa_verif_p256_sha2_comb_radix(mLen0, msg_0, pk, r_0, s_0);	
	// if (verificationSuccessful)	
	// 	ok = true;
	// else
	// 	ok = false;

	// return true;

// https://cse.iitkgp.ac.in/~debdeep/osscrypto/psec/downloads/PSEC-KEM_prime.pdf


#define SIZE   32
#define ROUNDS 10000

int main()
{


	// if (test_nist())
	// 	printf("%s\n", "Testing is correct \n ");
	// else
	// {
	// 	printf("%s\n", "Testing is failed \n ");
	// 	return -1;
	// }


	cycles a,b;
	clock_t t1,t2;
	uint8_t* result = (uint8_t*) malloc (sizeof (uint8_t) * 32);

	uint64_t len = SIZE;

	uint8_t scalar[SIZE];
	memset(scalar,'P',SIZE);
	
  	for (int j = 0; j < ROUNDS; j++)
		Hacl_P256_ecp256dh_i(result, scalar);

	t1 = clock();
  	a = cpucycles_begin();

  	for (int j = 0; j < ROUNDS; j++)
		Hacl_P256_ecp256dh_i(result, scalar);
	
	b = cpucycles_end();
	
	t2 = clock();
	clock_t tdiff1 = t2 - t1;
	cycles cdiff1 = b - a;

	double time = (((double)tdiff1) / CLOCKS_PER_SEC);
	double nsigs = ((double)ROUNDS) / time;
	printf("HACL P-256 [SecretToPublic] PERF Ladder \n");
	printf("ECDH %8.2f mul/s\n",nsigs);

  	printf("cycles per function call:  %" PRIu64 " \n \n",(uint64_t)cdiff1/ROUNDS);










  return EXIT_SUCCESS;
}

// #include <inttypes.h>
// void printU(uint64_t* a, int len)
// {
//   for (int i = 0; i < len; i++)
//    printf("%" PRIx64 "\n",   a[i]);
// }


// p256 = 2**384 - 2**128 - 2**96 + 2**32 - 1
// a256 = p256 - 3
// b256 = 27580193559959705877849011840389048093056905856361568521428707301988689241309860865136260764883745107765439761230575

// gx = 0xaa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7
// gy = 0x3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f

// FF = GF(p256)

// EC = EllipticCurve([FF(a256), FF(b256)])

// r = getrandbits(384)
// G = EC(FF(gx), FF(gy)) * 20
// P = (G * r).xy()
// x, y = P

// import __future__ 

// def print_(r):
//     for i in range(384/8 -1, -1, -1):
//         print(hex((Integer(r) >> (i * 8)) % (2 ** 8)) +  ",", end = " ")
//     print("\n")

// print_(G.xy()[0])
// print_(G.xy()[1])
// print_(r)
// print_(x)
// print_(y)