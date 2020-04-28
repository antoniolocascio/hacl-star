module Hacl.Impl.SHA2.Core

open FStar.Mul
open FStar.HyperStack
open FStar.HyperStack.All

open Lib.IntTypes
open Lib.NTuple
open Lib.Buffer
open Lib.IntVector
open Lib.MultiBuffer

open Spec.Hash.Definitions
open Hacl.Hash.Definitions
open Hacl.Spec.SHA2.Vec


module ST = FStar.HyperStack.ST
module NTup = Lib.NTuple
module Constants = Spec.SHA2.Constants
module Spec = Hacl.Spec.SHA2
module SpecVec = Hacl.Spec.SHA2.Vec
module VecTranspose = Lib.IntVector.Transpose
module LSeq = Lib.Sequence


#set-options "--max_fuel 0 --max_ifuel 0 --z3rlimit 50"

(** Top-level constant arrays for the SHA2 algorithms. *)

let h224 : x:glbuffer uint32 8ul{witnessed x Constants.h224 /\ recallable x} =
  createL_global Constants.h224_l
let h256 : x:glbuffer uint32 8ul{witnessed x Constants.h256 /\ recallable x} =
  createL_global Constants.h256_l
let h384 : x:glbuffer uint64 8ul{witnessed x Constants.h384 /\ recallable x} =
  createL_global Constants.h384_l
let h512 : x:glbuffer uint64 8ul{witnessed x Constants.h512 /\ recallable x} =
  createL_global Constants.h512_l


noextract inline_for_extraction
let index_h0 (a: sha2_alg) (i: size_t) : Stack (word a)
  (requires (fun _ -> size_v i < 8))
  (ensures (fun h0 r h1 ->
    h0 == h1 /\
    r == Seq.index (Spec.h0 a) (size_v i))) =
    match a with
    | SHA2_224 -> recall h224; recall_contents h224 Constants.h224; h224.(i)
    | SHA2_256 -> recall h256; recall_contents h256 Constants.h256; h256.(i)
    | SHA2_384 -> recall h384; recall_contents h384 Constants.h384; h384.(i)
    | SHA2_512 -> recall h512; recall_contents h512 Constants.h512; h512.(i)


let k224_256 : x:glbuffer uint32 64ul{witnessed x Constants.k224_256 /\ recallable x} =
  createL_global Constants.k224_256_l

let k384_512 : x:glbuffer uint64 80ul{witnessed x Constants.k384_512 /\ recallable x} =
  createL_global Constants.k384_512_l


noextract inline_for_extraction
let index_k0 (a:sha2_alg) (i:size_t) : Stack (word a)
  (requires (fun _ -> size_v i < Spec.size_k_w a))
  (ensures (fun h0 r h1 ->
    h0 == h1 /\
    r == Seq.index (Spec.k0 a) (size_v i))) =
  match a with
  | SHA2_224 | SHA2_256 ->
      recall_contents k224_256 Constants.k224_256;
      k224_256.(i)
  | SHA2_384 | SHA2_512 ->
      recall_contents k384_512 Constants.k384_512;
      k384_512.(i)


unfold let block_t (a:sha2_alg) =
  lbuffer uint8 (block_len a)

inline_for_extraction
let ws_t (a:sha2_alg) (m:m_spec) =
  lbuffer (element_t a m) 16ul

inline_for_extraction
val shuffle_core: #a: sha2_alg -> #m:m_spec ->
  k_t: word a ->
  ws_t: element_t a m ->
  st: state_t a m ->
  Stack unit
    (requires (fun h -> live h st))
    (ensures (fun h0 _ h1 ->
      modifies (loc st) h0 h1 /\
      as_seq h1 st ==
      SpecVec.shuffle_core_spec k_t ws_t (as_seq h0 st)))

#push-options "--z3rlimit 400"
let shuffle_core #a #m k_t ws_t st =
  let hp0 = ST.get() in
  let a0 = st.(0ul) in
  let b0 = st.(1ul) in
  let c0 = st.(2ul) in
  let d0 = st.(3ul) in
  let e0 = st.(4ul) in
  let f0 = st.(5ul) in
  let g0 = st.(6ul) in
  let h0 = st.(7ul) in
  let k_e_t = load_element a m k_t in
  let t1 = h0 +| (_Sigma1 e0) +| (_Ch e0 f0 g0) +| k_e_t +| ws_t in
  let t2 = (_Sigma0 a0) +| (_Maj a0 b0 c0) in
  let a1 = t1 +| t2 in
  let b1 = a0 in
  let c1 = b0 in
  let d1 = c0 in
  let e1 = d0 +| t1 in
  let f1 = e0 in
  let g1 = f0 in
  let h1 = g0 in
  st.(0ul) <- a1;
  st.(1ul) <- b1;
  st.(2ul) <- c1;
  st.(3ul) <- d1;
  st.(4ul) <- e1;
  st.(5ul) <- f1;
  st.(6ul) <- g1;
  st.(7ul) <- h1;
  let h1 = ST.get() in
  LSeq.eq_intro (as_seq h1 st)
           (shuffle_core_spec k_t ws_t (as_seq hp0 st))
#pop-options

