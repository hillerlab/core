# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BIGWIGMERGE — Merge multiple BigWig files using bigtools.
# Combines multiple coverage BigWig files into a single output file
# using the bigtools bigwigmerge utility.

version 1.3

task bigwigmerge {
  input {
    Array[File]+ bigwigs
    String prefix
  }

  String out = prefix + ".bw"

  command <<<
    set -euo pipefail

    bigtools bigwigmerge \
      ~{sep=' ' bigwigs} \
      ~{out}
  >>>

  output {
    File bigwig = out
  }

  requirements {
    container: "biocontainers/bigtools:0.5.6--hc1c3326_1"
  }
}

workflow run {
  input {
    Array[File]+ bigwigs
    String prefix
  }

  call bigwigmerge {
    input:
      bigwigs = bigwigs,
      prefix = prefix
  }

  output {
    File bigwig = bigwigmerge.bigwig
  }
}
