# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# AXTCHAIN — Convert PSL alignments to chains.
# Runs axtChain piped through chainAntiRepeat for one PSL bundle.
# Optional substitution score matrix (lastz_q) is supported.

version 1.3

task axtchain {
  input {
    File bundle_psl
    File target_twobit
    File query_twobit
    Int min_chain_score
    String chain_linear_gap
    File? lastz_q
  }

  String out_chain = basename(bundle_psl, ".psl") + ".chain"

  command <<<
    set -euo pipefail

    matrix_arg=""
    if [ -n "~{lastz_q}" ]; then
      matrix_arg="-scoreScheme=~{lastz_q}"
    fi

    axtChain \
        -psl \
        -verbose=0 \
        -minScore=~{min_chain_score} \
        -linearGap=~{chain_linear_gap} \
        $matrix_arg \
        ~{bundle_psl} \
        ~{target_twobit} \
        ~{query_twobit} \
        stdout \
    | chainAntiRepeat \
        ~{target_twobit} \
        ~{query_twobit} \
        stdin \
        ~{out_chain}
  >>>

  output {
    File chain = out_chain
  }

  requirements {
    container: "quay.io/biocontainers/ucsc_tools:332--1"
  }
}

workflow run {
  input {
    File bundle_psl
    File target_twobit
    File query_twobit
    Int min_chain_score
    String chain_linear_gap
    File? lastz_q
  }

  call axtchain {
    input:
      bundle_psl = bundle_psl,
      target_twobit = target_twobit,
      query_twobit = query_twobit,
      min_chain_score = min_chain_score,
      chain_linear_gap = chain_linear_gap,
      lastz_q = lastz_q
  }

  output {
    File chain = axtchain.chain
  }
}