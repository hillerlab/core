# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_COVERAGE — Measure annotation feature coverage by aligned chain blocks.
# Measures how many bases of annotation features (cds/exon/intron/utr) from
# BED/GTF/GFF are covered by chain alignment blocks on the selected side
# (reference/query) in forward genomic coordinates. Reports per-chrom and
# total coverage fractions.

version 1.3

task coverage {
  input {
    Array[File] chains
    File intervals
    String side
    String feature
    Int threads = 1
    String extra_args = ""
    String prefix = ""
  }

  String out_prefix = if prefix == "" then "coverage" else prefix
  String out_report = out_prefix + ".coverage.txt"

  command <<<
    set -euo pipefail

    chaintools coverage \
      --chains ~{sep=" " chains} \
      --side ~{side} \
      --intervals ~{intervals} \
      --feature ~{feature} \
      --threads ~{threads} \
      ~{extra_args} \
      > ~{out_report}
  >>>

  output {
    File report = out_report
  }

  requirements {
    container: "ghcr.io/alejandrogzi/chaintools:latest"
  }
}

workflow run {
  input {
    Array[File] chains
    File intervals
    String side
    String feature
    Int threads = 1
    String extra_args = ""
    String prefix = ""
  }

  call coverage {
    input:
      chains = chains,
      intervals = intervals,
      side = side,
      feature = feature,
      threads = threads,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File report = coverage.report
  }
}
