# - [ ] rodar o código para o pesquisador com menor h-index
# - [ ]  

include("../src/hindex.jl")

using Test
using .HIndex
using Logging

logger = SimpleLogger(stdout, Logging.Debug)
global_logger(logger)

@test begin
    abstract = Abstract()
    abstract.doi = "10.1007/s11192-005-0281-4"
    setBasicInfo!(abstract)
    true
end

@test begin
    author = Author("hasse", "technische universitat darmstadt")
    setBasicInfo!(author)
    setAuthoredAbstracts!(author)
    setCitations!(author)
    setCitationsBasicInfo!(author)
end
