# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PSLTOOLS_SPLIT — Split PSL files into multiple PSL files.

version 1.3

task split {
  input {
    File psl
    String extra_args = ""
    String prefix = ""
  }

  String out_prefix = if prefix == "" then basename(psl, ".psl") else prefix

  command <<<
    set -euo pipefail

    psltools split \
      ~{extra_args} \
      --psl ~{psl} \
      --out-prefix ~{out_prefix}
  >>>

  output {
    Array[File] psls = glob("*.psl")
    Array[File] psls_gz = glob("*.psl.gz")
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

  call split {
    input:
      psl = psl,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    Array[File] psls = split.psls
    Array[File] psls_gz = split.psls_gz
  }
}
