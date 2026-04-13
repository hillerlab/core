# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# APARENT_CHUNK — Chunk genomic regions for parallel APARENT prediction.
# Splits genomic regions from a BED file into chunks that can be processed
# in parallel by the APARENT predict step.

version 1.3

task chunk {
  input {
    File bed
    File genome
    Int threads = 1
  }

  String prefix = basename(bed, ".bed")

  command <<<
    set -euo pipefail

    aparent chunk \
      -b ~{bed} \
      -g ~{genome} \
      -t ~{threads} \
      -o ~{prefix} \
      --prefix ~{prefix}
  >>>

  output {
    Array[File] chunks = glob("chunks/*.tsv")
  }

  requirements {
    container: "ghcr.io/hillerlab/aparent:latest"
  }
}

workflow run {
  input {
    File bed
    File genome
    Int threads = 1
  }

  call chunk {
    input:
      bed = bed,
      genome = genome,
      threads = threads
  }

  output {
    Array[File] chunks = chunk.chunks
  }
}
