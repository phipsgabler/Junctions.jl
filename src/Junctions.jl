module Junctions

import Base: convert, getindex, similar
import Base.Broadcast

export @all, @any,
    eigenstates,
    Junction


struct Shift{F<:Function}
    continuation::F
end

getindex(s::Shift) = s.continuation()


struct Junction{T}
    reducer
end

struct And end
struct Or end

eigenstates(j::Junction, ::Type{T} = Any) where T = j.reducer(T[], (l, r) -> push!(l, r[]))

convert(::Type{Bool}, j::Junction{And}) = j.reducer(true, (l, r) -> l && r[])
convert(::Type{Bool}, j::Junction{Or}) = j.reducer(false, (l, r) -> l || r[])


function construct_junction(typ, values)
    comps = foldl((l, r) -> :($l ∘ Shift(() -> $r)), esc.(values), init = :i)
    :(Junction{$typ}((i, ∘) -> $comps))
end

macro all(values...)
    construct_junction(:And, values)
end

macro any(values...)
    construct_junction(:Or, values)
end


# broadcasting
BroadcastStyle(::Type{<:Junction}) = Broadcast.Style{Junction}()
# similar(bc::Broadcasted{Broadcast.Style{Junction}}, ::Type{Elype}) where Eltype =
    # Junction{Eltype}((i, ))

end # module
