# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_SCORE — Remove chains that are primiarily the result of
# repeats of degenerated DNA. Output is a suffixed .scored.chain file.

version 1.3

task score {
  input {
    File chain
    File reference
    File query
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(chain, ".gz"), "\\.chain$", "")
  String out_chain = prefix + ".scored.chain"

  command <<<
    set -euo pipefail

    chaintools score \
      --chain ~{chain} \
      --reference ~{reference} \
      --query ~{query} \
      --threads ~{threads} \
      --sort-by-score \
      --out-chain ~{out_chain} \
      ~{extra_args}
  >>>

  output {
    File scored_chain = out_chain
    File scored_chain_gz = out_chain + ".gz"
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

  call score {
    input:
      chain = chain,
      reference = reference,
      query = query,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File scored_chain = score.scored_chain
    File scored_chain_gz = score.scored_chain_gz
  }
}
