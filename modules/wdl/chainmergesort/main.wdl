# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task chainmergesort {
  input {
    Array[File]+ chain_files
    String target_name
    String query_name
  }

  String merged_chain_path = target_name + "." + query_name + ".all.chain.gz"

  command <<<
    set -euo pipefail

    mkdir -p temp_kent

    ~{sep='\n' prefix('echo ', chain_files)} > chain_file_list.txt

    chainMergeSort -inputList=chain_file_list.txt -tempDir=temp_kent \
    | gzip -c > ~{merged_chain_path}
  >>>

  output {
    File merged_chain = merged_chain_path
  }

  requirements {
    container: "quay.io/biocontainers/ucsc_tools:332--1"
  }
}

workflow run {
  input {
    Array[File]+ chain_files
    String target_name
    String query_name
  }

  call chainmergesort {
    input:
      chain_files = chain_files,
      target_name = target_name,
      query_name = query_name
  }

  output {
    File merged_chain = chainmergesort.merged_chain
  }
}