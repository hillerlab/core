# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PIGEON_CLASSIFY — Classify a prepared query GFF against a prepared reference,
# producing SQANTI3-style classification and junction tables. Classification only.

version 1.3

task classify {
  input {
    File models_gff
    File models_pgi
    File ref_gtf
    File ref_pgi
    File ref_fasta
    File ref_fai
    Int threads = 1
    String args = ""
  }

  String prefix = sub(models_gff, "\\.sorted\\.gtf$", "")

  command <<<
    set -euo pipefail

    pigeon classify \
      -j ~{threads} \
      -d . \
      -o "~{prefix}" \
      ~{args} \
      ~{models_gff} \
      ~{ref_gtf} \
      ~{ref_fasta}
  >>>

  output {
    File classification = "~{prefix}_classification.txt"
    File junctions = "~{prefix}_junctions.txt"
    # ponytail: report/summary are optional and unpredicatably named; select via glob,
    # absent when Pigeon does not emit them.
    File? report = if length(glob("*.report.json")) > 0 then glob("*.report.json")[0] else "NO_PIGEON_REPORT"
    File? summary = if length(glob("*.summary.txt")) > 0 then glob("*.summary.txt")[0] else "NO_PIGEON_SUMMARY"
  }

  requirements {
    container: "quay.io/biocontainers/pbpigeon:26.2.0--h9ee0642_0"
  }
}

workflow run {
  input {
    File models_gff
    File models_pgi
    File ref_gtf
    File ref_pgi
    File ref_fasta
    File ref_fai
    Int threads = 1
    String args = ""
  }

  call classify {
    input:
      models_gff = models_gff,
      models_pgi = models_pgi,
      ref_gtf = ref_gtf,
      ref_pgi = ref_pgi,
      ref_fasta = ref_fasta,
      ref_fai = ref_fai,
      threads = threads,
      args = args
  }

  output {
    File classification = classify.classification
    File junctions = classify.junctions
    File? report = classify.report
    File? summary = classify.summary
  }
}
