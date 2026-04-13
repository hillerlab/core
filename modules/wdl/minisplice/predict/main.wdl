# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# MINISPLICE_PREDICT — Predict splice site scores using MiniSplice.
# Uses a lightweight neural network model to predict splice site strength
# from genomic sequences.

version 1.3

task predict {
  input {
    File genome
    File model
    File calibration
    Int threads = 1
  }

  String prefix = sub(basename(genome, ".gz"), "\\.(fa|fasta|fna)$", "")
  String out = prefix + "_splice_scores.tsv"

  command <<<
    set -euo pipefail

    minisplice \
      predict \
      -t ~{threads} \
      -c ~{calibration} ~{model} ~{genome} \
      > ~{out}
  >>>

  output {
    File scores = out
  }

  requirements {
    container: "quay.io/biocontainers/minisplice:0.4--h577a1d6_0"
  }
}

workflow run {
  input {
    File genome
    File model
    File calibration
    Int threads = 1
  }

  call predict {
    input:
      genome = genome,
      model = model,
      calibration = calibration,
      threads = threads
  }

  output {
    File scores = predict.scores
  }
}
