(** This module exposes the EverCrypt cryptographic provider, which offers
    agile and multiplexing interfaces for HACL* primitives. *)

open SharedDefs

type bytes = CBytes.t
(** [bytes] is ultimately an alias for [Stdlib.Bytes.t], the type of buffers currently used
    throughout the library *)

module Error : sig
  type error_code =
    | UnsupportedAlgorithm
    | InvalidKey
    | AuthenticationFailure
    | InvalidIVLength
    | DecodeError
  type 'a result =
    | Success of 'a
    | Error of error_code
end
(** Return type used for {!AEAD} functions *)


(** {1 AEAD}
    Algorithms for AEAD (authenticated encryption with additional data) *)

(** {2 Agile interface } *)

module AEAD : sig
  type t

  val init : alg:AEADDefs.alg -> key:bytes -> t Error.result
  (** [init alg key] tries to allocate the internal state for algorithm [alg] with [key]
      and returns a {!t} if successful or an {!Error.error_code} otherwise. *)

  val encrypt : st:t -> iv:bytes -> ad:bytes -> pt:bytes -> (bytes * bytes) Error.result
  (** [encrypt key iv ad pt] takes a [key], an initial value [iv], additional data
      [ad], and plaintext [pt] and, if successful, returns a tuple containing the encrypted [pt] and the
      authentication tag for the plaintext and the associated data. *)

  val decrypt : st:t -> iv:bytes -> ad:bytes -> ct:bytes -> tag:bytes -> bytes Error.result
  (** [decrypt key iv ad ct tag] takes a [key], the initial value [iv], additional
      data [ad], ciphertext [ct], and authentication tag [tag], and, if successful,
      returns the decrypted [ct]. *)

  (** Versions of these functions which write their output in a buffer passed in as
      an argument *)
  module Noalloc : sig
    val encrypt : st:t -> iv:bytes -> ad:bytes -> pt:bytes -> ct:bytes -> tag:bytes -> unit Error.result
    (** [encrypt st iv ad pt ct tag] takes a state [st], an initial value [iv], additional data
        [ad], and plaintext [pt], as well as output buffers [ct], which, if successful, will
        contain the encrypted [pt], and [tag], which will contain the authentication tag for
        the plaintext and the associated data. *)

    val decrypt : st:t -> iv:bytes -> ad:bytes -> ct:bytes -> tag:bytes -> pt:bytes -> unit Error.result
    (** [decrypt st iv ad ct tag pt] takes a state [st], the initial value [iv], additional
        data [ad], ciphertext [ct], and authentication tag [tag], as well as output buffer [pt],
        which, if successful, will contain the decrypted [ct]. *)
  end
end
(** Agile, multiplexing AEAD interface exposing AES128-GCM, AES256-GCM, and Chacha20-Poly1305

    To use the agile AEAD interface, users first need to initialise an internal state
    using {!init}. This state will then need to be passed to every call to {!encrypt}
    and {!decrypt}. It can be reused as many times as needed.
    Users are not required to manually free the state.

    The [tag] buffer must be 16 bytes long. For [key] and [iv], each algorithm
    has different constraints:
    - AES128-GCM: [key] = 16 bytes , [iv] > 0 bytes
    - AES256-GCM: [key] = 32 bytes, [iv] > 0 bytes
    - Chacha20-Poly1305: [key] = 32 bytes, [iv] = 12 bytes
*)


(** {2 Chacha20-Poly1305} *)

module Chacha20_Poly1305 : Chacha20_Poly1305
(** Multiplexing interface for Chacha20-Poly1305 *)

(** {1 ECDH and EdDSA }
    Algorithms for digital signatures and key agreement *)

(** {2 Curve25519} *)

module Curve25519 : Curve25519
(** Multiplexing interface for ECDH using Curve25519 *)

(** {2 Ed25519} *)

module Ed25519 : EdDSA
(** This interface does not yet support multiplexing and is
    identical to the one in {!Hacl.Ed25519} *)


