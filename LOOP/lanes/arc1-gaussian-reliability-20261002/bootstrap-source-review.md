# Bootstrap source review before real execution

The initial Luna component passed 95 controlled-callback assertions. It has not run a real bootstrap or study seed. Parent source review found required repairs, delegated to the active uncertainty-interface worker after the original bootstrap owner finished.

1. Replace `Random.Xoshiro(seed)` with the frozen `MersenneTwister(UInt64)` stream under Julia 1.10.0. Add an independently computed generated-response check, rather than testing only callback counts. Return RNG and seed-derivation metadata.
2. Separate policy/source identity from success eligibility. A legitimate failed K0 can leave 16 derived K1 starts unattempted; it must retain the numerical selection failure, rather than become an identity mismatch because fewer than 19 starts ran. A usable selected fit still requires the full automatic schedule.
3. Pass a request-local selector ledger sink and retain its partial candidate and attempt rows on interruption. The current catch retains the bootstrap index but loses the inner optimizer record. Test interruption during the inner schedule, not only a callback throwing before returning anything.
4. Validate symmetry and positive definiteness of inner genetic and residual covariance matrices before counting an attempt usable. Finite matrices and a ratio inside [0,1] do not exclude two negative-definite matrices. Preserve the failed matrices in diagnostics.

Keep all fixed attempts and the original point fit. Nested summaries need explicit prefix and retained-stream sizes so the B=199 pilot result cannot be confused with its B=999 stored stream. A small real smoke and independent scientific review remain required after these repairs. No calibration or reliability gate is met by the controlled tests.

## Independent replay and interface review

The parent reproduced 117 repaired bootstrap assertions and six Julia interface assertions with a zero exit status. The parent also reproduced ten R control and interval-extraction assertions. These are controlled component checks, without a live twin or real bootstrap fit.

Further source inspection found three consistency gaps. Outer covariance matrices need the same explicit symmetry check as inner matrices. The result must return the actual RNG and Julia version. A generic inner exception must preserve an available partial selector ledger, just as an interruption does.

The R bootstrap bridge used the existing flat row serializer for nested candidate, fit and interruption records. That helper converts nested values to text. The interface worker is replacing this with structured transport and adding parity assertions for the nested values. The public uncertainty accessor must accept both fit and automatic-selection objects and document its actual object argument. Source is still changing; the component replay is not final-source acceptance evidence.
