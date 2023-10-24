export Prize

struct Prize
    name::String
    date::Date
end

function Prize(name, date::String)
    Prize(name, Date(date))
end

function name(prize::Prize)
    prize.name
end

function date(prize::Prize)
    prize.date
end
