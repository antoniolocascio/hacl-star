module Vale.InstructionReorder

/// Open all the relevant modules from the x64 semantics.

open Vale.X64.Bytes_Code_s
open Vale.X64.Instruction_s
open Vale.X64.Instructions_s
open Vale.X64.Machine_Semantics_s
open Vale.X64.Machine_s
open Vale.X64.Print_s

/// Open the PossiblyMonad so that we can keep track of failure cases
/// for easier debugging.

open Vale.PossiblyMonad

/// Finally some convenience module renamings

module L = FStar.List.Tot

/// We first need to talk about what locations may be accessed (either
/// via a read or via a write) by an instruction.
///
/// This allows us to define read and write sets for instructions.

type access_location =
  | ALoc64 : operand -> access_location
  | ALoc128 : operand128 -> access_location
  | ALocCf : access_location
  | ALocOf : access_location

let access_location_of_explicit (t:instr_operand_explicit) (i:instr_operand_t t) : access_location =
  match t with
  | IOp64 -> ALoc64 i
  | IOpXmm -> ALoc128 i

let access_location_of_implicit (t:instr_operand_implicit) : access_location =
  match t with
  | IOp64One i -> ALoc64 i
  | IOpXmmOne i -> ALoc128 i
  | IOpFlagsCf -> ALocCf
  | IOpFlagsOf -> ALocOf

type rw_set = (list access_location) * (list access_location)

