export setScopusApiKey, setScopusSearchData!, getCitationDates

scopusAuthorSearch_fprefix = "Scopus-AuthorSearch"
scopusAbstractRetrieval_fprefix = "Scopus-AbstractRetrieval"
scopusSearch_fprefix = "Scopus-Search"

include("scopus-search.jl")
include("scopus-abstract-retrieval.jl")
include("scopus-author-retrieval.jl")
