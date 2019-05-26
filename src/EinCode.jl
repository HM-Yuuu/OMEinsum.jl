# Ref
# * https://github.com/JuliaLang/julia/issues/2345#issuecomment-54537633
# * https://github.com/mauro3/SimpleTraits.jl

using TupleTools
using SimpleTraits, LinearAlgebra

export EinCode, is_pairwise, IsPairWise, einmagic!

struct EinCode{C} end

function EinCode(ixs::Tuple, iys::Tuple)
    # re-assign indices
    CODE = (ixs..., iys)
    EinCode{CODE}()
end

"""
a einsum code is a pairwise graph.
"""
function is_pairwise(code::Tuple)
    all_indices = TupleTools.vcat(code...)
    counts = Dict{Int, Int}()
    for ind in all_indices
        counts[ind] = get(counts, ind, 0) + 1
    end
    all(isequal(2), counts |> values)
end

@traitdef IsPairWise{CODE}
@traitimpl IsPairWise{CODE} <- is_pairwise(CODE)

"""The most general case as fall back"""
einmagic!(ixs::Tuple, xs::Tuple, iys::Tuple, y::AbstractArray) = einmagic!(EinCode(ixs, iys), xs, y)
function einmagic!(::Type{TP}, ::EinCode{C}, xs, y) where {TP, C}
    println("TYPE: $TP, CODE: $C -> general")
    einsum!(C[1:end-1], xs, C[end], y)
end

"""Dispatch to trace."""
function einmagic!(::EinCode{((1,1), ())}, xs, y)
    println("doing contraction using tr!")
    y[] = tr(xs[1])
    y
end

@traitfn function einmagic!(::EinCode{C}, xs, y) where {C; IsPairWise{C}}
    println("CODE $C (IsPairWise) -> @tensor!")
    einsum!(C[1:end-1], xs, C[end], y)
end
