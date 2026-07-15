# Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
# Distributed under the terms of the Apache License, Version 2.0.

# LONGREAD_PREPARE — Prepare isoform simulation inputs for longread.
# Processes BED annotations and transcript-gene mappings to generate
# isoform, depth, and manifest files used by downstream simulation tools.

version 1.3

task prepare {
  input {
    File bed
    File transcript_gene
    File? chrom_sizes
    String prefix = "output"
    Int? new_isoforms_per_gene
    Float mean_new_isoforms_per_gene = 1.0
    Int max_new_isoforms_per_gene = 5
    String event_weights = "1.0"
    Int max_event_attempts = 5
    Int minimum_transcript_length = 200
    Int fusion_count = 0
    Int min_fusion_intron = 50000
    Int? max_fusion_distance
    Float fusion_expression_scale = 0.05
    Int total_molecules = 10000000
    Float alpha = 1.0
    Int seed = 42
    Int threads = 1
  }

  command <<<
    set -euo pipefail

    chrom_arg=()
    if [ -n "~{default="" chrom_sizes}" ]; then
      chrom_arg+=(--chrom-sizes "~{default="" chrom_sizes}")
    fi

    iso_mode=()
    if [ -n "~{default="" new_isoforms_per_gene}" ]; then
      iso_mode+=(--new-isoforms-per-gene "~{default="" new_isoforms_per_gene}")
    else
      iso_mode+=(--mean-new-isoforms-per-gene "~{mean_new_isoforms_per_gene}")
      iso_mode+=(--max-new-isoforms-per-gene "~{max_new_isoforms_per_gene}")
    fi

    maxdist=()
    if [ -n "~{default="" max_fusion_distance}" ]; then
      maxdist+=(--max-fusion-distance "~{default="" max_fusion_distance}")
    fi

    longread prepare \
      --bed ~{bed} \
      --transcript-gene ~{transcript_gene} \
      "${chrom_arg[@]}" \
      --output-prefix ~{prefix} \
      "${iso_mode[@]}" \
      --event-weights ~{event_weights} \
      --max-event-attempts ~{max_event_attempts} \
      --minimum-transcript-length ~{minimum_transcript_length} \
      --fusion-count ~{fusion_count} \
      --min-fusion-intron ~{min_fusion_intron} \
      "${maxdist[@]}" \
      --fusion-expression-scale ~{fusion_expression_scale} \
      --total-molecules ~{total_molecules} \
      --alpha ~{alpha} \
      --seed ~{seed} \
      --threads ~{threads}
  >>>

  output {
    File isoforms_bed = prefix + ".isoforms.bed"
    File transcript_gene_out = prefix + ".transcript_gene.tsv"
    File gene_depth = prefix + ".gene_depth.tsv"
    File isoform_depth = prefix + ".isoform_depth.tsv"
    File manifest = prefix + ".manifest.tsv"
    File stats = prefix + ".stats.json"
  }

  requirements {
    container: "ghcr.io/hillerlab/longread-rs:latest"
  }
}

workflow run {
  input {
    File bed
    File transcript_gene
    File? chrom_sizes
    String prefix = "output"
    Int? new_isoforms_per_gene
    Float mean_new_isoforms_per_gene = 1.0
    Int max_new_isoforms_per_gene = 5
    String event_weights = "1.0"
    Int max_event_attempts = 5
    Int minimum_transcript_length = 200
    Int fusion_count = 0
    Int min_fusion_intron = 50000
    Int? max_fusion_distance
    Float fusion_expression_scale = 0.05
    Int total_molecules = 10000000
    Float alpha = 1.0
    Int seed = 42
    Int threads = 1
  }

  call prepare {
    input:
      bed = bed,
      transcript_gene = transcript_gene,
      chrom_sizes = chrom_sizes,
      prefix = prefix,
      new_isoforms_per_gene = new_isoforms_per_gene,
      mean_new_isoforms_per_gene = mean_new_isoforms_per_gene,
      max_new_isoforms_per_gene = max_new_isoforms_per_gene,
      event_weights = event_weights,
      max_event_attempts = max_event_attempts,
      minimum_transcript_length = minimum_transcript_length,
      fusion_count = fusion_count,
      min_fusion_intron = min_fusion_intron,
      max_fusion_distance = max_fusion_distance,
      fusion_expression_scale = fusion_expression_scale,
      total_molecules = total_molecules,
      alpha = alpha,
      seed = seed,
      threads = threads
  }

  output {
    File isoforms_bed = prepare.isoforms_bed
    File transcript_gene_out = prepare.transcript_gene_out
    File gene_depth = prepare.gene_depth
    File isoform_depth = prepare.isoform_depth
    File manifest = prepare.manifest
    File stats = prepare.stats
  }
}
