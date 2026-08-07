/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BQC_SNIFF_ADAPTERS — Infer which adapter sequences contaminate CBQ reads.
    Non-destructive: the input is opened read-only and never rewritten. The
    report is always written as JSON, the stable pipeline interface.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BQC_SNIFF_ADAPTERS {
    tag "$meta.id"
    label 'custom_process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/bqc:latest' }"

    input:
    tuple val(meta), path(cbq)

    output:
    tuple val(meta), path("*.adapters.json"), emit: report
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    bqc \\
        sniff adapters \\
        $cbq \\
        --format json \\
        -o ${prefix}.adapters.json \\
        -T $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqc: \$(bqc --version | sed 's/bqc //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo '{"result":{"r1":{"decision":"stub"},"r2":{"decision":"stub"}}}' > ${prefix}.adapters.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqc: \$(bqc --version | sed 's/bqc //g')
    END_VERSIONS
    """
}
