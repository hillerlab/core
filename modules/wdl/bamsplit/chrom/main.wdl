# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BAMSPLIT_CHROM — Split a BAM file into one output per reference sequence.
# Losslessly partitions reads by chromosome, with unplaced records routed to a
# dedicated `unmapped` output. Builds an index (BAI/CSI) for every output.

version 1.3

task chrom {
  input {
    File bam
    String out_dir = "chromosomes"
    String extra_args = ""
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    bamsplit \
        chrom \
        ~{extra_args} \
        ~{bam} \
        --out-dir ~{out_dir} \
        -t ~{threads}

    cat <<-END_VERSIONS > versions.yml
    "BAMSPLIT_CHROM":
        bamsplit: $( bamsplit --version | head -n 1 | sed 's/bamsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
  >>>

  output {
    Array[File] bams = glob(out_dir + "/*.bam")
    Array[File] bais = glob(out_dir + "/*.bai")
    Array[File] csis = glob(out_dir + "/*.csi")
    Array[File] manifests = glob(out_dir + "/*.json")
    File versions = "versions.yml"
  }

  requirements {
    container: "ghcr.io/alejandrogzi/bamsplit:latest"
  }
}

workflow run {
  input {
    File bam
    String out_dir = "chromosomes"
    String extra_args = ""
    Int threads = 1
  }

  call chrom {
    input:
      bam = bam,
      out_dir = out_dir,
      extra_args = extra_args,
      threads = threads
  }

  output {
    Array[File] bams = chrom.bams
    Array[File] bais = chrom.bais
    Array[File] csis = chrom.csis
    Array[File] manifests = chrom.manifests
    File versions = chrom.versions
  }
}
