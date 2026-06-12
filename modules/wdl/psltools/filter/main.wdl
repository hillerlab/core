# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PSLTOOLS_FILTER — Filter PSL files by score, strand, or other criteria.

version 1.3

task filter {
  input {
    File psl
    String extra_args = ""
    String prefix = ""
  }

  String out_prefix = if prefix == "" then basename(psl, ".psl") else prefix

  command <<<
    set -euo pipefail

    psltools filter \
      ~{extra_args} \
      --psl ~{psl} \
      --out-psl ~{out_prefix}.filtered.psl
  >>>

  output {
    File filtered_psl = "~{out_prefix}.filtered.psl"
    File? filtered_psl_gz = "~{out_prefix}.filtered.psl.gz"
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

  call filter {
    input:
      psl = psl,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File filtered_psl = filter.filtered_psl
    File? filtered_psl_gz = filter.filtered_psl_gz
  }
}
