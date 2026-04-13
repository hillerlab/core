# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_SORT — Sort chains by chain score/target/query.
# Sorts input chains by chain score/target/query according to the
# specified sort order. Output is a sorted chain file.

version 1.3

task sort {
  input {
    File chain
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(chain, ".gz"), "\\.chain$", "")
  String out_chain = prefix + ".sorted.chain"

  command <<<
    set -euo pipefail

    chaintools sort \
      --chain ~{chain} \
      --threads ~{threads} \
      --out-chain ~{out_chain} \
      ~{extra_args}
  >>>

  output {
    File sorted_chain = out_chain
    File sorted_chain_gz = out_chain + ".gz"
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
  }

  call sort {
    input:
      chain = chain,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File sorted_chain = sort.sorted_chain
    File sorted_chain_gz = sort.sorted_chain_gz
  }
}