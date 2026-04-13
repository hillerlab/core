# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# GXF2BED — Convert GXF (GFF/GTF) annotations to BED format.
# Transforms gene annotation files from GFF/GTF format to BED format
# for compatibility with downstream tools.

version 1.3

task gxf2bed {
  input {
    File gxf
  }

  String out = sub(basename(gxf, ".gz"), "\\.(gtf|gff3?)$", ".bed")

  command <<<
    set -euo pipefail

    gxf2bed \
      --input ~{gxf} \
      --output ~{out}
  >>>

  output {
    File bed = out
  }

  requirements {
    container: "ghcr.io/alejandrogzi/gxf2bed:main-78d8d6a"
  }
}

workflow run {
  input {
    File gxf
  }

  call gxf2bed {
    input:
      gxf = gxf
  }

  output {
    File bed = gxf2bed.bed
  }
}
