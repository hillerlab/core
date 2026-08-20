# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# KEGALIGN — GPU seeding / ungapped-extension / HSP filtering stage.
# Runs upstream KegAlign through its own orchestrator (runner.py) and packages
# the resulting per-block LASTZ workload as a tarball. Only this task needs a
# GPU: the gapped-extension LASTZ commands inside the tarball are run later by
# KEGALIGN_LASTZ on CPU, so the GPU allocation ends here.
#
# KegAlign owns its own reference/query partitioning.

version 1.3

task kegalign {
  input {
    String reference_name
    File reference_fa
    String query_name
    File query_fa
    Int lastz_k
    Int lastz_l
    Int lastz_h
    Int lastz_y
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    # KegAlign's LASTZ commands reference "<data_folder>ref.2bit" and
    # "<data_folder>query.2bit" by those exact names (hardcoded in KegAlign's
    # segment_printer), and runner.py hardcodes the data folder as "work/".
    mkdir -p work
    faToTwoBit ~{reference_fa} work/ref.2bit
    faToTwoBit ~{query_fa}     work/query.2bit

    # runner.py shells out to <tool_directory>/diagonal_partition.py and
    # package_output.py reads <tool_directory>/lastz-cmd.ini; both ship next to
    # the KegAlign executables (container /usr/local/bin, or the conda env bin).
    tool_dir=$(dirname $(command -v diagonal_partition.py))

    # Diagonal partitioning is always on: it splits oversized .segments files so
    # no single downstream LASTZ command blows up on traceback memory.
    runner.py \
        --output-type tarball \
        --output-file lastz-commands.txt \
        --tool_directory "$tool_dir" \
        --diagonal-partition \
        --num-cpu ~{threads} \
        ~{reference_fa} ~{query_fa} \
        --format axt+ \
        --hspthresh ~{lastz_k} \
        --gappedthresh ~{lastz_l} \
        --inner ~{lastz_h} \
        --ydrop ~{lastz_y}

    # Without this, package_output.py packs an empty workload and the failure
    # only surfaces inside run_lastz_tarball.py as an opaque output-count error.
    test -s lastz-commands.txt || {
        echo "KegAlign produced no alignment commands: no HSP passed --hspthresh ~{lastz_k}." >&2
        echo "Nothing to align for ~{reference_name} vs ~{query_name}." >&2
        exit 1
    }

    package_output.py --tool_directory "$tool_dir" --format_selector axt+
    mv data_package.tgz ~{reference_name}.~{query_name}.kegalign.tgz
  >>>

  output {
    File tarball = "~{reference_name}.~{query_name}.kegalign.tgz"
  }

  requirements {
    container: "quay.io/biocontainers/kegalign-full:0.1.2.9--hdfd78af_0"
  }
}

workflow run {
  input {
    String reference_name
    File reference_fa
    String query_name
    File query_fa
    Int lastz_k
    Int lastz_l
    Int lastz_h
    Int lastz_y
    Int threads = 1
  }

  call kegalign {
    input:
      reference_name = reference_name,
      reference_fa = reference_fa,
      query_name = query_name,
      query_fa = query_fa,
      lastz_k = lastz_k,
      lastz_l = lastz_l,
      lastz_h = lastz_h,
      lastz_y = lastz_y,
      threads = threads
  }

  output {
    File tarball = kegalign.tarball
  }
}