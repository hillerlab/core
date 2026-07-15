/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process LONGREAD_PREPARE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/longread-rs:latest' }"

    input:
    tuple val(meta), path(bed), path(transcript_gene)
    path chrom_sizes

    output:
    tuple val(meta), path("${meta.id}.isoforms.bed"),         emit: bed
    tuple val(meta), path("${meta.id}.transcript_gene.tsv"),  emit: transcript_gene
    tuple val(meta), path("${meta.id}.gene_depth.tsv"),       emit: gene_depth
    tuple val(meta), path("${meta.id}.isoform_depth.tsv"),    emit: isoform_depth
    tuple val(meta), path("${meta.id}.manifest.tsv"),         emit: manifest
    tuple val(meta), path("${meta.id}.stats.json"),           emit: stats
    path "versions.yml",                                      emit: versions

    script:
    def chrom_arg = chrom_sizes ? "--chrom-sizes ${chrom_sizes}" : ''
    def iso_mode  = params.new_isoforms_per_gene != null
        ? "--new-isoforms-per-gene ${params.new_isoforms_per_gene}"
        : "--mean-new-isoforms-per-gene ${params.mean_new_isoforms_per_gene} --max-new-isoforms-per-gene ${params.max_new_isoforms_per_gene}"
    def maxdist   = params.max_fusion_distance != null ? "--max-fusion-distance ${params.max_fusion_distance}" : ''
    """
    longread prepare \\
        --bed ${bed} \\
        --transcript-gene ${transcript_gene} \\
        ${chrom_arg} \\
        --output-prefix ${meta.id} \\
        ${iso_mode} \\
        --event-weights ${params.event_weights} \\
        --max-event-attempts ${params.max_event_attempts} \\
        --minimum-transcript-length ${params.minimum_transcript_length} \\
        --fusion-count ${params.fusion_count} \\
        --min-fusion-intron ${params.min_fusion_intron} \\
        ${maxdist} \\
        --fusion-expression-scale ${params.fusion_expression_scale} \\
        --total-molecules ${params.total_molecules} \\
        --alpha ${params.alpha} \\
        --seed ${params.seed} \\
        --threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.isoforms.bed
    touch ${prefix}.transcript_gene.tsv
    touch ${prefix}.gene_depth.tsv
    touch ${prefix}.isoform_depth.tsv
    touch ${prefix}.manifest.tsv
    touch ${prefix}.stats.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        longread: \$(longread --version | sed 's/longread //')
    END_VERSIONS
    """
}

