# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOTOOLS_ALIGN — Select long reads whose pass-1 split alignment suggests a
# re-align with a larger minimap2 intron cap, and emit them as FASTA / FASTQ / names.

version 1.3

task align {
  input {
    File bam
    File bai
    String args = ""
    String prefix = sub(basename(bam), "\\.bam$", "")
  }

  command <<<
    set -euo pipefail

    iso-align \
        ~{args} \
        --threads ~{cpus} \
        --bam ~{bam} \
        --output ~{prefix}.fragments.fasta \
        --output-format fasta \
        --report ~{prefix}.report.tsv

    if [ ! -s ~{prefix}.fragments.fasta ]; then
        rm ~{prefix}.fragments.fasta
    fi
  >>>

  output {
    File? fragments = prefix + ".fragments.fasta"
    File? report = prefix + ".report.tsv"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    File bam
    File bai
    String args = ""
  }

  call align {
    input:
      bam = bam,
      bai = bai,
      args = args
  }

  output {
    File? fragments = align.fragments
    File? report = align.report
  }
}
