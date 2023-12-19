"Stores information about a prize."
struct Prize
    name::String
    date::Date
end

function Prize(name, date::String)
    Prize(name, Date(date))
end

function nameof(prize::Prize)
    prize.name
end

function dateof(prize::Prize)
    prize.date
end
