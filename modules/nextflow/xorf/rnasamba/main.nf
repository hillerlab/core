// Copyright (c) 2025 Alejandro Gonzales-Irribarren <alejandrxgzi@gmail.com>
// Distributed under the terms of the Apache License, Version 2.0.

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RNASAMBA — Classifies ORFs as coding or non-coding using RNAsamba machine learning
    models through a Rust wrapper. Requires specifiying the upstream and downstream 
    amount of nucleotides extended from the incoming file.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process RNASAMBA {
    tag "$meta.id:$meta.name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container 'ghcr.io/alejandrogzi/orf-samba:latest'

    input:
    tuple val(meta), path(bed), path(sequence)
    tuple val(_), path(weights)

    output:
    tuple val(meta), path("${meta.id}/*tsv")      , optional: true, emit: samba
    tuple val(meta), path("${meta.id}/*strip.fa") , optional: true, emit: fasta
    tuple val(meta), path(bed)                    , optional: true, emit: bed
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def upstream = task.ext.upstream ?: 1000
    def downstream = task.ext.downstream ?: 1000
    """
    orf samba \\
    --fasta $sequence \\
    --outdir ${meta.id} \\
    --upstream-flank $upstream \\
    --downstream-flank $downstream \\
    --weights $weights \\
    $args

    mv ${meta.id}/samba/*tsv ${meta.id}/${meta.id}.${meta.name}.samba.tsv && rm -rf ${meta.id}/samba
    mv ${meta.name}.tmp.strip.fa ${meta.id}/${meta.id}.${meta.name}.strip.fa 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        orf-samba: \$(orf --version 2>&1 | sed 's/^.*orf //; s/ .*\$//')
        rnasamba: \$(rnasamba --version 2>&1 | tail -n 1 | sed 's/^rnasamba //')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}
    touch ${meta.id}/*strip.fa
    touch ${meta.id}/samba
    touch ${meta.id}/samba/*

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        orf-samba: \$(orf --version 2>&1 | sed 's/^.*orf //; s/ .*\$//')
        rnasamba: \$(rnasamba --version 2>&1 | tail -n 1 | sed 's/^rnasamba //')
    END_VERSIONS
    """
}
