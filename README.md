# I2C Chip Verification (UVM)

UVM-based verification environment for an I2C controller, built as a course project.
Includes constrained-random + directed tests, functional coverage, and protocol checks.

## What’s in here
- `project_benches/` : testbenches / top-level sims
- `verification_ip/` : verification components (agents/monitors/scoreboard as applicable)
- `docs/` : notes / diagrams (if any)

## Tooling
- Simulator: Questa/ModelSim (tested on: <YOUR VERSION/OS>)

## How to run (Questa/ModelSim)
This repo contains a Makefile-driven flow (see `project_benches/` history).
From the relevant bench directory, try:
```sh
make compile
make sim
