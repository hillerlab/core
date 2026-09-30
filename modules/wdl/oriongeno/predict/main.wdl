# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# ORIONGENO_PREDICT — Ab initio OrionGeno annotation on one GPU.
# Inference requires an NVIDIA GPU (compute capability >= 7.0, driver >= 525.60.13).
# There is no CPU fallback. lineage selects a checkpoint baked into the image
# and does not select the species. The published image contains mammals unless
# it was built with ORIONGENO_MODELS. checkpoint overrides lineage when set.
# format is gtf (default) or gff3. output_repeat also writes the repeat annotation.
# extra_args is appended as-is. Bundled OrionGeno is non-commercial.

version 1.3

task predict {
  input {
    File genome
    String lineage = "mammals"
    String species_name = ""
    String format = "gtf"
    Boolean output_repeat = false
    String checkpoint = ""
    String extra_args = ""
    String prefix = ""
  }

  String stem = sub(sub(basename(genome), "\\.gz$", ""), "\\.(fa|fasta|fna|fas)$", "")
  String sample = if prefix != "" then prefix else stem
  String ext = if format == "gff" || format == "gff3" then "gff3" else "gtf"
  String annotation_path = "annotation/" + sample + "." + ext
  String repeat_path = "repeats/" + sample + ".repeat." + ext

  command <<<
    set -euo pipefail

    lineage="~{lineage}"
    format="~{format}"
    checkpoint="~{checkpoint}"
    species="~{species_name}"

    case "$format" in
      gtf|gff|gff3) ;;
      *)
        echo "Unknown OrionGeno format '$format'. Use gtf or gff3." >&2
        exit 1
        ;;
    esac

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

    oriongeno \
      --genome "~{genome}" \
      --output "~{annotation_path}" \
      --checkpoint "$ckpt" \
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
    String lineage = "mammals"
    String species_name = ""
    String format = "gtf"
    Boolean output_repeat = false
    String checkpoint = ""
    String extra_args = ""
    String prefix = ""
  }

  call predict {
    input:
      genome = genome,
      lineage = lineage,
      species_name = species_name,
      format = format,
      output_repeat = output_repeat,
      checkpoint = checkpoint,
      extra_args = extra_args,
      prefix = prefix
  }

  output {
    File annotation = predict.annotation
    File? repeats = predict.repeats
  }
}
