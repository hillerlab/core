# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# RNASAMBA — Classifies ORFs as coding or non-coding using RNAsamba machine learning
# models through a Rust wrapper. Requires specifiying the upstream and downstream
# amount of nucleotides extended from the incoming file.

version 1.3

task samba {
  input {
    String meta_id
    String meta_name
    File bed
    File sequence
    File weights
    Int upstream = 1000
    Int downstream = 1000
    String args = ""
  }

  command <<<
    set -euo pipefail

    orf samba \
    --fasta ~{sequence} \
    --outdir ~{meta_id} \
    --upstream-flank ~{upstream} \
    --downstream-flank ~{downstream} \
    --weights ~{weights} \
    ~{args}

    mv ~{meta_id}/samba/*tsv ~{meta_id}/~{meta_id}.~{meta_name}.samba.tsv && rm -rf ~{meta_id}/samba
    mv ~{meta_name}.tmp.strip.fa ~{meta_id}/~{meta_id}.~{meta_name}.strip.fa

    cat <<-END_VERSIONS > versions.yml
    "RNASAMBA":
        orf-samba: $(orf --version 2>&1 | sed 's/^.*orf //; s/ .*$//')
        rnasamba: $(rnasamba --version 2>&1 | tail -n 1 | sed 's/^rnasamba //')
    END_VERSIONS
  >>>

  output {
    Array[File] samba = glob("${meta_id}/*tsv")
    Array[File] fasta = glob("${meta_id}/*strip.fa")
    File input_bed = bed
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/orf-samba:latest"
  }
}

workflow run {
  input {
    String meta_id
    String meta_name
    File bed
    File sequence
    File weights
    Int upstream = 1000
    Int downstream = 1000
    String args = ""
  }

  call samba {
    input:
      meta_id = meta_id,
      meta_name = meta_name,
      bed = bed,
      sequence = sequence,
      weights = weights,
      upstream = upstream,
      downstream = downstream,
      args = args
  }

  output {
    Array[File] samba = samba.samba
    Array[File] fasta = samba.fasta
    File input_bed = samba.input_bed
    File versions = samba.versions
  }
}
