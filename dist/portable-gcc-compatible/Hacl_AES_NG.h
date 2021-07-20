/* MIT License
 *
 * Copyright (c) 2016-2020 INRIA, CMU and Microsoft Corporation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */


#ifndef __Hacl_AES_NG_H
#define __Hacl_AES_NG_H

#if defined(__cplusplus)
extern "C" {
#endif

#include "evercrypt_targetconfig.h"
#include "libintvector.h"
#include "kremlin/internal/types.h"
#include "kremlin/lowstar_endianness.h"
#include <string.h>
#include "kremlin/internal/target.h"


#include "Hacl_Kremlib.h"
#include "Hacl_Spec.h"

/* SNIPPET_START: Hacl_AES_128_BitSlice_aes_ctx */

typedef uint64_t *Hacl_AES_128_BitSlice_aes_ctx;

/* SNIPPET_END: Hacl_AES_128_BitSlice_aes_ctx */

/* SNIPPET_START: Hacl_AES_128_BitSlice_skey */

typedef uint8_t *Hacl_AES_128_BitSlice_skey;

/* SNIPPET_END: Hacl_AES_128_BitSlice_skey */

/* SNIPPET_START: Hacl_AES_128_BitSlice_aes128_init */

void Hacl_AES_128_BitSlice_aes128_init(uint64_t *ctx, uint8_t *key, uint8_t *nonce);

/* SNIPPET_END: Hacl_AES_128_BitSlice_aes128_init */

/* SNIPPET_START: Hacl_AES_128_BitSlice_aes128_set_nonce */

void Hacl_AES_128_BitSlice_aes128_set_nonce(uint64_t *ctx, uint8_t *nonce);

/* SNIPPET_END: Hacl_AES_128_BitSlice_aes128_set_nonce */

/* SNIPPET_START: Hacl_AES_128_BitSlice_aes128_key_block */

void Hacl_AES_128_BitSlice_aes128_key_block(uint8_t *kb, uint64_t *ctx, uint32_t counter);

/* SNIPPET_END: Hacl_AES_128_BitSlice_aes128_key_block */

/* SNIPPET_START: Hacl_AES_128_BitSlice_aes128_update4 */

void
Hacl_AES_128_BitSlice_aes128_update4(uint8_t *out, uint8_t *inp, uint64_t *ctx, uint32_t ctr);

/* SNIPPET_END: Hacl_AES_128_BitSlice_aes128_update4 */

/* SNIPPET_START: Hacl_AES_128_BitSlice_aes128_ctr */

void
Hacl_AES_128_BitSlice_aes128_ctr(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint64_t *ctx,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_128_BitSlice_aes128_ctr */

/* SNIPPET_START: Hacl_AES_128_BitSlice_aes128_ctr_encrypt */

void
Hacl_AES_128_BitSlice_aes128_ctr_encrypt(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint8_t *k,
  uint8_t *n,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_128_BitSlice_aes128_ctr_encrypt */

/* SNIPPET_START: Hacl_AES_128_BitSlice_aes128_ctr_decrypt */

void
Hacl_AES_128_BitSlice_aes128_ctr_decrypt(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint8_t *k,
  uint8_t *n,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_128_BitSlice_aes128_ctr_decrypt */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes_ctx */

typedef uint64_t *Hacl_AES_256_BitSlice_aes_ctx;

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes_ctx */

/* SNIPPET_START: Hacl_AES_256_BitSlice_skey */

typedef uint8_t *Hacl_AES_256_BitSlice_skey;

/* SNIPPET_END: Hacl_AES_256_BitSlice_skey */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes256_init */

void Hacl_AES_256_BitSlice_aes256_init(uint64_t *ctx, uint8_t *key, uint8_t *nonce);

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes256_init */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes256_encrypt_block */

void Hacl_AES_256_BitSlice_aes256_encrypt_block(uint8_t *ob, uint64_t *ctx, uint8_t *ib);

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes256_encrypt_block */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes256_set_nonce */

void Hacl_AES_256_BitSlice_aes256_set_nonce(uint64_t *ctx, uint8_t *nonce);

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes256_set_nonce */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes256_key_block */

void Hacl_AES_256_BitSlice_aes256_key_block(uint8_t *kb, uint64_t *ctx, uint32_t counter);

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes256_key_block */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes256_update4 */

void
Hacl_AES_256_BitSlice_aes256_update4(uint8_t *out, uint8_t *inp, uint64_t *ctx, uint32_t ctr);

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes256_update4 */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes256_ctr */

void
Hacl_AES_256_BitSlice_aes256_ctr(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint64_t *ctx,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes256_ctr */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes256_ctr_encrypt */

void
Hacl_AES_256_BitSlice_aes256_ctr_encrypt(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint8_t *k,
  uint8_t *n,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes256_ctr_encrypt */

/* SNIPPET_START: Hacl_AES_256_BitSlice_aes256_ctr_decrypt */

void
Hacl_AES_256_BitSlice_aes256_ctr_decrypt(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint8_t *k,
  uint8_t *n,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_256_BitSlice_aes256_ctr_decrypt */

/* SNIPPET_START: Hacl_AES_128_NI_aes_ctx */

typedef Lib_IntVector_Intrinsics_vec128 *Hacl_AES_128_NI_aes_ctx;

/* SNIPPET_END: Hacl_AES_128_NI_aes_ctx */

/* SNIPPET_START: Hacl_AES_128_NI_skey */

typedef uint8_t *Hacl_AES_128_NI_skey;

/* SNIPPET_END: Hacl_AES_128_NI_skey */

/* SNIPPET_START: Hacl_AES_128_NI_aes128_init */

void
Hacl_AES_128_NI_aes128_init(Lib_IntVector_Intrinsics_vec128 *ctx, uint8_t *key, uint8_t *nonce);

/* SNIPPET_END: Hacl_AES_128_NI_aes128_init */

/* SNIPPET_START: Hacl_AES_128_NI_aes128_set_nonce */

void Hacl_AES_128_NI_aes128_set_nonce(Lib_IntVector_Intrinsics_vec128 *ctx, uint8_t *nonce);

/* SNIPPET_END: Hacl_AES_128_NI_aes128_set_nonce */

/* SNIPPET_START: Hacl_AES_128_NI_aes128_key_block */

void
Hacl_AES_128_NI_aes128_key_block(
  uint8_t *kb,
  Lib_IntVector_Intrinsics_vec128 *ctx,
  uint32_t counter
);

/* SNIPPET_END: Hacl_AES_128_NI_aes128_key_block */

/* SNIPPET_START: Hacl_AES_128_NI_aes128_update4 */

void
Hacl_AES_128_NI_aes128_update4(
  uint8_t *out,
  uint8_t *inp,
  Lib_IntVector_Intrinsics_vec128 *ctx,
  uint32_t ctr
);

/* SNIPPET_END: Hacl_AES_128_NI_aes128_update4 */

/* SNIPPET_START: Hacl_AES_128_NI_aes128_ctr */

void
Hacl_AES_128_NI_aes128_ctr(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  Lib_IntVector_Intrinsics_vec128 *ctx,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_128_NI_aes128_ctr */

/* SNIPPET_START: Hacl_AES_128_NI_aes128_ctr_encrypt */

void
Hacl_AES_128_NI_aes128_ctr_encrypt(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint8_t *k,
  uint8_t *n,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_128_NI_aes128_ctr_encrypt */

/* SNIPPET_START: Hacl_AES_128_NI_aes128_ctr_decrypt */

void
Hacl_AES_128_NI_aes128_ctr_decrypt(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint8_t *k,
  uint8_t *n,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_128_NI_aes128_ctr_decrypt */

/* SNIPPET_START: Hacl_AES_256_NI_aes_ctx */

typedef Lib_IntVector_Intrinsics_vec128 *Hacl_AES_256_NI_aes_ctx;

/* SNIPPET_END: Hacl_AES_256_NI_aes_ctx */

/* SNIPPET_START: Hacl_AES_256_NI_skey */

typedef uint8_t *Hacl_AES_256_NI_skey;

/* SNIPPET_END: Hacl_AES_256_NI_skey */

/* SNIPPET_START: Hacl_AES_256_NI_aes256_init */

void
Hacl_AES_256_NI_aes256_init(Lib_IntVector_Intrinsics_vec128 *ctx, uint8_t *key, uint8_t *nonce);

/* SNIPPET_END: Hacl_AES_256_NI_aes256_init */

/* SNIPPET_START: Hacl_AES_256_NI_aes256_encrypt_block */

void
Hacl_AES_256_NI_aes256_encrypt_block(
  uint8_t *ob,
  Lib_IntVector_Intrinsics_vec128 *ctx,
  uint8_t *ib
);

/* SNIPPET_END: Hacl_AES_256_NI_aes256_encrypt_block */

/* SNIPPET_START: Hacl_AES_256_NI_aes256_set_nonce */

void Hacl_AES_256_NI_aes256_set_nonce(Lib_IntVector_Intrinsics_vec128 *ctx, uint8_t *nonce);

/* SNIPPET_END: Hacl_AES_256_NI_aes256_set_nonce */

/* SNIPPET_START: Hacl_AES_256_NI_aes256_key_block */

void
Hacl_AES_256_NI_aes256_key_block(
  uint8_t *kb,
  Lib_IntVector_Intrinsics_vec128 *ctx,
  uint32_t counter
);

/* SNIPPET_END: Hacl_AES_256_NI_aes256_key_block */

/* SNIPPET_START: Hacl_AES_256_NI_aes256_update4 */

void
Hacl_AES_256_NI_aes256_update4(
  uint8_t *out,
  uint8_t *inp,
  Lib_IntVector_Intrinsics_vec128 *ctx,
  uint32_t ctr
);

/* SNIPPET_END: Hacl_AES_256_NI_aes256_update4 */

/* SNIPPET_START: Hacl_AES_256_NI_aes256_ctr */

void
Hacl_AES_256_NI_aes256_ctr(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  Lib_IntVector_Intrinsics_vec128 *ctx,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_256_NI_aes256_ctr */

/* SNIPPET_START: Hacl_AES_256_NI_aes256_ctr_encrypt */

void
Hacl_AES_256_NI_aes256_ctr_encrypt(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint8_t *k,
  uint8_t *n,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_256_NI_aes256_ctr_encrypt */

/* SNIPPET_START: Hacl_AES_256_NI_aes256_ctr_decrypt */

void
Hacl_AES_256_NI_aes256_ctr_decrypt(
  uint32_t len,
  uint8_t *out,
  uint8_t *inp,
  uint8_t *k,
  uint8_t *n,
  uint32_t c
);

/* SNIPPET_END: Hacl_AES_256_NI_aes256_ctr_decrypt */

#if defined(__cplusplus)
}
#endif

#define __Hacl_AES_NG_H_DEFINED
#endif
