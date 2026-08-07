# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_GREP — Search BINSEQ records for subsequences or regexes.
# Matching records are written to a FASTQ file; pass patterns (positional,
# --file, or --count for per-pattern counting) via extra_args.

version 1.3

task grep {
  input {
    File bins
    String extra_args
  }

  String prefix = sub(basename(bins), "\\.[^.]+$", "")

  command <<<
    set -euo pipefail

    bqtools \
      grep \
      ~{bins} \
      ~{extra_args} \
      -o ~{prefix}.matches.fastq
  >>>

  output {
    File matches = "~{prefix}.matches.fastq"
  }

  requirements {
    container: "ghcr.io/hillerlab/bqtools:latest"
  }
}

workflow run {
  input {
    File bins
    String extra_args
  }

  call grep {
    input:
      bins = bins,
      extra_args = extra_args
  }

  output {
    File matches = grep.matches
  }
}
