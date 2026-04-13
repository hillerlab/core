# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# APARENT_PREDICT — Predict polyadenylation sites using APARENT deep learning model.
# Uses a convolutional neural network to predict poly(A) signal usage and
# polyadenylation site strength from genomic sequences.

version 1.3

task predict {
  input {
    File chunk_tsv
    File weights
  }

  String prefix = basename(chunk_tsv, ".tsv")

  command <<<
    set -euo pipefail

    aparent predict \
      --bed ~{chunk_tsv} \
      --outdir aparent \
      --prefix ~{prefix} \
      --model ~{weights}
  >>>

  output {
    Array[File] bed = glob("aparent/*.aparent.bed")
    Array[File] bg_forward = glob("aparent/*.aparent.forward.bg")
    Array[File] bg_reverse = glob("aparent/*.aparent.reverse.bg")
  }

  requirements {
    container: "ghcr.io/hillerlab/aparent:latest"
  }
}

workflow run {
  input {
    File chunk_tsv
    File weights
  }

  call predict {
    input:
      chunk_tsv = chunk_tsv,
      weights = weights
  }

  output {
    Array[File] bed = predict.bed
    Array[File] bg_forward = predict.bg_forward
    Array[File] bg_reverse = predict.bg_reverse
  }
}
