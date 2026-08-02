# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BAMSPLIT_INSPECT — Describe a BAM file and what a split of it would look like.
# Reports header contents, sort order, index state and predicted output counts
# per routing mode. Writes no BAM files; emits a text or JSON report.

version 1.3

task inspect {
  input {
    File bam
    String prefix = "inspect"
    Boolean json = false
    String extra_args = ""
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    ext="txt"
    json_flag=""
    if [[ "~{extra_args}" == *"--json"* ]]; then
      ext="json"
    elif ~{if json then "true" else "false"}; then
      ext="json"
      json_flag="--json"
    fi

    bamsplit \
        inspect \
        ~{extra_args} \
        ~{bam} \
        -t ~{threads} \
        $json_flag \
        > ~{prefix}.$ext

    cat <<-END_VERSIONS > versions.yml
    "BAMSPLIT_INSPECT":
        bamsplit: $( bamsplit --version | head -n 1 | sed 's/bamsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
  >>>

  output {
    File? report = prefix + ".txt"
    File? json_report = prefix + ".json"
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/bamsplit:latest"
  }
}

workflow run {
  input {
    File bam
    String prefix = "inspect"
    Boolean json = false
    String extra_args = ""
    Int threads = 1
  }

  call inspect {
    input:
      bam = bam,
      prefix = prefix,
      json = json,
      extra_args = extra_args,
      threads = threads
  }

  output {
    File? report = inspect.report
    File? json_report = inspect.json_report
    File versions = inspect.versions
  }
}
