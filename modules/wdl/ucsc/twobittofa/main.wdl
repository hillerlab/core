# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TWOBIT_TO_FA — Convert 2bit files to FASTA format.
# Uses UCSC twoBitToFa to extract sequences from .2bit binary files.

version 1.3

task twobittofa {
  input {
    File twobit
    String args = ""
  }

  String prefix = basename(twobit, ".2bit")

  command <<<
    set -euo pipefail

    twoBitToFa ~{args} "~{twobit}" ~{prefix}.fasta
  >>>

  output {
    File fasta = "~{prefix}.fasta"
  }

  requirements {
    container: "quay.io/biocontainers/ucsc-twobittofa:482--hdc0a859_0"
  }
}

workflow run {
  input {
    File twobit
    String args = ""
  }

  call twobittofa {
    input:
      twobit = twobit,
      args = args
  }

  output {
    File fasta = twobittofa.fasta
  }
}