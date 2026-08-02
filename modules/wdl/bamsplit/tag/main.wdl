# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BAMSPLIT_TAG — Split a BAM file into one output per auxiliary-tag value or
# `@RG`-derived field. Route on a BAM tag (`--tag`, e.g. `CB`) or a read-group
# field (`--field`, e.g. `sample`). Records lacking the value go to a
# dedicated `no-tag` output.

version 1.3

task tag {
  input {
    File bam
    String? bam_tag
    String? bam_field
    String out_dir = "by-tag"
    String extra_args = ""
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    if [ -z "~{default="" bam_tag}" ] && [ -z "~{default="" bam_field}" ]; then
      echo "BAMSPLIT_TAG: either bam_tag or bam_field must be set" >&2
      exit 1
    fi

    route=()
    if [ -n "~{default="" bam_tag}" ]; then
      route+=(--tag "~{default="" bam_tag}")
    else
      route+=(--field "~{default="" bam_field}")
    fi

    bamsplit \
        tag \
        ~{extra_args} \
        "${route[@]}" \
        ~{bam} \
        --out-dir ~{out_dir} \
        -t ~{threads}

    cat <<-END_VERSIONS > versions.yml
    "BAMSPLIT_TAG":
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
    String? bam_tag
    String? bam_field
    String out_dir = "by-tag"
    String extra_args = ""
    Int threads = 1
  }

  call tag {
    input:
      bam = bam,
      bam_tag = bam_tag,
      bam_field = bam_field,
      out_dir = out_dir,
      extra_args = extra_args,
      threads = threads
  }

  output {
    Array[File] bams = tag.bams
    Array[File] bais = tag.bais
    Array[File] csis = tag.csis
    Array[File] manifests = tag.manifests
    File versions = tag.versions
  }
}
