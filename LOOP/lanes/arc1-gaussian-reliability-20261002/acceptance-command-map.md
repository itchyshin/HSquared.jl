# Arc1 acceptance command map

The canonical G2-G5 checker is `tools/arc1_gate_aggregate.py`. It verifies every cell through `arc1_receipt_check.py`, then applies the frozen scientific rules. The per-attempt integrity checker alone cannot pass a scientific gate.

For each gate, the final command shape is:

```text
python3 -B tools/arc1_gate_aggregate.py G2 confirmation <retained-bundle.json> --pins <independent-pins.json>
python3 -B tools/arc1_gate_aggregate.py G3 confirmation <retained-bundle.json> --pins <independent-pins.json>
python3 -B tools/arc1_gate_aggregate.py G4 confirmation <retained-bundle.json> --pins <independent-pins.json>
python3 -B tools/arc1_gate_aggregate.py G5 confirmation <retained-bundle.json> --pins <independent-pins.json>
```

The command must exit zero and its result must contain the corresponding `ARC1_G2_CONFIRMATION_PASS`, `ARC1_G3_CONFIRMATION_PASS`, `ARC1_G4_CONFIRMATION_PASS` or `ARC1_G5_CONFIRMATION_PASS` marker. G5 confirmation additionally requires the two exact-zero diagnostic cells. Pilot markers cannot satisfy final gates. The confirmation bundle and independently pinned admission do not yet exist; these are command templates, not approved runnable bindings.

Four bounded negative CLI controls used empty receipt/pin bundles. All four exited one, reported missing required cells and emitted no confirmation success marker. Each took less than 0.14 seconds. They performed no model evaluation. Evidence is retained under `.unlazy/arc1-gaussian-reliability/evidence/aggregate-cli-binding/`. These controls establish only rejection of missing evidence. Existing independent source review and corruption tests remain required for the complete checker.

When qualified, admitted study receipts exist, replace the GATES.md templates with absolute commands bound to inspected checker/source hashes, exact bundle bytes and independent pin files. Do not bind an empty bundle as a scientific result. Review the current implementation and complete inputs before approving each exact command. No study is admitted by this preparation.