inline_for_extraction
val set_wsi (#a:sha2_alg) (#m:m_spec) (ws:ws_t a m) (i:size_t{v i < 16}) (b:lbuffer uint8 (block_len a)) (bi:size_t{v bi < 16 / (lanes a m)}):
            Stack unit
            (requires (fun h -> live h b /\ live h ws /\ disjoint b ws))
            (ensures (fun h0 _ h1 -> modifies (loc ws) h0 h1 /\
                                    as_seq h1 ws == LSeq.upd (as_seq h0 ws) (v i)
                                                    (SpecVec.load_elementi #a #m (as_seq h0 b) (v bi))))
#push-options "--z3rlimit 100"
let set_wsi #a #m ws i b bi =
  [@inline_let]
  let l = lanes a m in
  ws.(i) <- vec_load_be (word_t a) l (sub b (bi *. size l *. word_len a) (size l *. word_len a))
#pop-options

noextract
let load_blocks_spec1 (#a:sha2_alg) (#m:m_spec{lanes a m == 1}) (b:multiblock_spec a m) : ws_spec a m =
  let b = b.(|0|) in
  let ws0 = SpecVec.load_elementi b 0 in
  let ws1 = SpecVec.load_elementi b 1 in
  let ws2 = SpecVec.load_elementi b 2 in
  let ws3 = SpecVec.load_elementi b 3 in
  let ws4 = SpecVec.load_elementi b 4 in
  let ws5 = SpecVec.load_elementi b 5 in
  let ws6 = SpecVec.load_elementi b 6 in
  let ws7 = SpecVec.load_elementi b 7 in
  let ws8 = SpecVec.load_elementi b 8 in
  let ws9 = SpecVec.load_elementi b 9 in
  let ws10 = SpecVec.load_elementi b 10 in
  let ws11 = SpecVec.load_elementi b 11 in
  let ws12 = SpecVec.load_elementi b 12 in
  let ws13 = SpecVec.load_elementi b 13 in
  let ws14 = SpecVec.load_elementi b 14 in
  let ws15 = SpecVec.load_elementi b 15 in
  create16 ws0 ws1 ws2 ws3 ws4 ws5 ws6 ws7
           ws8 ws9 ws10 ws11 ws12 ws13 ws14 ws15

noextract
let load_blocks_spec1_lemma (#a:sha2_alg) (#m:m_spec{lanes a m == 1}) (b:multiblock_spec a m) :
  Lemma (SpecVec.load_blocks b == load_blocks_spec1 b) =
  LSeq.eq_intro (SpecVec.load_blocks b) (load_blocks_spec1 b)

inline_for_extraction
val load_blocks1 (#a: sha2_alg) (#m:m_spec{lanes a m == 1})
                 (b: multibuf (lanes a m) (block_len a)) (ws: ws_t a m):
    Stack unit
    (requires (fun h -> live_multi h b /\ live h ws /\ disjoint_multi b ws))
    (ensures (fun h0 _ h1 -> modifies (loc ws) h0 h1 /\
                           as_seq h1 ws ==
                           SpecVec.load_blocks (as_seq_multi h0 b)))
#push-options "--z3rlimit 100"
let load_blocks1 #a #m ib ws =
  let h0 = ST.get() in
  let b = ib.(|0|) in
  set_wsi ws 0ul b 0ul;
  set_wsi ws 1ul b 1ul;
  set_wsi ws 2ul b 2ul;
  set_wsi ws 3ul b 3ul;
  set_wsi ws 4ul b 4ul;
  set_wsi ws 5ul b 5ul;
  set_wsi ws 6ul b 6ul;
  let h1 = ST.get() in
  assert (modifies (loc ws) h0 h1);
  set_wsi ws 7ul b 7ul;
  set_wsi ws 8ul b 8ul;
  set_wsi ws 9ul b 9ul;
  set_wsi ws 10ul b 10ul;
  set_wsi ws 11ul b 11ul;
  set_wsi ws 12ul b 12ul;
  set_wsi ws 13ul b 13ul;
  set_wsi ws 14ul b 14ul;
  set_wsi ws 15ul b 15ul;
  let h1 = ST.get() in
  assert (modifies (loc ws) h0 h1);
  LSeq.eq_intro (as_seq h1 ws) (load_blocks_spec1 (as_seq_multi h0 ib));
  load_blocks_spec1_lemma #a #m (as_seq_multi h0 ib);
  assert (as_seq h1 ws == load_blocks_spec1 (as_seq_multi h0 ib));
  assert (as_seq h1 ws == SpecVec.load_blocks (as_seq_multi h0 ib))
#pop-options

noextract
let load_blocks_spec4 (#a:sha2_alg) (#m:m_spec{lanes a m == 4}) (b:multiblock_spec a m) : ws_spec a m =
  let b0 = b.(|0|) in
  let b1 = b.(|1|) in
  let b2 = b.(|2|) in
  let b3 = b.(|3|) in
  let ws0 = SpecVec.load_elementi b0 0 in
  let ws1 = SpecVec.load_elementi b1 0 in
  let ws2 = SpecVec.load_elementi b2 0 in
  let ws3 = SpecVec.load_elementi b3 0 in
  let ws4 = SpecVec.load_elementi b0 1 in
  let ws5 = SpecVec.load_elementi b1 1 in
  let ws6 = SpecVec.load_elementi b2 1 in
  let ws7 = SpecVec.load_elementi b3 1 in
  let ws8 = SpecVec.load_elementi b0 2 in
  let ws9 = SpecVec.load_elementi b1 2 in
  let ws10 = SpecVec.load_elementi b2 2 in
  let ws11 = SpecVec.load_elementi b3 2 in
  let ws12 = SpecVec.load_elementi b0 3 in
  let ws13 = SpecVec.load_elementi b1 3 in
  let ws14 = SpecVec.load_elementi b2 3 in
  let ws15 = SpecVec.load_elementi b3 3 in
  create16 ws0 ws1 ws2 ws3 ws4 ws5 ws6 ws7
           ws8 ws9 ws10 ws11 ws12 ws13 ws14 ws15

noextract
let load_blocks_spec4_lemma (#a:sha2_alg) (#m:m_spec{lanes a m == 4}) (b:multiblock_spec a m) :
  Lemma (SpecVec.load_blocks b == load_blocks_spec4 b) =
  LSeq.eq_intro (SpecVec.load_blocks b) (load_blocks_spec4 b)

inline_for_extraction
val load_blocks4 (#a: sha2_alg) (#m:m_spec{lanes a m == 4})
                 (b: multibuf (lanes a m) (block_len a)) (ws: ws_t a m):
    Stack unit
    (requires (fun h -> live_multi h b /\ live h ws /\ disjoint_multi b ws))
    (ensures (fun h0 _ h1 -> modifies (loc ws) h0 h1 /\
                           as_seq h1 ws ==
                           SpecVec.load_blocks (as_seq_multi h0 b)))
#push-options "--z3rlimit 150"
let load_blocks4 #a #m ib ws =
  let h0 = ST.get() in
  let (b0,(b1,(b2,b3))) = NTup.tup4 ib in
  set_wsi ws 0ul b0 0ul;
  set_wsi ws 1ul b1 0ul;
  set_wsi ws 2ul b2 0ul;
  set_wsi ws 3ul b3 0ul;
  set_wsi ws 4ul b0 1ul;
  set_wsi ws 5ul b1 1ul;
  set_wsi ws 6ul b2 1ul;
  let h1 = ST.get() in
  assert (modifies (loc ws) h0 h1);
  set_wsi ws 7ul b3 1ul;
  set_wsi ws 8ul b0 2ul;
  set_wsi ws 9ul b1 2ul;
  set_wsi ws 10ul b2 2ul;
  set_wsi ws 11ul b3 2ul;
  set_wsi ws 12ul b0 3ul;
  set_wsi ws 13ul b1 3ul;
  set_wsi ws 14ul b2 3ul;
  set_wsi ws 15ul b3 3ul;
  let h1 = ST.get() in
  assert (modifies (loc ws) h0 h1);
  LSeq.eq_intro (as_seq h1 ws) (load_blocks_spec4 (as_seq_multi h0 ib));
  load_blocks_spec4_lemma #a #m (as_seq_multi h0 ib);
  assert (as_seq h1 ws == load_blocks_spec4 (as_seq_multi h0 ib));
  assert (as_seq h1 ws == SpecVec.load_blocks (as_seq_multi h0 ib));
  ()
#pop-options

noextract
let load_blocks_spec8 (#a:sha2_alg) (#m:m_spec{lanes a m == 8}) (b:multiblock_spec a m) : ws_spec a m =
  let b0 = b.(|0|) in
  let b1 = b.(|1|) in
  let b2 = b.(|2|) in
  let b3 = b.(|3|) in
  let b4 = b.(|4|) in
  let b5 = b.(|5|) in
  let b6 = b.(|6|) in
  let b7 = b.(|7|) in
  let ws0 = SpecVec.load_elementi b0 0 in
  let ws1 = SpecVec.load_elementi b1 0 in
  let ws2 = SpecVec.load_elementi b2 0 in
  let ws3 = SpecVec.load_elementi b3 0 in
  let ws4 = SpecVec.load_elementi b4 0 in
  let ws5 = SpecVec.load_elementi b5 0 in
  let ws6 = SpecVec.load_elementi b6 0 in
  let ws7 = SpecVec.load_elementi b7 0 in
  let ws8 = SpecVec.load_elementi b0 1 in
  let ws9 = SpecVec.load_elementi b1 1 in
  let ws10 = SpecVec.load_elementi b2 1 in
  let ws11 = SpecVec.load_elementi b3 1 in
  let ws12 = SpecVec.load_elementi b4 1 in
  let ws13 = SpecVec.load_elementi b5 1 in
  let ws14 = SpecVec.load_elementi b6 1 in
  let ws15 = SpecVec.load_elementi b7 1 in
  create16 ws0 ws1 ws2 ws3 ws4 ws5 ws6 ws7
           ws8 ws9 ws10 ws11 ws12 ws13 ws14 ws15

noextract
let load_blocks_spec8_lemma (#a:sha2_alg) (#m:m_spec{lanes a m == 8}) (b:multiblock_spec a m) :
  Lemma (SpecVec.load_blocks b == load_blocks_spec8 b) =
  LSeq.eq_intro (SpecVec.load_blocks b) (load_blocks_spec8 b)

inline_for_extraction
val load_blocks8 (#a: sha2_alg) (#m:m_spec{lanes a m == 8})
                 (b: multibuf (lanes a m) (block_len a)) (ws: ws_t a m):
    Stack unit
    (requires (fun h -> live_multi h b /\ live h ws /\ disjoint_multi b ws))
    (ensures (fun h0 _ h1 -> modifies (loc ws) h0 h1 /\
                           as_seq h1 ws ==
                           SpecVec.load_blocks (as_seq_multi h0 b)))
#push-options "--z3rlimit 150"
let load_blocks8 #a #m ib ws =
  let h0 = ST.get() in
  let (b0,(b1,(b2,(b3,(b4,(b5,(b6,b7))))))) = NTup.tup8 ib in
  set_wsi ws 0ul b0 0ul;
  set_wsi ws 1ul b1 0ul;
  set_wsi ws 2ul b2 0ul;
  set_wsi ws 3ul b3 0ul;
  set_wsi ws 4ul b4 0ul;
  set_wsi ws 5ul b5 0ul;
  set_wsi ws 6ul b6 0ul;
  let h1 = ST.get() in
  assert (modifies (loc ws) h0 h1);
  set_wsi ws 7ul b7 0ul;
  set_wsi ws 8ul b0 1ul;
  set_wsi ws 9ul b1 1ul;
  set_wsi ws 10ul b2 1ul;
  set_wsi ws 11ul b3 1ul;
  set_wsi ws 12ul b4 1ul;
  set_wsi ws 13ul b5 1ul;
  set_wsi ws 14ul b6 1ul;
  set_wsi ws 15ul b7 1ul;
  let h1 = ST.get() in
  assert (modifies (loc ws) h0 h1);
  LSeq.eq_intro (as_seq h1 ws) (load_blocks_spec8 (as_seq_multi h0 ib));
  load_blocks_spec8_lemma #a #m (as_seq_multi h0 ib);
  assert (as_seq h1 ws == load_blocks_spec8 (as_seq_multi h0 ib));
  assert (as_seq h1 ws == SpecVec.load_blocks (as_seq_multi h0 ib));
  ()
#pop-options

inline_for_extraction
val load_blocks (#a: sha2_alg) (#m:m_spec)
                (b: multibuf (lanes a m) (block_len a)) (ws: ws_t a m):
    Stack unit
    (requires (fun h -> live_multi h b /\ live h ws /\ disjoint_multi b ws))
    (ensures (fun h0 _ h1 -> modifies (loc ws) h0 h1 /\
                           as_seq h1 ws ==
                           SpecVec.load_blocks (as_seq_multi h0 b)))

let load_blocks #a #m b ws =
  match lanes a m with
  | 1 -> load_blocks1 b ws
  | 4 -> load_blocks4 b ws
  | 8 -> load_blocks8 b ws
  | _ -> admit()


inline_for_extraction
val transpose_ws4 (#a: sha2_alg) (#m:m_spec{lanes a m == 4}) (ws: ws_t a m):
    Stack unit
    (requires (fun h -> live h ws))
    (ensures (fun h0 _ h1 -> modifies (loc ws) h0 h1 /\
                           as_seq h1 ws ==
                           SpecVec.transpose_ws (as_seq h0 ws)))

let transpose_ws4 #a #m ws =
  let h0 = ST.get() in
  let (ws0,ws1,ws2,ws3) = VecTranspose.transpose4x4 (ws.(0ul),ws.(1ul),ws.(2ul),ws.(3ul)) in
  let (ws4,ws5,ws6,ws7) = VecTranspose.transpose4x4 (ws.(4ul),ws.(5ul),ws.(6ul),ws.(7ul)) in
  let (ws8,ws9,ws10,ws11) = VecTranspose.transpose4x4 (ws.(8ul),ws.(9ul),ws.(10ul),ws.(11ul)) in
  let (ws12,ws13,ws14,ws15) = VecTranspose.transpose4x4 (ws.(12ul),ws.(13ul),ws.(14ul),ws.(15ul)) in
  ws.(0ul) <- ws0;
  ws.(1ul) <- ws1;
  ws.(2ul) <- ws2;
  ws.(3ul) <- ws3;
  ws.(4ul) <- ws4;
  ws.(5ul) <- ws5;
  ws.(6ul) <- ws6;
  ws.(7ul) <- ws7;
  ws.(8ul) <- ws8;
  ws.(9ul) <- ws9;
  ws.(10ul) <- ws10;
  ws.(11ul) <- ws11;
  ws.(12ul) <- ws12;
  ws.(13ul) <- ws13;
  ws.(14ul) <- ws14;
  ws.(15ul) <- ws15;
  let h1 = ST.get() in
  LSeq.eq_intro (as_seq h1 ws) (SpecVec.transpose_ws (as_seq h0 ws))

inline_for_extraction
val transpose_ws8 (#a: sha2_alg) (#m:m_spec{lanes a m == 8}) (ws: ws_t a m):
    Stack unit
    (requires (fun h -> live h ws))
    (ensures (fun h0 _ h1 -> modifies (loc ws) h0 h1 /\
                           as_seq h1 ws ==
                           SpecVec.transpose_ws (as_seq h0 ws)))

let transpose_ws8 #a #m ws =
  let h0 = ST.get() in
  let (ws0,ws1,ws2,ws3,ws4,ws5,ws6,ws7) = VecTranspose.transpose8x8 (ws.(0ul),ws.(1ul),ws.(2ul),ws.(3ul),ws.(4ul),ws.(5ul),ws.(6ul),ws.(7ul)) in
  let (ws8,ws9,ws10,ws11,ws12,ws13,ws14,ws15) = VecTranspose.transpose8x8 (ws.(8ul),ws.(9ul),ws.(10ul),ws.(11ul),ws.(12ul),ws.(13ul),ws.(14ul),ws.(15ul)) in
  ws.(0ul) <- ws0;
  ws.(1ul) <- ws1;
  ws.(2ul) <- ws2;
  ws.(3ul) <- ws3;
  ws.(4ul) <- ws4;
  ws.(5ul) <- ws5;
  ws.(6ul) <- ws6;
  ws.(7ul) <- ws7;
  ws.(8ul) <- ws8;
  ws.(9ul) <- ws9;
  ws.(10ul) <- ws10;
  ws.(11ul) <- ws11;
  ws.(12ul) <- ws12;
  ws.(13ul) <- ws13;
  ws.(14ul) <- ws14;
  ws.(15ul) <- ws15;
  let h1 = ST.get() in
  LSeq.eq_intro (as_seq h1 ws) (SpecVec.transpose_ws8 (as_seq h0 ws))



inline_for_extraction
val transpose_ws (#a: sha2_alg) (#m:m_spec) (ws: ws_t a m):
    Stack unit
    (requires (fun h -> live h ws))
    (ensures (fun h0 _ h1 -> modifies (loc ws) h0 h1 /\
                           as_seq h1 ws ==
                           SpecVec.transpose_ws (as_seq h0 ws)))
let transpose_ws #a #m ws =
  match lanes a m with
  | 1 -> ()
  | 4 -> transpose_ws4 ws
  | 8 -> transpose_ws8 ws
  | _ -> admit()


inline_for_extraction
val load_ws (#a: sha2_alg) (#m:m_spec)
            (b: multibuf (lanes a m) (block_len a)) (ws: ws_t a m):
    Stack unit
    (requires (fun h ->
      live_multi h b /\ live h ws /\ disjoint_multi b ws))
    (ensures (fun h0 _ h1 ->
      modifies (loc ws) h0 h1 /\
      as_seq h1 ws == SpecVec.load_ws #a #m (as_seq_multi h0 b)))
let load_ws #a #m b ws =
    let h0 = ST.get() in
    load_blocks b ws;
    transpose_ws ws

#push-options "--z3rlimit 300"
inline_for_extraction
val ws_next (#a: sha2_alg) (#m:m_spec)
            (ws: ws_t a m):
    Stack unit
    (requires (fun h -> live h ws))
    (ensures (fun h0 _ h1 ->
      modifies (loc ws) h0 h1 /\
      as_seq h1 ws == SpecVec.ws_next (as_seq h0 ws)))
let ws_next #a #m ws =
  let h0 = ST.get() in
  loop1 h0 16ul ws
    (fun h -> ws_next_inner #a #m)
    (fun i ->
      Lib.LoopCombinators.unfold_repeati 16 (ws_next_inner #a #m) (as_seq h0 ws) (v i);
      let t16 = ws.(i) in
      let t15 = ws.((i+.1ul) %. 16ul) in
      let t7  = ws.((i+.9ul) %. 16ul) in
      let t2  = ws.((i+.14ul) %. 16ul) in
      let s1 = _sigma1 t2 in
      let s0 = _sigma0 t15 in
      ws.(i) <- (s1 +| t7 +| s0 +| t16))
#pop-options

inline_for_extraction
val shuffle: #a:sha2_alg -> #m:m_spec -> ws:ws_t a m -> hash:state_t a m ->
    Stack unit
    (requires (fun h ->
      live h hash /\ live h ws /\
      disjoint hash ws))
    (ensures (fun h0 _ h1 ->
      modifies2 ws hash h0 h1 /\
      as_seq h1 hash == SpecVec.shuffle #a #m (as_seq h0 ws) (as_seq h0 hash)))

let shuffle #a #m ws hash =
  let h0 = ST.get() in
  loop2 h0 (num_rounds16 a) ws hash
    (fun h -> shuffle_inner_loop #a #m)
    (fun i ->
      Lib.LoopCombinators.unfold_repeati (v (num_rounds16 a)) (shuffle_inner_loop #a #m) (as_seq h0 ws, as_seq h0 hash) (v i);
      let h1 = ST.get() in
      loop1 h1 16ul hash
      (fun h -> shuffle_inner #a #m (as_seq h1 ws) (v i))
      (fun j ->
       Lib.LoopCombinators.unfold_repeati 16 (shuffle_inner #a #m (as_seq h1 ws) (v i)) (as_seq h1 hash) (v j);
       let k_t = index_k0 a (16ul *. i +. j) in
       let ws_t = ws.(j) in
       shuffle_core k_t ws_t hash);
      if i <. num_rounds16 a -. 1ul then
        ws_next ws)


(** Init *)
inline_for_extraction
val alloc: a:sha2_alg -> m:m_spec ->
    StackInline (state_t a m)
    (requires (fun h -> True))
    (ensures (fun h0 b h1 -> live h1 b /\ stack_allocated b h0 h1 (Seq.create 8 (zero_element a m))))
let alloc a m = Lib.Buffer.create 8ul (zero_element a m)

let init #a #m hash =
  let h0 = ST.get() in
  fill h0 8ul hash
  (fun h i -> load_element a m (Seq.index (Spec.h0 a) i))
  (fun i -> let hi = index_h0 a i in
          load_element a m hi);
  let h1 = ST.get() in
  LSeq.eq_intro (as_seq h1 hash)
           (LSeq.createi 8 (fun i -> load_element a m (Seq.index (Spec.h0 a) i)))

#push-options "--z3rlimit 200"
let update #a #m b hash =
  let h0 = ST.get() in
  push_frame ();
  let h1 = ST.get() in
  let hash_old = create 8ul (zero_element a m) in
  let ws = create 16ul (zero_element a m) in
  assert (disjoint_multi b hash_old);
  assert (disjoint_multi b ws);
  assert (disjoint ws hash_old);
  assert (disjoint hash hash_old);
  assert (disjoint ws hash);
  copy hash_old hash;
  let h2 = ST.get() in
  assert (live_multi h2 b);
  Lib.NTuple.(eq_intro (as_seq_multi h2 b) (as_seq_multi h0 b));
  load_ws b ws;
  let h3 = ST.get() in
  assert (modifies (loc ws |+| loc hash_old) h0 h3);
  assert (as_seq h3 ws == Hacl.Spec.SHA2.Vec.load_ws (as_seq_multi h2 b));
  shuffle ws hash;
  let h4 = ST.get() in
  assert (modifies (loc hash |+| (loc ws |+| loc hash_old)) h0 h4);
  assert (as_seq h4 hash == Hacl.Spec.SHA2.Vec.shuffle (as_seq h3 ws) (as_seq h0 hash));
  map2T 8ul hash (+|) hash hash_old;
  let h5 = ST.get() in
  assert (modifies (loc hash |+| (loc ws |+| loc hash_old)) h0 h5);
  reveal_opaque (`%SpecVec.update) (SpecVec.update #a #m);
  assert (as_seq h5 hash == SpecVec.update (as_seq_multi h0 b) (as_seq h0 hash));
  pop_frame()
#pop-options

inline_for_extraction
let padded_blocks (a:sha2_alg) (len:size_t{v len < block_length a}) :
                  n:size_t{v n == SpecVec.padded_blocks a (v len)} =
  if (len +. len_len a +. 1ul <=. block_len a) then 1ul else 2ul


inline_for_extraction
val load_last_blocks: #a:sha2_alg ->
                      totlen_buf:lbuffer uint8 (len_len a) ->
                      len:size_t{v len < block_length a} ->
                      b:lbuffer uint8 len ->
                      fin:size_t{v fin == block_length a \/ v fin == 2 * block_length a} ->
                      last:lbuffer uint8 (2ul *. block_len a) ->
    Stack (lbuffer uint8 (block_len a) & lbuffer uint8 (block_len a))
    (requires (fun h -> live h totlen_buf /\ live h b /\ live h last /\
                      disjoint b last /\ disjoint last totlen_buf /\
                      as_seq h last == LSeq.create (2 * block_length a) (u8 0)))
    (ensures (fun h0 (l0,l1) h1 -> modifies (loc last) h0 h1 /\
                           live h1 l0 /\ live h1 l1 /\
                           (forall a l (r:lbuffer a l). disjoint last r ==> (disjoint l0 r /\ disjoint l1 r)) /\
                           (as_seq h1 l0, as_seq h1 l1) ==
                           SpecVec.load_last_blocks #a (as_seq h0 totlen_buf) (v fin) (v len) (as_seq h0 b)))
#push-options "--z3rlimit 200"
let load_last_blocks #a totlen_buf len b fin last =
  let h0 = ST.get() in
  update_sub last 0ul len b;
  last.(len) <- u8 0x80;
  update_sub last (fin -. len_len a) (len_len a) totlen_buf;
  let last0 : lbuffer uint8 (block_len a) = sub last 0ul (block_len a) in
  let last1 : lbuffer uint8 (block_len a) = sub last (block_len a) (block_len a) in
  let h1 = ST.get() in
  assert (modifies (loc last) h0 h1);
  (last0,last1)
#pop-options

noextract
let preserves_sub_disjoint_multi #lanes #len #len' (b:lbuffer uint8 len) (r:multibuf lanes len') =
    (forall a l (x:lbuffer a l). disjoint b x ==> disjoint_multi r x)

let load_last_t (a:sha2_alg) (m:m_spec) =
                  totlen_buf:lbuffer uint8 (len_len a) ->
                  len:size_t{v len < block_length a} ->
                  b:multibuf (lanes a m) len ->
                  fin:size_t{v fin == block_length a \/ v fin == 2 * block_length a} ->
                  last:lbuffer uint8 (size (lanes a m) *. 2ul *. block_len a) ->
    Stack (multibuf (lanes a m) (block_len a) & multibuf (lanes a m) (block_len a))
      (requires (fun h -> live h totlen_buf /\ live_multi h b /\ live h last /\
                      disjoint_multi b last /\ disjoint last totlen_buf /\
                      as_seq h last == LSeq.create (lanes a m * 2 * block_length a) (u8 0)))
      (ensures (fun h0 (l0,l1) h1 -> modifies (loc last) h0 h1 /\
                           live_multi h1 l0 /\ live_multi h1 l1 /\
                           preserves_sub_disjoint_multi last l0 /\
                           preserves_sub_disjoint_multi last l1 /\
                           (as_seq_multi h1 l0, as_seq_multi h1 l1) ==
                           SpecVec.load_last #a #m (as_seq h0 totlen_buf) (v fin) (v len) (as_seq_multi h0 b)))
inline_for_extraction
val load_last1: #a:sha2_alg -> #m:m_spec{lanes a m = 1} -> load_last_t a m
#push-options "--z3rlimit 250"
let load_last1 #a #m totlen_buf len b fin last =
  let h0 = ST.get() in
  let b0 = b.(|0|) in
  let (l0,l1) = load_last_blocks #a totlen_buf len b0 fin last in
  let lb0 : multibuf (lanes a m) (block_len a) = ntup1 l0 in
  let lb1 : multibuf (lanes a m) (block_len a) = ntup1 l1 in
  let h1 = ST.get() in
  assert (modifies (loc last) h0 h1);
  NTup.eq_intro (as_seq_multi h0 b) (ntup1 (as_seq h0 b0));
  NTup.eq_intro (as_seq_multi h1 lb0) (ntup1 (as_seq h1 l0));
  NTup.eq_intro (as_seq_multi h1 lb1) (ntup1 (as_seq h1 l1));
  assert ((as_seq_multi h1 lb0, as_seq_multi h1 lb1) ==
           SpecVec.load_last1 #a #m (as_seq h0 totlen_buf) (v fin) (v len) (as_seq_multi h0 b));
  reveal_opaque (`%SpecVec.load_last) (SpecVec.load_last #a #m);
  (lb0,lb1)
#pop-options


inline_for_extraction
val load_last4: #a:sha2_alg -> #m:m_spec{lanes a m = 4} -> load_last_t a m
#push-options "--z3rlimit 350"
let load_last4 #a #m totlen_buf len b fin last =
  let h0 = ST.get() in
  let (b0,(b1,(b2,b3))) = NTup.tup4 b in
  let last0 = sub last 0ul (2ul *. block_len a) in
  let last1 = sub last (2ul *. block_len a) (2ul *. block_len a) in
  let last2 = sub last (4ul *. block_len a) (2ul *. block_len a) in
  let last3 = sub last (6ul *. block_len a) (2ul *. block_len a) in
  let h1 = ST.get() in
  assert (disjoint last0 last1);
  LSeq.eq_intro (as_seq h1 last0) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last1) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last2) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last3) (LSeq.create (2 * block_length a) (u8 0));
  let (l00,l01) = load_last_blocks #a totlen_buf len b0 fin last0 in
  let (l10,l11) = load_last_blocks #a totlen_buf len b1 fin last1 in
  let (l20,l21) = load_last_blocks #a totlen_buf len b2 fin last2 in
  let (l30,l31) = load_last_blocks #a totlen_buf len b3 fin last3 in
  let mb0:multibuf (lanes a m) (block_len a) = ntup4 (l00, (l10, (l20, l30))) in
  let mb1:multibuf (lanes a m) (block_len a) = ntup4 (l01, (l11, (l21, l31))) in
  let h1 = ST.get() in
  assert ((as_seq h1 l00, as_seq h1 l01) ==
          SpecVec.load_last_blocks #a (as_seq h0 totlen_buf) (v fin) (v len) (as_seq h0 b0));
  assert ((as_seq h1 l10, as_seq h1 l11) ==
          SpecVec.load_last_blocks #a (as_seq h0 totlen_buf) (v fin) (v len) (as_seq h0 b1));
  assert ((as_seq h1 l20, as_seq h1 l21) ==
          SpecVec.load_last_blocks #a (as_seq h0 totlen_buf) (v fin) (v len) (as_seq h0 b2));
  assert ((as_seq h1 l30, as_seq h1 l31) ==
          SpecVec.load_last_blocks #a (as_seq h0 totlen_buf) (v fin) (v len) (as_seq h0 b3));
  NTup.eq_intro (as_seq_multi h1 mb0) (ntup4 (as_seq h1 l00, (as_seq h1 l10, (as_seq h1 l20, (as_seq h1 l30)))));
  NTup.eq_intro (as_seq_multi h1 mb1) (ntup4 (as_seq h1 l01, (as_seq h1 l11, (as_seq h1 l21, (as_seq h1 l31)))));
  assert (modifies (loc last0 |+| loc last1 |+| loc last2 |+| loc last3) h0 h1);
  assert (modifies (loc last) h0 h1);
  assert (live_multi h1 mb0);
  assert (live_multi h1 mb1);
  reveal_opaque (`%SpecVec.load_last) (SpecVec.load_last #a #m);
  (mb0, mb1)
#pop-options

inline_for_extraction
val load_last8: #a:sha2_alg -> #m:m_spec{lanes a m = 8} -> load_last_t a m
#push-options "--z3rlimit 600"
let load_last8 #a #m totlen_buf len b fin last =
  let h0 = ST.get() in
  let (b0,(b1,(b2,(b3,(b4,(b5,(b6,b7))))))) = NTup.tup8 b in
  let last0 = sub last 0ul (2ul *. block_len a) in
  let last1 = sub last (2ul *. block_len a) (2ul *. block_len a) in
  let last2 = sub last (4ul *. block_len a) (2ul *. block_len a) in
  let last3 = sub last (6ul *. block_len a) (2ul *. block_len a) in
  let last4 = sub last (8ul *. block_len a) (2ul *. block_len a) in
  let last5 = sub last (10ul *. block_len a) (2ul *. block_len a) in
  let last6 = sub last (12ul *. block_len a) (2ul *. block_len a) in
  let last7 = sub last (14ul *. block_len a) (2ul *. block_len a) in
  assert (internally_disjoint8 last0 last1 last2 last3 last4 last5 last6 last7);
  let h1 = ST.get() in
  assert (h0 == h1);
  LSeq.eq_intro (as_seq h1 last0) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last1) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last2) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last3) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last4) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last5) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last6) (LSeq.create (2 * block_length a) (u8 0));
  LSeq.eq_intro (as_seq h1 last7) (LSeq.create (2 * block_length a) (u8 0));
  let (l00,l01) = load_last_blocks #a totlen_buf len b0 fin last0 in
  let (l10,l11) = load_last_blocks #a totlen_buf len b1 fin last1 in
  let h2 = ST.get() in assert (modifies (loc last0 |+| loc last1) h0 h2);
  let (l20,l21) = load_last_blocks #a totlen_buf len b2 fin last2 in
  let (l30,l31) = load_last_blocks #a totlen_buf len b3 fin last3 in
  let h2 = ST.get() in assert (modifies (loc last0 |+| loc last1 |+| loc last2 |+| loc last3) h0 h2);
  let (l40,l41) = load_last_blocks #a totlen_buf len b4 fin last4 in
  let (l50,l51) = load_last_blocks #a totlen_buf len b5 fin last5 in
  let h2 = ST.get() in assert (modifies (loc last0 |+| loc last1 |+| loc last2 |+| loc last3 |+| loc last4 |+| loc last5) h0 h2);
  let (l60,l61) = load_last_blocks #a totlen_buf len b6 fin last6 in
  let (l70,l71) = load_last_blocks #a totlen_buf len b7 fin last7 in
  let h3 = ST.get() in assert (modifies (loc last0 |+| loc last1 |+| loc last2 |+| loc last3 |+| loc last4 |+| loc last5 |+| loc last6 |+| loc last7) h0 h3);
  assert (modifies (loc last) h0 h3);
  let mb0:multibuf (lanes a m) (block_len a) =
    ntup8 (l00, (l10, (l20, (l30, (l40, (l50, (l60, l70))))))) in
  let mb1:multibuf (lanes a m) (block_len a) =
    ntup8 (l01, (l11, (l21, (l31, (l41, (l51, (l61, l71))))))) in
  ntup8_lemma #_ #8 (l00, (l10, (l20, (l30, (l40, (l50, (l60, l70)))))));
  ntup8_lemma #_ #8 (l01, (l11, (l21, (l31, (l41, (l51, (l61, l71)))))));
  assert (live_multi h3 mb0);
  assert (live_multi h3 mb1);
  NTup.eq_intro (as_seq_multi h3 mb0)
                (ntup8 (as_seq h3 l00, (as_seq h3 l10, (as_seq h3 l20, (as_seq h3 l30,
                        (as_seq h3 l40, (as_seq h3 l50, (as_seq h3 l60, (as_seq h3 l70)))))))));
  NTup.eq_intro (as_seq_multi h3 mb1)
                (ntup8 (as_seq h3 l01, (as_seq h3 l11, (as_seq h3 l21, (as_seq h3 l31,
                        (as_seq h3 l41, (as_seq h3 l51, (as_seq h3 l61, (as_seq h3 l71)))))))));
  assert ((as_seq_multi h3 mb0, as_seq_multi h3 mb1) ==
           SpecVec.load_last8 #a #m (as_seq h0 totlen_buf) (v fin) (v len) (as_seq_multi h0 b));
  reveal_opaque (`%SpecVec.load_last) (SpecVec.load_last #a #m);
  (mb0, mb1)
#pop-options

inline_for_extraction
val load_last: #a:sha2_alg -> #m:m_spec -> load_last_t a m
let load_last #a #m  totlen_buf len b fin last =
  match lanes a m with
  | 1 -> load_last1 #a #m totlen_buf len b fin last
  | 4 -> load_last4 #a #m totlen_buf len b fin last
  | 8 -> load_last8 #a #m totlen_buf len b fin last
  | _ -> admit()

#push-options "--z3rlimit 350"
let update_last #a #m upd totlen len b hash =
  let h0 = ST.get() in
  push_frame ();
  let h1 = ST.get() in
  let blocks = padded_blocks a len in
  let fin = blocks *. block_len a in
  let last = create (size (lanes a m) *. 2ul *. block_len a) (u8 0) in
  let totlen_buf = create (len_len a) (u8 0) in
  let total_len_bits = secret (shift_left #(len_int_type a) totlen 3ul) in
  Lib.ByteBuffer.uint_to_bytes_be #(len_int_type a) totlen_buf total_len_bits;
  let h2 = ST.get () in
  NTup.eq_intro (as_seq_multi h2 b) (as_seq_multi h0 b);
  assert (as_seq h2 totlen_buf ==
          Lib.ByteSequence.uint_to_bytes_be #(len_int_type a) total_len_bits);
  let (last0,last1) = load_last #a #m totlen_buf len b fin last in
  let h3 = ST.get () in
  assert ((as_seq_multi h3 last0, as_seq_multi h3 last1) ==
          SpecVec.load_last #a #m (as_seq h2 totlen_buf) (v fin) (v len) (as_seq_multi h2 b));
  assert (disjoint_multi last1 hash);
  upd last0 hash;
  let h4 = ST.get() in
  assert (modifies (loc hash |+| loc last |+| loc totlen_buf) h1 h3);
  assert (as_seq h4 hash == SpecVec.update (as_seq_multi h3 last0) (as_seq h3 hash));
  NTup.eq_intro (as_seq_multi h4 last1) (as_seq_multi h3 last1);
  assert (v blocks > 1 ==> blocks >. 1ul);
  assert (blocks >. 1ul ==> v blocks > 1);
  assert (not (blocks >. 1ul) ==> not (v blocks > 1));
  if blocks >. 1ul then (
    upd last1 hash;
    let h5 = ST.get() in
    assert (as_seq h5 hash == SpecVec.update (as_seq_multi h4 last1) (as_seq h4 hash));
    assert (modifies (loc hash |+| loc last |+| loc totlen_buf) h1 h5);
    assert (as_seq h5 hash == SpecVec.update_last totlen (v len) (as_seq_multi h0 b) (as_seq h0 hash));
    pop_frame()
  ) else (
    let h6 = ST.get() in
    assert (h4 == h6);
    assert (modifies (loc hash |+| loc totlen_buf |+| loc last) h1 h6);
    assert (as_seq h6 hash == SpecVec.update_last totlen (v len) (as_seq_multi h0 b) (as_seq h0 hash));
    pop_frame())
#pop-options

inline_for_extraction
val transpose_state4 (#a: sha2_alg) (#m:m_spec{lanes a m == 4}) (st: state_t a m):
    Stack unit
    (requires (fun h -> live h st))
    (ensures (fun h0 _ h1 -> modifies (loc st) h0 h1 /\
                           as_seq h1 st ==
                           SpecVec.transpose_state4 (as_seq h0 st)))

#push-options "--z3rlimit 200"
let transpose_state4 #a #m st =
  let h0 = ST.get() in
  let st0 = st.(0ul) in
  let st1 = st.(1ul) in
  let st2 = st.(2ul) in
  let st3 = st.(3ul) in
  let st4 = st.(4ul) in
  let st5 = st.(5ul) in
  let st6 = st.(6ul) in
  let st7 = st.(7ul) in
  let (st0',st1',st2',st3') = VecTranspose.transpose4x4 (st0,st1,st2,st3) in
  let (st4',st5',st6',st7') = VecTranspose.transpose4x4 (st4,st5,st6,st7) in
  st.(0ul) <- st0';
  st.(1ul) <- st4';
  st.(2ul) <- st1';
  st.(3ul) <- st5';
  st.(4ul) <- st2';
  st.(5ul) <- st6';
  st.(6ul) <- st3';
  st.(7ul) <- st7';
  let h1 = ST.get() in
  LSeq.eq_intro (as_seq h1 st) (create8 st0' st4' st1' st5' st2' st6' st3' st7');
  LSeq.eq_intro (as_seq h0 st) (create8 st0 st1 st2 st3 st4 st5 st6 st7);
  LSeq.eq_intro (create8 st0' st4' st1' st5' st2' st6' st3' st7')
                        (SpecVec.transpose_state4 (create8 st0 st1 st2 st3 st4 st5 st6 st7));
  ()


inline_for_extraction
val transpose_state8 (#a: sha2_alg) (#m:m_spec{lanes a m == 8}) (st: state_t a m):
    Stack unit
    (requires (fun h -> live h st))
    (ensures (fun h0 _ h1 -> modifies (loc st) h0 h1 /\
                           as_seq h1 st ==
                           SpecVec.transpose_state8 (as_seq h0 st)))
let transpose_state8 #a #m st =
  let h0 = ST.get() in
  let st0 = st.(0ul) in
  let st1 = st.(1ul) in
  let st2 = st.(2ul) in
  let st3 = st.(3ul) in
  let st4 = st.(4ul) in
  let st5 = st.(5ul) in
  let st6 = st.(6ul) in
  let st7 = st.(7ul) in
  let (st0',st1',st2',st3',st4',st5',st6',st7') = VecTranspose.transpose8x8 (st0,st1,st2,st3,st4,st5,st6,st7) in
  st.(0ul) <- st0';
  st.(1ul) <- st1';
  st.(2ul) <- st2';
  st.(3ul) <- st3';
  st.(4ul) <- st4';
  st.(5ul) <- st5';
  st.(6ul) <- st6';
  st.(7ul) <- st7';
  let h1 = ST.get() in
  LSeq.eq_intro (as_seq h1 st) (create8 st0' st1' st2' st3' st4' st5' st6' st7');
  LSeq.eq_intro (as_seq h0 st) (create8 st0 st1 st2 st3 st4 st5 st6 st7);
  LSeq.eq_intro (create8 st0' st1' st2' st3' st4' st5' st6' st7')
                        (SpecVec.transpose_state8 (create8 st0 st1 st2 st3 st4 st5 st6 st7));
  ()
#pop-options


inline_for_extraction
val transpose_state (#a: sha2_alg) (#m:m_spec) (st: state_t a m):
    Stack unit
    (requires (fun h -> live h st))
    (ensures (fun h0 _ h1 -> modifies (loc st) h0 h1 /\
                           as_seq h1 st ==
                           SpecVec.transpose_state (as_seq h0 st)))
let transpose_state #a #m st =
  match lanes a m with
  | 1 -> ()
  | 4 -> transpose_state4 st
  | 8 -> transpose_state8 st
  | _ -> admit()


inline_for_extraction
val store_state: #a:sha2_alg -> #m:m_spec->
                 st:state_t a m ->
                 hbuf:lbuffer uint8 (size (lanes a m) *. 8ul *. word_len a) ->
    Stack unit
    (requires (fun h -> live h hbuf /\ live h st /\ disjoint hbuf st /\
                      as_seq h hbuf == LSeq.create (lanes a m * 8 * word_length a) (u8 0)))
    (ensures (fun h0 _ h1 -> modifies (loc st |+| loc hbuf) h0 h1 /\
                           as_seq h1 hbuf ==
                           SpecVec.store_state #a #m (as_seq h0 st)))
let store_state #a #m st hbuf =
  transpose_state st;
  Lib.IntVector.Serialize.vecs_store_be hbuf st


noextract
let emit1_spec (#a:sha2_alg) (#m:m_spec{lanes a m == 1})
          (hseq:LSeq.lseq uint8 (lanes a m * 8 * word_length a)):
          multiseq (lanes a m) (hash_length a) =
    let hsub = LSeq.sub hseq 0 (hash_length a) in
    ntup1 hsub


noextract
let emit1_lemma (#a:sha2_alg) (#m:m_spec{lanes a m == 1})
                (hseq:LSeq.lseq uint8 (lanes a m * 8 * word_length a)):
                Lemma (emit1_spec #a #m hseq ==
                       SpecVec.emit #a #m hseq) =
    Lib.NTuple.eq_intro (emit1_spec #a #m hseq) (SpecVec.emit #a #m hseq)


inline_for_extraction
val emit1: #a:sha2_alg -> #m:m_spec{lanes a m = 1} ->
             hbuf: lbuffer uint8 (8ul *. word_len a) ->
             result:multibuf (lanes a m) (hash_len a) ->
    Stack unit
    (requires (fun h -> live_multi h result /\ live h hbuf /\
                      internally_disjoint result /\ disjoint_multi result hbuf))
    (ensures (fun h0 _ h1 -> modifies_multi result h0 h1 /\
                           as_seq_multi h1 result ==
                           SpecVec.emit #a #m (as_seq h0 hbuf)))
let emit1 #a #m hbuf result =
  let h0 = ST.get() in
  copy result.(|0|) (sub hbuf 0ul (hash_len a));
  let h1 = ST.get() in
  Lib.NTuple.eq_intro (as_seq_multi h1 result) (emit1_spec #a #m (as_seq h0 hbuf));
  emit1_lemma #a #m (as_seq h0 hbuf);
  assert (modifies_multi result h0 h1)


noextract
let emit4_spec (#a:sha2_alg) (#m:m_spec{lanes a m == 4})
          (hseq:LSeq.lseq uint8 (lanes a m * 8 * word_length a)):
          multiseq (lanes a m) (hash_length a) =
    let open Lib.Sequence in
    let h0 = sub hseq 0 (hash_length a) in
    let h1 = sub hseq (8 * word_length a) (hash_length a) in
    let h2 = sub hseq (16 * word_length a) (hash_length a) in
    let h3 = sub hseq (24 * word_length a) (hash_length a) in
    let hsub : multiseq 4 (hash_length a) = ntup4 (h0,(h1,(h2,h3))) in
    hsub

noextract
let emit4_lemma (#a:sha2_alg) (#m:m_spec{lanes a m == 4})
                (hseq:LSeq.lseq uint8 (lanes a m * 8 * word_length a)):
                Lemma (emit4_spec #a #m hseq ==
                       SpecVec.emit #a #m hseq) =
    Lib.NTuple.eq_intro (emit4_spec #a #m hseq) (SpecVec.emit #a #m hseq)

inline_for_extraction
val emit4: #a:sha2_alg -> #m:m_spec{lanes a m = 4} ->
             hbuf: lbuffer uint8 (size (lanes a m) *. 8ul *. word_len a) ->
             result:multibuf (lanes a m) (hash_len a) ->
    Stack unit
    (requires (fun h -> live_multi h result /\ live h hbuf /\
                      internally_disjoint result  /\ disjoint_multi result hbuf))
    (ensures (fun h0 _ h1 -> modifies_multi result h0 h1 /\
                           as_seq_multi h1 result ==
                           SpecVec.emit #a #m (as_seq h0 hbuf)))
#push-options "--z3rlimit 200"
let emit4 #a #m hbuf result =
  let h0 = ST.get() in
  let (b0,(b1,(b2,b3))) = NTup.tup4 result in
  assert (disjoint b0 b1);
  assert (disjoint b0 b2);
  assert (disjoint b0 b3);
  assert (disjoint b1 b2);
  assert (disjoint b1 b3);
  assert (disjoint b2 b3);
  copy b0 (sub hbuf 0ul (hash_len a));
  copy b1 (sub hbuf (8ul *. word_len a) (hash_len a));
  copy b2 (sub hbuf (16ul *. word_len a) (hash_len a));
  copy b3 (sub hbuf (24ul *. word_len a) (hash_len a));
  let h1 = ST.get() in
  assert (as_seq h1 b0 == LSeq.sub (as_seq h0 hbuf) 0 (hash_length a));
  assert (as_seq h1 b1 == LSeq.sub (as_seq h0 hbuf) (8 * word_length a) (hash_length a));
  assert (as_seq h1 b2 == LSeq.sub (as_seq h0 hbuf) (16 * word_length a) (hash_length a));
  assert (as_seq h1 b3 == LSeq.sub (as_seq h0 hbuf) (24 * word_length a) (hash_length a));
  NTup.eq_intro (as_seq_multi h1 result) (NTup.ntup4 (as_seq h1 b0, (as_seq h1 b1, (as_seq h1 b2, as_seq h1 b3))));
  assert (modifies (loc b0 |+| loc b1 |+| loc b2 |+| loc b3) h0 h1);
  assert (as_seq_multi h1 result == emit4_spec #a #m (as_seq h0 hbuf));
  emit4_lemma #a #m (as_seq h0 hbuf);
  loc_multi4 result;
  assert (modifies_multi result h0 h1);
  ()
#pop-options

noextract
let emit8_spec (#a:sha2_alg) (#m:m_spec{lanes a m == 8})
          (hseq:LSeq.lseq uint8 (lanes a m * 8 * word_length a)):
          multiseq (lanes a m) (hash_length a) =
    let open Lib.Sequence in
    let h0 = sub hseq 0 (hash_length a) in
    let h1 = sub hseq (8 * word_length a) (hash_length a) in
    let h2 = sub hseq (16 * word_length a) (hash_length a) in
    let h3 = sub hseq (24 * word_length a) (hash_length a) in
    let h4 = sub hseq (32 * word_length a) (hash_length a) in
    let h5 = sub hseq (40 * word_length a) (hash_length a) in
    let h6 = sub hseq (48 * word_length a) (hash_length a) in
    let h7 = sub hseq (56 * word_length a) (hash_length a) in
    let hsub : multiseq 8 (hash_length a) = ntup8 (h0,(h1,(h2,(h3,(h4,(h5,(h6,h7))))))) in
    hsub

noextract
let emit8_lemma (#a:sha2_alg) (#m:m_spec{lanes a m == 8})
                (hseq:LSeq.lseq uint8 (lanes a m * 8 * word_length a)):
                Lemma (emit8_spec #a #m hseq ==
                       SpecVec.emit #a #m hseq) =
    Lib.NTuple.eq_intro (emit8_spec #a #m hseq) (SpecVec.emit #a #m hseq)

inline_for_extraction
val emit8: #a:sha2_alg -> #m:m_spec{lanes a m = 8} ->
             hbuf: lbuffer uint8 (size (lanes a m) *. 8ul *. word_len a) ->
             result:multibuf (lanes a m) (hash_len a) ->
    Stack unit
    (requires (fun h -> live_multi h result /\ live h hbuf /\
                      internally_disjoint result  /\ disjoint_multi result hbuf))
    (ensures (fun h0 _ h1 -> modifies_multi result h0 h1 /\
                           as_seq_multi h1 result ==
                           SpecVec.emit #a #m (as_seq h0 hbuf)))
#push-options "--z3rlimit 700"
let emit8 #a #m hbuf result =
  let h0 = ST.get() in
  let (b0,(b1,(b2,(b3,(b4,(b5,(b6,b7))))))) = NTup.tup8 result in
  assert (internally_disjoint8 b0 b1 b2 b3 b4 b5 b6 b7);
  copy b0 (sub hbuf 0ul (hash_len a));
  copy b1 (sub hbuf (8ul *. word_len a) (hash_len a));
  copy b2 (sub hbuf (16ul *. word_len a) (hash_len a));
  copy b3 (sub hbuf (24ul *. word_len a) (hash_len a));
  let h1 = ST.get() in
  assert (modifies (loc b0 |+| loc b1 |+| loc b2 |+| loc b3) h0 h1);
  copy b4 (sub hbuf (32ul *. word_len a) (hash_len a));
  copy b5 (sub hbuf (40ul *. word_len a) (hash_len a));
  copy b6 (sub hbuf (48ul *. word_len a) (hash_len a));
  copy b7 (sub hbuf (56ul *. word_len a) (hash_len a));
  let h1 = ST.get() in
  assert (as_seq h1 b0 == LSeq.sub (as_seq h0 hbuf) 0 (hash_length a));
  assert (as_seq h1 b1 == LSeq.sub (as_seq h0 hbuf) (8 * word_length a) (hash_length a));
  assert (as_seq h1 b2 == LSeq.sub (as_seq h0 hbuf) (16 * word_length a) (hash_length a));
  assert (as_seq h1 b3 == LSeq.sub (as_seq h0 hbuf) (24 * word_length a) (hash_length a));
  assert (as_seq h1 b4 == LSeq.sub (as_seq h0 hbuf) (32 * word_length a) (hash_length a));
  assert (as_seq h1 b5 == LSeq.sub (as_seq h0 hbuf) (40 * word_length a) (hash_length a));
  assert (as_seq h1 b6 == LSeq.sub (as_seq h0 hbuf) (48 * word_length a) (hash_length a));
  assert (as_seq h1 b7 == LSeq.sub (as_seq h0 hbuf) (56 * word_length a) (hash_length a));
  NTup.eq_intro (as_seq_multi h1 result)
    (NTup.ntup8 (as_seq h1 b0, (as_seq h1 b1, (as_seq h1 b2, (as_seq h1 b3, (as_seq h1 b4, (as_seq h1 b5, (as_seq h1 b6, as_seq h1 b7))))))));
  assert (modifies (loc b0 |+| loc b1 |+| loc b2 |+| loc b3 |+| loc b4 |+| loc b5 |+| loc b6 |+| loc b7) h0 h1);
  assert (as_seq_multi h1 result == emit8_spec #a #m (as_seq h0 hbuf));
  emit8_lemma #a #m (as_seq h0 hbuf);
  loc_multi8 result;
  assert (modifies_multi result h0 h1);
  ()
#pop-options


inline_for_extraction
val emit: #a:sha2_alg -> #m:m_spec ->
          hbuf: lbuffer uint8 (size (lanes a m) *. 8ul *. word_len a) ->
          result:multibuf (lanes a m) (hash_len a) ->
    Stack unit
    (requires (fun h -> live_multi h result /\ live h hbuf /\
                      internally_disjoint result /\ disjoint_multi result hbuf))
    (ensures (fun h0 _ h1 -> modifies_multi result h0 h1 /\
                           as_seq_multi h1 result ==
                           SpecVec.emit #a #m (as_seq h0 hbuf)))
let emit #a #m hbuf result =
  match lanes a m with
  | 1 -> emit1 #a #m hbuf result
  | 4 -> emit4 #a #m hbuf result
  | 8 -> emit8 #a #m hbuf result
  | _ -> admit()


let get_multiblock #a #m len b i =
  let h0 = ST.get() in
  match lanes a m with
  | 1 -> let b0 = NTup.tup1 b in
         let b' = sub b0 (i *. block_len a) (block_len a) in
         let mb' = NTup.ntup1 b' in
         let h1 = ST.get() in
         NTup.eq_intro (as_seq_multi h1 mb')
                       (SpecVec.get_multiblock_spec #a #m (v len) (as_seq_multi h0 b) (v i));
         mb'
  | 4 -> let (b0,(b1,(b2,b3))) = NTup.tup4 b in
         let bl0 = sub b0 (i *. block_len a) (block_len a) in
         let bl1 = sub b1 (i *. block_len a) (block_len a) in
         let bl2 = sub b2 (i *. block_len a) (block_len a) in
         let bl3 = sub b3 (i *. block_len a) (block_len a) in
         let mb = NTup.ntup4 (bl0, (bl1, (bl2, bl3))) in
         let h1 = ST.get() in
         NTup.eq_intro (as_seq_multi h1 mb)
                       (SpecVec.get_multiblock_spec #a #m (v len) (as_seq_multi h0 b) (v i));
         mb
  | 8 -> let (b0,(b1,(b2,(b3,(b4,(b5,(b6,b7))))))) = NTup.tup8 b in
         let bl0 = sub b0 (i *. block_len a) (block_len a) in
         let bl1 = sub b1 (i *. block_len a) (block_len a) in
         let bl2 = sub b2 (i *. block_len a) (block_len a) in
         let bl3 = sub b3 (i *. block_len a) (block_len a) in
         let bl4 = sub b4 (i *. block_len a) (block_len a) in
         let bl5 = sub b5 (i *. block_len a) (block_len a) in
         let bl6 = sub b6 (i *. block_len a) (block_len a) in
         let bl7 = sub b7 (i *. block_len a) (block_len a) in
         let mb = NTup.ntup8 (bl0, (bl1, (bl2, (bl3, (bl4, (bl5, (bl6, bl7))))))) in
         let h1 = ST.get() in
         NTup.eq_intro (as_seq_multi h1 mb)
                       (SpecVec.get_multiblock_spec #a #m (v len) (as_seq_multi h0 b) (v i));
         mb
  | _ -> admit()



#push-options "--z3rlimit 300"
let get_multilast #a #m len b =
  let h0 = ST.get() in
  let rem = len %. block_len a in
  assert (v (len -! rem) == v len - v rem);
  match lanes a m with
  | 1 -> let b0 = NTup.tup1 b in
         let b' = sub b0 (len -! rem) rem in
         let mb' = NTup.ntup1 b' in
         let h1 = ST.get() in
         NTup.eq_intro (as_seq_multi h1 mb')
                       (SpecVec.get_multilast_spec #a #m (v len) (as_seq_multi h0 b));
         mb'
  | 4 -> let (b0,(b1,(b2,b3))) = NTup.tup4 b in
         let bl0 = sub b0 (len -! rem) rem in
         let bl1 = sub b1 (len -! rem) rem in
         let bl2 = sub b2 (len -! rem) rem in
         let bl3 = sub b3 (len -! rem) rem in
         let mb = NTup.ntup4 (bl0, (bl1, (bl2, bl3))) in
         let h1 = ST.get() in
         NTup.eq_intro (as_seq_multi h1 mb)
                       (SpecVec.get_multilast_spec #a #m (v len) (as_seq_multi h0 b));
         mb
  | 8 -> let (b0,(b1,(b2,(b3,(b4,(b5,(b6,b7))))))) = NTup.tup8 b in
         let bl0 = sub b0 (len -! rem) (rem) in
         let bl1 = sub b1 (len -! rem) (rem) in
         let bl2 = sub b2 (len -! rem) (rem) in
         let bl3 = sub b3 (len -! rem) (rem) in
         let bl4 = sub b4 (len -! rem) (rem) in
         let bl5 = sub b5 (len -! rem) (rem) in
         let bl6 = sub b6 (len -! rem) (rem) in
         let bl7 = sub b7 (len -! rem) (rem) in
         let mb = NTup.ntup8 (bl0, (bl1, (bl2, (bl3, (bl4, (bl5, (bl6, bl7))))))) in
         let h1 = ST.get() in
         NTup.eq_intro (as_seq_multi h1 mb)
                       (SpecVec.get_multilast_spec #a #m (v len) (as_seq_multi h0 b));
         mb
  | _ -> admit()
#pop-options

#push-options "--z3rlimit 200"
let update_nblocks #a #m upd len b st =
    let blocks = len /. block_len a in
    let h0 = ST.get() in
    loop1 h0 blocks st
      (fun h -> SpecVec.update_block #a #m (v len) (as_seq_multi h0 b))
      (fun i ->
        Lib.LoopCombinators.unfold_repeati (v blocks) (SpecVec.update_block #a #m (v len) (as_seq_multi h0 b)) (as_seq h0 st) (v i);
        let h0' = ST.get() in
        let mb = get_multiblock len b i in
        upd mb st;
        let h1 = ST.get() in
        assert (modifies (loc st) h0 h1);
        NTup.eq_intro (as_seq_multi h0' b) (as_seq_multi h0 b);
        assert (as_seq h1 st == SpecVec.update_block #a #m (v len) (as_seq_multi h0 b) (v i) (as_seq h0' st)))
#pop-options


#push-options "--z3rlimit 100"
let finish #a #m st h =
  let h0 = ST.get() in
  push_frame();
  let hbuf = create (size (lanes a m) *. 8ul *. word_len a) (u8 0) in
  let h1 = ST.get() in
  store_state st hbuf;
  emit hbuf h;
  let h2 = ST.get() in
  assert (modifies (loc_multi h |+| loc st |+| loc hbuf) h1 h2);
  assert (as_seq_multi h2 h == SpecVec.finish #a #m (as_seq h0 st));
  pop_frame();
  let h3 = ST.get() in
  assert (modifies (loc_multi h |+| loc st) h0 h3);
  NTup.eq_intro (as_seq_multi h2 h) (as_seq_multi h3 h);
  assert (as_seq_multi h2 h == as_seq_multi h3 h);
  assert (as_seq_multi h3 h == SpecVec.finish #a #m (as_seq h0 st))
#pop-options


#push-options "--z3rlimit 500"
let hash #a #m upd h len b =
    let init_h0 = ST.get() in
    push_frame();
    let h0 = ST.get() in
    NTup.eq_intro (as_seq_multi h0 b) (as_seq_multi init_h0 b);
    let st = alloc a m in
    init #a #m st;
    let h1 = ST.get() in
    assert (modifies (loc st) h0 h1);
    assert (as_seq h1 st == SpecVec.init a m);
    NTup.eq_intro (as_seq_multi h1 b) (as_seq_multi h0 b);
    let rem = len %. block_len a in
    let len' : len_t a = Lib.IntTypes.cast #U32 #PUB (len_int_type a) PUB len in
    update_nblocks #a #m upd len b st;
    let h2 = ST.get() in
    assert (modifies (loc st) h0 h2);
    assert (as_seq h2 st == SpecVec.update_nblocks (v len) (as_seq_multi h0 b) (as_seq h1 st));
    NTup.eq_intro (as_seq_multi h2 b) (as_seq_multi h0 b);
    let lb: multibuf (lanes a m) rem = get_multilast len b in
    let h3 = ST.get() in
    assert (h2 == h3);
    assert (as_seq_multi h3 lb == SpecVec.get_multilast_spec #a #m (v len) (as_seq_multi h2 b));
    assert (preserves_disjoint_multi b lb);
    assert (disjoint_multi lb st);
    update_last #a #m upd len' rem lb st;
    let h4 = ST.get() in
    assert (modifies (loc st) h0 h4);
    assert (as_seq h4 st == SpecVec.update_last len' (v rem) (as_seq_multi h3 lb) (as_seq h3 st));
    finish #a #m st h;
    let h5 = ST.get() in
    assert (modifies (loc_multi h |+| loc st) h0 h5);
    assert (as_seq_multi h5 h == SpecVec.finish #a #m (as_seq h4 st));
    assert (as_seq_multi h5 h == SpecVec.hash #a #m (v len) (as_seq_multi h0 b));
    pop_frame();
    let h6 = ST.get() in
    NTup.eq_intro (as_seq_multi h6 h) (as_seq_multi h5 h)
#pop-options
