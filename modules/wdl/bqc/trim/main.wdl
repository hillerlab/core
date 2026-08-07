# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQC_TRIM — Shorten CBQ reads by position, quality, terminal Ns or poly tails.
# Requires at least one trimming operation via extra_args (e.g. --quality-tail,
# --trim-terminal-n, --poly-g); `bqc trim` refuses to run without one.

version 1.3

task trim {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    bqc \
      trim \
      ~{cbq} \
      -o ~{prefix}.trimmed.cbq \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File reads = "~{prefix}.trimmed.cbq"
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

  call trim {
    input:
      cbq = cbq,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File reads = trim.reads
  }
}
