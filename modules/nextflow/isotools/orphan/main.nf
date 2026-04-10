/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
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
    tuple val(meta), path("*/*orphan_free.bed")       , optional: true, emit: pass
    tuple val(meta1), path("*/*orphans.bed")          , optional: true, emit: orphans
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"

    meta1 = meta.clone()
    meta1.id = meta.id.split('.')[0] + '.orphans'
    """
    cut -f1-12 ${bed} > tmp.bed

    iso-orphan \\
        $args \\
        --ref $reference \\
        --query tmp.bed \\
        --all \\
        --threads ${task.cpus} \\
        --prefix ${prefix} 

    if [ ! -s orphans/${prefix}.orphan_free.bed ]; then
        rm orphans/${prefix}.orphan_free.bed
    else
        grep -f \\
        <(cut -f4 orphans/${prefix}.orphan_free.bed) ${bed} \\
        > tmp.bed && \\
        mv tmp.bed orphans/${prefix}.orphan_free.bed
    fi

    if [ ! -s orphans/${prefix}.orphans.bed ]; then
        rm orphans/${prefix}.orphans.bed
    else
        grep -f \\
        <(cut -f4 orphans/${prefix}.orphans.bed) ${bed} \\
        > tmp.bed && \\
        mv tmp.bed orphans/${prefix}.orphans.bed
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
    touch orphans/${prefix}.orphan_free.bed
    touch orphans/${prefix}.orphans.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-orphan: \$( iso-orphan --version | sed 's/iso-orphan //g' )
    END_VERSIONS
    """
}
