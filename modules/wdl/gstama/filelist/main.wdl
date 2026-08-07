# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# GSTAMA_FILELIST — Write a gs-tama file list TSV (one row per input BED) for
# downstream gs-tama steps.

version 1.3

task filelist {
  input {
    Array[File]+ bed
    String cap = ""
    String order = ""
  }

  String prefix = basename(bed[0], ".bed")

  command <<<
    set -euo pipefail

    : > "~{prefix}.tsv"
    for i in ~{sep=' ' bed}
    do
      printf '%s\t%s\t%s\t%s\n' "$i" "~{cap}" "~{order}" "$i" >> "~{prefix}.tsv"
    done
  >>>

  output {
    File tsv = "~{prefix}.tsv"
  }

  requirements {
    container: "nf-core/ubuntu:20.04"
  }
}

workflow run {
  input {
    Array[File]+ bed
    String cap = ""
    String order = ""
  }

  call filelist {
    input:
      bed = bed,
      cap = cap,
      order = order
  }

  output {
    File tsv = filelist.tsv
  }
}
