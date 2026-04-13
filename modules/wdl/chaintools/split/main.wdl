# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINTOOLS_SPLIT — Split chains into multiple chain files/chunks.
# Splits input chains into multiple chain files/chunks according to the
# specified number of chunks/files. Output is always under chains/ directory.

version 1.3

task split {
  input {
    File chain
    Int threads = 1
    String extra_args = ""
  }

  command <<<
    set -euo pipefail

    chaintools split \
      --chain ~{chain} \
      --threads ~{threads} \
      ~{extra_args}
  >>>

  output {
    Array[File] chains = glob("chains/*.chain")
    Array[File] chains_gz = glob("chains/*.chain.gz")
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

  call split {
    input:
      chain = chain,
      threads = threads,
      extra_args = extra_args
  }

  output {
    Array[File] chains = split.chains
    Array[File] chains_gz = split.chains_gz
  }
}