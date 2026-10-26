functor SMLLexFun (structure Tokens : SML_TOKENS)
  = struct

    structure yyInput : sig

        type stream
	val mkStream : (int -> string) -> stream
	val fromStream : TextIO.StreamIO.instream -> stream
	val getc : stream -> (Char.char * stream) option
	val getpos : stream -> int
	val getlineNo : stream -> int
	val subtract : stream * stream -> string
	val eof : stream -> bool
	val lastWasNL : stream -> bool

      end = struct

        structure TIO = TextIO
        structure TSIO = TIO.StreamIO
	structure TPIO = TextPrimIO

        datatype stream = Stream of {
            strm : TSIO.instream,
	    id : int,  (* track which streams originated
			* from the same stream *)
	    pos : int,
	    lineNo : int,
	    lastWasNL : bool
          }

	local
	  val next = ref 0
	in
	fun nextId() = !next before (next := !next + 1)
	end

	val initPos = 2 (* ml-lex bug compatibility *)

	fun mkStream inputN = let
              val strm = TSIO.mkInstream
			   (TPIO.RD {
			        name = "lexgen",
				chunkSize = 4096,
				readVec = SOME inputN,
				readArr = NONE,
				readVecNB = NONE,
				readArrNB = NONE,
				block = NONE,
				canInput = NONE,
				avail = (fn () => NONE),
				getPos = NONE,
				setPos = NONE,
				endPos = NONE,
				verifyPos = NONE,
				close = (fn () => ()),
				ioDesc = NONE
			      }, "")
	      in
		Stream {strm = strm, id = nextId(), pos = initPos, lineNo = 1,
			lastWasNL = true}
	      end

	fun fromStream strm = Stream {
		strm = strm, id = nextId(), pos = initPos, lineNo = 1, lastWasNL = true
	      }

	fun getc (Stream {strm, pos, id, lineNo, ...}) = (case TSIO.input1 strm
              of NONE => NONE
	       | SOME (c, strm') =>
		   SOME (c, Stream {
			        strm = strm',
				pos = pos+1,
				id = id,
				lineNo = lineNo +
					 (if c = #"\n" then 1 else 0),
				lastWasNL = (c = #"\n")
			      })
	     (* end case*))

	fun getpos (Stream {pos, ...}) = pos

	fun getlineNo (Stream {lineNo, ...}) = lineNo

	fun subtract (new, old) = let
	      val Stream {strm = strm, pos = oldPos, id = oldId, ...} = old
	      val Stream {pos = newPos, id = newId, ...} = new
              val (diff, _) = if newId = oldId andalso newPos >= oldPos
			      then TSIO.inputN (strm, newPos - oldPos)
			      else raise Fail
				"BUG: yyInput: attempted to subtract incompatible streams"
	      in
		diff
	      end

	fun eof s = not (isSome (getc s))

	fun lastWasNL (Stream {lastWasNL, ...}) = lastWasNL

      end

    datatype yystart_state = LCOM | AQ | LL | LLC | F | A | L | Q | S | INITIAL | ALC | LLCQ

    structure UserDeclarations =
      struct

(* sml.lex
 *
 * COPYRIGHT (c) 2015 The Fellowship of SML/NJ (https://smlnj.org)
 * All rights reserved.
 *
 * This version of the lexer supports the following SuccessorML lexical extensions:
 *
 *	- "_" as a separator in numeric literals; e.g., '123_456', '0xff_ff_ff_f3',
 *	  '123_456.1', ...
 *
 *	- end-of-line comments
 *
 *	- binary literals; e.g., '0b0101_1110'
 *)

(* The states that we use are as listed below.
 *
 * LCOM	-- SuccessorML end-of-line comment
 * A	-- bracketed comments
 * ALC  -- end-of-line comment inside bracketed comment
 * S	-- strings
 * F	-- formatting characters in a string
 * Q	-- quotation (extension)
 * AQ	-- antiquotation (extension)
 * L	-- #line comment
 * LL	-- more #line comment processing
 * LLC	-- rest of #line comment processing
 * LLCQ	-- quoted string in #line comment
 *
 * Note that this comment cannot appear where the states are defined, because
 * ml-lex's parser is broken.
 *)

open ErrorMsg;
open UserDeclarations;

structure TokTable = TokenTable(Tokens);

type svalue = Tokens.svalue

type lexresult = (svalue, pos) Tokens.token

type ('a,'b) token = ('a, 'b) Tokens.token

fun eof arg = let val pos = UserDeclarations.eof arg in Tokens.EOF(pos,pos) end

local
  fun cvt radix (s, i) = let
      (* strip any "_" separators *)
	val digits = Substring.foldr
	      (fn (#"_", ds) => ds | (d, ds) => d::ds)
		[]
		  (Substring.extract(s, i, NONE))
      (* convert to a IntInf.int value *)
	val SOME(n, _) = IntInf.scan radix List.getItem digits
	in
	  n
	end
in
val btoi = cvt StringCvt.BIN
val atoi = cvt StringCvt.DEC
val xtoi = cvt StringCvt.HEX
end (* local *)

(* strip "_" out of real literal *)
fun stripReal s = String.translate (fn #"_" => "" | c => str c) s

fun mysynch (srcmap, initpos, pos, args) = let
    fun cvt digits = (case IntInf.fromString digits
           of SOME n => if (n > SourceMap.limit)
                then raise Overflow
                else IntInf.toInt n
            | _ => 0 (* should be impossible *)
          (* end case *))
    val resynch = SourceMap.resynch srcmap
    in
      case args
       of [col, line] => resynch (initpos, pos, cvt line, cvt col, NONE)
        | [file, col, line] => resynch (initpos, pos, cvt line, cvt col, SOME file)
        | _ => impossible "ill-formed args in (*#line...*)"
      (* end case *)
    end

fun has_quote s = CharVector.exists (fn #"`" => true | _ => false) s

fun inc (ri as ref i) = (ri := i+1)
fun dec (ri as ref i) = (ri := i-1)



      end

    datatype yymatch
      = yyNO_MATCH
      | yyMATCH of yyInput.stream * action * yymatch
    withtype action = yyInput.stream * yymatch -> UserDeclarations.lexresult

    local

    val yytable =
#[([(#"\^@",#"\t",12),
(#"\v",#"\f",12),
(#"\^N",#"\255",12),
(#"\n",#"\n",13),
(#"\r",#"\r",14)], []), ([(#"\^@",#"\b",15),
(#"\v",#"\v",15),
(#"\^N",#"\^_",15),
(#"\"",#"\"",15),
(#"'",#"'",15),
(#")",#")",15),
(#",",#",",15),
(#".",#".",15),
(#"0",#"9",15),
(#";",#";",15),
(#"[",#"[",15),
(#"]",#"]",15),
(#"_",#"`",15),
(#"{",#"{",15),
(#"}",#"}",15),
(#"\127",#"\255",15),
(#"\t",#"\t",16),
(#"\f",#"\f",16),
(#" ",#" ",16),
(#"\n",#"\n",17),
(#"\r",#"\r",18),
(#"!",#"!",19),
(#"#",#"&",19),
(#"*",#"+",19),
(#"-",#"-",19),
(#"/",#"/",19),
(#":",#":",19),
(#"<",#"@",19),
(#"\\",#"\\",19),
(#"^",#"^",19),
(#"|",#"|",19),
(#"~",#"~",19),
(#"(",#"(",20),
(#"A",#"Z",21),
(#"a",#"z",21)], [89]), ([(#".",#".",25),
(#"0",#"0",26),
(#"1",#"9",27)], [43]), ([(#"\^@",#"\b",28),
(#"\v",#"\v",28),
(#"\^N",#"\^_",28),
(#"!",#"!",28),
(#"#",#")",28),
(#"+",#"\255",28),
(#"\t",#"\t",29),
(#"\f",#"\f",29),
(#" ",#" ",29),
(#"\n",#"\n",30),
(#"\r",#"\r",31),
(#"\"",#"\"",32),
(#"*",#"*",33)], []), ([(#"\^@",#"\b",37),
(#"\v",#"\v",37),
(#"\^N",#"\^_",37),
(#"!",#"[",37),
(#"]",#"\255",37),
(#"\t",#"\t",38),
(#"\f",#"\f",38),
(#" ",#" ",38),
(#"\n",#"\n",39),
(#"\r",#"\r",40),
(#"\\",#"\\",41)], [79]), ([(#"\^@",#"\t",43),
(#"\v",#"\f",43),
(#"\^N",#"'",43),
(#")",#")",43),
(#"+",#"\255",43),
(#"\n",#"\n",44),
(#"\r",#"\r",45),
(#"(",#"(",46),
(#"*",#"*",47)], []), ([(#"\^@",#"\t",28),
(#"\v",#"\f",28),
(#"\^N",#")",28),
(#"+",#"/",28),
(#":",#"\255",28),
(#"\n",#"\n",30),
(#"\r",#"\r",31),
(#"*",#"*",51),
(#"0",#"9",52)], []), ([(#"\^@",#"\t",55),
(#"\v",#"\f",55),
(#"\^N",#"]",55),
(#"_",#"_",55),
(#"a",#"\255",55),
(#"\n",#"\n",56),
(#"\r",#"\r",57),
(#"^",#"^",58),
(#"`",#"`",59)], []), ([(#"\^@",#"\t",62),
(#"\v",#"\f",62),
(#"\^N",#"\^_",62),
(#"\n",#"\n",63),
(#"\r",#"\r",64),
(#" ",#" ",65),
(#"\127",#"\255",65),
(#"!",#"!",66),
(#"#",#"[",66),
(#"]",#"~",66),
(#"\"",#"\"",67),
(#"\\",#"\\",68)], []), ([(#"\^@",#"\b",96),
(#"\v",#"\v",96),
(#"\^N",#"\^_",96),
(#"\127",#"\127",96),
(#"\t",#"\t",97),
(#"\f",#"\f",97),
(#" ",#" ",97),
(#"\n",#"\n",98),
(#"\r",#"\r",99),
(#"!",#"!",100),
(#"$",#"&",100),
(#"*",#"+",100),
(#"-",#"-",100),
(#"/",#"/",100),
(#":",#":",100),
(#"<",#"@",100),
(#"\\",#"\\",100),
(#"^",#"^",100),
(#"|",#"|",100),
(#"\"",#"\"",101),
(#"#",#"#",102),
(#"'",#"'",103),
(#"(",#"(",104),
(#")",#")",105),
(#",",#",",106),
(#".",#".",107),
(#"0",#"0",108),
(#"1",#"9",109),
(#";",#";",110),
(#"A",#"Z",111),
(#"a",#"z",111),
(#"[",#"[",112),
(#"]",#"]",113),
(#"_",#"_",114),
(#"`",#"`",115),
(#"{",#"{",116),
(#"}",#"}",117),
(#"~",#"~",118),
(#"\128",#"\255",119)], [0]), ([(#"\^@",#"\t",179),
(#"\v",#"\f",179),
(#"\^N",#"\255",179),
(#"\n",#"\n",180),
(#"\r",#"\r",181)], []), ([(#"\^@",#"\t",182),
(#"\v",#"!",182),
(#"#",#")",182),
(#"+",#"\255",182),
(#"\n",#"\n",183),
(#"\"",#"\"",184),
(#"*",#"*",185)], [46]), ([], [36]), ([], [35]), ([(#"\n",#"\n",13)], [35, 36]), ([], [93]), ([(#"\t",#"\t",24),
(#"\f",#"\f",24),
(#" ",#" ",24)], [89, 93]), ([], [88]), ([(#"\n",#"\n",17)], [88, 93]), ([(#"!",#"!",23),
(#"#",#"&",23),
(#"*",#"+",23),
(#"-",#"-",23),
(#"/",#"/",23),
(#":",#":",23),
(#"<",#"@",23),
(#"\\",#"\\",23),
(#"^",#"^",23),
(#"|",#"|",23),
(#"~",#"~",23)], [91, 93]), ([], [92, 93]), ([(#"'",#"'",22),
(#"0",#"9",22),
(#"A",#"Z",22),
(#"_",#"_",22),
(#"a",#"z",22)], [90, 93]), ([(#"'",#"'",22),
(#"0",#"9",22),
(#"A",#"Z",22),
(#"_",#"_",22),
(#"a",#"z",22)], [90]), ([(#"!",#"!",23),
(#"#",#"&",23),
(#"*",#"+",23),
(#"-",#"-",23),
(#"/",#"/",23),
(#":",#":",23),
(#"<",#"@",23),
(#"\\",#"\\",23),
(#"^",#"^",23),
(#"|",#"|",23),
(#"~",#"~",23)], [91]), ([(#"\t",#"\t",24),
(#"\f",#"\f",24),
(#" ",#" ",24)], [89]), ([], [41]), ([(#"0",#"0",26),
(#"1",#"9",27)], [42, 43]), ([(#"0",#"9",27)], [42]), ([], [49]), ([(#"\t",#"\t",35),
(#"\f",#"\f",35),
(#" ",#" ",35),
(#"\"",#"\"",36)], [49]), ([], [50]), ([(#"\n",#"\n",30)], [49, 50]), ([], [45, 49]), ([(#")",#")",34)], [49]), ([], [44, 48]), ([(#"\t",#"\t",35),
(#"\f",#"\f",35),
(#" ",#" ",35),
(#"\"",#"\"",36)], []), ([], [45]), ([], [81]), ([(#"\t",#"\t",42),
(#"\f",#"\f",42),
(#" ",#" ",42)], [79, 81]), ([], [78]), ([(#"\n",#"\n",39)], [78, 81]), ([], [80, 81]), ([(#"\t",#"\t",42),
(#"\f",#"\f",42),
(#" ",#" ",42)], [79]), ([], [57]), ([], [55]), ([(#"\n",#"\n",44)], [55, 57]), ([(#"*",#"*",49)], [57]), ([(#")",#")",48)], [57]), ([], [56]), ([(#")",#")",50)], [54]), ([], [51]), ([(#")",#")",54)], [49]), ([(#"0",#"9",53)], [40, 49]), ([(#"0",#"9",53)], [40]), ([], [48]), ([], [87]), ([], [86]), ([(#"\n",#"\n",56)], [86, 87]), ([(#"^",#"^",60),
(#"`",#"`",61)], [84, 87]), ([], [85, 87]), ([], [83]), ([], [82]), ([], [76, 77]), ([], [59, 76]), ([(#"\n",#"\n",95)], [59, 76, 77]), ([], [77]), ([(#"!",#"!",94),
(#"#",#"[",94),
(#"]",#"~",94)], [77]), ([], [58, 77]), ([(#"\^@",#"\b",69),
(#"\v",#"\v",69),
(#"\^N",#"\^_",69),
(#"!",#"!",69),
(#"#",#"/",69),
(#":",#"[",69),
(#"]",#"]",69),
(#"_",#"`",69),
(#"c",#"e",69),
(#"g",#"m",69),
(#"o",#"q",69),
(#"s",#"s",69),
(#"w",#"\127",69),
(#"\t",#"\t",70),
(#"\n",#"\n",71),
(#"\f",#"\f",72),
(#" ",#" ",72),
(#"\r",#"\r",73),
(#"\"",#"\"",74),
(#"0",#"9",75),
(#"\\",#"\\",76),
(#"^",#"^",77),
(#"a",#"a",78),
(#"b",#"b",79),
(#"f",#"f",80),
(#"n",#"n",81),
(#"r",#"r",82),
(#"t",#"t",83),
(#"u",#"u",84),
(#"v",#"v",85)], [61, 77]), ([], [75]), ([(#"\t",#"\t",70),
(#"\f",#"\f",70),
(#" ",#" ",70)], [61]), ([], [60]), ([(#"\t",#"\t",70),
(#"\f",#"\f",70),
(#" ",#" ",70)], [61, 75]), ([(#"\n",#"\n",71)], [60]), ([], [70]), ([(#"0",#"9",92)], []), ([], [69]), ([(#"\^@",#"\t",90),
(#"\v",#"?",90),
(#"`",#"\255",90),
(#"@",#"_",91)], []), ([], [62]), ([], [63]), ([], [64]), ([], [65]), ([], [66]), ([], [67]), ([(#"0",#"9",86),
(#"A",#"F",86),
(#"a",#"f",86)], [75]), ([], [68]), ([(#"0",#"9",87),
(#"A",#"F",87),
(#"a",#"f",87)], []), ([(#"0",#"9",88),
(#"A",#"F",88),
(#"a",#"f",88)], []), ([(#"0",#"9",89),
(#"A",#"F",89),
(#"a",#"f",89)], []), ([], [73]), ([], [72]), ([], [71, 72]), ([(#"0",#"9",93)], []), ([], [74]), ([(#"!",#"!",94),
(#"#",#"[",94),
(#"]",#"~",94)], [77]), ([], [59]), ([], [39]), ([(#"\t",#"\t",178),
(#"\f",#"\f",178),
(#" ",#" ",178)], [0, 39]), ([], [1]), ([(#"\n",#"\n",98)], [1, 39]), ([(#"!",#"!",120),
(#"#",#"&",120),
(#"*",#"+",120),
(#"-",#"-",120),
(#"/",#"/",120),
(#":",#":",120),
(#"<",#"@",120),
(#"\\",#"\\",120),
(#"^",#"^",120),
(#"|",#"|",120),
(#"~",#"~",120),
(#"`",#"`",123)], [17, 18, 39]), ([], [31, 39]), ([(#"!",#"!",120),
(#"#",#"&",120),
(#"*",#"+",120),
(#"-",#"-",120),
(#"/",#"/",120),
(#":",#":",120),
(#"<",#"@",120),
(#"\\",#"\\",120),
(#"^",#"^",120),
(#"|",#"|",120),
(#"~",#"~",120),
(#"\"",#"\"",176),
(#"[",#"[",177),
(#"`",#"`",123)], [17, 18, 39]), ([(#"'",#"'",175),
(#"0",#"9",175),
(#"A",#"Z",175),
(#"_",#"_",175),
(#"a",#"z",175)], [15, 39]), ([(#"*",#"*",167)], [11, 39]), ([], [12, 39]), ([], [4, 39]), ([(#".",#".",165)], [13, 39]), ([(#".",#".",124),
(#"0",#"9",149),
(#"E",#"E",125),
(#"e",#"e",125),
(#"_",#"_",148),
(#"b",#"b",150),
(#"w",#"w",151),
(#"x",#"x",152)], [29, 39]), ([(#".",#".",124),
(#"0",#"9",147),
(#"E",#"E",125),
(#"e",#"e",125),
(#"_",#"_",148)], [21, 29, 39]), ([], [10, 39]), ([(#"'",#"'",146),
(#"0",#"9",146),
(#"A",#"Z",146),
(#"_",#"_",146),
(#"a",#"z",146)], [16, 39]), ([], [7, 39]), ([], [9, 39]), ([(#"o",#"o",138)], [3, 39]), ([(#"!",#"!",123),
(#"#",#"&",123),
(#"*",#"+",123),
(#"-",#"-",123),
(#"/",#"/",123),
(#":",#":",123),
(#"<",#"@",123),
(#"\\",#"\\",123),
(#"^",#"^",123),
(#"`",#"`",123),
(#"|",#"|",123),
(#"~",#"~",123)], [17, 19, 39]), ([], [5, 39]), ([], [6, 39]), ([(#"!",#"!",120),
(#"#",#"&",120),
(#"*",#"+",120),
(#"-",#"-",120),
(#"/",#"/",120),
(#":",#":",120),
(#"<",#"@",120),
(#"\\",#"\\",120),
(#"^",#"^",120),
(#"|",#"|",120),
(#"~",#"~",120),
(#"0",#"0",121),
(#"1",#"9",122),
(#"`",#"`",123)], [17, 18, 39]), ([], [38, 39]), ([(#"!",#"!",120),
(#"#",#"&",120),
(#"*",#"+",120),
(#"-",#"-",120),
(#"/",#"/",120),
(#":",#":",120),
(#"<",#"@",120),
(#"\\",#"\\",120),
(#"^",#"^",120),
(#"|",#"|",120),
(#"~",#"~",120),
(#"`",#"`",123)], [17, 18]), ([(#".",#".",124),
(#"0",#"9",122),
(#"E",#"E",125),
(#"e",#"e",125),
(#"_",#"_",126),
(#"b",#"b",132),
(#"x",#"x",133)], [30]), ([(#".",#".",124),
(#"0",#"9",122),
(#"E",#"E",125),
(#"e",#"e",125),
(#"_",#"_",126)], [30]), ([(#"!",#"!",123),
(#"#",#"&",123),
(#"*",#"+",123),
(#"-",#"-",123),
(#"/",#"/",123),
(#":",#":",123),
(#"<",#"@",123),
(#"\\",#"\\",123),
(#"^",#"^",123),
(#"`",#"`",123),
(#"|",#"|",123),
(#"~",#"~",123)], [17]), ([(#"0",#"9",130)], []), ([(#"0",#"9",127),
(#"~",#"~",128)], []), ([(#"0",#"9",122),
(#"_",#"_",126)], []), ([(#"0",#"9",127),
(#"_",#"_",129)], [20]), ([(#"0",#"9",127)], []), ([(#"0",#"9",127),
(#"_",#"_",129)], []), ([(#"0",#"9",130),
(#"E",#"E",125),
(#"e",#"e",125),
(#"_",#"_",131)], [20]), ([(#"0",#"9",130),
(#"_",#"_",131)], []), ([(#"0",#"1",136)], []), ([(#"0",#"9",134),
(#"A",#"F",134),
(#"a",#"f",134)], []), ([(#"0",#"9",134),
(#"A",#"F",134),
(#"a",#"f",134),
(#"_",#"_",135)], [25]), ([(#"0",#"9",134),
(#"A",#"F",134),
(#"a",#"f",134),
(#"_",#"_",135)], []), ([(#"0",#"1",136),
(#"_",#"_",137)], [23]), ([(#"0",#"1",136),
(#"_",#"_",137)], []), ([(#"v",#"v",139)], []), ([(#"e",#"e",140)], []), ([(#"r",#"r",141)], []), ([(#"l",#"l",142)], []), ([(#"o",#"o",143)], []), ([(#"a",#"a",144)], []), ([(#"d",#"d",145)], []), ([], [2]), ([(#"'",#"'",146),
(#"0",#"9",146),
(#"A",#"Z",146),
(#"_",#"_",146),
(#"a",#"z",146)], [16]), ([(#".",#".",124),
(#"0",#"9",147),
(#"E",#"E",125),
(#"e",#"e",125),
(#"_",#"_",148)], [21, 29]), ([(#"0",#"9",149),
(#"_",#"_",148)], []), ([(#".",#".",124),
(#"0",#"9",149),
(#"E",#"E",125),
(#"e",#"e",125),
(#"_",#"_",148)], [29]), ([(#"0",#"1",163)], []), ([(#"0",#"9",155),
(#"b",#"b",156),
(#"x",#"x",157)], []), ([(#"0",#"9",153),
(#"A",#"F",153),
(#"a",#"f",153)], []), ([(#"0",#"9",153),
(#"A",#"F",153),
(#"a",#"f",153),
(#"_",#"_",154)], [24]), ([(#"0",#"9",153),
(#"A",#"F",153),
(#"a",#"f",153),
(#"_",#"_",154)], []), ([(#"0",#"9",155),
(#"_",#"_",162)], [26]), ([(#"0",#"1",160)], []), ([(#"0",#"9",158),
(#"A",#"F",158),
(#"a",#"f",158)], []), ([(#"0",#"9",158),
(#"A",#"F",158),
(#"a",#"f",158),
(#"_",#"_",159)], [28]), ([(#"0",#"9",158),
(#"A",#"F",158),
(#"a",#"f",158),
(#"_",#"_",159)], []), ([(#"0",#"1",160),
(#"_",#"_",161)], [27]), ([(#"0",#"1",160),
(#"_",#"_",161)], []), ([(#"0",#"9",155),
(#"_",#"_",162)], []), ([(#"0",#"1",163),
(#"_",#"_",164)], [22]), ([(#"0",#"1",163),
(#"_",#"_",164)], []), ([(#".",#".",166)], []), ([], [14]), ([(#"#",#"#",168),
(#")",#")",169)], [37]), ([(#"l",#"l",170)], []), ([], [34]), ([(#"i",#"i",171)], []), ([(#"n",#"n",172)], []), ([(#"e",#"e",173)], []), ([(#"\t",#"\t",174),
(#"\f",#"\f",174),
(#" ",#" ",174)], []), ([(#"\t",#"\t",174),
(#"\f",#"\f",174),
(#" ",#" ",174)], [33]), ([(#"'",#"'",175),
(#"0",#"9",175),
(#"A",#"Z",175),
(#"_",#"_",175),
(#"a",#"z",175)], [15]), ([], [32]), ([], [8]), ([(#"\t",#"\t",178),
(#"\f",#"\f",178),
(#" ",#" ",178)], [0]), ([], [53]), ([], [52]), ([(#"\n",#"\n",180)], [52, 53]), ([(#"\^@",#"!",183),
(#"#",#"\255",183)], [46, 49]), ([(#"\^@",#"!",183),
(#"#",#"\255",183)], [46]), ([(#"*",#"*",187)], [49]), ([(#"\^@",#"!",183),
(#"#",#"(",183),
(#"*",#"\255",183),
(#")",#")",186)], [46, 49]), ([(#"\^@",#"!",183),
(#"#",#"\255",183)], [46, 48]), ([(#")",#")",188)], []), ([], [47])]

    fun mk yyins = let
        (* current start state *)
        val yyss = ref INITIAL
	fun YYBEGIN ss = (yyss := ss)
	(* current input stream *)
        val yystrm = ref yyins
	(* get one char of input *)
	val yygetc = yyInput.getc
	(* create yytext *)
	fun yymktext(strm) = yyInput.subtract (strm, !yystrm)
        open UserDeclarations
        fun lex (yyarg as ({
  comLevel,
  sourceMap,
  err,
  charlist,
  stringstart,
  stringtype,
  brack_stack})) () = let
            fun continue() = let
                val yylastwasn = yyInput.lastWasNL (!yystrm)
                fun yystuck (yyNO_MATCH) = raise Fail "stuck state"
                  | yystuck (yyMATCH (strm, action, old)) =
                      action (strm, old)
                val yypos = yyInput.getpos (!yystrm)
                val yygetlineNo = yyInput.getlineNo
                fun yyactsToMatches (strm, [],	  oldMatches) = oldMatches
                  | yyactsToMatches (strm, act::acts, oldMatches) =
                      yyMATCH (strm, act, yyactsToMatches (strm, acts, oldMatches))
                fun yygo actTable =
                    (fn (~1, _, oldMatches) => yystuck oldMatches
                      | (curState, strm, oldMatches) => let
                          val (transitions, finals') = Vector.sub (yytable, curState)
                          val finals = List.map (fn i => Vector.sub (actTable, i)) finals'
                          fun tryfinal() =
                                yystuck (yyactsToMatches (strm, finals, oldMatches))
                          fun find (c, []) = NONE
                            | find (c, (c1, c2, s)::ts) =
                                if c1 <= c andalso c <= c2 then SOME s
                                else find (c, ts)
                          in case yygetc strm
                              of SOME(c, strm') =>
                                   (case find (c, transitions)
                                     of NONE => tryfinal()
                                      | SOME n =>
                                          yygo actTable
                                            (n, strm',
                                             yyactsToMatches (strm, finals, oldMatches)))
                               | NONE => tryfinal()
                          end)
                in
                  let
fun yyAction0 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction1 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; continue()))
fun yyAction2 (strm, lastMatch : yymatch) = let
      val oldStrm = !(yystrm)
      fun REJECT () = (yystrm := oldStrm; yystuck(lastMatch))
      in
        yystrm := strm;
        (if !ParserControl.overloadKW then
                             Tokens.OVERLOAD(yypos,yypos+1)
                         else REJECT())
      end
fun yyAction3 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.WILD(yypos,yypos+1)))
fun yyAction4 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.COMMA(yypos,yypos+1)))
fun yyAction5 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.LBRACE(yypos,yypos+1)))
fun yyAction6 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.RBRACE(yypos,yypos+1)))
fun yyAction7 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.LBRACKET(yypos,yypos+1)))
fun yyAction8 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.VECTORSTART(yypos,yypos+1)))
fun yyAction9 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.RBRACKET(yypos,yypos+1)))
fun yyAction10 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.SEMICOLON(yypos,yypos+1)))
fun yyAction11 (strm, lastMatch : yymatch) = (yystrm := strm;
      (if (null(!brack_stack))
                    then ()
                    else inc (hd (!brack_stack));
                    Tokens.LPAREN(yypos,yypos+1)))
fun yyAction12 (strm, lastMatch : yymatch) = (yystrm := strm;
      (if (null(!brack_stack))
                    then ()
                    else if (!(hd (!brack_stack)) = 1)
                         then ( brack_stack := tl (!brack_stack);
                                charlist := [];
                                YYBEGIN Q)
                         else dec (hd (!brack_stack));
                    Tokens.RPAREN(yypos,yypos+1)))
fun yyAction13 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.DOT(yypos,yypos+1)))
fun yyAction14 (strm, lastMatch : yymatch) = (yystrm := strm;
      (Tokens.DOTDOTDOT(yypos,yypos+3)))
fun yyAction15 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (TokTable.makeTyvar(yytext,yypos))
      end
fun yyAction16 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (TokTable.checkId(yytext, yypos))
      end
fun yyAction17 (strm, lastMatch : yymatch) = let
      val oldStrm = !(yystrm)
      fun REJECT () = (yystrm := oldStrm; yystuck(lastMatch))
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (if !ParserControl.quotation
                            then if (has_quote yytext)
                                 then REJECT()
                                 else TokTable.checkSymId(yytext,yypos)
                            else TokTable.checkSymId(yytext,yypos))
      end
fun yyAction18 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (TokTable.checkSymId(yytext,yypos))
      end
fun yyAction19 (strm, lastMatch : yymatch) = (yystrm := strm;
      (if !ParserControl.quotation
                            then (YYBEGIN Q;
                                  charlist := [];
                                  stringstart := yypos;
                                  Tokens.BEGINQ(yypos,yypos+1))
                            else (err(yypos, yypos+1)
                                     COMPLAIN "quotation implementation error"
				     nullErrorBody;
                                  Tokens.BEGINQ(yypos,yypos+1))))
fun yyAction20 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.REAL((yytext, RealLit.fromString yytext), yypos, yypos+size yytext))
      end
fun yyAction21 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.INT((yytext, atoi(yytext, 0)), yypos, yypos+size yytext))
      end
fun yyAction22 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.INT0((yytext, btoi(yytext, 2)), yypos, yypos+size yytext))
      end
fun yyAction23 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.INT0((yytext, IntInf.~(btoi(yytext, 3))), yypos, yypos+size yytext))
      end
fun yyAction24 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.INT0((yytext, xtoi(yytext, 2)), yypos, yypos+size yytext))
      end
fun yyAction25 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.INT0((yytext, IntInf.~(xtoi(yytext, 3))), yypos, yypos+size yytext))
      end
fun yyAction26 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.WORD((yytext, atoi(yytext, 2)), yypos, yypos+size yytext))
      end
fun yyAction27 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.WORD((yytext, btoi(yytext, 3)), yypos, yypos+size yytext))
      end
fun yyAction28 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.WORD((yytext, xtoi(yytext, 3)), yypos, yypos+size yytext))
      end
fun yyAction29 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.INT0((yytext, atoi(yytext, 0)), yypos, yypos+size yytext))
      end
fun yyAction30 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.INT0((yytext, atoi(yytext, 0)), yypos, yypos+size yytext))
      end
fun yyAction31 (strm, lastMatch : yymatch) = (yystrm := strm;
      (charlist := [""]; stringstart := yypos;
                    stringtype := true; YYBEGIN S; continue()))
fun yyAction32 (strm, lastMatch : yymatch) = (yystrm := strm;
      (charlist := [""]; stringstart := yypos;
                    stringtype := false; YYBEGIN S; continue()))
fun yyAction33 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN L; stringstart := yypos; comLevel := 1; continue()))
fun yyAction34 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN LCOM; continue()))
fun yyAction35 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; YYBEGIN INITIAL; continue()))
fun yyAction36 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction37 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN A; stringstart := yypos; comLevel := 1; continue()))
fun yyAction38 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (err (yypos,yypos) COMPLAIN
		      (concat[
			  "non-Ascii character (ord ",
			  Int.toString(Char.ord(String.sub(yytext, 0))), ")"
			]) nullErrorBody;
		    continue())
      end
fun yyAction39 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (yypos,yypos) COMPLAIN "illegal token" nullErrorBody;
		    continue()))
fun yyAction40 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (YYBEGIN LL; charlist := [yytext]; continue())
      end
fun yyAction41 (strm, lastMatch : yymatch) = (yystrm := strm;
      ((* cheat: take n > 0 dots *) continue()))
fun yyAction42 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (YYBEGIN LLC; addString(charlist, yytext); continue())
      end
fun yyAction43 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN LLC; addString(charlist, "1");    continue()
		(* note hack, since ml-lex chokes on the empty string for 0* *)))
fun yyAction44 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN INITIAL;
                    mysynch (sourceMap, !stringstart, yypos+2, !charlist)
                      handle Overflow => err
                        (!stringstart, yypos+2)
                        COMPLAIN
                        "illegal '#line' comment; line number too large"
                        nullErrorBody;
		    comLevel := 0; charlist := [];
                    continue ()))
fun yyAction45 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN LLCQ; continue()))
fun yyAction46 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (addString(charlist, yytext); continue())
      end
fun yyAction47 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN INITIAL;
                    mysynch(sourceMap, !stringstart, yypos+3, !charlist)
                      handle Overflow => err
                        (!stringstart, yypos+3)
                        COMPLAIN
                        "illegal '#line' comment; line number too large"
                        nullErrorBody;
                    comLevel := 0; charlist := [];
                    continue()))
fun yyAction48 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart, yypos+1) WARN
                       "ill-formed (*#line...*) taken as comment" nullErrorBody;
                     YYBEGIN INITIAL; comLevel := 0; charlist := []; continue()))
fun yyAction49 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart, yypos+1) WARN
                       "ill-formed (*#line...*) taken as comment" nullErrorBody;
                     YYBEGIN A; continue()))
fun yyAction50 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart, yypos) WARN
                       "ill-formed (*#line...*) taken as comment" nullErrorBody;
                     SourceMap.newline sourceMap yypos;
                     YYBEGIN A; continue()))
fun yyAction51 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN ALC; continue()))
fun yyAction52 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; YYBEGIN A; continue()))
fun yyAction53 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction54 (strm, lastMatch : yymatch) = (yystrm := strm;
      (inc comLevel; continue()))
fun yyAction55 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; continue()))
fun yyAction56 (strm, lastMatch : yymatch) = (yystrm := strm;
      (dec comLevel; if !comLevel=0 then YYBEGIN INITIAL else (); continue()))
fun yyAction57 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction58 (strm, lastMatch : yymatch) = (yystrm := strm;
      (let val s = makeString charlist
                        val s = if size s <> 1 andalso not(!stringtype)
                                 then (err(!stringstart,yypos) COMPLAIN
                                      "character constant not length 1"
                                       nullErrorBody;
                                       substring(s^"x",0,1))
                                 else s
                        val t = (s,!stringstart,yypos+1)
                    in YYBEGIN INITIAL;
                       if !stringtype then Tokens.STRING t else Tokens.CHAR t
                    end))
fun yyAction59 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart,yypos) COMPLAIN "unclosed string"
		        nullErrorBody;
		    SourceMap.newline sourceMap yypos;
		    YYBEGIN INITIAL; Tokens.STRING(makeString charlist,!stringstart,yypos)))
fun yyAction60 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap (yypos+1);
		    YYBEGIN F; continue()))
fun yyAction61 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN F; continue()))
fun yyAction62 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\007"); continue()))
fun yyAction63 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\008"); continue()))
fun yyAction64 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\012"); continue()))
fun yyAction65 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\010"); continue()))
fun yyAction66 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\013"); continue()))
fun yyAction67 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\009"); continue()))
fun yyAction68 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\011"); continue()))
fun yyAction69 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\\"); continue()))
fun yyAction70 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\""); continue()))
fun yyAction71 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (addChar(charlist,
			Char.chr(Char.ord(String.sub(yytext,2))-Char.ord #"@"));
		    continue())
      end
fun yyAction72 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err(yypos,yypos+2) COMPLAIN "illegal control escape; must be one of \
	  \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_" nullErrorBody;
	 continue()))
fun yyAction73 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (let
                    val x = Word.toIntX (valOf (Word.fromString (String.substring(yytext, 2, 4))))
                    in
		      if x>255
			then err (yypos,yypos+4) COMPLAIN (concat[
                            "illegal string escape '", yytext, "' is too large"
                          ]) nullErrorBody
			else addChar(charlist, Char.chr x);
		      continue()
		    end)
      end
fun yyAction74 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (let val SOME x = Int.fromString (String.substring(yytext, 1, 3))
		    in
		      if x>255
			then err (yypos,yypos+4) COMPLAIN (concat[
                            "illegal string escape '", yytext, "' is too large"
                          ]) nullErrorBody
			else addChar(charlist, Char.chr x);
		      continue()
		    end)
      end
fun yyAction75 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (yypos,yypos+1) COMPLAIN "illegal string escape" nullErrorBody;
		    continue()))
fun yyAction76 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (yypos,yypos+1) COMPLAIN "illegal non-printing character in string" nullErrorBody;
                    continue()))
fun yyAction77 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (addString(charlist,yytext); continue())
      end
fun yyAction78 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; continue()))
fun yyAction79 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction80 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN S; stringstart := yypos; continue()))
fun yyAction81 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart,yypos) COMPLAIN "unclosed string"
		        nullErrorBody;
		    YYBEGIN INITIAL; Tokens.STRING(makeString charlist,!stringstart,yypos+1)))
fun yyAction82 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "`"); continue()))
fun yyAction83 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "^"); continue()))
fun yyAction84 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN AQ;
                    let val x = makeString charlist
                    in
                    Tokens.OBJL(x,yypos,yypos+(size x))
                    end))
fun yyAction85 (strm, lastMatch : yymatch) = (yystrm := strm;
      ((* a closing quote *)
                    YYBEGIN INITIAL;
                    let val x = makeString charlist
                    in
                    Tokens.ENDQ(x,yypos,yypos+(size x))
                    end))
fun yyAction86 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; addString(charlist,"\n"); continue()))
fun yyAction87 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (addString(charlist,yytext); continue())
      end
fun yyAction88 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; continue()))
fun yyAction89 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction90 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (YYBEGIN Q;
                    let val hash = HashString.hashString yytext
                    in
                    Tokens.AQID(FastSymbol.rawSymbol(hash,yytext),
				yypos,yypos+(size yytext))
                    end)
      end
fun yyAction91 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (YYBEGIN Q;
                    let val hash = HashString.hashString yytext
                    in
                    Tokens.AQID(FastSymbol.rawSymbol(hash,yytext),
				yypos,yypos+(size yytext))
                    end)
      end
fun yyAction92 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN INITIAL;
                    brack_stack := ((ref 1)::(!brack_stack));
                    Tokens.LPAREN(yypos,yypos+1)))
fun yyAction93 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (err (yypos,yypos+1) COMPLAIN
		       ("ml lexer: bad character after antiquote "^yytext)
		       nullErrorBody;
                    Tokens.AQID(FastSymbol.rawSymbol(0w0,""),yypos,yypos))
      end
val yyactTable = Vector.fromList([yyAction0, yyAction1, yyAction2, yyAction3,
  yyAction4, yyAction5, yyAction6, yyAction7, yyAction8, yyAction9, yyAction10,
  yyAction11, yyAction12, yyAction13, yyAction14, yyAction15, yyAction16,
  yyAction17, yyAction18, yyAction19, yyAction20, yyAction21, yyAction22,
  yyAction23, yyAction24, yyAction25, yyAction26, yyAction27, yyAction28,
  yyAction29, yyAction30, yyAction31, yyAction32, yyAction33, yyAction34,
  yyAction35, yyAction36, yyAction37, yyAction38, yyAction39, yyAction40,
  yyAction41, yyAction42, yyAction43, yyAction44, yyAction45, yyAction46,
  yyAction47, yyAction48, yyAction49, yyAction50, yyAction51, yyAction52,
  yyAction53, yyAction54, yyAction55, yyAction56, yyAction57, yyAction58,
  yyAction59, yyAction60, yyAction61, yyAction62, yyAction63, yyAction64,
  yyAction65, yyAction66, yyAction67, yyAction68, yyAction69, yyAction70,
  yyAction71, yyAction72, yyAction73, yyAction74, yyAction75, yyAction76,
  yyAction77, yyAction78, yyAction79, yyAction80, yyAction81, yyAction82,
  yyAction83, yyAction84, yyAction85, yyAction86, yyAction87, yyAction88,
  yyAction89, yyAction90, yyAction91, yyAction92, yyAction93])
in
  if yyInput.eof(!(yystrm))
    then UserDeclarations.eof(yyarg)
    else (case (!(yyss))
       of LCOM => yygo yyactTable (0, !(yystrm), yyNO_MATCH)
        | AQ => yygo yyactTable (1, !(yystrm), yyNO_MATCH)
        | LL => yygo yyactTable (2, !(yystrm), yyNO_MATCH)
        | LLC => yygo yyactTable (3, !(yystrm), yyNO_MATCH)
        | F => yygo yyactTable (4, !(yystrm), yyNO_MATCH)
        | A => yygo yyactTable (5, !(yystrm), yyNO_MATCH)
        | L => yygo yyactTable (6, !(yystrm), yyNO_MATCH)
        | Q => yygo yyactTable (7, !(yystrm), yyNO_MATCH)
        | S => yygo yyactTable (8, !(yystrm), yyNO_MATCH)
        | INITIAL => yygo yyactTable (9, !(yystrm), yyNO_MATCH)
        | ALC => yygo yyactTable (10, !(yystrm), yyNO_MATCH)
        | LLCQ => yygo yyactTable (11, !(yystrm), yyNO_MATCH)
      (* end case *))
end
                end (* continue *)
            in
              continue()
	        handle IO.Io{cause, ...} => raise cause
            end
        in
          lex
        end
    in
    fun makeLexer yyinputN = mk (yyInput.mkStream yyinputN)
    end

  end
