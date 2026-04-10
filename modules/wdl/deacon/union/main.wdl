# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task union {
  input {
    Array[File]+ indexes
    String extra_args = ""
  }

  String prefix = basename(indexes[0], ".idx") + ".union"
  String index_path = prefix + ".idx"

  command <<<
    set -euo pipefail

    deacon \
      index \
      union \
      ~{extra_args} \
      ~{sep=' ' indexes} > ~{index_path}
  >>>

  output {
    File index = index_path
  }

  requirements {
    container: "biocontainers/deacon:0.13.2--h7ef3eeb_1"
  }
}

workflow run {
  input {
    Array[File]+ indexes
    String extra_args = ""
  }

  call union {
    input:
      indexes = indexes,
      extra_args = extra_args
  }

  output {
    File index = union.index
  }
}
