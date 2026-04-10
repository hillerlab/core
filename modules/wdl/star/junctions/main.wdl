# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task junctions {
  input {
    Array[File]+ junctions
    Int min_junction_len
    Int min_junction_coverage
  }

  String filtered_path = "ALL_SJ_out_filtered.tab"
  String count_file = "ALL_SJ_out_filtered.count.txt"

  command <<<
    set -euo pipefail

    join_junctions \
      -j ~{sep=' ' junctions} \
      -l ~{min_junction_len} \
      -m ~{min_junction_coverage} \
      -o .

    wc -l < ~{filtered_path} > ~{count_file}
  >>>

  output {
    File filtered_junctions = filtered_path
    Int filtered_junctions_count = read_int(count_file)
  }

  requirements {
    container: "ghcr.io/hillerlab/join_junctions:latest"
  }
}

workflow run {
  input {
    Array[File]+ junctions
    Int min_junction_len
    Int min_junction_coverage
  }

  call junctions {
    input:
      junctions = junctions,
      min_junction_len = min_junction_len,
      min_junction_coverage = min_junction_coverage
  }

  output {
    File filtered_junctions = junctions.filtered_junctions
    Int filtered_junctions_count = junctions.filtered_junctions_count
  }
}
