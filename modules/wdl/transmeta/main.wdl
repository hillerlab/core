# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TRANSMETA — Multi-sample RNA-seq transcript meta-assembly.
# Simultaneously assembles RNA-seq reads of multiple samples into a unified
# set of transcripts (GTF) and a set of transcripts for each individual sample.

version 1.3

task transmeta {
  input {
    Array[File]+ bams
    File? annotation
    Boolean single_end = false
    String strandedness = "unstranded"
    String args = ""
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    printf '%s\n' ~{sep=' ' bams} > bam.list

    if ~{if single_end then "true" else "false"}; then
      if [ "~{strandedness}" = "reverse" ]; then
        strand="single_reverse"
      elif [ "~{strandedness}" = "forward" ]; then
        strand="single_forward"
      else
        strand="single_unstranded"
      fi
    else
      if [ "~{strandedness}" = "reverse" ]; then
        strand="second"
      elif [ "~{strandedness}" = "forward" ]; then
        strand="first"
      else
        strand="unstranded"
      fi
    fi

    annotation_arg=""
    if [ -n "~{default="" annotation}" ]; then
      annotation_arg="-g ~{default="" annotation}"
    fi

    TransMeta \
      -B bam.list \
      -s "$strand" \
      -o transmeta_outdir \
      -p ~{threads} \
      $annotation_arg \
      ~{args}
  >>>

  output {
    File gtf = "transmeta_outdir/TransMeta.gtf"
    Array[File] meta_gtf = glob("transmeta_outdir/TransMeta-[0-9]*.gtf")
    Array[File] sample_gtf = glob("transmeta_outdir/TransMeta.bam*.gtf")
    Array[File] ag_gtf = glob("transmeta_outdir/TransMeta-AG*.gtf")
  }

  requirements {
    container: "ghcr.io/hillerlab/transmeta:latest"
  }
}

workflow run {
  input {
    Array[File]+ bams
    File? annotation
    Boolean single_end = false
    String strandedness = "unstranded"
    String args = ""
    Int threads = 1
  }

  call transmeta {
    input:
      bams = bams,
      annotation = annotation,
      single_end = single_end,
      strandedness = strandedness,
      args = args,
      threads = threads
  }

  output {
    File gtf = transmeta.gtf
    Array[File] meta_gtf = transmeta.meta_gtf
    Array[File] sample_gtf = transmeta.sample_gtf
    Array[File] ag_gtf = transmeta.ag_gtf
  }
}
