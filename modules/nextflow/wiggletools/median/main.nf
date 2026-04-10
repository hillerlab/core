process WIGGLETOOLS_MEDIAN {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/wiggletools:1.2.11--h7118728_10':
        'biocontainers/wiggletools:1.2.11--h7118728_10' }"

    input:
    tuple val(meta), path(bigwigs)

    output:
    tuple val(meta), path("*.wig"), emit: wig
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    wiggletools \\
        $args \\
        median \\
        $bigwigs \\
        > ${prefix}.wig

    if [ ${params.wigtools_keep_bigwig} == false ]; then
        for bw in ${bigwigs}; do
            if [ -L "\$bw" ]; then
                realpath=\$(readlink -f "\$bw")
                rm -f "\$bw"
                if [ -n "\$realpath" ]; then
                    rm -f "\$realpath"
                fi
            else
                rm -f "\$bw"
            fi
        done
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wiggletools: \$(wiggletools --version 2>&1 | sed 's/^wiggletools //; s/using //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.wig

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        wiggletools: \$(wiggletools --version 2>&1 | sed 's/^wiggletools //; s/using //')
    END_VERSIONS
    """
}
