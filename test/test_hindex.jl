include("../src/hindex.jl")

using .HIndex

ENV["JULIA_DEBUG"] = HIndex

hasse = Author("hasse", "technische universitat darmstadt")
@time setScopusData!(hasse)

articles_hasse = getAuthoredAbstracts(hasse)