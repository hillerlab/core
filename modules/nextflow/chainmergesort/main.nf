/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CHAIN_MERGE_SORT — Merge all per-bundle chain files into a single sorted chain.
    Uses chainMergeSort piped through gzip.
    Credits: Nil Mu
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process CHAIN_MERGE_SORT {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc_tools:332--1' : 
        'quay.io/biocontainers/ucsc_tools:332--1' }"

    input:
    path chain_files    // list of all .chain files from AXT_CHAIN
    val  target_name
    val  query_name

    output:
    path "${target_name}.${query_name}.all.chain.gz", emit: merged_chain
    path "versions.yml",                               emit: versions

    script:
    """
    mkdir -p temp_kent

    # Write file list for chainMergeSort -inputList
    ls *.chain > chain_file_list.txt

    chainMergeSort -inputList=chain_file_list.txt -tempDir=temp_kent \\
    | gzip -c > ${target_name}.${query_name}.all.chain.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc-chainmergesort: \$(chainMergeSort 2>&1 | grep version | awk '{print \$NF}' || echo 'N/A')
    END_VERSIONS
    """

    stub:
    """
    touch ${target_name}.${query_name}.all.chain.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc-chainmergesort: \$(chainMergeSort 2>&1 | grep version | awk '{print \$NF}' || echo 'N/A')
    END_VERSIONS
    """
}
