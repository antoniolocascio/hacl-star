module Hacl.Impl.QTesla.Params

open FStar.Int
open Lib.IntTypes
open Lib.Buffer
open FStar.Int.Cast
open Hacl.Impl.QTesla.Constants

module S = QTesla.Params
module SHA3 = Hacl.SHA3
module I16 = FStar.Int16
module I32 = FStar.Int32
module I64 = FStar.Int64
module UI16 = FStar.UInt16
module UI32 = FStar.UInt32
module UI64 = FStar.UInt64

#reset-options "--z3rlimit 100 --max_fuel 0 --max_ifuel 0"

include Hacl.Impl.QTesla.Heuristic.Parameters

/// Parameters in QTesla.Params aren't marked as unfold or inline_for_extraction;
/// so we need to normalize them here
let params_n = size S.params_n
let params_k = size S.params_k
let params_q = to_elem S.params_q
let params_h = size S.params_h
let params_Le  = UI32.uint_to_t S.params_Le
let params_Ls = UI32.uint_to_t S.params_Ls
let params_B = to_elem S.params_B
let params_U = to_elem S.params_Ls
let params_d = size S.params_d
let params_genA = size S.params_bGenA

/// Parameters specific to the implementation and not in the spec
let params_barr_mult = I64.int_to_t 1021
let params_barr_div = UI32.uint_to_t 32
let params_qinv = I64.int_to_t 3098553343
let params_q_log = size 23 // TODO: this can be computed
let params_r2_invn = I64.int_to_t 113307
let params_s_bits = size 10
let params_b_bits = size 20
let params_rejection = to_elem S.params_Le
let params_r = I64.int_to_t 1081347

inline_for_extraction noextract
let params_SHAKE = SHA3.shake128_hacl
inline_for_extraction noextract
let params_cSHAKE = cshake128_qtesla

inline_for_extraction noextract
let shake_rate = shake128_rate

let crypto_hmbytes = size 64
let crypto_randombytes = size 32
let crypto_seedbytes = size 32
let crypto_c_bytes = size 32

/// Sizes calculated based on parameters, but calculation method varies by parameter set
let crypto_secretkeybytes:size_t = normalize_term (size 2 *. params_s_bits *. params_n /. size 8 +. size 2 *. crypto_seedbytes)
let crypto_publickeybytes = normalize_term ((params_n *. params_q_log +. size 7) /. size 8 +. crypto_seedbytes)
let crypto_bytes = normalize_term (((params_n *. params_d +. size 7) /. (size 8)) +. crypto_c_bytes)

/// Precomputed polynomials for doing NTT transformations

