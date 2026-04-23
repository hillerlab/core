# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHUNKER — Splits genomic regions (BED/GTF/GFF) and sequences (2bit/FA/FA.GZ)
# into chunks for parallel processing. Allows to extend the extracted chunk by a given
# upstream and downstream amount of nucleotides. Additionally, it allows to specify
# the number of chunks to be generated.

version 1.3

task chunk {
  input {
    String meta_id
    String meta_chr
    File regions
    File sequence
    Int chunk_size
    Int upstream = 1000
    Int downstream = 1000
    String prefix = meta_chr
  }

  command <<<
    set -euo pipefail

    orf chunk \
    --regions ~{regions} \
    --sequence ~{sequence} \
    --chunks ~{chunk_size} \
    -u ~{upstream} \
    -d ~{downstream} \
    --prefix ~{prefix} \
    --ignore-errors

    cat <<-END_VERSIONS > versions.yml
    "CHUNKER":
        orf-chunk: $(orf --version 2>&1 | sed 's/^.*orf //; s/ .*$//')
    END_VERSIONS
  >>>

  output {
    Array[File] chunked_regions = glob("tmp/*bed")
    Array[File] chunked_sequences = glob("tmp/*fa")
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/orf-chunk:latest"
  }
}

workflow run {
  input {
    String meta_id
    String meta_chr
    File regions
    File sequence
    Int chunk_size
    Int upstream = 1000
    Int downstream = 1000
    String prefix = meta_chr
  }

  call chunk {
    input:
      meta_id = meta_id,
      meta_chr = meta_chr,
      regions = regions,
      sequence = sequence,
      chunk_size = chunk_size,
      upstream = upstream,
      downstream = downstream,
      prefix = prefix
  }

  output {
    Array[File] chunked_regions = chunk.chunked_regions
    Array[File] chunked_sequences = chunk.chunked_sequences
    File versions = chunk.versions
  }
}
