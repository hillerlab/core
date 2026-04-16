# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOTOOLS_CIGAR — Rescuing missed 3' splice junctions by CIGAR matching.
# Additional arguments may change results (--clip-cutoff {}, -E {} and --wiggle {}).

version 1.3

task cigar {
  input {
    File bam
    File bai
    File genome
    File annotation
    Int threads = 1
    String args = ""
  }

  command <<<
    set -euo pipefail

    iso-cigar \
      ~{args} \
      --bam ~{bam} \
      --annotation ~{annotation} \
      --sequence ~{genome} \
      --split-bam \
      --threads ~{threads}
  >>>

  output {
    Array[File] aligned = glob("*.align.bam")
    Array[File] aligned_index = glob("*.align.bam.bai")
    Array[File] extended = glob("*.extended.bam")
    Array[File] extended_index = glob("*.extended.bam.bai")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    File bam
    File bai
    File genome
    File annotation
    Int threads = 1
    String args = ""
  }

  call cigar {
    input:
      bam = bam,
      bai = bai,
      genome = genome,
      annotation = annotation,
      threads = threads,
      args = args
  }

  output {
    Array[File] aligned = cigar.aligned
    Array[File] aligned_index = cigar.aligned_index
    Array[File] extended = cigar.extended
    Array[File] extended_index = cigar.extended_index
  }
}