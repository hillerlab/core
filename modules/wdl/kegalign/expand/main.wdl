# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# KEGALIGN_EXPAND — Unpack a KegAlign package into one job record per partition.
# Emits the extracted package plus jobs.tsv (job_id, segments filename), one
# line per KegAlign diagonal partition, which KEGALIGN_ALIGNMENT fans out into
# independent KEG_LASTZ tasks.
#
# Job ids are assigned in .segments-filename order, not commands.json order:
# KegAlign writes commands.json from parallel workers, so its line order is not
# reproducible and ids derived from it would break resume caching.
#
# Partition boundaries are read, never recomputed — KegAlign stays the sole
# authority for HSP partitioning.

version 1.3

task expand {
  input {
    File tarball
  }

  command <<<
    set -euo pipefail

    mkdir -p package
    tar -xzf ~{tarball} -C package

    test -s package/galaxy/commands.json || {
        echo "KegAlign package has no galaxy/commands.json: ~{tarball}" >&2
        exit 1
    }

    # One --segments= per LASTZ command, and it is the partition's identity.
    grep -o '"--segments=[^"]*"' package/galaxy/commands.json \
        | sed 's/^"--segments=//; s/"$//' \
        | sort > segments.txt

    test -s segments.txt || {
        echo "KegAlign package declares no partitions: ~{tarball}" >&2
        exit 1
    }
    if [ "$(sort -u segments.txt | wc -l)" -ne "$(wc -l < segments.txt)" ]; then
        echo "Duplicate --segments= across KegAlign commands — job ids would collide." >&2
        exit 1
    fi

    awk '{ printf "keg_%06d\t%s\n", NR, $0 }' segments.txt > jobs.tsv
    echo "KegAlign partitions: $(wc -l < jobs.tsv)" >&2
  >>>

  output {
    Array[File] package = glob("package/**")
    File jobs = "jobs.tsv"
  }

  requirements {
    container: "quay.io/biocontainers/python:3.8.0--2"
  }
}

workflow run {
  input {
    File tarball
  }

  call expand {
    input:
      tarball = tarball
  }

  output {
    Array[File] package = expand.package
    File jobs = expand.jobs
  }
}