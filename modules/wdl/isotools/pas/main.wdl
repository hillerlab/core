# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOTOOLS_PAS — Call polyadenylation sites using iso-pas.
# Identifies poly(A) sites by analyzing forward and reverse strand peaks
# from RNA-seq data.

version 1.3

task pas {
  input {
    File bed
    File annotation
    File forward_peaks
    File reverse_peaks
    Int threads = 1
  }

  String prefix = basename(bed, ".bed")

  command <<<
    set -euo pipefail

    iso-pas \
      --refs ~{annotation} \
      --query ~{bed} \
      --threads ~{threads} \
      --prefix ~{prefix} \
      -F ~{forward_peaks} \
      -R ~{reverse_peaks}
  >>>

  output {
    Array[File] descriptor = glob("*.tsv")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    File bed
    File annotation
    File forward_peaks
    File reverse_peaks
    Int threads = 1
  }

  call pas {
    input:
      bed = bed,
      annotation = annotation,
      forward_peaks = forward_peaks,
      reverse_peaks = reverse_peaks,
      threads = threads
  }

  output {
    Array[File] descriptor = pas.descriptor
  }
}
