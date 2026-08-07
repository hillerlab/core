process GSTAMA_BLASTP_PARSER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gs-tama:1.0.3--hdfd78af_0' :
        'quay.io/biocontainers/gs-tama:1.0.3--hdfd78af_0' }"

    input:
    tuple val(meta), path(blastp)

    output:
    tuple val(meta), path("*_parsed.tsv"), emit: tsv
    path "versions.yml"                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat ${blastp.join(' ')} > ${prefix}.blastp.txt

    tama_orf_blastp_parser.py \\
        -b ${prefix}.blastp.txt \\
        -o ${prefix}_parsed.tsv \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gstama: 1.0.3
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_parsed.tsv
    touch versions.yml
    """
}
