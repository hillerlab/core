# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TALON_INITIALIZE_DATABASE — Build the TALON SQLite database from the reference
# annotation. Runs once per reference.

version 1.3

task initdb {
  input {
    File annotation
    String build
    String annotation_name
    String args = ""
  }

  String prefix = basename(annotation, ".gtf")

  command <<<
    set -euo pipefail

    talon_initialize_database \
      --f ~{annotation} \
      --g ~{build} \
      --a ~{annotation_name} \
      ~{args} \
      --o ~{prefix}
  >>>

  output {
    File db = "~{prefix}.db"
  }

  requirements {
    container: "quay.io/biocontainers/talon:6.0.1--pyhdfd78af_0"
  }
}

workflow run {
  input {
    File annotation
    String build
    String annotation_name
    String args = ""
  }

  call initdb {
    input:
      annotation = annotation,
      build = build,
      annotation_name = annotation_name,
      args = args
  }

  output {
    File db = initdb.db
  }
}
