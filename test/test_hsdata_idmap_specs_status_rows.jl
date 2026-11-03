# Contract tests for HSDataIDMap, HSAnnotationSpec, HSEnvironmentSpec and the
# per-component status rows. The R twin reads these field names, so a rename
# or retype must fail here. The structs have no inner constructors; the input
# guards live in the HSData constructor and are pinned through it.

@testset "HSDataIDMap and spec types: field names and types" begin
    @test fieldnames(HSDataIDMap) == (
        :phenotype_ids, :pedigree_ids, :genotype_ids, :expression_ids,
        :phenotypes_without_pedigree, :phenotypes_without_genotypes,
        :phenotypes_without_expression, :genotypes_without_phenotypes,
        :expression_without_phenotypes,
    )
    @test all(==(Vector{Any}), fieldtypes(HSDataIDMap))
    @test fieldnames(HSAnnotationSpec) == (
        :key, :annotation_features, :expression_features,
        :expression_without_annotation, :annotation_without_expression,
        :duplicate_annotation_features,
    )
    @test fieldtypes(HSAnnotationSpec) ==
          (Symbol, Vector{String}, Vector{String}, Vector{String}, Vector{String}, Vector{String})
    @test fieldnames(HSEnvironmentSpec) == (
        :key, :phenotype_environment_ids, :environment_ids,
        :phenotypes_without_environment, :environment_without_phenotypes,
        :duplicate_environment_ids,
    )
    @test fieldtypes(HSEnvironmentSpec) ==
          (Symbol, Vector{String}, Vector{String}, Vector{String}, Vector{String}, Vector{String})
    for T in (HSDataIDMap, HSAnnotationSpec, HSEnvironmentSpec)
        @test isstructtype(T)
        @test !ismutabletype(T)
    end
end

@testset "HSData status row types: field names, types, immutability" begin
    contract = (
        HSDataGenotypeStatusRow => ((:metric, :value), (String, String)),
        HSDataAnnotationStatusRow => ((:metric, :value), (String, String)),
        HSDataExpressionStatusRow => ((:metric, :value), (String, String)),
        HSDataEnvironmentStatusRow => ((:metric, :value), (String, String)),
        HSDataPedigreeStatusRow => ((:metric, :count), (String, Int)),
    )
    for (T, (names, types)) in contract
        @test fieldnames(T) == names
        @test fieldtypes(T) == types
        @test isstructtype(T)
        @test !ismutabletype(T)
    end
end

throws_argument_error(f) = try
    f()
    false
catch err
    err isa ArgumentError
end

@testset "HSData constructor guards behind the id map and specs" begin
    pheno = (id = ["a", "b", "c"], env = ["e1", "e2", "e1"])

    @test_throws ArgumentError HSData((id = String[],))
    @test_throws ArgumentError HSData((id = ["a", ""],))
    # Current behaviour: "0" is accepted as a phenotype ID (unlike marker IDs,
    # which reject it).
    @test HSData((id = ["a", "0"],)).id_map.phenotype_ids == ["a", "0"]
    @test_throws ArgumentError HSData((id = Any["a", missing],))
    @test_throws ArgumentError HSData((x = ["a"],))

    # Duplicate or mismatched IDs in the optional components.
    @test_throws ArgumentError HSData(pheno; expression = (id = ["a", "a"], f1 = [1.0, 2.0]))
    @test_throws ArgumentError HSData(pheno; expression = (id = ["a", "b"], f1 = [1.0, 2.0]), expression_ids = ["a"])
    @test_throws ArgumentError HSData(pheno; expression_ids = ["a"])
    @test_throws ArgumentError HSData(pheno; pedigree = (id = ["a", "b"],))

    # Annotation guards.
    expr = (id = ["a", "b", "c"], f1 = [1.0, 2.0, 3.0], f2 = [0.1, 0.2, 0.3])
    @test_throws ArgumentError HSData(pheno; annotation_id = :feature)
    # Looks like a gap: a range is not table-like, but propertynames(1:3) is
    # non-empty so the "must be table-like" guard does not fire.
    @test_broken throws_argument_error(() -> HSData(pheno; annotation = 1:3))
    @test_throws ArgumentError HSData(pheno; expression = expr, annotation = (feature = ["f1", ""],), annotation_id = :feature)
    @test_throws ArgumentError HSData(pheno; expression = expr, annotation = (feature = ["f1"],), annotation_id = Symbol(""))
    @test_throws ArgumentError HSData(pheno; expression = [1.0 2.0; 3.0 4.0; 5.0 6.0], annotation = (feature = ["f1"],), annotation_id = :feature)
    @test_throws ArgumentError HSData(pheno; expression = (id = ["a", "b", "c"],), annotation = (feature = ["f1"],), annotation_id = :feature)

    # Environment guards.
    @test_throws ArgumentError HSData(pheno; environment_id = :env)
    @test_broken throws_argument_error(() -> HSData(pheno; environment = 1:3))
    @test_throws ArgumentError HSData(pheno; environment = (env = ["e1", ""],), environment_id = :env)
    @test_throws ArgumentError HSData(pheno; environment = (other = ["e1"],), environment_id = :env)
    @test_throws ArgumentError HSData(pheno; environment = (env = ["e1"],), environment_id = Symbol(""))
