# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# STRINGTIE3 — Transcript assembly and quantification for RNA-seq.
# Assembles transcripts from BAM alignments and quantifies their
# expression in GTF format.

version 1.3

task stringtie3 {
  input {
    File bam
    String strandedness = "unstranded"
    String args = ""
    Int threads = 1
  }

  String prefix = basename(bam, ".bam")

  command <<<
    set -euo pipefail

    strand_arg=""
    if [ "~{strandedness}" = "forward" ]; then
      strand_arg="--fr"
    elif [ "~{strandedness}" = "reverse" ]; then
      strand_arg="--rf"
    fi

    stringtie \
      ~{bam} \
      $strand_arg \
      -o ~{prefix}.transcripts.gtf \
      -p ~{threads} \
      ~{args}
  >>>

  output {
    File gtf = prefix + ".transcripts.gtf"
  }

  requirements {
    container: "biocontainers/stringtie:3.0.3--h29c0135_0"
  }
}

workflow run {
  input {
    File bam
    String strandedness = "unstranded"
    String args = ""
    Int threads = 1
  }

  call stringtie3 {
    input:
      bam = bam,
      strandedness = strandedness,
      args = args,
      threads = threads
  }

  output {
    File gtf = stringtie3.gtf
  }
}
