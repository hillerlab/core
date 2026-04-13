# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOTOOLS_UTR — Detect 3'UTR truncation events using iso-utr.
# Identifies potential 3'UTR truncation sites by comparing query and reference
# transcript annotations.

version 1.3

task utr {
  input {
    File bed
    Int threads = 1
  }

  String prefix = basename(bed, ".bed")

  command <<<
    set -euo pipefail

    iso-utr \
      --ref ~{bed} \
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
    Int threads = 1
  }

  call utr {
    input:
      bed = bed,
      threads = threads
  }

  output {
    Array[File] descriptor = utr.descriptor
  }
}
