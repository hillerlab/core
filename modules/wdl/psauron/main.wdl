# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PSAURON — Predict splice sites from genomic sequences using Psauron.
# A deep learning model for splice site prediction from genomic FASTA
# sequences, producing CSV output with predicted splice probabilities.

version 1.3

task psauron {
  input {
    File fasta
    String prefix = sub(basename(fasta), "\\.(fa|fasta|fa\\.gz|fasta\\.gz)$", "")
    String args = ""
  }

  String csv_path = prefix + ".csv"

  command <<<
    set -euo pipefail

    psauron \
      ~{args} \
      -i ~{fasta} \
      -o ~{csv_path} \
      --use-cpu
  >>>

  output {
    File csv = csv_path
  }

  requirements {
    container: "quay.io/biocontainers/psauron:1.1.3--pyhdfd78af_0"
  }
}

workflow run {
  input {
    File fasta
    String prefix = sub(basename(fasta), "\\.(fa|fasta|fa\\.gz|fasta\\.gz)$", "")
    String args = ""
  }

  call psauron {
    input:
      fasta = fasta,
      prefix = prefix,
      args = args
  }

  output {
    File csv = psauron.csv
  }
}
