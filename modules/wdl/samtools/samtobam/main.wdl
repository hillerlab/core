# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task samtobam {
  input {
    File sam
    Int threads = 1
  }

  String bam_path = basename(sam, ".sam") + ".bam"
  String bai_path = bam_path + ".bai"

  command <<<
    set -euo pipefail

    samtools \
      view \
      -@ ~{threads} \
      -b ~{sam} \
      | samtools \
          sort \
          -@ ~{threads} \
          -o ~{bam_path}

    samtools \
      index \
      -@ ~{threads} \
      ~{bam_path}
  >>>

  output {
    File bam = bam_path
    File bai = bai_path
  }

  requirements {
    container: "biocontainers/samtools:1.23--h96c455f_0"
  }
}

workflow run {
  input {
    File sam
    Int threads = 1
  }

  call samtobam {
    input:
      sam = sam,
      threads = threads
  }

  output {
    File bam = samtobam.bam
    File bai = samtobam.bai
  }
}
