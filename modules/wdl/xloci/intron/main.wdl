# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# XLOCI_INTRON — Extract intronic loci from genome and RNA-seq reads.
# Identifies novel intronic transcription by comparing genome sequences
# against RNA-seq reads.

version 1.3

task intron {
  input {
    File genome
    File reads
    Int threads = 1
  }

  String prefix = sub(basename(reads, ".gz"), "\\.(bed|tsv|txt|fa|fasta|fq|fastq)$", "")

  command <<<
    set -euo pipefail

    xloci \
      -f intron \
      -o . \
      -s ~{genome} \
      -r ~{reads} \
      -t ~{threads} \
      --prefix ~{prefix}
  >>>

  output {
    Array[File] fasta = glob("*.fa")
    Array[File] tsv = glob("*.tsv")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/xloci:latest"
  }
}

workflow run {
  input {
    File genome
    File reads
    Int threads = 1
  }

  call intron {
    input:
      genome = genome,
      reads = reads,
      threads = threads
  }

  output {
    Array[File] fasta = intron.fasta
    Array[File] tsv = intron.tsv
  }
}
