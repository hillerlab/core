# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# GENEPRED_LINT — Lint BED/GTF/GFF files.

version 1.3

task genepred_lint {
  input {
    File file
    String args = ""
  }

  command <<<
    set -euo pipefail

    genepred \
        lint \
        ~{args} \
        ~{file}
  >>>

  output {
  }

  requirements {
    container: "ghcr.io/alejandrogzi/genepred:latest"
  }
}

workflow run {
  input {
    File file
    String args = ""
  }

  call genepred_lint {
    input:
      file = file,
      args = args
  }

  output {
  }
}