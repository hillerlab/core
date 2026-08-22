# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_STATS — Summarize alignment, gap, and continuity statistics.
# Streams a chain file and reports GENERAL/ALIGNMENT/CONTINUITY/GAPS/STRAND/SCORE
# plus optional per-target fragmentation (--by-sequence) and top chains.

version 1.3

task stats {
  input {
    File chain
    Int threads = 1
    String extra_args = ""
    String prefix = ""
  }

  String base = sub(basename(chain, ".gz"), "\\.chain$", "")
  String out_prefix = if prefix == "" then base else prefix
  String out_report = out_prefix + ".stats.txt"

  command <<<
    set -euo pipefail

    chaintools stats \
      --chain ~{chain} \
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
    File chain
    Int threads = 1
    String extra_args = ""
    String prefix = ""
  }

  call stats {
    input:
      chain = chain,
      threads = threads,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File report = stats.report
  }
}
