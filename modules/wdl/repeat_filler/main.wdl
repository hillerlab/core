# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# REPEAT_FILLER — Fill gaps in chain alignments using repeat filling.
# Uses repeat masker to identify repeats within gaps and attempts to
# align query sequences to fill the gaps with lastz.

version 1.3

task repeat_filler {
  input {
    File chain_chunk
    File target_twobit
    File query_twobit
    Int chain_min_score
    Int fill_gap_max_size_t
    Int fill_gap_max_size_q
    Int fill_insert_chain_min_score
    Int fill_gap_min_size_t
    Int fill_gap_min_size_q
    Int fill_lastz_k
    Int fill_lastz_l
    String chain_linear_gap
    Boolean skip_fill_unmask
    String lastz_path
  }

  String out_chain = basename(chain_chunk) + ".filled.chain"

  command <<<
    set -euo pipefail

    unmask_arg=()
    if ! ~{if skip_fill_unmask then "true" else "false"}; then
      unmask_arg+=(--unmask)
    fi

    repeat_filler.py \
      --chain ~{chain_chunk} \
      --T2bit ~{target_twobit} \
      --Q2bit ~{query_twobit} \
      --workdir ./ \
      --lastz ~{lastz_path} \
      --axtChain axtChain \
      --chainSort chainSort \
      --chainMinScore ~{chain_min_score} \
      --gapMaxSizeT ~{fill_gap_max_size_t} \
      --gapMaxSizeQ ~{fill_gap_max_size_q} \
      --scoreThreshold ~{fill_insert_chain_min_score} \
      --gapMinSizeT ~{fill_gap_min_size_t} \
      --gapMinSizeQ ~{fill_gap_min_size_q} \
      --lastzParameters "K=~{fill_lastz_k} L=~{fill_lastz_l}" \
      "${unmask_arg[@]}" \
    | chainScore \
      -linearGap=~{chain_linear_gap} \
      stdin \
      ~{target_twobit} \
      ~{query_twobit} \
      stdout \
    | chainSort stdin ~{out_chain}
  >>>

  output {
    File filled_chain = out_chain
  }

  requirements {
    container: "ghcr.io/hillerlab/repeat_filler:latest"
  }
}

workflow run {
  input {
    File chain_chunk
    File target_twobit
    File query_twobit
    Int chain_min_score
    Int fill_gap_max_size_t
    Int fill_gap_max_size_q
    Int fill_insert_chain_min_score
    Int fill_gap_min_size_t
    Int fill_gap_min_size_q
    Int fill_lastz_k
    Int fill_lastz_l
    String chain_linear_gap
    Boolean skip_fill_unmask
    String lastz_path
  }

  call repeat_filler {
    input:
      chain_chunk = chain_chunk,
      target_twobit = target_twobit,
      query_twobit = query_twobit,
      chain_min_score = chain_min_score,
      fill_gap_max_size_t = fill_gap_max_size_t,
      fill_gap_max_size_q = fill_gap_max_size_q,
      fill_insert_chain_min_score = fill_insert_chain_min_score,
      fill_gap_min_size_t = fill_gap_min_size_t,
      fill_gap_min_size_q = fill_gap_min_size_q,
      fill_lastz_k = fill_lastz_k,
      fill_lastz_l = fill_lastz_l,
      chain_linear_gap = chain_linear_gap,
      skip_fill_unmask = skip_fill_unmask,
      lastz_path = lastz_path
  }

  output {
    File filled_chain = repeat_filler.filled_chain
  }
}
