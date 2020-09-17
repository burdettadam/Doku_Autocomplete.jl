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

function is_block_tower(first::Array{Char,1}, second::Array{Char,1})
    for idx in [1,2,3]
        for jdx in [idx,idx+3,idx+6]
            @inbounds second[idx] == first[jdx] && return false # fourth row check
        end
    end
    for idx in [4,5,6]
        for jdx in [idx-3,idx,idx+3]
            @inbounds second[idx] == first[jdx] && return false 
        end
    end
    for idx in [7,8,9]
        for jdx in [idx-6,idx-3,idx]
            @inbounds second[idx] == first[jdx] && return false 
        end
    end
    true
end

function is_soduko_block_tower(first::Array{Char,1}, second::Array{Char,1}, third::Array{Char,1})
    #= first and second must be valid tower blocks=#
    for idx in [1,2,3]
        for jdx in [idx,idx+3,idx+6]
            @inbounds third[idx] == first[jdx] && return false 
            @inbounds third[idx] == second[jdx] && return false 
        end
    end
    for idx in [4,5,6]
        for jdx in [idx-3,idx,idx+3]
            @inbounds third[idx] == first[jdx] && return false 
            @inbounds third[idx] == second[jdx] && return false 
        end
    end
    for idx in [7,8,9]
        for jdx in [idx-6,idx-3,idx]
            @inbounds third[idx] == first[jdx] && return false 
            @inbounds third[idx] == second[jdx] && return false 
        end
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

