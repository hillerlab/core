# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# DEACON_FILTER — Filter reads using a Deacon transcript index.
# Removes reads that map to a reference index, keeping only novel
# transcripts for downstream analysis.

version 1.3

task filter {
  input {
    Array[File]+ reads
    File index
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(reads[0], ".gz"), "\\.(fastq|fq)$", "")
  String log_path = prefix + ".deacon.log"

  command <<<
    set -euo pipefail

    deacon \
      filter \
      --threads ~{threads} \
      --output ~{prefix}_1.deacon.fastq.gz \
      --output2 ~{prefix}_2.deacon.fastq.gz \
      ~{extra_args} \
      ~{index} \
      ~{sep=' ' reads} \
      > ~{log_path} 2>&1
  >>>

  output {
    Array[File] reads = glob("*.deacon.fastq.gz")
    File log = log_path
  }

  requirements {
    container: "biocontainers/deacon:0.13.2--h7ef3eeb_1"
  }
}

workflow run {
  input {
    Array[File]+ reads
    File index
    Int threads = 1
    String extra_args = ""
  }

  call filter {
    input:
      reads = reads,
      index = index,
      threads = threads,
      extra_args = extra_args
  }

  output {
    Array[File] reads = filter.reads
    File log = filter.log
  }
}
