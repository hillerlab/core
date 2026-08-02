# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BAMSPLIT_REGION — Split a BAM file into one output per annotated region
# (BED/GTF/GFF) or per generated window. Reads are assigned to regions by
# alignment start (`--assignment start` default) or best overlap. Builds an
# index for every output.

version 1.3

task region {
  input {
    File bam
    File? annotation
    Int? window_size
    String out_dir = "regions"
    String extra_args = ""
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    if [ -z "~{default="" annotation}" ] && [ -z "~{default="" window_size}" ]; then
      echo "BAMSPLIT_REGION: an annotation input or window_size must be provided" >&2
      exit 1
    fi

    regions_arg=()
    if [ -n "~{default="" annotation}" ]; then
      regions_arg+=(--regions "~{default="" annotation}")
    else
      regions_arg+=(--window-size "~{default="" window_size}")
    fi

    bamsplit \
        region \
        ~{extra_args} \
        "${regions_arg[@]}" \
        ~{bam} \
        --out-dir ~{out_dir} \
        -t ~{threads}

    cat <<-END_VERSIONS > versions.yml
    "BAMSPLIT_REGION":
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
    File? annotation
    Int? window_size
    String out_dir = "regions"
    String extra_args = ""
    Int threads = 1
  }

  call region {
    input:
      bam = bam,
      annotation = annotation,
      window_size = window_size,
      out_dir = out_dir,
      extra_args = extra_args,
      threads = threads
  }

  output {
    Array[File] bams = region.bams
    Array[File] bais = region.bais
    Array[File] csis = region.csis
    Array[File] manifests = region.manifests
    File versions = region.versions
  }
}
