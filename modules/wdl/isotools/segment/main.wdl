# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task segment {
  input {
    File bam
    File bai
    Int batch
    Boolean singleton = false
  }

  String prefix = basename(bam, ".bam")
  String singleton_flag = if singleton then "--singleton" else ""

  command <<<
    set -euo pipefail

    iso-segment \
      --bam ~{bam} \
      --prefix ~{prefix} \
      --batch ~{batch} \
      ~{singleton_flag}

    if ~{if singleton then "true" else "false"}; then
      for f in *~{prefix}.hq.bed; do
        [ -f "$f" ] || continue
        mv "$f" "${f%.hq.bed}.~{batch}.singleton.hq.bed"
      done
    else
      for f in *~{prefix}.hq.bed; do
        [ -f "$f" ] || continue
        mv "$f" "${f%.hq.bed}.~{batch}.hq.bed"
      done
    fi
  >>>

  output {
    Array[File] hq_bam = glob("*.hq.bam")
    Array[File] hq_bed = glob("*.hq.bed")
    Array[File] lq_bam = glob("*.lq.bam")
    Array[File] lq_bed = glob("*.lq.bed")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    File bam
    File bai
    Int batch
    Boolean singleton = false
  }

  call segment {
    input:
      bam = bam,
      bai = bai,
      batch = batch,
      singleton = singleton
  }

  output {
    Array[File] hq_bam = segment.hq_bam
    Array[File] hq_bed = segment.hq_bed
    Array[File] lq_bam = segment.lq_bam
    Array[File] lq_bed = segment.lq_bed
  }
}
