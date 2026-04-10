# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task wget {
  input {
    String url
    String output_name
  }

  command <<<
    set -euo pipefail

    wget \
      -O - \
      ~{url} \
      > ~{output_name}
  >>>

  output {
    File outfile = output_name
  }

  requirements {
    container: "community.wave.seqera.io/library/wget:1.21.4--8b0fcde81c17be5e"
  }
}

workflow run {
  input {
    String url
    String output_name
  }

  call wget {
    input:
      url = url,
      output_name = output_name
  }

  output {
    File outfile = wget.outfile
  }
}
