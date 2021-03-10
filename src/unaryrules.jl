# Unary operations are searched in the following order
# 0. special rules `Identity` and `Tr`,
# 1. rules reducing dimensions `Sum` (note: `PTrace` has been removed),
# 2. `Permutedims`,
# 3. `Repeat` and `Duplicate`,
#   - we use `loop_einsum` instead of using existing API,
#   - because it is has similar or even better performance.

# For unclassified unary rules
# 1. the simplified pattern can be handled by `Sum` + `Permutedims`,
# 2. generate the correct output using `Repeat` and `Duplicate`,

# `NT` for number of tensors
abstract type EinRule{NT} end

struct Sum <: EinRule{1} end
struct Tr <: EinRule{1} end
struct Permutedims <: EinRule{1} end
struct Identity <: EinRule{1} end
struct Repeat <: EinRule{1} end
struct DefaultRule <: EinRule{Any} end
# potential rules:
# - `Duplicate` and `TensorDiagonal`
# - `Kron`

@doc raw"
    match_rule(ixs, iy)
    match_rule(code::EinCode{ixs, iy})
    match_rule(code::NestedEinCode)

Returns the rule that matches, otherwise use `DefaultRule` - the slow `loop_einsum` backend.
"
function match_rule(ixs::NTuple{Nx,NTuple}, iy::Tuple) where Nx
    DefaultRule()
end

function match_rule(ixs::Tuple{NTuple{Nx,T}}, iy::NTuple{Ny,T}) where {Nx, Ny, T}
    ix, = ixs
    # the first rule with the higher the priority
    if Ny === 0 && Nx === 2 && ix[1] == ix[2]
        return Tr()
    elseif allunique(iy)
        if ix === iy
            return Identity()
        elseif allunique(ix)
            if Nx === Ny
                if all(i -> i in iy, ix)
                    return Permutedims()
                else  # e.g. (abcd->bcde)
                    return DefaultRule()
                end
            else
                if all(i -> i in ix, iy)
                    return Sum()
                elseif all(i -> i in iy, ix)
                    return Repeat()
                else  # e.g. ijkxc,ijkl
                    return DefaultRule()
                end
            end
        else  # ix is not unique
            return DefaultRule()
        end
    else  # iy is not unique
        return DefaultRule()
    end
end

match_rule(code::EinCode{ixs, iy}) where {ixs, iy} = match_rule(ixs, iy)

# trace
function einsum(::Tr, ::EinCode{ixs,iy}, xs::NTuple{1, Any}, size_dict) where {ixs, iy}
    @debug "Tr" size.(xs)
    asarray(tr(xs[1]), xs[1])
end

function einsum(::Sum, code::EinCode{ixs, iy}, xs, size_dict) where {ixs, iy}
    dims = (findall(i -> i ∉ iy, ixs[1])...,)
    (ix1,) = ixs
    ix1f = filter!(i -> i in iy, collect(ix1))
    # einsum(EinCode{((ix1f...,),),(iy)}(), res, size_dict)
    perm = map(i -> findfirst(==(i), ix1f), iy)
    res = dropdims(sum(xs[1], dims=dims), dims=dims)
    if perm == iy
        @debug "Sum" ixs => iy size.(xs)
        res
    else
        @debug "Sum permutedims" ixs => iy size.(xs) perm
        tensorpermute(res, perm)
    end
end

function einsum(::Permutedims, code::EinCode{ixs, iy}, xs, size_dict) where {ixs, iy}
    (ix,) = ixs
    (x,) = xs
    perm = map(i -> findfirst(==(i), ix), iy)
    @debug "Permutedims" ix => iy size(xs[1]) perm
    return tensorpermute(x, perm)
end

function einsum(::Identity, ::EinCode{ixs, iy}, xs, size_dict) where {ixs, iy}
    xs[1]
end

# the fallback
for RULE in [:Repeat, :DefaultRule]
    @eval function einsum(::$RULE, code::EinCode{ixs, iy}, xs, size_dict) where {ixs, iy}
        @debug "DefaultRule loop_einsum" ixs => iy size.(xs)
        loop_einsum(code, xs, size_dict)
    end
end

@doc raw"
    einsum(::EinCode{ixs, iy}, xs, size_dict) where {ixs, iy}

return the tensor that results from contracting the tensors `xs` according
to their indices `ixs`, where all indices that do not appear in the output `iy` are
summed over.
The result is permuted according to `out`.

- `ixs` - tuple of tuples of index-labels of the input-tensors `xs`

- `iy` - tuple of index-labels of the output-tensor

- `xs` - tuple of tensors

- `size_dict` - `IndexSize`-object that maps index-labels to their sizes

# example

```jldoctest; setup = :(using OMEinsum)
julia> a, b = rand(2,2), rand(2,2);

julia> einsum(EinCode((('i','j'),('j','k')),('i','k')), (a, b)) ≈ a * b
true

julia> einsum(EinCode((('i','j'),('j','k')),('k','i')), (a, b)) ≈ permutedims(a * b, (2,1))
true
```
"
@generated function einsum(code::EinCode{ixs, iy}, xs, size_dict) where {ixs, iy}
    rule = match_rule(ixs, iy)
    :(einsum($rule, code, xs, size_dict))
end