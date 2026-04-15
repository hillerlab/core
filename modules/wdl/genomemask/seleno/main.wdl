# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# GENOMEMASK_SELENO — Masks selenocysteine codons of the genome using a
# derived database of selenocysteine codons. Additional arguments may be
# required (--output-format {} and --nucleotide {}).

version 1.3

task seleno {
  input {
    File genome
    File selenocysteine
    String args = ""
    String meta_id = "genomemask"
  }

  String out_2bit = meta_id + ".2bit"
  String out_fasta = meta_id + ".fa"
  String out_fasta_gz = meta_id + ".fa.gz"

  command <<<
    set -euo pipefail

    genomemask \
        ~{args} \
        --sequence ~{genome} \
        --selenocysteine ~{selenocysteine}

    cat <<-END_VERSIONS > versions.yml
    "GENOMEMASK_SELENO":
        genomemask: $( genomemask --version | head -n 1 | sed 's/genomemask //g' | sed 's/ (.*//g' )
    END_VERSIONS
  >>>

  output {
    File? twobit = glob(out_2bit)[0]
    File? fasta = glob(out_fasta)[0]
    File? fasta_gz = glob(out_fasta_gz)[0]
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/genomemask:latest"
  }
}

workflow run {
  input {
    File genome
    File selenocysteine
    String args = ""
    String meta_id = "genomemask"
  }

  call seleno {
    input:
      genome = genome,
      selenocysteine = selenocysteine,
      args = args,
      meta_id = meta_id
  }

  output {
    File? twobit = seleno.twobit
    File? fasta = seleno.fasta
    File? fasta_gz = seleno.fasta_gz
    File versions = seleno.versions
  }
}
