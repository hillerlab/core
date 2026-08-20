# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# XLOCI_EXON — Extract exonic loci from genome using reads [bed/gff/gtf].

version 1.3

task exon {
  input {
    File genome
    File reads
    Int threads = 1
  }

  String prefix = sub(basename(reads, ".gz"), "\\.(bed|tsv|txt|fa|fasta|fq|fastq)$", "")

  command <<<
    set -euo pipefail

    xloci \
      -f exon \
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

  call exon {
    input:
      genome = genome,
      reads = reads,
      threads = threads
  }

  output {
    Array[File] fasta = exon.fasta
    Array[File] tsv = exon.tsv
  }
}