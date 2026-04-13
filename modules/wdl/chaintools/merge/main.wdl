# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_MERGE — Merge chains into a single chain file.
# Merges multiple chain files into a single chain file that
# can be sorted and/or gzipped.

version 1.3

task merge {
  input {
    Array[File] chains
    Int threads = 1
    String extra_args = ""
  }

  String out_chain = "merged.chain"

  command <<<
    set -euo pipefail

    chaintools merge \
      --chains ~{sep="," chains} \
      --threads ~{threads} \
      --out-chain ~{out_chain} \
      ~{extra_args}
  >>>

  output {
    File merged_chain = out_chain
    File merged_chain_gz = out_chain + ".gz"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/chaintools:latest"
  }
}

workflow run {
  input {
    Array[File] chains
    Int threads = 1
    String extra_args = ""
  }

  call merge {
    input:
      chains = chains,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File merged_chain = merge.merged_chain
    File merged_chain_gz = merge.merged_chain_gz
  }
}