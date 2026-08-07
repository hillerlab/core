# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQC_SNIFF_ADAPTERS — Infer which adapter sequences contaminate CBQ reads.
# Non-destructive: the input is opened read-only and never rewritten. The
# report is always written as JSON, the stable pipeline interface.

version 1.3

task sniff_adapters {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    bqc \
      sniff adapters \
      ~{cbq} \
      --format json \
      -o ~{prefix}.adapters.json \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File report = "~{prefix}.adapters.json"
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

  call sniff_adapters {
    input:
      cbq = cbq,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File report = sniff_adapters.report
  }
}
