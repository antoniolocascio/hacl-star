module Hacl.Spec.AES.SubBytes

// TODO
// the pre-computed sbox should *not* be part of the specification
// it's used as a placeholder until it's replaced by its mathematical definition
val sbox (i:nat{i<256}) : (r:nat{r<256})
let sbox i = match i with
|   0 -> 0x63 |   1 -> 0x7c |   2 -> 0x77 |   3 -> 0x7b |   4 -> 0xf2 |   5 -> 0x6b |   6 -> 0x6f |   7 -> 0xc5
|   8 -> 0x30 |   9 -> 0x01 |  10 -> 0x67 |  11 -> 0x2b |  12 -> 0xfe |  13 -> 0xd7 |  14 -> 0xab |  15 -> 0x76
|  16 -> 0xca |  17 -> 0x82 |  18 -> 0xc9 |  19 -> 0x7d |  20 -> 0xfa |  21 -> 0x59 |  22 -> 0x47 |  23 -> 0xf0
|  24 -> 0xad |  25 -> 0xd4 |  26 -> 0xa2 |  27 -> 0xaf |  28 -> 0x9c |  29 -> 0xa4 |  30 -> 0x72 |  31 -> 0xc0
|  32 -> 0xb7 |  33 -> 0xfd |  34 -> 0x93 |  35 -> 0x26 |  36 -> 0x36 |  37 -> 0x3f |  38 -> 0xf7 |  39 -> 0xcc
|  40 -> 0x34 |  41 -> 0xa5 |  42 -> 0xe5 |  43 -> 0xf1 |  44 -> 0x71 |  45 -> 0xd8 |  46 -> 0x31 |  47 -> 0x15
|  48 -> 0x04 |  49 -> 0xc7 |  50 -> 0x23 |  51 -> 0xc3 |  52 -> 0x18 |  53 -> 0x96 |  54 -> 0x05 |  55 -> 0x9a
|  56 -> 0x07 |  57 -> 0x12 |  58 -> 0x80 |  59 -> 0xe2 |  60 -> 0xeb |  61 -> 0x27 |  62 -> 0xb2 |  63 -> 0x75
|  64 -> 0x09 |  65 -> 0x83 |  66 -> 0x2c |  67 -> 0x1a |  68 -> 0x1b |  69 -> 0x6e |  70 -> 0x5a |  71 -> 0xa0
|  72 -> 0x52 |  73 -> 0x3b |  74 -> 0xd6 |  75 -> 0xb3 |  76 -> 0x29 |  77 -> 0xe3 |  78 -> 0x2f |  79 -> 0x84
|  80 -> 0x53 |  81 -> 0xd1 |  82 -> 0x00 |  83 -> 0xed |  84 -> 0x20 |  85 -> 0xfc |  86 -> 0xb1 |  87 -> 0x5b
|  88 -> 0x6a |  89 -> 0xcb |  90 -> 0xbe |  91 -> 0x39 |  92 -> 0x4a |  93 -> 0x4c |  94 -> 0x58 |  95 -> 0xcf
|  96 -> 0xd0 |  97 -> 0xef |  98 -> 0xaa |  99 -> 0xfb | 100 -> 0x43 | 101 -> 0x4d | 102 -> 0x33 | 103 -> 0x85
| 104 -> 0x45 | 105 -> 0xf9 | 106 -> 0x02 | 107 -> 0x7f | 108 -> 0x50 | 109 -> 0x3c | 110 -> 0x9f | 111 -> 0xa8
| 112 -> 0x51 | 113 -> 0xa3 | 114 -> 0x40 | 115 -> 0x8f | 116 -> 0x92 | 117 -> 0x9d | 118 -> 0x38 | 119 -> 0xf5
| 120 -> 0xbc | 121 -> 0xb6 | 122 -> 0xda | 123 -> 0x21 | 124 -> 0x10 | 125 -> 0xff | 126 -> 0xf3 | 127 -> 0xd2
| 128 -> 0xcd | 129 -> 0x0c | 130 -> 0x13 | 131 -> 0xec | 132 -> 0x5f | 133 -> 0x97 | 134 -> 0x44 | 135 -> 0x17
| 136 -> 0xc4 | 137 -> 0xa7 | 138 -> 0x7e | 139 -> 0x3d | 140 -> 0x64 | 141 -> 0x5d | 142 -> 0x19 | 143 -> 0x73
| 144 -> 0x60 | 145 -> 0x81 | 146 -> 0x4f | 147 -> 0xdc | 148 -> 0x22 | 149 -> 0x2a | 150 -> 0x90 | 151 -> 0x88
| 152 -> 0x46 | 153 -> 0xee | 154 -> 0xb8 | 155 -> 0x14 | 156 -> 0xde | 157 -> 0x5e | 158 -> 0x0b | 159 -> 0xdb
| 160 -> 0xe0 | 161 -> 0x32 | 162 -> 0x3a | 163 -> 0x0a | 164 -> 0x49 | 165 -> 0x06 | 166 -> 0x24 | 167 -> 0x5c
| 168 -> 0xc2 | 169 -> 0xd3 | 170 -> 0xac | 171 -> 0x62 | 172 -> 0x91 | 173 -> 0x95 | 174 -> 0xe4 | 175 -> 0x79
| 176 -> 0xe7 | 177 -> 0xc8 | 178 -> 0x37 | 179 -> 0x6d | 180 -> 0x8d | 181 -> 0xd5 | 182 -> 0x4e | 183 -> 0xa9
| 184 -> 0x6c | 185 -> 0x56 | 186 -> 0xf4 | 187 -> 0xea | 188 -> 0x65 | 189 -> 0x7a | 190 -> 0xae | 191 -> 0x08
| 192 -> 0xba | 193 -> 0x78 | 194 -> 0x25 | 195 -> 0x2e | 196 -> 0x1c | 197 -> 0xa6 | 198 -> 0xb4 | 199 -> 0xc6
| 200 -> 0xe8 | 201 -> 0xdd | 202 -> 0x74 | 203 -> 0x1f | 204 -> 0x4b | 205 -> 0xbd | 206 -> 0x8b | 207 -> 0x8a
| 208 -> 0x70 | 209 -> 0x3e | 210 -> 0xb5 | 211 -> 0x66 | 212 -> 0x48 | 213 -> 0x03 | 214 -> 0xf6 | 215 -> 0x0e
| 216 -> 0x61 | 217 -> 0x35 | 218 -> 0x57 | 219 -> 0xb9 | 220 -> 0x86 | 221 -> 0xc1 | 222 -> 0x1d | 223 -> 0x9e
| 224 -> 0xe1 | 225 -> 0xf8 | 226 -> 0x98 | 227 -> 0x11 | 228 -> 0x69 | 229 -> 0xd9 | 230 -> 0x8e | 231 -> 0x94
| 232 -> 0x9b | 233 -> 0x1e | 234 -> 0x87 | 235 -> 0xe9 | 236 -> 0xce | 237 -> 0x55 | 238 -> 0x28 | 239 -> 0xdf
| 240 -> 0x8c | 241 -> 0xa1 | 242 -> 0x89 | 243 -> 0x0d | 244 -> 0xbf | 245 -> 0xe6 | 246 -> 0x42 | 247 -> 0x68
| 248 -> 0x41 | 249 -> 0x99 | 250 -> 0x2d | 251 -> 0x0f | 252 -> 0xb0 | 253 -> 0x54 | 254 -> 0xbb | 255 -> 0x16
