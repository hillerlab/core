# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_SPLIT — Split a BINSEQ file into per-pattern files.
# Patterns come from a pattern file (plain text, FASTA or TSV with alias);
# records matching no pattern land in an unmatched file. Per-pattern output
# files are named after the pattern alias.

version 1.3

task split {
  input {
    File bins
    File patterns
    String extra_args = ""
  }

  String prefix = sub(basename(bins), "\\.[^.]+$", "")

  command <<<
    set -euo pipefail

    bqtools \
      split \
      ~{bins} \
      --file ~{patterns} \
      --basepath ~{prefix}_split \
      ~{extra_args}
  >>>

  output {
    Array[File] split_bins = glob("~{prefix}_split/*")
  }

  requirements {
    container: "ghcr.io/hillerlab/bqtools:latest"
  }
}

workflow run {
  input {
    File bins
    File patterns
    String extra_args = ""
  }

  call split {
    input:
      bins = bins,
      patterns = patterns,
      extra_args = extra_args
  }

  output {
    Array[File] split_bins = split.split_bins
  }
}
