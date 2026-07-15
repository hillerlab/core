# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# LONGREAD_SPLIT — Split transcript data into PBSIM3 simulation chunks.
# Divides transcript abundance data into equal-sized chunks for parallel
# PBSIM3 simulation, emitting chunk manifests for downstream processing.

version 1.3

task split {
  input {
    File transcript
    Int pbsim_chunks = 10
    Int pass_count = 3
    String prefix = "output"
  }

  command <<<
    set -euo pipefail

    longread split \
      --transcript ~{transcript} \
      --pbsim-chunks ~{pbsim_chunks} \
      --pass-count ~{pass_count} \
      --outdir chunks \
      --prefix ~{prefix}
  >>>

  output {
    Array[File] chunks = glob("chunks/chunk_*.transcript.tsv")
    File manifest = "chunks/chunks.tsv"
  }

  requirements {
    container: "ghcr.io/hillerlab/longread-rs:latest"
  }
}

workflow run {
  input {
    File transcript
    Int pbsim_chunks = 10
    Int pass_count = 3
    String prefix = "output"
  }

  call split {
    input:
      transcript = transcript,
      pbsim_chunks = pbsim_chunks,
      pass_count = pass_count,
      prefix = prefix
  }

  output {
    Array[File] chunks = split.chunks
    File manifest = split.manifest
  }
}
