# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BAX2BAM — Convert BAX to BAM format. Outputs BAM files with scraps and subreads.

version 1.3

task bax2bam {
  input {
    String meta_id
    Array[File] baxs
    String? prefix
  }

  String out_prefix = if defined(prefix) then prefix else meta_id

  command <<<
    set -euo pipefail

    bax2bam \
      -o ~{out_prefix} \
      ~{sep=' ' baxs}
  >>>

  output {
    File subreads = out_prefix + ".subreads.bam"
    File scraps = out_prefix + ".scraps.bam"
    File versions = "versions.yml"
  }

  requirements {
    container: "quay.io/biocontainers/bax2bam:0.0.9--0"
  }
}

workflow run {
  input {
    String meta_id
    Array[File] baxs
    String? prefix
  }

  call bax2bam {
    input:
      meta_id = meta_id,
      baxs = baxs,
      prefix = prefix
  }

  output {
    File subreads = bax2bam.subreads
    File scraps = bax2bam.scraps
  }
}