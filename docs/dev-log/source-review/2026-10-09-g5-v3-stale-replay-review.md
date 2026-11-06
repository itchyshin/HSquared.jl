# Arc 1 G5 retained-artifact replay candidate v3 review

Decision: HOLD. This candidate is obsolete and authorizes no artifact read or replay.

Independent reviewer: Astra source-review lane, read-only.

Candidate SHA-256: `58628f9e398b617965dcc80a495ad17a77ca615ec98097579b63ea4d7784ca29`.

The reviewer identified four blockers: the candidate reuses the terminal v6 artifact and output directory; its supplemental inspector hash `fc58f9444affe63c21ec854212ae00220728bf2f933735fd73e4cf71faf6b206` is stale relative to current source `d14a5eca4f39e833409031cab6c76f6227678010205357ec19475648c9e99e9e`; the launcher, process supervisor, runtime wrapper, and result checker are not pinned as executable safeguards; and the required checks do not require a retained successful result. The local original-source mirror also differs from the original admission at executor and inspector files.

No remote connection, artifact access, or execution occurred. The terminal v6 replay remains terminal. A different plan requires a new proposal, exact source review, and a clearly authorized path; it cannot reuse this candidate or claim G5 evidence.
