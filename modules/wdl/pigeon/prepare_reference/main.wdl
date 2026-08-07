# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PIGEON_PREPARE_REFERENCE — Prepare the reference annotation and genome for Pigeon
# classification. Runs once per reference. Emits the sorted GTF, its .pgi index and
# the genome .fai index bundled together.

version 1.3

task prepare_reference {
  input {
    File ref_gtf
    File ref_fasta
    String args = ""
  }

  String base = sub(ref_gtf, "\\.[^\\.]+$", "")
  String out_gtf = base + ".sorted.gtf"

  command <<<
    set -euo pipefail

    # lightweight preflight so an obviously non Gencode-like reference fails with a
    # clear message rather than an obscure Pigeon parser error.
    awk 'BEGIN{FS="\t"}
         !/^#/ && NF>=9 {
             feats[$3]++
             if ($3=="gene" && $9 !~ /gene_name[ =]/) missing_gene_name++
             if ($3=="transcript") { if ($9 !~ /gene_id[ =]/) missing_gid++; if ($9 !~ /transcript_id[ =]/) missing_tid++ }
             if ($3=="gene" || $3=="transcript" || $3=="exon") { if ($7!="+" && $7!="-") bad_strand++ }
         }
         END{
             err=0
             if (!(feats["gene"]>0))       { print "PIGEON preflight ERROR: reference annotation has no gene records"       > "/dev/stderr"; err=1 }
             if (!(feats["transcript"]>0)) { print "PIGEON preflight ERROR: reference annotation has no transcript records" > "/dev/stderr"; err=1 }
             if (!(feats["exon"]>0))       { print "PIGEON preflight ERROR: reference annotation has no exon records"       > "/dev/stderr"; err=1 }
             if (missing_gene_name>0)      { print "PIGEON preflight ERROR: " missing_gene_name " gene record(s) lack a gene_name attribute (required by Pigeon)" > "/dev/stderr"; err=1 }
             if (missing_gid>0)            { print "PIGEON preflight ERROR: " missing_gid " transcript record(s) lack a gene_id attribute"       > "/dev/stderr"; err=1 }
             if (missing_tid>0)            { print "PIGEON preflight ERROR: " missing_tid " transcript record(s) lack a transcript_id attribute" > "/dev/stderr"; err=1 }
             if (bad_strand>0)             { print "PIGEON preflight ERROR: " bad_strand " gene/transcript/exon record(s) have an invalid strand (must be + or -)" > "/dev/stderr"; err=1 }
             if (err) exit 1
         }' ~{ref_gtf}

    pigeon prepare \
      ~{args} \
      ~{ref_gtf} \
      ~{ref_fasta}
  >>>

  output {
    File sorted_gtf = "~{out_gtf}"
    File pgi = "~{out_gtf}.pgi"
    File fasta_fai = "~{ref_fasta}.fai"
  }

  requirements {
    container: "quay.io/biocontainers/pbpigeon:26.2.0--h9ee0642_0"
  }
}

workflow run {
  input {
    File ref_gtf
    File ref_fasta
    String args = ""
  }

  call prepare_reference {
    input:
      ref_gtf = ref_gtf,
      ref_fasta = ref_fasta,
      args = args
  }

  output {
    File sorted_gtf = prepare_reference.sorted_gtf
    File pgi = prepare_reference.pgi
    File fasta_fai = prepare_reference.fasta_fai
  }
}
