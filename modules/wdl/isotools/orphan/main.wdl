# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

version 1.3

task orphan {
  input {
    File bed
    File reference
    Int threads = 1
  }

  String prefix = basename(bed, ".bed")

  command <<<
    set -euo pipefail

    cut -f1-12 ~{bed} > tmp.bed

    iso-orphan \
      --ref ~{reference} \
      --query tmp.bed \
      --all \
      --threads ~{threads} \
      --prefix ~{prefix}

    if [ ! -s orphans/~{prefix}.orphan_free.bed ]; then
      rm -f orphans/~{prefix}.orphan_free.bed
    else
      grep -Ff <(cut -f4 orphans/~{prefix}.orphan_free.bed) ~{bed} > tmp.filtered.bed
      mv tmp.filtered.bed orphans/~{prefix}.orphan_free.bed
    fi

    if [ ! -s orphans/~{prefix}.orphans.bed ]; then
      rm -f orphans/~{prefix}.orphans.bed
    else
      grep -Ff <(cut -f4 orphans/~{prefix}.orphans.bed) ~{bed} > tmp.filtered.bed
      mv tmp.filtered.bed orphans/~{prefix}.orphans.bed
    fi

    rm -f tmp.bed
  >>>

  output {
    Array[File] pass = glob("orphans/*.orphan_free.bed")
    Array[File] orphans = glob("orphans/*.orphans.bed")
  }

  requirements {
    container: "ghcr.io/alejandrogzi/isotools:latest"
  }
}

workflow run {
  input {
    File bed
    File reference
    Int threads = 1
  }

  call orphan {
    input:
      bed = bed,
      reference = reference,
      threads = threads
  }

  output {
    Array[File] pass = orphan.pass
    Array[File] orphans = orphan.orphans
  }
}
