# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PIGEON_PREPARE_MODELS — Sort and index a query transcript GFF for Pigeon classify.

version 1.3

task prepare_models {
  input {
    File gff
    String args = ""
  }

  String base = sub(gff, "\\.[^\\.]+$", "")
  String out_gtf = base + ".sorted.gtf"

  command <<<
    set -euo pipefail

    pigeon prepare \
      ~{args} \
      ~{gff}
  >>>

  output {
    File sorted_gtf = "~{out_gtf}"
    File pgi = "~{out_gtf}.pgi"
  }

  requirements {
    container: "quay.io/biocontainers/pbpigeon:26.2.0--h9ee0642_0"
  }
}

workflow run {
  input {
    File gff
    String args = ""
  }

  call prepare_models {
    input:
      gff = gff,
      args = args
  }

  output {
    File sorted_gtf = prepare_models.sorted_gtf
    File pgi = prepare_models.pgi
  }
}
