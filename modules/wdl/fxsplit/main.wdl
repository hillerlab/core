# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# FXSPLIT — Split FASTX/FASTQ reads into chunks for parallel processing.
# Partitions read files into smaller chunks to enable parallel processing
# across multiple CPUs.

version 1.3

task fxsplit {
  input {
    File reads
    Int chunks = 400000
    Int threads = 1
    Boolean singleton = false
  }

  String prefix = sub(basename(reads, ".gz"), "\\.(fastq|fq|fasta|fa)$", "")

  command <<<
    set -euo pipefail

    fxsplit \
      -f ~{reads} \
      -c ~{chunks} \
      -t ~{threads} \
      -C \
      --suffix ~{prefix}

    if ~{if singleton then "true" else "false"}; then
      for f in chunks/*fasta.gz; do
        [ -f "$f" ] || continue
        mv "$f" "${f%}.singleton.fasta.gz"
      done

      for f in chunks/*fastq.gz; do
        [ -f "$f" ] || continue
        mv "$f" "${f%}.singleton.fastq.gz"
      done

      for f in chunks/*fasta; do
        [ -f "$f" ] || continue
        mv "$f" "${f%}.singleton.fasta"
      done

      for f in chunks/*fastq; do
        [ -f "$f" ] || continue
        mv "$f" "${f%}.singleton.fastq"
      done
    fi

    if [[ "~{reads}" == *.gz ]]; then
      mkdir -p chunks/gz
      mv chunks/*fast*.gz chunks/gz
    else
      mkdir -p chunks/fx
      mv chunks/*fast* chunks/fx
    fi
  >>>

  output {
    Array[File] fastx_gz = glob("chunks/gz/*.gz")
    Array[File] fastx = glob("chunks/fx/*.f*")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/fxsplit:latest"
  }
}

workflow run {
  input {
    File reads
    Int chunks = 400000
    Int threads = 1
    Boolean singleton = false
  }

  call fxsplit {
    input:
      reads = reads,
      chunks = chunks,
      threads = threads,
      singleton = singleton
  }

  output {
    Array[File] fastx_gz = fxsplit.fastx_gz
    Array[File] fastx = fxsplit.fastx
  }
}
