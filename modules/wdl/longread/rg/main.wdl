# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# LONGREAD_RG — Canonicalize PBSIM3 subread BAMs as one synthetic PacBio
# movie before merging. Assigns deterministic global ZMWs, rewrites QNAME
# and zm tags, and emits a read-group-compliant BAM per input.

version 1.3

task rg {
  input {
    Array[File]+ bams
    String prefix = "output"
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    ls -1 ~{sep=' ' bams} > bam.list

    longread rg \
      --movie "movie.~{prefix}" \
      --bams bam.list \
      --outdir . \
      --zmw-map zmw_map.tsv \
      --threads ~{threads}
  >>>

  output {
    Array[File] normalized_bam = glob("*.normalized.bam")
    File zmw_map = "zmw_map.tsv"
  }

  requirements {
    container: "ghcr.io/hillerlab/longread-rs:latest"
  }
}

workflow run {
  input {
    Array[File]+ bams
    String prefix = "output"
    Int threads = 1
  }

  call rg {
    input:
      bams = bams,
      prefix = prefix,
      threads = threads
  }

  output {
    Array[File] normalized_bam = rg.normalized_bam
    File zmw_map = rg.zmw_map
  }
}
