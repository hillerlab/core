# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# MERGEBAM — Merge multiple BAM files into one.
# Combines several BAM files into a single sorted BAM file using samtools merge.

version 1.3

task mergebam {
  input {
    Array[File]+ bams
    String prefix
    Int threads = 1
  }

  String bam_path = prefix + ".bam"
  String bai_path = bam_path + ".bai"

  command <<<
    set -euo pipefail

    samtools merge \
      -@ ~{threads} \
      -f \
      ~{bam_path} \
      ~{sep=' ' bams}

    samtools index \
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
    Array[File]+ bams
    String prefix
    Int threads = 1
  }

  call mergebam {
    input:
      bams = bams,
      prefix = prefix,
      threads = threads
  }

  output {
    File bam = mergebam.bam
    File bai = mergebam.bai
  }
}
