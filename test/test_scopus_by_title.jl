include("../src/hindex.jl")

using Eyeball
using .HIndex

ENV["JULIA_DEBUG"] = HIndex
logger = ConsoleLogger(stdout, Logging.Error)
global_logger(logger)

# Preparing API
formatted_query_string = "Momentum exchange in quantum two-electron photon interactions"
endpoint = "https://api.elsevier.com/content/search/scopus"
headers = [
           "Accept" => "application/json",
           "X-ELS-APIKey" => scopus_api_key
          ]
params = [
          "query" => formatted_query_string,
          "start" => "$start"
          ]
try
    response = HTTP.get(endpoint, headers; query=params).body |> String
    return response
catch y
    if isa(y, HTTP.Exceptions.StatusError)
        @error "HTTP StatusError for Scopus Search" query_string*"$start"
        addQueryKnownToFault(scopusSearch_fprefix, query_string*"$start")
        return nothing
    end
end

abstract = Abstract("Momentum exchange in quantum two-electron photon interactions")

setBasicInfo!(abstract)

eye(abstract)