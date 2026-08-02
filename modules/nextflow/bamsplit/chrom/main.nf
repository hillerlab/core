/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BAMSPLIT_CHROM — Split a BAM file into one output per reference sequence.
    Losslessly partitions reads by chromosome, with unplaced records routed to a
    dedicated `unmapped` output. Builds an index (BAI/CSI) for every output.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BAMSPLIT_CHROM {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/alejandrogzi/bamsplit:latest' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("${out_dir}/*.bam")        , optional: true, emit: bam
    tuple val(meta), path("${out_dir}/*.bai")        , optional: true, emit: bai
    tuple val(meta), path("${out_dir}/*.csi")        , optional: true, emit: csi
    tuple val(meta), path("${out_dir}/*.json")       , optional: true, emit: manifest
    path  "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args    = task.ext.args   ?: ''
    def out_dir = task.ext.out_dir ?: 'chromosomes'
    """
    bamsplit \\
        chrom \\
        $args \\
        $bam \\
        --out-dir $out_dir \\
        -t $task.cpus

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bamsplit: \$( bamsplit --version | head -n 1 | sed 's/bamsplit //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def out_dir = task.ext.out_dir ?: 'chromosomes'
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
