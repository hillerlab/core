# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# GSTAMA_ADD_CDS_REGIONS — Add CDS regions to a gs-tama BED from parsed ORF BLAST
# output and the transcript FASTA.

version 1.3

task addcdsregions {
  input {
    File parsed
    File bed
    File fasta
    String args = ""
  }

  String prefix = basename(bed, ".bed")

  command <<<
    set -euo pipefail

    tama_cds_regions_bed_add.py \
      -p ~{parsed} \
      -a ~{bed} \
      -f ~{fasta} \
      -o "~{prefix}_cds.bed" \
      ~{args}
  >>>

  output {
    File cds_bed = "~{prefix}_cds.bed"
  }

  requirements {
    container: "quay.io/biocontainers/gs-tama:1.0.3--hdfd78af_0"
  }
}

workflow run {
  input {
    File parsed
    File bed
    File fasta
    String args = ""
  }

  call addcdsregions {
    input:
      parsed = parsed,
      bed = bed,
      fasta = fasta,
      args = args
  }

  output {
    File cds_bed = addcdsregions.cds_bed
  }
}
