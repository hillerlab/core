# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQC_FILTER — Accept or reject CBQ reads against per-read predicates.
# Rejected records are kept in a separate CBQ (--failed), so nothing is lost.
# Requires at least one predicate via extra_args (e.g. --min-length, --max-n).

version 1.3

task filter {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    bqc \
      filter \
      ~{cbq} \
      -o ~{prefix}.filtered.cbq \
      --failed ~{prefix}.failed.cbq \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File reads = "~{prefix}.filtered.cbq"
    File failed = "~{prefix}.failed.cbq"
  }

  requirements {
    container: "ghcr.io/hillerlab/bqc:latest"
  }
}

workflow run {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  call filter {
    input:
      cbq = cbq,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File reads = filter.reads
    File failed = filter.failed
  }
}
