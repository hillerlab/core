# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task intronic {
  input {
    File introns
  }

  String prefix = basename(introns, ".gz")
  String out = prefix + ".meta.iic"

  command <<<
    set -euo pipefail

    if [ ! -s "~{introns}" ]; then
      touch ~{out}
    else
      intronIC classify \
        -q ~{introns} \
        -n ~{prefix}

      if ! compgen -G "*.meta.iic" > /dev/null; then
        touch ~{out}
      fi
    fi
  >>>

  output {
    File iic = out
  }

  requirements {
    container: "ghcr.io/hillerlab/containers/intronic:latest"
  }
}

workflow run {
  input {
    File introns
  }

  call intronic {
    input:
      introns = introns
  }

  output {
    File iic = intronic.iic
  }
}
