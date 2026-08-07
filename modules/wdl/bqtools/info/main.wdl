# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_INFO — Show information and statistics about a BINSEQ file.
# Always written as JSON: raw numerical values, no underscore delimiters.

version 1.3

task info {
  input {
    File bins
    String extra_args = ""
  }

  String prefix = sub(basename(bins), "\\.[^.]+$", "")

  command <<<
    set -euo pipefail

    bqtools \
      info \
      ~{bins} \
      --json \
      ~{extra_args} \
      > ~{prefix}.info.json
  >>>

  output {
    File report = "~{prefix}.info.json"
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

  call info {
    input:
      bins = bins,
      extra_args = extra_args
  }

  output {
    File report = info.report
  }
}
