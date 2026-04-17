/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ISOTOOLS_ORPHAN — Identify orphan transcripts using iso-orphan.
    Finds transcripts in the query that do not overlap with any reference
    transcript and separates them from matched transcripts.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process ISOTOOLS_ORPHAN {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bed)
    tuple val(meta1), path(reference)

    output:
    tuple val(meta), path("*/*.hq.bed")       , optional: true, emit: hq
    tuple val(meta1), path("*/*.scraps.bed")  , optional: true, emit: scraps
    path "versions.yml"                       , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"

    meta1 = meta.clone()
    meta1.id = meta.id.split('.')[0] + '.scraps'
    """
    cut -f1-12 ${bed} > tmp.bed

    iso-orphan \\
        $args \\
        --ref $reference \\
        --query tmp.bed \\
        --all \\
        --threads ${task.cpus} \\
        --prefix ${prefix} 

    if [ ! -s orphans/${prefix}.hq.bed ]; then
        rm orphans/${prefix}.hq.bed
    else
        grep -f \\
        <(cut -f4 orphans/${prefix}.hq.bed) ${bed} \\
        > tmp.bed && \\
        mv tmp.bed orphans/${prefix}.hq.bed
    fi

    if [ ! -s orphans/${prefix}.scraps.bed ]; then
        rm orphans/${prefix}.scraps.bed
    else
        grep -f \\
        <(cut -f4 orphans/${prefix}.scraps.bed) ${bed} \\
        > tmp.bed && \\
        mv tmp.bed orphans/${prefix}.scraps.bed
    fi

    rm tmp.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-orphan: \$( iso-orphan --version | sed 's/iso-orphan //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch orphans/${prefix}.hq.bed
    touch orphans/${prefix}.scraps.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-orphan: \$( iso-orphan --version | sed 's/iso-orphan //g' )
    END_VERSIONS
    """
}