let rec aux_read_set0 (args:list instr_operand) (oprs:instr_operands_t_args args) =
  match args with
  | [] -> []
  | (IOpEx i) :: args ->
    let l, r = coerce #(instr_operand_t i & instr_operands_t_args args) oprs in
    access_location_of_explicit i l :: aux_read_set0 args r
  | (IOpIm i) :: args ->
    access_location_of_implicit i :: aux_read_set0 args (coerce #(instr_operands_t_args args) oprs)

let rec aux_read_set1
    (outs:list instr_out) (args:list instr_operand) (oprs:instr_operands_t outs args) : list access_location =
  match outs with
  | [] -> aux_read_set0 args oprs
  | (Out, IOpEx i) :: outs ->
    let l, r = coerce #(instr_operand_t i & instr_operands_t outs args) oprs in
    aux_read_set1 outs args r
  | (InOut, IOpEx i) :: outs ->
    let l, r = coerce #(instr_operand_t i & instr_operands_t outs args) oprs in
    access_location_of_explicit i l :: aux_read_set1 outs args r
  | (Out, IOpIm i) :: outs ->
    aux_read_set1 outs args (coerce #(instr_operands_t outs args) oprs)
  | (InOut, IOpIm i) :: outs ->
    access_location_of_implicit i :: aux_read_set1 outs args (coerce #(instr_operands_t outs args) oprs)

let read_set (i:instr_t_record) (oprs:instr_operands_t i.outs i.args) : list access_location =
  aux_read_set1 i.outs i.args oprs

let rec aux_write_set
    (outs:list instr_out) (args:list instr_operand) (oprs:instr_operands_t outs args) : list access_location =
  match outs with
  | [] -> []
  | (_, IOpEx i) :: outs ->
    let l, r = coerce #(instr_operand_t i & instr_operands_t outs args) oprs in
    access_location_of_explicit i l :: aux_write_set outs args r
  | (_, IOpIm i) :: outs ->
    access_location_of_implicit i :: aux_write_set outs args (coerce #(instr_operands_t outs args) oprs)

let write_set (i:instr_t_record) (oprs:instr_operands_t i.outs i.args) : list access_location =
  aux_write_set i.outs i.args oprs

let rw_set_of_ins (i:ins) : rw_set =
  match i with
  | Instr i oprs _ ->
    read_set i oprs, write_set i oprs
  | Push src t ->
    [ALoc64 (OReg rRsp); ALoc64 src],
    [ALoc64 (OReg rRsp); admit ()]
    (* TODO FIXME: How do we reconcile this with the MConst in the [untainted_eval_ins] write? *)
  | Pop dst t ->
    [ALoc64 (OReg rRsp); ALoc64 (OStack (MReg rRsp 0, t))],
    [ALoc64 (OReg rRsp); ALoc64 dst]
  | Alloc _
  | Dealloc _ ->
    [ALoc64 (OReg rRsp)], [ALoc64 (OReg rRsp)]

/// We now need to define what it means for two different access
/// locations to be "disjoint".
///
/// Note that it is safe to say that two operands are not disjoint
/// even if they are, but the converse is not true. That is, to be
/// safe, we can say two operands are disjoint only if it is
/// guaranteed that they are disjoint.

let disjoint_access_locations (a1 a2:access_location) : pbool =
  match a1, a2 with
  | ALocCf, ALocCf -> ffalse "carry flag not disjoint from itself"
  | ALocOf, ALocOf -> ffalse "overflow flag not disjoint from itself"
  | ALocCf, _ | ALocOf, _ | _, ALocCf | _, ALocOf -> ttrue
  | ALoc64 o1, ALoc64 o2 -> (
      match o1, o2 with
      | OConst _, _ | _, OConst _ -> ttrue
      | OReg r1, OReg r2 -> (r1 <> r2) /- ("register " ^ print_reg_name r1 ^ " not disjoint from itself")
      | _ ->
        unimplemented "conservatively not disjoint ALoc64s"
    )
  | ALoc128 o1, ALoc128 o2 -> (
      match o1, o2 with
      | OReg128 r1, OReg128 r2 -> (r1 <> r2) /- ("register " ^ print_xmm r1 gcc ^ " not disjoint from itself")
      | _ ->
      unimplemented "conservatively not disjoint ALoc128s"
    )
  | ALoc64 o1, ALoc128 o2 | ALoc128 o1, ALoc64 o2 -> (
      unimplemented "conservatively not disjoint ALoc64 & ALoc128"
    )

/// Given two read/write sets corresponding to two neighboring
/// instructions, we can say whether exchanging those two instructions
/// should be allowed.

let rw_exchange_allowed (rw1 rw2 : rw_set) : pbool =
  let (r1, w1), (r2, w2) = rw1, rw2 in
  let (&&.) (x y:pbool) : pbool =
    match x with
    | ttrue -> y
    | _ -> x in
  let rec for_all (f : 'a -> pbool) (l : list 'a) : pbool =
    match l with
    | [] -> ttrue
    | x :: xs -> f x &&. for_all f xs in
  let disjoint (l1 l2:list access_location) r : pbool =
    match l1 with
    | [] -> ttrue
    | x :: xs ->
      (for_all (fun y -> (disjoint_access_locations x y)) l2) /+< (r ^ " because ") in
  (disjoint r1 w2 "read set of 1st not disjoint from write set of 2nd") &&.
  (disjoint r2 w2 "read set of 2nd not disjoint from write set of 1st") &&.
  (disjoint w1 w2 "write sets not disjoint")

let ins_exchange_allowed (i1 i2 : ins) : pbool =
  (rw_exchange_allowed (rw_set_of_ins i1) (rw_set_of_ins i2))
  /+> (" for instructions " ^ print_ins i1 gcc ^ " and " ^ print_ins i2 gcc)

/// First, we must define what it means for two states to be
/// equivalent. We currently assume that we can _completely_ ignore
/// the flags. This is a terrible idea, and should be fixed ASAP.
///
/// WARNING UNSOUND TODO FIXME

let equiv_states (s1 s2 : machine_state) : GTot Type0 =
  admit ()

private abstract
let sanity_check_equiv_states (s1 s2 s3 : machine_state) :
  Lemma
    (ensures (
        (equiv_states s1 s1) /\
        (equiv_states s1 s2 ==> equiv_states s2 s1) /\
        (equiv_states s1 s2 /\ equiv_states s2 s3 ==> equiv_states s1 s3))) =
  admit ()

/// If an exchange is allowed between two instructions based off of
/// their read/write sets, then both orderings of the two instructions
/// behave exactly the same, as per the previously defined
/// [equiv_states] relation.

let lemma_instruction_exchange (i1 i2 : ins) (s1 s2 : machine_state) :
  Lemma
    (requires (
        !!(ins_exchange_allowed i1 i2) /\
        (equiv_states s1 s2)))
    (ensures (
        (let s1', s2' =
           machine_eval_ins i1 (machine_eval_ins i2 s1),
           machine_eval_ins i2 (machine_eval_ins i1 s2) in
         equiv_states s1' s2'))) =
  admit ()

/// Given that we can perform simple swaps between instructions, we
/// can define a relation that tells us if a sequence of instructions
/// can be transformed into another using only swaps allowed via the
/// [ins_exchange_allowed] relation.

let reordering_allowed (c1 c2 : codes) : pbool =
  admit ()

/// If there are two sequences of instructions that can be transformed
/// amongst each other, then they behave identically as per the
/// [equiv_states] relation.

let lemma_reordering (c1 c2 : codes) (fuel:nat) (s1 s2 : machine_state) :
  Lemma
    (requires (
        !!(reordering_allowed c1 c2) /\
        (equiv_states s1 s2) /\
        (Some? (machine_eval_codes c1 fuel s1))))
    (ensures (
        (Some? (machine_eval_codes c2 fuel s2)) /\
        (let Some s1', Some s2' =
           machine_eval_codes c1 fuel s1,
           machine_eval_codes c2 fuel s2 in
         equiv_states s1' s2'))) =
  admit ()
