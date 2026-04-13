# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_FILTER — Filter chains by chain score/target/query.
# Filters input chains by chain score/target/query/gap/strand/id according
# to the specified filter criteria. Output is a filtered chain file.

version 1.3

task filter {
  input {
    File chain
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(chain, ".gz"), "\\.chain$", "")
  String out_chain = prefix + ".filtered.chain"

  command <<<
    set -euo pipefail

    chaintools filter \
      --chain ~{chain} \
      --threads ~{threads} \
      --out-chain ~{out_chain} \
      ~{extra_args}
  >>>

  output {
    File filtered_chain = out_chain
    File filtered_chain_gz = out_chain + ".gz"
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

  call filter {
    input:
      chain = chain,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File filtered_chain = filter.filtered_chain
    File filtered_chain_gz = filter.filtered_chain_gz
  }
}