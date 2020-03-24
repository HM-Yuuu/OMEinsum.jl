using .CuArrays
using .CuArrays.CUDAnative

println("OMEinsum: YOU FIND CUDA!")

include("cudapatch.jl")

asarray(x::Number, arr::CuArray) where T = CuArray(fill(x, ()))

function get_output_array(xs::NTuple{N, CuArray{<:Any,M} where M}, size) where N
    out = CuArrays.zeros(promote_type(map(eltype,xs)...), size)
end

CUDAnative.cudaconvert(A::EinArray{T}) where T = EinArray{T}(cudaconvert.(A.xs), A.x_indexers, A.y_indexer, A.size, A.ICIS, A.OCIS)
CuArrays.cu(A::EinArray{T}) where T = EinArray{T}(cu.(A.xs), A.x_indexers, A.y_indexer, A.size, A.ICIS, A.OCIS)

function CuArrays.mapreducedim_kernel_serial(f, op, R, A::EinArray, range)
    i = (blockIdx().x-1) * blockDim().x + threadIdx().x
    i > length(A.OCIS) && return nothing
    @inbounds ind_y = A.OCIS[i]
    iy = subindex(A.y_indexer, ind_y.I)
    #invoke(CuArrays.mapreducedim_kernel_serial, Tuple{Any,Any,Any,Any,Any}, f, op, R, A, range)
    @inbounds for ind_x in A.ICIS
        ind_xy = TupleTools.vcat(ind_x.I,ind_y.I)
        R[iy] = op(R[iy], f(map_prod(A.xs, ind_xy, A.x_indexers)))
    end
    return nothing
end

function loop_einsum!(code::EinCode{ixs, iy},
                xs::NTuple{N, CuArray{<:Any,M} where M},
                y::CuArray{T,L}, size_dict) where {N,L,T,IT <: Union{AbstractChar,Integer}, ixs, iy}
    NO = length(tunique(iy))
    A = einarray(code, xs, size_dict)
    y = reshape(y, fill(1, ndims(A)-NO)...,size(y)...)
    dropdims(Base._mapreducedim!(x->x, +, y, A), dims=(1:ndims(A)-NO...,))
end

# define einsum for both PairWise and PTrace with CuArray to have those operations
function einsum(::PTrace, code::EinCode{ixs, iy},
            xs::NTuple{NT,CuArray{T} where T<:CuBlasFloat},
            size_dict) where {ixs, iy, NT}
    loop_einsum(code, xs, size_dict)
end

function _batched_gemm(C1::Char, C2::Char, A::CuArray{T1, 3}, B::CuArray{T2,3}) where {T1<:Number, T2<:Number}
    CuArrays.CUBLAS.gemm_strided_batched(C1, C2, align_eltypes(A,B)...)
end

@generated function einsum(::BatchedContract, ::EinCode{ixs,iy}, xs::NTuple{<:Any, CuArray{<:CuBlasFloat}}, size_dict) where {ixs, iy}
    quote
        ixs1, xs1 = _preprocess_dupindices($(Val(ixs[1])), xs[1])
        ixs2, xs2 = _preprocess_dupindices($(Val(ixs[2])), xs[2])
        @debug "BatchedContract" ixs => iy Tuple(ixs1) Tuple(ixs2) size.((xs1, xs2))
        batched_contract(ixs1, xs1, ixs2, xs2, $(Val(iy)))
    end
end

tensorpermute(A::CuArray, perm) = permutedims(A, perm)
