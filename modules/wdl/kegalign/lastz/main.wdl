# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# KEGALIGN_LASTZ — CPU gapped-extension stage for the KegAlign backend.
# Consumes the tarball KEGALIGN produced (per-block .segments + the .2bit
# copies + one LASTZ command per block) and runs those commands with upstream
# run_lastz_tarball.py, concatenating the AXT+ output.

version 1.3

task lastz {
  input {
    File tarball
    Int threads = 1
  }

  String prefix = sub(basename(tarball, ".tgz"), "\\.kegalign$", "")

  command <<<
    set -euo pipefail

    run_lastz_tarball.py \
      --input ~{tarball} \
      --output ~{prefix}.axt \
      --parallel ~{threads}
  >>>

  output {
    File axt = "~{prefix}.axt"
  }

  requirements {
    container: "quay.io/biocontainers/kegalign-full:0.1.2.9--hdfd78af_0"
  }
}

workflow run {
  input {
    File tarball
    Int threads = 1
  }

  call lastz {
    input:
      tarball = tarball,
      threads = threads
  }

  output {
    File axt = lastz.axt
  }
}