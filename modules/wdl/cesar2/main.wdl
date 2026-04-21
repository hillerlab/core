# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CESAR2 — Generate chromosome size files from genome FASTA.
# Extracts sequence lengths from a FASTA genome and outputs a chrom.sizes
# file required by many UCSC tools.

version 1.3

task cesar2 {
  input {
    String meta_id
    File fasta
    String args = ""
  }

  command <<<
    set -euo pipefail

    cesar \
      ~{args} \
      --max-memory ~{memory} \
      ~{fasta}

    cat <<-END_VERSIONS > versions.yml
    "CESAR2":
        cesar: $(cesar --version | sed -e "s/cesar v//g")
    END_VERSIONS
  >>>

  output {
    File cesar = meta_id + ".fa"
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/hillerlab/cesar2:latest"
  }
}

workflow run {
  input {
    String meta_id
    File fasta
    String args = ""
  }

  call cesar2 {
    input:
      meta_id = meta_id,
      fasta = fasta,
      args = args
  }

  output {
    File cesar = cesar2.cesar
    File versions = cesar2.versions
  }
}