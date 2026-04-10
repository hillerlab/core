# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task beaver {
  input {
    Array[File]+ gtfs
    Int threads = 1
    String prefix = "beaver_output"
    String extra_args = ""
  }

  String gtf_path = "beaver_output/" + prefix + ".gtf"
  String csv_path = "beaver_output/" + prefix + "_feature.csv"

  command <<<
    set -euo pipefail

    : > gtf_list.txt
    for gtf in ~{sep=' ' gtfs}; do
      printf '%s\n' "$gtf" >> gtf_list.txt
    done

    mkdir -p beaver_output

    beaver \
      gtf_list.txt \
      ~{prefix} \
      -t ~{threads} \
      ~{extra_args}

    mv ~{prefix}.gtf beaver_output/
    mv ~{prefix}_feature.csv beaver_output/
  >>>

  output {
    File gtf = gtf_path
    File csv = csv_path
    File gtf_list = "gtf_list.txt"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/beaver:latest"
  }
}

workflow run {
  input {
    Array[File]+ gtfs
    Int threads = 1
    String prefix = "beaver_output"
    String extra_args = ""
  }

  call beaver {
    input:
      gtfs = gtfs,
      threads = threads,
      prefix = prefix,
      extra_args = extra_args
  }

  output {
    File gtf = beaver.gtf
    File csv = beaver.csv
    File gtf_list = beaver.gtf_list
  }
}
