# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQC_ADAPTER — Remove 3' adapter sequences from CBQ reads.
# Requires an adapter source (--adapter-r1/--adapter-r2, --adapter-fasta,
# --auto-detect or --paired-overlap) via extra_args; `bqc adapter` refuses to
# trim without one.

version 1.3

task adapter {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    bqc \
      adapter \
      ~{cbq} \
      -o ~{prefix}.adapter.cbq \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File reads = "~{prefix}.adapter.cbq"
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

  call adapter {
    input:
      cbq = cbq,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File reads = adapter.reads
  }
}
