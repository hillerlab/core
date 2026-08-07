# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# CHAINC — Remove chain-breaking alignments using chain/net files.
# A Rust implementation of UCSC chainCleaner. When no NET is supplied the chains
# are netted in memory, so --net (and the size files) are optional.

version 1.3

task chainc {
  input {
    File chain
    File? net
    File? reference_sizes
    File? query_sizes
    File reference
    File query
    Int threads = 1
    String extra_args = ""
  }

  String prefix = sub(basename(chain, ".gz"), "\\.chain$", "")

  command <<<
    set -euo pipefail

    chainc \
      --chains ~{chain} \
      ~{if defined(net) then "--net " + net else ""} \
      --reference ~{reference} \
      --query ~{query} \
      --output ~{prefix}.chain \
      --removed-bed ~{prefix}.removed.bed \
      --new-chain-id-dict ~{prefix}.new_chain_ids.txt \
      --linear-gap loose \
      ~{if defined(reference_sizes) then "--reference-sizes " + reference_sizes else ""} \
      ~{if defined(query_sizes) then "--query-sizes " + query_sizes else ""} \
      --threads ~{threads} \
      ~{extra_args}
  >>>

  output {
    File chains = "~{prefix}.chain"
    File removed_bed = "~{prefix}.removed.bed"
    File new_chain_ids = "~{prefix}.new_chain_ids.txt"
  }

  requirements {
    container: "ghcr.io/hillerlab/chainc:latest"
  }
}

workflow run {
  input {
    File chain
    File? net
    File? reference_sizes
    File? query_sizes
    File reference
    File query
    Int threads = 1
    String extra_args = ""
  }

  call chainc {
    input:
      chain = chain,
      net = net,
      reference_sizes = reference_sizes,
      query_sizes = query_sizes,
      reference = reference,
      query = query,
      threads = threads,
      extra_args = extra_args
  }

  output {
    File chains = chainc.chains
    File removed_bed = chainc.removed_bed
    File new_chain_ids = chainc.new_chain_ids
  }
}
