using ResearchMetrics
using Test

@testset "ResearchMetrics" begin
    @testset "arein(a,b)" begin
        @test arein([1,2], [1,2,3]) == true
        @test arein([1,2,3], [1,2]) == false
        @test arein([1,2,2], [1,2]) == true
        @test arein([1,2], [1,2,2]) == true
        @test arein([1], [2]) == false
        @test arein([1], [1]) == true
    end
end
