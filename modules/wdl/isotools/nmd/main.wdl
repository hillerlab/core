# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOTOOLS_NMD — Detect nonsense-mediated decay candidates using iso-nmd.
# Identifies transcripts likely subject to nonsense-mediated decay based
# on premature termination codon positions.

version 1.3

task nmd {
  input {
    File bed
    Int threads = 1
  }

  String prefix = basename(bed, ".bed")

  command <<<
    set -euo pipefail

    iso-nmd \
      --bed ~{bed} \
      --threads ~{threads} \
      --prefix ~{prefix} \
      --outdir nmd
  >>>

  output {
    Array[File] reads = glob("nmd/*reads.bed")
    Array[File] nmd = glob("nmd/*nmd.bed")
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

  call nmd {
    input:
      bed = bed,
      threads = threads
  }

  output {
    Array[File] reads = nmd.reads
    Array[File] nmd = nmd.nmd
  }
}