end

@testset "HSData status rows reflect annotation, expression, environment, pedigree inputs" begin
    pheno = (id = ["a", "b", "c", "c"], env = ["e1", "e2", "e1", "e3"])
    ped = (id = ["a", "b", "c", "d"], sire = [nothing, nothing, "a", "a"], dam = [nothing, nothing, "b", "x"])
    expr = (id = ["a", "b", "z"], f1 = [1.0, 2.0, 3.0], f2 = [0.1, 0.2, 0.3], f3 = [1.0, 1.0, 1.0])
    ann = (feature = ["f1", "f2", "f2", "f9"], chrom = ["1", "1", "2", "2"])
    envs = (env = ["e1", "e2", "e2", "e9"], temp = [1.0, 2.0, 3.0, 4.0])

    d = HSData(
        pheno;
        pedigree = ped,
        expression = expr,
        annotation = ann,
        annotation_id = :feature,
        environment = envs,
        environment_id = :env,
    )
    st = data_status(d)
    @test st isa HSDataStatus
    @test st.components == [:phenotypes, :pedigree, :expression, :annotation, :environment]

    rowdict(rows) = Dict(r.metric => getfield(r, 2) for r in rows)

    # ID map and overlap rows.
    m = id_map(d)
    @test m isa HSDataIDMap
    @test m.phenotype_ids == ["a", "b", "c"]
    @test m.expression_ids == ["a", "b", "z"]
    @test m.phenotypes_without_expression == ["c"]
    @test m.expression_without_phenotypes == ["z"]
    @test m.genotype_ids == Any[]
    ov = rowdict(st.id_overlap)
    @test ov["phenotype_ids"] == 3
    @test ov["pedigree_ids"] == 4
    @test ov["expression_ids"] == 3
    @test ov["phenotypes_without_expression"] == 1
    @test ov["expression_without_phenotypes"] == 1
    @test ov["phenotypes_without_pedigree"] == 0

    # Pedigree rows.
    pr = st.pedigree_status
    @test all(r -> r isa HSDataPedigreeStatusRow, pr)
    p = rowdict(pr)
    @test p["pedigree_rows"] == 4
    @test p["pedigree_ids"] == 4
    @test p["phenotype_ids_with_pedigree"] == 3
    @test p["pedigree_only_ids"] == 1
    @test p["founders"] == 2
    @test p["nonfounders"] == 2
    @test p["known_sire_links"] == 2
    @test p["known_dam_links"] == 2
    @test p["missing_known_parent_ids"] == 1
    @test p["duplicate_pedigree_ids"] == 0
    @test p["self_parent_rows"] == 0
    @test p["same_known_parent_rows"] == 0

    # Expression rows.
    er = st.expression_status
    @test all(r -> r isa HSDataExpressionStatusRow, er)
    e = rowdict(er)
    @test e["expression_rows"] == "3"
    @test e["expression_ids"] == "3"
    @test e["expression_features"] == "3"
    @test e["named_expression_features"] == "3"
    @test e["unnamed_expression_features"] == "0"
    @test e["duplicate_expression_features"] == "0"
    @test e["component_type"] == "table"

    # Annotation spec and rows.
    spec = d.annotation_spec
    @test spec isa HSAnnotationSpec
    @test spec.key == :feature
    @test d.annotation_id == :feature
    @test spec.annotation_features == ["f1", "f2", "f9"]
    @test spec.expression_features == ["f1", "f2", "f3"]
    @test spec.expression_without_annotation == ["f3"]
    @test spec.annotation_without_expression == ["f9"]
    @test spec.duplicate_annotation_features == ["f2"]
    ar = st.annotation_status
    @test all(r -> r isa HSDataAnnotationStatusRow, ar)
    a = rowdict(ar)
    @test a["annotation_rows"] == "4"
    @test a["annotation_key"] == "feature"
    @test a["annotation_features"] == "3"
    @test a["expression_features"] == "3"
    @test a["expression_features_with_annotation"] == "2"
    @test a["annotation_only_features"] == "1"
    @test a["expression_features_without_annotation"] == "1"
    @test a["duplicate_annotation_features"] == "1"

    # Environment spec and rows.
    es = d.environment_spec
    @test es isa HSEnvironmentSpec
    @test es.key == :env
    @test d.environment_id == :env
    @test es.phenotype_environment_ids == ["e1", "e2", "e3"]
    @test es.environment_ids == ["e1", "e2", "e9"]
    @test es.phenotypes_without_environment == ["e3"]
    @test es.environment_without_phenotypes == ["e9"]
    @test es.duplicate_environment_ids == ["e2"]
    evr = st.environment_status
    @test all(r -> r isa HSDataEnvironmentStatusRow, evr)
    v = rowdict(evr)
    @test v["environment_rows"] == "4"
    @test v["environment_key"] == "env"
    @test v["environment_ids"] == "3"
    @test v["phenotype_environment_ids"] == "3"
    @test v["phenotype_environment_ids_with_metadata"] == "2"
    @test v["environment_only_ids"] == "1"
    @test v["phenotype_environment_ids_without_metadata"] == "1"
    @test v["duplicate_environment_ids"] == "1"

    # Components not supplied give no status.
    @test st.genotype_status === nothing
    @test st.marker_status === nothing
