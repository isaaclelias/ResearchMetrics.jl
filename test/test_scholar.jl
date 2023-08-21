# - [ ] rodar o código para o pesquisador com menor h-index
# - [ ]  

include("../src/hindex.jl")

using Test
using .HIndex
using Logging

logger = SimpleLogger(stdout, Logging.Debug)
global_logger(logger)

@test begin
    author = Author("hasse", "technische universitat darmstadt")

    setBasicInfo!(author)
    print(author)

    setAuthoredAbstracts!(author)
    print(author)

    setCitations!(author)
    print(author)

    setCitationsBasicInfo!(author)
    print(author)

    setHIndex!(author)
    print(author)

    plot(author.hindex)
end
