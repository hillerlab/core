# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHROMSIZE — Generate chromosome size files from genome FASTA.
# Extracts sequence lengths from a FASTA genome and outputs a chrom.sizes
# file required by many UCSC tools.

version 1.3

task chromsize {
  input {
    File genome
  }

  String prefix = sub(basename(genome, ".gz"), "\\.(fa|fasta|fna)$", "")
  String out = prefix + "/chrom.sizes"

  command <<<
    set -euo pipefail

    chromsize \
      -s ~{genome} \
      -o ~{prefix}
  >>>

  output {
    File chromsize = out
  }

  requirements {
    container: "ghcr.io/alejandrogzi/chromsize:latest"
  }
}

workflow run {
  input {
    File genome
  }

  call chromsize {
    input:
      genome = genome
  }

  output {
    File chromsize = chromsize.chromsize
  }
}
