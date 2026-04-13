/*
Copyright (c) 2026 The Hiller Lab at the Senckenberg Gessellschaft für Naturforschung
Distributed under the terms of the Apache License, Version 2.0.
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PBBAM_TO_FA — Extract PacBio BAM sequences to FASTA format.
    Splits a PacBio BAM file into high-quality reads and singletons,
    outputting both FASTA and BAM formats.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

process PBBAM_TO_FA {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.22.1--h96c455f_0' :
        'biocontainers/samtools:1.22.1--h96c455f_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta1), path("*.singletons.fasta.gz") , optional: true, emit: singletons
    tuple val(meta1),  path("*.singletons.bam")     , optional: true, emit: singletons_bam
    tuple val(meta2), path("*.hq.fasta.gz")         , optional: true, emit: hq
    tuple val(meta2), path("*.hq.bam")              , optional: true, emit: hq_bam
    path  "versions.yml"                            , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix        = task.ext.prefix ?: "${meta.id}"
    def keep_temp     = task.ext.keep_temp ?: false

    def singleton_bam = prefix + ".singletons.bam"
    def singleton_fa  = prefix + ".singletons.fasta.gz"
    def hq_bam        = prefix + ".hq.bam"
    def hq_fa         = prefix + ".hq.fasta.gz"

    meta1 = meta.clone()
    meta2 = meta.clone()

    meta1.singleton = true
    meta2.singleton = false
    """
    set +e
    trap '' PIPE
    samtools view -h -@ ${task.cpus} ${bam} \\
    | tee >(
        awk '{
          {
            if(\$1 ~ /^@/) {{print; next}} 
            for (i=12;i<=NF;i++) {{
                if(\$i ~ /^is:i:1\$/) {{print; break}}
            }}
          }
        }' \\
    | samtools view -@ ${task.cpus} -bo ${singleton_bam} -) \\
    | awk '{
        {
          if(\$1 ~ /^@/) {{print; next}} 
          for (i=12;i<=NF;i++) {{
            if(\$i ~ /^is:i:/) {{
              split(\$i,a,\":\"); 
              if (a[3]!=1) {{print; break}}
            }}
          }}
        }
      }' \\
    | samtools view -@ ${task.cpus} -bo ${hq_bam} -

    set -e
    samtools fasta -@ ${task.cpus} ${hq_bam} | gzip -9 > ${hq_fa}
    samtools fasta -@ ${task.cpus} ${singleton_bam} | gzip -9 > ${singleton_fa}

    if [ ${keep_temp} == false ]; then
        rm ${hq_bam} ${singleton_bam}
    fi

    # Remove optional outputs that contain no FASTA records without tripping pipefail.
    for f in ${hq_fa} ${singleton_fa}; do
        if [ -f "\$f" ]; then
            if gunzip -c "\$f" 2>/dev/null | awk 'BEGIN { has_content = 0 } { has_content = 1 } END { exit has_content ? 0 : 1 }'; then
                echo "Keeping \$f"
            elif gzip -t "\$f" >/dev/null 2>&1; then
                echo "Removing \$f (contains no data)"
                rm "\$f"
            else
                echo "Failed to validate \$f" >&2
                exit 1
            fi
        fi
    done

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$( samtools --version | head -n 1 | sed 's/samtools //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def keep_temp = task.ext.keep_temp ?: false
    """
    touch ${prefix}.singletons.fasta.gz
    touch ${prefix}.hq.fasta.gz
    touch ${prefix}.singletons.bam
    touch ${prefix}.hq.bam

    if [ ${keep_temp} == false ]; then
        rm ${prefix}.singletons.bam
        rm ${prefix}.hq.bam
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$( samtools --version | head -n 1 | sed 's/samtools //g' | sed 's/ (.*//g' )
    END_VERSIONS
    """
}