end

@testset "HSData status rows without annotation_id / environment_id" begin
    pheno = (id = ["a", "b"],)
    d = HSData(pheno; annotation = (feature = ["f1"],), environment = (env = ["e1", "e2"],))
    @test d.annotation_spec === nothing
    @test d.environment_spec === nothing
    @test d.annotation_id === nothing
    @test d.environment_id === nothing
    st = data_status(d)
    a = Dict(r.metric => r.value for r in st.annotation_status)
    @test a["annotation_rows"] == "1"
    @test a["annotation_key"] == "not_checked_no_annotation_id"
    @test a["annotation_features"] == "not_available"
    v = Dict(r.metric => r.value for r in st.environment_status)
    @test v["environment_rows"] == "2"
    @test v["environment_key"] == "not_checked_no_environment_id"
    @test v["duplicate_environment_ids"] == "not_available"
    @test st.pedigree_status === nothing
    @test st.expression_status === nothing
end

@testset "HSData genotype status rows and Pedigree-typed input" begin
    pheno = (id = ["a", "b", "c"],)
    geno = (id = ["a", "b", "q"], m1 = [0, 1, 2], m2 = [1, missing, 0])
    d = HSData(pheno; genotypes = geno)
    g = Dict(r.metric => r.value for r in data_status(d).genotype_status)
    @test all(r -> r isa HSDataGenotypeStatusRow, data_status(d).genotype_status)
    @test g["genotype_rows"] == "3"
    @test g["genotype_ids"] == "3"
    @test g["genotype_marker_columns"] == "2"
    @test g["missing_genotype_values"] == "1"
    @test g["component_type"] == "table"
    @test id_map(d).phenotypes_without_genotypes == ["c"]
    @test id_map(d).genotypes_without_phenotypes == ["q"]

    dm = HSData(pheno; genotypes = [0 1; 1 2; 2 0], genotype_ids = ["a", "b", "c"])
    gm = Dict(r.metric => r.value for r in data_status(dm).genotype_status)
    @test gm["component_type"] == "matrix"
    @test gm["unnamed_genotype_marker_columns"] == "2"
end
