# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# LONGREAD_PBSIM — Generate PBSIM3 transcript simulations using longread.
# Reads sequence, isoform depth, and manifest files to produce simulated
# transcript abundance tables for PacBio simulation.

version 1.3

task pbsim3 {
  input {
    File sequences
    File isoform_depth
    File manifest
    String prefix = "output"
  }

  String tsv_path = prefix + ".pbsim.transcript.tsv"

  command <<<
    set -euo pipefail

    longread pbsim \
      --sequences ~{sequences} \
      --isoform-depth ~{isoform_depth} \
      --manifest ~{manifest} \
      --output ~{tsv_path}
  >>>

  output {
    File transcript = tsv_path
  }

  requirements {
    container: "ghcr.io/hillerlab/longread-rs:latest"
  }
}

workflow run {
  input {
    File sequences
    File isoform_depth
    File manifest
    String prefix = "output"
  }

  call pbsim3 {
    input:
      sequences = sequences,
      isoform_depth = isoform_depth,
      manifest = manifest,
      prefix = prefix
  }

  output {
    File transcript = pbsim3.transcript
  }
}
