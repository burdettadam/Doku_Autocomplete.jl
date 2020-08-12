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
    # first 3 rows must all ready be unique sub squares/blocks, this test foruth row is
    # complient tower addition. this fourth row is used to mapp symbols across floors. 
    for idx = [1,2,3,4,5,6,7,8,9]
        @inbounds fourth[idx] == third[idx] && return false
        @inbounds fourth[idx] == second[idx] && return false
        @inbounds fourth[idx] == first[idx] && return false
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

function generate_cypher_forth_row()
    first = ['A','B','C','D','E','F','G','H','I']
    row_permutations = Combinatorics.permutations(first) |> collect 
    row_permutations_size = length(row_permutations)
    sds = sudoku_cipher_text()
    ciphertext = Array{Tuple{Array{Char,1},Array{Tuple{Array{Char,1},Array{Array{Char,1},1}},1}},1}()
    @showprogress for idx = 1:12096 #for each valid second row
        @inbounds second = sds[idx][1]
        #println(second)
        thirds=[]
        for jdx in 1: length(sds[idx][2]) # for each valid third row
            @inbounds third = sds[idx][2][jdx]
            fourths = []
            for kdx in 1:row_permutations_size
                @inbounds fourth = row_permutations[kdx]
                if is_tower( first , second, third, fourth) # test possible fourth rows
                    push!(fourths,fourth)
                end
            end
            if !isempty(fourths)
                push!(thirds,(third,fourths))
            end
        end
        if !isempty(thirds)
            #println(thirds[1][1])
            push!(ciphertext,(second,thirds))
        end
    end
    println(length(ciphertext))
    key = "Sudoku_second_third_fourth_rows"
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

    origin = ["A","B","C","D","E","F","G","H","I"]

    tower_1 = []
    tower_2 = []
    tower_3 = []
    
    for j in [3,2,1]
        row_a = []
        row_b = []
        row_c = []
        for i in 1:9
            push!(row_a, puzzle[i][j])
            push!(row_b, puzzle[i][j+3])
            push!(row_c, puzzle[i][j+6])
        end
        push!(tower_1,row_a)
        push!(tower_2,row_b)
        push!(tower_3,row_c)
    end

    optimal_mapping = function(puzzle)
        #pick optimal arrangement of rows with in floor for mapping
        symbol_count = function(arr)
            count = 0
            for i = 1:length(arr)
                if arr[i] != 0
                    count += 1
                end
            end
            return count
        end

        floor_arrangement = Dict()

        for i in [1,4,7]
            optimal = symbol_count(puzzle[i])
            floor_arrangement[i]=i
            floor_arrangement[i+1]=i+1
            floor_arrangement[i+2]=i+2
            second_row = symbol_count(puzzle[i+1])
            if second_row > optimal
                floor_arrangement[i]=i+1
                floor_arrangement[i+1]=i
                floor_arrangement[i+2]=i+2
                optimal = second_row
            end
            third_row = symbol_count(puzzle[i+2])
            if third_row > optimal
                floor_arrangement[i]=i+2
                floor_arrangement[i+1]=i+1
                floor_arrangement[i+2]=i
                optimal = second_row
            end
        end
        return floor_arrangement
    end

    #pick optimal arrangement of rows with in tower for mapping
    floor_arrangement = optimal_mapping(puzzle)
    # println("floor_arrangement",floor_arrangement)
    tower_arrangement = optimal_mapping([tower_1..., tower_2..., tower_3...])
    # println("tower_arrangement",tower_arrangement)
    # create key mapping for most optimal row of each floor
    symbol_mapping = function(puzzle, arrangement)
        mapping = Dict()
        for i in [1,4,7]
            mapping[i]=Dict()
            for idx in [1,2,3,4,5,6,7,8,9]
                row_index = arrangement[i]
                if puzzle[row_index][idx] != 0 
                    mapping[i][puzzle[row_index][idx]] = origin[idx]
                end
            end
        end
        return mapping
    end

    row_mapping = symbol_mapping(puzzle, floor_arrangement)
    tower_mapping = symbol_mapping([tower_1..., tower_2..., tower_3...], tower_arrangement)

    # for idx in [1,2,3,4,5,6,7,8,9]
    #     if block_1[idx] != 0
    #         if haskey(row_1_mapping,block_1[idx])
    #             block_mapping[block_1[idx]] = row_1_mapping[block_1[idx]]
    #         elseif !(origin[idx] in values(row_1_mapping))
    #             block_mapping[block_1[idx]] = origin[idx]
    #         end
    #     end
    # end
    # floor regular expression

    for idx in [2,3,5,6,8,9]
        row_mapping[idx] = ["[^ABC]","[^ABC]","[^ABC]","[^DEF]","[^DEF]","[^DEF]","[^GHI]","[^GHI]","[^GHI]"]
        tower_mapping[idx] = [".",".",".",".",".",".",".",".","."]
    end

    floors_to_regex! = function(puzzle, mapping, arrangement)
        for idx in [1,2,3,4,5,6,7,8,9]
            for tidx = [(2,1),(3,1),(5,4),(6,4),(8,7),(9,7)]
                ridx , midx = tidx
                row_index = arrangement[ridx] 
                if puzzle[row_index][idx] != 0
                    if haskey(mapping[midx],puzzle[row_index][idx])
                        mapping[ridx][idx] = mapping[midx][puzzle[row_index][idx]]
                    else
                        mapped_digits = values(mapping[midx])
                        if !isempty(mapped_digits)
                            mapping[ridx][idx] = join(["[^", values(mapping[midx])..., "]"])
                        end
                    end
                end
            end
        end
    end

    floors_to_regex!(puzzle,row_mapping,floor_arrangement)
    floors_to_regex!([tower_1..., tower_2..., tower_3...],tower_mapping,tower_arrangement)

    floor_regs = Dict()
    tower_regs = Dict()

    for idx in [2,3,5,6,8,9]
        floor_regs[idx] = Regex(join(row_mapping[idx]))
        tower_regs[idx] = Regex(join(tower_mapping[idx]))
    end

    possible_floors = Dict()
    possible_towers = Dict()

    for idx in [2,5,8]
        possible_floors[idx] = Array{Tuple{Array{Char,1},Array{Char,1}},1}()
        possible_towers[idx] = Array{Tuple{Array{Char,1},Array{Char,1}},1}()
    end

    for idx in 1:12096 #length(sds)
        ex = join(sds[idx][1])
        for fdx in [2,5,8]
            if occursin(floor_regs[fdx], ex) 
                for kdx in 1: length(sds[idx][2])
                    ex_ = join(sds[idx][2][kdx])
                    if occursin(floor_regs[fdx+1],ex_)
                        push!(possible_floors[fdx],(sds[idx][1],sds[idx][2][kdx]))
                    end
                end
            end
