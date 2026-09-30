# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ORIONGENO_MULTI — Ab initio OrionGeno annotation across one or more GPUs.
# Thin wrapper around `oriongeno multi`. devices is a comma-separated list of
# GPU ids ("0,1,2,3"). The caller schedules those devices; this task writes GTF.
# lineage, species_name, output_repeat, checkpoint, and extra_args match predict.
# Inference requires an NVIDIA GPU. There is no CPU fallback.
# Bundled OrionGeno is non-commercial.

version 1.3

task multi {
  input {
    File genome
    String devices
    String lineage = "mammals"
    String species_name = ""
    Boolean output_repeat = false
    String checkpoint = ""
    String extra_args = ""
    String prefix = ""
  }

  String stem = sub(sub(basename(genome), "\\.gz$", ""), "\\.(fa|fasta|fna|fas)$", "")
  String sample = if prefix != "" then prefix else stem
  String annotation_path = "annotation/" + sample + ".gtf"
  String repeat_path = "repeats/" + sample + ".repeat.gtf"

  command <<<
    set -euo pipefail

    lineage="~{lineage}"
    devices="~{devices}"
    checkpoint="~{checkpoint}"
    species="~{species_name}"

    if [ -z "$devices" ]; then
      echo "ORIONGENO_MULTI requires at least one GPU id in devices." >&2
      exit 1
    fi

    if [ -n "$checkpoint" ]; then
      ckpt="$checkpoint"
    else
      case "$lineage" in
        mammals|birds|fish|other_vertebrates|arthropods|other_invertebrates|plants|fungi) ;;
        *)
          echo "Unknown OrionGeno lineage '$lineage'." >&2
          exit 1
          ;;
      esac
      ckpt="/opt/oriongeno/checkpoints/oriongeno_${lineage}"
    fi

    mkdir -p annotation
    species_args=()
    if [ -n "$species" ]; then
      species_args+=(--species-name "$species")
    fi

    oriongeno multi \
      --genome "~{genome}" \
      --output "~{annotation_path}" \
      --checkpoint "$ckpt" \
      --devices "$devices" \
      --work-dir oriongeno-work \
      --output-gene true \
      --output-repeat ~{if output_repeat then "true" else "false"} \
      "${species_args[@]}" \
      ~{extra_args}

    gene="~{annotation_path}"
    repeat_src="${gene%.*}.repeat.${gene##*.}"
    if [ -f "$repeat_src" ]; then
      mkdir -p repeats
      mv "$repeat_src" "~{repeat_path}"
    fi
  >>>

  output {
    File annotation = annotation_path
    File? repeats = repeat_path
  }

  requirements {
    container: "ghcr.io/hillerlab/oriongeno:latest"
  }
}

workflow run {
  input {
    File genome
    String devices
    String lineage = "mammals"
    String species_name = ""
    Boolean output_repeat = false
    String checkpoint = ""
    String extra_args = ""
    String prefix = ""
  }

  call multi {
    input:
      genome = genome,
      devices = devices,
      lineage = lineage,
      species_name = species_name,
      output_repeat = output_repeat,
      checkpoint = checkpoint,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File annotation = multi.annotation
    File? repeats = multi.repeats
  }
}
