# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_QC — FastQC-inspired quality control on a BINSEQ file.
# Writes a Markdown summary plus per-module TSV files into one directory.

version 1.3

task qc {
  input {
    File bins
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(bins), "\\.[^.]+$", "")

  command <<<
    set -euo pipefail

    bqtools \
      qc \
      ~{bins} \
      -o ~{prefix}_qc \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    Directory report = "~{prefix}_qc"
  }

  requirements {
    container: "ghcr.io/hillerlab/bqtools:latest"
  }
}

workflow run {
  input {
    File bins
    Int threads = 1
    String extra_args = ""
  }

  call qc {
    input:
      bins = bins,
      threads = threads,
      extra_args = extra_args
  }

  output {
    Directory report = qc.report
  }
}
