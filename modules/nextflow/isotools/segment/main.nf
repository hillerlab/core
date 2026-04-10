/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process ISOTOOLS_SEGMENT {
    tag "$meta.id chunk $meta.chunk"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/isotools:latest' }"

    input:
    tuple val(meta), path(bam)
    tuple val(meta2), path(bai)

    output:
    tuple val(meta), path("*.hq.bam")                    , optional: true, emit: hq_bam
    tuple val(meta), path("*.hq.bed")                    , optional: true, emit: hq_bed
    tuple val(meta), path("*.lq.bam")                    , optional: true, emit: lq_bam
    tuple val(meta), path("*.lq.bed")                    , optional: true, emit: lq_bed
    path "versions.yml"                                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args      = task.ext.args ?: ''
    def prefix    = task.ext.prefix ?: "${meta.id}"
    def singleton = meta.singleton ? "--singleton" : ""
    def keep_temp = task.ext.keep_temp ?: false
    def chunk     = meta.chunk.toInteger()
    """
    iso-segment \\
        $args \\
        --bam $bam \\
        --prefix ${prefix} \\
        --batch ${chunk} \\
        $singleton

    if [ $keep_temp == false ]; then
        if [ -f *${prefix}.lq.bed ]; then
            rm *${prefix}.lq.bed
        fi
    fi

    if [ $singleton ]; then
        for f in *${prefix}.hq.bed; do
            if [ -f "\$f" ]; then
              mv "\$f" "\${f%.hq.bed}.${chunk}.singleton.hq.bed"
            fi
        done
    else
        for f in *${prefix}.hq.bed; do
            if [ -f "\$f" ]; then
              mv "\$f" "\${f%.hq.bed}.${chunk}.hq.bed"
            fi
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-segment: \$( iso-segment --version | sed 's/iso-segment //g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch *${prefix}*.hq.bam
    touch *${prefix}*.hq.bed
    touch *${prefix}*.lq.bam
    touch *${prefix}*.lq.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        iso-segment: \$( iso-segment --version | sed 's/iso-segment //g' )
    END_VERSIONS
    """
}
