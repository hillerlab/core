# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# DEACON_CBQ_FILTER — Filter CBQ reads using a Deacon transcript index.
# The CBQ-native variant of DEACON_FILTER: reads are detected as CBQ by magic
# bytes and written when the output path ends in .cbq. CBQ pairing is native,
# so paired reads stay in one file and --output2 must not be used.
# Depletion (--deplete) is enabled via extra_args, as in DEACON_FILTER.

version 1.3

task filter {
  input {
    File cbq
    File index
    Int threads = 1
    String extra_args = ""
  }

  String prefix = basename(cbq, ".cbq")

  command <<<
    set -euo pipefail

    deacon \
      filter \
      --threads ~{threads} \
      -o ~{prefix}.deacon.cbq \
      -s ~{prefix}.deacon.json \
      ~{extra_args} \
      ~{index} \
      ~{cbq} \
      > ~{prefix}.deacon.log 2>&1
  >>>

  output {
    File out_cbq = "~{prefix}.deacon.cbq"
    File summary = "~{prefix}.deacon.json"
    File log = "~{prefix}.deacon.log"
  }

  requirements {
    container: "ghcr.io/hillerlab/deacon-cbq:latest"
  }
}

workflow run {
  input {
    File cbq
    File index
    Int threads = 1
    String extra_args = ""
  }

  call filter {
    input:
      cbq = cbq,
      index = index,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File out_cbq = filter.out_cbq
    File summary = filter.summary
    File log = filter.log
  }
}
