# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task align {
  input {
    File reads
    File reference
    String prefix
    Int threads = 1
    File? splice_scores
    File? junc_bed
  }

  String out = prefix + ".sam"

  command <<<
    set -euo pipefail

    spsc_arg=()
    junc_arg=()

    if [ -n "~{default="" splice_scores}" ]; then
      spsc_arg+=(--spsc="~{default="" splice_scores}")
    fi

    if [ -n "~{default="" junc_bed}" ]; then
      junc_arg+=(--junc-bed "~{default="" junc_bed}")
    fi

    minimap2 \
      "${spsc_arg[@]}" \
      "${junc_arg[@]}" \
      -t ~{threads} \
      ~{reference} \
      ~{reads} \
      -o ~{out}
  >>>

  output {
    File sam = out
  }

  requirements {
    container: "biocontainers/minimap2:2.30--h577a1d6_0"
  }
}

workflow run {
  input {
    File reads
    File reference
    String prefix
    Int threads = 1
    File? splice_scores
    File? junc_bed
  }

  call align {
    input:
      reads = reads,
      reference = reference,
      prefix = prefix,
      threads = threads,
      splice_scores = splice_scores,
      junc_bed = junc_bed
  }

  output {
    File sam = align.sam
  }
}
