# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ISOSEQ_CLUSTER2 — Cluster PacBio IsoSeq reads using isoseq cluster2.
# Groups similar full-length reads into consensus transcripts and outputs
# clustered BAM files with cluster reports.

version 1.3

task cluster2 {
  input {
    Array[File]+ bam_files
  }

  String prefix = basename(bam_files[0], ".bam")
  String fofn_path = prefix + ".flnc.fofn"

  command <<<
    set -euo pipefail

    printf '%s\n' ~{sep=' ' bam_files} > ~{fofn_path}

    isoseq \
      cluster2 \
      ~{fofn_path} \
      ~{prefix}.transcripts.bam
  >>>

  output {
    File bam = prefix + ".transcripts.bam"
    File pbi = prefix + ".transcripts.bam.pbi"
    File cluster_report = prefix + ".transcripts.cluster_report.csv"
    Array[File] hq_bam = glob("*.transcripts.hq.bam")
    Array[File] hq_pbi = glob("*.transcripts.hq.bam.pbi")
    Array[File] lq_bam = glob("*.transcripts.lq.bam")
    Array[File] lq_pbi = glob("*.transcripts.lq.bam.pbi")
    Array[File] singletons_bam = glob("*.transcripts.singletons.bam")
    Array[File] singletons_pbi = glob("*.transcripts.singletons.bam.pbi")
    File fofn = fofn_path
  }

  requirements {
    container: "biocontainers/isoseq:4.0.0--h9ee0642_0"
  }
}

workflow run {
  input {
    Array[File]+ bam_files
  }

  call cluster2 {
    input:
      bam_files = bam_files
  }

  output {
    File bam = cluster2.bam
    File pbi = cluster2.pbi
    File cluster_report = cluster2.cluster_report
    Array[File] hq_bam = cluster2.hq_bam
    Array[File] hq_pbi = cluster2.hq_pbi
    Array[File] lq_bam = cluster2.lq_bam
    Array[File] lq_pbi = cluster2.lq_pbi
    Array[File] singletons_bam = cluster2.singletons_bam
    Array[File] singletons_pbi = cluster2.singletons_pbi
    File fofn = cluster2.fofn
  }
}
