# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TALON_FILTER_TRANSCRIPTS — Select which transcript models belong in the final
# annotation, producing a (gene_id, transcript_id) whitelist. Optional.

version 1.3

task filter {
  input {
    File db
    String annotation_name
    String args = ""
  }

  String prefix = basename(db, ".db")

  command <<<
    set -euo pipefail

    talon_filter_transcripts \
      --db ~{db} \
      -a ~{annotation_name} \
      ~{args} \
      --o "~{prefix}_whitelist.csv"
  >>>

  output {
    File whitelist = "~{prefix}_whitelist.csv"
  }

  requirements {
    container: "quay.io/biocontainers/talon:6.0.1--pyhdfd78af_0"
  }
}

workflow run {
  input {
    File db
    String annotation_name
    String args = ""
  }

  call filter {
    input:
      db = db,
      annotation_name = annotation_name,
      args = args
  }

  output {
    File whitelist = filter.whitelist
  }
}
