using Test, HSquared, LinearAlgebra
@testset "Pedigree clonal and lineage residual contracts" begin
    @testset "Terminal clones retain supported additive rows" begin
        ped=normalize_pedigree(["P","Q","G","r1","r2","U"],
            ["0","0","P","0","0","0"],["0","0","Q","0","0","0"])
        clone_of=["0","0","0","G","r1","0"]
        C=clonal_relationship(ped,clone_of)
        reps=[1,2,3,3,3,6];A=additive_relationship(ped)
        @test C≈A[reps,reps]
        @test C[4,:]==C[3,:]
        @test C[5,:]==C[3,:]
        @test C[4,1]≈.5
        @test C[4,4]≈1.
        @test rank(C)==4
        @test clonal_relationship(ped,fill("0",6))==A
        @test_throws ArgumentError clonal_relationship(ped,fill("0",5))
        @test_throws ArgumentError clonal_relationship(ped,fill("absent",6))
        @test_throws ArgumentError clonal_relationship(ped,ped.ids)
    end
    @testset "Ramets cannot be sexual parents" begin
        for role in (:sire,:dam)
            ids=["P","Q","G","r","U","h"]
            s=["0","0","P","0","0",role===:sire ? "r" : "U"]
            d=["0","0","Q","0","0",role===:dam ? "r" : "U"]
            ped=normalize_pedigree(ids,s,d)
            clones=[id=="r" ? "G" : "0" for id in ped.ids]
            @test_throws ArgumentError clonal_relationship(ped,clones)
        end
        # A terminal clone link may target another ramet, but that ramet is also
        # subject to the sexual-parent refusal if it produces an offspring.
        ids=["P","Q","G","r1","r2","U","h"]
        ped=normalize_pedigree(ids,["0","0","P","0","0","0","r2"],
                                  ["0","0","Q","0","0","0","U"])
        clones=[id=="r1" ? "G" : id=="r2" ? "r1" : "0" for id in ped.ids]
        @test_throws ArgumentError clonal_relationship(ped,clones)
    end
    @testset "Cytoplasmic grouping matches pedigree key equality" begin
        nanped=normalize_pedigree([NaN],[0],[0])
        @test isequal(maternal_lineage(nanped),[NaN])
        @test cytoplasmic_relationship(nanped)==ones(1,1)
        zeroped=normalize_pedigree([-0.,0.],[nothing,nothing],[nothing,nothing];missing_values=(nothing,))
        @test length(unique(zeroped.ids))==2
        @test cytoplasmic_relationship(zeroped)==Matrix{Float64}(I,2,2)
        ordinary=normalize_pedigree(["mother","child","other"],["0","0","0"],["0","mother","0"])
        @test cytoplasmic_relationship(ordinary)==[1. 1 0;1 1 0;0 0 1]
        @test maternal_lineage(ordinary)==["mother","mother","other"]
    end
    @testset "Labelled Gamma and existing numerical policy" begin
        ids=["child","sire","dam"];s=["sire","0","0"];d=["0","0","0"]
        group=["child_group","founder_group","founder_group"];G=[.2 .1;.1 .8]
        ped=normalize_pedigree(ids,s,d);normalized_group=group[ped.original_order]
        _,_,_,labels=HSquared._metafounder_combined_indices(ped,normalized_group)
        @test labels==["founder_group","child_group"]
        A=metafounder_relationship(ids,s,d,group,G)
        @test diag(A)≈[1.1,1.05,1.1]
        @test A≈metafounder_relationship(ped,normalized_group,G)
        @test metafounder_relationship_inverse(ids,s,d,group,G)≈inv(A)
        founder=normalize_pedigree(["a"],[0],[0])
        @test metafounder_inbreeding(founder,["base"],fill(.4,1,1))≈[.2]
        @test_throws ArgumentError metafounder_inverse(founder,["base"],fill(1e-14,1,1))
        @test metafounder_relationship(founder,["base"],fill(1e-14,1,1))[1,1]≈1.
        p=normalize_pedigree(["a","b","child"],[0,0,"a"],[0,0,"b"])
        @test metafounder_inbreeding(p,["A","B",nothing],[.3 -.1;-.1 .5])[3]≈-.05
    end
    @testset "Full-sib examples require unrelated parents" begin
        p=normalize_pedigree(["p","q","a","b","c","d"],
            ["0","0","p","p","a","a"],["0","0","q","q","b","b"])
        @test inbreeding_coefficients(p)[3:4]==[0.,0.]
        @test dominance_relationship(p)[5,6]≈5/16
        @test epistatic_relationship(p;kind=:additive_additive)[5,6]≈9/16
    end
end
