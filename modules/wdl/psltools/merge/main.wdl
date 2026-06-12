# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PSLTOOLS_MERGE — Merge PSL files into a single PSL file.

version 1.3

task merge {
  input {
    Array[File] psls
    String extra_args = ""
    String prefix = "merged"
  }

  command <<<
    set -euo pipefail

    ls *.psl > psl.list

    psltools merge \
      ~{extra_args} \
      --file psl.list \
      --out-psl ~{prefix}.merged.psl
  >>>

  output {
    File merged_psl = "~{prefix}.merged.psl"
    File? merged_psl_gz = "~{prefix}.merged.psl.gz"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/psltools:latest"
  }
}

workflow run {
  input {
    Array[File] psls
    String extra_args = ""
    String prefix = "merged"
  }

  call merge {
    input:
      psls = psls,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File merged_psl = merge.merged_psl
    File? merged_psl_gz = merge.merged_psl_gz
  }
}
