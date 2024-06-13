scopusAuthorSearch_fprefix = "Scopus-AuthorSearch"
scopusAbstractRetrieval_fprefix = "Scopus-AbstractRetrieval"
scopusSearch_fprefix = "Scopus-Search"
scopus_nresultsperpage = 10

function _formattitleforscopussearch(title)
    return replace(title, "-" => "?")    
end

include("scopus-search.jl")
include("scopus-abstract-retrieval.jl")
include("scopus-author-retrieval.jl")
include("scopus-author-search.jl")
