include("../src/ResearchMetrics.jl")
using .ResearchMetrics
using Dates

researcher = Researcher("Rattman", "Aperture Science")
publications = [Publication("Morality Core",
                            Date("2005-10-01"),
                            citations=[Publication(Date("2006-10-01")),
                                       Publication(Date("2006-10-01"))])]

researchers = [ 
    Researcher("Hommelhoff", "Universität Erlangen-Nürnberg") # Survey 2
    Researcher("Martínez-Pinedo", "Technische Universitat Darmstadt") # Survey 3
    Researcher("André", "Universität Augsburg") # Survey 4
    Researcher("Haddadin", "Technische Universität München") # Survey 5
    Researcher("Wessling", "RWTH") # Survey 6
    #Author("schölkopf", "mpi") # Survey 7
    #Author("mädler", "universität bremen") # Survey 8
    #Author("grimme", "universität bonn") # Survey 9
    #Author("dreizler", "technische universität darmstadt") # Survey 9
    #Author("merklein", "universität erlangen-nürnberg") # Survey 8
    #Author("rosch", "universität zu köln") # Survey 7
]

setScopusAuthorSearch!.(researchers)
setAuthoredPublicationsWithScopusSearch!.(researchers)
setCitationsWithSerpapiGScholarCite!.(researchers)
