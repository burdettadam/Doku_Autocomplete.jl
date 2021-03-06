using Doku_Autocomplete
using Test
using Combinatorics
using ProgressMeter

include("solved_Sudokus.jl")

@testset "encode/decode symbols" begin
encoding = doku_encode_map()
decoding = doku_decode_map()
char = 33
@showprogress for combo in Combinatorics.permutations(['A','B','C','D','E','F','G','H','I'],3)
    sub = join(combo)
    key = Char(char)
    #@test haskey(decoding,key)
    @test haskey(encoding,sub)
    char += 1
    end
end

@testset "row encoding" begin

    first = ['A','B','C','D','E','F','G','H','I']
    row_permutations = Combinatorics.permutations(first) |> collect 
    row_permutations_size = length(row_permutations)
    @test row_permutations_size == 362880
    @showprogress for i = 1:row_permutations_size
        @inbounds row = row_permutations[i]
            encoded_row = doku_encode(row)
            @test length(encoded_row) < length(row)
            decoded_row = doku_decode(encoded_row)
            @test decoded_row == row
    end
end

@testset "Doku_Autocomplete.jl" begin
    @test length(sfds) == 12096
    unknowns = ['C','F','G']
    regex_trio = "HI(?<C>[^AEHBID])B.E(?<G>[^AEHBID])DA[^AEHBID].BEA.I.D" #second row with unknowns
    possible_trio_columns = [
        ("HIGBCEFDA", "CFBEAHIGD"),
        ("HIGBCEFDA", "CGBEAHIFD"),
        ("HIGBFECDA", "FCBEAHIGD"),
        ("HIGBFECDA", "FGBEAHICD")
        ]
    fixed_unkowns_index = Dict(['G'=>[(1,3)]])
    satisfide = overlapping_tiles(unknowns, possible_trio_columns)
    @test keys(satisfide) == keys(fixed_unkowns_index)
    for index in 1:length(hard_puzzle)
        sudoku_autocomplete(hard_puzzle[index],sfds,stds)
    end

end
