var documenterSearchIndex = {"docs":
[{"location":"#OMEinsum.jl-1","page":"Home","title":"OMEinsum.jl","text":"","category":"section"},{"location":"#","page":"Home","title":"Home","text":"","category":"page"},{"location":"#","page":"Home","title":"Home","text":"Modules = [OMEinsum]","category":"page"},{"location":"#OMEinsum.einsum-Union{Tuple{T}, Tuple{N}, Tuple{Tuple{Vararg{Tuple{Vararg{T,M}} where M,N}},Tuple{Vararg{AbstractArray{#s14,M} where #s14 where M,N}},Tuple{Vararg{T,#s15}} where #s15}} where T where N","page":"Home","title":"OMEinsum.einsum","text":"einsum(cs, ts, out)\n\nreturn the tensor that results from contracting the tensors ts according to their indices cs, where twice-appearing indices are contracted. The result is permuted according to out.\n\ncs - tuple of tuple of integers that label all indices of a tensor.      Indices that appear twice (in different tensors) are summed over\nts - tuple of tensors\nout - tuple of integers that should correspond to remaining indices in cs after contractions.\n\nThis implementation has space requirements that are exponential in the number of unique indices.\n\nexample\n\njulia> a = rand(2,2);\n\njulia> b = rand(2,2);\n\njulia> einsum(((1,2),(2,3)), (a, b), (1,3)) ≈ a * b\ntrue\n\njulia> einsum(((1,2),(2,3)), (a, b), (3,1)) ≈ permutedims(a * b, (2,1))\ntrue\n\n\n\n\n\n","category":"method"},{"location":"#OMEinsum.bpcheck-Tuple{Any,Vararg{Any,N} where N}","page":"Home","title":"OMEinsum.bpcheck","text":"bpcheck(f, args...; η = 1e-5, verbose=false)\n\nreturns a Bool indicating whether Zygote calculates the gradient of f(args...) -> scalar correctly using the relation f(x - ηg) ≈ f(x) - η|g|². If verbose=true, print f(x) - f(x - ηg)and η|g|².\n\n\n\n\n\n","category":"method"},{"location":"#OMEinsum.einsum_grad-NTuple{5,Any}","page":"Home","title":"OMEinsum.einsum_grad","text":"einsum_grad(ixs, xs, iy, y, i)\n\nreturn gradient w.r.t the ith tensor in xs\n\n\n\n\n\n","category":"method"},{"location":"#OMEinsum.get_size_dict-Tuple{Any,Any}","page":"Home","title":"OMEinsum.get_size_dict","text":"get the dictionary of index=>size, error if there are conflicts\n\n\n\n\n\n","category":"method"},{"location":"#OMEinsum.index_map-Tuple{CartesianIndex,Tuple}","page":"Home","title":"OMEinsum.index_map","text":"take an index subset from ind\n\n\n\n\n\n","category":"method"},{"location":"#OMEinsum.loop!-Union{Tuple{S}, Tuple{T}, Tuple{N}, Tuple{Tuple{Vararg{Tuple{Vararg{T,M}} where T where M,N}},Any,Any,AbstractArray{T,N} where N,CartesianIndices}} where S where T where N","page":"Home","title":"OMEinsum.loop!","text":"loop and accumulate products to y\n\n\n\n\n\n","category":"method"}]
}
