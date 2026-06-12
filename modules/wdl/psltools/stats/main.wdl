# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PSLTOOLS_STATS — Get statistics about PSL files.

version 1.3

task stats {
  input {
    File psl
    String extra_args = ""
    String prefix = ""
  }

  String out_prefix = if prefix == "" then basename(psl, ".psl") else prefix

  command <<<
    set -euo pipefail

    extension=".tsv"
    if [[ "~{extra_args}" == *"--json"* ]]; then
      extension=".json"
    fi

    psltools stats \
      ~{extra_args} \
      --psl ~{psl} \
      > ~{out_prefix}.stats$extension
  >>>

  output {
    File? stats_json = "~{out_prefix}.stats.json"
    File? stats_tsv = "~{out_prefix}.stats.tsv"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/psltools:latest"
  }
}

workflow run {
  input {
    File psl
    String extra_args = ""
    String prefix = ""
  }

  call stats {
    input:
      psl = psl,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File? stats_json = stats.stats_json
    File? stats_tsv = stats.stats_tsv
  }
}
