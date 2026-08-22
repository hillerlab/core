# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_COMPARE — Compare exact mappings, coverage, ambiguity, and continuity.
# Canonicalizes two chain files and reports mapping agreement, coverage deltas,
# and interpretation. Fails if estimated canonical mappings exceed --memory-ceiling.

version 1.3

task compare {
  input {
    File chain_a
    File chain_b
    Int threads = 1
    String extra_args = ""
    String prefix = ""
  }

  String base_a = sub(basename(chain_a, ".gz"), "\\.chain$", "")
  String base_b = sub(basename(chain_b, ".gz"), "\\.chain$", "")
  String out_prefix = if prefix == "" then base_a + "_vs_" + base_b else prefix
  String out_report = out_prefix + ".compare.txt"

  command <<<
    set -euo pipefail

    chaintools compare \
      --chain-a ~{chain_a} \
      --chain-b ~{chain_b} \
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
    File chain_a
    File chain_b
    Int threads = 1
    String extra_args = ""
    String prefix = ""
  }

  call compare {
    input:
      chain_a = chain_a,
      chain_b = chain_b,
      threads = threads,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File report = compare.report
  }
}
