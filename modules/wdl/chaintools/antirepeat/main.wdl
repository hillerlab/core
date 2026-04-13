# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_ANTIREPEAT — Remove chains that are primarily the result of
# repeats of degenerated DNA. Output is a suffixed .clean.chain file.

version 1.3

task antirepeat {
  input {
    File chain
    File reference
    File query
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(chain, ".gz"), "\\.chain$", "")
  String out_chain = prefix + ".clean.chain"

  command <<<
    set -euo pipefail

    chaintools antirepeat \
      --chain ~{chain} \
      --reference ~{reference} \
      --query ~{query} \
      --threads ~{threads} \
      --out-chain ~{out_chain} \
      ~{extra_args}
  >>>

  output {
    File clean_chain = out_chain
    File clean_chain_gz = out_chain + ".gz"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/chaintools:latest"
  }
}

workflow run {
  input {
    File chain
    File reference
    File query
    Int threads = 1
    String extra_args = ""
  }

  call antirepeat {
    input:
      chain = chain,
      reference = reference,
      query = query,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File clean_chain = antirepeat.clean_chain
    File clean_chain_gz = antirepeat.clean_chain_gz
  }
}