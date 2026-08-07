# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BQTOOLS_ENCODE — Encode FASTQ reads into the columnar BINSEQ (CBQ) format.
# A paired FASTQ set collapses into a single .cbq carrying both mates. The BINSEQ
# mode is inferred from the .cbq output extension, so no --mode flag is needed.

version 1.3

task encode {
  input {
    Array[File]+ reads
    Boolean delete_input = false
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(reads[0], ".gz"), "\\.(fastq|fq)$", "")

  command <<<
    set -euo pipefail

    bqtools \
      encode \
      -o ~{prefix}.cbq \
      -T ~{threads} \
      ~{extra_args} \
      ~{sep=' ' reads}

    if [ "~{delete_input}" == "true" ]; then
      # Resolve symlinks and delete actual files
      for file in ~{sep=' ' reads}; do
        if [ -L "$file" ]; then
          realpath=$(readlink -f "$file")
          rm -f "$realpath"
        else
          rm -f "$file"
        fi
      done
    fi
  >>>

  output {
    File cbq = "~{prefix}.cbq"
  }

  requirements {
    container: "ghcr.io/hillerlab/bqtools:latest"
  }
}

workflow run {
  input {
    Array[File]+ reads
    Boolean delete_input = false
    Int threads = 1
    String extra_args = ""
  }

  call encode {
    input:
      reads = reads,
      delete_input = delete_input,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File cbq = encode.cbq
  }
}
