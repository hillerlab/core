# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task cat_psl {
  input {
    String bucket_key
    Array[File]+ psl_files
  }

  String psl_gz_path = bucket_key + ".psl.gz"

  command <<<
    set -euo pipefail

    cat ~{sep=' ' psl_files} | grep -v '^#' | gzip -c > ~{psl_gz_path}
  >>>

  output {
    File psl_gz = psl_gz_path
  }

  requirements {
    container: "quay.io/nf-core/coreutils:9.5--ae99c88a9b28c264"
  }
}

workflow run {
  input {
    String bucket_key
    Array[File]+ psl_files
  }

  call cat_psl {
    input:
      bucket_key = bucket_key,
      psl_files = psl_files
  }

  output {
    File psl_gz = cat_psl.psl_gz
  }
}