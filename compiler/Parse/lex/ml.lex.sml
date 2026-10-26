functor MLLexFun (structure Tokens : ML_TOKENS)
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

    datatype yystart_state = AQ | LL | LLC | F | A | L | Q | S | INITIAL | LLCQ

    structure UserDeclarations =
      struct

(* ml.lex
 *
 * Copyright 1989 by AT&T Bell Laboratories
 *)

open ErrorMsg;
open UserDeclarations;

structure TokTable = TokenTable(Tokens);

type svalue = Tokens.svalue

type lexresult = (svalue, pos) Tokens.token

type ('a,'b) token = ('a, 'b) Tokens.token

fun eof arg = let val pos = UserDeclarations.eof arg in Tokens.EOF(pos,pos) end

local
  fun cvt radix (s, i) =
	#1(valOf(IntInf.scan radix Substring.getc (Substring.extract(s, i, NONE))))
in
val atoi = cvt StringCvt.DEC
val xtoi = cvt StringCvt.HEX
end (* local *)

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
#[([(#"\^@",#"\b",10),
(#"\v",#"\v",10),
(#"\^N",#"\^_",10),
(#"\"",#"\"",10),
(#"'",#"'",10),
(#")",#")",10),
(#",",#",",10),
(#".",#".",10),
(#"0",#"9",10),
(#";",#";",10),
(#"[",#"[",10),
(#"]",#"]",10),
(#"_",#"`",10),
(#"{",#"{",10),
(#"}",#"}",10),
(#"\127",#"\255",10),
(#"\t",#"\t",11),
(#"\f",#"\f",11),
(#" ",#" ",11),
(#"\n",#"\n",12),
(#"\r",#"\r",13),
(#"!",#"!",14),
(#"#",#"&",14),
(#"*",#"+",14),
(#"-",#"-",14),
(#"/",#"/",14),
(#":",#":",14),
(#"<",#"@",14),
(#"\\",#"\\",14),
(#"^",#"^",14),
(#"|",#"|",14),
(#"~",#"~",14),
(#"(",#"(",15),
(#"A",#"Z",16),
(#"a",#"z",16)], [80]), ([(#".",#".",20),
(#"0",#"0",21),
(#"1",#"9",22)], [37]), ([(#"\^@",#"\b",23),
(#"\v",#"\v",23),
(#"\^N",#"\^_",23),
(#"!",#"!",23),
(#"#",#")",23),
(#"+",#"\255",23),
(#"\t",#"\t",24),
(#"\f",#"\f",24),
(#" ",#" ",24),
(#"\n",#"\n",25),
(#"\r",#"\r",26),
(#"\"",#"\"",27),
(#"*",#"*",28)], []), ([(#"\^@",#"\b",32),
(#"\v",#"\v",32),
(#"\^N",#"\^_",32),
(#"!",#"[",32),
(#"]",#"\255",32),
(#"\t",#"\t",33),
(#"\f",#"\f",33),
(#" ",#" ",33),
(#"\n",#"\n",34),
(#"\r",#"\r",35),
(#"\\",#"\\",36)], [70]), ([(#"\^@",#"\t",38),
(#"\v",#"\f",38),
(#"\^N",#"'",38),
(#")",#")",38),
(#"+",#"\255",38),
(#"\n",#"\n",39),
(#"\r",#"\r",40),
(#"(",#"(",41),
(#"*",#"*",42)], []), ([(#"\^@",#"\t",23),
(#"\v",#"\f",23),
(#"\^N",#")",23),
(#"+",#"/",23),
(#":",#"\255",23),
(#"\n",#"\n",25),
(#"\r",#"\r",26),
(#"*",#"*",45),
(#"0",#"9",46)], []), ([(#"\^@",#"\t",49),
(#"\v",#"\f",49),
(#"\^N",#"]",49),
(#"_",#"_",49),
(#"a",#"\255",49),
(#"\n",#"\n",50),
(#"\r",#"\r",51),
(#"^",#"^",52),
(#"`",#"`",53)], []), ([(#"\^@",#"\t",56),
(#"\v",#"\f",56),
(#"\^N",#"\^_",56),
(#"\n",#"\n",57),
(#"\r",#"\r",58),
(#" ",#" ",59),
(#"\127",#"\255",59),
(#"!",#"!",60),
(#"#",#"[",60),
(#"]",#"~",60),
(#"\"",#"\"",61),
(#"\\",#"\\",62)], []), ([(#"\^@",#"\b",90),
(#"\v",#"\v",90),
(#"\^N",#"\^_",90),
(#"\127",#"\127",90),
(#"\t",#"\t",91),
(#"\f",#"\f",91),
(#" ",#" ",91),
(#"\n",#"\n",92),
(#"\r",#"\r",93),
(#"!",#"!",94),
(#"$",#"&",94),
(#"*",#"+",94),
(#"-",#"-",94),
(#"/",#"/",94),
(#":",#":",94),
(#"<",#"@",94),
(#"\\",#"\\",94),
(#"^",#"^",94),
(#"|",#"|",94),
(#"\"",#"\"",95),
(#"#",#"#",96),
(#"'",#"'",97),
(#"(",#"(",98),
(#")",#")",99),
(#",",#",",100),
(#".",#".",101),
(#"0",#"0",102),
(#"1",#"9",103),
(#";",#";",104),
(#"A",#"Z",105),
(#"a",#"z",105),
(#"[",#"[",106),
(#"]",#"]",107),
(#"_",#"_",108),
(#"`",#"`",109),
(#"{",#"{",110),
(#"}",#"}",111),
(#"~",#"~",112),
(#"\128",#"\255",113)], [0]), ([(#"\^@",#"\t",155),
(#"\v",#"!",155),
(#"#",#")",155),
(#"+",#"\255",155),
(#"\n",#"\n",156),
(#"\"",#"\"",157),
(#"*",#"*",158)], [40]), ([], [84]), ([(#"\t",#"\t",19),
(#"\f",#"\f",19),
(#" ",#" ",19)], [80, 84]), ([], [79]), ([(#"\n",#"\n",12)], [79, 84]), ([(#"!",#"!",18),
(#"#",#"&",18),
(#"*",#"+",18),
(#"-",#"-",18),
(#"/",#"/",18),
(#":",#":",18),
(#"<",#"@",18),
(#"\\",#"\\",18),
(#"^",#"^",18),
(#"|",#"|",18),
(#"~",#"~",18)], [82, 84]), ([], [83, 84]), ([(#"'",#"'",17),
(#"0",#"9",17),
(#"A",#"Z",17),
(#"_",#"_",17),
(#"a",#"z",17)], [81, 84]), ([(#"'",#"'",17),
(#"0",#"9",17),
(#"A",#"Z",17),
(#"_",#"_",17),
(#"a",#"z",17)], [81]), ([(#"!",#"!",18),
(#"#",#"&",18),
(#"*",#"+",18),
(#"-",#"-",18),
(#"/",#"/",18),
(#":",#":",18),
(#"<",#"@",18),
(#"\\",#"\\",18),
(#"^",#"^",18),
(#"|",#"|",18),
(#"~",#"~",18)], [82]), ([(#"\t",#"\t",19),
(#"\f",#"\f",19),
(#" ",#" ",19)], [80]), ([], [35]), ([(#"0",#"0",21),
(#"1",#"9",22)], [36, 37]), ([(#"0",#"9",22)], [36]), ([], [43]), ([(#"\t",#"\t",30),
(#"\f",#"\f",30),
(#" ",#" ",30),
(#"\"",#"\"",31)], [43]), ([], [44]), ([(#"\n",#"\n",25)], [43, 44]), ([], [39, 43]), ([(#")",#")",29)], [43]), ([], [38, 42]), ([(#"\t",#"\t",30),
(#"\f",#"\f",30),
(#" ",#" ",30),
(#"\"",#"\"",31)], []), ([], [39]), ([], [72]), ([(#"\t",#"\t",37),
(#"\f",#"\f",37),
(#" ",#" ",37)], [70, 72]), ([], [69]), ([(#"\n",#"\n",34)], [69, 72]), ([], [71, 72]), ([(#"\t",#"\t",37),
(#"\f",#"\f",37),
(#" ",#" ",37)], [70]), ([], [48]), ([], [46]), ([(#"\n",#"\n",39)], [46, 48]), ([(#"*",#"*",44)], [48]), ([(#")",#")",43)], [48]), ([], [47]), ([], [45]), ([(#")",#")",48)], [43]), ([(#"0",#"9",47)], [34, 43]), ([(#"0",#"9",47)], [34]), ([], [42]), ([], [78]), ([], [77]), ([(#"\n",#"\n",50)], [77, 78]), ([(#"^",#"^",54),
(#"`",#"`",55)], [75, 78]), ([], [76, 78]), ([], [74]), ([], [73]), ([], [67, 68]), ([], [50, 67]), ([(#"\n",#"\n",89)], [50, 67, 68]), ([], [68]), ([(#"!",#"!",88),
(#"#",#"[",88),
(#"]",#"~",88)], [68]), ([], [49, 68]), ([(#"\^@",#"\b",63),
(#"\v",#"\v",63),
(#"\^N",#"\^_",63),
(#"!",#"!",63),
(#"#",#"/",63),
(#":",#"[",63),
(#"]",#"]",63),
(#"_",#"`",63),
(#"c",#"e",63),
(#"g",#"m",63),
(#"o",#"q",63),
(#"s",#"s",63),
(#"w",#"\127",63),
(#"\t",#"\t",64),
(#"\n",#"\n",65),
(#"\f",#"\f",66),
(#" ",#" ",66),
(#"\r",#"\r",67),
(#"\"",#"\"",68),
(#"0",#"9",69),
(#"\\",#"\\",70),
(#"^",#"^",71),
(#"a",#"a",72),
(#"b",#"b",73),
(#"f",#"f",74),
(#"n",#"n",75),
(#"r",#"r",76),
(#"t",#"t",77),
(#"u",#"u",78),
(#"v",#"v",79)], [52, 68]), ([], [66]), ([(#"\t",#"\t",64),
(#"\f",#"\f",64),
(#" ",#" ",64)], [52]), ([], [51]), ([(#"\t",#"\t",64),
(#"\f",#"\f",64),
(#" ",#" ",64)], [52, 66]), ([(#"\n",#"\n",65)], [51]), ([], [61]), ([(#"0",#"9",86)], []), ([], [60]), ([(#"\^@",#"\t",84),
(#"\v",#"?",84),
(#"`",#"\255",84),
(#"@",#"_",85)], []), ([], [53]), ([], [54]), ([], [55]), ([], [56]), ([], [57]), ([], [58]), ([(#"0",#"9",80),
(#"A",#"F",80),
(#"a",#"f",80)], [66]), ([], [59]), ([(#"0",#"9",81),
(#"A",#"F",81),
(#"a",#"f",81)], []), ([(#"0",#"9",82),
(#"A",#"F",82),
(#"a",#"f",82)], []), ([(#"0",#"9",83),
(#"A",#"F",83),
(#"a",#"f",83)], []), ([], [64]), ([], [63]), ([], [62, 63]), ([(#"0",#"9",87)], []), ([], [65]), ([(#"!",#"!",88),
(#"#",#"[",88),
(#"]",#"~",88)], [68]), ([], [50]), ([], [33]), ([(#"\t",#"\t",154),
(#"\f",#"\f",154),
(#" ",#" ",154)], [0, 33]), ([], [1]), ([(#"\n",#"\n",92)], [1, 33]), ([(#"!",#"!",114),
(#"#",#"&",114),
(#"*",#"+",114),
(#"-",#"-",114),
(#"/",#"/",114),
(#":",#":",114),
(#"<",#"@",114),
(#"\\",#"\\",114),
(#"^",#"^",114),
(#"|",#"|",114),
(#"~",#"~",114),
(#"`",#"`",117)], [17, 18, 33]), ([], [28, 33]), ([(#"!",#"!",114),
(#"#",#"&",114),
(#"*",#"+",114),
(#"-",#"-",114),
(#"/",#"/",114),
(#":",#":",114),
(#"<",#"@",114),
(#"\\",#"\\",114),
(#"^",#"^",114),
(#"|",#"|",114),
(#"~",#"~",114),
(#"\"",#"\"",152),
(#"[",#"[",153),
(#"`",#"`",117)], [17, 18, 33]), ([(#"'",#"'",151),
(#"0",#"9",151),
(#"A",#"Z",151),
(#"_",#"_",151),
(#"a",#"z",151)], [15, 33]), ([(#"*",#"*",144)], [11, 33]), ([], [12, 33]), ([], [4, 33]), ([(#".",#".",142)], [13, 33]), ([(#".",#".",118),
(#"0",#"9",135),
(#"E",#"E",119),
(#"e",#"e",119),
(#"w",#"w",136),
(#"x",#"x",137)], [22, 33]), ([(#".",#".",118),
(#"0",#"9",134),
(#"E",#"E",119),
(#"e",#"e",119)], [21, 22, 33]), ([], [10, 33]), ([(#"'",#"'",133),
(#"0",#"9",133),
(#"A",#"Z",133),
(#"_",#"_",133),
(#"a",#"z",133)], [16, 33]), ([], [7, 33]), ([], [9, 33]), ([(#"o",#"o",125)], [3, 33]), ([(#"!",#"!",117),
(#"#",#"&",117),
(#"*",#"+",117),
(#"-",#"-",117),
(#"/",#"/",117),
(#":",#":",117),
(#"<",#"@",117),
(#"\\",#"\\",117),
(#"^",#"^",117),
(#"`",#"`",117),
(#"|",#"|",117),
(#"~",#"~",117)], [17, 19, 33]), ([], [5, 33]), ([], [6, 33]), ([(#"!",#"!",114),
(#"#",#"&",114),
(#"*",#"+",114),
(#"-",#"-",114),
(#"/",#"/",114),
(#":",#":",114),
(#"<",#"@",114),
(#"\\",#"\\",114),
(#"^",#"^",114),
(#"|",#"|",114),
(#"~",#"~",114),
(#"0",#"0",115),
(#"1",#"9",116),
(#"`",#"`",117)], [17, 18, 33]), ([], [32, 33]), ([(#"!",#"!",114),
(#"#",#"&",114),
(#"*",#"+",114),
(#"-",#"-",114),
(#"/",#"/",114),
(#":",#":",114),
(#"<",#"@",114),
(#"\\",#"\\",114),
(#"^",#"^",114),
(#"|",#"|",114),
(#"~",#"~",114),
(#"`",#"`",117)], [17, 18]), ([(#".",#".",118),
(#"0",#"9",116),
(#"E",#"E",119),
(#"e",#"e",119),
(#"x",#"x",123)], [23]), ([(#".",#".",118),
(#"0",#"9",116),
(#"E",#"E",119),
(#"e",#"e",119)], [23]), ([(#"!",#"!",117),
(#"#",#"&",117),
(#"*",#"+",117),
(#"-",#"-",117),
(#"/",#"/",117),
(#":",#":",117),
(#"<",#"@",117),
(#"\\",#"\\",117),
(#"^",#"^",117),
(#"`",#"`",117),
(#"|",#"|",117),
(#"~",#"~",117)], [17]), ([(#"0",#"9",122)], []), ([(#"0",#"9",120),
(#"~",#"~",121)], []), ([(#"0",#"9",120)], [20]), ([(#"0",#"9",120)], []), ([(#"0",#"9",122),
(#"E",#"E",119),
(#"e",#"e",119)], [20]), ([(#"0",#"9",124),
(#"A",#"F",124),
(#"a",#"f",124)], []), ([(#"0",#"9",124),
(#"A",#"F",124),
(#"a",#"f",124)], [25]), ([(#"v",#"v",126)], []), ([(#"e",#"e",127)], []), ([(#"r",#"r",128)], []), ([(#"l",#"l",129)], []), ([(#"o",#"o",130)], []), ([(#"a",#"a",131)], []), ([(#"d",#"d",132)], []), ([], [2]), ([(#"'",#"'",133),
(#"0",#"9",133),
(#"A",#"Z",133),
(#"_",#"_",133),
(#"a",#"z",133)], [16]), ([(#".",#".",118),
(#"0",#"9",134),
(#"E",#"E",119),
(#"e",#"e",119)], [21, 22]), ([(#".",#".",118),
(#"0",#"9",135),
(#"E",#"E",119),
(#"e",#"e",119)], [22]), ([(#"0",#"9",139),
(#"x",#"x",140)], []), ([(#"0",#"9",138),
(#"A",#"F",138),
(#"a",#"f",138)], []), ([(#"0",#"9",138),
(#"A",#"F",138),
(#"a",#"f",138)], [24]), ([(#"0",#"9",139)], [26]), ([(#"0",#"9",141),
(#"A",#"F",141),
(#"a",#"f",141)], []), ([(#"0",#"9",141),
(#"A",#"F",141),
(#"a",#"f",141)], [27]), ([(#".",#".",143)], []), ([], [14]), ([(#"#",#"#",145)], [31]), ([(#"l",#"l",146)], []), ([(#"i",#"i",147)], []), ([(#"n",#"n",148)], []), ([(#"e",#"e",149)], []), ([(#"\t",#"\t",150),
(#"\f",#"\f",150),
(#" ",#" ",150)], []), ([(#"\t",#"\t",150),
(#"\f",#"\f",150),
(#" ",#" ",150)], [30]), ([(#"'",#"'",151),
(#"0",#"9",151),
(#"A",#"Z",151),
(#"_",#"_",151),
(#"a",#"z",151)], [15]), ([], [29]), ([], [8]), ([(#"\t",#"\t",154),
(#"\f",#"\f",154),
(#" ",#" ",154)], [0]), ([(#"\^@",#"!",156),
(#"#",#"\255",156)], [40, 43]), ([(#"\^@",#"!",156),
(#"#",#"\255",156)], [40]), ([(#"*",#"*",160)], [43]), ([(#"\^@",#"!",156),
(#"#",#"(",156),
(#"*",#"\255",156),
(#")",#")",159)], [40, 43]), ([(#"\^@",#"!",156),
(#"#",#"\255",156)], [40, 42]), ([(#")",#")",161)], []), ([], [41])]

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
        (Tokens.INT0((yytext, atoi(yytext, 0)), yypos, yypos+size yytext))
      end
fun yyAction23 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (Tokens.INT0((yytext, atoi(yytext, 0)), yypos, yypos+size yytext))
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
        (Tokens.WORD((yytext, xtoi(yytext, 3)), yypos, yypos+size yytext))
      end
fun yyAction28 (strm, lastMatch : yymatch) = (yystrm := strm;
      (charlist := [""]; stringstart := yypos;
                    stringtype := true; YYBEGIN S; continue()))
fun yyAction29 (strm, lastMatch : yymatch) = (yystrm := strm;
      (charlist := [""]; stringstart := yypos;
                    stringtype := false; YYBEGIN S; continue()))
fun yyAction30 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN L; stringstart := yypos; comLevel := 1; continue()))
fun yyAction31 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN A; stringstart := yypos; comLevel := 1; continue()))
fun yyAction32 (strm, lastMatch : yymatch) = let
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
fun yyAction33 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (yypos,yypos) COMPLAIN "illegal token" nullErrorBody;
		    continue()))
fun yyAction34 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (YYBEGIN LL; charlist := [yytext]; continue())
      end
fun yyAction35 (strm, lastMatch : yymatch) = (yystrm := strm;
      ((* cheat: take n > 0 dots *) continue()))
fun yyAction36 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (YYBEGIN LLC; addString(charlist, yytext); continue())
      end
fun yyAction37 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN LLC; addString(charlist, "1");    continue()
		(* note hack, since ml-lex chokes on the empty string for 0* *)))
fun yyAction38 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN INITIAL;
                    mysynch (sourceMap, !stringstart, yypos+2, !charlist)
                      handle Overflow => err
                        (!stringstart, yypos+2)
                        COMPLAIN
                        "illegal '#line' comment; line number too large"
                        nullErrorBody;
		    comLevel := 0; charlist := [];
                    continue ()))
fun yyAction39 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN LLCQ; continue()))
fun yyAction40 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (addString(charlist, yytext); continue())
      end
fun yyAction41 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN INITIAL;
                    mysynch(sourceMap, !stringstart, yypos+3, !charlist)
                      handle Overflow => err
                        (!stringstart, yypos+3)
                        COMPLAIN
                        "illegal '#line' comment; line number too large"
                        nullErrorBody;
                    comLevel := 0; charlist := [];
                    continue()))
fun yyAction42 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart, yypos+1) WARN
                       "ill-formed (*#line...*) taken as comment" nullErrorBody;
                     YYBEGIN INITIAL; comLevel := 0; charlist := []; continue()))
fun yyAction43 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart, yypos+1) WARN
                      "ill-formed (*#line...*) taken as comment" nullErrorBody;
                    YYBEGIN A; charlist := []; continue()))
fun yyAction44 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart, yypos) WARN
                      "ill-formed (*#line...*) taken as comment" nullErrorBody;
                    SourceMap.newline sourceMap yypos;
                    YYBEGIN A; charlist := []; continue()))
fun yyAction45 (strm, lastMatch : yymatch) = (yystrm := strm;
      (inc comLevel; continue()))
fun yyAction46 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; continue()))
fun yyAction47 (strm, lastMatch : yymatch) = (yystrm := strm;
      (dec comLevel; if !comLevel=0 then YYBEGIN INITIAL else (); continue()))
fun yyAction48 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction49 (strm, lastMatch : yymatch) = (yystrm := strm;
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
fun yyAction50 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart,yypos) COMPLAIN "unclosed string"
		        nullErrorBody;
		    SourceMap.newline sourceMap yypos;
		    YYBEGIN INITIAL; Tokens.STRING(makeString charlist,!stringstart,yypos)))
fun yyAction51 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap (yypos+1);
		    YYBEGIN F; continue()))
fun yyAction52 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN F; continue()))
fun yyAction53 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\007"); continue()))
fun yyAction54 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\008"); continue()))
fun yyAction55 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\012"); continue()))
fun yyAction56 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\010"); continue()))
fun yyAction57 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\013"); continue()))
fun yyAction58 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\009"); continue()))
fun yyAction59 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\011"); continue()))
fun yyAction60 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\\"); continue()))
fun yyAction61 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "\""); continue()))
fun yyAction62 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm;
        (addChar(charlist,
			Char.chr(Char.ord(String.sub(yytext,2))-Char.ord #"@"));
		    continue())
      end
fun yyAction63 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err(yypos,yypos+2) COMPLAIN "illegal control escape; must be one of \
	  \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_" nullErrorBody;
	 continue()))
fun yyAction64 (strm, lastMatch : yymatch) = let
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
fun yyAction65 (strm, lastMatch : yymatch) = let
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
fun yyAction66 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (yypos,yypos+1) COMPLAIN "illegal string escape" nullErrorBody;
		    continue()))
fun yyAction67 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (yypos,yypos+1) COMPLAIN "illegal non-printing character in string" nullErrorBody;
                    continue()))
fun yyAction68 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (addString(charlist,yytext); continue())
      end
fun yyAction69 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; continue()))
fun yyAction70 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction71 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN S; continue()))
fun yyAction72 (strm, lastMatch : yymatch) = (yystrm := strm;
      (err (!stringstart,yypos) COMPLAIN "unclosed string"
		        nullErrorBody;
		    YYBEGIN INITIAL; Tokens.STRING(makeString charlist,!stringstart,yypos+1)))
fun yyAction73 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "`"); continue()))
fun yyAction74 (strm, lastMatch : yymatch) = (yystrm := strm;
      (addString(charlist, "^"); continue()))
fun yyAction75 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN AQ;
                    let val x = makeString charlist
                    in
                    Tokens.OBJL(x,yypos,yypos+(size x))
                    end))
fun yyAction76 (strm, lastMatch : yymatch) = (yystrm := strm;
      ((* a closing quote *)
                    YYBEGIN INITIAL;
                    let val x = makeString charlist
                    in
                    Tokens.ENDQ(x,yypos,yypos+(size x))
                    end))
fun yyAction77 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; addString(charlist,"\n"); continue()))
fun yyAction78 (strm, lastMatch : yymatch) = let
      val yytext = yymktext(strm)
      in
        yystrm := strm; (addString(charlist,yytext); continue())
      end
fun yyAction79 (strm, lastMatch : yymatch) = (yystrm := strm;
      (SourceMap.newline sourceMap yypos; continue()))
fun yyAction80 (strm, lastMatch : yymatch) = (yystrm := strm; (continue()))
fun yyAction81 (strm, lastMatch : yymatch) = let
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
fun yyAction82 (strm, lastMatch : yymatch) = let
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
fun yyAction83 (strm, lastMatch : yymatch) = (yystrm := strm;
      (YYBEGIN INITIAL;
                    brack_stack := ((ref 1)::(!brack_stack));
                    Tokens.LPAREN(yypos,yypos+1)))
fun yyAction84 (strm, lastMatch : yymatch) = let
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
  yyAction83, yyAction84])
in
  if yyInput.eof(!(yystrm))
    then UserDeclarations.eof(yyarg)
    else (case (!(yyss))
       of AQ => yygo yyactTable (0, !(yystrm), yyNO_MATCH)
        | LL => yygo yyactTable (1, !(yystrm), yyNO_MATCH)
        | LLC => yygo yyactTable (2, !(yystrm), yyNO_MATCH)
        | F => yygo yyactTable (3, !(yystrm), yyNO_MATCH)
        | A => yygo yyactTable (4, !(yystrm), yyNO_MATCH)
        | L => yygo yyactTable (5, !(yystrm), yyNO_MATCH)
        | Q => yygo yyactTable (6, !(yystrm), yyNO_MATCH)
        | S => yygo yyactTable (7, !(yystrm), yyNO_MATCH)
        | INITIAL => yygo yyactTable (8, !(yystrm), yyNO_MATCH)
        | LLCQ => yygo yyactTable (9, !(yystrm), yyNO_MATCH)
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
