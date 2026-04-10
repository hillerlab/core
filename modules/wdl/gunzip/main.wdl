# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task gunzip {
  input {
    File archive
  }

  String out = basename(archive, ".gz")

  command <<<
    set -euo pipefail

    gunzip \
      -c \
      ~{archive} \
      > ~{out}
  >>>

  output {
    File gunzip = out
  }

  requirements {
    container: "community.wave.seqera.io/library/coreutils_grep_gzip_lbzip2_pruned:838ba80435a629f8"
  }
}

workflow run {
  input {
    File archive
  }

  call gunzip {
    input:
      archive = archive
  }

  output {
    File gunzip = gunzip.gunzip
  }
}
