/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    BQC — CBQ-native all-in-one quality control (the FASTP of the CBQ path).
    Runs the adapter, trim and filter stages in a single pass and writes a
    structured JSON report used to populate the run samplesheet.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process BQC {
    tag "$meta.id"
    label 'custom_process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' :
        'ghcr.io/hillerlab/bqc:latest' }"

    input:
    tuple val(meta), path(cbq)

    output:
    tuple val(meta), path("*.clean.cbq"), emit: reads
    tuple val(meta), path("*.bqc.json") , emit: report
    path "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // NOTE: `bqc workflow` aborts with "no operation configured" when no adapter,
    // trim, filter or correction option is given, so $args must never be empty.
    // The bqc_* defaults in nextflow.config guarantee at least --min-length.
    """
    bqc \\
        workflow \\
        $cbq \\
        -o ${prefix}.clean.cbq \\
        --report ${prefix}.bqc.json \\
        --report-format json \\
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
    touch ${prefix}.clean.cbq
    echo '{"counts":{"records_in":0,"records_out":0,"records_rejected":0}}' > ${prefix}.bqc.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bqc: \$(bqc --version | sed 's/bqc //g')
    END_VERSIONS
    """
}
