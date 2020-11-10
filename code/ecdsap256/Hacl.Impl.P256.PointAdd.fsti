module Hacl.Impl.P256.PointAdd

open FStar.HyperStack.All
open FStar.HyperStack
module ST = FStar.HyperStack.ST

open Lib.IntTypes
open Lib.Buffer

open Hacl.Spec.P256.Definition
open Spec.P256
open Hacl.Spec.P256.MontgomeryMultiplication

#set-options "--z3rlimit 100"

val lemma_point_eval: c: curve -> h0: mem -> h1: mem -> p: point c -> Lemma
  (requires (point_eval c h0 p /\ as_seq h0 p == as_seq h1 p))
  (ensures (point_eval c h1 p))


val lemma_coord_eval: c: curve -> h0: mem -> h1 : mem -> p: point c -> 
  Lemma 
    (requires (as_seq h1 p == as_seq h0 p))
    (ensures (
      point_x_as_nat c h0 p == point_x_as_nat c h1 p /\
      point_y_as_nat c h0 p == point_y_as_nat c h1 p /\
      point_z_as_nat c h0 p == point_z_as_nat c h1 p))  


val point_add: #c: curve -> p: point c -> q: point c -> result: point c 
  -> tempBuffer: lbuffer uint64 (size 17 *! getCoordinateLenU64 c) -> 
   Stack unit (requires fun h -> 
     live h p /\ live h q /\ live h result /\ live h tempBuffer /\ 
     
     eq_or_disjoint q result /\ disjoint p q /\ disjoint p tempBuffer /\ 
     disjoint q tempBuffer /\ disjoint p result /\ disjoint result tempBuffer /\ 
     
     point_eval c h p /\ point_eval c h q
   )
   (ensures fun h0 _ h1 -> 
     modifies (loc tempBuffer |+| loc result) h0 h1 /\ point_eval c h1 result /\ (
     let pX, pY, pZ = point_x_as_nat c h0 p, point_y_as_nat c h0 p, point_z_as_nat c h0 p in 
     let qX, qY, qZ = point_x_as_nat c h0 q, point_y_as_nat c h0 q, point_z_as_nat c h0 q in 
     let x3, y3, z3 = point_x_as_nat c h1 result, point_y_as_nat c h1 result, point_z_as_nat c h1 result in 
     
     let pxD, pyD, pzD = fromDomain_ #c pX, fromDomain_ #c pY, fromDomain_ #c pZ in 
     let qxD, qyD, qzD = fromDomain_ #c qX, fromDomain_ #c qY, fromDomain_ #c qZ in 
     let x3D, y3D, z3D = fromDomain_ #c x3, fromDomain_ #c y3, fromDomain_ #c z3 in
      
     let xN, yN, zN = _point_add #c (pxD, pyD, pzD) (qxD, qyD, qzD) in 
     x3D == xN /\ y3D == yN /\ z3D == zN))
