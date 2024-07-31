scopusAuthorSearch_fprefix = "Scopus-AuthorSearch"
scopusAbstractRetrieval_fprefix = "Scopus-AbstractRetrieval"
scopusSearch_fprefix = "Scopus-Search"
scopus_nresultsperpage = 10

function _formattitleforscopussearch(title)
    return replace(title, "-" => "?")    
end
