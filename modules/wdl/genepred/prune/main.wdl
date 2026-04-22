# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# GENEPRED_PRUNE — Prune BED/GTF/GFF files.

version 1.3

task genepred_prune {
  input {
    File file
    String args = ""
    String prefix = basename(file, ".bed")
  }

  command <<<
    set -euo pipefail

    genepred \
        lint \
        ~{args} \
        --prune \
        ~{file} > ~{prefix}.pruned.bed
  >>>

  output {
    File bed = prefix + ".pruned.bed"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/genepred:latest"
  }
}

workflow run {
  input {
    File file
    String args = ""
    String prefix = basename(file, ".bed")
  }

  call genepred_prune {
    input:
      file = file,
      args = args,
      prefix = prefix
  }

  output {
    File bed = genepred_prune.bed
  }
}