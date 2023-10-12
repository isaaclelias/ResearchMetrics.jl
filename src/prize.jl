using Dates

struct Prize
    name::String
    date::Date
end

function name(prize::Prize)
    prize.name
end

function date(prize::Prize)
    prize.date
end
