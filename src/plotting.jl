function addprizes!(plt, prizes)
    _prizes = _parse_prizes(prizes)
    if isnothing(_prizes) || length(_prizes) == 0
        return nothing
    end

    for prize in _prizes
        vline!(plt, [dateof(prize)], label=nameof(prize))
    end
end

function _parse_prizes(prizes)
    if length(prizes) == 0
        return nothing
    end

    _prizes = Prize[]
    for prize in prizes
        push!(_prizes, Prize(prize[2], prize[1]))
    end

    return _prizes
end

function format_xticks!(plt)
    _xticks_v = xticks(plt)[1][1]
    _xticks_d = xticks(plt)[1][2]

    _xticks_d = _xticks_d .|> Date .|> x->Dates.format(x, "YYYY")

    plot!(plt, xticks=(_xticks_v, _xticks_d))

    return nothing
end

function partition_hindex_evol_with_prizes(_hindex_evol, prizes)
    if isnothing(prizes) || length(prizes) == 0
        return [_hindex_evol]
    end
    
    tas = TimeArray[]
    previous_date = Date(0)
    for prize in prizes
        ta = _hindex_evol |>
             x->from(x, previous_date) |>
             x->to(x, Date(prize[1]))
        push!(tas, ta)
        previous_date = Date(prize[1])
    end
    ta = from(_hindex_evol, previous_date)
    push!(tas, ta)

    return tas
end

function fit_curve_for_partition(partition)
  
end

function addtrendlines!(plt, partitions)
    for partition in partitions
        fit_x = timestamp(partition) .|> x->x.instant.periods.value
        fit_y = values(partition)
        fit = linear_fit(fit_x, fit_y)

        plot_y1 = fit[1] + fit[2]*fit_x[begin]
        plot_y2 = fit[1] + fit[2]*fit_x[end]


        plot!(plt, [fit_x[begin], fit_x[end]], [plot_y1, plot_y2], label = "$(round(fit[2]*365; digits=3)) increase per year")
    end
end

function plot_hindex_evol(_hindex_evol, _name, prizes; trendlines=true)
    plt = plot(_hindex_evol, linetype=:steppre, title=_name*"'s H-Index evolution", label="H-Index")
    addprizes!(plt, prizes)
    format_xticks!(plt)

    # fit the lines
    partitions = partition_hindex_evol_with_prizes(_hindex_evol, prizes)
    trendlines && addtrendlines!(plt, partitions)
    return plt
end


