# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# FLAIR_TRANSCRIPTOME — Build a high-confidence isoform annotation directly from a
# coordinate-sorted, indexed genome-aligned BAM (FLAIR 3.0 `flair transcriptome`).
# Annotation only.

version 1.3

task transcriptome {
  input {
    File bam
    File bai
    File genome
    File? annotation
    File? shortread_sj
    Int threads = 1
    String args = ""
  }

  String prefix = basename(bam, ".bam")

  command <<<
    set -euo pipefail

    flair transcriptome \
      -b ~{bam} \
      -g ~{genome} \
      ~{"-f " + annotation} \
      ~{"--shortread " + shortread_sj} \
      -o ~{prefix} \
      -t ~{threads} \
      ~{args}
  >>>

  output {
    File gtf = "~{prefix}.isoforms.gtf"
    File bed = "~{prefix}.isoforms.bed"
    File? cds_bed = "~{prefix}.isoforms.CDS.bed"
    File? fasta = "~{prefix}.isoforms.fa"
    File? read_map = "~{prefix}.read.map.txt"
  }

  requirements {
    container: "quay.io/biocontainers/flair:3.0.0--pyhdfd78af_0"
  }
}

workflow run {
  input {
    File bam
    File bai
    File genome
    File? annotation
    File? shortread_sj
    Int threads = 1
    String args = ""
  }

  call transcriptome {
    input:
      bam = bam,
      bai = bai,
      genome = genome,
      annotation = annotation,
      shortread_sj = shortread_sj,
      threads = threads,
      args = args
  }

  output {
    File gtf = transcriptome.gtf
    File bed = transcriptome.bed
    File? cds_bed = transcriptome.cds_bed
    File? fasta = transcriptome.fasta
    File? read_map = transcriptome.read_map
  }
}
