// Copyright (c) 2025 Alejandro Gonzales-Irribarren <alejandrxgzi@gmail.com>
// Distributed under the terms of the Apache License, Version 2.0.

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NETSTART2 — Predicts translation initiation sites using neural networks
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process NETSTART2 {
    tag "$meta.id:$meta.name"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container 'ghcr.io/alejandrogzi/orf-net:latest'

    input:
    tuple val(meta), path(sequence)
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path("${meta.id}*csv"), optional: true, emit: netstart
    tuple val(meta), env(PREDICTION_COUNT),  optional: true, emit: count
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    netstart2 \\
    -in $sequence \\
    -compute_device cpu \\
    -o chordata \\
    -out ${meta.id}_netstart
    $args

    PREDICTION_COUNT=\$(wc -l < ${meta.id}*csv)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        netstart2: \$(netstart2 --version 2>&1 | sed 's/.*Version: //')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}*

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        netstart2: \$(netstart2 --version 2>&1 | sed 's/.*Version: //')
    END_VERSIONS
    """
}
