/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BAMSPLIT_TAG — Split a BAM file into one output per auxiliary-tag value or
    `@RG`-derived field. Route on a BAM tag (`--tag`, e.g. `CB`) or a read-group
    field (`--field`, e.g. `sample`). Records lacking the value go to a
    dedicated `no-tag` output.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BAMSPLIT_TAG {
    tag "$meta.id"
    label 'process_low_long'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/bamsplit:latest' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*/*.bam")        , optional: true, emit: bam
    tuple val(meta), path("*/*.bai")        , optional: true, emit: bai
    tuple val(meta), path("*/*.csi")        , optional: true, emit: csi
    tuple val(meta), path("*/*.json")       , optional: true, emit: manifest
    path  "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args    ?: ''
    def out_dir = task.ext.out_dir ?: 'by-tag'
    def tag     = task.ext.tag     ?: null
    def field   = task.ext.field   ?: null

    if (!tag && !field) {
        error "BAMSPLIT_TAG: either `ext.tag` or `ext.field` must be set"
    }
    def route = tag ? "--tag $tag" : "--field $field"
    """
    bamsplit \\
        tag \\
        $args \\
        $route \\
        $bam \\
        --out-dir $out_dir \\
        -t $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bamsplit: \$( bamsplit --version | head -n 1 | sed 's/bamsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def out_dir = task.ext.out_dir ?: 'by-tag'
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
