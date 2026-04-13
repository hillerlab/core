# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BEDGRAPHTOBIGWIG — Convert BedGraph to BigWig using bigtools.
# Transforms BedGraph coverage files into indexed BigWig binary format
# for efficient visualization in genome browsers.

version 1.3

task bedgraphtobigwig {
  input {
    File bedgraph
    File chrom_sizes
  }

  String prefix = sub(basename(bedgraph, ".gz"), "\\.(bedgraph|bg)$", "")
  String out = prefix + ".bw"

  command <<<
    set -euo pipefail

    bigtools bedgraphtobigwig \
      ~{bedgraph} \
      ~{chrom_sizes} \
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
    File bedgraph
    File chrom_sizes
  }

  call bedgraphtobigwig {
    input:
      bedgraph = bedgraph,
      chrom_sizes = chrom_sizes
  }

  output {
    File bigwig = bedgraphtobigwig.bigwig
  }
}
