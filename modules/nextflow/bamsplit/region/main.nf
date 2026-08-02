/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BAMSPLIT_REGION — Split a BAM file into one output per annotated region
    (BED/GTF/GFF) or per generated window. Reads are assigned to regions by
    alignment start (`--assignment start` default) or best overlap. Builds an
    index for every output.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BAMSPLIT_REGION {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/bamsplit:latest' }"

    input:
    tuple val(meta), path(bam)
    tuple val(meta1), path(annotation)

    output:
    tuple val(meta), path("*/*.bam")        , optional: true, emit: bam
    tuple val(meta), path("*/*.bai")        , optional: true, emit: bai
    tuple val(meta), path("*/*.csi")        , optional: true, emit: csi
    tuple val(meta), path("*/*.json")       , optional: true, emit: manifest
    path  "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args        ?: ''
    def out_dir     = task.ext.out_dir     ?: 'regions'
    def window_size = task.ext.window_size ?: null

    if (!annotation && !window_size) {
        error "BAMSPLIT_REGION: an `annotation` input or `ext.window_size` must be provided"
    }

    def regions_arg
    if (annotation) {
        regions_arg = "--regions $annotation"
    }
    else {
        regions_arg = "--window-size $window_size"
    }
    """
    bamsplit \\
        region \\
        $args \\
        $regions_arg \\
        $bam \\
        --out-dir $out_dir \\
        -t $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bamsplit: \$( bamsplit --version | head -n 1 | sed 's/bamsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def out_dir = task.ext.out_dir ?: 'regions'
    """
    mkdir -p $out_dir
    touch $out_dir/*.bam
    touch $out_dir/*.bai
    touch $out_dir/*.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bamsplit: \$( bamsplit --version | head -n 1 | sed 's/bamsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
}
