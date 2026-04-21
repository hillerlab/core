# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CESAR2 —  A method to realign coding exons or genes to DNA sequences using a 
# Hidden Markov Model. Substantially improves the identification of splice sites 
# that have shifted over a larger distance, which improves the accuracy of detecting 
# the correct exon boundaries. Second, CESAR 2.0 provides a new gene mode that 
# re-aligns entire genes at once

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
