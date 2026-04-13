# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINCLEANER — Remove weak and suspicious chains using chainCleaner.
# chainCleaner requires additional Kent binaries (chainNet, NetFilterNonNested.perl)
# in PATH; these are handled by the container/conda environment.

version 1.3

task chaincleaner {
  input {
    File input_chain_gz
    File target_twobit
    File query_twobit
    File target_chrom_sizes
    File query_chrom_sizes
    String chain_linear_gap
    String clean_chain_parameters
  }

  command <<<
    set -euo pipefail

    gunzip -c ~{input_chain_gz} > before_cleaning.chain

    gzip -k before_cleaning.chain

    chainCleaner \
        before_cleaning.chain \
        ~{target_twobit} \
        ~{query_twobit} \
        cleaned_intermediate.chain \
        removed_suspects.bed \
        -linearGap=~{chain_linear_gap} \
        -tSizes=~{target_chrom_sizes} \
        -qSizes=~{query_chrom_sizes} \
        ~{clean_chain_parameters} \
        || true
  >>>

  output {
    File before_clean = "before_cleaning.chain.gz"
    File cleaned_chain = "cleaned_intermediate.chain"
    File suspects_bed = "removed_suspects.bed"
  }

  requirements {
    container: "quay.io/biocontainers/ucsc_tools:332--1"
  }
}

workflow run {
  input {
    File input_chain_gz
    File target_twobit
    File query_twobit
    File target_chrom_sizes
    File query_chrom_sizes
    String chain_linear_gap
    String clean_chain_parameters
  }

  call chaincleaner {
    input:
      input_chain_gz = input_chain_gz,
      target_twobit = target_twobit,
      query_twobit = query_twobit,
      target_chrom_sizes = target_chrom_sizes,
      query_chrom_sizes = query_chrom_sizes,
      chain_linear_gap = chain_linear_gap,
      clean_chain_parameters = clean_chain_parameters
  }

  output {
    File before_clean = chaincleaner.before_clean
    File cleaned_chain = chaincleaner.cleaned_chain
    File suspects_bed = chaincleaner.suspects_bed
  }
}