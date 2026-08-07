# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQC_SNIFF_STRAND — Infer RNA-seq library strandedness by mapping CBQ reads
# against a Salmon 2.x transcriptome index.
# ponytail: the hillerlab/bqc image is built with default cargo features, so
# this subcommand is not compiled in and fails at runtime until the image is
# rebuilt with --features sniff-strand.

version 1.3

task sniff_strand {
  input {
    File cbq
    Directory index
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    bqc \
      sniff strand \
      ~{cbq} \
      --index ~{index} \
      --format json \
      -o ~{prefix}.strand.json \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File report = "~{prefix}.strand.json"
  }

  requirements {
    container: "ghcr.io/hillerlab/bqc:latest"
  }
}

workflow run {
  input {
    File cbq
    Directory index
    Int threads = 1
    String extra_args = ""
  }

  call sniff_strand {
    input:
      cbq = cbq,
      index = index,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File report = sniff_strand.report
  }
}