function generate_sudoku_floor_tower()
    sds = sudoku_cipher_text() # second_row : [third_rows]
    for idx in 1:12096 #length(sds) # for every possible sudoku second/third pairs
        sds[idx][1]
        if occursin(regex[1], ex) # first row
            Print(here,)
            for kdx in 1: length(sds[idx][2])
                ex_ = join(sds[idx][2][kdx]) # for every coupled pair
                if occursin(regex[2],ex_) # second row
                    push!(possible_rows[1],(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
        if occursin(regex_t[1], ex) # first column
            for kdx in 1: length(sds[idx][2])
                ex_ = join(sds[idx][2][kdx]) # for every coupled pair
                if occursin(regex_t[2],ex_) # second column
                    push!(possible_columns[1],(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
        if occursin(regex[9], ex) # last row
            for kdx in 1: length(sds[idx][2])
                ex_ = join(sds[idx][2][kdx]) # for every coupled pair
                if occursin(regex[8],ex_) # second row
                    push!(possible_rows[9],(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
        if occursin(regex_t[9], ex) # last column
            for kdx in 1: length(sds[idx][2])
                ex_ = join(sds[idx][2][kdx]) # for every coupled pair
                if occursin(regex_t[8],ex_) # second column
                    push!(possible_columns[9],(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
    end
end

function generate_cypher()
    first = ['A','B','C','D','E','F','G','H','I']
    row_permutations = Combinatorics.permutations(first) |> collect 
    row_permutations_size = length(row_permutations)
    #println(row_permutations_size)
    ciphertext = Array{Tuple{String,Array{String,1}},1}()
    #ciphertext = Trie()
    @showprogress for i = 1:row_permutations_size # for every possible 2nd row
        @inbounds second = row_permutations[i]
        thirds = []
        if  is_duko(first , second)
            for j = 1:row_permutations_size # for every possible 3rd row
                @inbounds third = row_permutations[j]
                if is_soduko( first , second, third)
                    #word = join(second)*join(third)
                    push!(thirds,join(third))
                end
            end
        end
        if !isempty(thirds)
            push!(ciphertext,(join(second),thirds))
        end
    end
    println(length(ciphertext))
    key = "Sudoku_second_third_rows_strs"
    save(joinpath(@__DIR__,join([key,".jld"])), key, ciphertext)
    println("------------ completed ------------")
end

function generate_cypher_block_towers()
    first_block = ['A','B','C','D','E','F','G','H','I']
    row_permutations = Combinatorics.permutations(first_block) |> collect 
    row_permutations_size = length(row_permutations)
    #println(row_permutations_size)
    ciphertext = Array{Tuple{String,Array{String,1}},1}()
    #ciphertext = Trie()
    @showprogress for i = 1:row_permutations_size # for every possible 2nd row
        @inbounds second_block = row_permutations[i]
        third_blocks = []
        if  is_block_tower(first_block , second_block)
            for j = 1:row_permutations_size # for every possible 3rd row
                @inbounds third_block = row_permutations[j]
                if is_soduko_block_tower( first_block , second_block, third_block)
                    push!(third_blocks,join(third_block))
                end
            end
        end
        if !isempty(third_blocks)
            push!(ciphertext,(join(second_block),third_blocks))
        end
    end
    println(length(ciphertext))
    key = "Sudoku_second_third_block_tower"
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

function sudoku_cipher_text()::Array{Tuple{String,Array{String,1}},1}
    sudokuCipherText = Array{Tuple{Array{Char,1},Array{Array{Char,1},1}},1}()
    try#todo: if load fails raise error or generate_cypher
        println("loading Sudoku Floor Data Structure")
        _sudokuCipherText = load(joinpath(@__DIR__,"Sudoku_Floor_Data_Structure.jld"))
        sudokuCipherText = _sudokuCipherText["Sudoku_second_third_rows_strs"]
        #Todo: actually check if loaded correctly
        #println(length(sudokuCipherText))
        println("Sudoku Floor Data Structure loaded successfully")
    catch e
        println("Sudoku DataStructure failed to load, please run Sudoku generater")
        println(e)
        #generate_cypher()# takes around 12 minutes on a mac pro
    end
    return sudokuCipherText
end

function strs_to_chars!(strs)
    for i =1:length(strs)
        strs[i] = strs[i][1]
    end
end

function unique_floor_candidate(possible_words)
    satisfide = [true,true,true,true,true,true,true,true,true,
    true,true,true,true,true,true,true,true,true]
    for idx = 2:length(possible_words) # find all satisfide possitions
        for jdx = 1:9
            (possible_words[idx][1][jdx] != possible_words[idx-1][1][jdx]) && (satisfide[jdx] = false)
            (possible_words[idx][2][jdx] != possible_words[idx-1][2][jdx]) && (satisfide[9+jdx] = false)
        end
    end
        return satisfide
end

function overlapping_tiles(unknowns, possible_words)::Dict{Char,Array} # single elimination
    #= 
    given a list of unkown variables and a list of possible second and third rows, 
    return a dictionary of known variables and the index of the cell in the word with the value.
    satisfiability exposes variables that are determined by the pattern in the first/second row words. 
    =#
    strs_to_chars!(unknowns)

    discovered = Dict{Char,Array}()
    satisfide = unique_floor_candidate(possible_words)
    # find all unknowns that are satisfiable
    for idx in 1:length(unknowns)
        for jdx in 1:9
            if unknowns[idx] == possible_words[1][1][jdx] && satisfide[jdx]
                if !haskey(discovered,unknowns[idx])
                    discovered[unknowns[idx]]=[]
                end
                push!(discovered[unknowns[idx]], (1,jdx))
            end
            if unknowns[idx] == possible_words[1][2][jdx] && satisfide[9+jdx]
                if !haskey(discovered,unknowns[idx])
                    discovered[unknowns[idx]]=[]
                end
                push!(discovered[unknowns[idx]], (2,jdx))
            end
        end
    end
    return discovered
end

function satisfide_varibles(unknowns, possible_words)::Dict{Char,Set}
    #= 
    =#
    strs_to_chars!(unknowns) #statdardize input as chars



#=     discovered = Dict{Char,Set}()
    for idx = 1:length(unknowns)
        for word in possible_words
            for jdx = 1:9
                if unknowns[idx] == word[1][jdx]
                    if !haskey(discovered,unknowns[idx])
                        discovered[unknowns[idx]]=Set()
                    end
                    push!(discovered[unknowns[idx]], (1,jdx))
                end
                if unknowns[idx] == word[2][jdx]
                    if !haskey(discovered,unknowns[idx])
                        discovered[unknowns[idx]]=Set()
                    end
                    push!(discovered[unknowns[idx]], (2,jdx))
                end
            end
        end
    end
    return discovered =#
end

function sudoku_tower_data_structure()::Array{Tuple{String,Array{String,1}},1}
    sudokuCipherText = Array{Tuple{Array{Char,1},Array{Array{Char,1},1}},1}()
    try#todo: if load fails raise error or generate_cypher
        println("loading Sudoku Tower Data Structure")
        _sudokuCipherText = load(joinpath(@__DIR__,"Sudoku_Tower_Data_Structure.jld"))
        sudokuCipherText = _sudokuCipherText["Sudoku_second_third_block_tower"]
        #Todo: actually check if loaded correctly
        #println(length(sudokuCipherText))
        println("Sudoku Tower Data Structure loaded successfully")
    catch e
        println("Sudoku DataStructure failed to load, please run Sudoku generater")
        println(e)
        #generate_cypher_block_towers()# takes around 8 minutes on a mac pro
    end
    return sudokuCipherText
end

function floors_to_regex(puzzle)

    origin = ["A","B","C","D","E","F","G","H","I"]
    mappings = symbol_mapping(puzzle, origin)
    mapping = mappings[1]
    unknowns = mappings[2]

    # floor regular expression
    for idx in [2,3,5,6,8,9]
        mapping[idx] = [".",".",".",".",".",".",".",".","."]
    end

    for tidx = [(2,1),(5,4),(8,7)] # for each first row and mapping index
        ridx , midx = tidx
        for idx in [1,2,3,4,5,6,7,8,9] # for every symbol
            if puzzle[ridx][idx] != 0
                if haskey(mapping[midx],puzzle[ridx][idx])
                    mapping[ridx][idx] = mapping[midx][puzzle[ridx][idx]]
                else
                    mapped_digits = values(mapping[midx])
                    if !isempty(mapped_digits)
                        mapping[ridx][idx] = join(["(?<",origin[idx],">","[^", values(mapping[midx])..., "])"])
                    else # incase of completly empty row
                        mapping[ridx][idx] = join(["(?<",origin[idx],">",".",")"])# todo: optimize this
                    end
                end
            end
        end
    end
    for tidx = [(3,1),(6,4),(9,7)] # for each second row and mapping index
        ridx , midx = tidx
        for idx in [1,2,3,4,5,6,7,8,9] # for every symbol
            if puzzle[ridx][idx] != 0
                if haskey(mapping[midx],puzzle[ridx][idx])
                    mapping[ridx][idx] = mapping[midx][puzzle[ridx][idx]]
                else
                    seen = false
                    for jdx = 1:9
                        if puzzle[ridx-1][jdx] == puzzle[ridx][idx]
                            mapping[ridx][idx] = join(["\\g<",origin[jdx],">"])
                            seen = true
                            break
                        end
                    end 
                    if !seen
                        mapped_digits = values(mapping[midx])
                        if !isempty(mapped_digits)
                            mapping[ridx][idx] = join(["[^", values(mapping[midx])..., "]"])
                            #mapping[ridx][idx] = join(["(?<",origin[idx],">[^", values(mapping[midx])..., "])"])
                        end
                    end
                end
            end
        end
    end

    floor_regs = Dict()
    floor_word_regs = Dict()

    for idx in [2,5,8]
        floor_regs[idx] = Regex(join(mapping[idx]))
    end

    for idx in [2,5,8]
        floor_word_regs[idx] = Regex(join([mapping[idx]...,mapping[idx+1]...]))
    end

    return floor_regs, floor_word_regs, mapping, unknowns

end

function symbol_mapping(puzzle, origin)
    # create key mapping for row of each floor
    mapping = Dict()
    unknowns = [[],[],[],[],[],[],[],[],[]]
    for i in [1,4,7]
        mapping[i]=Dict()
        for idx in [1,2,3,4,5,6,7,8,9]
            if puzzle[i][idx] != 0 
                mapping[i][puzzle[i][idx]] = origin[idx]
            else
                push!(unknowns[i], origin[idx])
            end
        end
    end
    return mapping,unknowns
end

function reduce_satifide_patterns(sfds, stds, floor_regs, floor_word_regs, tower_regs, tower_word_regs )# todo: better names
    possible_floors = Dict()
    possible_towers = Dict()

    for idx in [2,5,8]
        possible_floors[idx] = Array{Tuple{String,String},1}()
        possible_towers[idx] = Array{Tuple{String,String},1}()
    end

    for idx in 1:12096 #length(sds)
        ex = sfds[idx][1]
        ex_t = stds[idx][1]
        for fdx in [2,5,8]
            if occursin(floor_regs[fdx], ex) 
                for kdx in 1: length(sfds[idx][2])
                    ex_ = ex * sfds[idx][2][kdx]
                    if occursin(floor_word_regs[fdx],ex_)
                        push!(possible_floors[fdx],(sfds[idx][1],sfds[idx][2][kdx]))
                    end
                end
            end
            if occursin(tower_regs[fdx], ex_t) 
                for kdx in 1: length(stds[idx][2])
                    ex_ =  ex_t * stds[idx][2][kdx]
                    if occursin(tower_word_regs[fdx],ex_)
                        push!(possible_towers[fdx],(stds[idx][1],stds[idx][2][kdx]))
                    end
                end
            end
        end
    end
    return possible_floors, possible_towers
end

function sudoku_autocomplete(puzzle::Array{Array{Int64,1},1},sfds::Array{Tuple{String,Array{String,1}},1},stds::Array{Tuple{String,Array{String,1}},1})
    # build partial mapping for cypher from first row, example, 4 => B, 5=>c.
    # then use this mapping to generate regular expression for second row and third row


    puzzle_t = Array{Array{Int64,1},1}()
    for hdx in [0,3,6] # tower
        block_1 = Array{Int64,1}()
        block_2 = Array{Int64,1}()
        block_3 = Array{Int64,1}()
        for idx in [1,2,3] # block rows
            for jdx in [1,2,3] # block columns
                push!(block_1,puzzle[idx + 0][jdx + hdx])
                push!(block_2,puzzle[idx + 3][jdx + hdx])
                push!(block_3,puzzle[idx + 6][jdx + hdx])
            end
        end 
        push!(puzzle_t,block_1)
        push!(puzzle_t,block_2)
        push!(puzzle_t,block_3)
    end
    for i in [1,2,3,4]

        # Todo: optimize, combine rows and columns to reduce for loops
        floor_regs, floor_word_regs, row_mapping, row_unknowns = floors_to_regex(puzzle)
        tower_regs, tower_word_regs, tower_mapping, tower_unknowns = floors_to_regex(puzzle_t)

        possible_floors, possible_towers = reduce_satifide_patterns(sfds, stds, floor_regs, floor_word_regs, tower_regs, tower_word_regs)
        
        function update_sole_candidates!(second_row, third_row ,sole_floors, possible_floors, row_mapping)
            for jdx = 1:9
                if sole_floors[jdx]
                    _first_row = possible_floors[1][1]
                    println("first_row ", first_row)
                    println("first_row[idx] ", first_row[jdx])
                    key = ""
                    for (k,v) in row_mapping
                        println("v ", v, "k ", k)
                        if v == _first_row[jdx]
                            key = k
                            break
                        end
                    end
                    println(_first_row[jdx])
                    println(second_row)
                    println(second_row[jdx])
                    println(key)
                    second_row[jdx] = key
                end
                if jdx + 1 < 10 && sole_floors[9 + jdx]
                    _second_row = possible_floors[1][2]
                    println("second_row ", _second_row)
                    println("second_row[idx] ", _second_row[jdx])
                    third_row[jdx+1] = [ k for (k,v) in row_mapping if v == second_row[jdx] ]
                end
            end
        end

        for idx in [2,5,8]
            sole_floors = unique_floor_candidate(possible_floors[idx])
            println("sole_floors")
            println(sole_floors)
            println(possible_floors[2])
            update_sole_candidates!(puzzle[idx], puzzle[idx + 1], sole_floors, possible_floors[idx], row_mapping[idx-1])
            sole_towers = unique_floor_candidate(possible_towers[idx])
            update_sole_candidates!(puzzle_t[idx], puzzle_t[idx + 1], sole_towers, possible_towers, tower_mapping[idx-1])
        end
        println("puzzle ", puzzle)
        println("puzzle_t ", puzzle_t)
        println("Mapping ", row_mapping)
        println(length(possible_floors[2]))
        #= println(possible_floors[2][1])
        println(possible_floors[2][2]) =#

        #frist_row_sat =   satisfide_varibles(row_unknowns[1]  ,possible_floors[2])
        #println("1st row satisfiable variables",frist_row_sat)
        #println("1st row satisfiable variables",keys(frist_row_sat))
        #println("1st row satisfide possitions",values(frist_row_sat))

        println(length(possible_floors[5]))
        #= println(possible_floors[5][1])
        println(possible_floors[5][2]) =#

        fourth_row_sat =  overlapping_tiles(row_unknowns[4]  ,possible_floors[5])
        println("4th row satisfide", keys(fourth_row_sat))

        println(length(possible_floors[8]))
        #= println(possible_floors[8][1])
        println(possible_floors[8][2])
    =#
        seventh_row_sat = overlapping_tiles(row_unknowns[7]  ,possible_floors[8])
        println("7th row satisfide",keys(seventh_row_sat))
        println("sole floor cannidates", unique_floor_candidate(possible_floors[8]))

        println("")

        println(length(possible_towers[2]))
        #= println(possible_towers[2][1])
        println(possible_towers[2][2])
        println(possible_towers[2][3])
        println(possible_towers[2][4]) =#

        #println("tower unknowns", tower_unknowns[1], "satisfiable rows ",possible_towers[2])
        #first_tower_sat = satisfide_varibles(tower_unknowns[1],possible_towers[2])
        #println("1st tower satisfiable variables",first_tower_sat)
        #println("1st tower satisfiable variables",keys(first_tower_sat))
        #println("1st tower satisfide possitions",values(first_tower_sat))

        tower_sat = overlapping_tiles(tower_unknowns[4],possible_towers[5])
        println("4th tower satisfide",keys(tower_sat))
        tower_sat = overlapping_tiles(tower_unknowns[7],possible_towers[8])
        println("7th tower satisfide",keys(tower_sat))

    #=     println(length(possible_towers[5]))
        println(length(possible_towers[8]))
    =#
        println("")
    end
    return puzzle
end

#= function sudoku_autocomplete(_puzzle::Array{Array{Int64,1},1} ,sds::Array{Tuple{Array{Char,1},Array{Array{Char,1},1}},1})
    #= 
    stratigie: given a puzzle and Sudoku Data Structure, transpose first, second, eighth and ninth columns. Convert transpose columns and rows 
    first, second, eight and ninth into regular expressions using provided hints. Search Sudoku data structure using regular 
    expressions to find possible column and row pairs. reduce possible column and row pairs to only pairs where the begining 
    and end match, the intersection of each corner. transpose third and seventh columns, then convert third and seventh columns/rows 
    to regular expressions. find all possible pairs of second and third, eighth and seventh, reduce on pairs where first second and 
    seventh and ninth are valid pairs in Sudoku data structure. Reduce possible third and eighth by intersection of Sudoku corner blocks.
    at this point, the first and last floor/tower with the four edge blocks has all possible solution. for each solved possible 
    tower/floor, find the center 3 rows/columns using the same algorithm as above.
    =#

    origin = Dict(0=>".",1=>"A",2=>"B",3=>"C",4=>"D",5=>"E",6=>"F",7=>"G",8=>"H",9=>"I")

    # make copy of puzzle, convert to Alphabet sudoku
    puzzle = Array{Array{String,1},1}(undef,9)
    puzzle_t = Array{Array{String,1},1}(undef,9)
    for i = 1:9
        puzzle[i] = ["","","","","","","","",""]
        puzzle_t[i] = ["","","","","","","","",""]
    end

    for idx in 1:9
        for jdx in 1:9
            puzzle[idx][jdx] = origin[_puzzle[idx][jdx]]
            # transpose puzzle
            puzzle_t[jdx][idx] = puzzle[idx][jdx]
        end
    end

    # create regular expressions
    regex = Array{Regex,1}(undef,9)
    regex_t = Array{Regex,1}(undef,9)
    
    for row in 1:9        
            regex[row] = Regex( join(puzzle[row]) )
            regex_t[row] = Regex( join(puzzle_t[row]) )
            println(regex[row])
            println(regex_t[row])
    end


    possible_rows = Dict()
    possible_columns = Dict()

    for idx = 1:9
        possible_rows[idx] = Array{Tuple{Array{Char,1},Array{Char,1}},1}()
        possible_columns[idx] = Array{Tuple{Array{Char,1},Array{Char,1}},1}()
    end

    for idx in 1:12096 #length(sds) # for every possible sudoku pairs
        ex = join(sds[idx][1])
        if occursin(regex[1], ex) # first row
            Print(here,)
            for kdx in 1: length(sds[idx][2])
                ex_ = join(sds[idx][2][kdx]) # for every coupled pair
                if occursin(regex[2],ex_) # second row
                    push!(possible_rows[1],(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
        if occursin(regex_t[1], ex) # first column
            for kdx in 1: length(sds[idx][2])
                ex_ = join(sds[idx][2][kdx]) # for every coupled pair
                if occursin(regex_t[2],ex_) # second column
                    push!(possible_columns[1],(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
        if occursin(regex[9], ex) # last row
            for kdx in 1: length(sds[idx][2])
                ex_ = join(sds[idx][2][kdx]) # for every coupled pair
                if occursin(regex[8],ex_) # second row
                    push!(possible_rows[9],(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
        if occursin(regex_t[9], ex) # last column
            for kdx in 1: length(sds[idx][2])
                ex_ = join(sds[idx][2][kdx]) # for every coupled pair
                if occursin(regex_t[8],ex_) # second column
                    push!(possible_columns[9],(sds[idx][1],sds[idx][2][kdx]))
                end
            end
        end
    end

    println("possible 1/2 row ",length(possible_rows[1]))
    println("possible 1/2 column ",length(possible_columns[1]))
    println("possible 9/8 row ",length(possible_rows[9]))
    println("possible 9/8 column ",length(possible_columns[9]))

end =#
sfds = sudoku_cipher_text()
stds = sudoku_tower_data_structure()
#generate_cypher_forth_row()
#generate_cypher()
#generate_cypher_block_towers()