# Coverage gate operating characteristics: Astra reviewed

Current authorization clarification, 2026-10-03: the user explicitly approved implementation of the plan with 400 confirmation datasets per cell and unchanged acceptance criteria. Astra confirmed that the operating-characteristic calculation shows low joint certification power, not invalid inference or an impossible gate. The earlier recommendation for another allocation decision is superseded. Retain the warning and all failed gates. No 1600 allocation, seed or criterion change is adopted. Qualified pilots, matching source/protocol admission and approval of any campaign projected above three hours remain required.

Historical record below; the clarification above governs the allocation authorization.

The design check precedes all studies. No simulated outcome from an allocated study has been inspected. The approved gates remain unchanged.

For n=400 and the frozen requirement that the 90% Wilson interval lie wholly within [0.92,0.98], the independent receipt checker accepts all-attempt coverage counts 377 through 387 inclusive. Direct binomial summation at true coverage 0.95 gives a single-cell acceptance probability of 0.7571888505775669. For one target across nine independent cells each with true coverage 0.95, the joint probability is 0.08181593428633004. Correlated targets within a cell do not remove the requirement that this one target pass all nine independent cells.

Calculation: enumerate k=0:400 with the existing Wilson formula, retain the accepted integer counts, and sum binomial(400,k)*0.95^k*0.05^(400-k). The calculation quantifies the certification rule's power. It assumes every cell's true all-attempt coverage is exactly 0.95 and independent datasets across cells. Actual method performance is unknown.

Astra must assess this before expensive confirmation admission. A method can fail the original gates through sampling variability even at nominal coverage. This observation does not authorize changing the sample allocation, margins, confidence level, or failed outcome after a study. Any redesign requires an explicit recorded decision and updated frozen protocol before confirmation seeds are used.

## Allocation sensitivity for review only

The same exact binomial calculation gives the following probabilities, assuming true all-attempt coverage 0.95 in every cell. The final column is the union-bound lower bound for all 57 required target/cell coverage checks (45 repeatability and 12 FA), without assuming independence among targets. These values concern sampling variability only; they do not predict numerical formation or actual method calibration.

| Attempts per cell | Accepted covered counts | Single-check probability | Nine independent cells, one target | Lower bound for all 57 checks |
|---|---|---|---|---|
| 400 | 377:387 | 0.757189 | 0.081816 | 0.000000 |
| 800 | 749:777 | 0.963964 | 0.718698 | 0.000000 |
| 1200 | 1120:1168 | 0.995393 | 0.959292 | 0.737395 |
| 1600 | 1490:1558 | 0.999569 | 0.996124 | 0.975413 |
| 2000 | 1860:1949 | 0.999959 | 0.999635 | 0.997689 |

Increasing confirmation allocation is one possible redesign that preserves the scientific coverage margins and confidence level. It would increase runtime and require an updated pre-run estimate and approval. No allocation change is authorized or implemented by this table.

Astra independently confirmed the n=400 and n=1600 probabilities and recommends holding confirmation admission for an explicit pre-study allocation decision. The alternative 1600 attempts per cell preserves the coverage margins and confidence level but multiplies outer replication by four. It requires measured runtime estimates and approval. The 400-attempt allocation remains authoritative meanwhile.
