# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BAM2GTF — Turn a genome-aligned (spliced) BAM into a transcript GTF, one transcript
# per primary read: each read's CIGAR is walked so that N operations split exons.
# No collapsing is done.

version 1.3

task bam2gtf {
  input {
    File bam
    String args = ""
  }

  String prefix = basename(bam, ".bam")

  command <<<
    set -euo pipefail

    samtools view -F 2308 ~{bam} \
      | awk 'BEGIN{ OFS="\t" }
        {
          qn=$1; flag=$2; chr=$3; pos=$4+0; cig=$6
          if (chr=="*" || cig=="*") next
          strand = (int(flag/16)%2) ? "-" : "+"
          refpos = pos; exstart = pos; ne = 0; num = ""
          L = length(cig)
          for (k=1; k<=L; k++) {
            c = substr(cig, k, 1)
            if (c ~ /[0-9]/) { num = num c; continue }
            n = num + 0; num = ""
            if (c=="M" || c=="=" || c=="X" || c=="D") { refpos += n }
            else if (c=="N") { ne++; es[ne]=exstart; ee[ne]=refpos-1; refpos += n; exstart = refpos }
          }
          ne++; es[ne]=exstart; ee[ne]=refpos-1
          attr = "gene_id \"" qn "\"; transcript_id \"" qn "\";"
          print chr, "bam", "transcript", pos, refpos-1, ".", strand, ".", attr
          for (i=1; i<=ne; i++) print chr, "bam", "exon", es[i], ee[i], ".", strand, ".", attr
        }' > "~{prefix}.models.gtf" \
      ~{args}
  >>>

  output {
    File gtf = "~{prefix}.models.gtf"
  }

  requirements {
    container: "quay.io/biocontainers/samtools:1.23--h96c455f_0"
  }
}

workflow run {
  input {
    File bam
    String args = ""
  }

  call bam2gtf {
    input:
      bam = bam,
      args = args
  }

  output {
    File gtf = bam2gtf.gtf
  }
}
