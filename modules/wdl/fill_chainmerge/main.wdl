# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task fill_chainmerge {
  input {
    Array[File]+ filled_chain_files
    String target_name
    String query_name
  }

  String filled_chain_path = target_name + "." + query_name + ".filled.chain.gz"

  command <<<
    set -euo pipefail

    mkdir -p temp_kent

    ~{sep='\n' prefix('echo ', filled_chain_files)} > filled_chain_list.txt

    chainMergeSort -inputList=filled_chain_list.txt -tempDir=temp_kent \
    | gzip -c > ~{filled_chain_path}
  >>>

  output {
    File filled_chain = filled_chain_path
  }

  requirements {
    container: "quay.io/biocontainers/ucsc_tools:332--1"
  }
}

workflow run {
  input {
    Array[File]+ filled_chain_files
    String target_name
    String query_name
  }

  call fill_chainmerge {
    input:
      filled_chain_files = filled_chain_files,
      target_name = target_name,
      query_name = query_name
  }

  output {
    File filled_chain = fill_chainmerge.filled_chain
  }
}