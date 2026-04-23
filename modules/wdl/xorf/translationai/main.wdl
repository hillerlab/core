# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TRANSLATIONAI — Runs translational inference (TAI) on ORF predictions through a
# Rust wrapper. Requires specifiying the upstream and downstream amount of nucleotides
# extended from the incoming file.

version 1.3

task translation {
  input {
    String meta_id
    String meta_name
    File bed
    File sequence
    Int upstream = 1000
    Int downstream = 1000
  }

  command <<<
    set -euo pipefail

    orf tai \
    --fasta ~{sequence} \
    --bed ~{bed} \
    --outdir ~{meta_id} \
    -u ~{upstream} \
    -d ~{downstream}

    mv ~{meta_id}/tai/*result ~{meta_id}/ && rm -rf ~{meta_id}/tai

    cat <<-END_VERSIONS > versions.yml
    "TRANSLATION":
        orf-tai: $(orf --version 2>&1 | sed 's/^.*orf //; s/ .*$//')
        translationai: 0.0.1
    END_VERSIONS
  >>>

  output {
    File input_bed = bed
    File input_sequence = sequence
    Array[File] predictions = glob("${meta_id}/*result")
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/orf-tai:latest"
  }
}

workflow run {
  input {
    String meta_id
    String meta_name
    File bed
    File sequence
    Int upstream = 1000
    Int downstream = 1000
  }

  call translation {
    input:
      meta_id = meta_id,
      meta_name = meta_name,
      bed = bed,
      sequence = sequence,
      upstream = upstream,
      downstream = downstream
  }

  output {
    File input_bed = translation.input_bed
    File input_sequence = translation.input_sequence
    Array[File] predictions = translation.predictions
    File versions = translation.versions
  }
}
