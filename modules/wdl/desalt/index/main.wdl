# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# DESALT_INDEX — Build deSALT index for a genome

version 1.3

task index {
  input {
    File genome
    String prefix
    String args = ""
  }

  String index_dir = prefix + ".index"

  command <<<
    set -euo pipefail

    deSALT index \
      ~{args} \
      ~{genome} \
      ~{index_dir}

    cat <<-END_VERSIONS > versions.yml
    "DESALT_INDEX":
        deSALT: $(deSALT 2>&1 | grep 'Version' | awk '{print $2}')
    END_VERSIONS
  >>>

  output {
    Directory index = index_dir
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/hillerlab/desalt:latest"
  }
}

workflow run {
  input {
    File genome
    String prefix
    String args = ""
  }

  call index {
    input:
      genome = genome,
      prefix = prefix,
      args = args
  }

  output {
    Directory index = index.index
    File versions = index.versions
  }
}