#=             if occursin(tower_regs[fdx], ex) 
                for kdx in 1: length(sds[idx][2])
                    ex_ = join(sds[idx][2][kdx])
                    if occursin(tower_regs[fdx+1],ex_)
                        push!(possible_towers[fdx],(sds[idx][1],sds[idx][2][kdx]))
                    end
                end
            end =#
        end
    end
    possible_blocks = []

    #= for idx in 1:length(possible_floors[2])
        block_1=[
            "A","B","C",
            possible_floors[2][idx][1][1:3]...,
            possible_floors[2][idx][2][1:3]...
        ]
        blk1mapping = Dict()
        for row_index in 1:3
            for idx in [1,2,3]
                if puzzle[row_index][idx] != 0 
                    blk1mapping[puzzle[row_index][idx]] = block_1[idx]
                end
            end
        end
        block_2=[
            puzzle[4][1:3]...,
            puzzle[5][1:3]...,
            puzzle[6][1:3]...,
        ]

        blk2mapping = Dict()
        for idx in [1,2,3,4,5,6,7,8,9]
            if block_2[idx] != 0
                if haskey(blk1mapping,block_2[idx])
                    blk2mapping[idx] = blk1mapping[block_2[idx]]
                else
                    mapped_digits = values(blk1mapping)
                    if !isempty(mapped_digits)
                        blk2mapping[idx] = join(["[^", values(blk1mapping)..., "]"])
                    end
                end
            end
        end

        block_3=[
            puzzle[7][1:3]...,
            puzzle[8][1:3]...,
            puzzle[9][1:3]...,
        ]

        blk3mapping = Dict()
        for idx in [1,2,3,4,5,6,7,8,9]
            if block_3[idx] != 0
                if haskey(blk1mapping,block_3[idx])
                    blk3mapping[idx] = blk1mapping[block_3[idx]]
                else
                    mapped_digits = values(blk1mapping)
                    if !isempty(mapped_digits)
                        blk3mapping[idx] = join(["[^", values(blk1mapping)..., "]"])
                    end
                end
            end
        end
        block2_regs = Regex(join(blk2mapping))
        block3_regs = Regex(join(blk3mapping))
        for idx in 1:12096 
            ex = join(sds[idx][1])
                if occursin(block2_regs, ex) 
                    for kdx in 1: length(sds[idx][2])
                        ex_ = join(sds[idx][2][kdx])
                        if occursin(block3_regs,ex_)
                            push!(possible_blocks,(sds[idx][1],sds[idx][2][kdx]))
                        end
                    end
                end
        end

    end
 =#    
    #println(length(possible_blocks))
    
    println(length(possible_floors[2]))
    println(length(possible_floors[5]))
    println(length(possible_floors[8]))
    println("")
#=     println(length(possible_towers[2]))
    println(length(possible_towers[5]))
    println(length(possible_towers[8]))
    println("") =#
    return puzzle
end

#sudoku_cipher_text()
generate_cypher_forth_row()