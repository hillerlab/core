# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task derive {
  input {
    File genome
    File annotation
    Directory spliceai
    Int threads = 1
  }

  String prefix = basename(annotation, ".bed")
  String out = prefix + ".derived.tsv"

  command <<<
    set -euo pipefail

    spliceai derive \
      -t ~{threads} \
      --bigwig-dir ~{spliceai} \
      --sequence ~{genome} \
      --regions ~{annotation} \
      --prefix ~{prefix}
  >>>

  output {
    File scores = out
  }

  requirements {
    container: "ghcr.io/hillerlab/containers/spliceai:latest"
  }
}

workflow run {
  input {
    File genome
    File annotation
    Directory spliceai
    Int threads = 1
  }

  call derive {
    input:
      genome = genome,
      annotation = annotation,
      spliceai = spliceai,
      threads = threads
  }

  output {
    File scores = derive.scores
  }
}
