# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_CAT — Concatenate multiple BINSEQ files into one.
# The output variant is inherited from the first input file.

version 1.3

task cat {
  input {
    Array[File]+ bins
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(bins[0]), "\\.[^.]+$", "")
  String ext = sub(basename(bins[0]), "^.*\\.", "")

  command <<<
    set -euo pipefail

    bqtools \
      cat \
      ~{sep=' ' bins} \
      -o ~{prefix}.cat.~{ext} \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    Array[File] combined = glob("~{prefix}.cat.*")
  }

  requirements {
    container: "ghcr.io/hillerlab/bqtools:latest"
  }
}

workflow run {
  input {
    Array[File]+ bins
    Int threads = 1
    String extra_args = ""
  }

  call cat {
    input:
      bins = bins,
      threads = threads,
      extra_args = extra_args
  }

  output {
    Array[File] combined = cat.combined
  }
}
