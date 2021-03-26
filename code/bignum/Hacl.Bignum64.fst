module Hacl.Bignum64

open FStar.Mul

module BN = Hacl.Bignum
module BM = Hacl.Bignum.Montgomery
module BE = Hacl.Bignum.Exponentiation
module BR = Hacl.Bignum.ModReduction
module AM = Hacl.Bignum.AlmostMontgomery

#set-options "--z3rlimit 50 --fuel 0 --ifuel 0"

inline_for_extraction noextract
let kam (len:BN.meta_len t_limbs) =
  AM.mk_runtime_almost_mont #t_limbs len

inline_for_extraction noextract
let ke (len:BN.meta_len t_limbs) =
  BE.mk_runtime_exp #t_limbs len

let add len a b res =
  (ke len).BE.bn.BN.add a b res

let sub len a b res =
  (ke len).BE.bn.BN.sub a b res

let mul len a b res =
  (ke len).BE.bn.BN.mul a b res

let sqr len a res =
  (ke len).BE.bn.BN.sqr a res

let mod len n a res =
  BS.mk_bn_mod_slow_safe (kam len) (BR.bn_mod_slow_precompr2 (kam len)) n a res

// let mod_exp_vartime_precompr2 len n a bBits b r2 res =
//   BE.bn_mod_exp_vartime_precompr2 (ke len) n a bBits b r2 res

// let mod_exp_consttime_precompr2 len n a bBits b r2 res =
//   BE.bn_mod_exp_consttime_precompr2 (ke len) n a bBits b r2 res

let mod_exp_vartime len n a bBits b res =
  BS.mk_bn_mod_exp_safe (ke len) (ke len).BE.exp_vt n a bBits b res

let mod_exp_consttime len n a bBits b res =
  BS.mk_bn_mod_exp_safe (ke len) (ke len).BE.exp_ct n a bBits b res

// let new_precompr2 len r n =
//   BS.new_bn_precomp_r2_mod_n (ke len).BE.mont r n

let mod_inv_prime_vartime len n a res =
  BS.mk_bn_mod_inv_prime_safe len (ke len).BE.exp_vt n a res

let new_bn_from_bytes_be r len b =
  BS.new_bn_from_bytes_be r len b

let new_bn_from_bytes_le r len b =
  BS.new_bn_from_bytes_le r len b

let bn_to_bytes_be len b res =
  Hacl.Bignum.Convert.mk_bn_to_bytes_be len b res

let bn_to_bytes_le len b res =
  Hacl.Bignum.Convert.mk_bn_to_bytes_le len b res

let lt_mask len a b =
  BN.bn_lt_mask len a b
