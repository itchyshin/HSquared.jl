# Arc 1 temporary execution pause

## 1. Goal

Prevent reviewed Arc 1 launchers from starting an attempt while the chosen
Totoro attempt record lacks a verified history and rollback protection.

## 2. Implemented

The standard Python cell runner, pilot and diagnostic launch gates, their
reviewed direct workers, and the Julia executable refuse before creating a new
attempt or invoking the admitted engine. Read-only plan and receipt inspection
remain available. The pause is unconditional and has no mode or environment
switch. It is not an operational Totoro registry.

## 3a. Decisions and Rejected Alternatives

Shinichi selected Totoro as the proposed single-host authority. Two recovered
receipts cannot establish a complete history. A caller-controlled test-mode
exception or a per-output-directory lock would leave a bypass. The planned
record remains disabled until its history and rollback checks are verified.

## 4. Files Touched

The Arc 1 Python runner, cell, pilot and diagnostic launchers; the Julia attempt
command; focused Python and Julia tests; the CI workflow; and this report and
its check-log shard.

## 5. Checks Run

Six no-fit Python launch-refusal tests, five execution-scope tests and thirteen
synthetic diagnostic tests passed locally. Six Julia CLI assertions passed,
including a forged engineering-probe input and checks for absent output. A
fake-engine subprocess passed using a deliberately modified temporary script.
The full Julia suite and hosted CI are required for the final branch identity.

## 6. Tests of the Tests

Before the pause, the new Python controls failed and the Julia command tried to
read a missing input. After the pause, the controls refused before execution.
The temporary fake-engine copy removes the pause for internal executor tests;
it does not demonstrate that the unmodified CLI can launch.

## 7a. Issue Ledger

The incomplete history, the source maps and the attempt authority remain open.
No scientific gate or attempt count changes.

## 8. Consistency Audit

Independent review checked the reviewed launch points for mode, environment
and output-root bypasses. Diagnostic and pilot entry points refuse before their
own reservation or start-record side effects. CI runs the new Python no-fit
regression on Linux.

## 9. What Did Not Go Smoothly

A local pilot test required an unavailable historical fixture. Two local
receipt tests could not reach their assertions because the available candidate
manifest rejected a historical seed-context collision. These outcomes are
recorded as local environment and evidence gaps, not passes.

## 10. Known Residuals

Direct included functions, custom launchers, old checkouts and deliberate code
changes remain outside this pause. The per-cell store's `begin` can still be
called directly to write a local start record. A synthetic SQLite prototype
passed local and Totoro process-race tests, but it is not integrated and its
public initialization and reservation functions always refuse. Power-loss,
rollback, production history and full-host guarantees remain unverified.

## 11. Team Learning

Stopping only the Julia command can be too late: a batch launcher may already
have written a start record. Refuse before each supported launcher mutates its
attempt state.

## 12. Cross-Product Coverage

This pause covers the reviewed Python launchers and Julia command. It does NOT cover
direct engine calls, old checkouts or other custom launchers. No scientific fit,
study attempt, R contract change, capability promotion or historical gate credit
is claimed. The pause does not authorize resuming Arc 1 studies.
