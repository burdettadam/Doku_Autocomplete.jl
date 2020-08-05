using Combinatorics
using ProgressMeter
using DataStructures
using JLD

function unique(a::Array{Char,1},b::Array{Char,1})
    # check if there is any duplicates
    for i = 1:3
        @inbounds in(b[i],a) && return false
    end
    true
end

function unique_sub(a::Array{Char,1},b::Array{Char,1},c::Array{Char,1})
    # check if there is any duplicates
    for i = 1:3
        @inbounds in(c[i],a) && return false
        @inbounds in(c[i],b) && return false
    end
    true
end

function is_duko(a::Array{Char,1},b::Array{Char,1})
    # unique row is given, we must test sub squares for
    # uniqueness, no repeating values.
    for idx in [1,4,7]
        @inbounds ta = a[idx:idx + 2] 
        @inbounds tb = b[idx:idx + 2]
        !unique(ta,tb) && return false
    end
    true
end

function is_soduko(a::Array{Char,1},b::Array{Char,1},c::Array{Char,1})
    # unique row is given, we must test sub squares for
    # uniqueness, no repeating values.
    for idx in [1,4,7]
        @inbounds ta = a[idx:idx + 2] 
        @inbounds tb = b[idx:idx + 2]
        @inbounds tc = c[idx:idx + 2]
        !unique_sub(ta,tb,tc) && return false
    end
    true
end

function is_tower(first::Array{Char,1}, second::Array{Char,1}, third::Array{Char,1}, fourth::Array{Char,1})
    for idx = [1,2,3,4,5,6,7,8,9]
        fourth[idx] == third[idx] && return false
        fourth[idx] == second[idx] && return false
        fourth[idx] == first[idx] && return false
    end
    true
end

function is_tall_tower(first::Array{Char,1}, second::Array{Char,1}, third::Array{Char,1}, fourth::Array{Char,1}, fifth::Array{Char,1}, sixth::Array{Char,1}, seventh::Array{Char,1})
    for idx = [1,2,3,4,5,6,7,8,9]
        seventh[idx] == sixth[idx] && return false
        seventh[idx] == fifth[idx] && return false
        seventh[idx] == fourth[idx] && return false
        seventh[idx] == third[idx] && return false
        seventh[idx] == second[idx] && return false
        seventh[idx] == first[idx] && return false
    end
    true
end



function generate_cypher()
    first = ['A','B','C','D','E','F','G','H','I']
    row_permutations = Combinatorics.permutations(first) |> collect 
    row_permutations_size = length(row_permutations)
    #println(row_permutations_size)
    ciphertext = Array{Tuple{Array{Char,1},Array{Array{Char,1},1}},1}()
    #ciphertext = Trie()
    @showprogress for i = 1:row_permutations_size # for every possible 2nd row
        @inbounds second = row_permutations[i]
        thirds = []
        if  is_duko(first , second)
            for j = 1:row_permutations_size # for every possible 3rd row
                @inbounds third = row_permutations[j]
                if is_soduko( first , second, third)
                    #word = join(second)*join(third)
                    push!(thirds,third)
                end
            end
        end
        if !isempty(thirds)
            push!(ciphertext,(second,thirds))
        end
    end
    println(length(ciphertext))
    key = "Sudoku_second_third_rows"
    save(joinpath(@__DIR__,join([key,".jld"])), key, ciphertext)
    println("------------ completed ------------")
end

function sudoku_cipher_text()::Array{Tuple{Array{Char,1},Array{Array{Char,1},1}},1}
    sudokuCipherText = Array{Tuple{Array{Char,1},Array{Array{Char,1},1}},1}()
    try#todo: if load fails raise error or generate_cypher
        println("loading Sudoku Data Structure")
        _sudokuCipherText = load(joinpath(@__DIR__,"Sudoku_second_third_rows.jld"))
        sudokuCipherText = _sudokuCipherText["Sudoku_second_third_rows"]
        #Todo: actually check if loaded correctly
        #println(length(sudokuCipherText))
        println("Sudoku Data Structure loaded successfully")
    catch e
        println("Sudoku DataStructure failed to load, please run Sudoku generater")
        println(e)
        #generate_cypher()# takes around 19 minutes on a mac pro
    end
    return sudokuCipherText
end

function sudoku_autocomplete(puzzle::Array{Array{Int64,1},1},sds::Array{Tuple{Array{Char,1},Array{Array{Char,1},1}},1})
    # build partial mapping for cypher from first row, example, 4 => B, 5=>c.
    # then use this mapping to generate regular expression for second row and third row
    mapping = Dict()
    origin = ['A','B','C','D','E','F','G','H','I']
    # first floor ---------------------------------
    for idx in [1,2,3,4,5,6,7,8,9]
        if puzzle[1][idx] != 0 # is a hint of the pattern used
            mapping[puzzle[1][idx]] = origin[idx]
        end
    end
    # floor regular expression
    second = ['.','.','.','.','.','.','.','.','.']
    third = ['.','.','.','.','.','.','.','.','.']
    for idx in [1,2,3,4,5,6,7,8,9]
        if puzzle[2][idx] != 0
            if haskey(mapping,puzzle[2][idx])
                second[idx] = mapping[puzzle[2][idx]]
            end
        end
        if puzzle[3][idx] != 0
            if haskey(mapping,puzzle[3][idx])
                third[idx] = mapping[puzzle[3][idx]]
            end
        end
    end
    second_regx = Regex(join(second))
    third_regx = Regex(join(third))
    possible_floors = Array{Tuple{Array{Char,1},Array{Char,1}},1}()
    for idx in 1:12096 #length(sds)
        if occursin(second_regx,join(sds[idx][1]))
            for kdx in 1: length(sds[idx][2])
                if occursin(third_regx,join(sds[idx][2][kdx]))
                    println("4 ",(sds[idx][1],sds[idx][2][kdx]))
                    push!(possible_floors,(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
    end
    println(length(possible_floors))
    return puzzle
end

#sudoku_cipher_text()
