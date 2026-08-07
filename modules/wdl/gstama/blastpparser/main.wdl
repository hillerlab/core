# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# GSTAMA_BLASTP_PARSER — Concatenate BLASTP outputs and parse them into a TSV with
# gs-tama's ORF blastp parser.

version 1.3

task blastpparser {
  input {
    Array[File]+ blastp
    String args = ""
  }

  String prefix = basename(blastp[0], ".out")

  command <<<
    set -euo pipefail

    cat ~{sep=' ' blastp} > "${prefix}.blastp.txt"

    tama_orf_blastp_parser.py \
      -b "${prefix}.blastp.txt" \
      -o "${prefix}_parsed.tsv" \
      ~{args}
  >>>

  output {
    File tsv = "${prefix}_parsed.tsv"
  }

  requirements {
    container: "quay.io/biocontainers/gs-tama:1.0.3--hdfd78af_0"
  }
}

workflow run {
  input {
    Array[File]+ blastp
    String args = ""
  }

  call blastpparser {
    input:
      blastp = blastp,
      args = args
  }

  output {
    File tsv = blastpparser.tsv
  }
}
