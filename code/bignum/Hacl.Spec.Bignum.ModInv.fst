module Hacl.Spec.Bignum.ModInv

open FStar.Mul

open Lib.IntTypes
open Lib.Sequence
open Lib.LoopCombinators

open Hacl.Spec.Bignum.Definitions
open Hacl.Spec.Bignum

module Fermat = FStar.Math.Fermat
module Euclid = FStar.Math.Euclid
module BE = Hacl.Spec.Bignum.Exponentiation


#reset-options "--z3rlimit 50 --fuel 0 --ifuel 0"

#push-options "--fuel 1"
val pow_eq: a:nat -> n:nat -> Lemma (Fermat.pow a n == Lib.NatMod.pow a n)
let rec pow_eq a n =
  if n = 0 then ()
  else pow_eq a (n - 1)
#pop-options

val mod_inv_prime_lemma: n:nat{2 < n /\ Euclid.is_prime n} -> a:pos{a < n} ->
  Lemma (Lib.NatMod.pow_mod #n a (n - 2) * a % n = 1)

let mod_inv_prime_lemma n a =
  Math.Lemmas.small_mod a n;
  assert (a == a % n);
  assert (a <> 0 /\ a % n <> 0);

  calc (==) {
    Lib.NatMod.pow_mod #n a (n - 2) * a % n;
    (==) { Lib.NatMod.lemma_pow_mod #n a (n - 2) }
    Lib.NatMod.pow a (n - 2) % n * a % n;
    (==) { Math.Lemmas.lemma_mod_mul_distr_l (Lib.NatMod.pow a (n - 2)) a n }
    Lib.NatMod.pow a (n - 2) * a % n;
    (==) { Lib.NatMod.lemma_pow1 a; Lib.NatMod.lemma_pow_add a (n - 2) 1 }
    Lib.NatMod.pow a (n - 1) % n;
    (==) { pow_eq a (n - 1) }
    Fermat.pow a (n - 1) % n;
    (==) { Fermat.fermat_alt n a }
    1;
    }


val bn_mod_inv_prime:
    #nLen:size_pos{128 * nLen <= max_size_t}
  -> n:lbignum nLen
  -> a:lbignum nLen ->
  lbignum nLen

let bn_mod_inv_prime #nLen n a =
  let b2 = create 1 (u64 2) in
  let c, n2 = bn_sub n b2 in
  BE.bn_mod_exp nLen n a (64 * nLen) n2


val bn_mod_inv_prime_lemma:
    #nLen:size_pos{128 * nLen <= max_size_t}
  -> n:lbignum nLen
  -> a:lbignum nLen -> Lemma
  (requires
    bn_v n % 2 = 1 /\ 1 < bn_v n /\
    0 < bn_v a /\ bn_v a < bn_v n /\
    Euclid.is_prime (bn_v n))
  (ensures  (bn_v (bn_mod_inv_prime n a) * bn_v a % bn_v n = 1))

let bn_mod_inv_prime_lemma #nLen n a =
  let b2 = create 1 (u64 2) in
  bn_eval1 b2;
  assert (bn_v b2 = 2);

  let c, n2 = bn_sub n b2 in
  bn_sub_lemma n b2;
  assert (bn_v n2 - v c * pow2 (64 * nLen) == bn_v n - 2);
  bn_eval_bound n2 nLen;
  bn_eval_bound n nLen;
  assert (v c = 0);
  assert (bn_v n2 == bn_v n - 2);

  let res = BE.bn_mod_exp nLen n a (64 * nLen) n2 in
  BE.bn_mod_exp_lemma nLen n a (64 * nLen) n2;
  assert (bn_v res == Lib.NatMod.pow_mod #(bn_v n) (bn_v a) (bn_v n2));
  mod_inv_prime_lemma (bn_v n) (bn_v a)