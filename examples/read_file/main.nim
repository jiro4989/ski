import ski
from streams import newFileStream, lines
import json

# Define combinators from JSON file
let combinators = readFile("combinators.json").parseJson.to(seq[Combinator])

# Read and calculate from text file
let strm = newFileStream("in.txt")
for line in strm.lines:
  echo line
  for ret in line.calculateAndResults(combinators):
    echo "  -> " & ret
strm.close
