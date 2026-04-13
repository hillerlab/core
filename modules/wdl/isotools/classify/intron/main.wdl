# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOTOOLS_CLASSIFY_INTRON — Classify intronic intervals using iso-classify.
# Classifies introns from long-read data using genome, annotation, repeats,
# and optional SpliceAI BigWig files.

version 1.3

task classify_intron {
  input {
    File reads
    File genome
    File annotation
    File? intronic
    File? repeats
    File? bigwig
  }

  String prefix = sub(basename(reads, ".gz"), "\\.(bed|bam|tsv)$", "")

  command <<<
    set -euo pipefail

    spliceai_arg=()
    repeats_arg=()
    iic_arg=()

    if [ -n "~{default="" bigwig}" ]; then
      spliceai_arg+=(--bigwig "~{default="" bigwig}")
    fi

    if [ -n "~{default="" repeats}" ]; then
      repeats_arg+=(--repeats "~{default="" repeats}")
    fi

    if [ -n "~{default="" intronic}" ] && [ -s "~{default="" intronic}" ]; then
      iic_arg+=(--iic "~{default="" intronic}")
    fi

    iso-classify intron \
      --isoseq ~{reads} \
      --sequence ~{genome} \
      --toga ~{annotation} \
      --prefix ~{prefix} \
      "${spliceai_arg[@]}" \
      "${repeats_arg[@]}" \
      "${iic_arg[@]}" \
      --outdir .
  >>>

  output {
    Array[File] tsv = glob("*.tsv")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    File reads
    File genome
    File annotation
    File? intronic
    File? repeats
    File? bigwig
  }

  call classify_intron {
    input:
      reads = reads,
      genome = genome,
      annotation = annotation,
      intronic = intronic,
      repeats = repeats,
      bigwig = bigwig
  }

  output {
    Array[File] tsv = classify_intron.tsv
  }
}
