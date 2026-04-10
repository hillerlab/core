# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task index {
  input {
    File fasta
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(fasta, ".gz"), "\\.(fa|fasta|fna)$", "")
  String index_path = prefix + ".idx"

  command <<<
    set -euo pipefail

    deacon \
      index \
      build \
      --threads ~{threads} \
      ~{extra_args} \
      ~{fasta} > ~{index_path}
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
    File fasta
    Int threads = 1
    String extra_args = ""
  }

  call index {
    input:
      fasta = fasta,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File index = index.index
  }
}
