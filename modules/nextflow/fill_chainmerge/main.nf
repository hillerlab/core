/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FILL_CHAIN_MERGE — Merge all filled chain chunks into a single compressed chain.
    Uses chainMergeSort piped through gzip.
    Credits: Nil Mu
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process FILL_CHAIN_MERGE {
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc_tools:332--1' : 
        'quay.io/biocontainers/ucsc_tools:332--1' }"

    input:
    path filled_chain_files   // list of *.filled.chain files from REPEAT_FILLER
    val  target_name
    val  query_name

    output:
    path "${target_name}.${query_name}.filled.chain.gz", emit: filled_chain
    path "versions.yml",                                  emit: versions

    script:
    """
    mkdir -p temp_kent

    ls *.filled.chain > filled_chain_list.txt

    chainMergeSort -inputList=filled_chain_list.txt -tempDir=temp_kent \\
    | gzip -c > ${target_name}.${query_name}.filled.chain.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc-chainmergesort: \$(chainMergeSort 2>&1 | grep version | awk '{print \$NF}' || echo 'N/A')
    END_VERSIONS
    """

    stub:
    """
    touch ${target_name}.${query_name}.filled.chain.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ucsc-chainmergesort: \$(chainMergeSort 2>&1 | grep version | awk '{print \$NF}' || echo 'N/A')
    END_VERSIONS
    """ 
}
