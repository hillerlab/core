/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process SPLICEAI_PUBLISH {
    tag "publish"
    label 'process_single'

    input:
    tuple val(meta), path(donor_plus)
    tuple val(meta1), path(donor_minus)
    tuple val(meta2), path(acceptor_plus)
    tuple val(meta3), path(acceptor_minus)

    output:
    path("spliceai"), emit: spliceai

    script:
    """
    mkdir -p spliceai
    cp ${donor_plus} spliceai/
    cp ${donor_minus} spliceai/
    cp ${acceptor_plus} spliceai/
    cp ${acceptor_minus} spliceai/
    """

    stub:
    """
    mkdir -p spliceai
    touch spliceai/*.bw
    """
}