unfold let zeta_list: list elem_base = [
3359531l; 2189080l; 370173l; 677362l;
3132616l; 2989204l; 2362181l; 1720831l;
1203721l; 3239574l; 641414l; 3932234l;
3634017l; 2251707l; 355329l; 4152265l;
1356023l; 4021436l; 1465601l; 4145892l;
3348341l; 675693l; 1598775l; 2799365l;
3336234l; 3856839l; 603157l; 1381183l;
1069471l; 2142038l; 2877387l; 2653969l;
2055310l; 3837123l; 3141231l; 1951522l;
2375048l; 445122l; 1689285l; 3664328l;
676319l; 3844199l; 3669724l; 1009639l;
3666694l; 1585701l; 2102892l; 966523l;
4069555l; 3246046l; 846643l; 2088895l;
4068915l; 3715722l; 4119007l; 230501l;
1626667l; 2119752l; 1171284l; 3153846l;
17941l; 1316589l; 1814059l; 3185686l;
1183551l; 2533671l; 4152595l; 2616162l;
3015757l; 194860l; 1601807l; 1271569l;
139534l; 2581874l; 2183200l; 2060697l;
1036874l; 646550l; 2823563l; 3312274l;
391700l; 99391l; 638903l; 2397164l;
3924868l; 3315551l; 1170767l; 422539l;
1801679l; 166402l; 742283l; 222557l;
522210l; 3415900l; 177835l; 3243355l;
4196855l; 1821376l; 1290490l; 3624896l;
1546898l; 1282351l; 3960516l; 835944l;
2251927l; 90910l; 3034838l; 4082965l;
2311377l; 3512216l; 2652413l; 2191140l;
302935l; 3866228l; 2007511l; 744185l;
2801160l; 3993630l; 592962l; 795067l;
2822609l; 3471782l; 3710854l; 1824985l;
1495256l; 3906591l; 3111335l; 3902620l;
11234l; 1586236l; 3698245l; 492808l;
2729660l; 3369937l; 1869963l; 7244l;
1453951l; 1757304l; 1005437l; 3668653l;
1821321l; 4203686l; 1192473l; 113408l;
2904803l; 1346735l; 4161890l; 711442l;
4020959l; 1164150l; 2139014l; 4134238l;
731747l; 3856202l; 2351090l; 3382729l;
2644693l; 617098l; 2796766l; 1911274l;
552932l; 2476095l; 1801797l; 1381577l;
2338697l; 1336590l; 2798544l; 459121l;
3555631l; 741068l; 2302686l; 1883916l;
2148181l; 2471691l; 2174195l; 1684042l;
3266036l; 227434l; 4107207l; 2910899l;
3427718l; 2011049l; 2706372l; 4182237l;
1243355l; 2908998l; 15068l; 1966206l;
2157082l; 4114100l; 1846352l; 230880l;
1161075l; 1259576l; 1212857l; 1697580l;
39500l; 3079648l; 2529577l; 2082167l;
50282l; 476606l; 1494601l; 1334236l;
3349015l; 1600445l; 413060l; 3104844l;
139283l; 1688398l; 3230017l; 1009712l;
614253l; 2973529l; 2077610l; 2218429l;
4185344l; 254428l; 506799l; 196179l;
3310395l; 4183346l; 3897905l; 2234639l;
1859699l; 3322900l; 2151737l; 1904476l;
2457045l; 383438l; 2543045l; 2985636l;
731083l; 1609871l; 2171434l; 535413l;
2666041l; 405934l; 3303186l; 802974l;
3573046l; 1760267l; 2758359l; 2102800l;
1512274l; 3981750l; 1838169l; 2101846l;
1363757l; 1342163l; 3608830l; 321523l;
1072908l; 855117l; 1679204l; 3624675l;
3183259l; 2438624l; 407591l; 1549799l;
490068l; 2769318l; 3185950l; 990968l;
3700398l; 2715638l; 3672301l; 3203080l;
1775408l; 2071611l; 778637l; 2335351l;
3317014l; 3768001l; 571163l; 2618746l;
1028702l; 3174131l; 764504l; 1386439l;
4188876l; 1131998l; 1057083l; 39651l;
2588805l; 2519763l; 3838931l; 4130059l;
1893001l; 2066802l; 572208l; 2529031l;
220967l; 3880345l; 1820301l; 2205978l;
3036090l; 1648541l; 4012391l; 1432533l;
3068186l; 1645476l; 1397186l; 2112498l;
4168213l; 1234734l; 1648052l; 1803157l;
2011730l; 1648875l; 2547914l; 437873l;
2460774l; 3403214l; 2690605l; 2567052l;
739775l; 1854855l; 520305l; 3661464l;
1120944l; 1245195l; 1147367l; 2571134l;
696367l; 3009976l; 834907l; 1691662l;
1384090l; 2795844l; 1813845l; 3425954l;
4194068l; 1317042l; 2056507l; 470026l;
3097617l; 2678203l; 3077203l; 2116013l;
4155561l; 2844478l; 1467696l; 4150754l;
992951l; 471101l; 4062883l; 1584992l;
2252609l; 3322854l; 1597940l; 3581574l;
1115369l; 4153697l; 3236495l; 4075586l;
2066340l; 1262360l; 2730720l; 3664692l;
2681478l; 2929295l; 3831713l; 3683420l;
2511172l; 3689552l; 2645837l; 2414330l;
857564l; 3703853l; 468246l; 1574274l;
3590547l; 2348366l; 1565207l; 1815326l;
2508730l; 1749217l; 465029l; 260794l;
1630097l; 3019607l; 3872759l; 1053481l;
3958758l; 3415305l; 54348l; 2516l; 
3045515l; 3011542l; 1951553l; 1882613l;
1729323l; 801736l; 3662451l; 909634l;
2949838l; 2598628l; 1652685l; 1945350l;
3221627l; 2879417l; 2732226l; 3883548l;
1891328l; 3215710l; 3159721l; 1318941l;
2153764l; 1870381l; 4039453l; 3375151l;
2655219l; 4089723l; 1388508l; 3436490l;
3956335l; 2748982l; 4111030l; 328986l;
1780674l; 2570336l; 2608795l; 2600572l;
2748827l; 790335l; 1988956l; 3946950l;
1789942l; 710384l; 3900335l; 457139l;
2550557l; 3042298l; 1952120l; 1998308l;
259999l; 2361900l; 119023l; 3680445l;
1893737l; 4050016l; 2696786l; 567472l;
3085466l; 1580931l; 1360307l; 3075154l;
904205l; 1306381l; 3257843l; 2926984l;
2065676l; 3221598l; 2551064l; 1580354l;
1636374l; 699891l; 1821560l; 670885l;
947258l; 2908840l; 3049868l; 1038075l;
1701447l; 2439140l; 2048478l; 3183312l;
2224644l; 320592l; 3304074l; 2611056l;
422256l; 1752180l; 2217951l; 2900510l;
1321050l; 2797671l; 312886l; 2624042l;
3166863l; 908176l; 24947l; 152205l;
2891981l; 189908l; 1959427l; 1365987l;
2071767l; 1932065l; 3185693l; 3889374l;
3644713l; 79765l; 969178l; 11268l; 
1992233l; 1579325l; 1224905l; 3741957l; 
1894871l; 3060100l; 1787540l; 4194180l; 
1396587l; 2745514l; 26822l; 695515l; 
2348201l; 249698l; 2988539l; 1081347l ] 

