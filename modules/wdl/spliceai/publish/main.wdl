# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# SPLICEAI_PUBLISH — Collect and organize SpliceAI output files.
# Copies donor and acceptor strand BigWig files into a single output directory.

version 1.3

task publish {
  input {
    File donor_plus
    File donor_minus
    File acceptor_plus
    File acceptor_minus
  }

  command <<<
    set -euo pipefail

    mkdir -p spliceai
    cp ~{donor_plus} spliceai/
    cp ~{donor_minus} spliceai/
    cp ~{acceptor_plus} spliceai/
    cp ~{acceptor_minus} spliceai/
  >>>

  output {
    Directory spliceai = "spliceai"
  }
}

workflow run {
  input {
    File donor_plus
    File donor_minus
    File acceptor_plus
    File acceptor_minus
  }

  call publish {
    input:
      donor_plus = donor_plus,
      donor_minus = donor_minus,
      acceptor_plus = acceptor_plus,
      acceptor_minus = acceptor_minus
  }

  output {
    Directory spliceai = publish.spliceai
  }
}
