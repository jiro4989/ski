import strutils
from sequtils import filterIt

type Combinator* = ref object
  ## コンビネータ
  name*: string     ## コンビネータの名前
  argsCount*: int   ## コンビネータが必要とする引数の数
  format*: string   ## コンビネータの変換書式。"{0}{1}"という具合に書く。

proc takeBracketCombinator(code: string): string =
  ## 先頭の括弧"()"で括られた文字列を返す。
  ## このプロシージャ自体は括弧の整合性をチェックしないので
  ## 閉じ括弧が不足している場合などのチェックは呼び出し元で実施すること。
  var cnt: int
  for c in code:
    result.add c

    case c
    of '(': inc cnt
    of ')': dec cnt
    else: discard

    if cnt <= 0:
      break
      
proc takePrefixCombinator(code: string, cs: openArray[Combinator]): string =
  ## 先頭のコンビネータを返す。
  ## 先頭の文字列が括弧始まりの場合は括弧で括られたコンビネータを返す。
  ## そうでなければ、定義済みコンビネータ(cs)の内、マッチするものを返す。
  ## それらのいずれでもなければ、1文字返す。
  if code.len <= 0:
    return ""
  if code.startsWith "(":
    return code.takeBracketCombinator
  for c in cs:
    if code.startsWith c.name:
      return c.name
  return $code[0]

proc takeCombinator(code: string, cs: openArray[Combinator]): tuple[combinator: string, args: seq[string], suffix: string] =
  ## 先頭コンビネータ、先頭コンビネータが必要とする引数コンビネータのリスト、余りを返す。
  ## 定義済みコンビネータとマッチしなければ引数リストに空を返す。
  let
    pref = code.takePrefixCombinator cs
    matched = cs.filterIt(it.name == pref)
    co = if matched.len <= 0: Combinator(name: pref, argsCount: 0, format: "")
         else: matched[0]

  var
    code2 = code[pref.len .. code.len-1]
    args: seq[string] = @[]
  for i in 1..co.argsCount:
    if code2 == "":
      break
    let c = code2.takePrefixCombinator cs
    if c == "":
      return (pref, @[], code2.substr pref.len)
    args.add c
    code2 = code2[c.len .. code2.len-1]

  let joined = pref & args.join("")
  return (pref, args, code.substr joined.len)

proc calcFormat(co: Combinator, args: openArray[string]): string =
  ## コンビネータの変換書式に、引数を適用して返す。
  ## 引数が不足した場合は、コンビネータ名と引数を結合して返す。
  if args.len < co.argsCount:
    return co.name & args.join("")

  result = co.format
  for i in 0..<co.argsCount:
    let f = "{" & $i & "}"
    result = result.replace(f, args[i])

proc calcCLCode1Time(code: string, cs: openArray[Combinator]): string =
  ## 一度だけコンビネータを計算する。
  ## 計算できなかった場合は、計算対象のコードをそのまま返す。
  let
    coTuple = code.takeCombinator cs
    matched = cs.filterIt(it.name == coTuple.combinator)
  if matched.len < 1:
    if coTuple.combinator.startsWith("("):
      # 前後の括弧を削除
      let pref = coTuple.combinator[1..^2]
      return pref & coTuple.suffix
    else:
      return code
  let co = matched[0]
  result = co.calcFormat(coTuple.args) & coTuple.suffix

proc calcCLCode*(code: string, cs: openArray[Combinator], n: int = -1): string =
  ## 計算不能になるまでコンビネータ文字列を計算して返す。
  ## 計算不能、とは計算前と計算後の結果が一致する場合、または
  ## 指定した計算回数(n)分計算をした場合を指す。
  var m = n
  if m == 0:
    return code
  if -1 < m:
    dec m
  let ret = code.calcCLCode1Time cs
  if code == ret:
    return code
  result = ret.calcCLCode(cs, m)

proc calcCLCodeAndResults*(code: string, cs: openArray[Combinator], results: seq[string] = @[], n: int = -1): seq[string] =
  ## 計算不能になるまでコンビネータ文字列を計算して、計算過程とともに返す。
  ## 計算不能、とは計算前と計算後の結果が一致する場合、または
  ## 指定した計算回数(n)分計算をした場合を指す。
  var m = n
  if m == 0:
    return results
  if -1 < m:
    dec m
  let ret = code.calcCLCode1Time cs
  if code == ret:
    return results
  var nr = results
  nr.add ret
  result = ret.calcCLCodeAndResults(cs, nr, m)
