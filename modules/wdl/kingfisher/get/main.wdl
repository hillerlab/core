# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# KINGFISHER_GET — Downloads SRA runs from the Sequence Read Archive using kingfisher.

version 1.3

task kingfisher_get {
  input {
    String accession
    String provider = "ena-ftp,aws-http,aws-cp"
  }

  command <<<
    set -euo pipefail

    kingfisher get \
      -r ~{accession} \
      -m ~{provider}
  >>>

  output {
    Array[File] fastq = glob("*.fastq.gz")
    Array[File] fasta = glob("*.fasta")
    Array[File] bam = glob("*.bam")
    File versions = "versions.yml"
  }

  requirements {
    container: "quay.io/biocontainers/kingfisher:0.5.0--pyhdfd78af_0"
  }
}

workflow run {
  input {
    String accession
    String provider = "ena-ftp aws-http aws-cp"
  }

  call kingfisher_get {
    input:
      accession = accession,
      provider = provider
  }

  output {
    Array[File] fastq = kingfisher_get.fastq
    Array[File] fasta = kingfisher_get.fasta
    Array[File] bam = kingfisher_get.bam
  }
}
