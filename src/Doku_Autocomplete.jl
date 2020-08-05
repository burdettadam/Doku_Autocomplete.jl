module Doku_Autocomplete

using Combinatorics
using ProgressMeter
using JLD

include("Encoding.jl")
include("Sudoku_Cypher.jl")

export doku_encode_map, doku_decode_map, doku_encode, doku_decode, 
        sudoku_cipher_text, sudoku_autocomplete

end