unfold let zetainv_list: list elem_base = [
1217030l; 3955871l; 1857368l; 3510054l; 4178747l; 1460055l; 2808982l; 11389l;
2418029l; 1145469l; 2310698l; 463612l; 2980664l; 2626244l; 2213336l; 4194301l;
3236391l; 4125804l; 560856l; 316195l; 1019876l; 2273504l; 2133802l; 2839582l;
2246142l; 4015661l; 1313588l; 4053364l; 4180622l; 3297393l; 1038706l;
1581527l; 3892683l; 1407898l; 2884519l; 1305059l; 1987618l; 2453389l;
3783313l; 1594513l; 901495l; 3884977l; 1980925l; 1022257l; 2157091l; 1766429l;
2504122l; 3167494l; 1155701l; 1296729l; 3258311l; 3534684l; 2384009l;
3505678l; 2569195l; 2625215l; 1654505l; 983971l; 2139893l; 1278585l; 947726l;
2899188l; 3301364l; 1130415l; 2845262l; 2624638l; 1120103l; 3638097l;
1508783l; 155553l; 2311832l; 525124l; 4086546l; 1843669l; 3945570l; 2207261l;
2253449l; 1163271l; 1655012l; 3748430l; 305234l; 3495185l; 2415627l; 258619l;
2216613l; 3415234l; 1456742l; 1604997l; 1596774l; 1635233l; 2424895l;
3876583l; 94539l; 1456587l; 249234l; 769079l; 2817061l; 115846l; 1550350l;
830418l; 166116l; 2335188l; 2051805l; 2886628l; 1045848l; 989859l; 2314241l;
322021l; 1473343l; 1326152l; 983942l; 2260219l; 2552884l; 1606941l; 1255731l;
3295935l; 543118l; 3403833l; 2476246l; 2322956l; 2254016l; 1194027l; 1160054l;
4203053l; 4151221l; 790264l; 246811l; 3152088l; 332810l; 1185962l; 2575472l;
3944775l; 3740540l; 2456352l; 1696839l; 2390243l; 2640362l; 1857203l; 615022l;
2631295l; 3737323l; 501716l; 3348005l; 1791239l; 1559732l; 516017l; 1694397l;
522149l; 373856l; 1276274l; 1524091l; 540877l; 1474849l; 2943209l; 2139229l;
129983l; 969074l; 51872l; 3090200l; 623995l; 2607629l; 882715l; 1952960l;
2620577l; 142686l; 3734468l; 3212618l; 54815l; 2737873l; 1361091l; 50008l;
2089556l; 1128366l; 1527366l; 1107952l; 3735543l; 2149062l; 2888527l; 11501l;
779615l; 2391724l; 1409725l; 2821479l; 2513907l; 3370662l; 1195593l; 3509202l;
1634435l; 3058202l; 2960374l; 3084625l; 544105l; 3685264l; 2350714l; 3465794l;
1638517l; 1514964l; 802355l; 1744795l; 3767696l; 1657655l; 2556694l; 2193839l;
2402412l; 2557517l; 2970835l; 37356l; 2093071l; 2808383l; 2560093l; 1137383l;
2773036l; 193178l; 2557028l; 1169479l; 1999591l; 2385268l; 325224l; 3984602l;
1676538l; 3633361l; 2138767l; 2312568l; 75510l; 366638l; 1685806l; 1616764l;
4165918l; 3148486l; 3073571l; 16693l; 2819130l; 3441065l; 1031438l; 3176867l;
1586823l; 3634406l; 437568l; 888555l; 1870218l; 3426932l; 2133958l; 2430161l;
1002489l; 533268l; 1489931l; 505171l; 3214601l; 1019619l; 1436251l; 3715501l;
2655770l; 3797978l; 1766945l; 1022310l; 580894l; 2526365l; 3350452l; 3132661l;
3884046l; 596739l; 2863406l; 2841812l; 2103723l; 2367400l; 223819l; 2693295l;
2102769l; 1447210l; 2445302l; 632523l; 3402595l; 902383l; 3799635l; 1539528l;
3670156l; 2034135l; 2595698l; 3474486l; 1219933l; 1662524l; 3822131l;
1748524l; 2301093l; 2053832l; 882669l; 2345870l; 1970930l; 307664l; 22223l;
895174l; 4009390l; 3698770l; 3951141l; 20225l; 1987140l; 2127959l; 1232040l;
3591316l; 3195857l; 975552l; 2517171l; 4066286l; 1100725l; 3792509l; 2605124l;
856554l; 2871333l; 2710968l; 3728963l; 4155287l; 2123402l; 1675992l; 1125921l;
4166069l; 2507989l; 2992712l; 2945993l; 3044494l; 3974689l; 2359217l; 91469l;
2048487l; 2239363l; 4190501l; 1296571l; 2962214l; 23332l; 1499197l; 2194520l;
777851l; 1294670l; 98362l; 3978135l; 939533l; 2521527l; 2031374l; 1733878l;
2057388l; 2321653l; 1902883l; 3464501l; 649938l; 3746448l; 1407025l; 2868979l;
1866872l; 2823992l; 2403772l; 1729474l; 3652637l; 2294295l; 1408803l;
3588471l; 1560876l; 822840l; 1854479l; 349367l; 3473822l; 71331l; 2066555l;
3041419l; 184610l; 3494127l; 43679l; 2858834l; 1300766l; 4092161l; 3013096l;
1883l; 2384248l; 536916l; 3200132l; 2448265l; 2751618l; 4198325l; 2335606l;
835632l; 1475909l; 3712761l; 507324l; 2619333l; 4194335l; 302949l; 1094234l;
298978l; 2710313l; 2380584l; 494715l; 733787l; 1382960l; 3410502l; 3612607l;
211939l; 1404409l; 3461384l; 2198058l; 339341l; 3902634l; 2014429l; 1553156l;
693353l; 1894192l; 122604l; 1170731l; 4114659l; 1953642l; 3369625l; 245053l;
2923218l; 2658671l; 580673l; 2915079l; 2384193l; 8714l; 962214l; 4027734l;
789669l; 3683359l; 3983012l; 3463286l; 4039167l; 2403890l; 3783030l; 3034802l;
890018l; 280701l; 1808405l; 3566666l; 4106178l; 3813869l; 893295l; 1382006l;
3559019l; 3168695l; 2144872l; 2022369l; 1623695l; 4066035l; 2934000l;
2603762l; 4010709l; 1189812l; 1589407l; 52974l; 1671898l; 3022018l; 1019883l;
2391510l; 2888980l; 4187628l; 1051723l; 3034285l; 2085817l; 2578902l;
3975068l; 86562l; 489847l; 136654l; 2116674l; 3358926l; 959523l; 136014l;
3239046l; 2102677l; 2619868l; 538875l; 3195930l; 535845l; 361370l; 3529250l;
541241l; 2516284l; 3760447l; 1830521l; 2254047l; 1064338l; 368446l; 2150259l;
1551600l; 1328182l; 2063531l; 3136098l; 2824386l; 3602412l; 348730l; 869335l;
1406204l; 2606794l; 3529876l; 857228l; 59677l; 2739968l; 184133l; 2849546l;
53304l; 3850240l; 1953862l; 571552l; 273335l; 3564155l; 965995l; 3001848l;
2484738l; 1843388l; 1216365l; 1072953l; 3528207l; 3835396l; 2016489l; 846038l;
3124222l ]

