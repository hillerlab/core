# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQC_WORKFLOW — CBQ-native all-in-one quality control.
# Runs the adapter, trim and filter stages in a single pass and writes a
# structured JSON report used to populate the run samplesheet.

version 1.3

task bqc_workflow {
  input {
    File cbq
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    # NOTE: `bqc workflow` aborts with "no operation configured" when no adapter,
    # trim, filter or correction option is given, so extra_args must never be empty.
    # The bqc_* defaults in nextflow.config guarantee at least --min-length.
    bqc \
      workflow \
      ~{cbq} \
      -o ~{prefix}.clean.cbq \
      --report ~{prefix}.bqc.json \
      --report-format json \
      -T ~{threads} \
      ~{extra_args}
  >>>

  output {
    File reads = "~{prefix}.clean.cbq"
    File report = "~{prefix}.bqc.json"
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

  call bqc_workflow {
    input:
      cbq = cbq,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File reads = bqc_workflow.reads
    File report = bqc_workflow.report
  }
}
