# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHOOSE — Select fields from text files using the Rust choose CLI.
# Reads tabular data from stdin and extracts the specified column
# selections, outputting tab-separated results to a new file.

version 1.3

task choose {
  input {
    File input_file
    String selections
    String args = ""
  }

  String output_name = sub(basename(input_file), "\\.(tsv|csv|txt)$", "") + ".choose.tsv"

  command <<<
    set -euo pipefail

    choose \
      ~{args} \
      ~{selections} \
      -o '\t' \
      < ~{input_file} \
      > ~{output_name}
  >>>

  output {
    File output = output_name
  }

  requirements {
    container: "ghcr.io/hillerlab/choose:1.3.7"
  }
}

workflow run {
  input {
    File input_file
    String selections
    String args = ""
  }

  call choose {
    input:
      input_file = input_file,
      selections = selections,
      args = args
  }

  output {
    File output = choose.output
  }
}
