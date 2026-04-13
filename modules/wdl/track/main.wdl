# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# TRACKDB — Generate UCSC genome browser track database schema files.
# Replaces placeholders in a schema template with browser, species, track, and
# additional columns configuration.

version 1.3

task trackdb {
  input {
    File schema
    String browser
    String species
    String track
    String additional_columns
    String prefix
  }

  String out = prefix + ".schema.ra"

  command <<<
    set -euo pipefail

    sed \
      -e "s|{BROWSER}|~{browser}|g" \
      -e "s|{SPECIES}|~{species}|g" \
      -e "s|{TRACK}|~{track}|g" \
      -e "s|{ADDITIONAL_COLUMNS}|~{additional_columns}|g" \
      -e "s|{PREFIX}|~{prefix}|g" \
      ~{schema} > ~{out}
  >>>

  output {
    File schema_ra = out
  }

  requirements {
    container: "ghcr.io/hillerlab/sed:latest"
  }
}

workflow run {
  input {
    File schema
    String browser
    String species
    String track
    String additional_columns
    String prefix
  }

  call trackdb {
    input:
      schema = schema,
      browser = browser,
      species = species,
      track = track,
      additional_columns = additional_columns,
      prefix = prefix
  }

  output {
    File schema_ra = trackdb.schema_ra
  }
}
