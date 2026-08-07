# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# SQANTI3_QC — Structural QC and classification of collapsed transcript models
# against a reference annotation and genome. Classification only.

version 1.3

task qc {
  input {
    File models
    File ref_gtf
    File ref_fasta
    Int threads = 1
    String args = ""
  }

  String prefix = sub(models, "\\.[^\\.]+$", "")

  command <<<
    set -euo pipefail

    # TOGA references carry degenerate "lost gene" transcripts (a 3-bp entry with
    # start/stop codons but no CDS). SQANTI3's gtfToGenePred rejects these; drop the
    # codon records since coding bounds are derived from CDS.
    awk -F'\t' '/^#/ || ($3 != "start_codon" && $3 != "stop_codon")' ~{ref_gtf} > ref.sqanti.gtf

    # classification and junction table are the meaningful outputs; the HTML report is
    # an optional R step that can fail on unusual isoform IDs, so don't let it kill the
    # run once classification has succeeded.
    set +e
    sqanti3_qc.py \
      --isoforms ~{models} \
      --refGTF ref.sqanti.gtf \
      --refFasta ~{ref_fasta} \
      -o "~{prefix}" \
      -d . \
      -t ~{threads} \
      ~{args}
    sqanti_rc=$?
    set -e

    if [ -s "${prefix}_corrected.cds.gff3" ]; then
      mv "${prefix}_corrected.cds.gff3" "${prefix}_corrected.cds.gtf"
    fi

    if [ ! -s "${prefix}_classification.txt" ] || [ ! -s "${prefix}_junctions.txt" ]; then
        echo "SQANTI3_QC failed before producing classification/junctions (exit ${sqanti_rc})" >&2
        exit ${sqanti_rc}
    fi
    if [ "${sqanti_rc}" -ne 0 ]; then
        echo "WARNING: SQANTI3_QC exited ${sqanti_rc} after classification -- likely the optional HTML report step; continuing with classification outputs." >&2
    fi
  >>>

  output {
    File corrected_gtf = "~{prefix}_corrected.gtf"
    File classification = "~{prefix}_classification.txt"
    File junctions = "~{prefix}_junctions.txt"
    File? corrected_fasta = "~{prefix}_corrected.fasta"
    File? cds_gtf = "~{prefix}_corrected.cds.gtf"
    File? genepred = "~{prefix}_corrected.genePred"
    File? report_html = "~{prefix}_SQANTI3_report.html"
    File? report_pdf = "~{prefix}_SQANTI3_report.pdf"
    File? params = "~{prefix}.qc_params.txt"
  }

  requirements {
    container: "quay.io/biocontainers/sqanti3:6.0.1--hdfd78af_0"
  }
}

workflow run {
  input {
    File models
    File ref_gtf
    File ref_fasta
    Int threads = 1
    String args = ""
  }

  call qc {
    input:
      models = models,
      ref_gtf = ref_gtf,
      ref_fasta = ref_fasta,
      threads = threads,
      args = args
  }

  output {
    File corrected_gtf = qc.corrected_gtf
    File classification = qc.classification
    File junctions = qc.junctions
    File? corrected_fasta = qc.corrected_fasta
    File? cds_gtf = qc.cds_gtf
    File? genepred = qc.genepred
    File? report_html = qc.report_html
    File? report_pdf = qc.report_pdf
    File? params = qc.params
  }
}
