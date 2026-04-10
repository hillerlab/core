# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task fusion {
  input {
    Array[File]+ beds
    File reference
    String prefix
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    iso-fusion \
      --ref ~{reference} \
      --query ~{sep=',' beds} \
      --threads ~{threads} \
      --prefix ~{prefix}

    if [ -f ~{prefix}/fusions.fakes.bed ]; then
      cat ~{prefix}/fusions.fakes.bed >> ~{prefix}/fusions.free.bed
    fi

    if [ -f ~{prefix}/fusions.review.bed ]; then
      cat ~{prefix}/fusions.review.bed >> ~{prefix}/fusions.free.bed
    fi
  >>>

  output {
    Array[File] fusion = glob("*/fusions.bed")
    Array[File] free_fusion = glob("*/fusions.free.bed")
    Array[File] descriptor = glob("*/fusions.tsv")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    Array[File]+ beds
    File reference
    String prefix
    Int threads = 1
  }

  call fusion {
    input:
      beds = beds,
      reference = reference,
      prefix = prefix,
      threads = threads
  }

  output {
    Array[File] fusion = fusion.fusion
    Array[File] free_fusion = fusion.free_fusion
    Array[File] descriptor = fusion.descriptor
  }
}
