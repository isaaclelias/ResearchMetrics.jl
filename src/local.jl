"""
    localQuery(::String)::String

CURRENTLY WORKING ON
NOT TESTED
"""
function localQuery(query_type::String, query_string::String)::Union{String, Nothing}
    regex = Regex(query_type*".*"*queryID(query_string))
    what_we_have = readdir(api_query_folder)
    what_we_have = filter(s-> occursin(regex, s), what_we_have)
    if !isempty(what_we_have)
        sort!(what_we_have)
        fpath = api_query_folder*what_we_have[1]
        open(fpath, "r") do file
            @debug "Local query returned file" fpath
            return read(file, String)
        end
    else
        return nothing
    end 
end

"""
    queryKnownToFault(query_type::String, query_string::String)

TASKS:
- Regexing an entire file seems a very inneficient way of doing it
"""
function queryKnownToFault(query_type::String, query_string::String)::Bool
    fpath = "resources/known-to-fault"
    touch(fpath)
    open(fpath, "r") do file
        faulted_queries = read(file, String)
        if occursin(query_type*"-"*queryID(query_string), faulted_queries)
            @info "The query has failed previously" query_type*"-"*query_string
            return true
        else
            return false
        end
    end
end

function addQueryKnownToFault(query_type::String, query_string::String)::Nothing
    fpath = "resources/known-to-fault"
    touch(fpath)
    open(fpath, "a") do file
        write(file, query_type*"-"*queryID(query_string)*" "*"\"$query_string\""*"\n")
    end
    return nothing
end