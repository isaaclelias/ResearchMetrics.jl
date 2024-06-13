function _uniqueidentifierSHA(unique_identifier::String)::String
    query_sha = first(bytes2hex(sha256(unique_identifier)), sha_length)
end
@deprecate queryID(query_string::String) _uniqueidentifierSHA(query_string)

"""
    _savequery(query_type, query_string, response)

- `query_type`: internal name of the query
"""
function _savequery(query_type::AbstractString, query_string::AbstractString, response::AbstractString)::Nothing
    fname = query_type*"_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*"_"*_uniqueidentifierSHA(query_string)*".json"
    fpath = api_query_folder*fname
    touch(fpath)
    open(fpath, "w") do file
        write(file, response)
        @debug "Query saved to disk" query_type query_string fpath
    end
    return nothing
end
@deprecate saveQuery(query_type::String, query_string::String, response::String) _savequery(query_type, query_string, response)

function _localquery(query_type::String, query_string::String)::Union{String, Nothing}
    regex = Regex(query_type*".*"*_uniqueidentifierSHA(query_string))
    what_we_have = readdir(api_query_folder)
    what_we_have = filter(s-> occursin(regex, s), what_we_have)
    if !isempty(what_we_have)
        sort!(what_we_have)
        fpath = api_query_folder*what_we_have[1]
        open(fpath, "r") do file
            @debug "Local query returned file" query_type query_string fpath
            return read(file, String)
        end
    else
        deb_localquerynotfound && @debug "_localquery\nQuery not found locally" query_type query_string
        return nothing
    end 
end
@deprecate localQuery(query_type, query_string) _localquery(query_type, query_string)

function _isqueryknowntofail(query_type::String, query_string::String)::Bool
    fpath = "resources/known-to-fault"
    touch(fpath)
    open(fpath, "r") do file
        faulted_queries = read(file, String)
        if occursin(query_type*"-"*_uniqueidentifierSHA(query_string), faulted_queries)
            @debug "The query has failed previously" query_type*"-"*query_string
            return true
        else
            return false
        end
    end
end
@deprecate queryKnownToFault(query_type::String, query_string::String) _isqueryknowntofail(query_type, query_string)
 

function addQueryKnownToFault(query_type::String, query_string::String)::Nothing
    fpath = "resources/known-to-fault"
    touch(fpath)
    open(fpath, "a") do file
        write(file, query_type*"-"*queryID(query_string)*" "*"\"$query_string\""*"\n")
    end
    return nothing
end


