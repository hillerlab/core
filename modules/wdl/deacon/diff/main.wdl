# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# DEACON_DIFF — Compute differential transcript indexes using Deacon.
# Finds transcripts present in one sample but absent in another by comparing
# two transcript indexes.

version 1.3

task diff {
  input {
    File index_a
    File index_b
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(index_a, ".idx") + "_filtered"
  String index_path = prefix + ".idx"

  command <<<
    set -euo pipefail

    deacon \
      index \
      diff \
      --threads ~{threads} \
      --output ~{index_path} \
      ~{extra_args} \
      ~{index_a} \
      ~{index_b}
  >>>

  output {
    File index = index_path
  }

  requirements {
    container: "biocontainers/deacon:0.13.2--h7ef3eeb_1"
  }
}

workflow run {
  input {
    File index_a
    File index_b
    Int threads = 1
    String extra_args = ""
  }

  call diff {
    input:
      index_a = index_a,
      index_b = index_b,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File index = diff.index
  }
}
