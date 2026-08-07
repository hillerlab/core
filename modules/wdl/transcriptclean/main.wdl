# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TRANSCRIPTCLEAN — Reference-based correction of mismatches, microindels and
# noncanonical splice junctions in a splice-aware genome alignment. Correction only.

version 1.3

task transcriptclean {
  input {
    File bam
    File genome
    File? splice_jns
    File? variants
    Int threads = 1
    String args = ""
  }

  String prefix = basename(bam, ".bam")

  command <<<
    set -euo pipefail

    # TranscriptClean requires a SAM (splice-aware): convert the aligned BAM first.
    samtools view -h -@ ~{threads} -o "~{prefix}.input.sam" ~{bam}

    TranscriptClean.py \
      --sam "~{prefix}.input.sam" \
      --genome ~{genome} \
      --threads ~{threads} \
      ~{"--spliceJns " + splice_jns} \
      ~{"--variants " + variants} \
      --deleteTmp \
      --outprefix ~{prefix} \
      ~{args}
  >>>

  output {
    File sam = "~{prefix}_clean.sam"
    File? fasta = "~{prefix}_clean.fa"
    File? log = "~{prefix}_clean.log"
    File? te_log = "~{prefix}_clean.TE.log"
  }

  requirements {
    container: "veupathdb/longreadrnaseq:1.0.0"
  }
}

workflow run {
  input {
    File bam
    File genome
    File? splice_jns
    File? variants
    Int threads = 1
    String args = ""
  }

  call transcriptclean {
    input:
      bam = bam,
      genome = genome,
      splice_jns = splice_jns,
      variants = variants,
      threads = threads,
      args = args
  }

  output {
    File clean_sam = transcriptclean.sam
    File? clean_fasta = transcriptclean.fasta
    File? log = transcriptclean.log
    File? te_log = transcriptclean.te_log
  }
}
