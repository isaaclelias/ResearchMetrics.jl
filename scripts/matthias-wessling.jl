include("../src/ResearchMetrics.jl")
using .ResearchMetrics

using Dates, TimeSeries
using Logging, LoggingExtras
using Debugger
using Eyeball
using CurveFit
using Plots
using Serialization

# setup logging
io_path = "logs/matthias-wessling_"*Dates.format(now(), "yyyy-mm-dd_HH-MM")*".log"
touch(io_path)
io = open(io_path, "w+")
logger = TeeLogger(ConsoleLogger(stdout, Logging.Info),
                   SimpleLogger(io, Logging.Debug))
global_logger(logger)
@info "Logging" io_path

wessling = Researcher(
    "wessling",
    "rwth"
)

nomination_offset = Year(2)

#=
function uppercasen(s::AbstractString, i::Int)
    0 < i <= length(s) || error("index $i out of range")
    pos =  chr2ind(s, i)
    string(s[1:prevind(s, pos)], uppercase(s[pos]), s[nextind(s, pos):end])
end
=#

function plothindexevolution(researcher::Researcher, h_index=nothing)
     # What to plot
     indication_date = dateof(prizes(researcher)[1])-Year(2)
     if isnothing(h_index)
        h_index = hindex(researcher)
     end
     fit_start_date = first(findwhen(h_index[:A] .> 5))
     h_index_before = h_index |> (y -> from(y, fit_start_date)) |> (y->to(y, indication_date))
     h_index_after = from(h_index, indication_date)
     x_h_index_before = float(Dates.value.(timestamp(h_index_before)))
     x_h_index_after = float(Dates.value.(timestamp(h_index_after)))
     y_h_index_before = float(values(h_index_before))
     y_h_index_after = float(values(h_index_after))
     fit_h_index_before = curve_fit(LinearFit, x_h_index_before, y_h_index_before)
     fit_h_index_after = curve_fit(LinearFit, x_h_index_after, y_h_index_after)
     #lastname = uppercasen(wessling.lastname, 1)
     save_date = Dates.format(now(), "YYYY-mm-dd_HH-MM")
     # Plots
     plot(h_index, linetype=:steppre, label="h-index", title = "Wessling's H-Index evolution")
     vline!([dateof(prizes(researcher)[1])-nomination_offset], linestyle=:dash, label = "Indication for Gottfried Wilhelm Leibniz Prize")
     plot!(x_h_index_before, fit_h_index_before.(x_h_index_before), label="Linear fit before indication")
     plot!(x_h_index_after, fit_h_index_after.(x_h_index_after), label="Linear fit after indication")
     #savefig("output/hindex_$(lastname)_$(save_date).png")
end

#setinfoforhindex!(wessling, only_local=true)
  
