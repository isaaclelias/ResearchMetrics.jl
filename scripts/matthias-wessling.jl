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

#setinfoforhindex!(wessling, only_local=true)
  
