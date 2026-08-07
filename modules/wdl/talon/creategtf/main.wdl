# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TALON_CREATE_GTF — Export the observed transcript annotation from the TALON
# database, optionally restricted to a whitelist. No abundance/counts exported.

version 1.3

task creategtf {
  input {
    File db
    String build
    String annotation_name
    File? whitelist
    String args = ""
  }

  String prefix = basename(db, ".db")

  command <<<
    set -euo pipefail

    talon_create_GTF \
      --db ~{db} \
      -b ~{build} \
      -a ~{annotation_name} \
      --observed \
      ~{"--whitelist " + whitelist} \
      ~{args} \
      --o ~{prefix}
  >>>

  output {
    File gtf = glob("~{prefix}_talon*.gtf")[0]
  }

  requirements {
    container: "quay.io/biocontainers/talon:6.0.1--pyhdfd78af_0"
  }
}

workflow run {
  input {
    File db
    String build
    String annotation_name
    File? whitelist
    String args = ""
  }

  call creategtf {
    input:
      db = db,
      build = build,
      annotation_name = annotation_name,
      whitelist = whitelist,
      args = args
  }

  output {
    File gtf = creategtf.gtf
  }
}
