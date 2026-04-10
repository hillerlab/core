# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task predict {
  input {
    File fasta
  }

  command <<<
    set -euo pipefail

    spliceai predict \
      --outdir spliceai \
      --offset 50000 \
      --sequence ~{fasta}
  >>>

  output {
    Array[File] donor_plus = glob("spliceai/*.donor_plus.wig")
    Array[File] donor_minus = glob("spliceai/*.donor_minus.wig")
    Array[File] acceptor_plus = glob("spliceai/*.acceptor_plus.wig")
    Array[File] acceptor_minus = glob("spliceai/*.acceptor_minus.wig")
    Array[File] all = glob("spliceai/*.wig")
  }

  requirements {
    container: "ghcr.io/hillerlab/containers/spliceai:latest"
  }
}

workflow run {
  input {
    File fasta
  }

  call predict {
    input:
      fasta = fasta
  }

  output {
    Array[File] donor_plus = predict.donor_plus
    Array[File] donor_minus = predict.donor_minus
    Array[File] acceptor_plus = predict.acceptor_plus
    Array[File] acceptor_minus = predict.acceptor_minus
    Array[File] all = predict.all
  }
}
