import unittest

include ski

let cs = combinators

suite "takePrefixCombinator":
  test "先頭の文字を返す":
    check("S" == "Sxyz".takePrefixCombinator(cs))
  test "括弧で括られた文字の場合はそれらを返す":
    check("(SKI)" == "(SKI)xyz".takePrefixCombinator(cs))
    check("(SKI)" == "(SKI)".takePrefixCombinator(cs))
  test "空文字の場合は空文字を返す":
    check("" == "".takePrefixCombinator(cs))
  test "コンビネータが登録されていないものなら1文字返す":
    check("x" == "xyz".takePrefixCombinator(cs))

suite "takeBracketCombinator":
  test "括弧で括られた文字を返す":
    check("(SKI)" == "(SKI)xyz".takeBracketCombinator)
  test "ネストした括弧で括られている場合は、一番外の括弧で返す":
    check("(ABC(D))" == "(ABC(D))xyz".takeBracketCombinator)
    check("((D)ABC)" == "((D)ABC)xyz".takeBracketCombinator)
  test "括弧閉じが不足する場合は、全部返す":
    check("(SKIxyz" == "(SKIxyz".takeBracketCombinator)
    check("((SKIxyz" == "((SKIxyz".takeBracketCombinator)
    check("((SKI)xyz" == "((SKI)xyz".takeBracketCombinator)

suite "takeCombinator":
  let args: seq[string] = @[]
  test "コンビネータと引数と残りを返す":
    check((combinator: "S", args: @["x", "y", "z"], suffix: "A") == "SxyzA".takeCombinator(cs))
  test "引数コンビネータが括弧に括られている場合は括弧ごと引数とする":
    check((combinator: "S", args: @["(x)", "(xy)", "(xyz)"], suffix: "(ABC)") == "S(x)(xy)(xyz)(ABC)".takeCombinator(cs))
  test "先頭のコンビネータが渡したコンビネータに存在しなければ、引数なしで返す":
    check((combinator: "a", args: args, suffix: "bcdefg") == "abcdefg".takeCombinator(cs))
  test "先頭のコンビネータが括弧でくくられていれば、すべてsuffixになる":
    check((combinator: "(Sxy)", args: args, suffix: "z") == "(Sxy)z".takeCombinator(cs))
  test "引数不足ならargsは空":
    check((combinator: "S", args: @["x", "y"], suffix: "") == "Sxy".takeCombinator(cs))

suite "calculateFormat":
  test "置換処理を実行する":
    check("xz(yz)" == cs[0].calculateFormat(["x", "y", "z"]))
    check("(abc)(ghi)((def)(ghi))" == cs[0].calculateFormat(["(abc)", "(def)", "(ghi)"]))
  test "コンビネータの引数が不足していると、そのまま返す":
    check("Sx" == cs[0].calculateFormat(["x"]))
    let args: seq[string] = @[]
    check("S" == cs[0].calculateFormat(args))

suite "calculate1Time":
  test "1回だけ計算する":
    check("xz(yz)" == "Sxyz".calculate1Time(cs))
  test "これ以上計算できない場合はそのまま返す":
    check("SS(((SS)S)S)" == "SS(((SS)S)S)".calculate1Time(cs))
  test "余っていた引数は末尾に付与される":
    check("xz(yz)A" == "SxyzA".calculate1Time(cs))
  test "2回目は計算されない":
    check("Kz(Iz)" == "SKIz".calculate1Time(cs))
  test "未定義コンビネータならそのまま返す":
    check("syz" == "syz".calculate1Time(cs))
  test "先頭のコンビネータが括弧でくくられていた場合は括弧を展開する":
    check("Sxyz" == "(Sxyz)".calculate1Time(cs))
  test "引数指定なしのコンビネータの場合はそのまま置換":
    check("K" == "T".calculate1Time(cs))
    check("SK" == "F".calculate1Time(cs))

