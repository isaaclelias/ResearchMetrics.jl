include("../src/hindex.jl")

using .HIndex

ENV["JULIA_DEBUG"] = HIndex

# Searching for an author
hasse = Author("hasse", "technische universitat darmstadt")
@time setScopusData!(hasse)

# Getting his papers
articles_hasse = getScopusAuthoredAbstracts(hasse)
@time setScopusData!(articles_hasse[1])

# Getting the paper that cites
@time citing = getScopusCitingAbstracts(articles_hasse[1])
@info citing
