/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

process TRACKDB {
    tag "${prefix} trackDb"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        '':
        'ghcr.io/hillerlab/sed:latest' }"

    input:
    path schema
    val browser
    val species
    val track
    val additional_columns
    val prefix

    output:
    path "*.ra",          emit: schema
    path "versions.yml",  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    sed \
      -e "s|{BROWSER}|$browser|g" \
      -e "s|{SPECIES}|$species|g" \
      -e "s|{TRACK}|$track|g" \
      -e "s|{ADDITIONAL_COLUMNS}|$additional_columns|g" \
      -e "s|{PREFIX}|$prefix|g" \
      $schema > ${prefix}.schema.ra

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sed: \$(sed --version 2>&1 | head -n1 | sed 's/sed (GNU sed) //g; s/  .*//')
    END_VERSIONS
    """

    stub:
    """
    touch ${prefix}.schema.ra

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sed: \$(sed --version 2>&1 | head -n1 | sed 's/sed (GNU sed) //g; s/  .*//')
    END_VERSIONS
    """
}
