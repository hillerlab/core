/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FLAIR_TRANSCRIPTOME — Build a high-confidence isoform ANNOTATION directly from a
    coordinate-sorted, indexed genome-aligned BAM (FLAIR 3.0 `flair transcriptome`).
    This is the FLAIR path suited to already-aligned reads: unlike `flair collapse` it
    does not require the raw reads or a BED12 query. Annotation-only — the read→isoform
    map it can emit is a native diagnostic and is never used for quantification.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process FLAIR_TRANSCRIPTOME {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/flair:3.0.0--pyhdfd78af_0' :
        'biocontainers/flair:3.0.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bam), path(bai)   // coordinate-sorted genome BAM + its .bai
    path genome                             // reference genome FASTA
    tuple val(meta2), path(annotation)      // reference annotation GTF (recommended)
    tuple val(meta3), path(shortread_sj)    // optional short-read splice junctions BED ([meta, []] when absent)

    output:
    tuple val(meta), path("*.isoforms.gtf") ,                 emit: gtf
    tuple val(meta), path("*.isoforms.bed") ,                 emit: bed
    tuple val(meta), path("*.isoforms.CDS.bed"),              optional: true, emit: cds_bed
    tuple val(meta), path("*.isoforms.fa")  , optional: true, emit: fasta
    // INFO: read→isoform map is a native diagnostic only (NOT a quantification product);
    //       kept optional and never propagated/published downstream.
    tuple val(meta), path("*.read.map.txt") , optional: true, emit: read_map
    path "versions.yml"                     ,                 emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def gtf    = annotation   ? "-f ${annotation}"        : ''
    // INFO: -j/--shortread adds short-read splice junctions (no novel SJs are detected
    //       without orthogonal short reads). Omitted when none are provided.
    def sr     = shortread_sj ? "--shortread ${shortread_sj}" : ''
    """
    flair transcriptome \\
        -b ${bam} \\
        -g ${genome} \\
        ${gtf} \\
        ${sr} \\
        -o ${prefix} \\
        -t ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flair: \$( flair --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.isoforms.gtf
    touch ${prefix}.isoforms.bed
    touch ${prefix}.isoforms.fa
    touch ${prefix}.read.map.txt
    touch ${prefix}.isoforms.CDS.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flair: \$( flair --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+\\.[0-9]+' | head -n1 )
    END_VERSIONS
    """
}
