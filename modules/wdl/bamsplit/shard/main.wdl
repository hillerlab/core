# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# BAMSPLIT_SHARD — Split a BAM file into a fixed number of deterministic,
# hash-assigned shards. Records are hashed on a key (`qname` by default) so
# that every read of a pair stays in the same shard. Builds an index for
# every output shard.

version 1.3

task shard {
  input {
    File bam
    Int shards = 8
    String key = "qname"
    String out_dir = "shards"
    String extra_args = ""
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    bamsplit \
        shard \
        ~{extra_args} \
        ~{bam} \
        --shards ~{shards} \
        --key ~{key} \
        --out-dir ~{out_dir} \
        -t ~{threads}

    cat <<-END_VERSIONS > versions.yml
    "BAMSPLIT_SHARD":
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
    Int shards = 8
    String key = "qname"
    String out_dir = "shards"
    String extra_args = ""
    Int threads = 1
  }

  call shard {
    input:
      bam = bam,
      shards = shards,
      key = key,
      out_dir = out_dir,
      extra_args = extra_args,
      threads = threads
  }

  output {
    Array[File] bams = shard.bams
    Array[File] bais = shard.bais
    Array[File] csis = shard.csis
    Array[File] manifests = shard.manifests
    File versions = shard.versions
  }
}
