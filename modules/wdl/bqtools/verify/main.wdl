# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_VERIFY — Compute an order-independent checksum over a BINSEQ file.
# Always written as JSON: field list, mate and algorithm included.

version 1.3

task verify {
  input {
    File bins
    String extra_args = ""
  }

  String prefix = sub(basename(bins), "\\.[^.]+$", "")

  command <<<
    set -euo pipefail

    bqtools \
      verify \
      ~{bins} \
      --json \
      ~{extra_args} \
      > ~{prefix}.verify.json
  >>>

  output {
    File report = "~{prefix}.verify.json"
  }

  requirements {
    container: "ghcr.io/hillerlab/bqtools:latest"
  }
}

workflow run {
  input {
    File bins
    String extra_args = ""
  }

  call verify {
    input:
      bins = bins,
      extra_args = extra_args
  }

  output {
    File report = verify.report
  }
}
