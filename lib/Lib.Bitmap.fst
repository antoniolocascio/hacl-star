module Lib.Bitmap

open Lib.IntTypes
open Lib.Sliceable
open Lib.Circuits
module UI = FStar.UInt
module S = FStar.Seq

#set-options "--fuel 0 --ifuel 0"

private val aux (t:inttype{unsigned t}) (l:secrecy_level) (n:nat{n<=bits t}) : foo bool
let aux t l n =
{ n = n
; t = int_t t l
; v = (fun x i -> UI.nth #(bits t) (v x) i)
; mk = (fun f -> mk_int (UI.from_vec #(bits t) (S.init (bits t) (fun i -> if i<n then f i else false))))
; mk_def = (fun f i -> ())
}

val uN (t:inttype{unsigned t}) (l:secrecy_level) (n:nat{n<=bits t}) : bar
let uN t l n =
{ xN = aux t l n
; ones_ = ones t l
; zeros_ = zeros t l
; and_ = (fun x y -> logand #t #l x y)
; xor_ = (fun x y -> logxor #t #l x y)
; or_ = (fun x y -> logor #t #l x y)
; not_ = (fun x -> lognot #t #l x)
; ones_spec = (fun i -> UI.ones_nth_lemma #(bits t) i)
; zeros_spec = (fun i -> UI.zero_nth_lemma #(bits t) i)
; and_spec = (fun x y i -> logand_spec #t #l x y)
; xor_spec = (fun x y i -> logxor_spec #t #l x y)
; or_spec = (fun x y i -> logor_spec #t #l x y)
; not_spec = (fun x i -> lognot_spec #t #l x)
}

let uN_zeros_spec (#t:inttype{unsigned t}) (#l:secrecy_level) (#n:nat{n<=bits t}) (i:nat{i<n}) :
  Lemma ((_).v (uN t l n).zeros_ i == false)
  = ()
let uN_ones_spec (#t:inttype{unsigned t}) (#l:secrecy_level) (#n:nat{n<=bits t}) (i:nat{i<n}) :
  Lemma ((_).v (uN t l n).ones_ i == true)
  = UI.ones_nth_lemma #(bits t) i

let uN_and_spec #t #l #n (x y:(aux t l n).t) (i:nat{i<n}) :
  Lemma ((_).v ((uN t l n).and_ x y) i == ((_).v x i && (_).v y i))
  = logand_spec #t #l x y
let uN_or_spec #t #l #n (x y:(aux t l n).t) (i:nat{i<n}) :
  Lemma ((_).v ((uN t l n).or_ x y) i == ((_).v x i || (_).v y i))
  = logor_spec #t #l x y
let uN_xor_spec #t #l #n (x y:(aux t l n).t) (i:nat{i<n}) :
  Lemma ((_).v ((uN t l n).xor_ x y) i == ((_).v x i <> (_).v y i))
  = logxor_spec #t #l x y
let uN_not_spec #t #l #n (x:(aux t l n).t) (i:nat{i<n}) :
  Lemma ((_).v ((uN t l n).not_ x) i == not((_).v x i))
  = lognot_spec #t #l x

(*
val uN_eq
  (#t1 #t2:(t:inttype{unsigned t})) (#l:secrecy_level)
  (#n:nat{n<=bits t1 /\ n<=bits t2})
  (x:(uN t1 l n).t) (y:(uN t2 l n).t) : Type0
let uN_eq x y = forall i. (_).v x i == (_).v y i

val lemma0 (n:nat) (m:nat{n<=m}) (a:UI.uint_t n) (i:nat{i<n}) :
  Lemma (UI.size a m /\ UI.nth #m a i == UI.nth #n a i)
let rec lemma0 n m a i =
  if n=0 then (
    ()
  ) else (
    admit ()
  )

val uN_cast (#t1 t2:(t:inttype{unsigned t})) (#l:secrecy_level) (#n:nat{n<=bits t1 /\ n<=bits t2}) (x:(uN t1 l n).t) :
  Pure (uN t2 l n).t (requires True) (ensures fun y -> uN_eq y x)
let uN_cast #t1 t2 #l #n x =
  let n1 = bits t1 in
  let n2 = bits t2 in
  let a : int_t t1 l = x in
  assume (PUB? l \/ SEC? l);
  let b : int_t t2 l = cast t2 l a in
  let y : (uN t2 l n).t = b in
  assert(forall (i:nat{i<n}). (_).v y i == UI.nth #n2 (v a % pow2 n2) i);
  let aux (i:nat{i<n}) : Lemma (UI.nth #n2 (v a % pow2 n2) i == UI.nth #n1 (v a) i) =
    if n = 0 then ( ()
    ) else if n2<n1 then (
      lemma0 n2 n1 (v a % pow2 n2) i;
      lemma0 n2 n1 (pow2 n2 - 1) i
    ) else (
      lemma0 n1 n2 (v a) i
    )
  in
  FStar.Classical.forall_intro aux;
  assert(forall (i:nat{i<n}). UI.nth #n2 (v a % pow2 n2) i == UI.nth #n1 (v a) i);
  y

val uN_expend (#t:(t:inttype{unsigned t})) (#l:secrecy_level) (#n:nat{n<=bits t}) (m:nat{n<=m /\ m<=bits t}) (x:(uN t l n).t) :
  Pure (uN t l m).t (requires True) (ensures fun y -> forall (i:nat{i<n}). (_).v y i == (_).v x i)
let uN_expend m x = x

val uN_reduce (#t:(t:inttype{unsigned t})) (#l:secrecy_level) (#n:nat{n<=bits t}) (m:nat{m<=n}) (x:(uN t l n).t) :
  Pure (uN t l m).t (requires True) (ensures fun y -> forall (i:nat{i<m}). (_).v y i == (_).v x i)
let uN_reduce m x = x

val uN_shift_left
  (#t:inttype{unsigned t}) (#l:secrecy_level) (#n:nat{n<=bits t})
  (x:(uN t l n).t) (k:nat{k<bits t}) :
  Pure (uN t l n).t
    (requires True)
    (ensures fun y -> forall (i:nat{i<n-k}). (_).v y i == (_).v x (i+k))
let uN_shift_left #t #l #n x k =
  let y : (uN t l n).t = shift_left #t #l x (size k) in
  let aux (i:nat{i<n-k}) : Lemma ((_).v y i == (_).v x (i+k)) =
    if n=0 then
      ()
    else
      UI.shift_left_lemma_2 #(bits t) (v #t #l x) k i
  in
  FStar.Classical.forall_intro aux;
  y

val uN_shift_right
  (#t:inttype{unsigned t}) (#l:secrecy_level) (#n:nat{n<=bits t})
  (x:(uN t l n).t) (k:nat{k<bits t}) :
  Pure (uN t l n).t
    (requires True)
    (ensures fun y -> forall (i:nat{i<n}). (_).v y i == (if i<k then false else (_).v x (i-k)))
let uN_shift_right #t #l #n x k =
  let y : (uN t l n).t = shift_right #t #l x (size k) in
  let aux (i:nat{i<n}) : Lemma ((_).v y i == (if i<k then false else (_).v x (i-k))) =
    if n=0 then (
      ()
    ) else if i<k then (
      UI.shift_right_lemma_1 #(bits t) (v #t #l x) k i
    ) else (
      UI.shift_right_lemma_2 #(bits t) (v #t #l x) k i
    )
  in
  FStar.Classical.forall_intro aux;
  y

val uN_concat
  (#t1:inttype{unsigned t1}) (#l:secrecy_level)
  (t2:inttype{unsigned t2})
  (#n:nat{n<=bits t1 /\ n+n<=bits t2})
  (x y:(uN t1 l n).t) :
  Pure (uN t2 l (n+n)).t
    (requires True)
    (ensures fun z -> forall (i:nat{i<n+n}). (_).v z i == (if i<n then (_).v x i else (_).v y (i-n)))
#push-options "--z3rlimit 100"
let uN_concat #t1 #l t2 #n x y =
  let mask : (uN t2 l (n+n)).t = uN_not (uN_shift_right uN_ones n) in
  //assert(forall (i:nat{i<n+n}). (_).v mask i == (if i<n then true else false));
  let x' : (uN t2 l (n+n)).t = uN_expend (n+n) (uN_cast t2 x) in
  //assert (forall (i:nat{i<n+n}). (_).v x' i == (if i<n then (_).v x i else (_).v x' i));
  let x' : (uN t2 l (n+n)).t = uN_and x' mask in
  //assert(forall (i:nat{i<n+n}). (_).v x' i == (if i<n then (_).v x i else false));
  let y' : (uN t2 l (n+n)).t = uN_expend (n+n) (uN_cast t2 y) in
  //assert(forall (i:nat{i<n+n}). (_).v y' i == (if i<n then (_).v y i else (_).v y' i));
  let y' : (uN t2 l (n+n)).t = uN_shift_right #t2 #l #(n+n) y' n in
  //assert(forall (i:nat{i<n+n}). (_).v y' i == (if i<n then false else (_).v y (i-n)));
  admit ();
  uN_or x' y'
#pop-options

val uN_split
  (#t1:inttype{unsigned t1}) (#l:secrecy_level)
  (t2:inttype{unsigned t2})
  (#n:nat{n+n<=bits t1 /\ n<=bits t2})
  (x:(uN t1 l (n+n)).t) :
  Pure ((uN t2 l n).t * (uN t2 l n).t)
    (requires True)
    (ensures fun (y, z) -> forall (i:nat{i<n+n}). (_).v (uN_concat t1 y z) i == (_).v x i)
#push-options "--z3rlimit 100"
let uN_split #t1 #l t2 #n x =
  let y : (uN t2 l n).t = uN_cast t2 (uN_reduce n x) in
  assert(forall (i:nat{i<n}). (_).v y i == (_).v x i);
  let z : (uN t2 l n).t = uN_cast t2 (uN_reduce n (uN_shift_left x n)) in
  assert(forall (i:nat{i<n}). (_).v z i == (_).v x (i+n));
  FStar.Classical.forall_intro (fun (i:nat{i<n+n}) ->
    ( if i<n then (
        assert((_).v (uN_concat t1 y z) i == (_).v y i)
      ) else (
        assert((i-n)+n == i);
        assert((_).v (uN_concat t1 y z) i == (_).v z (i-n));
        assert((_).v z (i-n) == (_).v x ((i-n)+n))
      )
    ) <: Lemma ((_).v (uN_concat t1 y z) i == (_).v x i)
  ) <: Lemma (forall (i:nat{i<n+n}). (_).v (uN_concat t1 y z) i == (_).v x i);
  (y, z)

let uNxM (t:inttype{unsigned t}) (l:secrecy_level) (n:nat{n<=bits t}) (m:nat) : Type0 =
  xNxM (uN t l n) m

val uNxM_h_concat
  (#t1:inttype{unsigned t1}) (#l:secrecy_level)
  (t2:inttype{unsigned t2})
  (#n:nat{n<=bits t1 /\ n+n<=bits t2}) (#m:nat)
  (x y:uNxM t1 l n m) :
  Pure (uNxM t2 l (n+n) m)
    (requires True)
    (ensures fun z -> forall (i:nat{i<n+n}) (j:nat{j<m}).
      (_).v (index z j) i == (if i<n then (_).v (index x j) i else (_).v (index y j) (i-n))
    )
let uNxM_h_concat t2 x y =
  xNxM_mk _ _ (fun i -> uN_concat t2 (index x i) (index y i))

val uNxM_h_split
  (#t1:inttype{unsigned t1}) (#l:secrecy_level)
  (t2:inttype{unsigned t2})
  (#n:nat{n+n<=bits t1 /\ n<=bits t2}) (#m:nat)
  (x:uNxM t1 l (n+n) m) :
  Pure (uNxM t2 l n m * uNxM t2 l n m)
    (requires True)
    (ensures fun (y, z) -> forall (i:nat{i<n+n}) (j:nat{j<m}).
      (_).v (index (uNxM_h_concat t1 y z) j) i == (_).v (index x j) i
    )
#push-options "--z3rlimit 100"
let uNxM_h_split #t1 #l t2 #n #m x =
  let aux1 (a, b) = a in
  let aux2 (a, b) = b in
  let y : uNxM t2 l n m = xNxM_mk _ _ (fun j -> aux1 (uN_split t2 (index x j))) in
  let z : uNxM t2 l n m = xNxM_mk _ _ (fun j -> aux2 (uN_split t2 (index x j))) in
  FStar.Classical.forall_intro_2 (fun (i:nat{i<n+n}) (j:nat{j<m}) ->
    ( let a = aux1 (uN_split t2 (index x j)) in
      let b = aux2 (uN_split t2 (index x j)) in
      assert(uN_split t2 (index x j) == (a, b))
    ) <: Lemma ((_).v (index (uNxM_h_concat t1 y z) j) i == (_).v (index x j) i)
  );
  (y, z)
#pop-options

val uNxM_v_concat
  (#t:inttype{unsigned t}) (#l:secrecy_level)
  (#n:nat{n<=bits t}) (#m:nat)
  (x y:uNxM t l n m) :
  Pure (uNxM t l n (m+m))
    (requires True)
    (ensures fun z -> forall (i:nat{i<n}) (j:nat{j<m+m}).
      (_).v (index z j) i == (if j<m then (_).v (index x j) i else (_).v (index y (j-m)) i)
    )
let uNxM_v_concat #t #l #n #m x y =
  xNxM_mk _ _ (fun i -> if i<m then index x i else index y (i-m))

val uNxM_v_split
  (#t:inttype{unsigned t}) (#l:secrecy_level)
  (#n:nat{n<=bits t}) (#m:nat)
  (x:uNxM t l n (m+m)) :
  Pure (uNxM t l n m * uNxM t l n m)
    (requires True)
    (ensures fun (y, z) -> forall (i:nat{i<n}) (j:nat{j<m+m}).
      (_).v (index (uNxM_v_concat y z) j) i == (_).v (index x j) i
    )
#push-options "--z3rlimit 100"
let uNxM_v_split #t #l #n #m x =
  let y = xNxM_mk _ _ (fun j -> index x j) in
  let z = xNxM_mk _ _ (fun j -> index x (j+m)) in
  FStar.Classical.forall_intro_2 (fun i j ->
    ( if j<m then (
        assert ((_).v (index (uNxM_v_concat y z) j) i == (_).v (index y j) i)
      ) else (
        assert ((_).v (index (uNxM_v_concat y z) j) i == (_).v (index z (j-m)) i);
        assert (index z (j-m) == index x ((j-m)+m));
        assert (index x ((j-m)+m) == index x j)
      )
    ) <:Lemma ((_).v (index (uNxM_v_concat y z) j) i == (_).v (index x j) i)
  );
  (y, z)
#pop-options

let tt (n:nat) = (t:inttype{unsigned t /\ n<=bits t})

type transposable : (n:nat -> tt n -> m:nat -> tt m -> Type0) =
| Tr1 : t1:tt 1 -> t2:tt 1 -> transposable 1 t1 1 t2
| TrH : n:nat -> m:nat -> #t1:tt n -> #t2:tt m -> t3:tt (n+n) -> transposable n t1 m t2 -> transposable (n+n) t3 m t2
| TrV : n:nat -> m:nat -> #t1:tt n -> #t2:tt m -> t3:tt (m+m) -> transposable n t1 m t2 -> transposable n t1 (m+m) t3

val transpose
  (#n #m:nat) (#t1:tt n) (#l:secrecy_level) (#t2:tt m)
  (pr:transposable n t1 m t2)
  (x:uNxM t1 l n m) :
  Pure (uNxM t2 l m n)
    (requires True)
    (ensures fun y -> forall (i:nat{i<n}) (j:nat{j<m}). (_).v (index y i) j == (_).v (index x j) i)
    (decreases pr)
#push-options "--ifuel 1 --z3rlimit 100"
let rec transpose #n #m #t1 #l #t2 pr x =
  admit ()
  //match pr with
  //| Tr1 _ _ -> xNxM_mk _ _ (fun 0 -> uN_cast t2 (index x 0))
  //| TrH n m #t3 #t2 t1 pr' ->
  //  let (y, z) : (uNxM t3 l n m * uNxM t3 l n m) = uNxM_h_split t3 (x <: uNxM t1 l (n+n) m) in
  //  let y' : uNxM t2 l m n = transpose pr' y in
  //  let z' : uNxM t2 l m n = transpose pr' z in
  //  let w : uNxM t2 l m (n+n) = uNxM_v_concat y' z' in
  //  w
  //| TrV n m #t1 #t3 t2 pr' ->
  //  let (y, z) : (uNxM t1 l n m * uNxM t1 l n m) = uNxM_v_split (x <: uNxM t1 l n (m+m)) in
  //  let y' : uNxM t3 l m n = transpose pr' y in
  //  let z' : uNxM t3 l m n = transpose pr' z in
  //  let w : uNxM t2 l (m+m) n = uNxM_h_concat t2 y' z' in
  //  w
#pop-options

val transpose_inv (#n #m:nat) (#t1:tt n) (#t2:tt m) (pr:transposable n t1 m t2) :
  Pure (transposable m t2 n t1) (requires True) (ensures fun _ -> True) (decreases pr)
#push-options "--ifuel 1"
let rec transpose_inv pr = match pr with
| Tr1 t1 t2 -> Tr1 t2 t1
| TrH n m #t1 #t2 t3 pr -> TrV m n #t2 #t1 t3 (transpose_inv pr)
| TrV n m #t1 #t2 t3 pr -> TrH m n #t2 #t1 t3 (transpose_inv pr)
#pop-options

val transpose_8_8 : transposable 8 U8 8 U8
let transpose_8_8 =
    TrH 4 8 U8
  ( TrV 4 4 U8
  ( TrH 2 4 U8
  ( TrV 2 2 U8
  ( TrH 1 2 U8
  ( TrV 1 1 U8
  ( Tr1 U8 U8
  ))))))

val transpose_8_16 : transposable 8 U8 16 U16
let transpose_8_16 = TrV 8 8 U16 transpose_8_8

val transpose_8_32 : transposable 8 U8 32 U32
let transpose_8_32 = TrV 8 16 U32 transpose_8_16

val transpose_8_64 : transposable 8 U8 64 U64
let transpose_8_64 = TrV 8 32 U64 transpose_8_32

val transpose_64_8 : transposable 64 U64 8 U8
let transpose_64_8 = transpose_inv transpose_8_64

val line (#a:Type0) (#xN:foo a) (#m:nat) (i:nat{i<m}) (x:xNxM xN m) : x1xM a xN.n
let line i x =
  let aux1 j k = (_).v (index x i) j in
  let aux2 j = (_).mk (aux1 j) in
  xNxM_mk _ _ aux2

val line_transpose (#n #m:nat) (#t1:tt n) (#t2:tt m) (#l:secrecy_level) (x:uNxM t1 l n m) (i:nat{i<n})
  (pr:transposable n t1 m t2) :
    Lemma (line i (transpose pr x) == column i x)
  [SMTPat (line i (transpose pr x))]
let line_transpose x i pr = xNxM_eq_intro (line i (transpose pr x)) (column i x)

val column_transpose (#n #m:nat) (#t1:tt n) (#t2:tt m) (#l:secrecy_level) (x:uNxM t1 l n m) (j:nat{j<m})
  (pr:transposable n t1 m t2) :
    Lemma (column j (transpose pr x) == line j x)
  [SMTPat (column j (transpose pr x))]
let column_transpose x j pr = xNxM_eq_intro (column j (transpose pr x)) (line j x)

val transpose_transpose
  (#n #m:nat)
  (#t1:tt n) (#t2:tt m) (#t3:tt n) (#l:secrecy_level)
  (x:uNxM t1 l n m) (j:nat{j<m})
  (pr1:transposable n t1 m t2) (pr2:transposable m t2 n t3) :
    Lemma (line j (transpose pr2 (transpose pr1 x)) == line j x)
let transpose_transpose x j pr1 pr2 = ()
*)