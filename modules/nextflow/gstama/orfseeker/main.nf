process GSTAMA_ORF_SEEKER {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gs-tama:1.0.3--hdfd78af_0' :
        'quay.io/biocontainers/gs-tama:1.0.3--hdfd78af_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*_orfs.fa"), emit: fasta
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    tama_orf_seeker.py \\
        -f $fasta \\
        -o ${prefix}_orfs.fa \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gstama: 1.0.3
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo -e '>orf1\\nMPEPTIDE*\\n>orf2\\nMPEPTIDE*\\n>orf3\\nMPEPTIDE*' > ${prefix}_orfs.fa
    touch versions.yml
    """
}
