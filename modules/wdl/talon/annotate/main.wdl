# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TALON_ANNOTATE — Match labelled reads to the reference transcript database,
# assigning known/novel transcript models. Updates a local copy of the database.
# Annotation only.

version 1.3

task annotate {
  input {
    File labeled_sam
    File db
    String build
    String platform
    Int threads = 1
    String args = ""
  }

  String prefix = basename(labeled_sam, ".sam")

  command <<<
    set -euo pipefail

    # TALON config CSV: dataset_name,description,platform,sam_file (absolute path).
    sam_full=$( readlink -f ~{labeled_sam} )
    echo "~{prefix},~{prefix},~{platform},${sam_full}" > "~{prefix}_config.csv"

    # copy the database first so the annotator mutates a local copy.
    cp ~{db} "~{prefix}_annotated.db"

    talon \
      --f "~{prefix}_config.csv" \
      --db "~{prefix}_annotated.db" \
      --build ~{build} \
      --threads ~{threads} \
      ~{args} \
      --o ~{prefix}
  >>>

  output {
    File db_out = "~{prefix}_annotated.db"
    File? read_annotation = "~{prefix}_talon_read_annot.tsv"
    File? log = "~{prefix}_QC.log"
  }

  requirements {
    container: "quay.io/biocontainers/talon:6.0.1--pyhdfd78af_0"
  }
}

workflow run {
  input {
    File labeled_sam
    File db
    String build
    String platform
    Int threads = 1
    String args = ""
  }

  call annotate {
    input:
      labeled_sam = labeled_sam,
      db = db,
      build = build,
      platform = platform,
      threads = threads,
      args = args
  }

  output {
    File annotated_db = annotate.db_out
    File? read_annotation = annotate.read_annotation
    File? log = annotate.log
  }
}