/// Gaussian sampler parameters and precomputed CDTs

unfold let params_cdt32_rows = size 207
unfold let params_cdt32_cols = size 2

unfold let params_cdt32_v: list I32.t = [
    0x00000000l; 0x00000000l; // 0
    0x023A1B3Fl; 0x4A499901l; // 1
    0x06AD3C4Cl; 0x0CA08592l; // 2
    0x0B1D1E95l; 0x401E5DB9l; // 3
    0x0F879D85l; 0x73D5BFB7l; // 4
    0x13EA9C5Cl; 0x2939948Al; // 5
    0x18440933l; 0x7FE9008Dl; // 6
    0x1C91DFF1l; 0x48F0AE83l; // 7
    0x20D22D0Fl; 0x100BC806l; // 8
    0x25031040l; 0x60F31377l; // 9
    0x2922BEEBl; 0x50B180CFl; // 10
    0x2D2F866Al; 0x1E289169l; // 11
    0x3127CE19l; 0x102CF7B2l; // 12
    0x350A1928l; 0x118E580Dl; // 13
    0x38D5082Cl; 0x6A7E620Al; // 14
    0x3C875A73l; 0x599D6D36l; // 15
    0x401FEF0El; 0x33E6A3E9l; // 16
    0x439DC59El; 0x183BDACEl; // 17
    0x46FFFEDAl; 0x27E0518Bl; // 18
    0x4A45DCD3l; 0x174E5549l; // 19
    0x4D6EC2F3l; 0x49172E12l; // 20
    0x507A35C1l; 0x7D9AA338l; // 21
    0x5367DA64l; 0x752F8E31l; // 22
    0x563775EDl; 0x2DC9F137l; // 23
    0x58E8EC6Bl; 0x2865CAFCl; // 24
    0x5B7C3FD0l; 0x5CCC8CBEl; // 25
    0x5DF18EA7l; 0x3326C087l; // 26
    0x6049129Fl; 0x01DAE6B6l; // 27
    0x62831EF8l; 0x2B524213l; // 28
    0x64A01ED3l; 0x0A5D1038l; // 29
    0x66A09363l; 0x6544ED52l; // 30
    0x68851217l; 0x1F7909FBl; // 31
    0x6A4E42A8l; 0x589BF09Cl; // 32
    0x6BFCDD30l; 0x162DC445l; // 33
    0x6D91A82Dl; 0x7BCBF55Cl; // 34
    0x6F0D7697l; 0x75D3528Fl; // 35
    0x707125EDl; 0x13F82E79l; // 36
    0x71BD9C54l; 0x260C26C7l; // 37
    0x72F3C6C7l; 0x7D9C0191l; // 38
    0x74149755l; 0x04472E63l; // 39
    0x7521036Dl; 0x21A138EAl; // 40
    0x761A0251l; 0x35015867l; // 41
    0x77008B94l; 0x30C0BD22l; // 42
    0x77D595B9l; 0x2DE3507Fl; // 43
    0x789A14EEl; 0x19C5DB94l; // 44
    0x794EF9E2l; 0x6BE2990Al; // 45
    0x79F530BEl; 0x20A7F127l; // 46
    0x7A8DA031l; 0x08443399l; // 47
    0x7B1928A5l; 0x4D9D53CFl; // 48
    0x7B98A38Cl; 0x72C68357l; // 49
    0x7C0CE2C7l; 0x5D698B25l; // 50
    0x7C76B02Al; 0x6EF32779l; // 51
    0x7CD6CD1Dl; 0x09F74C79l; // 52
    0x7D2DF24Dl; 0x5037123Al; // 53
    0x7D7CCF81l; 0x52E6CC5Dl; // 54
    0x7DC40B76l; 0x6127DAEAl; // 55
    0x7E0443D9l; 0x16F11331l; // 56
    0x7E3E0D4Bl; 0x48A00B90l; // 57
    0x7E71F37El; 0x64E0EF47l; // 58
    0x7EA07957l; 0x6735C829l; // 59
    0x7ECA1921l; 0x78D7B202l; // 60
    0x7EEF44CBl; 0x639ED1AEl; // 61
    0x7F10662Dl; 0x02BA119Fl; // 62
    0x7F2DDF53l; 0x66EE6A14l; // 63
    0x7F480AD7l; 0x6F81453Bl; // 64
    0x7F5F3C32l; 0x2587B359l; // 65
    0x7F73C018l; 0x34C60C54l; // 66
    0x7F85DCD8l; 0x6B4FC49Dl; // 67
    0x7F95D2B9l; 0x3769ED08l; // 68
    0x7FA3DC55l; 0x2996B8DEl; // 69
    0x7FB02EFAl; 0x0EEEE30Fl; // 70
    0x7FBAFB03l; 0x45D73B72l; // 71
    0x7FC46C34l; 0x7C8C59F2l; // 72
    0x7FCCAA10l; 0x15CAA326l; // 73
    0x7FD3D828l; 0x7BEA4849l; // 74
    0x7FDA1675l; 0x3608E7C2l; // 75
    0x7FDF819Al; 0x1D3DFF35l; // 76
    0x7FE43333l; 0x1952FF5Fl; // 77
    0x7FE84217l; 0x5506F15Al; // 78
    0x7FEBC29Al; 0x61880546l; // 79
    0x7FEEC6C7l; 0x4786A8A8l; // 80
    0x7FF15E99l; 0x0A1CB795l; // 81
    0x7FF3982El; 0x24C17DCCl; // 82
    0x7FF57FFAl; 0x11B43169l; // 83
    0x7FF720EFl; 0x69B7A428l; // 84
    0x7FF884ABl; 0x30B995E4l; // 85
    0x7FF9B396l; 0x651D9C1El; // 86
    0x7FFAB50Bl; 0x68EE9B1Al; // 87
    0x7FFB8F72l; 0x5D4208A6l; // 88
    0x7FFC485El; 0x08AD19C4l; // 89
    0x7FFCE4A3l; 0x61DC95CCl; // 90
    0x7FFD6873l; 0x573AAF25l; // 91
    0x7FFDD76Bl; 0x6C207ED1l; // 92
    0x7FFE34AAl; 0x43673438l; // 93
    0x7FFE82DEl; 0x2E535443l; // 94
    0x7FFEC454l; 0x55D51370l; // 95
    0x7FFEFB06l; 0x12FD6DC5l; // 96
    0x7FFF28A2l; 0x0A588B08l; // 97
    0x7FFF4E98l; 0x1CA2A14Fl; // 98
    0x7FFF6E21l; 0x3E0B4535l; // 99
    0x7FFF8847l; 0x43F95CC4l; // 100
    0x7FFF9DEBl; 0x38044301l; // 101
    0x7FFFAFCBl; 0x3DA0CF24l; // 102
    0x7FFFBE88l; 0x16D5DC7Cl; // 103
    0x7FFFCAA8l; 0x532DED04l; // 104
    0x7FFFD49El; 0x330C43AAl; // 105
    0x7FFFDCC8l; 0x488C8B03l; // 106
    0x7FFFE376l; 0x5E2582C2l; // 107
    0x7FFFE8EBl; 0x2A699905l; // 108
    0x7FFFED5Dl; 0x5773C7A7l; // 109
    0x7FFFF0FBl; 0x63D3499Fl; // 110
    0x7FFFF3EBl; 0x621D490Al; // 111
    0x7FFFF64Dl; 0x1BAFE266l; // 112
    0x7FFFF83Al; 0x1AA50219l; // 113
    0x7FFFF9C8l; 0x1E74DD87l; // 114
    0x7FFFFB08l; 0x7E5630D3l; // 115
    0x7FFFFC0Al; 0x7C050D38l; // 116
    0x7FFFFCDAl; 0x093EEF3Bl; // 117
    0x7FFFFD80l; 0x01F3172Bl; // 118
    0x7FFFFE04l; 0x5CDFCE2El; // 119
    0x7FFFFE6El; 0x54177CDFl; // 120
    0x7FFFFEC3l; 0x06B266A3l; // 121
    0x7FFFFF06l; 0x14C2B342l; // 122
    0x7FFFFF3Bl; 0x367771F9l; // 123
    0x7FFFFF65l; 0x4F37BDD3l; // 124
    0x7FFFFF86l; 0x7D6081B5l; // 125
    0x7FFFFFA1l; 0x2734F6F5l; // 126
    0x7FFFFFB6l; 0x057B565Cl; // 127
    0x7FFFFFC6l; 0x2C2BD768l; // 128
    0x7FFFFFD3l; 0x118798A8l; // 129
    0x7FFFFFDDl; 0x13DF050Cl; // 130
    0x7FFFFFE4l; 0x7E436700l; // 131
    0x7FFFFFEBl; 0x0C554F26l; // 132
    0x7FFFFFEFl; 0x6D58FEBAl; // 133
    0x7FFFFFF3l; 0x46B2EA4Dl; // 134
    0x7FFFFFF6l; 0x35E875C6l; // 135
    0x7FFFFFF8l; 0x523C11B9l; // 136
    0x7FFFFFFAl; 0x2DF7BE14l; // 137
    0x7FFFFFFBl; 0x577585A6l; // 138
    0x7FFFFFFCl; 0x59F2AC82l; // 139
    0x7FFFFFFDl; 0x3E37F0C9l; // 140
    0x7FFFFFFEl; 0x0B1F4CF2l; // 141
    0x7FFFFFFEl; 0x45FE12ACl; // 142
    0x7FFFFFFEl; 0x72F8E740l; // 143
    0x7FFFFFFFl; 0x154618FFl; // 144
    0x7FFFFFFFl; 0x2F61E68Cl; // 145
    0x7FFFFFFFl; 0x43379BB6l; // 146
    0x7FFFFFFFl; 0x5241D483l; // 147
    0x7FFFFFFFl; 0x5DA3C063l; // 148
    0x7FFFFFFFl; 0x663CDF59l; // 149
    0x7FFFFFFFl; 0x6CB865F1l; // 150
    0x7FFFFFFFl; 0x71993691l; // 151
    0x7FFFFFFFl; 0x75432D5Cl; // 152
    0x7FFFFFFFl; 0x780253E4l; // 153
    0x7FFFFFFFl; 0x7A10727Dl; // 154
    0x7FFFFFFFl; 0x7B995BC9l; // 155
    0x7FFFFFFFl; 0x7CBE3B28l; // 156
    0x7FFFFFFFl; 0x7D981EEFl; // 157
    0x7FFFFFFFl; 0x7E39EAD2l; // 158
    0x7FFFFFFFl; 0x7EB1D52Cl; // 159
    0x7FFFFFFFl; 0x7F0A8A07l; // 160
    0x7FFFFFFFl; 0x7F4C08CCl; // 161
    0x7FFFFFFFl; 0x7F7C4CC9l; // 162
    0x7FFFFFFFl; 0x7F9FCD06l; // 163
    0x7FFFFFFFl; 0x7FB9DD06l; // 164
    0x7FFFFFFFl; 0x7FCCF5DEl; // 165
    0x7FFFFFFFl; 0x7FDAED50l; // 166
    0x7FFFFFFFl; 0x7FE51F3El; // 167
    0x7FFFFFFFl; 0x7FEC8CC3l; // 168
    0x7FFFFFFFl; 0x7FF1F385l; // 169
    0x7FFFFFFFl; 0x7FF5DF23l; // 170
    0x7FFFFFFFl; 0x7FF8B62Fl; // 171
    0x7FFFFFFFl; 0x7FFAC3DFl; // 172
    0x7FFFFFFFl; 0x7FFC3F40l; // 173
    0x7FFFFFFFl; 0x7FFD5084l; // 174
    0x7FFFFFFFl; 0x7FFE14FBl; // 175
    0x7FFFFFFFl; 0x7FFEA1F4l; // 176
    0x7FFFFFFFl; 0x7FFF06ECl; // 177
    0x7FFFFFFFl; 0x7FFF4F19l; // 178
    0x7FFFFFFFl; 0x7FFF8298l; // 179
    0x7FFFFFFFl; 0x7FFFA744l; // 180
    0x7FFFFFFFl; 0x7FFFC155l; // 181
    0x7FFFFFFFl; 0x7FFFD3D3l; // 182
    0x7FFFFFFFl; 0x7FFFE0EBl; // 183
    0x7FFFFFFFl; 0x7FFFEA2Cl; // 184
    0x7FFFFFFFl; 0x7FFFF0B3l; // 185
    0x7FFFFFFFl; 0x7FFFF54Cl; // 186
    0x7FFFFFFFl; 0x7FFFF886l; // 187
    0x7FFFFFFFl; 0x7FFFFACAl; // 188
    0x7FFFFFFFl; 0x7FFFFC60l; // 189
    0x7FFFFFFFl; 0x7FFFFD7Cl; // 190
    0x7FFFFFFFl; 0x7FFFFE42l; // 191
    0x7FFFFFFFl; 0x7FFFFECBl; // 192
    0x7FFFFFFFl; 0x7FFFFF2Bl; // 193
    0x7FFFFFFFl; 0x7FFFFF6Dl; // 194
    0x7FFFFFFFl; 0x7FFFFF9Bl; // 195
    0x7FFFFFFFl; 0x7FFFFFBBl; // 196
    0x7FFFFFFFl; 0x7FFFFFD1l; // 197
    0x7FFFFFFFl; 0x7FFFFFE0l; // 198
    0x7FFFFFFFl; 0x7FFFFFEAl; // 199
    0x7FFFFFFFl; 0x7FFFFFF1l; // 200
    0x7FFFFFFFl; 0x7FFFFFF6l; // 201
    0x7FFFFFFFl; 0x7FFFFFF9l; // 202
    0x7FFFFFFFl; 0x7FFFFFFCl; // 203
    0x7FFFFFFFl; 0x7FFFFFFDl; // 204
    0x7FFFFFFFl; 0x7FFFFFFEl; // 205
    0x7FFFFFFFl; 0x7FFFFFFFl  // 206
]

