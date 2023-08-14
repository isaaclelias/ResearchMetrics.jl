include("../src/hindex.jl")

using .HIndex

readline("SerApi API Key: ") |> setSerapiApiKey

abstract = Abstract()
abstract.doi = "10.1007/s11192-005-0281-4"

setScholarBasicFields!(abstract)
