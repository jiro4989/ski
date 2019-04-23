## ski is module for calculating `SKI Combinator <https://en.wikipedia.org/wiki/SKI_combinator_calculus>`_.
##
## Basic usage
## ===========
##
## You can pretty calculate SKI Combinators with `calculate proc <#calculate,string,openArray[Combinator],int>`_.
##
## .. code-block:: nim
##
##    import ski
##
##    echo "Sxyz".calculate(combinators)
##
## See also
## ========
## * `SKI Combinator calculus - Wikipedia <https://en.wikipedia.org/wiki/SKI_combinator_calculus>`_

import strutils
from sequtils import filterIt

type Combinator* = ref object
  ## Definition of Combinator.
  name*: string     ## Name
  argsCount*: int   ## Argument count
  format*: string   ## Format of convertion. Format example is "{0}{1}"...

let combinators* = @[
  Combinator(name:"S", argsCount:3, format:"{0}{2}({1}{2})"),
  Combinator(name:"K", argsCount:2, format:"{0}"),
  Combinator(name:"I", argsCount:1, format:"{0}"),
  Combinator(name:"B", argsCount:3, format:"{0}({1}{2})"),
  Combinator(name:"C", argsCount:3, format:"({0}{2}){1}"),
  Combinator(name:"T", argsCount:0, format:"K"),
  Combinator(name:"F", argsCount:0, format:"SK"),
] ## Builtin Combinators.

proc takeBracketCombinator(code: string): string =
  ## Returns head combinator.
  ## **Note:** You have to validate pairs of brackets before using this proc.
  ##
  ## **Japanese:**
  ##
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
  ## Returns head combinator.
  ## Returns the combinator when prefix combinator is defined in `cs`.
  ## Returns brackets enclosed in brackets when `code` starts with brackets.
  ## Or returns 1 char.
  ##
  ## **Japanese:**
  ##
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
  ## Returns combinator name, arguments that combinator needs and others.
  ## Returns empty arguments when head combinator is not defined in `cs`.
  ##
  ## **Japanese:**
  ##
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

  let joined = pref & args.join
  return (pref, args, code.substr joined.len)

proc calculateFormat(co: Combinator, args: openArray[string]): string =
  ## Returns calculated format.
  ##
  ## **Japanese:**
  ##
  ## コンビネータの変換書式に、引数を適用して返す。
  ## 引数が不足した場合は、コンビネータ名と引数を結合して返す。
  if args.len < co.argsCount:
    return co.name & args.join

  result = co.format
  for i in 0..<co.argsCount:
    let f = "{" & $i & "}"
    result = result.replace(f, args[i])

proc calculate1Time(code: string, cs: openArray[Combinator]): string =
  ## Returns result that calculated by 1 times.
  ##
  ## **Japanese:**
  ##
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
  result = co.calculateFormat(coTuple.args) & coTuple.suffix

proc calculate*(code: string, cs: openArray[Combinator], n: int = -1): string =
  ## Returns results of repeat calculation.
  ## Count of calculation is `n`.
  ## Calculate until `code` can not be calculated when `n` is `-1`.
  ##
  ## **Japanese:**
  ##
  ## 計算不能になるまでコンビネータ文字列を計算して返す。
  ## 計算不能、とは計算前と計算後の結果が一致する場合、または
  ## 指定した計算回数(n)分計算をした場合を指す。
  runnableExamples:
    doAssert "Sxyz".calculate(combinators) == "xz(yz)"
    doAssert "KKaxyz".calculate(combinators) == "xz"
    doAssert "KKaxyz".calculate(combinators, 1) == "Kxyz"
  var m = n
  if m == 0:
    return code
  if -1 < m:
    dec m
  let ret = code.calculate1Time cs
  if code == ret:
    return code
  result = ret.calculate(cs, m)

proc calculateSeq*(code: string, cs: openArray[Combinator], results: seq[string] = @[], n: int = -1): seq[string] =
  ## Returns process and results of repeat calculation.
  ## Count of calculation is `n`.
  ## Calculate until `code` can not be calculated when `n` is `-1`.
  ##
  ## **Japanese:**
  ##
  ## 計算不能になるまでコンビネータ文字列を計算して、計算過程とともに返す。
  ## 計算不能、とは計算前と計算後の結果が一致する場合、または
  ## 指定した計算回数(n)分計算をした場合を指す。
  runnableExamples:
    doAssert "Sxyz".calculateSeq(combinators) == @["xz(yz)"]
    doAssert "KKaxyz".calculateSeq(combinators) == @["Kxyz", "xz"]
    doAssert "KKaxyz".calculateSeq(combinators, n=1) == @["Kxyz"]
  var m = n
  if m == 0:
    return results
  if -1 < m:
    dec m
  let ret = code.calculate1Time cs
  if code == ret:
    return results
  var nr = results
  nr.add ret
  result = ret.calculateSeq(cs, nr, m)

iterator calculateIterator*(code: string, cs: openArray[Combinator], n: int = -1): string =
  ## Returns process and results of repeat calculation.
  ## Count of calculation is `n`.
  ## Calculate until `code` can not be calculated when `n` is `-1`.
  ##
  ## **Japanese:**
  ##
  ## 計算不能になるまでコンビネータ文字列を計算して、計算過程とともに返す。
  ## 計算不能、とは計算前と計算後の結果が一致する場合、または
  ## 指定した計算回数(n)分計算をした場合を指す。
  runnableExamples:
    var ret: seq[string]
    for r in "SKISxyz".calculateIterator(combinators):
      ret.add r
    doAssert ret == @["KS(IS)xyz", "Sxyz", "xz(yz)"]
  if n != 0:
    var m = n
    var code2 = code
    while m == -1 or 0 < m:
      let ret = code2.calculate1Time cs
      if code2 == ret:
        break
      yield ret
      code2 = ret
      if -1 < m:
        dec m