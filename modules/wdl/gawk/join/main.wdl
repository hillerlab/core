# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task join {
  input {
    Array[File]+ files
    String extension
    String prefix
  }

  String out = prefix + "." + extension

  command <<<
    set -euo pipefail

    gawk 1 ~{sep=' ' files} > ~{out}

    if [[ ! -s "~{out}" ]]; then
      rm ~{out}
    elif [[ "~{extension}" == "bed" ]]; then
      sort -k1,1 -k2,2n ~{out} > ~{prefix}.sorted.~{extension}
      mv ~{prefix}.sorted.~{extension} ~{out}
    fi
  >>>

  output {
    Array[File] output = glob(out)
  }

  requirements {
    container: "biocontainers/gawk:5.3.0"
  }
}

workflow run {
  input {
    Array[File]+ files
    String extension
    String prefix
  }

  call join {
    input:
      files = files,
      extension = extension,
      prefix = prefix
  }

  output {
    Array[File] output = join.output
  }
}
