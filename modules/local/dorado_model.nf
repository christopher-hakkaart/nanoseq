process DORADO_MODEL {
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/nanoporetech/dorado:sha097d9c8abc39b8266e3ee58f531f5ef8944a02c3' :
        'docker.io/nanoporetech/dorado:sha097d9c8abc39b8266e3ee58f531f5ef8944a02c3' }"

    input:
    val model

    output:
    path "*"            , emit: model
    path "versions.yml" , emit: versions

    script:
    def args = task.ext.args ?: ''

    """
    dorado download \\
        --model ${model}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1)
    END_VERSIONS
    """
}
