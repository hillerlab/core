# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# GSTAMA_ORF_SEEKER — Predict open reading frames in a transcript FASTA with gs-tama.

version 1.3

task orfseeker {
  input {
    File fasta
    String args = ""
  }

  String prefix = basename(fasta, ".fasta")

  command <<<
    set -euo pipefail

    tama_orf_seeker.py \
      -f ~{fasta} \
      -o "~{prefix}_orfs.fa" \
      ~{args}
  >>>

  output {
    File fasta_out = "~{prefix}_orfs.fa"
  }

  requirements {
    container: "quay.io/biocontainers/gs-tama:1.0.3--hdfd78af_0"
  }
}

workflow run {
  input {
    File fasta
    String args = ""
  }

  call orfseeker {
    input:
      fasta = fasta,
      args = args
  }

  output {
    File orfs = orfseeker.fasta_out
  }
}
