# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_DECODE — Convert BINSEQ back to FASTQ.
# Default decodes to a single interleaved FASTQ; set split_mates to write
# separate _R1/_R2 files instead (the bqtools --prefix mode).

version 1.3

task decode {
  input {
    File bins
    Boolean split_mates = false
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(bins), "\\.[^.]+$", "")

  command <<<
    set -euo pipefail

    bqtools \
      decode \
      ~{bins} \
      ~{if split_mates then "--prefix " + prefix + " -f q" else "-o " + prefix + ".fastq"} \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File? fastq = "~{prefix}.fastq"
    File? fastq_r1 = "~{prefix}_R1.fq"
    File? fastq_r2 = "~{prefix}_R2.fq"
  }

  requirements {
    container: "ghcr.io/hillerlab/bqtools:latest"
  }
}

workflow run {
  input {
    File bins
    Boolean split_mates = false
    Int threads = 1
    String extra_args = ""
  }

  call decode {
    input:
      bins = bins,
      split_mates = split_mates,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File? fastq = decode.fastq
    File? fastq_r1 = decode.fastq_r1
    File? fastq_r2 = decode.fastq_r2
  }
}
