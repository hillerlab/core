# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQC_SEGMENT — Split reads at internal adapter occurrences.
# One read becomes zero, one or many records, so it cannot be part of a
# `bqc workflow`. Single-end input only. The provenance sidecar is always
# written: it is the only surviving provenance on header-free input.

version 1.3

task segment {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    bqc \
      segment \
      ~{cbq} \
      -o ~{prefix}.segmented.cbq \
      --segments ~{prefix}.segments.tsv \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File reads = "~{prefix}.segmented.cbq"
    File segments = "~{prefix}.segments.tsv"
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

  call segment {
    input:
      cbq = cbq,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File reads = segment.reads
    File segments = segment.segments
  }
}