(** {1 Hashing } *)
(** {2 Agile interface } *)

module Hash : sig

(** {1 Direct interface} *)

  val hash : alg:HashDefs.alg -> msg:bytes -> bytes
  (** [hash alg msg] hashes [msg] using algorithm [alg] and returns the digest. *)

  val hash_noalloc : alg:HashDefs.alg -> msg:bytes -> digest:bytes -> unit
  (** [hash_noalloc alg msg digest] hashes [msg] using algorithm [alg] and outputs the
      result in [digest]. *)

(** {1 Streaming interface}

    To use the agile streaming interface, users first need to initialise and internal state using {!init}.
    The state will then need to be passed to every call to {!update} and {!finish}. Both {!update} and
    {!finish} can be called as many times as needed without invalidating the state.
    Users are not required to manually free the state.

    When using the streaming interface, the total number of bytes passed through {!update} must not exceed
    - 2{^61} for SHA-224, SHA-256, and the legacy algorithms
    - 2{^125} for SHA-384 and SHA-512
*)

  type t
  val init : alg:HashDefs.alg -> t
  (** [init alg] allocates the internal state for algorithm [alg] and
      returns a {!t}. *)

  val update : st:t -> msg:bytes -> unit
  (** [update st msg] updates the internal state [st] with the contents of [msg]. *)

  val finish : st:t -> bytes
  (** [finish st] returns the digest without invalidating the internal state [st]. *)

  val finish_noalloc : st:t -> digest:bytes -> unit
  (** [finish_noalloc st digest] writes a digest in [digest], without invalidating the
      internal state [st]. *)

end
(** Agile, multiplexing hashing interface, exposing 4 variants of SHA-2
    (SHA-224, SHA-256, SHA-384, SHA-512), BLAKE2, and 2 legacy algorithms (SHA-1, MD5).
    It offers both direct hashing and a streaming interface.

    {i Note:} The agile BLAKE2 interface is NOT currently multiplexing and it only exposes the portable C
    implementations of BLAKE2b and BLAKE2s. Optimised, platform-specific versions are aviailable
    in {{!Hacl.blake2}Hacl}.

    For [digest], its size must match the size of the digest produced by the algorithm being used:
    - SHA-224: 28 bytes
    - SHA-256: 32 bytes
    - SHA-384: 48 bytes
    - SHA-512: 64 bytes
    - BLAKE2b: <= 64 bytes
    - BLAKE2s: <= 32 bytes

    {b The {{!SharedDefs.HashDefs.deprecated_alg}legacy algorithms} (marked [deprecated]) should NOT be used for cryptographic purposes. }
    For these, the size of the digest is:
    - SHA-1: 20 bytes
    - MD5: 16 bytes
*)

(** {2:sha2 SHA-2}
Multiplexing interfaces for SHA-224 and SHA-256 which use {{!AutoConfig2.SHAEXT}Intel SHA extensions} when available.
*)

module SHA2_224 : HashFunction
(** Direct hashing with SHA-224

The [digest] buffer must match the digest size of SHA-224, which is 28 bytes.
*)

module SHA2_256 : HashFunction
(** Direct hashing with SHA-256

The [digest] buffer must match the digest size of SHA-256, which is 32 bytes.
*)


(** {1:mac MACs}
Message authentication codes *)

(** {2 HMAC}
    Portable HMAC implementations. They can use optimised assembly implementations for the
    underlying hash function, if such an implementation exists and
    {{!AutoConfig2.SHAEXT}Intel SHA extensions} are available (see {!sha2}).
*)

