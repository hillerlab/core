# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ALETSCH — Assemble RNA-seq transcripts using Aletsch.
# Long-read RNA-seq transcript assembler that generates GTF annotations
# and expression profiles from BAM files.

version 1.3

task aletsch {
  input {
    File bam
    File bai
    String library_type = "unstranded"
    String extra_args = ""
  }

  String prefix = basename(bam, ".bam")
  String gtf_path = prefix + ".gtf"
  String profile_dir = prefix + ".profile"
  String count_file = prefix + ".transcript_count.txt"

  command <<<
    set -euo pipefail

    mkdir -p ~{prefix}_profile
    mkdir -p ~{prefix}_gtf

    printf '%s\t%s\t%s\n' ~{bam} ~{bai} ~{library_type} > ~{prefix}.info

    aletsch \
      --profile \
      -i ~{prefix}.info \
      -p ~{prefix}_profile \
      ~{extra_args}

    aletsch \
      -i ~{prefix}.info \
      -o ~{prefix}_gtf/~{prefix}.gtf \
      -p ~{prefix}_profile \
      -d ~{prefix}_gtf \
      ~{extra_args}

    mv ~{prefix}_gtf/~{prefix}.gtf ~{gtf_path}
    mv ~{prefix}_profile ~{profile_dir}

    grep -w 'transcript' ~{gtf_path} | wc -l > ~{count_file}

    rm -rf ~{prefix}_gtf
  >>>

  output {
    File gtf = gtf_path
    Directory profile = profile_dir
    Int assembled_transcripts = read_int(count_file)
  }

  requirements {
    container: "biocontainers/aletsch:1.1.3--hdbdd923_0"
  }
}

workflow run {
  input {
    File bam
    File bai
    String library_type = "unstranded"
    String extra_args = ""
  }

  call aletsch {
    input:
      bam = bam,
      bai = bai,
      library_type = library_type,
      extra_args = extra_args
  }

  output {
    File gtf = aletsch.gtf
    Directory profile = aletsch.profile
    Int assembled_transcripts = aletsch.assembled_transcripts
  }
}
