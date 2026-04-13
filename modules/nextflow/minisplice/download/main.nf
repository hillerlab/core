/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MINISPLICE_DOWNLOAD — Download MiniSplice model and calibration files.
    Fetches the pre-trained MiniSplice model and calibration data from Zenodo.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process MINISPLICE_DOWNLOAD {
    tag "minisplice"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/wget:1.25.0' :
        'quay.io/biocontainers/wget:1.25.0' }"

    output:
    tuple val("minisplice"), path("*.kan"), emit: model
    tuple val("minisplice"), path("*.cali"), emit: calibration
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    wget -O- https://zenodo.org/records/15931054/files/vi2-7k.tgz | tar zxf -

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$( wget --version | sed 's/GNU Wget //g' )
    END_VERSIONS
    """

    stub:
    """
    touch vi2-7k.kan
    touch vi2-7k.kan.cali

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wget: \$( wget --version | sed 's/GNU Wget //g' )
    END_VERSIONS
    """
}
