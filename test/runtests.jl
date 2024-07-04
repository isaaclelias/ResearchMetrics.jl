using ResearchMetrics
using Test

pwd()
#setworkingdir("")

@testset "ResearchMetrics" begin
    @testset "arein(a,b)" begin
        @test arein([1,2], [1,2,3]) == true
        @test arein([1,2,3], [1,2]) == false
        @test arein([1,2,2], [1,2]) == true
        @test arein([1,2], [1,2,2]) == true
        @test arein([1], [2]) == false
        @test arein([1], [1]) == true
    end

    @testset "Scopus API" begin
        researcher = Researcher(
            "Christian Hasse",
            "Technische Universität Darmstadt"
        )

        @testset "set_scopus_search!()" begin
            set_scopus_search!(researcher)
            @test researcher.success_set_scopus_search == true
        end

        @testset "set_scopus_author_search!()" begin
          
        end

        @testset "set_scopus_abstract_retrieval()" begin
          
        end
    end

    @testset "SerpApi" begin
      
    end
end