module HMAC : sig
  val is_supported_alg : alg:HashDefs.alg -> bool
  (** [is_supported_alg alg] returns true if the hashing algorithm [alg] is supported
      in the agile HMAC interface. *)

  val mac : alg:HashDefs.alg -> key:bytes -> msg:bytes -> bytes
  (** [mac alg key msg] computes the HMAC of [msg] based on hashing algorithm [alg]
      using key [key]. *)

  val mac_noalloc : alg:HashDefs.alg -> key:bytes -> msg:bytes -> tag:bytes -> unit
  (** [mac_noalloc alg key msg tag] computes the HMAC of [msg] based on hashing algorithm [alg]
      using key [key] and writes the result in [tag]. The `tag` buffer needs to satisfy
      the size requirements for the output buffer. *)
end
(** Agile, multiplexing interface for HMAC

The hashing algorithms currently supported are the same as for the {{!EverCrypt.Hash}agile hashing interface}:
    - SHA-2 (SHA-256, SHA-384, SHA-512)
    - BLAKE2 (BLAKE2b, BLAKE2s)

      For HMAC with SHA2, the output buffer is the same size as the digest size of
      the corresponding hash function (see {{!EverCrypt.Hash} here}). For HMAC with BLAKE2,
      the output buffer is 64 bytes for BLAKE2b and 32 bytes for BLAKE2s.
*)


(** Non-agile, multiplexing interfaces for each version of HMAC are also available. *)

module HMAC_SHA2_256 : MAC
(** Multiplexing interface for HMAC-SHA-256 *)

module HMAC_SHA2_384 : MAC
(** Multiplexing interface for HMAC-SHA-384 *)

module HMAC_SHA2_512 : MAC
(** Multiplexing interface for HMAC-SHA-512 *)

(** {2 Poly1305} *)

module Poly1305 : MAC
(** Multiplexing interface for Poly1305 *)


(** {1 Key derivation} *)
(** {2:hkdf HKDF}
    HMAC-based key derivation function

    Portable HKDF implementations. They can use optimised assembly implementations for the
    underlying hash function, if such an implementation exists and
    {{!AutoConfig2.SHAEXT}Intel SHA extensions} are available (see {!sha2}).
*)

module HKDF : sig
  val extract : alg:HashDefs.alg -> salt:bytes -> ikm:bytes -> bytes
  (** [extract alg salt ikm] computes a pseudorandom key using hashing algorithm [alg] with
      input key material [ikm] and salt [salt]. *)

  val expand : alg:HashDefs.alg -> prk:bytes -> info:bytes -> size:int -> bytes
  (** [expand alg prk info size] expands the pseudorandom key [prk] using hashing
      algorithm [alg], taking the info string [info] into account and
      returns a buffer of [size] bytes. *)

  module Noalloc : sig
    val extract : alg:HashDefs.alg -> salt:bytes -> ikm:bytes -> prk:bytes -> unit
    (** [extract alg salt ikm prk] computes a pseudorandom key [prk] using
        hashing algorithm [alg] with input key material [ikm] and salt [salt]. *)

    val expand : alg:HashDefs.alg -> prk:bytes -> info:bytes -> okm:bytes -> unit
    (** [expand alg prk info okm] expands the pseudorandom key [prk] using
        hashing algorithm [alg], taking the info string [info] into account,
        and writes the output key material in [okm]. *)
  end
end
(** Agile, multiplexing interface for HKDF

    Supports the same hashing algorithms as {!EverCrypt.HMAC}.
*)

module HKDF_SHA2_256 : HKDF
(** Multiplexing interface for HKDF using SHA2-256 *)

module HKDF_SHA2_384 : HKDF
(** Multiplexing interface for HKDF using SHA2-384 *)

module HKDF_SHA2_512 : HKDF
(** Multiplexing interface for HKDF using SHA2-512 *)

(** {1 DRBG}

Deterministic random bit generator
*)

(** {2 HMAC-DRBG} *)

module DRBG : sig
  type t
  val instantiate : ?personalization_string: bytes -> HashDefs.alg -> t option
  val reseed : ?additional_input: bytes -> t -> bool
  val generate : ?additional_input: bytes -> t -> bytes -> bool
  val uninstantiate : t -> unit
end
