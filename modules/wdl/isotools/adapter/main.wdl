# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOTOOLS_ADAPTER — Detect and optionally remove adapter sequences from
# soft-clipped regions of long-read BAM alignments.

version 1.3

task isotools_adapter {
  input {
    File bam
    File bai
    String args = ""
    String prefix = sub(basename(bam), "\\.bam$", "")
  }

  command <<<
    set -euo pipefail

    iso-adapter \
        ~{args} \
        --threads ~{cpus} \
        --out-bam . \
        ~{bam}
  >>>

  output {
    File bam_out = prefix + ".without_adapters.bam"
    File? bai_out = prefix + ".bai"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    File bam
    File bai
    String args = ""
  }

  call isotools_adapter {
    input:
      bam = bam,
      bai = bai,
      args = args
  }

  output {
    File bam_out = isotools_adapter.bam_out
    File? bai_out = isotools_adapter.bai_out
  }
}