suite "calculate":
  test "計算する":
    check("xz(yz)" == "Sxyz".calculate(cs))
    check("xz(yz)A" == "SxyzA".calculate(cs))
    check("x(xyz)((xy)(xyz))" == "S(x)(xy)(xyz)".calculate(cs))
  test "回数指定で計算する":
    check("KI(II)" == "SKII".calculate(cs, 1))
    check("I" == "SKII".calculate(cs, 2))
    check("I" == "SKII".calculate(cs, 3))
  test "2回目以降も計算される":
    check("z" == "SKIz".calculate(cs))
    check("SKISxyz" == "SKISxyz".calculate(cs, 0))
    check("KS(IS)xyz" == "SKISxyz".calculate(cs, 1))
    check("Sxyz" == "SKISxyz".calculate(cs, 2))
    check("xz(yz)" == "SKISxyz".calculate(cs, 3))
    check("xz(yz)" == "SKISxyz".calculate(cs, 4))
    check("xz(yz)" == "SKISxyz".calculate(cs))
    check("xz(yz)A" == "SKISxyzA".calculate(cs))
    check("zA((yz)A)" == "SKISSyzA".calculate(cs))
  test "SSSSSS":
    check("SS(SS)SS" == "SSSSSS".calculate(cs, 1))
    check("SS((SS)S)S" == "SSSSSS".calculate(cs, 2))
    check("SS(((SS)S)S)" == "SSSSSS".calculate(cs, 3))
    check("SS(((SS)S)S)" == "SSSSSS".calculate(cs))
  test "未定義コンビネータならそのまま返す":
    check("xyz" == "xyz".calculate(cs))
  test "空文字のときは空文字を返す":
   check("" == "".calculate(cs))
  test "括弧でくくられていても計算する":
    check("xz(yz)" == "(Sxy)z".calculate(cs))
  test "括弧だらけ":
    check("x" == "(x)".calculate(cs))
    check("x" == "((((x))))".calculate(cs))
    check("xy" == "((x)y)".calculate(cs))
    check("xyz" == "(((x)y)z)".calculate(cs))
    check("xz(yz)" == "(((S(x))y)z)".calculate(cs))
  test "引数指定なしのコンビネータの場合はそのまま置換":
    check("x" == "Txz".calculate(cs))
    check("z" == "Fxz".calculate(cs))

suite "calculateSeq":
  test "2回目以降も計算される":
    check(@["KS(IS)xyz"] == "SKISxyz".calculateSeq(cs, n = 1))
    check(@["KS(IS)xyz", "Sxyz"] == "SKISxyz".calculateSeq(cs, n = 2))
    check(@["KS(IS)xyz", "Sxyz", "xz(yz)"] == "SKISxyz".calculateSeq(cs, n = 3))
    check(@["KS(IS)xyz", "Sxyz", "xz(yz)"] == "SKISxyz".calculateSeq(cs))
  test "計算不可のときは空を返す":
    let empty: seq[string] = @[]
    check(empty == "xyz".calculateSeq(cs))
    check(empty == "Sxyz".calculateSeq(cs, n = 0))
  
suite "calculateIterator":
  test "計算回数が1回":
    var ret: seq[string]
    for r in "Sxyz".calculateIterator(cs):
      ret.add r
    check ret == @["xz(yz)"]
  test "計算回数が3回":
    var ret: seq[string]
    for r in "SKISxyz".calculateIterator(cs):
      ret.add r
    check ret == @["KS(IS)xyz", "Sxyz", "xz(yz)"]
  test "計算回数が0回":
    var ret: seq[string]
    for r in "x".calculateIterator(cs):
      ret.add r
    var empty: seq[string]
    check ret == empty
  test "計算回数を2回に指定":
    var ret: seq[string]
    for r in "SKISxyz".calculateIterator(cs, 2):
      ret.add r
    check ret == @["KS(IS)xyz", "Sxyz"]