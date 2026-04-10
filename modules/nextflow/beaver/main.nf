/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process BEAVER {
    tag "meta_assembly"
    label 'process_long_high'

    conda "${moduleDir}/environment.yml"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' : 
        'ghcr.io/alejandrogzi/beaver:latest' }"

    input:
    path gtfs

    output:
    path "beaver_output/*gtf"        , emit: gtf
    path "beaver_output/*csv"        , emit: csv
    path "gtf_list.txt"              , emit: gtf_list
    path "versions.yml"              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "beaver_output"
    """
    for gtf in ${gtfs}; do
        echo "\$gtf" >> gtf_list.txt
    done

    # Create output directory
    mkdir -p beaver_output

    # Run Beaver
    beaver \\
        gtf_list.txt \\
        ${prefix} \\
        -t ${task.cpus} \\
        $args

    mv ${prefix}.gtf beaver_output/
    mv ${prefix}_feature.csv beaver_output/

    if [ ${params.beaver_keep_aletsch_gtf} == false ]; then
        for gtf in ${gtfs}; do
            if [ -L "\$gtf" ]; then
                realpath=\$(readlink -f "\$gtf")
                rm -f "\$gtf"
                if [ -n "\$realpath" ]; then
                    rm -f "\$realpath"
                fi
            else
                rm -f "\$gtf"
            fi
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        beaver: \$(beaver --version 2>&1 | sed 's/^.*beaver //; s/ .*\$//' || echo "0.0.1")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "beaver_output"
    """
    mkdir -p beaver_output
    touch gtf_list.txt
    touch beaver_output/${prefix}.gtf
    touch beaver_output/${prefix}.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        beaver: 0.0.1
    END_VERSIONS
    """
}
