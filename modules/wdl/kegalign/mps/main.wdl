# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# KEGALIGN_MPS — the KEGALIGN GPU stage run as N concurrent KegAlign instances
# sharing one allocated GPU through the NVIDIA MPS daemon.
#
# Still ONE task and ONE requested GPU: the chromosome-bin splitting and the
# MPS scheduling both happen inside this task, using upstream's own scripts
# (bin/split_input.py, bin/run_mig.py — vendored, not reimplemented).
#
# Emits one keg per (reference bin × query bin) pair instead of one whole-genome
# keg. Each keg is the same self-contained package KEGALIGN produces, so the
# CPU gapped-extension stage downstream is unchanged.
#
# run_mig.py's default worker starts LASTZ while KegAlign is still on the GPU;
# --kegalign_cmd swaps in bin/run_kegalign_mps_pair.py, which stops at the
# tarball. No LASTZ runs inside the GPU allocation.

version 1.3

task mps {
  input {
    String reference_name
    File reference_fa
    String query_name
    File query_fa
    Int workers
    Int lastz_k
    Int lastz_l
    Int lastz_h
    Int lastz_y
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    # Upstream's recommended bin sizing for human-sized genomes; hardcoded until
    # a benchmark actually tunes it. split_input.py keeps chromosomes intact.
    goal_bp=200000000
    max_chunks=20

    # ── preflight: MPS is the whole point, so fail here rather than at pair 1 ──
    command -v nvidia-smi > /dev/null || {
        echo "nvidia-smi not found — the gpu profile must expose the driver into the container." >&2
        exit 1
    }
    command -v nvidia-cuda-mps-control > /dev/null || {
        echo "nvidia-cuda-mps-control not found: this container cannot start an MPS daemon." >&2
        echo "Run with --kegalign_mps_workers 1 (no MPS), or use a runtime that injects the" >&2
        echo "driver's MPS binaries (Docker --gpus all does; Apptainer --nv may not)." >&2
        exit 1
    }
    python -c 'import pynvml' 2> /dev/null || {
        echo "run_mig.py needs nvidia-ml-py (pynvml), which is missing from this environment." >&2
        exit 1
    }

    uuids=$(nvidia-smi --query-gpu=uuid --format=csv,noheader | paste -sd,)
    test -n "$uuids" || {
        echo "No GPU visible to this task — --kegalign_mps_workers > 1 needs one." >&2
        exit 1
    }
    # run_mig.py pairs --MPS with --MIG by position, so it needs one worker count
    # per visible device. Every host GPU the gpu profile exposes gets used; this
    # is still a single GPU allocation.
    mps=$(nvidia-smi --query-gpu=uuid --format=csv,noheader | sed "s/.*/~{workers}/" | paste -sd,)

    # Validation guidance, not automatic worker selection: upstream reports a
    # default KegAlign instance using roughly 12-16 GiB of VRAM.
    nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits \
        | awk -v w=~{workers} '{ if ($1 / w < 14000) printf "WARNING: %d MiB VRAM shared by %d MPS workers (< 14 GiB each) — KegAlign may run out of GPU memory\n", $1, w > "/dev/stderr" }'

    # ── reference / query → similarly sized chromosome bins ──────────────────
    # Upstream's splitter, on the FASTA the subworkflow already produced. It
    # writes chunk_N plus chunk_N.2bit, which is what the pair worker symlinks.
    split_input.py --input ~{reference_fa} --out ref_split   --to_2bit --goal_bp $goal_bp --max_chunks $max_chunks
    split_input.py --input ~{query_fa}     --out query_split --to_2bit --goal_bp $goal_bp --max_chunks $max_chunks

    if find ref_split query_split -name 'chunk_*' -empty | grep -q .; then
        echo "split_input.py produced an empty bin — KegAlign would align nothing for it." >&2
        exit 1
    fi

    n_ref=$(find ref_split   -name 'chunk_*' -not -name '*.2bit' | wc -l)
    n_query=$(find query_split -name 'chunk_*' -not -name '*.2bit' | wc -l)
    expected=$(( n_ref * n_query ))
    echo "KegAlign MPS: $n_ref reference bins x $n_query query bins = $expected pairs, ~{workers} concurrent instance(s) per GPU" >&2

    # ── MPS daemon + scheduler, both task-local ──────────────────────────────
    mkdir -p tmp mps_pipe
    for uuid in $(echo "$uuids" | tr ',' ' '); do
        mkdir -p "mps_pipe/$uuid"
    done

    # run_mig.py stops its own daemons on normal completion and on error, but not
    # when this task is killed outright — a leaked daemon would hold GPU context.
    trap 'for uuid in $(echo "$uuids" | tr "," " "); do echo quit | CUDA_VISIBLE_DEVICES=$uuid CUDA_MPS_PIPE_DIRECTORY=$PWD/mps_pipe/$uuid nvidia-cuda-mps-control > /dev/null 2>&1 || true; done' EXIT

    # --output is unused: the pair worker writes its own keg_NNNN.tgz, so
    # run_mig.py finds no part files to concatenate and reports "Missing N output
    # parts" / "Could not combine results" on every successful run. Harmless —
    # the keg count below is the check that matters.
    run_mig.py \
        --MIG "$uuids" \
        --MPS "$mps" \
        --target ref_split \
        --query query_split \
        --tmp_dir tmp \
        --mps_pipe_dir mps_pipe \
        --output ignored.tgz \
        --format axt+ \
        --num_threads ~{threads} \
        --kegalign_cmd run_kegalign_mps_pair.py \
        --opt_cmd "--hspthresh ~{lastz_k} --gappedthresh ~{lastz_l} --inner ~{lastz_h} --ydrop ~{lastz_y}"

    # ── integrity: run_mig.py exits 0 even when it loses pairs ───────────────
    # Same last-line defence the distributed CPU stage keeps over its partition
    # list. Without it a lost pair silently produces incomplete chains.
    n_keg=$(find . -maxdepth 1 -name 'keg_*.tgz'   | wc -l)
    n_none=$(find . -maxdepth 1 -name 'keg_*.empty' | wc -l)
    if [ $(( n_keg + n_none )) -ne $expected ]; then
        echo "KegAlign MPS integrity check failed: expected $expected chunk pairs" \
             "($n_ref reference bins x $n_query query bins), got $n_keg keg(s)" \
             "and $n_none pair(s) with no HSP. $(( expected - n_keg - n_none )) pair(s)" \
             "were lost silently — see e.txt, o.txt and any surviving pair_*/runner.log." >&2
        exit 1
    fi
    test "$n_keg" -gt 0 || {
        echo "No chunk pair produced any alignment command: no HSP passed --hspthresh ~{lastz_k}." >&2
        exit 1
    }
    echo "KegAlign MPS integrity check passed: $n_keg/$expected kegs ($n_none pair(s) had no HSP above --hspthresh)" >&2

    # Name kegs like KEGALIGN's single tarball so the CPU stage derives unique
    # per-keg output names from them.
    for keg in keg_*.tgz; do
        mv "$keg" "~{reference_name}.~{query_name}.${keg%.tgz}.kegalign.tgz"
    done
  >>>

  output {
    Array[File] tarball = glob("*.kegalign.tgz")
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
    Int workers
    Int lastz_k
    Int lastz_l
    Int lastz_h
    Int lastz_y
    Int threads = 1
  }

  call mps {
    input:
      reference_name = reference_name,
      reference_fa = reference_fa,
      query_name = query_name,
      query_fa = query_fa,
      workers = workers,
      lastz_k = lastz_k,
      lastz_l = lastz_l,
      lastz_h = lastz_h,
      lastz_y = lastz_y,
      threads = threads
  }

  output {
    Array[File] tarball = mps.tarball
  }
}