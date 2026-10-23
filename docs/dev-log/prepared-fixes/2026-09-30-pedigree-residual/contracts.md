# Frozen bounded pedigree correction contracts

Base source522741349ecfca48afc29d06f04bf4f6a0206fbc84648606e1ebf9f5444267d4. No fitted inheritance capability is added.

1. Clonal rows may be terminal copies, including transitive clone links. A row explicitly marked as a clone may not appear as a sire or dam in the sexual pedigree. Refuse this input before ordinary dense A is built; clone-aware sexual recursion remains unsupported.
2. Maternal lineage grouping must use the same `isequal` semantics as validated pedigree IDs/Dict/unique and unknown markers. Preserve caller label values and existing ID policy.
3. Gamma coordinate order remains first group appearance after pedigree normalization; visible prose and hand-derived labelled fixtures state this contract. No Gamma reorder or new API.
4. Preserve implemented Gamma eigen/symmetry/PSD/PD policy exactly; describe max(1,max(abs Gamma)) scale and inverse eigen floor.
5. Distinguish animal F from metafounder F, and qualify familiar full-sib D/AA examples by unrelated, non-inbred parents. No new dominance-inbreeding or fitting support.
