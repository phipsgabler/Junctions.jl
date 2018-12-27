module Junctions

import Base: convert, getindex, reduce
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


function construct_junction(typ, values)
    # comps = foldl((current, rest) -> :($current ∘ (() -> $rest)), esc.(values), init = :i)
    # comps = foldr((current, rest) -> :($current ∘ (() -> $rest)), esc.(reverse(values)), init = :i)
    # :(Junction{$typ}((init, op, cont) -> $comps))

    expr = :(nothing)
    for v in Iterators.reverse(values)
        expr = quote
            let v = $v
                acc = op(acc, v)
                if cont(v)
                    $expr
                end
            end
        end
    end

    expr = quote
        acc = init
        $expr
        return acc
    end

    :(Junction{$typ}((init, op, cont) -> $expr))
end

macro all(values...)
    construct_junction(:And, values)
end

macro any(values...)
    construct_junction(:Or, values)
end


reduce(op, j::Junction, init) = j.reducer(init, op, _ -> true)

eigenstates(j::Junction, ::Type{T} = Any) where T = reduce(push!, j, T[])

convert(::Type{Bool}, j::Junction{And}) = j.reducer(true, &, identity)
convert(::Type{Bool}, j::Junction{Or}) = j.reducer(false, |, !)


# broadcasting
struct JunctionStyle <: Broadcast.BroadcastStyle end
Base.BroadcastStyle(::Type{<:Junction}) = JunctionStyle()
Broadcast.BroadcastStyle(s::JunctionStyle, ::Broadcast.BroadcastStyle) = s

Broadcast.broadcastable(x::Junction) = x

function Broadcast.broadcasted(::JunctionStyle, f, arg1::Junction{T}) where T
    function reducer(init, op, cont)
        arg1.reducer(init, (acc, v) -> op(acc, f(v)), v -> cont(f(v)))
    end
    Junction{T}(reducer)
end


end # module
