# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task median {
  input {
    Array[File]+ bigwigs
    String extra_args = ""
  }

  String prefix = basename(bigwigs[0], ".bw")
  String wig_path = prefix + ".wig"

  command <<<
    set -euo pipefail

    wiggletools \
      ~{extra_args} \
      median \
      ~{sep=' ' bigwigs} \
      > ~{wig_path}
  >>>

  output {
    File wig = wig_path
  }

  requirements {
    container: "biocontainers/wiggletools:1.2.11--h7118728_10"
  }
}

workflow run {
  input {
    Array[File]+ bigwigs
    String extra_args = ""
  }

  call median {
    input:
      bigwigs = bigwigs,
      extra_args = extra_args
  }

  output {
    File wig = median.wig
  }
}
