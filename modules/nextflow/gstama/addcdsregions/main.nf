process GSTAMA_ADD_CDS_REGIONS {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gs-tama:1.0.3--hdfd78af_0' :
        'quay.io/biocontainers/gs-tama:1.0.3--hdfd78af_0' }"

    input:
    tuple val(meta), path(parsed), path(bed), path(fasta)

    output:
    tuple val(meta), path("*_cds.bed"), emit: bed
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    tama_cds_regions_bed_add.py \\
        -p $parsed \\
        -a $bed \\
        -f $fasta \\
        -o ${prefix}_cds.bed \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gstama: 1.0.3
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_cds.bed
    touch versions.yml
    """
}
