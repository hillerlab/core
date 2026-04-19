# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BED2GTF — Convert BED to GTF.
# Transforms BED format files to GTF/GFF format for compatibility
# with downstream analysis tools.

version 1.3

task bed2gtf {
  input {
    File bed
    File? isoforms
    String args = ""
    String format = "gtf"
    Int cpus = 1
  }

  String prefix = sub(basename(bed), "\\.bed$", "") + "." + format

  command <<<
    set -euo pipefail

    bed2gtf \
      ~{args} \
      ~{"--isoforms " + isoforms} \
      -T ~{cpus} \
      -i ~{bed} \
      -o ~{prefix}
  >>>

  output {
    File gtf = prefix
  }

  requirements {
    container: "ghcr.io/alejandrogzi/bed2gtf:latest"
  }
}

workflow run {
  input {
    File bed
    File? isoforms
    String args = ""
    String format = "gtf"
    Int cpus = 1
  }

  call bed2gtf {
    input:
      bed = bed,
      isoforms = isoforms,
      args = args,
      format = format,
      cpus = cpus
  }

  output {
    File gtf = bed2gtf.gtf
  }
}