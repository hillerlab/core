# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task chainfilter {
  input {
    File cleaned_chain
    Int min_chain_score
    String target_name
    String query_name
  }

  String final_chain_path = target_name + "." + query_name + ".final.chain.gz"

  command <<<
    set -euo pipefail

    chainFilter -minScore=~{min_chain_score} ~{cleaned_chain} \
    | gzip -c > ~{final_chain_path}
  >>>

  output {
    File final_chain = final_chain_path
  }

  requirements {
    container: "quay.io/biocontainers/ucsc_tools:332--1"
  }
}

workflow run {
  input {
    File cleaned_chain
    Int min_chain_score
    String target_name
    String query_name
  }

  call chainfilter {
    input:
      cleaned_chain = cleaned_chain,
      min_chain_score = min_chain_score,
      target_name = target_name,
      query_name = query_name
  }

  output {
    File final_chain = chainfilter.final_chain
  }
}