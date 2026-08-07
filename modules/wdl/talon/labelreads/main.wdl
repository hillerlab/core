# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TALON_LABEL_READS — Flag each read with the fraction of trailing genomic As
# (internal-priming signal) ahead of TALON annotation.

version 1.3

task labelreads {
  input {
    File sam
    File genome
    Int threads = 1
    String args = ""
  }

  String prefix = basename(sam, ".sam")

  command <<<
    set -euo pipefail

    talon_label_reads \
      --f ~{sam} \
      --g ~{genome} \
      --t ~{threads} \
      ~{args} \
      --o ~{prefix}
  >>>

  output {
    File sam_out = "~{prefix}_labeled.sam"
    File? read_labels = "~{prefix}_read_labels.tsv"
  }

  requirements {
    container: "quay.io/biocontainers/talon:6.0.1--pyhdfd78af_0"
  }
}

workflow run {
  input {
    File sam
    File genome
    Int threads = 1
    String args = ""
  }

  call labelreads {
    input:
      sam = sam,
      genome = genome,
      threads = threads,
      args = args
  }

  output {
    File labeled_sam = labelreads.sam_out
    File? read_labels = labelreads.read_labels
  }
}
