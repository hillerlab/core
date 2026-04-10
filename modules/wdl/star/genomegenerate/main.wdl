# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task genomegenerate {
  input {
    File fasta
    File gtf
    Boolean use_gtf = true
    Int threads = 1
    Int genome_sa_index_n_bases = 0
    String extra_args = ""
  }

  command <<<
    set -euo pipefail

    gtf_arg=()
    if ~{if use_gtf then "true" else "false"}; then
      gtf_arg+=(--sjdbGTFfile ~{gtf})
    fi

    if [ "~{genome_sa_index_n_bases}" -gt 0 ]; then
      num_bases="~{genome_sa_index_n_bases}"
    else
      samtools faidx ~{fasta}
      num_bases=$(gawk '{sum = sum + $2} END {if ((log(sum)/log(2))/2 - 1 > 14) {printf "%.0f", 14} else {printf "%.0f", (log(sum)/log(2))/2 - 1}}' ~{fasta}.fai)
    fi

    mkdir -p star
    STAR \
      --runMode genomeGenerate \
      --genomeDir star/ \
      --genomeFastaFiles ~{fasta} \
      "${gtf_arg[@]}" \
      --runThreadN ~{threads} \
      --genomeSAindexNbases "$num_bases" \
      ~{extra_args}
  >>>

  output {
    Directory index = "star"
  }

  requirements {
    container: "community.wave.seqera.io/library/htslib_samtools_star_gawk:ae438e9a604351a4"
  }
}

workflow run {
  input {
    File fasta
    File gtf
    Boolean use_gtf = true
    Int threads = 1
    Int genome_sa_index_n_bases = 0
    String extra_args = ""
  }

  call genomegenerate {
    input:
      fasta = fasta,
      gtf = gtf,
      use_gtf = use_gtf,
      threads = threads,
      genome_sa_index_n_bases = genome_sa_index_n_bases,
      extra_args = extra_args
  }

  output {
    Directory index = genomegenerate.index
  }
}
