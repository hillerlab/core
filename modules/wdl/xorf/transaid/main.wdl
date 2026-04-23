# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TRANSAID — Predicts translation initiation sites using TransAID deep learning
# models.

version 1.3

task transaid {
  input {
    String meta_id
    String meta_name
    File sequence
    File bed
    String args = ""
  }

  String out_prefix = meta_id + "_transaid"

  command <<<
    set -euo pipefail

    transaid \
    --input ~{sequence} \
    --gpu -1 \
    --output ~{out_prefix} \
    ~{args}

    mv *csv ~{meta_id}.~{meta_name}.transaid.csv
    PREDICTION_COUNT=$(wc -l < ~{meta_id}.~{meta_name}.transaid.csv)

    rm *.faa

    cat <<-END_VERSIONS > versions.yml
    "TRANSAID":
        transaid: $(transaid --version 2>&1 | sed 's/.*Version: //')
    END_VERSIONS
  >>>

  output {
    Array[File] transaid = glob("*.csv")
    Int count = read_int("PREDICTION_COUNT")
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/orf-net:latest"
  }
}

workflow run {
  input {
    String meta_id
    String meta_name
    File sequence
    File bed
    String args = ""
  }

  call transaid {
    input:
      meta_id = meta_id,
      meta_name = meta_name,
      sequence = sequence,
      bed = bed,
      args = args
  }

  output {
    Array[File] transaid = transaid.transaid
    Int count = transaid.count
    File versions = transaid.versions
  }
}
