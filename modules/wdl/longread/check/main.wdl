# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# LONGREAD_CHECK — Fail before pbmerge if CCS chunks overlap in
# PacBio's movie/ZMW key space. Scans every chunk BAM in parallel and
# errors if any movie/ZMW key appears in more than one record.

version 1.3

task check {
  input {
    Array[File]+ bams
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    ls -1 ~{sep=' ' bams} > bam.list

    longread check \
      --bams bam.list \
      --out ccs_chunks.valid \
      --threads ~{threads}
  >>>

  output {
    File valid = "ccs_chunks.valid"
  }

  requirements {
    container: "ghcr.io/hillerlab/longread-rs:latest"
  }
}

workflow run {
  input {
    Array[File]+ bams
    Int threads = 1
  }

  call check {
    input:
      bams = bams,
      threads = threads
  }

  output {
    File valid = check.valid
  }
}
