# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PSLTOOLS_SWAP — Swap PSL files from reference to query.

version 1.3

task swap {
  input {
    File psl
    String extra_args = ""
    String prefix = ""
  }

  String out_prefix = if prefix == "" then basename(psl, ".psl") else prefix

  command <<<
    set -euo pipefail

    psltools swap \
      ~{extra_args} \
      --psl ~{psl} \
      --out-psl ~{out_prefix}.swapped.psl
  >>>

  output {
    File swapped_psl = "~{out_prefix}.swapped.psl"
    File? swapped_psl_gz = "~{out_prefix}.swapped.psl.gz"
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

  call swap {
    input:
      psl = psl,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File swapped_psl = swap.swapped_psl
    File? swapped_psl_gz = swap.swapped_psl_gz
  }
}
