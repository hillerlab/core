/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process REPEAT_FILLER {
    tag "$chain_chunk.name"
    label 'process_fast'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '' : 
        'ghcr.io/hillerlab/containers/repeat_filler:latest' }"

    input:
    path chain_chunk         // one infill_chain_N file
    path target_twobit
    path query_twobit
    val  chain_min_score
    val  fill_gap_max_size_t
    val  fill_gap_max_size_q
    val  fill_insert_chain_min_score
    val  fill_gap_min_size_t
    val  fill_gap_min_size_q
    val  fill_lastz_k
    val  fill_lastz_l
    val  chain_linear_gap
    val  skip_fill_unmask
    val  lastz_path

    output:
    path "${chain_chunk.name}.filled.chain", emit: filled_chain
    path "versions.yml",                      emit: versions

    script:
    def unmask_arg = skip_fill_unmask ? '' : '--unmask'
    def out_chain  = "${chain_chunk.name}.filled.chain"
    """
    repeat_filler.py \\
        --chain ${chain_chunk} \\
        --T2bit ${target_twobit} \\
        --Q2bit ${query_twobit} \\
        --workdir ./ \\
        --lastz ${lastz_path} \\
        --axtChain axtChain \\
        --chainSort chainSort \\
        --chainMinScore ${chain_min_score} \\
        --gapMaxSizeT ${fill_gap_max_size_t} \\
        --gapMaxSizeQ ${fill_gap_max_size_q} \\
        --scoreThreshold ${fill_insert_chain_min_score} \\
        --gapMinSizeT ${fill_gap_min_size_t} \\
        --gapMinSizeQ ${fill_gap_min_size_q} \\
        --lastzParameters "K=${fill_lastz_k} L=${fill_lastz_l}" \\
        ${unmask_arg} \\
    | chainScore \\
        -linearGap=${chain_linear_gap} \\
        stdin \\
        ${target_twobit} \\
        ${query_twobit} \\
        stdout \\
    | chainSort stdin ${out_chain}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | awk '{print \$2}')
        repeat_filler: \$(repeat_filler.py --version | sed -e "s/repeat_filler //g")
    END_VERSIONS
    """

    stub:
    def out_chain = "${chain_chunk.name}.filled.chain"
    """
    touch ${out_chain}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | awk '{print \$2}')
        repeat_filler: \$(repeat_filler.py --version | sed -e "s/repeat_filler //g")
    END_VERSIONS
    """
}
