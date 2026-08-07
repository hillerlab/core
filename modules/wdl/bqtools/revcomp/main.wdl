# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_REVCOMP — Reverse complement the sequences in a BINSEQ file,
# preserving its format and configuration. Both mates by default; use
# --mate 1|2 via extra_args for one mate only. The output variant is inherited
# from the input file.

version 1.3

task revcomp {
  input {
    File bins
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(bins), "\\.[^.]+$", "")
  String ext = sub(basename(bins), "^.*\\.", "")

  command <<<
    set -euo pipefail

    bqtools \
      revcomp \
      ~{bins} \
      -o ~{prefix}.revcomp.~{ext} \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    Array[File] revcomped = glob("~{prefix}.revcomp.*")
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

  call revcomp {
    input:
      bins = bins,
      threads = threads,
      extra_args = extra_args
  }

  output {
    Array[File] revcomped = revcomp.revcomped
  }
}
