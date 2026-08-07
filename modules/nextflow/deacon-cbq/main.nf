/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    DEACON_CBQ_FILTER — Filter CBQ reads using a Deacon transcript index.
    The CBQ-native variant of DEACON_FILTER: reads are detected as CBQ by magic
    bytes and written when the output path ends in .cbq. CBQ pairing is native,
    so paired reads stay in one file and --output2 must not be used.
    Depletion (--deplete) is enabled via ext.args, as in DEACON_FILTER.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process DEACON_CBQ_FILTER {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/deacon-cbq:latest' }"

    input:
    tuple val(meta), path(cbq)
    tuple val(meta1), path(index)

    output:
    tuple val(meta), path("*.deacon.cbq") , emit: cbq
    tuple val(meta), path("*.deacon.json"), emit: summary
    tuple val(meta), path("*.deacon.log") , emit: log
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    deacon \\
        filter \\
        --threads $task.cpus \\
        -o ${prefix}.deacon.cbq \\
        -s ${prefix}.deacon.json \\
        $args \\
        $index \\
        $cbq \\
        > ${prefix}.deacon.log 2>&1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version | head -n1 | sed 's/deacon //g')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.deacon.cbq
    echo '{"seqs_in":0,"seqs_out":0}' > ${prefix}.deacon.json
    touch ${prefix}.deacon.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        deacon: \$(deacon --version | head -n1 | sed 's/deacon //g')
    END_VERSIONS
    """
}
