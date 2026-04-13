# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# PB_BAM_TO_FA — Extract PacBio BAM sequences to FASTA format.
# Splits a PacBio BAM file into high-quality reads and singletons,
# outputting both FASTA and BAM formats.

version 1.3

task pbbamtofa {
  input {
    File bam
    Int threads = 1
  }

  String prefix = basename(bam, ".bam")
  String singletons = prefix + ".singletons.fasta.gz"
  String singletons_bam = prefix + ".singletons.bam"
  String hq = prefix + ".hq.fasta.gz"
  String hq_bam = prefix + ".hq.bam"

  command <<<
    set -uo pipefail

    set +e
    trap '' PIPE
    samtools view -h -@ ~{threads} ~{bam} \
      | tee >(
          awk '{
            if ($1 ~ /^@/) { print; next }
            for (i = 12; i <= NF; i++) {
              if ($i ~ /^is:i:1$/) { print; break }
            }
          }' \
            | samtools view -@ ~{threads} -bo ~{singletons_bam} -
        ) \
      | awk '{
          if ($1 ~ /^@/) { print; next }
          for (i = 12; i <= NF; i++) {
            if ($i ~ /^is:i:/) {
              split($i, a, ":")
              if (a[3] != 1) { print; break }
            }
          }
        }' \
      | samtools view -@ ~{threads} -bo ~{hq_bam} -

    set -e
    samtools fasta -@ ~{threads} ~{hq_bam} | gzip -9 > ~{hq}
    samtools fasta -@ ~{threads} ~{singletons_bam} | gzip -9 > ~{singletons}

    for f in ~{hq} ~{singletons}; do
      if [ -f "$f" ]; then
        if gunzip -c "$f" 2>/dev/null | awk 'BEGIN { has_content = 0 } { has_content = 1 } END { exit has_content ? 0 : 1 }'; then
          :
        elif gzip -t "$f" >/dev/null 2>&1; then
          rm "$f"
        else
          echo "Failed to validate $f" >&2
          exit 1
        fi
      fi
    done
  >>>

  output {
    Array[File] singletons = glob("*.singletons.fasta.gz")
    Array[File] singletons_bam = glob("*.singletons.bam")
    Array[File] hq = glob("*.hq.fasta.gz")
    Array[File] hq_bam = glob("*.hq.bam")
  }

  requirements {
    container: "biocontainers/samtools:1.22.1--h96c455f_0"
  }
}

workflow run {
  input {
    File bam
    Int threads = 1
  }

  call pbbamtofa {
    input:
      bam = bam,
      threads = threads
  }

  output {
    Array[File] singletons = pbbamtofa.singletons
    Array[File] singletons_bam = pbbamtofa.singletons_bam
    Array[File] hq = pbbamtofa.hq
    Array[File] hq_bam = pbbamtofa.hq_bam
  }
}
