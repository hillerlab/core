# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BEDTOBIGBED — Convert BED files to BigBed format using bigtools.
# Transforms BED format files into indexed BigBed binary format for
# efficient querying in genome browsers.

version 1.3

task bedtobigbed {
  input {
    File bed
    File chrom_sizes
    File? autosql
  }

  String prefix = basename(bed, ".bed")
  String out = prefix + ".bb"

  command <<<
    set -euo pipefail

    autosql_arg=()

    if [ -n "~{default="" autosql}" ]; then
      autosql_arg+=(--autosql "~{default="" autosql}")
    fi

    bigtools bedtobigbed \
      "${autosql_arg[@]}" \
      ~{bed} \
      ~{chrom_sizes} \
      ~{out}
  >>>

  output {
    File bigbed = out
  }

  requirements {
    container: "biocontainers/bigtools:0.5.6--hc1c3326_1"
  }
}

workflow run {
  input {
    File bed
    File chrom_sizes
    File? autosql
  }

  call bedtobigbed {
    input:
      bed = bed,
      chrom_sizes = chrom_sizes,
      autosql = autosql
  }

  output {
    File bigbed = bedtobigbed.bigbed
  }
}
