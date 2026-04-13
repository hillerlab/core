# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOTOOLS_INTRON — Detect intron retention events using iso-intron.
# Identifies intron retention by comparing query transcripts against a
# reference intron annotation.

version 1.3

task intron {
  input {
    File bed
    File introns
    Int threads = 1
  }

  String prefix = basename(bed, ".bed")

  command <<<
    set -euo pipefail

    iso-intron \
      --introns ~{introns} \
      --query ~{bed} \
      --threads ~{threads} \
      --prefix ~{prefix}
  >>>

  output {
    Array[File] descriptor = glob("*.tsv")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    File bed
    File introns
    Int threads = 1
  }

  call intron {
    input:
      bed = bed,
      introns = introns,
      threads = threads
  }

  output {
    Array[File] descriptor = intron.descriptor
  }
}
