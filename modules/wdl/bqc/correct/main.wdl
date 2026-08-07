# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQC_CORRECT — Correct low-quality bases from the other mate where the pair
# overlaps. Requires paired input with stored qualities; single-end or
# quality-free input is refused before processing starts.

version 1.3

task correct {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    bqc \
      correct \
      ~{cbq} \
      -o ~{prefix}.corrected.cbq \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File reads = "~{prefix}.corrected.cbq"
  }

  requirements {
    container: "ghcr.io/hillerlab/bqc:latest"
  }
}

workflow run {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  call correct {
    input:
      cbq = cbq,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File reads = correct.reads
  }
}
