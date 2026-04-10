# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task wigtobigwig {
  input {
    File wig
    File sizes
  }

  String out = sub(basename(wig, ".gz"), "\\.(wig|wiggle)$", ".bw")

  command <<<
    set -euo pipefail

    wigToBigWig \
      ~{wig} \
      ~{sizes} \
      ~{out}
  >>>

  output {
    File bigwig = out
  }

  requirements {
    container: "community.wave.seqera.io/library/ucsc-wigtobigwig:482--7b910cc21c32327e"
  }
}

workflow run {
  input {
    File wig
    File sizes
  }

  call wigtobigwig {
    input:
      wig = wig,
      sizes = sizes
  }

  output {
    File bigwig = wigtobigwig.bigwig
  }
}
