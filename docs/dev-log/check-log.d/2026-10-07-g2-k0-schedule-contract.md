# G2 K0 schedule and receipt contracts

Date: 2026-10-07 (America/Edmonton)
Scope: selector and evidence-contract repair only. No study admission, seed use, denominator change, or G2 qualification.

## Exact-source review

Independent Astra review: PASS on the exact nine-file snapshot. The reviewer verified six K0 starts, K0 split metadata retention, explicit K1 failure rows, better-unaccepted K0 refusal, best eligible K0 anchoring, selected ordinary receipt reconciliation, interrupted null-guard handling, and unchanged v2/legacy routing. The review does not establish R/Julia parity or qualify G2.

| File | SHA-256 |
| --- | --- |
| `src/fa_rank_selection.jl` | `03851ee50a403c6edccc38dc778b0a6ecce8429b68e0e38cb4df0e9a4487a00f` |
| `src/arc1_bootstrap.jl` | `a03454ca2729c92db379c764c5a010ac69fc362f27643b824324bf0f51ec6b62` |
| `sim/arc1/execute_attempt.jl` | `8df0da58cb81ea52d6f1d603307c0a14d8cd042cf8a04e96bfd4ded94bdf524d` |
| `tools/arc1_receipt_check.py` | `d7e4981edcd12c57184632665f451ec0173e031a8f363372a68eb050c39f0ce2` |
| `docs/design/arc1-gaussian-reliability-20261002.md` | `2ef44b87897e3abc6e12cc2a77b61551c50f514c8530028b46d07071112d59a1` |
| `test/arc1_optimizer_contracts.jl` | `7f0f13079c1fb9647b471953a85f4bd0a41095280e1131eeafac2b7b96746a5a` |
| `test/arc1_bootstrap.jl` | `33ae00fa034189e04bb6a2f53dcf562a89a60a8c09bab69a1de22951a7dfe6a8` |
| `test/arc1_simulation_executor.jl` | `0b1fc5c72c2bdf4db2068b761ba9e8d9b9d12d1d9d21699c79eb058e6faa8b21` |
| `test/test_arc1_receipt_adversaries.py` | `03eb754b93a2120b6e069fd930a38a36664d23e639025b19e3d099c1ba39cf11` |

## Focused verification

Julia optimizer and selector contracts passed 663/663 in 23.6 seconds. This includes K0 initialization failure, all-K0 failure, better finite unaccepted K0 refusal, and a strictly better later K0 supplying all sixteen derived K1 starts. Output: `2026-10-07-g2-k0-schedule-contract-julia.log` (SHA-256 `fdbdfcb4eb71c8cc40ac46fd8bb72d1ef021dfa7f4bc73cfb0fb1619ccb4dde0`).

Julia fixed-B bootstrap tests passed 293/293 across four testsets, including v2's 19-start route. Output: `2026-10-07-g2-k0-schedule-bootstrap.log` (SHA-256 `0d58a6d927e0ee9faecb15ab9d821f01071f1e064b3bf8df98bc652a81d732c7`).

Four focused Python receipt adversaries passed; Python compilation also passed. They cover ledger deletion and `inner_index` spoofing, interrupted null guards with a complete schedule, bootstrap inner receipts, and failed-candidate denominators. Output: `2026-10-07-g2-k0-schedule-receipts.log` (SHA-256 `ccf7b54f144d3e9682c95e71a54d347376487292982197f61b4f9bb2d6f65cc8`).

The full receipt-adversary file and simulation executor were not completed; their nested Julia subprocess previously exceeded five minutes locally and was stopped. No campaign was run. Reverification of the retained G1, G6, and G7 receipts returned `current Julia/R source inventory differs from the externally pinned freeze`; retained output: `2026-10-07-g2-k0-schedule-receipt-rechecks.log` (SHA-256 `41129ceecca71ec76d4f67931f725a37fe1b6a98a7761bc2f58d92c7bfd69fef1`). Their old evidence remains historical; the ledger now reopens G1, G6, and G7 for this source snapshot. Current-source R parity remains unproved.
