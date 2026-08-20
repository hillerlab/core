# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# HSPZ — GPU-accelerated high-scoring ungapped alignment pair backend.
# Runs upstream hspZ, resulting in per-block LASTZ workload as a tarball.
# This task runs on GPU, so the CPU gapped-extension stage downstream is
# unchanged.

version 1.3

task hspz {
  input {
    String reference_name
    File reference_sequence
    String query_name
    File query_sequence
    Boolean tar = true
    String args = ""
  }

  command <<<
    set -euo pipefail

    hspZ \
      run \
      ~{args} \
      -r ~{reference_sequence} \
      -q ~{query_sequence} \
      -o segments \
      -D \
      ~{if tar then "-Z" else ""} \
      --time \
      --dump-plan plan.tsv
  >>>

  output {
    Array[File] segments = glob("segments/*.segments")
    Array[File] tarball = glob("segments/*.tar.gz")
    File plan = "plan.tsv"
  }

  requirements {
    container: "ghcr.io/hillerlab/hspz:latest"
  }
}

workflow run {
  input {
    String reference_name
    File reference_sequence
    String query_name
    File query_sequence
    Boolean tar = true
    String args = ""
  }

  call hspz {
    input:
      reference_name = reference_name,
      reference_sequence = reference_sequence,
      query_name = query_name,
      query_sequence = query_sequence,
      tar = tar,
      args = args
  }

  output {
    Array[File] segments = hspz.segments
    Array[File] tarball = hspz.tarball
    File plan = hspz.plan
  }
}