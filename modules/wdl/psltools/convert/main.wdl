# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PSLTOOLS_CONVERT — Convert PSL to BED

version 1.3

task convert {
  input {
    File psl
    String extra_args = ""
    String prefix = ""
    String type = "12"
    Boolean gzip = false
  }

  String out_prefix = if prefix == "" then basename(psl, ".psl") else prefix

  command <<<
    set -euo pipefail

    gzip_arg=""
    if ~{gzip}; then
      gzip_arg="--gzip"
    fi

    psltools convert \
      ~{extra_args} \
      $gzip_arg \
      --psl ~{psl} \
      --out ~{out_prefix}.bed \
      --type ~{type}
  >>>

  output {
    File bed = "~{out_prefix}.bed"
    File? bed_gz = "~{out_prefix}.bed.gz"
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
    String type = "12"
    Boolean gzip = false
  }

  call convert {
    input:
      psl = psl,
      extra_args = extra_args,
      prefix = prefix,
      type = type,
      gzip = gzip
  }

  output {
    File bed = convert.bed
    File? bed_gz = convert.bed_gz
  }
}
