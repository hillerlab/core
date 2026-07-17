# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# DESALT_ALIGN — Align reads to a genome using deSALT

version 1.3

task align {
  input {
    File reads
    Directory index
    File? gtf
    Int threads = 1
    String prefix
    String args = ""
  }

  command <<<
    set -euo pipefail

    gtf_arg=""
    if [ -n "~{default="" gtf}" ]; then
      gtf_arg="--gtf ~{gtf}"
    fi

    deSALT aln \
      ~{args} \
      $gtf_arg \
      --thread ~{threads} \
      --output ~{prefix}.sam \
      ~{index} \
      ~{reads}

    cat <<-END_VERSIONS > versions.yml
    "DESALT_ALIGN":
        deSALT: $(deSALT 2>&1 | grep 'Version' | awk '{print $2}')
    END_VERSIONS
  >>>

  output {
    File sam = prefix + ".sam"
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/hillerlab/desalt:latest"
  }
}

workflow run {
  input {
    File reads
    Directory index
    File? gtf
    Int threads = 1
    String prefix
    String args = ""
  }

  call align {
    input:
      reads = reads,
      index = index,
      gtf = gtf,
      threads = threads,
      prefix = prefix,
      args = args
  }

  output {
    File sam = align.sam
    File versions = align.versions
  }
}
