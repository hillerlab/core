# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PSLTOOLS_SORT — Sort PSL files by chromosome, start, or other criteria.

version 1.3

task sort {
  input {
    File psl
    String extra_args = ""
    String prefix = ""
  }

  String out_prefix = if prefix == "" then basename(psl, ".psl") else prefix

  command <<<
    set -euo pipefail

    psltools score \
      ~{extra_args} \
      --psl ~{psl} \
      --out ~{out_prefix}.scores.tsv
  >>>

  output {
    File scores_tsv = "~{out_prefix}.scores.tsv"
    File? scores_tsv_gz = "~{out_prefix}.scores.tsv.gz"
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

  call sort {
    input:
      psl = psl,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File scores_tsv = sort.scores_tsv
    File? scores_tsv_gz = sort.scores_tsv_gz
  }
}
