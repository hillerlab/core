# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task pslsortacc {
  input {
    Array[File]+ psl_gz_files
  }

  command <<<
    set -euo pipefail

    mkdir -p sorted_psl temp_kent

    pslSortAcc nohead sorted_psl temp_kent ~{sep=' ' psl_gz_files}
  >>>

  output {
    Array[File] sorted_psl = glob("sorted_psl/*")
  }

  requirements {
    container: "quay.io/biocontainers/ucsc_tools:332--1"
  }
}

workflow run {
  input {
    Array[File]+ psl_gz_files
  }

  call pslsortacc {
    input:
      psl_gz_files = psl_gz_files
  }

  output {
    Array[File] sorted_psl = pslsortacc.sorted_psl
  }
}