unfold let params_cdt64_rows = size 209
unfold let params_cdt64_cols = size 1

unfold let params_cdt64_v: list I64.t = [
    0x0000000000000000L; // 0
    0x023A1B3F94933202L; // 1
    0x06AD3C4C19410B24L; // 2
    0x0B1D1E95803CBB73L; // 3
    0x0F879D85E7AB7F6FL; // 4
    0x13EA9C5C52732915L; // 5
    0x18440933FFD2011BL; // 6
    0x1C91DFF191E15D07L; // 7
    0x20D22D0F2017900DL; // 8
    0x25031040C1E626EFL; // 9
    0x2922BEEBA163019DL; // 10
    0x2D2F866A3C5122D3L; // 11
    0x3127CE192059EF64L; // 12
    0x350A1928231CB01AL; // 13
    0x38D5082CD4FCC414L; // 14
    0x3C875A73B33ADA6BL; // 15
    0x401FEF0E67CD47D3L; // 16
    0x439DC59E3077B59CL; // 17
    0x46FFFEDA4FC0A316L; // 18
    0x4A45DCD32E9CAA91L; // 19
    0x4D6EC2F3922E5C24L; // 20
    0x507A35C1FB354670L; // 21
    0x5367DA64EA5F1C63L; // 22
    0x563775ED5B93E26EL; // 23
    0x58E8EC6B50CB95F8L; // 24
    0x5B7C3FD0B999197DL; // 25
    0x5DF18EA7664D810EL; // 26
    0x6049129F03B5CD6DL; // 27
    0x62831EF856A48427L; // 28
    0x64A01ED314BA206FL; // 29
    0x66A09363CA89DAA3L; // 30
    0x688512173EF213F5L; // 31
    0x6A4E42A8B137E138L; // 32
    0x6BFCDD302C5B888AL; // 33
    0x6D91A82DF797EAB8L; // 34
    0x6F0D7697EBA6A51DL; // 35
    0x707125ED27F05CF1L; // 36
    0x71BD9C544C184D8DL; // 37
    0x72F3C6C7FB380322L; // 38
    0x74149755088E5CC6L; // 39
    0x7521036D434271D4L; // 40
    0x761A02516A02B0CEL; // 41
    0x77008B9461817A43L; // 42
    0x77D595B95BC6A0FEL; // 43
    0x789A14EE338BB727L; // 44
    0x794EF9E2D7C53213L; // 45
    0x79F530BE414FE24DL; // 46
    0x7A8DA03110886732L; // 47
    0x7B1928A59B3AA79EL; // 48
    0x7B98A38CE58D06AEL; // 49
    0x7C0CE2C7BAD3164AL; // 50
    0x7C76B02ADDE64EF2L; // 51
    0x7CD6CD1D13EE98F2L; // 52
    0x7D2DF24DA06E2473L; // 53
    0x7D7CCF81A5CD98B9L; // 54
    0x7DC40B76C24FB5D4L; // 55
    0x7E0443D92DE22661L; // 56
    0x7E3E0D4B91401720L; // 57
    0x7E71F37EC9C1DE8DL; // 58
    0x7EA07957CE6B9051L; // 59
    0x7ECA1921F1AF6404L; // 60
    0x7EEF44CBC73DA35BL; // 61
    0x7F10662D0574233DL; // 62
    0x7F2DDF53CDDCD427L; // 63
    0x7F480AD7DF028A76L; // 64
    0x7F5F3C324B0F66B2L; // 65
    0x7F73C018698C18A7L; // 66
    0x7F85DCD8D69F8939L; // 67
    0x7F95D2B96ED3DA10L; // 68
    0x7FA3DC55532D71BBL; // 69
    0x7FB02EFA1DDDC61EL; // 70
    0x7FBAFB038BAE76E4L; // 71
    0x7FC46C34F918B3E3L; // 72
    0x7FCCAA102B95464CL; // 73
    0x7FD3D828F7D49092L; // 74
    0x7FDA16756C11CF83L; // 75
    0x7FDF819A3A7BFE69L; // 76
    0x7FE4333332A5FEBDL; // 77
    0x7FE84217AA0DE2B3L; // 78
    0x7FEBC29AC3100A8BL; // 79
    0x7FEEC6C78F0D514EL; // 80
    0x7FF15E9914396F2AL; // 81
    0x7FF3982E4982FB97L; // 82
    0x7FF57FFA236862D1L; // 83
    0x7FF720EFD36F4850L; // 84
    0x7FF884AB61732BC7L; // 85
    0x7FF9B396CA3B383CL; // 86
    0x7FFAB50BD1DD3633L; // 87
    0x7FFB8F72BA84114BL; // 88
    0x7FFC485E115A3388L; // 89
    0x7FFCE4A3C3B92B98L; // 90
    0x7FFD6873AE755E4AL; // 91
    0x7FFDD76BD840FDA1L; // 92
    0x7FFE34AA86CE6870L; // 93
    0x7FFE82DE5CA6A885L; // 94
    0x7FFEC454ABAA26DFL; // 95
    0x7FFEFB0625FADB89L; // 96
    0x7FFF28A214B1160FL; // 97
    0x7FFF4E983945429DL; // 98
    0x7FFF6E217C168A6AL; // 99
    0x7FFF884787F2B986L; // 100
    0x7FFF9DEB70088602L; // 101
    0x7FFFAFCB7B419E48L; // 102
    0x7FFFBE882DABB8F8L; // 103
    0x7FFFCAA8A65BDA07L; // 104
    0x7FFFD49E66188754L; // 105
    0x7FFFDCC891191605L; // 106
    0x7FFFE376BC4B0583L; // 107
    0x7FFFE8EB54D33209L; // 108
    0x7FFFED5DAEE78F4EL; // 109
    0x7FFFF0FBC7A6933DL; // 110
    0x7FFFF3EBC43A9213L; // 111
    0x7FFFF64D375FC4CCL; // 112
    0x7FFFF83A354A0431L; // 113
    0x7FFFF9C83CE9BB0DL; // 114
    0x7FFFFB08FCAC61A6L; // 115
    0x7FFFFC0AF80A1A6FL; // 116
    0x7FFFFCDA127DDE76L; // 117
    0x7FFFFD8003E62E56L; // 118
    0x7FFFFE04B9BF9C5BL; // 119
    0x7FFFFE6EA82EF9BDL; // 120
    0x7FFFFEC30D64CD46L; // 121
    0x7FFFFF0629856684L; // 122
    0x7FFFFF3B6CEEE3F1L; // 123
    0x7FFFFF659E6F7BA6L; // 124
    0x7FFFFF86FAC1036AL; // 125
    0x7FFFFFA14E69EDE9L; // 126
    0x7FFFFFB60AF6ACB7L; // 127
    0x7FFFFFC65857AECFL; // 128
    0x7FFFFFD3230F314FL; // 129
    0x7FFFFFDD27BE0A17L; // 130
    0x7FFFFFE4FC86CDFFL; // 131
    0x7FFFFFEB18AA9E4CL; // 132
    0x7FFFFFEFDAB1FD73L; // 133
    0x7FFFFFF38D65D499L; // 134
    0x7FFFFFF66BD0EB8CL; // 135
    0x7FFFFFF8A4782371L; // 136
    0x7FFFFFFA5BEF7C27L; // 137
    0x7FFFFFFBAEEB0B4CL; // 138
    0x7FFFFFFCB3E55903L; // 139
    0x7FFFFFFD7C6FE192L; // 140
    0x7FFFFFFE163E99E3L; // 141
    0x7FFFFFFE8BFC2558L; // 142
    0x7FFFFFFEE5F1CE80L; // 143
    0x7FFFFFFF2A8C31FDL; // 144
    0x7FFFFFFF5EC3CD18L; // 145
    0x7FFFFFFF866F376BL; // 146
    0x7FFFFFFFA483A906L; // 147
    0x7FFFFFFFBB4780C4L; // 148
    0x7FFFFFFFCC79BEB2L; // 149
    0x7FFFFFFFD970CBE1L; // 150
    0x7FFFFFFFE3326D21L; // 151
    0x7FFFFFFFEA865AB8L; // 152
    0x7FFFFFFFF004A7C8L; // 153
    0x7FFFFFFFF420E4F9L; // 154
    0x7FFFFFFFF732B791L; // 155
    0x7FFFFFFFF97C764FL; // 156
    0x7FFFFFFFFB303DDDL; // 157
    0x7FFFFFFFFC73D5A3L; // 158
    0x7FFFFFFFFD63AA57L; // 159
    0x7FFFFFFFFE15140DL; // 160
    0x7FFFFFFFFE981196L; // 161
    0x7FFFFFFFFEF89992L; // 162
    0x7FFFFFFFFF3F9A0CL; // 163
    0x7FFFFFFFFF73BA0BL; // 164
    0x7FFFFFFFFF99EBBBL; // 165
    0x7FFFFFFFFFB5DAA0L; // 166
    0x7FFFFFFFFFCA3E7BL; // 167
    0x7FFFFFFFFFD91985L; // 168
    0x7FFFFFFFFFE3E70AL; // 169
    0x7FFFFFFFFFEBBE45L; // 170
    0x7FFFFFFFFFF16C5CL; // 171
    0x7FFFFFFFFFF587BEL; // 172
    0x7FFFFFFFFFF87E7FL; // 173
    0x7FFFFFFFFFFAA108L; // 174
    0x7FFFFFFFFFFC29F5L; // 175
    0x7FFFFFFFFFFD43E8L; // 176
    0x7FFFFFFFFFFE0DD7L; // 177
    0x7FFFFFFFFFFE9E31L; // 178
    0x7FFFFFFFFFFF0530L; // 179
    0x7FFFFFFFFFFF4E88L; // 180
    0x7FFFFFFFFFFF82AAL; // 181
    0x7FFFFFFFFFFFA7A6L; // 182
    0x7FFFFFFFFFFFC1D6L; // 183
    0x7FFFFFFFFFFFD458L; // 184
    0x7FFFFFFFFFFFE166L; // 185
    0x7FFFFFFFFFFFEA97L; // 186
    0x7FFFFFFFFFFFF10CL; // 187
    0x7FFFFFFFFFFFF594L; // 188
    0x7FFFFFFFFFFFF8C0L; // 189
    0x7FFFFFFFFFFFFAF7L; // 190
    0x7FFFFFFFFFFFFC83L; // 191
    0x7FFFFFFFFFFFFD96L; // 192
    0x7FFFFFFFFFFFFE56L; // 193
    0x7FFFFFFFFFFFFEDAL; // 194
    0x7FFFFFFFFFFFFF36L; // 195
    0x7FFFFFFFFFFFFF75L; // 196
    0x7FFFFFFFFFFFFFA1L; // 197
    0x7FFFFFFFFFFFFFBFL; // 198
    0x7FFFFFFFFFFFFFD4L; // 199
    0x7FFFFFFFFFFFFFE2L; // 200
    0x7FFFFFFFFFFFFFECL; // 201
    0x7FFFFFFFFFFFFFF2L; // 202
    0x7FFFFFFFFFFFFFF7L; // 203
    0x7FFFFFFFFFFFFFFAL; // 204
    0x7FFFFFFFFFFFFFFCL; // 205
    0x7FFFFFFFFFFFFFFDL; // 206
    0x7FFFFFFFFFFFFFFEL; // 207
    0x7FFFFFFFFFFFFFFFL  // 208
]
