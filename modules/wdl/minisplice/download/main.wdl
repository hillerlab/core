# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# MINISPLICE_DOWNLOAD — Download MiniSplice model and calibration files.
# Fetches the pre-trained MiniSplice model and calibration data from Zenodo.

version 1.3

task download {
  command <<<
    set -euo pipefail

    wget -O- https://zenodo.org/records/15931054/files/vi2-7k.tgz | tar zxf -
  >>>

  output {
    File model = "vi2-7k.kan"
    File calibration = "vi2-7k.kan.cali"
  }

  requirements {
    container: "quay.io/biocontainers/wget:1.25.0"
  }
}

workflow run {
  call download

  output {
    File model = download.model
    File calibration = download.calibration
  }
}
