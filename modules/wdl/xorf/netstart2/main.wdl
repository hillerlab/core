# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# NETSTART2 — Predicts translation initiation sites using neural networks

version 1.3

task netstart2 {
  input {
    String meta_id
    String meta_name
    File sequence
    File bed
    String args = ""
  }

  String out_prefix = meta_id + "_netstart"

  command <<<
    set -euo pipefail

    netstart2 \
    -in ~{sequence} \
    -compute_device cpu \
    -o chordata \
    -out ~{out_prefix} \
    ~{args}

    PREDICTION_COUNT=$(wc -l < ~{meta_id}*csv)

    cat <<-END_VERSIONS > versions.yml
    "NETSTART2":
        netstart2: $(netstart2 --version 2>&1 | sed 's/.*Version: //')
    END_VERSIONS
  >>>

  output {
    Array[File] netstart = glob("${meta_id}*csv")
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

  call netstart2 {
    input:
      meta_id = meta_id,
      meta_name = meta_name,
      sequence = sequence,
      bed = bed,
      args = args
  }

  output {
    Array[File] netstart = netstart2.netstart
    Int count = netstart2.count
    File versions = netstart2.versions
  }
}
