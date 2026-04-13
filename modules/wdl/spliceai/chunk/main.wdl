# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# SPLICEAI_CHUNK — Chunk genomic sequences for parallel SpliceAI prediction.
# Splits large genomes into smaller chunks to enable parallel processing
# across multiple CPUs while avoiding memory issues.

version 1.3

task chunk {
  input {
    File genome
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    spliceai chunk \
      -t ~{threads} \
      --sequence ~{genome}
  >>>

  output {
    Array[File] fasta = glob("chunks/*.fa")
    Array[File] fasta_gz = glob("chunks/*.fa.gz")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/spliceai:latest"
  }
}

workflow run {
  input {
    File genome
    Int threads = 1
  }

  call chunk {
    input:
      genome = genome,
      threads = threads
  }

  output {
    Array[File] fasta = chunk.fasta
    Array[File] fasta_gz = chunk.fasta_gz
  }
}
